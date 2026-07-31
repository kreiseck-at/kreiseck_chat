# kreiseck_chat

Reusable, backend-agnostic chat UI widgets and models for Flutter apps.

This package contains only UI and plain data models — no networking, storage,
or vendor-specific logic. Wire it up to whatever transport (REST, sockets,
a database, ...) your app already uses by feeding it lists of `ChatMessage`
and `ChatConversation` and handling the `onSend`/`onOpen` callbacks.

## Features

* **Models** — `ChatMessage`, `ChatConversation`, `ChatParticipant`,
  `ChatPresence`, `ChatAttachment`, `MessageReaction`, `ChatMessageRef`,
  `TypingState`: immutable data classes with `copyWith` and value equality.
  `ChatMessage` carries an optional `sender` (for group threads), typed
  `attachments`, a `replyTo` reference, `reactions`, and delivery/read
  timestamps — plus `channel`, `errorText`, `kind`, `translation`, and
  `headline` (see below). `ChatConversation` carries `channels`, a list of
  `ChatChannel` feeding into it.
* **`ChatChannel`** — a value object describing a channel a message travelled
  over: an id, display label, icon, and brand color. Ready-made templates —
  `ChatChannel.whatsApp()`, `.sms()`, `.email()`, `.inApp()`, `.voice()` —
  cover the channels most apps have; override anything via `copyWith` to
  match your own branding. Rendered consistently by `ChatChannelBadge`.
* **`ChatCapabilities`** — a single flag set (`reactions`, `replies`, `media`,
  `typingIndicator`, `presence`, `readReceipts`) that tells the widgets which
  affordances a channel actually supports, so the UI never offers something
  the backend can't do. Built-in profiles: `ChatCapabilities.twilioSms()`
  (plain text only), `ChatCapabilities.twilioWhatsApp()` (media, replies,
  reactions, read receipts, no typing/presence), and
  `ChatCapabilities.inApp()` (everything on). Use the default constructor or
  `ChatCapabilities.custom(...)` for anything in between.
* **`ChatTheme`** — a layered visual configuration composed of `ChatColors`,
  `ChatTypography`, `ChatIcons`, and `ChatMotion`, plus a `BubbleStyle`
  (`whatsApp`, `iMessage`, `minimal`), `bubbleRadius`, and `showBubbleTail`.
  Ready-made presets: `ChatTheme.light()`, `ChatTheme.dark()`,
  `ChatTheme.whatsApp()`, and `ChatTheme.iMessage()` (the latter two take a
  `brightness`). Override just the sub-config you need; the pre-0.3 flat
  color getters (`accentColor`, `incomingBubbleColor`, ...) are preserved
  for existing call sites. `ChatColors` now also carries `error` and
  `warning`. `showBubbleTail` is off by default in every preset, including
  `whatsApp` and `iMessage` — the classic speech-bubble tail is opt-in, not
  drawn automatically just because a preset is styled after an app that
  has one.
* **`BubbleInk` / `ChatColors.inkFor`** — colors that sit *on* a bubble
  (message text, muted timestamps/status, quote lines/dividers) are not
  fixed values: `ChatColors.inkFor(bubble)` returns a `BubbleInk` derived
  from that bubble's own fill color via `BubbleInk.forSurface`, so a host
  picking any custom `outgoingBubble`/`incomingBubble` color still gets
  legible text without hand-picking a matching text color. The derived
  tones follow the polarity of that bubble's own text color
  (`outgoingText`/`incomingText`), so timestamp, quote bar and reply name
  always match the message text instead of independently chasing raw
  contrast. `line` is guaranteed at least 3:1; `text` and `muted` reach
  4.5:1 wherever that polarity allows it, and fall back to the same 3:1
  floor where it doesn't — e.g. on the default outgoing blue, white text
  only reaches 4.07:1, an accepted trade-off for one consistent tone over
  maximum contrast. Set `incomingInk`/`outgoingInk` on `ChatColors` to
  override the derivation for a given bubble. The lower-level `readableOn(surface,
  desired, {target})` and `contrastRatio(a, b)` helpers do the same for
  colors that must keep their own hue (e.g. an error red or the read-tick
  blue) rather than being replaced outright — used throughout the bubble,
  channel badge, and banner for exactly that.
* **`MessageBubble`** — timestamp, delivery status icon, sender name/avatar
  in group threads, quoted replies, reaction chips, and media attachments —
  each gated by `ChatCapabilities`. Also renders a bold `headline` above the
  text, a `ChatChannelBadge` when the message has a `channel`, the
  `errorText` under a failed bubble with an `onRetry` callback that shows a
  "Erneut senden" action next to it (omit it to show just the failure
  reason, with no retry action), and — when `translation` is set — a
  tap-to-toggle between original text and translation (which side it opens
  on follows `ChatTranslation.showFirst`). Pass `textBuilder` to draw the
  body yourself — e.g. linkified text — instead of a plain `Text`, and
  `ChatColors.incomingBubbleBorder` / `outgoingBubbleBorder` for a hairline
  around bubbles whose fill is close to the background.
* **`ChatSystemCard`** — a centered card for non-message content in the
  thread: system notes, logged events, summaries. Messages with
  `kind: ChatMessageKind.system` render as this automatically.
* **`ChatBanner`** — a notice bar (`ChatBannerVariant.info` / `.warning`)
  for states affecting the reply: a restricted channel, a disconnected
  connection, a locked thread.
