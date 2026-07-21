# Chat-Core Revamp — Design (kreiseck_chat v0.3.0)

Date: 2026-07-21
Package: `flutter/kreiseck_chat`
Branch: `chat-core-revamp` (off `main`)
Status: approved for planning

## 1. Goal

Lift the chat half of `kreiseck_chat` from a minimal bubble list to a
market-leader-grade messaging UI kit (WhatsApp / iMessage class), while keeping
the package a **pure, backend-agnostic UI kit**. Every advanced feature is
individually toggleable, and channels select a preconfigured capability profile
(`ChatCapabilities.twilioSms()`, `ChatCapabilities.twilioWhatsApp()`,
`ChatCapabilities.inApp()`, or `custom`). The same widgets must serve SMS,
E-Mail (core parts), WhatsApp, and future in-app messaging — each channel only
supplies what it can.

This spec covers the **chat core only**. Explicitly deferred to their own specs:
the detailed E-Mail composer, wiring the revamped chat into the Meine-Taxis app,
and later extras (voice messages, edit/delete UI, emoji picker, search,
forwarding).

## 2. Guiding principles

- **Pure UI, backend-agnostic.** No networking, storage, or vendor logic. State
  (presence, typing, reactions, receipts) flows in via richer models; actions
  (pick photo, send, react, reply) flow out via callbacks.
- **No heavy new dependencies.** Haptics via Flutter's `HapticFeedback`;
  animations via built-in `Animated* ` / `AnimationController`. Image *rendering*
  uses an `ImageProvider`/URL the app supplies; image *picking/upload* is the
  app's job via a callback — no `image_picker` in the package.
- **Optional with defaults.** The only required inputs stay `messages` + `onSend`.
  Everything else has a sensible default; a host app can override one field
  (e.g. `accentColor`) and inherit the rest.
- **Capability-gated affordances.** Widgets never show an affordance the channel
  can't honor (no reaction menu on SMS, no typing bubble without typing support).

## 3. Capabilities — the backbone

`ChatCapabilities` is an immutable value object describing what UI affordances
are allowed for the current channel. Widgets read it to decide what to render.

```dart
class ChatCapabilities {
  final bool reactions;        // long-press reaction menu + reaction chips
  final bool replies;          // swipe-to-reply + quoted-reply block
  final bool media;            // image bubbles + composer attach/camera button
  final bool typingIndicator;  // typing bubble + "tippt…" in list/header
  final bool presence;         // online dot + "zuletzt gesehen"
  final bool readReceipts;     // read ticks vs delivered-only ceiling

  const ChatCapabilities({ /* all named, all default false */ });

  const ChatCapabilities.twilioSms();       // text only; status ceiling = delivered
  const ChatCapabilities.twilioWhatsApp();  // media, reactions(in), read receipts, reply-quote; no typing
  const ChatCapabilities.inApp();           // everything true
  const ChatCapabilities.custom({ ... });   // pick each flag

  ChatCapabilities copyWith({ ... });
}
```

