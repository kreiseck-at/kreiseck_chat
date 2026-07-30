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
  (`whatsApp`, `iMessage`, `minimal`) and `bubbleRadius`. Ready-made presets:
  `ChatTheme.light()`, `ChatTheme.dark()`, `ChatTheme.whatsApp()`, and
  `ChatTheme.iMessage()` (the latter two take a `brightness`). Override just
  the sub-config you need; the pre-0.3 flat color getters (`accentColor`,
  `incomingBubbleColor`, ...) are preserved for existing call sites.
  `ChatColors` now also carries `error` and `warning`.
* **`MessageBubble`** — timestamp, delivery status icon, sender name/avatar
  in group threads, quoted replies, reaction chips, and media attachments —
  each gated by `ChatCapabilities`. Also renders a bold `headline` above the
  text, a `ChatChannelBadge` when the message has a `channel`, the
  `errorText` under a failed bubble, and — when `translation` is set — a
  tap-to-toggle between original text and translation.
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
