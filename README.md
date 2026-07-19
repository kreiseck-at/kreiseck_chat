# kreiseck_chat

Reusable, backend-agnostic chat UI widgets and models for Flutter apps.

This package contains only UI and plain data models — no networking, storage,
or vendor-specific logic. Wire it up to whatever transport (REST, sockets,
a database, ...) your app already uses by feeding it lists of `ChatMessage`
and `ChatConversation` and handling the `onSend`/`onOpen` callbacks.

## Features

* `ChatMessage` / `ChatConversation` — simple, immutable data models with
  `copyWith` and value equality.
* `ChatTheme` — a single place to configure colors and bubble radius, with
  `ChatTheme.light()` and `ChatTheme.dark()` presets.
* `MessageBubble` — a chat bubble with timestamp and delivery status icon.
* `Composer` — a text field + send button that clears itself after sending.
* `ChatThreadView` — a scrollable message list (auto-scrolls to the newest
  message) plus a composer.
* `ConversationListView` — a conversation inbox list with unread badges.

## Installation

```yaml
dependencies:
  kreiseck_chat: ^0.1.0
```

## Usage

```dart
import 'package:kreiseck_chat/kreiseck_chat.dart';

ChatThreadView(
  messages: messages, // List<ChatMessage>, oldest first
  onSend: (text) {
    // append a new outgoing ChatMessage to your own state/store
  },
  theme: ChatTheme.dark(),
)
```

```dart
ConversationListView(
  conversations: conversations, // List<ChatConversation>
  onOpen: (conversation) {
    // navigate to the thread for this conversation
  },
)
```

See `example/lib/main.dart` for a complete, self-contained demo using
in-memory data.

## Additional information

Widgets never hard-code colors; everything is driven through `ChatTheme` so
apps can support light and dark mode without forking the widgets.