Notes:
- `readReceipts:false` means the status icon never advances past `delivered`
  even if a message carries `MessageStatus.read` (SMS can't prove reads).
- Motion/haptics are **not** capabilities (they are channel-independent) — they
  live in `ChatMotion` (theme level).
- Profiles are plain named constructors so callers can start from one and
  `copyWith` a single flag (e.g. `ChatCapabilities.twilioSms().copyWith(media: true)`
  for MMS).

## 4. Models

Backward-compatible additions where possible. The one intentional breaking
change: `ChatMessage.attachments` becomes `List<ChatAttachment>` (was
`List<String>`). Acceptable because the chat widgets are not yet wired into any
app (only the mail half is). Version bumps to `0.3.0`.

### 4.1 ChatMessage (extended)
Existing: `id, direction, text, at, status`. Added (all optional):
- `sender` — `ChatParticipant?` (for group avatars/names; null in 1:1).
- `attachments` — `List<ChatAttachment>` (typed; default `const []`).
- `replyTo` — `ChatMessageRef?` (quoted message: id, snippet, sender label).
- `reactions` — `List<MessageReaction>` (default `const []`).
- `editedAt` — `DateTime?`.
- `deliveredAt`, `readAt` — `DateTime?` (optional precise receipts).

Keeps `copyWith`, `==`, `hashCode` (updated for new fields).

### 4.2 New types
- **`ChatParticipant`** — `id, displayName, avatar (ImageProvider?), avatarUrl (String?),
  presence (ChatPresence?), color (Color?)`. `avatar` wins over `avatarUrl` when
  both set; when neither, widgets render an initials monogram from `displayName`.
- **`ChatPresence`** — `state: PresenceState {online, offline, unknown}`,
  `lastSeen: DateTime?`, `customLabel: String?`. Widgets format a label
  ("Online", "zuletzt gesehen 14:32", "zuletzt gesehen gestern") unless
  `customLabel` overrides it.
- **`ChatAttachment`** — `kind: AttachmentKind {image, video, file, audio}`,
  `url: String?`, `thumbnail: ImageProvider?`/`thumbnailUrl: String?`,
  `fileName: String?`, `sizeBytes: int?`, `width/height: int?`. Has
  `fromJson`/`toJson` (mirrors `MailAttachment` style for consistency).
- **`ChatMessageRef`** — `id, snippet, senderLabel` for reply quoting.
- **`MessageReaction`** — `emoji: String, count: int, reactedByMe: bool`.
- **`TypingState`** — `participants: List<ChatParticipant>` currently typing
  (empty = nobody). Convenience `bool get anyoneTyping`.

### 4.3 ChatConversation (extended)
Existing: `id, title, subtitle, channelLabel, lastText, lastAt, unread`. Added:
`avatar (ImageProvider?)`/`avatarUrl`, `presence (ChatPresence?)`, `typing (bool)`,
`muted (bool = false)`, `pinned (bool = false)`. `copyWith`/equality updated.

## 5. Theme & customization — layered `ChatTheme`

`ChatTheme` becomes a composition of independently overridable sub-configs, each
with defaults. The existing `ChatTheme.light()`/`.dark()` API is preserved.
`MailTheme` is separate and untouched.

- **`ChatColors`** — current 8 colors plus: bubble tail, reaction-chip bg/text,
  presence-online color, typing-dot color, date-separator bg/text, reply-accent
  bar, selection/highlight. `ChatColors.light()`/`.dark()`.
- **`ChatTypography`** — `TextStyle`s: `body, timestamp, senderName,
  dateSeparator, systemMessage, headerTitle, headerSubtitle, replyQuote`.
  Factory `ChatTypography.fromTextTheme(TextTheme)` derives sensible defaults
  from the ambient theme when not explicitly set.
- **`ChatIcons`** — `IconData` for `send, attach, camera, mic, sent, delivered,
  read, reply, error`. Defaults to Material icons; swappable (e.g. Cupertino).
- **`ChatMotion`** — durations + curves + toggles:
  `bubbleEntrance (bool), sendAnimation (bool), animatedAutoScroll (bool),
  hapticsEnabled (bool)`, plus per-event haptic flags
  `hapticOnSend, hapticOnReceive, hapticOnLongPress, hapticOnReaction` and the
  `HapticFeedback` intensity per event. `ChatMotion.none()` disables all
  animation + haptics in one call. All on by default.
- **`bubbleStyle: BubbleStyle {whatsApp, iMessage, minimal}`** — controls tail
  rendering, corner radii, grouping-corner behavior, and time/status placement
  (WhatsApp: time+ticks inside bottom-right of bubble; iMessage: time as
  separate light row, reactions as tapbacks; minimal: no tail, uniform corners).

Coherent presets: `ChatTheme.whatsApp({Brightness})` and
`ChatTheme.iMessage({Brightness})` set colors + `bubbleStyle` + typography
together. `ChatTheme` exposes `copyWith` and forwards field overrides so a host
can tweak a single value.

## 6. Widgets

### 6.1 MessageBubble (rewrite)
- Renders per `bubbleStyle` — tail via a `CustomPainter` for WhatsApp/iMessage,
  plain rounded rect for minimal.
- **Grouping**: takes `isFirstInGroup`/`isLastInGroup` (computed by
  `ChatThreadView`) to adjust corner radii, whether to show the sender
  avatar/name (groups only), and vertical spacing.
- **Reply quote** block above the text when `message.replyTo != null`.
- **Attachments**: image attachments render as rounded thumbnails (aspect-ratio
  boxed); tap invokes `onOpenAttachment(attachment)` (host shows fullscreen).
  Non-image attachments render a compact file chip.
- **Reactions**: reaction chips row anchored to the bubble corner when
  `capabilities.reactions` and `message.reactions` non-empty.
- **Time + status** placed per preset; status icon respects the `readReceipts`
  ceiling.
- **Entrance animation** (fade + slide/scale) when `motion.bubbleEntrance`.
- **Interactions** (all capability-gated): long-press opens a reaction/reply
  action menu (`onReact`, `onReplyRequested`); horizontal swipe triggers
  swipe-to-reply (`onReplyRequested`). Long-press/reaction fire haptics per
  `ChatMotion`.

### 6.2 Supporting widgets
- **`TypingIndicator`** — animated three-dot bubble in incoming style.
- **`DateSeparator`** — centered pill ("Heute"/"Gestern"/date).
- **`ChatHeader`** (optional) — avatar + title + presence/last-seen line (or
  "tippt…" when typing) + trailing actions slot.

### 6.3 ChatThreadView (rewrite)
Orchestrates the thread:
- Groups consecutive messages by sender + time proximity → sets grouping flags.
- Inserts `DateSeparator`s at day boundaries.
- Renders `TypingIndicator` at the bottom when `typing.anyoneTyping` &&
  `capabilities.typingIndicator`.
- Auto-scrolls to newest (animated when `motion.animatedAutoScroll`).
- `onLoadEarlier` callback for pull-to-load-older history.
- Optional embedded `ChatHeader` (or host supplies its own AppBar).
- Passes `capabilities`, `theme`, and callbacks (`onSend`, `onReact`,
  `onReplyRequested`, `onOpenAttachment`, `onTypingChanged`, `onLoadEarlier`)
  down to children.

### 6.4 Composer (rewrite)
- Auto-growing multiline field (1–5 lines).
- **Attach/camera button** shown only when `capabilities.media` →
  `onAttach(AttachSource)` callback (host runs the picker/camera + upload).
- Send button with send animation + haptic (per `ChatMotion`).
- `onTypingChanged(bool)` callback (debounced) so the host can broadcast typing.
- Mic button rendered as a disabled placeholder for future voice messages
  (behind a flag; off by default).

### 6.5 ConversationListView / tile (rewrite)
- Avatar (image or initials monogram) with a presence dot overlay when
  `capabilities.presence`.
- Unread badge, muted/pinned indicators, channel-label chip.
- Preview line shows "tippt…" when `conversation.typing` &&
  `capabilities.typingIndicator`, else `lastText` with a trailing status tick.

## 7. Example app = visual QA

`example/lib/main.dart` becomes a gallery with live toggles:
- Bubble preset (WhatsApp / iMessage / minimal).
- Capability profile (SMS / WhatsApp / InApp / custom flags).
- Light/dark.
- Seeded data exercising presence, typing, reactions, image + file
  attachments, reply quotes, grouping, date separators.

This doubles as the manual/screenshot QA surface for approval.

## 8. Tests

Widget tests (finder/structure based, avoiding brittle goldens):
- Bubble renders the expected structure per `bubbleStyle`.
- **Capability gating**: reaction menu absent when `reactions:false`; attach
  button absent when `media:false`; typing bubble absent when
  `typingIndicator:false`; status icon capped at delivered when
  `readReceipts:false`.
- Grouping flags produce the expected avatar/name visibility and corner
  treatment.
- `TypingIndicator` animates (controller advances).
- Presence label formatting ("Online" / "zuletzt gesehen …").
- Composer attach-button visibility follows `capabilities.media`.
- `ChatMotion.none()` disables entrance animation and suppresses haptics.

## 9. Versioning & compatibility

- Version → `0.3.0` (pre-1.0; the `attachments` type change is a permitted
  breaking change; only the path-dependent app consumes the package, and it uses
  only the mail half).
- `ChatTheme.light()`/`.dark()`, `MessageBubble`, `Composer`, `ChatThreadView`,
  `ConversationListView` keep their public names; new required-behavior is
  additive with defaults.
- README + CHANGELOG updated to document capabilities, presets, and the new
  models.

## 10. Deferred (own specs, not dropped)

1. Detailed E-Mail composer (To/CC/BCC, subject, rich text, attachments).
2. Wiring the revamped chat core into the Meine-Taxis app SMS/WhatsApp inbox.
3. Voice messages, message edit/delete UI, emoji picker, search, forwarding.
