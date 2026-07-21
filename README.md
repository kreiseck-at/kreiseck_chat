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
  timestamps.
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
* **`MessageBubble`** — timestamp, delivery status icon, sender name/avatar
  in group threads, quoted replies, reaction chips, and media attachments —
  each gated by `ChatCapabilities`.
* **`Composer`** — an auto-growing text field with a send button, an
  attach button gated on `capabilities.media`, and typing-change callbacks.
* **`ChatThreadView`** — a scrollable message list that groups consecutive
  messages by sender, inserts date separators, shows a `TypingIndicator`,
  auto-scrolls to the newest message, and renders an optional `header`.
* **`ChatHeader`** — a conversation header with avatar, title, and a
  presence/typing subtitle.
* **`ConversationListView`** — a conversation inbox list with avatars,
  presence dots, unread badges, and typing previews.

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

See `example/lib/main.dart` for a self-contained demo gallery that switches
between bubble presets, capability profiles, and light/dark mode against
seeded data (presence, typing, reactions, a reply).

## Additional information

Widgets never hard-code colors; everything is driven through `ChatTheme` so
apps can support light and dark mode and match a channel's native look
(WhatsApp, iMessage, or a fully custom `minimal` base) without forking the
widgets. Pair a theme with the `ChatCapabilities` profile that matches your
transport so the UI only offers what the channel can actually deliver.