* **`Composer`** — an auto-growing text field with a send button, an
  attach button gated on `capabilities.media`, typing-change callbacks, and
  an optional `leading` widget (e.g. a channel picker).
* **`ChatThreadView`** — a scrollable message list that groups consecutive
  messages by sender, inserts date separators, shows a `TypingIndicator`,
  auto-scrolls to the newest message, and renders an optional `header`.
  `customMessageBuilder` lets the host render its own widget for
  `kind: ChatMessageKind.custom` messages (falling back to the normal bubble
  if it returns `null`); `composerBanner` and `composerLeading` are forwarded
  to the composer; `readOnly` hides the composer entirely for archive or
  supervisory views.
* **`ChatHeader`** — a conversation header with avatar, title, and a
  presence/typing subtitle.
* **`ConversationListView`** — a conversation inbox list with avatars,
  presence dots, unread badges, and typing previews. `onLongPress` opens an
  action sheet from a row; `titleBadgeBuilder` renders a small badge before
  the title (e.g. a spam marker); each row shows a compact strip of channel
  badges built from `ChatConversation.channels` in the subtitle line
  (`channelBadge` still wins when supplied, then `channels`, then the plain
  `channelLabel` text).
* **`ChatStrings`** — every word the widgets put on screen (reply/copy/retry,
  today/yesterday, the composer's hint and attachment labels, the typing
  indicator, presence/last-seen wording, and the mail widgets' subject/to/
  body/spam labels) lives in one immutable class, resolved from the ambient
  `Locale`. A host that already sets its app locale needs to pass nothing —
  but a plain `MaterialApp.locale` isn't quite enough on its own, since
  `TextField`s (like the composer's) also need `MaterialLocalizations`,
  which Flutter only ships pre-built for English. One thing this doesn't
  cover: `ChatChannel`'s templates (`.whatsApp()`, `.sms()`, ...) carry
  their own `label` (e.g. `.voice()`'s default is the German "Anruf") —
  channel names are data on a `const` value object rather than `ChatStrings`
  wording, so translate them by passing your own `label` per instance.

  ```yaml
  # pubspec.yaml of the app (not this package — it adds none of its own
  # dependencies), so MaterialLocalizations has real resources to load for
  # 'uk' instead of just falling through to English.
  dependencies:
    flutter_localizations:
      sdk: flutter
  ```

  ```dart
  import 'package:flutter_localizations/flutter_localizations.dart';

  MaterialApp(
    locale: const Locale('uk'),
    supportedLocales: const [Locale('uk'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: ChatThreadView(messages: messages, onSend: send),
  );

  // Or override a single word:
  ChatThreadView(
    messages: messages,
    onSend: send,
    strings: const ChatStrings.de().copyWith(retry: 'Nochmal versuchen'),
  );
  ```

  Not keen on the extra dependency? `example/lib/main.dart` shows the
  delegate pair this package's own tests use to preview every locale
  without depending on `flutter_localizations` — it hands the framework's
  English-only resources back for any locale, unconditionally.

  Built-in presets cover English, German, Croatian, Turkish, and Ukrainian
  (`ChatStrings.en()` … `.uk()`); any other locale falls back to English.
  `copyWith` also takes a `clearX` switch (e.g. `clearAvatarUrl: true`) to
  empty a nullable field on the various model classes across this package —
  something `field ?? this.field` alone can't express, since there's no way
  to tell "leave it" apart from "set it back to null".

## Installation

```yaml
dependencies:
  kreiseck_chat: ^0.3.0
```

## Usage

```dart
import 'package:kreiseck_chat/kreiseck_chat.dart';

ChatThreadView(
  messages: messages, // List<ChatMessage>, oldest first
  onSend: (text) {
    // append a new outgoing ChatMessage to your own state/store
  },
  theme: ChatTheme.iMessage(brightness: Brightness.dark),
  capabilities: const ChatCapabilities.inApp(),
)
```

```dart
ConversationListView(
  conversations: conversations, // List<ChatConversation>
  onOpen: (conversation) {
    // navigate to the thread for this conversation
  },
  theme: ChatTheme.whatsApp(),
  capabilities: const ChatCapabilities.twilioWhatsApp(),
)
```

Channel-aware threads with a restricted composer, a channel picker, and
custom message rendering:

```dart
ChatThreadView(
  messages: messages,
  onSend: send,
  capabilities: const ChatCapabilities.twilioSms(),
  composerBanner: ChatBanner(
    text: 'Über SMS sind keine Bilder möglich.',
    variant: ChatBannerVariant.warning,
    theme: theme, // ChatThreadView can't hand its theme down to a
    // pre-built child widget, so pass the same theme explicitly.
  ),
  composerLeading: myChannelPicker,
  customMessageBuilder: (m) => m.kind == ChatMessageKind.custom
      ? MyCallCard(message: m)
      : null,
)
```

See `example/lib/main.dart` for a self-contained demo gallery that switches
between bubble presets, capability profiles, and light/dark mode against
seeded data (presence, typing, reactions, a reply, channels, translations,
system/custom messages, and a conversation list with pinned rows and channel
badges).

## Additional information

Widgets never hard-code colors; everything is driven through `ChatTheme` so
apps can support light and dark mode and match a channel's native look
(WhatsApp, iMessage, or a fully custom `minimal` base) without forking the
widgets. Pair a theme with the `ChatCapabilities` profile that matches your
transport so the UI only offers what the channel can actually deliver.
