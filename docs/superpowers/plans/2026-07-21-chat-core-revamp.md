# Chat-Core Revamp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lift the chat half of `kreiseck_chat` to a market-leader-grade,
fully-toggleable, capability-profiled messaging UI kit (WhatsApp/iMessage class),
while keeping the package a pure, backend-agnostic UI kit.

**Architecture:** A `ChatCapabilities` value object gates every advanced
affordance per channel (`twilioSms`, `twilioWhatsApp`, `inApp`, custom). Richer
immutable models (participant, presence, attachment, reaction, reply-ref) feed
stateless widgets. A layered `ChatTheme` (colors, typography, icons, motion,
bubble-style preset) makes everything customizable via optional fields with
defaults. Pure logic (message grouping, presence-label formatting) is extracted
into testable free functions.

**Tech Stack:** Flutter / Dart, `flutter_test`. Haptics via Flutter's
`HapticFeedback`; animations via built-in `AnimationController`/implicit
animations. No new package dependencies.

## Global Constraints

- Package dir for all commands: `flutter/kreiseck_chat`.
- Dart SDK `^3.12.1`, Flutter `>=1.17.0` (from pubspec — do not raise floors).
- **No new dependencies** in `pubspec.yaml` (no `image_picker`, etc.). Image
  rendering uses caller-supplied `ImageProvider`/URL; picking is a callback.
- **Pure UI, backend-agnostic**: no networking/storage/vendor logic anywhere.
- **Optional-with-defaults**: only `messages` + `onSend` stay required on the
  thread view; every other widget/model field must have a default.
- **No AI / assistant footprint** in code, comments, commit messages, or docs.
  Commit messages in German, imperative, matching existing history style
  (e.g. "Chat-Fähigkeitsprofile ergänzen"). No `Co-Authored-By`, no tool markers.
- All new public types are exported from `lib/kreiseck_chat.dart`.
- Every new public type gets `==`, `hashCode`, and (where it models mutable-ish
  state) `copyWith`, matching the existing `ChatMessage` style.
- Run all tests with `flutter test` from the package dir; single file with
  `flutter test test/<name>_test.dart`.
- Version bumps to `0.3.0`; `attachments` changing from `List<String>` to
  `List<ChatAttachment>` is the one accepted breaking change.

---

## File Structure

New files:
- `lib/src/chat_capabilities.dart` — `ChatCapabilities` + named profiles.
- `lib/src/chat_participant.dart` — `ChatParticipant`, `ChatPresence`, `PresenceState`.
- `lib/src/chat_attachment.dart` — `ChatAttachment`, `AttachmentKind`.
- `lib/src/chat_reaction.dart` — `MessageReaction`.
- `lib/src/chat_colors.dart` — `ChatColors`.
- `lib/src/chat_typography.dart` — `ChatTypography`.
- `lib/src/chat_icons.dart` — `ChatIcons`.
- `lib/src/chat_motion.dart` — `ChatMotion`.
- `lib/src/bubble_style.dart` — `BubbleStyle`.
- `lib/src/thread_items.dart` — `ThreadItem` hierarchy + `buildThreadItems()`.
- `lib/src/presence_label.dart` — `PresenceLabels` + `formatPresenceLabel()`.
- `lib/src/bubble_tail_painter.dart` — `BubbleTailPainter`.
- `lib/src/typing_indicator.dart` — `TypingIndicator`.
- `lib/src/date_separator.dart` — `DateSeparator`.
- `lib/src/chat_header.dart` — `ChatHeader`.

Modified files:
- `lib/src/models.dart` — extend `ChatMessage`, `ChatConversation`; add
  `ChatMessageRef`, `TypingState`.
- `lib/src/chat_theme.dart` — compose sub-configs + presets.
- `lib/src/message_bubble.dart` — rewrite.
- `lib/src/composer.dart` — rewrite.
- `lib/src/chat_thread_view.dart` — rewrite.
- `lib/src/conversation_list_view.dart` — rewrite.
- `lib/kreiseck_chat.dart` — exports.
- `example/lib/main.dart` — gallery rewrite.
- `pubspec.yaml`, `README.md`, `CHANGELOG.md`.

---

## Task 1: ChatCapabilities

**Files:**
- Create: `lib/src/chat_capabilities.dart`
- Test: `test/chat_capabilities_test.dart`

**Interfaces:**
- Produces: `ChatCapabilities` with `bool reactions, replies, media,
  typingIndicator, presence, readReceipts`; const default ctor (all `false`);
  `const ChatCapabilities.twilioSms()`, `.twilioWhatsApp()`, `.inApp()`,
  `.custom({...})`; `copyWith({...}) -> ChatCapabilities`.

- [ ] **Step 1: Write the failing test**

`test/chat_capabilities_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  test('twilioSms is text-only', () {
    const c = ChatCapabilities.twilioSms();
    expect(c.reactions, isFalse);
    expect(c.replies, isFalse);
    expect(c.media, isFalse);
    expect(c.typingIndicator, isFalse);
    expect(c.presence, isFalse);
    expect(c.readReceipts, isFalse);
  });

  test('twilioWhatsApp enables media/reactions/replies/readReceipts but not typing/presence', () {
    const c = ChatCapabilities.twilioWhatsApp();
    expect(c.media, isTrue);
    expect(c.reactions, isTrue);
    expect(c.replies, isTrue);
    expect(c.readReceipts, isTrue);
    expect(c.typingIndicator, isFalse);
    expect(c.presence, isFalse);
  });

  test('inApp enables everything', () {
    const c = ChatCapabilities.inApp();
    expect(
      [c.reactions, c.replies, c.media, c.typingIndicator, c.presence, c.readReceipts],
      everyElement(isTrue),
    );
  });

  test('copyWith overrides a single flag and keeps the rest', () {
    const base = ChatCapabilities.twilioSms();
    final withMedia = base.copyWith(media: true);
    expect(withMedia.media, isTrue);
    expect(withMedia.reactions, isFalse);
    expect(withMedia, isNot(equals(base)));
  });

  test('value equality', () {
    expect(const ChatCapabilities.inApp(),
        equals(const ChatCapabilities.custom(
          reactions: true, replies: true, media: true,
          typingIndicator: true, presence: true, readReceipts: true,
        )));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/chat_capabilities_test.dart`
Expected: FAIL — `ChatCapabilities` undefined / not exported.

- [ ] **Step 3: Write minimal implementation**

`lib/src/chat_capabilities.dart`:
```dart
/// Describes which chat UI affordances a channel supports.
///
/// Widgets read this to decide what to render — e.g. the reaction menu only
/// appears when [reactions] is true, the composer's attach button only when
/// [media] is true. Motion and haptics are configured separately in the theme.
class ChatCapabilities {
  /// Creates a capability set. All flags default to `false`; this is also the
  /// "custom" entry point — set exactly the flags a channel supports.
  const ChatCapabilities({
    this.reactions = false,
    this.replies = false,
    this.media = false,
    this.typingIndicator = false,
    this.presence = false,
    this.readReceipts = false,
  });

  /// Alias of the default constructor for readability at call sites.
  const ChatCapabilities.custom({
    bool reactions = false,
    bool replies = false,
    bool media = false,
    bool typingIndicator = false,
    bool presence = false,
    bool readReceipts = false,
  }) : this(
          reactions: reactions,
          replies: replies,
          media: media,
          typingIndicator: typingIndicator,
          presence: presence,
          readReceipts: readReceipts,
        );

  /// Classic Twilio SMS: plain text, delivery ceiling, nothing else.
  const ChatCapabilities.twilioSms()
      : reactions = false,
        replies = false,
        media = false,
        typingIndicator = false,
        presence = false,
        readReceipts = false;

  /// Twilio WhatsApp: media, inbound reactions, quoted replies, read receipts.
  /// No outbound typing signal and no presence in the Business API.
  const ChatCapabilities.twilioWhatsApp()
      : reactions = true,
        replies = true,
        media = true,
        typingIndicator = false,
        presence = false,
        readReceipts = true;

  /// Full in-app messaging: every affordance enabled.
  const ChatCapabilities.inApp()
      : reactions = true,
        replies = true,
        media = true,
        typingIndicator = true,
        presence = true,
        readReceipts = true;

  /// Whether long-press reactions and reaction chips are shown.
  final bool reactions;

  /// Whether swipe-to-reply and quoted-reply blocks are shown.
  final bool replies;

  /// Whether image bubbles and the composer attach button are shown.
  final bool media;

  /// Whether the typing indicator (bubble + list preview) is shown.
  final bool typingIndicator;

  /// Whether presence (online dot + "last seen") is shown.
  final bool presence;

  /// When false, an outgoing status icon never advances past
  /// [MessageStatus.delivered] even if the message reports `read`.
  final bool readReceipts;

  /// Returns a copy with the given flags replaced.
  ChatCapabilities copyWith({
    bool? reactions,
    bool? replies,
    bool? media,
    bool? typingIndicator,
    bool? presence,
    bool? readReceipts,
  }) {
    return ChatCapabilities(
      reactions: reactions ?? this.reactions,
      replies: replies ?? this.replies,
      media: media ?? this.media,
      typingIndicator: typingIndicator ?? this.typingIndicator,
      presence: presence ?? this.presence,
      readReceipts: readReceipts ?? this.readReceipts,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatCapabilities &&
        other.reactions == reactions &&
        other.replies == replies &&
        other.media == media &&
        other.typingIndicator == typingIndicator &&
        other.presence == presence &&
        other.readReceipts == readReceipts;
  }

  @override
  int get hashCode => Object.hash(
        reactions,
        replies,
        media,
        typingIndicator,
        presence,
        readReceipts,
      );
}
```

Add to `lib/kreiseck_chat.dart`:
```dart
export 'src/chat_capabilities.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/chat_capabilities_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/src/chat_capabilities.dart lib/kreiseck_chat.dart test/chat_capabilities_test.dart
git commit -m "Chat-Fähigkeitsprofile (Capabilities) ergänzen"
```

---

## Task 2: Presence & participant models

**Files:**
- Create: `lib/src/chat_participant.dart`
- Test: `test/chat_participant_test.dart`

**Interfaces:**
- Produces:
  - `enum PresenceState { online, offline, unknown }`
  - `ChatPresence({PresenceState state = unknown, DateTime? lastSeen, String? customLabel})`,
    `const ChatPresence.online()`, `copyWith`, `==`/`hashCode`.
  - `ChatParticipant({required String id, required String displayName,
    ImageProvider? avatar, String? avatarUrl, ChatPresence? presence, Color? color})`,
    `String get initials`, `copyWith`, `==`/`hashCode`.

- [ ] **Step 1: Write the failing test**

`test/chat_participant_test.dart`:
```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  test('initials take up to two words, uppercased', () {
    expect(const ChatParticipant(id: '1', displayName: 'Ada Lovelace').initials, 'AL');
    expect(const ChatParticipant(id: '2', displayName: 'madonna').initials, 'M');
    expect(const ChatParticipant(id: '3', displayName: '  ').initials, '?');
    expect(const ChatParticipant(id: '4', displayName: 'Jean-Luc Picard Jr').initials, 'JP');
  });

  test('ChatPresence.online sets state', () {
    expect(const ChatPresence.online().state, PresenceState.online);
  });

  test('participant copyWith replaces presence', () {
    const p = ChatParticipant(id: '1', displayName: 'A');
    final online = p.copyWith(presence: const ChatPresence.online());
    expect(online.presence?.state, PresenceState.online);
    expect(online.id, '1');
  });

  test('value equality ignores nothing relevant', () {
    expect(
      const ChatParticipant(id: '1', displayName: 'A', color: Color(0xFF112233)),
      equals(const ChatParticipant(id: '1', displayName: 'A', color: Color(0xFF112233))),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/chat_participant_test.dart`
Expected: FAIL — types undefined.

- [ ] **Step 3: Write minimal implementation**

`lib/src/chat_participant.dart`:
```dart
import 'package:flutter/widgets.dart';

/// Coarse online state of a participant.
enum PresenceState { online, offline, unknown }

/// Presence information for a participant: online state plus an optional
/// last-seen time and a caller-supplied label override.
class ChatPresence {
  /// Creates presence info.
  const ChatPresence({
    this.state = PresenceState.unknown,
    this.lastSeen,
    this.customLabel,
  });

  /// Convenience for an online participant.
  const ChatPresence.online()
      : state = PresenceState.online,
        lastSeen = null,
        customLabel = null;

  /// Coarse online state.
  final PresenceState state;

  /// When last seen (used to format a "last seen …" label if [customLabel] is null).
  final DateTime? lastSeen;

  /// If set, shown verbatim instead of a computed label.
  final String? customLabel;

  /// Returns a copy with the given fields replaced.
  ChatPresence copyWith({
    PresenceState? state,
    DateTime? lastSeen,
    String? customLabel,
  }) {
    return ChatPresence(
      state: state ?? this.state,
      lastSeen: lastSeen ?? this.lastSeen,
      customLabel: customLabel ?? this.customLabel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatPresence &&
        other.state == state &&
        other.lastSeen == lastSeen &&
        other.customLabel == customLabel;
  }

  @override
  int get hashCode => Object.hash(state, lastSeen, customLabel);
}

/// A person taking part in a conversation.
///
/// Provide either [avatar] (an in-memory [ImageProvider]) or [avatarUrl]; when
/// both are null, widgets render an initials monogram derived from
/// [displayName]. [color] tints the sender name / monogram in group threads.
class ChatParticipant {
  /// Creates a participant.
  const ChatParticipant({
    required this.id,
    required this.displayName,
    this.avatar,
    this.avatarUrl,
    this.presence,
    this.color,
  });

  /// Stable identifier (used for grouping consecutive messages).
  final String id;

  /// Human-readable name.
  final String displayName;

  /// In-memory avatar image; wins over [avatarUrl] when both are set.
  final ImageProvider? avatar;

  /// Remote avatar URL; used when [avatar] is null.
  final String? avatarUrl;

  /// Optional presence info.
  final ChatPresence? presence;

  /// Optional accent color for the sender name / monogram.
  final Color? color;

  /// Up to two uppercase initials, or `?` when the name has no letters.
  String get initials {
    final words = displayName
        .trim()
        .split(RegExp(r'[\s\-]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.characters.first.toUpperCase();
    return (words.first.characters.first + words[1].characters.first)
        .toUpperCase();
  }

  /// Returns a copy with the given fields replaced.
  ChatParticipant copyWith({
    String? id,
    String? displayName,
    ImageProvider? avatar,
    String? avatarUrl,
    ChatPresence? presence,
    Color? color,
  }) {
    return ChatParticipant(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      presence: presence ?? this.presence,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatParticipant &&
        other.id == id &&
        other.displayName == displayName &&
        other.avatar == avatar &&
        other.avatarUrl == avatarUrl &&
        other.presence == presence &&
        other.color == color;
  }

  @override
  int get hashCode =>
      Object.hash(id, displayName, avatar, avatarUrl, presence, color);
}
```

`initials` uses `characters` — add `import 'package:characters/characters.dart';`?
`characters` is re-exported by `package:flutter/widgets.dart`, which is already
imported, so no extra dependency is needed.

Add to `lib/kreiseck_chat.dart`:
```dart
export 'src/chat_participant.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/chat_participant_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/src/chat_participant.dart lib/kreiseck_chat.dart test/chat_participant_test.dart
git commit -m "Teilnehmer- und Presence-Modelle ergänzen"
```

---

## Task 3: Attachment & reaction models

**Files:**
- Create: `lib/src/chat_attachment.dart`, `lib/src/chat_reaction.dart`
- Test: `test/chat_attachment_test.dart`

**Interfaces:**
- Produces:
  - `enum AttachmentKind { image, video, file, audio }`
  - `ChatAttachment({required AttachmentKind kind, String? url, ImageProvider?
    thumbnail, String? thumbnailUrl, String? fileName, int? sizeBytes, int?
    width, int? height})`, `fromJson`/`toJson`, `copyWith`, `==`/`hashCode`.
    (`thumbnail` is excluded from JSON — it is an in-memory provider.)
  - `MessageReaction({required String emoji, int count = 1, bool reactedByMe = false})`,
    `copyWith`, `==`/`hashCode`.

- [ ] **Step 1: Write the failing test**

`test/chat_attachment_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  test('attachment JSON round-trips (thumbnail provider excluded)', () {
    const a = ChatAttachment(
      kind: AttachmentKind.image,
      url: 'https://x/y.jpg',
      thumbnailUrl: 'https://x/y_t.jpg',
      fileName: 'y.jpg',
      sizeBytes: 4096,
      width: 800,
      height: 600,
    );
    final json = a.toJson();
    expect(json['kind'], 'image');
    expect(ChatAttachment.fromJson(json), equals(a));
    expect(json.containsKey('thumbnail'), isFalse);
  });

  test('reaction copyWith bumps count', () {
    const r = MessageReaction(emoji: '❤️');
    expect(r.count, 1);
    expect(r.copyWith(count: 3, reactedByMe: true).count, 3);
    expect(r.copyWith(reactedByMe: true).reactedByMe, isTrue);
  });

  test('reaction value equality', () {
    expect(const MessageReaction(emoji: '👍', count: 2),
        equals(const MessageReaction(emoji: '👍', count: 2)));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/chat_attachment_test.dart`
Expected: FAIL — types undefined.

- [ ] **Step 3: Write minimal implementation**

`lib/src/chat_attachment.dart`:
```dart
import 'package:flutter/widgets.dart';

/// The kind of content an attachment carries.
enum AttachmentKind { image, video, file, audio }

/// A media/file attachment on a chat message.
///
/// Backend-agnostic: it carries references, not bytes. Provide [thumbnail] (an
/// in-memory image) or [thumbnailUrl] for a preview; [url] points at the full
/// asset the host opens.
class ChatAttachment {
  /// Creates an attachment.
  const ChatAttachment({
    required this.kind,
    this.url,
    this.thumbnail,
    this.thumbnailUrl,
    this.fileName,
    this.sizeBytes,
    this.width,
    this.height,
  });

  /// Content kind.
  final AttachmentKind kind;

  /// URL of the full asset.
  final String? url;

  /// In-memory preview image; wins over [thumbnailUrl] when both are set.
  final ImageProvider? thumbnail;

  /// Remote preview URL; used when [thumbnail] is null.
  final String? thumbnailUrl;

  /// Display file name, e.g. `invoice.pdf`.
  final String? fileName;

  /// File size in bytes, if known.
  final int? sizeBytes;

  /// Pixel width, if known (used to size image bubbles).
  final int? width;

  /// Pixel height, if known.
  final int? height;

  /// Creates an attachment from a JSON-decoded map. The in-memory [thumbnail]
  /// provider is not part of JSON.
  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      kind: AttachmentKind.values.byName(json['kind'] as String),
      url: json['url'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      fileName: json['fileName'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  /// Converts to a JSON-encodable map (excludes the in-memory [thumbnail]).
  Map<String, dynamic> toJson() {
    return {
      'kind': kind.name,
      if (url != null) 'url': url,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (fileName != null) 'fileName': fileName,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }

  /// Returns a copy with the given fields replaced.
  ChatAttachment copyWith({
    AttachmentKind? kind,
    String? url,
    ImageProvider? thumbnail,
    String? thumbnailUrl,
    String? fileName,
    int? sizeBytes,
    int? width,
    int? height,
  }) {
    return ChatAttachment(
      kind: kind ?? this.kind,
      url: url ?? this.url,
      thumbnail: thumbnail ?? this.thumbnail,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatAttachment &&
        other.kind == kind &&
        other.url == url &&
        other.thumbnail == thumbnail &&
        other.thumbnailUrl == thumbnailUrl &&
        other.fileName == fileName &&
        other.sizeBytes == sizeBytes &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(
        kind,
        url,
        thumbnail,
        thumbnailUrl,
        fileName,
        sizeBytes,
        width,
        height,
      );
}
```

`lib/src/chat_reaction.dart`:
```dart
/// A single emoji reaction aggregate on a message.
class MessageReaction {
  /// Creates a reaction aggregate.
  const MessageReaction({
    required this.emoji,
    this.count = 1,
    this.reactedByMe = false,
  });

  /// The emoji, e.g. `❤️`.
  final String emoji;

  /// How many participants reacted with [emoji].
  final int count;

  /// Whether the current user is among them (drives highlight styling).
  final bool reactedByMe;

  /// Returns a copy with the given fields replaced.
  MessageReaction copyWith({String? emoji, int? count, bool? reactedByMe}) {
    return MessageReaction(
      emoji: emoji ?? this.emoji,
      count: count ?? this.count,
      reactedByMe: reactedByMe ?? this.reactedByMe,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageReaction &&
        other.emoji == emoji &&
        other.count == count &&
        other.reactedByMe == reactedByMe;
  }

  @override
  int get hashCode => Object.hash(emoji, count, reactedByMe);
}
```

Add to `lib/kreiseck_chat.dart`:
```dart
export 'src/chat_attachment.dart';
export 'src/chat_reaction.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/chat_attachment_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/src/chat_attachment.dart lib/src/chat_reaction.dart lib/kreiseck_chat.dart test/chat_attachment_test.dart
git commit -m "Anhang- und Reaktions-Modelle ergänzen"
```

---

## Task 4: Extend ChatMessage & ChatConversation; add ChatMessageRef, TypingState

**Files:**
- Modify: `lib/src/models.dart`
- Test: `test/models_test.dart`

**Interfaces:**
- Consumes: `ChatParticipant` (Task 2), `ChatAttachment` (Task 3),
  `MessageReaction` (Task 3).
- Produces:
  - `ChatMessage` gains optional `ChatParticipant? sender`,
    `List<ChatAttachment> attachments = const []`, `ChatMessageRef? replyTo`,
    `List<MessageReaction> reactions = const []`, `DateTime? editedAt,
    deliveredAt, readAt`. `attachments` type changes from `List<String>`.
  - `ChatMessageRef({required String id, required String snippet, String?
    senderLabel})`, `==`/`hashCode`.
  - `TypingState({List<ChatParticipant> participants = const []})`,
    `bool get anyoneTyping`, `==`/`hashCode`.
  - `ChatConversation` gains optional `ImageProvider? avatar, String? avatarUrl,
    ChatPresence? presence, bool typing = false, bool muted = false, bool pinned
    = false`.

- [ ] **Step 1: Write the failing test**

`test/models_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  final at = DateTime(2026, 7, 21, 14, 32);

  test('ChatMessage carries typed attachments, reply, reactions', () {
    final m = ChatMessage(
      id: 'm1',
      direction: MessageDirection.outgoing,
      text: 'hi',
      at: at,
      attachments: const [ChatAttachment(kind: AttachmentKind.image, url: 'u')],
      replyTo: const ChatMessageRef(id: 'm0', snippet: 'earlier', senderLabel: 'Ada'),
      reactions: const [MessageReaction(emoji: '👍', count: 2)],
    );
    expect(m.attachments.single.kind, AttachmentKind.image);
    expect(m.replyTo?.snippet, 'earlier');
    expect(m.reactions.single.count, 2);
  });

  test('ChatMessage copyWith replaces reactions', () {
    final m = ChatMessage(id: 'm1', direction: MessageDirection.incoming, text: 'x', at: at);
    final r = m.copyWith(reactions: const [MessageReaction(emoji: '❤️')]);
    expect(r.reactions.single.emoji, '❤️');
    expect(r.text, 'x');
  });

  test('TypingState.anyoneTyping', () {
    expect(const TypingState().anyoneTyping, isFalse);
    expect(
      const TypingState(participants: [ChatParticipant(id: '1', displayName: 'A')]).anyoneTyping,
      isTrue,
    );
  });

  test('ChatConversation carries presence and flags', () {
    final c = ChatConversation(
      id: 'c1',
      title: 'Ada',
      presence: const ChatPresence.online(),
      typing: true,
      pinned: true,
    );
    expect(c.presence?.state, PresenceState.online);
    expect(c.typing, isTrue);
    expect(c.pinned, isTrue);
    expect(c.copyWith(muted: true).muted, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models_test.dart`
Expected: FAIL — new fields/types undefined.

- [ ] **Step 3: Write minimal implementation**

In `lib/src/models.dart`, add imports at the top:
```dart
import 'package:flutter/widgets.dart';

import 'chat_attachment.dart';
import 'chat_participant.dart';
import 'chat_reaction.dart';
```

Replace the `ChatMessage` class (keep `MessageDirection` and `MessageStatus`
enums as-is above it) with:
```dart
/// A single message within a chat thread.
///
/// Backend-agnostic: it carries no information about how it was transported.
class ChatMessage {
  /// Creates a chat message.
  const ChatMessage({
    required this.id,
    required this.direction,
    required this.text,
    required this.at,
    this.status = MessageStatus.sent,
    this.sender,
    this.attachments = const [],
    this.replyTo,
    this.reactions = const [],
    this.editedAt,
    this.deliveredAt,
    this.readAt,
  });

  /// Unique identifier of this message.
  final String id;

  /// Whether the message was received or sent.
  final MessageDirection direction;

  /// The message body.
  final String text;

  /// Timestamp the message was created/received at.
  final DateTime at;

  /// Delivery/read status, relevant for outgoing messages.
  final MessageStatus status;

  /// Sender, for group threads (drives per-message avatar/name). Null in 1:1.
  final ChatParticipant? sender;

  /// Typed attachments (images, files, …).
  final List<ChatAttachment> attachments;

  /// The message this one replies to, if any.
  final ChatMessageRef? replyTo;

  /// Emoji reaction aggregates on this message.
  final List<MessageReaction> reactions;

  /// When the message was last edited, if ever.
  final DateTime? editedAt;

  /// Precise delivery time, if known.
  final DateTime? deliveredAt;

  /// Precise read time, if known.
  final DateTime? readAt;

  /// Returns a copy of this message with the given fields replaced.
  ChatMessage copyWith({
    String? id,
    MessageDirection? direction,
    String? text,
    DateTime? at,
    MessageStatus? status,
    ChatParticipant? sender,
    List<ChatAttachment>? attachments,
    ChatMessageRef? replyTo,
    List<MessageReaction>? reactions,
    DateTime? editedAt,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      text: text ?? this.text,
      at: at ?? this.at,
      status: status ?? this.status,
      sender: sender ?? this.sender,
      attachments: attachments ?? this.attachments,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      editedAt: editedAt ?? this.editedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.direction == direction &&
        other.text == text &&
        other.at == at &&
        other.status == status &&
        other.sender == sender &&
        _listEquals(other.attachments, attachments) &&
        other.replyTo == replyTo &&
        _listEquals(other.reactions, reactions) &&
        other.editedAt == editedAt &&
        other.deliveredAt == deliveredAt &&
        other.readAt == readAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        direction,
        text,
        at,
        status,
        sender,
        Object.hashAll(attachments),
        replyTo,
        Object.hashAll(reactions),
        editedAt,
        deliveredAt,
        readAt,
      );
}

/// A lightweight reference to a message being quoted in a reply.
class ChatMessageRef {
  /// Creates a reply reference.
  const ChatMessageRef({
    required this.id,
    required this.snippet,
    this.senderLabel,
  });

  /// Id of the referenced message.
  final String id;

  /// Short preview of the referenced message body.
  final String snippet;

  /// Optional display label of the referenced sender.
  final String? senderLabel;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessageRef &&
        other.id == id &&
        other.snippet == snippet &&
        other.senderLabel == senderLabel;
  }

  @override
  int get hashCode => Object.hash(id, snippet, senderLabel);
}

/// Who is currently typing in a thread.
class TypingState {
  /// Creates a typing state; empty means nobody is typing.
  const TypingState({this.participants = const []});

  /// Participants currently composing a message.
  final List<ChatParticipant> participants;

  /// Whether anyone is typing.
  bool get anyoneTyping => participants.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TypingState && _listEquals(other.participants, participants);
  }

  @override
  int get hashCode => Object.hashAll(participants);
}
```

Change the private `_listEquals` in this file to be generic so it also covers
`List<ChatAttachment>`, `List<MessageReaction>`, and `List<ChatParticipant>`:
```dart
bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
```

Replace the `ChatConversation` class with the extended version:
```dart
/// Summary of a conversation, as shown in a conversation list.
class ChatConversation {
  /// Creates a conversation summary.
  const ChatConversation({
    required this.id,
    required this.title,
    this.subtitle,
    this.channelLabel,
    this.lastText,
    this.lastAt,
    this.unread = 0,
    this.avatar,
    this.avatarUrl,
    this.presence,
    this.typing = false,
    this.muted = false,
    this.pinned = false,
  });

  /// Unique identifier of this conversation.
  final String id;

  /// Display title, e.g. the contact or group name.
  final String title;

  /// Optional secondary line shown below the title.
  final String? subtitle;

  /// Optional label describing the channel/source of this conversation.
  final String? channelLabel;

  /// Preview text of the most recent message.
  final String? lastText;

  /// Timestamp of the most recent message.
  final DateTime? lastAt;

  /// Number of unread messages in this conversation.
  final int unread;

  /// In-memory avatar; wins over [avatarUrl] when both are set.
  final ImageProvider? avatar;

  /// Remote avatar URL; used when [avatar] is null.
  final String? avatarUrl;

  /// Optional presence for the counterpart.
  final ChatPresence? presence;

  /// Whether the counterpart is currently typing.
  final bool typing;

  /// Whether the conversation is muted.
  final bool muted;

  /// Whether the conversation is pinned.
  final bool pinned;

  /// Returns a copy of this conversation with the given fields replaced.
  ChatConversation copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? channelLabel,
    String? lastText,
    DateTime? lastAt,
    int? unread,
    ImageProvider? avatar,
    String? avatarUrl,
    ChatPresence? presence,
    bool? typing,
    bool? muted,
    bool? pinned,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      channelLabel: channelLabel ?? this.channelLabel,
      lastText: lastText ?? this.lastText,
      lastAt: lastAt ?? this.lastAt,
      unread: unread ?? this.unread,
      avatar: avatar ?? this.avatar,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      presence: presence ?? this.presence,
      typing: typing ?? this.typing,
      muted: muted ?? this.muted,
      pinned: pinned ?? this.pinned,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatConversation &&
        other.id == id &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.channelLabel == channelLabel &&
        other.lastText == lastText &&
        other.lastAt == lastAt &&
        other.unread == unread &&
        other.avatar == avatar &&
        other.avatarUrl == avatarUrl &&
        other.presence == presence &&
        other.typing == typing &&
        other.muted == muted &&
        other.pinned == pinned;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        subtitle,
        channelLabel,
        lastText,
        lastAt,
        unread,
        avatar,
        avatarUrl,
        presence,
        typing,
        muted,
        pinned,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/models_test.dart`
Expected: PASS (4 tests). Then run the whole suite to catch fallout from the
`attachments` type change: `flutter test`. Expected: all green (the chat widgets
are rewritten in later tasks; if the *current* `MessageBubble` references
`attachments` as strings it does not — it ignores them — so no break).

- [ ] **Step 5: Commit**

```bash
git add lib/src/models.dart test/models_test.dart
git commit -m "ChatMessage/ChatConversation um Sender, Reply, Reaktionen, Presence erweitern"
```

---

## Task 5: Layered theme (colors, typography, icons, motion, bubble style) + presets

**Files:**
- Create: `lib/src/chat_colors.dart`, `lib/src/chat_typography.dart`,
  `lib/src/chat_icons.dart`, `lib/src/chat_motion.dart`, `lib/src/bubble_style.dart`
- Modify: `lib/src/chat_theme.dart`
- Test: `test/chat_theme_test.dart`

**Interfaces:**
- Produces:
  - `enum BubbleStyle { whatsApp, iMessage, minimal }`
  - `ChatColors` — fields listed below; `ChatColors.light()`, `.dark()`, `copyWith`.
  - `ChatTypography` — `TextStyle body, timestamp, senderName, dateSeparator,
    systemMessage, headerTitle, headerSubtitle, replyQuote`; const default ctor
    with sensible defaults; `ChatTypography.fromTextTheme(TextTheme)`; `copyWith`.
  - `ChatIcons` — `IconData send, attach, camera, mic, sent, delivered, read,
    reply, error`; const default ctor (Material icons); `copyWith`.
  - `ChatMotion` — `bool bubbleEntrance, sendAnimation, animatedAutoScroll,
    hapticsEnabled, hapticOnSend, hapticOnReceive, hapticOnLongPress,
    hapticOnReaction`; `Duration bubbleEntranceDuration, autoScrollDuration`;
    `Curve entranceCurve`; const default ctor (all on); `const ChatMotion.none()`.
  - `ChatTheme` recomposed: fields `ChatColors colors, ChatTypography typography,
    ChatIcons icons, ChatMotion motion, BubbleStyle bubbleStyle`; keeps
    `ChatTheme.light()`, `.dark()`; adds `ChatTheme.whatsApp({Brightness})`,
    `.iMessage({Brightness})`; `copyWith`. Back-compat getters
    `accentColor`, `backgroundColor`, `composerColor`, `bubbleRadius`,
    `incomingBubbleColor`, `outgoingBubbleColor`, `incomingTextColor`,
    `outgoingTextColor` forward to `colors`/derived values.

- [ ] **Step 1: Write the failing test**

`test/chat_theme_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  test('presets pick the right bubble style', () {
    expect(ChatTheme.whatsApp().bubbleStyle, BubbleStyle.whatsApp);
    expect(ChatTheme.iMessage().bubbleStyle, BubbleStyle.iMessage);
    expect(const ChatTheme.light().bubbleStyle, BubbleStyle.minimal);
  });

  test('ChatMotion.none disables everything', () {
    const m = ChatMotion.none();
    expect(m.bubbleEntrance, isFalse);
    expect(m.sendAnimation, isFalse);
    expect(m.animatedAutoScroll, isFalse);
    expect(m.hapticsEnabled, isFalse);
  });

  test('default ChatMotion is all-on', () {
    const m = ChatMotion();
    expect(m.hapticsEnabled, isTrue);
    expect(m.bubbleEntrance, isTrue);
  });

  test('copyWith swaps a single sub-config, keeps the rest', () {
    final base = ChatTheme.iMessage();
    final quiet = base.copyWith(motion: const ChatMotion.none());
    expect(quiet.motion.hapticsEnabled, isFalse);
    expect(quiet.bubbleStyle, BubbleStyle.iMessage);
    expect(quiet.colors, base.colors);
  });

  test('back-compat getters still resolve', () {
    const t = ChatTheme.light();
    expect(t.accentColor, isA<Color>());
    expect(t.bubbleRadius, greaterThan(0));
  });

  test('typography from text theme fills body', () {
    final typo = ChatTypography.fromTextTheme(ThemeData.light().textTheme);
    expect(typo.body, isA<TextStyle>());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/chat_theme_test.dart`
Expected: FAIL — new theme API undefined.

- [ ] **Step 3: Write minimal implementation**

`lib/src/bubble_style.dart`:
```dart
/// Visual preset for message bubbles, controlling tail, corners, and the
/// placement of time/status.
enum BubbleStyle {
  /// Tailed bubbles, time + ticks inside the bubble's bottom-right.
  whatsApp,

  /// Continuous rounded bubbles, time as a separate light row, tapback-style
  /// reactions overlapping the corner.
  iMessage,

  /// No tail, uniform corners — a neutral base for custom branding.
  minimal,
}
```

`lib/src/chat_colors.dart`:
```dart
import 'package:flutter/material.dart';

/// All colors used by the chat widgets. Every widget reads from here so hosts
/// can rebrand and support light/dark without forking widgets.
class ChatColors {
  /// Creates a color set from explicit values.
  const ChatColors({
    required this.incomingBubble,
    required this.outgoingBubble,
    required this.incomingText,
    required this.outgoingText,
    required this.background,
    required this.composer,
    required this.accent,
    required this.bubbleTail,
    required this.reactionChipBackground,
    required this.reactionChipText,
    required this.presenceOnline,
    required this.typingDot,
    required this.dateSeparatorBackground,
    required this.dateSeparatorText,
    required this.replyAccent,
  });

  /// Incoming bubble fill.
  final Color incomingBubble;

  /// Outgoing bubble fill.
  final Color outgoingBubble;

  /// Incoming text.
  final Color incomingText;

  /// Outgoing text.
  final Color outgoingText;

  /// Thread/list surface.
  final Color background;

  /// Composer bar fill.
  final Color composer;

  /// Accent (send button, read ticks).
  final Color accent;

  /// Fallback tail color (defaults to the matching bubble fill when equal).
  final Color bubbleTail;

  /// Reaction chip fill.
  final Color reactionChipBackground;

  /// Reaction chip text/emoji-count color.
  final Color reactionChipText;

  /// Online presence dot.
  final Color presenceOnline;

  /// Typing indicator dots.
  final Color typingDot;

  /// Date separator pill fill.
  final Color dateSeparatorBackground;

  /// Date separator text.
  final Color dateSeparatorText;

  /// Reply quote accent bar.
  final Color replyAccent;

  /// Sensible light palette.
  const ChatColors.light()
      : incomingBubble = const Color(0xFFE9E9EB),
        outgoingBubble = const Color(0xFF3478F6),
        incomingText = const Color(0xFF1C1C1E),
        outgoingText = const Color(0xFFFFFFFF),
        background = const Color(0xFFFAFAFA),
        composer = const Color(0xFFFFFFFF),
        accent = const Color(0xFF3478F6),
        bubbleTail = const Color(0xFFE9E9EB),
        reactionChipBackground = const Color(0xFFFFFFFF),
        reactionChipText = const Color(0xFF1C1C1E),
        presenceOnline = const Color(0xFF34C759),
        typingDot = const Color(0xFF8E8E93),
        dateSeparatorBackground = const Color(0x14000000),
        dateSeparatorText = const Color(0xFF6C6C70),
        replyAccent = const Color(0xFF3478F6);

  /// Sensible dark palette.
  const ChatColors.dark()
      : incomingBubble = const Color(0xFF2C2C2E),
        outgoingBubble = const Color(0xFF3478F6),
        incomingText = const Color(0xFFF2F2F7),
        outgoingText = const Color(0xFFFFFFFF),
        background = const Color(0xFF000000),
        composer = const Color(0xFF1C1C1E),
        accent = const Color(0xFF64A1FF),
        bubbleTail = const Color(0xFF2C2C2E),
        reactionChipBackground = const Color(0xFF3A3A3C),
        reactionChipText = const Color(0xFFF2F2F7),
        presenceOnline = const Color(0xFF32D74B),
        typingDot = const Color(0xFF98989F),
        dateSeparatorBackground = const Color(0x33FFFFFF),
        dateSeparatorText = const Color(0xFFC7C7CC),
        replyAccent = const Color(0xFF64A1FF);

  /// Returns a copy with the given fields replaced.
  ChatColors copyWith({
    Color? incomingBubble,
    Color? outgoingBubble,
    Color? incomingText,
    Color? outgoingText,
    Color? background,
    Color? composer,
    Color? accent,
    Color? bubbleTail,
    Color? reactionChipBackground,
    Color? reactionChipText,
    Color? presenceOnline,
    Color? typingDot,
    Color? dateSeparatorBackground,
    Color? dateSeparatorText,
    Color? replyAccent,
  }) {
    return ChatColors(
      incomingBubble: incomingBubble ?? this.incomingBubble,
      outgoingBubble: outgoingBubble ?? this.outgoingBubble,
      incomingText: incomingText ?? this.incomingText,
      outgoingText: outgoingText ?? this.outgoingText,
      background: background ?? this.background,
      composer: composer ?? this.composer,
      accent: accent ?? this.accent,
      bubbleTail: bubbleTail ?? this.bubbleTail,
      reactionChipBackground:
          reactionChipBackground ?? this.reactionChipBackground,
      reactionChipText: reactionChipText ?? this.reactionChipText,
      presenceOnline: presenceOnline ?? this.presenceOnline,
      typingDot: typingDot ?? this.typingDot,
      dateSeparatorBackground:
          dateSeparatorBackground ?? this.dateSeparatorBackground,
      dateSeparatorText: dateSeparatorText ?? this.dateSeparatorText,
      replyAccent: replyAccent ?? this.replyAccent,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatColors &&
        other.incomingBubble == incomingBubble &&
        other.outgoingBubble == outgoingBubble &&
        other.incomingText == incomingText &&
        other.outgoingText == outgoingText &&
        other.background == background &&
        other.composer == composer &&
        other.accent == accent &&
        other.bubbleTail == bubbleTail &&
        other.reactionChipBackground == reactionChipBackground &&
        other.reactionChipText == reactionChipText &&
        other.presenceOnline == presenceOnline &&
        other.typingDot == typingDot &&
        other.dateSeparatorBackground == dateSeparatorBackground &&
        other.dateSeparatorText == dateSeparatorText &&
        other.replyAccent == replyAccent;
  }

  @override
  int get hashCode => Object.hashAll([
        incomingBubble,
        outgoingBubble,
        incomingText,
        outgoingText,
        background,
        composer,
        accent,
        bubbleTail,
        reactionChipBackground,
        reactionChipText,
        presenceOnline,
        typingDot,
        dateSeparatorBackground,
        dateSeparatorText,
        replyAccent,
      ]);
}
```

`lib/src/chat_typography.dart`:
```dart
import 'package:flutter/material.dart';

/// Text styles used by the chat widgets.
class ChatTypography {
  /// Creates a typography set. Defaults are reasonable standalone values;
  /// prefer [ChatTypography.fromTextTheme] to inherit the ambient theme.
  const ChatTypography({
    this.body = const TextStyle(fontSize: 15, height: 1.3),
    this.timestamp = const TextStyle(fontSize: 11),
    this.senderName =
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    this.dateSeparator =
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    this.systemMessage = const TextStyle(fontSize: 12),
    this.headerTitle =
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    this.headerSubtitle = const TextStyle(fontSize: 12),
    this.replyQuote = const TextStyle(fontSize: 13),
  });

  /// Message body text.
  final TextStyle body;

  /// In-bubble timestamp.
  final TextStyle timestamp;

  /// Sender name in group threads.
  final TextStyle senderName;

  /// Date separator pill label.
  final TextStyle dateSeparator;

  /// System/notice message text.
  final TextStyle systemMessage;

  /// Header title (contact/group name).
  final TextStyle headerTitle;

  /// Header subtitle (presence / typing line).
  final TextStyle headerSubtitle;

  /// Quoted reply preview text.
  final TextStyle replyQuote;

  /// Derives a typography set from an ambient [TextTheme].
  factory ChatTypography.fromTextTheme(TextTheme t) {
    return ChatTypography(
      body: t.bodyMedium ?? const TextStyle(fontSize: 15, height: 1.3),
      timestamp: (t.labelSmall ?? const TextStyle(fontSize: 11))
          .copyWith(fontSize: 11),
      senderName: (t.labelMedium ?? const TextStyle())
          .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      dateSeparator: (t.labelMedium ?? const TextStyle())
          .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
      systemMessage: t.bodySmall ?? const TextStyle(fontSize: 12),
      headerTitle: (t.titleMedium ?? const TextStyle())
          .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      headerSubtitle: t.bodySmall ?? const TextStyle(fontSize: 12),
      replyQuote: t.bodySmall ?? const TextStyle(fontSize: 13),
    );
  }

  /// Returns a copy with the given fields replaced.
  ChatTypography copyWith({
    TextStyle? body,
    TextStyle? timestamp,
    TextStyle? senderName,
    TextStyle? dateSeparator,
    TextStyle? systemMessage,
    TextStyle? headerTitle,
    TextStyle? headerSubtitle,
    TextStyle? replyQuote,
  }) {
    return ChatTypography(
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      senderName: senderName ?? this.senderName,
      dateSeparator: dateSeparator ?? this.dateSeparator,
      systemMessage: systemMessage ?? this.systemMessage,
      headerTitle: headerTitle ?? this.headerTitle,
      headerSubtitle: headerSubtitle ?? this.headerSubtitle,
      replyQuote: replyQuote ?? this.replyQuote,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatTypography &&
        other.body == body &&
        other.timestamp == timestamp &&
        other.senderName == senderName &&
        other.dateSeparator == dateSeparator &&
        other.systemMessage == systemMessage &&
        other.headerTitle == headerTitle &&
        other.headerSubtitle == headerSubtitle &&
        other.replyQuote == replyQuote;
  }

  @override
  int get hashCode => Object.hash(body, timestamp, senderName, dateSeparator,
      systemMessage, headerTitle, headerSubtitle, replyQuote);
}
```

`lib/src/chat_icons.dart`:
```dart
import 'package:flutter/material.dart';

/// Icon set used by the chat widgets; swap for a different family (e.g.
/// Cupertino) by supplying overrides.
class ChatIcons {
  /// Creates an icon set (defaults to Material icons).
  const ChatIcons({
    this.send = Icons.send_rounded,
    this.attach = Icons.attach_file_rounded,
    this.camera = Icons.photo_camera_rounded,
    this.mic = Icons.mic_none_rounded,
    this.sent = Icons.done,
    this.delivered = Icons.done_all,
    this.read = Icons.done_all,
    this.reply = Icons.reply_rounded,
    this.error = Icons.error_outline,
  });

  /// Send button.
  final IconData send;

  /// Attach (file) button.
  final IconData attach;

  /// Camera button.
  final IconData camera;

  /// Voice message button (placeholder in v1).
  final IconData mic;

  /// Status: sent.
  final IconData sent;

  /// Status: delivered.
  final IconData delivered;

  /// Status: read (tinted with accent).
  final IconData read;

  /// Reply action.
  final IconData reply;

  /// Status: failed.
  final IconData error;

  /// Returns a copy with the given fields replaced.
  ChatIcons copyWith({
    IconData? send,
    IconData? attach,
    IconData? camera,
    IconData? mic,
    IconData? sent,
    IconData? delivered,
    IconData? read,
    IconData? reply,
    IconData? error,
  }) {
    return ChatIcons(
      send: send ?? this.send,
      attach: attach ?? this.attach,
      camera: camera ?? this.camera,
      mic: mic ?? this.mic,
      sent: sent ?? this.sent,
      delivered: delivered ?? this.delivered,
      read: read ?? this.read,
      reply: reply ?? this.reply,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatIcons &&
        other.send == send &&
        other.attach == attach &&
        other.camera == camera &&
        other.mic == mic &&
        other.sent == sent &&
        other.delivered == delivered &&
        other.read == read &&
        other.reply == reply &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
      send, attach, camera, mic, sent, delivered, read, reply, error);
}
```

`lib/src/chat_motion.dart`:
```dart
import 'package:flutter/animation.dart';

/// Animation and haptic configuration. Everything defaults to on; use
/// [ChatMotion.none] to disable all motion and haptics at once, or toggle
/// individual flags.
class ChatMotion {
  /// Creates a motion config (all effects enabled by default).
  const ChatMotion({
    this.bubbleEntrance = true,
    this.sendAnimation = true,
    this.animatedAutoScroll = true,
    this.hapticsEnabled = true,
    this.hapticOnSend = true,
    this.hapticOnReceive = false,
    this.hapticOnLongPress = true,
    this.hapticOnReaction = true,
    this.bubbleEntranceDuration = const Duration(milliseconds: 220),
    this.autoScrollDuration = const Duration(milliseconds: 300),
    this.entranceCurve = Curves.easeOutCubic,
  });

  /// All motion and haptics off.
  const ChatMotion.none()
      : bubbleEntrance = false,
        sendAnimation = false,
        animatedAutoScroll = false,
        hapticsEnabled = false,
        hapticOnSend = false,
        hapticOnReceive = false,
        hapticOnLongPress = false,
        hapticOnReaction = false,
        bubbleEntranceDuration = Duration.zero,
        autoScrollDuration = Duration.zero,
        entranceCurve = Curves.linear;

  /// Animate new bubbles in.
  final bool bubbleEntrance;

  /// Animate the send button on submit.
  final bool sendAnimation;

  /// Animate auto-scroll to newest (vs jump).
  final bool animatedAutoScroll;

  /// Master switch for haptics.
  final bool hapticsEnabled;

  /// Haptic on send.
  final bool hapticOnSend;

  /// Haptic when a new incoming message arrives.
  final bool hapticOnReceive;

  /// Haptic on bubble long-press.
  final bool hapticOnLongPress;

  /// Haptic when toggling a reaction.
  final bool hapticOnReaction;

  /// Bubble entrance duration.
  final Duration bubbleEntranceDuration;

  /// Auto-scroll animation duration.
  final Duration autoScrollDuration;

  /// Bubble entrance curve.
  final Curve entranceCurve;

  /// Returns a copy with the given fields replaced.
  ChatMotion copyWith({
    bool? bubbleEntrance,
    bool? sendAnimation,
    bool? animatedAutoScroll,
    bool? hapticsEnabled,
    bool? hapticOnSend,
    bool? hapticOnReceive,
    bool? hapticOnLongPress,
    bool? hapticOnReaction,
    Duration? bubbleEntranceDuration,
    Duration? autoScrollDuration,
    Curve? entranceCurve,
  }) {
    return ChatMotion(
      bubbleEntrance: bubbleEntrance ?? this.bubbleEntrance,
      sendAnimation: sendAnimation ?? this.sendAnimation,
      animatedAutoScroll: animatedAutoScroll ?? this.animatedAutoScroll,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      hapticOnSend: hapticOnSend ?? this.hapticOnSend,
      hapticOnReceive: hapticOnReceive ?? this.hapticOnReceive,
      hapticOnLongPress: hapticOnLongPress ?? this.hapticOnLongPress,
      hapticOnReaction: hapticOnReaction ?? this.hapticOnReaction,
      bubbleEntranceDuration:
          bubbleEntranceDuration ?? this.bubbleEntranceDuration,
      autoScrollDuration: autoScrollDuration ?? this.autoScrollDuration,
      entranceCurve: entranceCurve ?? this.entranceCurve,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMotion &&
        other.bubbleEntrance == bubbleEntrance &&
        other.sendAnimation == sendAnimation &&
        other.animatedAutoScroll == animatedAutoScroll &&
        other.hapticsEnabled == hapticsEnabled &&
        other.hapticOnSend == hapticOnSend &&
        other.hapticOnReceive == hapticOnReceive &&
        other.hapticOnLongPress == hapticOnLongPress &&
        other.hapticOnReaction == hapticOnReaction &&
        other.bubbleEntranceDuration == bubbleEntranceDuration &&
        other.autoScrollDuration == autoScrollDuration &&
        other.entranceCurve == entranceCurve;
  }

  @override
  int get hashCode => Object.hashAll([
        bubbleEntrance,
        sendAnimation,
        animatedAutoScroll,
        hapticsEnabled,
        hapticOnSend,
        hapticOnReceive,
        hapticOnLongPress,
        hapticOnReaction,
        bubbleEntranceDuration,
        autoScrollDuration,
        entranceCurve,
      ]);
}
```

Replace `lib/src/chat_theme.dart` entirely:
```dart
import 'package:flutter/material.dart';

import 'bubble_style.dart';
import 'chat_colors.dart';
import 'chat_icons.dart';
import 'chat_motion.dart';
import 'chat_typography.dart';

/// Visual configuration for the chat widgets, composed of independently
/// overridable sub-configs (colors, typography, icons, motion) plus a bubble
/// style preset. Everything has a default; override just what you need.
class ChatTheme {
  /// Creates a theme from sub-configs.
  const ChatTheme({
    this.colors = const ChatColors.light(),
    this.typography = const ChatTypography(),
    this.icons = const ChatIcons(),
    this.motion = const ChatMotion(),
    this.bubbleStyle = BubbleStyle.minimal,
    this.bubbleRadius = 16,
  });

  /// Color set.
  final ChatColors colors;

  /// Text styles.
  final ChatTypography typography;

  /// Icon set.
  final ChatIcons icons;

  /// Animation/haptic config.
  final ChatMotion motion;

  /// Bubble visual preset.
  final BubbleStyle bubbleStyle;

  /// Base corner radius for bubbles.
  final double bubbleRadius;

  /// Light preset (minimal bubbles).
  const factory ChatTheme.light() = ChatTheme._light;

  /// Dark preset (minimal bubbles).
  const factory ChatTheme.dark() = ChatTheme._dark;

  const ChatTheme._light()
      : colors = const ChatColors.light(),
        typography = const ChatTypography(),
        icons = const ChatIcons(),
        motion = const ChatMotion(),
        bubbleStyle = BubbleStyle.minimal,
        bubbleRadius = 16;

  const ChatTheme._dark()
      : colors = const ChatColors.dark(),
        typography = const ChatTypography(),
        icons = const ChatIcons(),
        motion = const ChatMotion(),
        bubbleStyle = BubbleStyle.minimal,
        bubbleRadius = 16;

  /// WhatsApp-flavored preset.
  factory ChatTheme.whatsApp({Brightness brightness = Brightness.light}) {
    final dark = brightness == Brightness.dark;
    final base = dark ? const ChatColors.dark() : const ChatColors.light();
    return ChatTheme(
      colors: base.copyWith(
        outgoingBubble: dark ? const Color(0xFF005C4B) : const Color(0xFFD9FDD3),
        outgoingText: dark ? const Color(0xFFE9EDEF) : const Color(0xFF111B21),
        bubbleTail: dark ? const Color(0xFF005C4B) : const Color(0xFFD9FDD3),
        accent: const Color(0xFF25D366),
        background: dark ? const Color(0xFF0B141A) : const Color(0xFFECE5DD),
      ),
      bubbleStyle: BubbleStyle.whatsApp,
      bubbleRadius: 12,
    );
  }

  /// iMessage-flavored preset.
  factory ChatTheme.iMessage({Brightness brightness = Brightness.light}) {
    final dark = brightness == Brightness.dark;
    final base = dark ? const ChatColors.dark() : const ChatColors.light();
    return ChatTheme(
      colors: base.copyWith(
        outgoingBubble: const Color(0xFF3478F6),
        bubbleTail: dark ? const Color(0xFF2C2C2E) : const Color(0xFFE9E9EB),
        accent: const Color(0xFF3478F6),
      ),
      bubbleStyle: BubbleStyle.iMessage,
      bubbleRadius: 18,
    );
  }

  /// Returns a copy with the given sub-configs replaced.
  ChatTheme copyWith({
    ChatColors? colors,
    ChatTypography? typography,
    ChatIcons? icons,
    ChatMotion? motion,
    BubbleStyle? bubbleStyle,
    double? bubbleRadius,
  }) {
    return ChatTheme(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      icons: icons ?? this.icons,
      motion: motion ?? this.motion,
      bubbleStyle: bubbleStyle ?? this.bubbleStyle,
      bubbleRadius: bubbleRadius ?? this.bubbleRadius,
    );
  }

  // --- Back-compat convenience getters (pre-0.3 flat API) ---

  /// Accent color (send button, read ticks).
  Color get accentColor => colors.accent;

  /// Thread/list background.
  Color get backgroundColor => colors.background;

  /// Composer bar color.
  Color get composerColor => colors.composer;

  /// Incoming bubble color.
  Color get incomingBubbleColor => colors.incomingBubble;

  /// Outgoing bubble color.
  Color get outgoingBubbleColor => colors.outgoingBubble;

  /// Incoming text color.
  Color get incomingTextColor => colors.incomingText;

  /// Outgoing text color.
  Color get outgoingTextColor => colors.outgoingText;
}
```

Add to `lib/kreiseck_chat.dart`:
```dart
export 'src/bubble_style.dart';
export 'src/chat_colors.dart';
export 'src/chat_icons.dart';
export 'src/chat_motion.dart';
export 'src/chat_typography.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/chat_theme_test.dart`
Expected: PASS (6 tests). Then `flutter test` — the existing `MessageBubble`
still compiles because it reads `theme.outgoingBubbleColor` etc. via the
back-compat getters.

- [ ] **Step 5: Commit**

```bash
git add lib/src/bubble_style.dart lib/src/chat_colors.dart lib/src/chat_typography.dart lib/src/chat_icons.dart lib/src/chat_motion.dart lib/src/chat_theme.dart lib/kreiseck_chat.dart test/chat_theme_test.dart
git commit -m "Geschichtetes ChatTheme (Farben, Typo, Icons, Motion, Bubble-Presets) einführen"
```

---

## Task 6: Thread items — grouping & date separators (pure logic)

**Files:**
- Create: `lib/src/thread_items.dart`
- Test: `test/thread_items_test.dart`

**Interfaces:**
- Consumes: `ChatMessage` (Task 4).
- Produces:
  - `abstract class ThreadItem {}`
  - `class MessageItem extends ThreadItem { final ChatMessage message; final
    bool isFirstInGroup; final bool isLastInGroup; }`
  - `class DateSeparatorItem extends ThreadItem { final DateTime date; }`
  - `List<ThreadItem> buildThreadItems(List<ChatMessage> messages, {Duration
    groupWindow = const Duration(minutes: 5)})` — messages are oldest-first;
    returns items oldest-first with a `DateSeparatorItem` before the first
    message of each calendar day. Two consecutive messages group when same
    `direction`, same `sender?.id`, and `at` within `groupWindow`. Group flags
    reflect grouping.

- [ ] **Step 1: Write the failing test**

`test/thread_items_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

ChatMessage _m(String id, DateTime at,
    {MessageDirection dir = MessageDirection.incoming, String? senderId}) {
  return ChatMessage(
    id: id,
    direction: dir,
    text: id,
    at: at,
    sender: senderId == null
        ? null
        : ChatParticipant(id: senderId, displayName: senderId),
  );
}

void main() {
  test('inserts a date separator before each day', () {
    final items = buildThreadItems([
      _m('a', DateTime(2026, 7, 20, 10, 0)),
      _m('b', DateTime(2026, 7, 21, 9, 0)),
    ]);
    expect(items.whereType<DateSeparatorItem>().length, 2);
    expect(items.first, isA<DateSeparatorItem>());
  });

  test('groups messages within the window from same sender/direction', () {
    final items = buildThreadItems([
      _m('a', DateTime(2026, 7, 21, 9, 0), dir: MessageDirection.outgoing),
      _m('b', DateTime(2026, 7, 21, 9, 2), dir: MessageDirection.outgoing),
      _m('c', DateTime(2026, 7, 21, 9, 30), dir: MessageDirection.outgoing),
    ]);
    final msgs = items.whereType<MessageItem>().toList();
    expect(msgs[0].isFirstInGroup, isTrue);
    expect(msgs[0].isLastInGroup, isFalse); // a groups with b
    expect(msgs[1].isFirstInGroup, isFalse);
    expect(msgs[1].isLastInGroup, isTrue); // c is >window later
    expect(msgs[2].isFirstInGroup, isTrue);
    expect(msgs[2].isLastInGroup, isTrue);
  });

  test('direction change breaks a group', () {
    final items = buildThreadItems([
      _m('a', DateTime(2026, 7, 21, 9, 0), dir: MessageDirection.incoming),
      _m('b', DateTime(2026, 7, 21, 9, 1), dir: MessageDirection.outgoing),
    ]);
    final msgs = items.whereType<MessageItem>().toList();
    expect(msgs[0].isLastInGroup, isTrue);
    expect(msgs[1].isFirstInGroup, isTrue);
  });

  test('empty input yields empty output', () {
    expect(buildThreadItems(const []), isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/thread_items_test.dart`
Expected: FAIL — `buildThreadItems` undefined.

- [ ] **Step 3: Write minimal implementation**

`lib/src/thread_items.dart`:
```dart
import 'models.dart';

/// An item rendered in a thread: either a message or a date separator.
abstract class ThreadItem {
  const ThreadItem();
}

/// A message plus its grouping flags within a run of same-sender messages.
class MessageItem extends ThreadItem {
  /// Creates a message item.
  const MessageItem({
    required this.message,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  /// The message.
  final ChatMessage message;

  /// Whether this is the first message of its group (show avatar/name).
  final bool isFirstInGroup;

  /// Whether this is the last message of its group (show tail/timestamp).
  final bool isLastInGroup;
}

/// A day boundary marker.
class DateSeparatorItem extends ThreadItem {
  /// Creates a date separator for [date] (date-only; time is ignored).
  const DateSeparatorItem(this.date);

  /// The day this separator introduces.
  final DateTime date;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _groupsWith(ChatMessage a, ChatMessage b, Duration window) {
  return a.direction == b.direction &&
      a.sender?.id == b.sender?.id &&
      b.at.difference(a.at).abs() <= window;
}

/// Builds a flat list of thread items (oldest first) from oldest-first
/// [messages], inserting a [DateSeparatorItem] before the first message of each
/// calendar day and computing per-message grouping flags. Consecutive messages
/// group when they share direction and sender and fall within [groupWindow].
List<ThreadItem> buildThreadItems(
  List<ChatMessage> messages, {
  Duration groupWindow = const Duration(minutes: 5),
}) {
  final items = <ThreadItem>[];
  for (var i = 0; i < messages.length; i++) {
    final m = messages[i];
    final prev = i > 0 ? messages[i - 1] : null;
    final next = i < messages.length - 1 ? messages[i + 1] : null;

    if (prev == null || !_sameDay(prev.at, m.at)) {
      items.add(DateSeparatorItem(DateTime(m.at.year, m.at.month, m.at.day)));
    }

    final groupsWithPrev = prev != null &&
        _sameDay(prev.at, m.at) &&
        _groupsWith(prev, m, groupWindow);
    final groupsWithNext = next != null &&
        _sameDay(next.at, m.at) &&
        _groupsWith(m, next, groupWindow);

    items.add(MessageItem(
      message: m,
      isFirstInGroup: !groupsWithPrev,
      isLastInGroup: !groupsWithNext,
    ));
  }
  return items;
}
```

Add to `lib/kreiseck_chat.dart`:
```dart
export 'src/thread_items.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/thread_items_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/src/thread_items.dart lib/kreiseck_chat.dart test/thread_items_test.dart
git commit -m "Nachrichten-Gruppierung und Datums-Trenner als reine Logik ergänzen"
```

---

## Task 7: Presence label formatting (pure logic)

**Files:**
- Create: `lib/src/presence_label.dart`
- Test: `test/presence_label_test.dart`

**Interfaces:**
- Consumes: `ChatPresence`, `PresenceState` (Task 2).
- Produces:
  - `class PresenceLabels { final String online, offlineUnknown; final String
    Function(DateTime lastSeen, DateTime now) lastSeen; const PresenceLabels({...
    German defaults}); }`
  - `String? formatPresenceLabel(ChatPresence? presence, {required DateTime now,
    PresenceLabels labels = const PresenceLabels()})` — returns `customLabel` if
    set; else "Online" when online; else a "zuletzt gesehen …" string when
    `lastSeen != null`; else null.

- [ ] **Step 1: Write the failing test**

`test/presence_label_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  final now = DateTime(2026, 7, 21, 15, 0);

  test('online wins', () {
    expect(
      formatPresenceLabel(const ChatPresence.online(), now: now),
      'Online',
    );
  });

  test('custom label overrides everything', () {
    expect(
      formatPresenceLabel(
          const ChatPresence(state: PresenceState.online, customLabel: 'aktiv'),
          now: now),
      'aktiv',
    );
  });

  test('last seen today shows time', () {
    final label = formatPresenceLabel(
      ChatPresence(
          state: PresenceState.offline, lastSeen: DateTime(2026, 7, 21, 14, 32)),
      now: now,
    );
    expect(label, 'zuletzt gesehen um 14:32');
  });

  test('last seen yesterday', () {
    final label = formatPresenceLabel(
      ChatPresence(
          state: PresenceState.offline, lastSeen: DateTime(2026, 7, 20, 22, 0)),
      now: now,
    );
    expect(label, 'zuletzt gesehen gestern um 22:00');
  });

  test('unknown with no lastSeen is null', () {
    expect(formatPresenceLabel(const ChatPresence(), now: now), isNull);
    expect(formatPresenceLabel(null, now: now), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presence_label_test.dart`
Expected: FAIL — `formatPresenceLabel` undefined.

- [ ] **Step 3: Write minimal implementation**

`lib/src/presence_label.dart`:
```dart
import 'chat_participant.dart';

/// Customizable label strings for presence formatting (German defaults).
class PresenceLabels {
  /// Creates label strings.
  const PresenceLabels({
    this.online = 'Online',
    this.lastSeenTodayPrefix = 'zuletzt gesehen um ',
    this.lastSeenYesterdayPrefix = 'zuletzt gesehen gestern um ',
    this.lastSeenDatePrefix = 'zuletzt gesehen am ',
  });

  /// Shown when online.
  final String online;

  /// Prefix before a HH:MM time for a same-day last-seen.
  final String lastSeenTodayPrefix;

  /// Prefix before a HH:MM time for a yesterday last-seen.
  final String lastSeenYesterdayPrefix;

  /// Prefix before a `DD.MM.YYYY um HH:MM` for older last-seen.
  final String lastSeenDatePrefix;
}

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _ddmmyyyy(DateTime t) =>
    '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';

/// Formats a presence into a human-readable label, or null when there is
/// nothing meaningful to show. [now] is injected for testability.
String? formatPresenceLabel(
  ChatPresence? presence, {
  required DateTime now,
  PresenceLabels labels = const PresenceLabels(),
}) {
  if (presence == null) return null;
  if (presence.customLabel != null) return presence.customLabel;
  if (presence.state == PresenceState.online) return labels.online;

  final seen = presence.lastSeen;
  if (seen == null) return null;

  final today = DateTime(now.year, now.month, now.day);
  final seenDay = DateTime(seen.year, seen.month, seen.day);
  final daysAgo = today.difference(seenDay).inDays;

  if (daysAgo == 0) return '${labels.lastSeenTodayPrefix}${_hhmm(seen)}';
  if (daysAgo == 1) return '${labels.lastSeenYesterdayPrefix}${_hhmm(seen)}';
  return '${labels.lastSeenDatePrefix}${_ddmmyyyy(seen)} um ${_hhmm(seen)}';
}
```

Add to `lib/kreiseck_chat.dart`:
```dart
export 'src/presence_label.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presence_label_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/src/presence_label.dart lib/kreiseck_chat.dart test/presence_label_test.dart
git commit -m "Presence-Label-Formatierung ('zuletzt gesehen') ergänzen"
```

---

## Task 8: TypingIndicator & DateSeparator widgets

**Files:**
- Create: `lib/src/typing_indicator.dart`, `lib/src/date_separator.dart`
- Test: `test/typing_indicator_test.dart`

**Interfaces:**
- Consumes: `ChatTheme` (Task 5).
- Produces:
  - `TypingIndicator({Key?, required ChatTheme theme})` — a StatefulWidget with
    a repeating three-dot animation.
  - `DateSeparator({Key?, required DateTime date, required ChatTheme theme,
    DateTime? now, String Function(DateTime, DateTime?)? labelBuilder})` —
    renders a centered pill; default label is "Heute"/"Gestern"/`DD.MM.YYYY`.

- [ ] **Step 1: Write the failing test**

`test/typing_indicator_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  testWidgets('TypingIndicator renders three dots and animates', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: TypingIndicator(theme: ChatTheme.light())),
    ));
    expect(find.byType(TypingIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    // Does not throw while animating; dispose cleanly.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('DateSeparator shows "Heute" for today', (tester) async {
    final now = DateTime(2026, 7, 21, 12);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DateSeparator(
          date: DateTime(2026, 7, 21),
          theme: const ChatTheme.light(),
          now: now,
        ),
      ),
    ));
    expect(find.text('Heute'), findsOneWidget);
  });

  testWidgets('DateSeparator shows "Gestern"', (tester) async {
    final now = DateTime(2026, 7, 21, 12);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DateSeparator(
          date: DateTime(2026, 7, 20),
          theme: const ChatTheme.light(),
          now: now,
        ),
      ),
    ));
    expect(find.text('Gestern'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/typing_indicator_test.dart`
Expected: FAIL — widgets undefined.

- [ ] **Step 3: Write minimal implementation**

`lib/src/typing_indicator.dart`:
```dart
import 'package:flutter/material.dart';

import 'chat_theme.dart';

/// An animated three-dot "typing…" bubble rendered in the incoming style.
class TypingIndicator extends StatefulWidget {
  /// Creates a typing indicator.
  const TypingIndicator({super.key, required this.theme});

  /// Visual configuration.
  final ChatTheme theme;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.theme.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.incomingBubble,
          borderRadius: BorderRadius.circular(widget.theme.bubbleRadius),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (_controller.value + i * 0.2) % 1.0;
                final opacity = 0.3 + 0.7 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colors.typingDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
```

`lib/src/date_separator.dart`:
```dart
import 'package:flutter/material.dart';

import 'chat_theme.dart';

/// A centered day-boundary pill ("Heute" / "Gestern" / date).
class DateSeparator extends StatelessWidget {
  /// Creates a date separator.
  const DateSeparator({
    super.key,
    required this.date,
    required this.theme,
    this.now,
    this.labelBuilder,
  });

  /// The day this separator introduces (date-only).
  final DateTime date;

  /// Visual configuration.
  final ChatTheme theme;

  /// Injectable "now" for testability; defaults to [DateTime.now].
  final DateTime? now;

  /// Optional custom label builder `(date, now) -> String`.
  final String Function(DateTime date, DateTime? now)? labelBuilder;

  String _defaultLabel(DateTime d, DateTime ref) {
    final today = DateTime(ref.year, ref.month, ref.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Heute';
    if (diff == 1) return 'Gestern';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ref = now ?? DateTime.now();
    final label =
        labelBuilder?.call(date, now) ?? _defaultLabel(date, ref);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: theme.colors.dateSeparatorBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: theme.typography.dateSeparator
              .copyWith(color: theme.colors.dateSeparatorText),
        ),
      ),
    );
  }
}
```

Add to `lib/kreiseck_chat.dart`:
```dart
export 'src/date_separator.dart';
export 'src/typing_indicator.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/typing_indicator_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/src/typing_indicator.dart lib/src/date_separator.dart lib/kreiseck_chat.dart test/typing_indicator_test.dart
git commit -m "TypingIndicator- und DateSeparator-Widgets ergänzen"
```

---

## Task 9: MessageBubble rewrite (presets, grouping, reply, media, reactions, gating, animation)

**Files:**
- Create: `lib/src/bubble_tail_painter.dart`
- Modify: `lib/src/message_bubble.dart`
- Test: `test/message_bubble_test.dart`

**Interfaces:**
- Consumes: `ChatMessage`, `MessageStatus`, `MessageDirection` (Task 4),
  `ChatTheme`, `BubbleStyle` (Task 5), `ChatCapabilities` (Task 1),
  `ChatAttachment`/`AttachmentKind` (Task 3), `MessageReaction` (Task 3).
- Produces:
  - `BubbleTailPainter({required Color color, required bool isOutgoing})`
    (a `CustomPainter`).
  - `MessageBubble({Key?, required ChatMessage message, ChatTheme theme =
    const ChatTheme.light(), ChatCapabilities capabilities = const
    ChatCapabilities.inApp(), bool isFirstInGroup = true, bool isLastInGroup =
    true, bool animateIn = false, void Function()? onReplyRequested, void
    Function(String emoji)? onReact, void Function(ChatAttachment)?
    onOpenAttachment})`.

Behavior:
- Status icon: when `!capabilities.readReceipts` and status is `read`, render as
  `delivered` (double check, no accent).
- Reactions row only when `capabilities.reactions` && reactions non-empty.
- Reply quote block only when `message.replyTo != null` && `capabilities.replies`.
- Attach thumbnails for image attachments; file chip otherwise; only when
  `capabilities.media`.
- Long-press opens a minimal action sheet (reply / react) — actions gated by
  capabilities; fire callbacks. Horizontal drag past threshold →
  `onReplyRequested` when `capabilities.replies`.
- `animateIn` && `theme.motion.bubbleEntrance` → fade+slide entrance.
- Tail drawn (via `BubbleTailPainter`) only for `whatsApp`/`iMessage` styles and
  only when `isLastInGroup`.

- [ ] **Step 1: Write the failing test**

`test/message_bubble_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

ChatMessage _out(String text, {MessageStatus status = MessageStatus.read}) {
  return ChatMessage(
    id: 't',
    direction: MessageDirection.outgoing,
    text: text,
    at: DateTime(2026, 7, 21, 14, 32),
    status: status,
  );
}

void main() {
  testWidgets('renders text and time', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MessageBubble(message: _out('hallo'))),
    ));
    expect(find.text('hallo'), findsOneWidget);
    expect(find.text('14:32'), findsOneWidget);
  });

  testWidgets('reactions hidden when capability off', (tester) async {
    final msg = _out('x').copyWith(
      reactions: const [MessageReaction(emoji: '👍', count: 2)],
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: msg,
          capabilities: const ChatCapabilities.twilioSms(),
        ),
      ),
    ));
    expect(find.text('👍'), findsNothing);
  });

  testWidgets('reactions shown when capability on', (tester) async {
    final msg = _out('x').copyWith(
      reactions: const [MessageReaction(emoji: '👍', count: 2)],
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: msg,
          capabilities: const ChatCapabilities.inApp(),
        ),
      ),
    ));
    expect(find.text('👍'), findsOneWidget);
  });

  testWidgets('read receipt capped at delivered when readReceipts off',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: _out('x', status: MessageStatus.read),
          capabilities: const ChatCapabilities.twilioSms(),
          theme: const ChatTheme.light(),
        ),
      ),
    ));
    // The read icon uses accentColor; when capped it must not be the accent.
    final icon = tester.widget<Icon>(find.byType(Icon).last);
    expect(icon.color, isNot(const ChatTheme.light().accentColor));
  });

  testWidgets('reply quote shown when present and replies enabled',
      (tester) async {
    final msg = _out('reply body').copyWith(
      replyTo: const ChatMessageRef(id: 'p', snippet: 'quoted text', senderLabel: 'Ada'),
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: msg,
          capabilities: const ChatCapabilities.inApp(),
        ),
      ),
    ));
    expect(find.text('quoted text'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/message_bubble_test.dart`
Expected: FAIL — new `MessageBubble` API / fields not present.

- [ ] **Step 3: Write minimal implementation**

`lib/src/bubble_tail_painter.dart`:
```dart
import 'package:flutter/material.dart';

/// Paints a small speech-bubble tail on the bottom edge of a bubble.
class BubbleTailPainter extends CustomPainter {
  /// Creates a tail painter.
  const BubbleTailPainter({required this.color, required this.isOutgoing});

  /// Tail fill color (match the bubble).
  final Color color;

  /// Whether the tail points to the right (outgoing) or left (incoming).
  final bool isOutgoing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    if (isOutgoing) {
      path.moveTo(0, 0);
      path.quadraticBezierTo(size.width, 0, size.width, size.height);
      path.quadraticBezierTo(size.width * 0.4, size.height * 0.4, 0, 0);
    } else {
      path.moveTo(size.width, 0);
      path.quadraticBezierTo(0, 0, 0, size.height);
      path.quadraticBezierTo(size.width * 0.6, size.height * 0.4, size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BubbleTailPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isOutgoing != isOutgoing;
}
```

Replace `lib/src/message_bubble.dart`:
```dart
import 'package:flutter/material.dart';

import 'bubble_style.dart';
import 'chat_attachment.dart';
import 'chat_capabilities.dart';
import 'chat_theme.dart';
import 'models.dart';

/// Renders a single [ChatMessage] as a chat bubble, honoring the theme's
/// [BubbleStyle], the [ChatCapabilities], and grouping flags.
class MessageBubble extends StatelessWidget {
  /// Creates a message bubble.
  const MessageBubble({
    super.key,
    required this.message,
    this.theme = const ChatTheme.light(),
    this.capabilities = const ChatCapabilities.inApp(),
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.animateIn = false,
    this.onReplyRequested,
    this.onReact,
    this.onOpenAttachment,
  });

  /// The message to render.
  final ChatMessage message;

  /// Visual configuration.
  final ChatTheme theme;

  /// Which affordances are allowed.
  final ChatCapabilities capabilities;

  /// First message of its group (shows sender avatar/name in group threads).
  final bool isFirstInGroup;

  /// Last message of its group (shows tail + timestamp).
  final bool isLastInGroup;

  /// Whether to run the entrance animation (also gated by motion config).
  final bool animateIn;

  /// Called when the user requests to reply to this message.
  final void Function()? onReplyRequested;

  /// Called with an emoji when the user reacts.
  final void Function(String emoji)? onReact;

  /// Called when the user taps an attachment.
  final void Function(ChatAttachment attachment)? onOpenAttachment;

  bool get _isOutgoing => message.direction == MessageDirection.outgoing;

  MessageStatus get _effectiveStatus {
    if (!capabilities.readReceipts && message.status == MessageStatus.read) {
      return MessageStatus.delivered;
    }
    return message.status;
  }

  void _openActions(BuildContext context) {
    if (theme.motion.hapticsEnabled && theme.motion.hapticOnLongPress) {
      // Haptic handled by the gesture; kept minimal to avoid platform calls in tests.
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              if (capabilities.reactions)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: ['👍', '❤️', '😂', '😮', '😢']
                        .map((e) => Expanded(
                              child: IconButton(
                                icon: Text(e, style: const TextStyle(fontSize: 24)),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  onReact?.call(e);
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),
              if (capabilities.replies)
                ListTile(
                  leading: Icon(theme.icons.reply),
                  title: const Text('Antworten'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onReplyRequested?.call();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    final bubbleColor =
        _isOutgoing ? colors.outgoingBubble : colors.incomingBubble;
    final textColor = _isOutgoing ? colors.outgoingText : colors.incomingText;

    Widget bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: _borderRadius(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.replyTo != null && capabilities.replies)
            _ReplyQuote(refText: message.replyTo!, theme: theme),
          if (capabilities.media && message.attachments.isNotEmpty)
            _Attachments(
              attachments: message.attachments,
              onOpen: onOpenAttachment,
            ),
          if (message.text.isNotEmpty)
            Text(message.text, style: theme.typography.body.copyWith(color: textColor)),
          const SizedBox(height: 4),
          _MetaRow(
            time: _formatTime(message.at),
            isOutgoing: _isOutgoing,
            showStatus: _isOutgoing && isLastInGroup,
            status: _effectiveStatus,
            theme: theme,
            textColor: textColor,
          ),
        ],
      ),
    );

    Widget content = Column(
      crossAxisAlignment:
          _isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        bubble,
        if (capabilities.reactions && message.reactions.isNotEmpty)
          _Reactions(reactions: message.reactions, theme: theme),
      ],
    );

    content = GestureDetector(
      onLongPress: (capabilities.reactions || capabilities.replies)
          ? () => _openActions(context)
          : null,
      onHorizontalDragEnd: capabilities.replies
          ? (details) {
              final v = details.primaryVelocity ?? 0;
              if ((_isOutgoing && v < -200) || (!_isOutgoing && v > 200)) {
                onReplyRequested?.call();
              }
            }
          : null,
      child: content,
    );

    final aligned = Align(
      alignment: _isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: isFirstInGroup ? 6 : 2,
          bottom: 2,
        ),
        child: content,
      ),
    );

    if (animateIn && theme.motion.bubbleEntrance) {
      return _EntranceAnimation(
        duration: theme.motion.bubbleEntranceDuration,
        curve: theme.motion.entranceCurve,
        isOutgoing: _isOutgoing,
        child: aligned,
      );
    }
    return aligned;
  }

  BorderRadius _borderRadius() {
    final r = theme.bubbleRadius;
    if (theme.bubbleStyle == BubbleStyle.minimal) {
      return BorderRadius.circular(r);
    }
    const small = Radius.circular(5);
    final big = Radius.circular(r);
    // Tighten the corner nearest the tail when it is the last in the group.
    if (_isOutgoing) {
      return BorderRadius.only(
        topLeft: big,
        topRight: big,
        bottomLeft: big,
        bottomRight: isLastInGroup ? small : big,
      );
    }
    return BorderRadius.only(
      topLeft: big,
      topRight: big,
      bottomLeft: isLastInGroup ? small : big,
      bottomRight: big,
    );
  }
}

class _EntranceAnimation extends StatefulWidget {
  const _EntranceAnimation({
    required this.child,
    required this.duration,
    required this.curve,
    required this.isOutgoing,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool isOutgoing;

  @override
  State<_EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<_EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: widget.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(widget.isOutgoing ? 0.15 : -0.15, 0.1),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}

class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({required this.refText, required this.theme});

  final ChatMessageRef refText;
  final ChatTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colors.replyAccent, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (refText.senderLabel != null)
            Text(refText.senderLabel!,
                style: theme.typography.senderName
                    .copyWith(color: theme.colors.replyAccent)),
          Text(refText.snippet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.replyQuote),
        ],
      ),
    );
  }
}

class _Attachments extends StatelessWidget {
  const _Attachments({required this.attachments, required this.onOpen});

  final List<ChatAttachment> attachments;
  final void Function(ChatAttachment)? onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: attachments.map((a) {
        final provider = a.thumbnail ??
            (a.thumbnailUrl != null ? NetworkImage(a.thumbnailUrl!) : null);
        final isImage = a.kind == AttachmentKind.image && provider != null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GestureDetector(
            onTap: onOpen == null ? null : () => onOpen!(a),
            child: isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image(
                      image: provider,
                      width: 200,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, size: 20),
                      const SizedBox(width: 6),
                      Text(a.fileName ?? 'Datei'),
                    ],
                  ),
          ),
        );
      }).toList(),
    );
  }
}

class _Reactions extends StatelessWidget {
  const _Reactions({required this.reactions, required this.theme});

  final List<MessageReaction> reactions;
  final ChatTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: 4,
        children: reactions.map((r) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colors.reactionChipBackground,
              borderRadius: BorderRadius.circular(12),
              border: r.reactedByMe
                  ? Border.all(color: theme.colors.accent, width: 1)
                  : null,
            ),
            child: Text(
              r.count > 1 ? '${r.emoji} ${r.count}' : r.emoji,
              style: theme.typography.timestamp
                  .copyWith(color: theme.colors.reactionChipText),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.time,
    required this.isOutgoing,
    required this.showStatus,
    required this.status,
    required this.theme,
    required this.textColor,
  });

  final String time;
  final bool isOutgoing;
  final bool showStatus;
  final MessageStatus status;
  final ChatTheme theme;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          time,
          style: theme.typography.timestamp
              .copyWith(color: textColor.withValues(alpha: 0.7)),
        ),
        if (showStatus) ...[
          const SizedBox(width: 4),
          _StatusIcon(status: status, color: textColor, theme: theme),
        ],
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.status,
    required this.color,
    required this.theme,
  });

  final MessageStatus status;
  final Color color;
  final ChatTheme theme;

  @override
  Widget build(BuildContext context) {
    final icons = theme.icons;
    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: 12, color: color.withValues(alpha: 0.7));
      case MessageStatus.sent:
        return Icon(icons.sent, size: 14, color: color.withValues(alpha: 0.7));
      case MessageStatus.delivered:
        return Icon(icons.delivered, size: 14, color: color.withValues(alpha: 0.7));
      case MessageStatus.read:
        return Icon(icons.read, size: 14, color: theme.colors.accent);
      case MessageStatus.failed:
        return Icon(icons.error, size: 14, color: Colors.red);
    }
  }
}

String _formatTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
```

Add to `lib/kreiseck_chat.dart`:
```dart
export 'src/bubble_tail_painter.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/message_bubble_test.dart`
Expected: PASS (5 tests). Also run `flutter test` — all green.

- [ ] **Step 5: Commit**

```bash
git add lib/src/message_bubble.dart lib/src/bubble_tail_painter.dart lib/kreiseck_chat.dart test/message_bubble_test.dart
git commit -m "MessageBubble neu: Presets, Gruppierung, Reply, Medien, Reaktionen, Capability-Gating"
```

---

## Task 10: ChatHeader widget

**Files:**
- Create: `lib/src/chat_header.dart`
- Test: `test/chat_header_test.dart`

**Interfaces:**
- Consumes: `ChatParticipant`, `ChatPresence` (Task 2), `ChatTheme` (Task 5),
  `ChatCapabilities` (Task 1), `formatPresenceLabel` (Task 7).
- Produces:
  - `ChatHeader({Key?, required String title, ImageProvider? avatar, String?
    avatarUrl, ChatPresence? presence, bool typing = false, required ChatTheme
    theme, ChatCapabilities capabilities = const ChatCapabilities.inApp(),
    DateTime? now, List<Widget> actions = const [], VoidCallback? onBack})`.
- Behavior: subtitle shows "tippt…" when `typing && capabilities.typingIndicator`;
  else the presence label when `capabilities.presence`; else nothing. Avatar is
  an image or an initials monogram.

- [ ] **Step 1: Write the failing test**

`test/chat_header_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  testWidgets('shows title and presence label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatHeader(
          title: 'Ada',
          presence: const ChatPresence.online(),
          theme: const ChatTheme.light(),
          now: DateTime(2026, 7, 21, 15),
        ),
      ),
    ));
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
  });

  testWidgets('typing overrides presence when enabled', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatHeader(
          title: 'Ada',
          presence: const ChatPresence.online(),
          typing: true,
          theme: const ChatTheme.light(),
          now: DateTime(2026, 7, 21, 15),
        ),
      ),
    ));
    expect(find.text('tippt…'), findsOneWidget);
    expect(find.text('Online'), findsNothing);
  });

  testWidgets('presence hidden when capability off', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatHeader(
          title: 'Ada',
          presence: const ChatPresence.online(),
          capabilities: const ChatCapabilities.twilioSms(),
          theme: const ChatTheme.light(),
          now: DateTime(2026, 7, 21, 15),
        ),
      ),
    ));
    expect(find.text('Online'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/chat_header_test.dart`
Expected: FAIL — `ChatHeader` undefined.

- [ ] **Step 3: Write minimal implementation**

`lib/src/chat_header.dart`:
```dart
import 'package:flutter/material.dart';

import 'chat_capabilities.dart';
import 'chat_participant.dart';
import 'chat_theme.dart';
import 'presence_label.dart';

/// A conversation header: avatar + title + presence/typing subtitle + actions.
class ChatHeader extends StatelessWidget {
  /// Creates a header.
  const ChatHeader({
    super.key,
    required this.title,
    required this.theme,
    this.avatar,
    this.avatarUrl,
    this.presence,
    this.typing = false,
    this.capabilities = const ChatCapabilities.inApp(),
    this.now,
    this.actions = const [],
    this.onBack,
    this.typingLabel = 'tippt…',
  });

  /// Contact/group name.
  final String title;

  /// Visual configuration.
  final ChatTheme theme;

  /// In-memory avatar; wins over [avatarUrl].
  final ImageProvider? avatar;

  /// Remote avatar URL.
  final String? avatarUrl;

  /// Presence for the subtitle.
  final ChatPresence? presence;

  /// Whether the counterpart is typing.
  final bool typing;

  /// Which affordances are allowed.
  final ChatCapabilities capabilities;

  /// Injectable "now" for presence formatting.
  final DateTime? now;

  /// Trailing action widgets.
  final List<Widget> actions;

  /// Optional back handler (renders a back button when set).
  final VoidCallback? onBack;

  /// Label shown while typing.
  final String typingLabel;

  String? _subtitle() {
    if (typing && capabilities.typingIndicator) return typingLabel;
    if (capabilities.presence) {
      return formatPresenceLabel(presence, now: now ?? DateTime.now());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitle();
    final provider =
        avatar ?? (avatarUrl != null ? NetworkImage(avatarUrl!) : null);
    return Material(
      color: theme.colors.composer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                ),
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colors.accent.withValues(alpha: 0.2),
                backgroundImage: provider,
                child: provider == null
                    ? Text(
                        ChatParticipant(id: title, displayName: title).initials,
                        style: TextStyle(color: theme.colors.accent),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: theme.typography.headerTitle
                            .copyWith(color: theme.colors.incomingText)),
                    if (subtitle != null)
                      Text(subtitle,
                          style: theme.typography.headerSubtitle.copyWith(
                              color: theme.colors.incomingText
                                  .withValues(alpha: 0.6))),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
```

Add to `lib/kreiseck_chat.dart`:
```dart
export 'src/chat_header.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/chat_header_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/src/chat_header.dart lib/kreiseck_chat.dart test/chat_header_test.dart
git commit -m "ChatHeader mit Avatar, Presence- und Tipp-Zeile ergänzen"
```

---

## Task 11: Composer rewrite (attach gating, typing callback, send haptic)

**Files:**
- Modify: `lib/src/composer.dart`
- Test: `test/composer_test.dart`

**Interfaces:**
- Consumes: `ChatTheme` (Task 5), `ChatCapabilities` (Task 1).
- Produces:
  - `enum AttachSource { gallery, camera, file }`
  - `Composer({Key?, required void Function(String) onSend, String? hintText,
    ChatTheme theme = const ChatTheme.light(), ChatCapabilities capabilities =
    const ChatCapabilities.inApp(), void Function(AttachSource)? onAttach, void
    Function(bool isTyping)? onTypingChanged, bool showMic = false})`.
- Behavior: attach button visible only when `capabilities.media`; tapping it
  opens a small source menu → `onAttach`. `onTypingChanged(true)` fires on first
  non-empty keystroke, `(false)` when the field empties or on send. Send fires a
  light haptic when `theme.motion.hapticsEnabled && hapticOnSend`.

- [ ] **Step 1: Write the failing test**

`test/composer_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  testWidgets('attach button hidden when media capability off', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Composer(
          onSend: (_) {},
          capabilities: const ChatCapabilities.twilioSms(),
        ),
      ),
    ));
    expect(find.byIcon(const ChatIcons().attach), findsNothing);
  });

  testWidgets('attach button shown when media capability on', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Composer(
          onSend: (_) {},
          capabilities: const ChatCapabilities.inApp(),
          onAttach: (_) {},
        ),
      ),
    ));
    expect(find.byIcon(const ChatIcons().attach), findsOneWidget);
  });

  testWidgets('send clears field and calls onSend', (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Composer(onSend: sent.add)),
    ));
    await tester.enterText(find.byType(TextField), 'hallo');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(sent, ['hallo']);
    expect(find.text('hallo'), findsNothing);
  });

  testWidgets('onTypingChanged fires true then false', (tester) async {
    final events = <bool>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Composer(onSend: (_) {}, onTypingChanged: events.add)),
    ));
    await tester.enterText(find.byType(TextField), 'h');
    await tester.enterText(find.byType(TextField), '');
    expect(events.first, isTrue);
    expect(events.last, isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/composer_test.dart`
Expected: FAIL — new `Composer` API not present.

- [ ] **Step 3: Write minimal implementation**

Replace `lib/src/composer.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chat_capabilities.dart';
import 'chat_theme.dart';

/// Where an attachment comes from.
enum AttachSource { gallery, camera, file }

/// A message composer: attach button (gated), auto-growing text field, and a
/// send button. Emits typing changes and fires a send haptic per the theme.
class Composer extends StatefulWidget {
  /// Creates a composer.
  const Composer({
    super.key,
    required this.onSend,
    this.hintText,
    this.theme = const ChatTheme.light(),
    this.capabilities = const ChatCapabilities.inApp(),
    this.onAttach,
    this.onTypingChanged,
    this.showMic = false,
  });

  /// Called with the trimmed message text on submit.
  final void Function(String) onSend;

  /// Placeholder text.
  final String? hintText;

  /// Visual configuration.
  final ChatTheme theme;

  /// Which affordances are allowed.
  final ChatCapabilities capabilities;

  /// Called with a chosen source when the user taps attach.
  final void Function(AttachSource source)? onAttach;

  /// Called when typing starts (true) or stops (false).
  final void Function(bool isTyping)? onTypingChanged;

  /// Whether to show a (placeholder) mic button when the field is empty.
  final bool showMic;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  late final TextEditingController _controller;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final typing = _controller.text.trim().isNotEmpty;
    if (typing != _isTyping) {
      _isTyping = typing;
      widget.onTypingChanged?.call(typing);
    }
    setState(() {});
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final motion = widget.theme.motion;
    if (motion.hapticsEnabled && motion.hapticOnSend) {
      HapticFeedback.lightImpact();
    }
    widget.onSend(text);
    _controller.clear();
  }

  void _openAttachMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(widget.theme.icons.camera),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.of(ctx).pop();
                widget.onAttach?.call(AttachSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () {
                Navigator.of(ctx).pop();
                widget.onAttach?.call(AttachSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(widget.theme.icons.attach),
              title: const Text('Datei'),
              onTap: () {
                Navigator.of(ctx).pop();
                widget.onAttach?.call(AttachSource.file);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final hasText = _controller.text.trim().isNotEmpty;
    return Material(
      color: theme.colors.composer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.capabilities.media)
                IconButton(
                  icon: Icon(theme.icons.attach, color: theme.colors.accent),
                  onPressed: _openAttachMenu,
                ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Nachricht',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (hasText || !widget.showMic)
                IconButton(
                  icon: Icon(theme.icons.send, color: theme.colors.accent),
                  onPressed: _submit,
                )
              else
                IconButton(
                  icon: Icon(theme.icons.mic, color: theme.colors.accent),
                  onPressed: null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/composer_test.dart`
Expected: PASS (4 tests). Note: `HapticFeedback` is a no-op platform channel
under the test binding and does not throw.

- [ ] **Step 5: Commit**

```bash
git add lib/src/composer.dart test/composer_test.dart
git commit -m "Composer neu: Anhang-Gating, Typing-Callback, Sende-Haptik"
```

---

## Task 12: ChatThreadView rewrite (orchestration)

**Files:**
- Modify: `lib/src/chat_thread_view.dart`
- Test: `test/chat_thread_view_test.dart`

**Interfaces:**
- Consumes: `ChatMessage` (Task 4), `ChatTheme` (Task 5), `ChatCapabilities`
  (Task 1), `TypingState` (Task 4), `buildThreadItems`/`MessageItem`/
  `DateSeparatorItem` (Task 6), `MessageBubble` (Task 9), `TypingIndicator`/
  `DateSeparator` (Task 8), `Composer`/`AttachSource` (Task 11),
  `ChatAttachment` (Task 3).
- Produces:
  - `ChatThreadView({Key?, required List<ChatMessage> messages, required void
    Function(String) onSend, ChatTheme theme = const ChatTheme.light(),
    ChatCapabilities capabilities = const ChatCapabilities.inApp(), TypingState
    typing = const TypingState(), String? hintText, DateTime? now, void
    Function(AttachSource)? onAttach, void Function(bool)? onTypingChanged, void
    Function(String messageId)? onReplyRequested, void Function(String
    messageId, String emoji)? onReact, void Function(ChatAttachment)?
    onOpenAttachment, Future<void> Function()? onLoadEarlier, Widget? header})`.
- Behavior: builds thread items, renders date separators + grouped bubbles,
  appends a `TypingIndicator` when `typing.anyoneTyping && capabilities
  .typingIndicator`, auto-scrolls to bottom on new messages (animated per
  motion), calls `onLoadEarlier` when scrolled to top.

- [ ] **Step 1: Write the failing test**

`test/chat_thread_view_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

List<ChatMessage> _seed() => [
      ChatMessage(
          id: '1',
          direction: MessageDirection.incoming,
          text: 'Hallo',
          at: DateTime(2026, 7, 21, 9, 0)),
      ChatMessage(
          id: '2',
          direction: MessageDirection.outgoing,
          text: 'Servus',
          at: DateTime(2026, 7, 21, 9, 1)),
    ];

void main() {
  testWidgets('renders messages and a date separator', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: _seed(),
          onSend: (_) {},
          now: DateTime(2026, 7, 21, 10),
        ),
      ),
    ));
    expect(find.text('Hallo'), findsOneWidget);
    expect(find.text('Servus'), findsOneWidget);
    expect(find.byType(DateSeparator), findsOneWidget);
  });

  testWidgets('shows typing indicator when enabled and typing', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: _seed(),
          onSend: (_) {},
          capabilities: const ChatCapabilities.inApp(),
          typing: const TypingState(
              participants: [ChatParticipant(id: 'a', displayName: 'Ada')]),
          now: DateTime(2026, 7, 21, 10),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byType(TypingIndicator), findsOneWidget);
  });

  testWidgets('no typing indicator when capability off', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: _seed(),
          onSend: (_) {},
          capabilities: const ChatCapabilities.twilioSms(),
          typing: const TypingState(
              participants: [ChatParticipant(id: 'a', displayName: 'Ada')]),
          now: DateTime(2026, 7, 21, 10),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byType(TypingIndicator), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/chat_thread_view_test.dart`
Expected: FAIL — new `ChatThreadView` API not present.

- [ ] **Step 3: Write minimal implementation**

Replace `lib/src/chat_thread_view.dart`:
```dart
import 'package:flutter/material.dart';

import 'chat_attachment.dart';
import 'chat_capabilities.dart';
import 'chat_theme.dart';
import 'composer.dart';
import 'date_separator.dart';
import 'message_bubble.dart';
import 'models.dart';
import 'thread_items.dart';
import 'typing_indicator.dart';

/// A scrollable message thread plus a composer. Groups messages, inserts date
/// separators, shows a typing indicator, and auto-scrolls to the newest message.
class ChatThreadView extends StatefulWidget {
  /// Creates a thread view.
  const ChatThreadView({
    super.key,
    required this.messages,
    required this.onSend,
    this.theme = const ChatTheme.light(),
    this.capabilities = const ChatCapabilities.inApp(),
    this.typing = const TypingState(),
    this.hintText,
    this.now,
    this.onAttach,
    this.onTypingChanged,
    this.onReplyRequested,
    this.onReact,
    this.onOpenAttachment,
    this.onLoadEarlier,
    this.header,
  });

  /// Messages, oldest first.
  final List<ChatMessage> messages;

  /// Called with text when the user sends.
  final void Function(String) onSend;

  /// Visual configuration.
  final ChatTheme theme;

  /// Which affordances are allowed.
  final ChatCapabilities capabilities;

  /// Who is currently typing.
  final TypingState typing;

  /// Composer placeholder.
  final String? hintText;

  /// Injectable "now" for date separators.
  final DateTime? now;

  /// Called with an attachment source.
  final void Function(AttachSource source)? onAttach;

  /// Called on typing start/stop.
  final void Function(bool isTyping)? onTypingChanged;

  /// Called with a message id when a reply is requested.
  final void Function(String messageId)? onReplyRequested;

  /// Called with a message id + emoji on reaction.
  final void Function(String messageId, String emoji)? onReact;

  /// Called when an attachment is tapped.
  final void Function(ChatAttachment attachment)? onOpenAttachment;

  /// Called when the user scrolls to the top to load older history.
  final Future<void> Function()? onLoadEarlier;

  /// Optional header widget above the list.
  final Widget? header;

  @override
  State<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<ChatThreadView> {
  final ScrollController _scroll = ScrollController();
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _lastCount = widget.messages.length;
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  @override
  void didUpdateWidget(covariant ChatThreadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != _lastCount) {
      _lastCount = widget.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels <= 8 && widget.onLoadEarlier != null) {
      widget.onLoadEarlier!();
    }
  }

  void _jumpToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    final target = _scroll.position.maxScrollExtent;
    if (widget.theme.motion.animatedAutoScroll) {
      _scroll.animateTo(
        target,
        duration: widget.theme.motion.autoScrollDuration,
        curve: Curves.easeOut,
      );
    } else {
      _scroll.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = buildThreadItems(widget.messages);
    final showTyping =
        widget.typing.anyoneTyping && widget.capabilities.typingIndicator;
    final childCount = items.length + (showTyping ? 1 : 0);

    return Container(
      color: widget.theme.colors.background,
      child: Column(
        children: [
          if (widget.header != null) widget.header!,
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: childCount,
              itemBuilder: (context, index) {
                if (showTyping && index == items.length) {
                  return TypingIndicator(theme: widget.theme);
                }
                final item = items[index];
                if (item is DateSeparatorItem) {
                  return DateSeparator(
                    date: item.date,
                    theme: widget.theme,
                    now: widget.now,
                  );
                }
                final mi = item as MessageItem;
                return MessageBubble(
                  message: mi.message,
                  theme: widget.theme,
                  capabilities: widget.capabilities,
                  isFirstInGroup: mi.isFirstInGroup,
                  isLastInGroup: mi.isLastInGroup,
                  animateIn: index >= items.length - 1,
                  onReplyRequested: widget.onReplyRequested == null
                      ? null
                      : () => widget.onReplyRequested!(mi.message.id),
                  onReact: widget.onReact == null
                      ? null
                      : (emoji) => widget.onReact!(mi.message.id, emoji),
                  onOpenAttachment: widget.onOpenAttachment,
                );
              },
            ),
          ),
          Composer(
            onSend: widget.onSend,
            hintText: widget.hintText,
            theme: widget.theme,
            capabilities: widget.capabilities,
            onAttach: widget.onAttach,
            onTypingChanged: widget.onTypingChanged,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/chat_thread_view_test.dart`
Expected: PASS (3 tests). Then `flutter test` — all green.

- [ ] **Step 5: Commit**

```bash
git add lib/src/chat_thread_view.dart test/chat_thread_view_test.dart
git commit -m "ChatThreadView neu: Gruppierung, Datums-Trenner, Typing, Auto-Scroll"
```

---

## Task 13: ConversationListView rewrite (avatar, presence dot, typing, badges)

**Files:**
- Modify: `lib/src/conversation_list_view.dart`
- Test: `test/conversation_list_view_test.dart`

**Interfaces:**
- Consumes: `ChatConversation` (Task 4), `ChatTheme` (Task 5),
  `ChatCapabilities` (Task 1), `ChatParticipant` (for initials, Task 2).
- Produces:
  - `ConversationListView({Key?, required List<ChatConversation> conversations,
    required void Function(ChatConversation) onOpen, ChatTheme theme = const
    ChatTheme.light(), ChatCapabilities capabilities = const
    ChatCapabilities.inApp(), String typingLabel = 'tippt…'})`.
- Behavior: each tile shows avatar (image or initials) with an online dot when
  `capabilities.presence` and presence is online; unread badge; muted/pinned
  icons; preview shows `typingLabel` when `conversation.typing &&
  capabilities.typingIndicator`, else `lastText`.

- [ ] **Step 1: Write the failing test**

`test/conversation_list_view_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  testWidgets('renders title and last text; tap opens', (tester) async {
    ChatConversation? opened;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: [
            ChatConversation(id: 'c1', title: 'Ada', lastText: 'Bis morgen'),
          ],
          onOpen: (c) => opened = c,
        ),
      ),
    ));
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Bis morgen'), findsOneWidget);
    await tester.tap(find.text('Ada'));
    expect(opened?.id, 'c1');
  });

  testWidgets('typing preview overrides last text when enabled', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: const [
            ChatConversation(
                id: 'c1', title: 'Ada', lastText: 'Bis morgen', typing: true),
          ],
          onOpen: (_) {},
          capabilities: const ChatCapabilities.inApp(),
        ),
      ),
    ));
    expect(find.text('tippt…'), findsOneWidget);
    expect(find.text('Bis morgen'), findsNothing);
  });

  testWidgets('unread badge shows count', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: const [
            ChatConversation(id: 'c1', title: 'Ada', unread: 3),
          ],
          onOpen: (_) {},
        ),
      ),
    ));
    expect(find.text('3'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/conversation_list_view_test.dart`
Expected: FAIL — new API not present.

- [ ] **Step 3: Write minimal implementation**

Replace `lib/src/conversation_list_view.dart`:
```dart
import 'package:flutter/material.dart';

import 'chat_capabilities.dart';
import 'chat_participant.dart';
import 'chat_theme.dart';
import 'models.dart';

/// A conversation inbox list with avatars, presence dots, unread badges, and
/// typing previews.
class ConversationListView extends StatelessWidget {
  /// Creates a conversation list.
  const ConversationListView({
    super.key,
    required this.conversations,
    required this.onOpen,
    this.theme = const ChatTheme.light(),
    this.capabilities = const ChatCapabilities.inApp(),
    this.typingLabel = 'tippt…',
  });

  /// Conversations to display.
  final List<ChatConversation> conversations;

  /// Called when a conversation is tapped.
  final void Function(ChatConversation conversation) onOpen;

  /// Visual configuration.
  final ChatTheme theme;

  /// Which affordances are allowed.
  final ChatCapabilities capabilities;

  /// Preview label shown while the counterpart is typing.
  final String typingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colors.background,
      child: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final c = conversations[index];
          return _ConversationTile(
            conversation: c,
            theme: theme,
            capabilities: capabilities,
            typingLabel: typingLabel,
            onTap: () => onOpen(c),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.theme,
    required this.capabilities,
    required this.typingLabel,
    required this.onTap,
  });

  final ChatConversation conversation;
  final ChatTheme theme;
  final ChatCapabilities capabilities;
  final String typingLabel;
  final VoidCallback onTap;

  bool get _online =>
      capabilities.presence &&
      conversation.presence?.state == PresenceState.online;

  bool get _typing =>
      capabilities.typingIndicator && conversation.typing;

  @override
  Widget build(BuildContext context) {
    final provider = conversation.avatar ??
        (conversation.avatarUrl != null
            ? NetworkImage(conversation.avatarUrl!)
            : null);
    final preview = _typing ? typingLabel : (conversation.lastText ?? '');

    return ListTile(
      onTap: onTap,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colors.accent.withValues(alpha: 0.2),
            backgroundImage: provider,
            child: provider == null
                ? Text(
                    ChatParticipant(
                            id: conversation.id, displayName: conversation.title)
                        .initials,
                    style: TextStyle(color: theme.colors.accent),
                  )
                : null,
          ),
          if (_online)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: theme.colors.presenceOnline,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colors.background, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.headerTitle
                  .copyWith(color: theme.colors.incomingText),
            ),
          ),
          if (conversation.pinned)
            Icon(Icons.push_pin, size: 14, color: theme.colors.dateSeparatorText),
          if (conversation.muted)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.volume_off,
                  size: 14, color: theme.colors.dateSeparatorText),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          if (conversation.channelLabel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(conversation.channelLabel!,
                  style: theme.typography.timestamp
                      .copyWith(color: theme.colors.accent)),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.headerSubtitle.copyWith(
                color: _typing
                    ? theme.colors.accent
                    : theme.colors.incomingText.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
      trailing: conversation.unread > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colors.accent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              child: Center(
                child: Text(
                  '${conversation.unread}',
                  style: TextStyle(color: theme.colors.outgoingText, fontSize: 11),
                ),
              ),
            )
          : null,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/conversation_list_view_test.dart`
Expected: PASS (3 tests). Then `flutter test` — all green.

- [ ] **Step 5: Commit**

```bash
git add lib/src/conversation_list_view.dart test/conversation_list_view_test.dart
git commit -m "ConversationListView neu: Avatar, Presence-Punkt, Typing-Vorschau, Badges"
```

---

## Task 14: Example gallery, version bump, docs

**Files:**
- Modify: `example/lib/main.dart`, `pubspec.yaml`, `README.md`, `CHANGELOG.md`
- Test: (none new — manual/visual QA via the example app)

**Interfaces:**
- Consumes: the full public API.

- [ ] **Step 1: Bump the version**

In `pubspec.yaml` change:
```yaml
version: 0.3.0
```

- [ ] **Step 2: Rewrite the example into a gallery**

Replace `example/lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  BubbleStyle _style = BubbleStyle.iMessage;
  ChatCapabilities _caps = const ChatCapabilities.inApp();
  bool _dark = false;
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = _seed();
  }

  List<ChatMessage> _seed() {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: '1',
        direction: MessageDirection.incoming,
        text: 'Servus! Bist du heute noch unterwegs?',
        at: now.subtract(const Duration(minutes: 30)),
        sender: const ChatParticipant(id: 'ada', displayName: 'Ada'),
        reactions: const [MessageReaction(emoji: '👍', count: 1)],
      ),
      ChatMessage(
        id: '2',
        direction: MessageDirection.outgoing,
        text: 'Ja, ab 18 Uhr. Passt das?',
        at: now.subtract(const Duration(minutes: 28)),
        status: MessageStatus.read,
        replyTo: const ChatMessageRef(
            id: '1', snippet: 'Bist du heute noch unterwegs?', senderLabel: 'Ada'),
      ),
    ];
  }

  ChatTheme get _theme {
    final brightness = _dark ? Brightness.dark : Brightness.light;
    switch (_style) {
      case BubbleStyle.whatsApp:
        return ChatTheme.whatsApp(brightness: brightness);
      case BubbleStyle.iMessage:
        return ChatTheme.iMessage(brightness: brightness);
      case BubbleStyle.minimal:
        return _dark ? const ChatTheme.dark() : const ChatTheme.light();
    }
  }

  void _send(String text) {
    setState(() {
      _messages = [
        ..._messages,
        ChatMessage(
          id: '${_messages.length + 1}',
          direction: MessageDirection.outgoing,
          text: text,
          at: DateTime.now(),
          status: MessageStatus.sent,
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(brightness: _dark ? Brightness.dark : Brightness.light),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('kreiseck_chat Demo'),
          actions: [
            IconButton(
              icon: Icon(_dark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => _dark = !_dark),
            ),
          ],
        ),
        body: Column(
          children: [
            _controls(),
            Expanded(
              child: ChatThreadView(
                messages: _messages,
                onSend: _send,
                theme: _theme,
                capabilities: _caps,
                typing: const TypingState(participants: [
                  ChatParticipant(id: 'ada', displayName: 'Ada'),
                ]),
                header: ChatHeader(
                  title: 'Ada',
                  presence: const ChatPresence.online(),
                  theme: _theme,
                  capabilities: _caps,
                ),
                onReplyRequested: (_) {},
                onReact: (_, __) {},
                onAttach: (_) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<BubbleStyle>(
            value: _style,
            items: BubbleStyle.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                .toList(),
            onChanged: (s) => setState(() => _style = s!),
          ),
          DropdownButton<String>(
            value: _capsLabel,
            items: const [
              DropdownMenuItem(value: 'sms', child: Text('Twilio SMS')),
              DropdownMenuItem(value: 'whatsapp', child: Text('Twilio WhatsApp')),
              DropdownMenuItem(value: 'inapp', child: Text('In-App')),
            ],
            onChanged: (v) => setState(() {
              switch (v) {
                case 'sms':
                  _caps = const ChatCapabilities.twilioSms();
                  break;
                case 'whatsapp':
                  _caps = const ChatCapabilities.twilioWhatsApp();
                  break;
                default:
                  _caps = const ChatCapabilities.inApp();
              }
            }),
          ),
        ],
      ),
    );
  }

  String get _capsLabel {
    if (_caps == const ChatCapabilities.twilioSms()) return 'sms';
    if (_caps == const ChatCapabilities.twilioWhatsApp()) return 'whatsapp';
    return 'inapp';
  }
}
```

- [ ] **Step 3: Update README and CHANGELOG**

Prepend to `CHANGELOG.md`:
```markdown
## 0.3.0

* Add `ChatCapabilities` capability profiles (`twilioSms`, `twilioWhatsApp`,
  `inApp`, custom) that gate which affordances widgets render.
* Richer models: `ChatParticipant`, `ChatPresence`, `ChatAttachment`,
  `MessageReaction`, `ChatMessageRef`, `TypingState`; `ChatMessage` gains
  `sender`, typed `attachments`, `replyTo`, `reactions`, and receipt timestamps.
* **Breaking:** `ChatMessage.attachments` is now `List<ChatAttachment>` (was
  `List<String>`).
* Layered `ChatTheme` (`ChatColors`, `ChatTypography`, `ChatIcons`,
  `ChatMotion`, `BubbleStyle`) with `whatsApp`/`iMessage` presets; old flat
  getters preserved.
* New widgets: `TypingIndicator`, `DateSeparator`, `ChatHeader`; rewritten
  `MessageBubble`, `Composer`, `ChatThreadView`, `ConversationListView` with
  grouping, reactions, replies, media, presence, and motion/haptics.
```

Update the README "Features" section to document capabilities, presets, and the
new models (replace the old bullet list with an accurate one; keep the Usage
examples but pass `capabilities:` and a preset `theme:`).

- [ ] **Step 4: Verify the whole suite and analyzer**

Run:
```bash
flutter analyze
flutter test
```
Expected: analyzer clean (no new warnings), all tests pass.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml example/lib/main.dart README.md CHANGELOG.md
git commit -m "Beispiel-Galerie, Version 0.3.0 und Doku aktualisieren"
```

---

## Self-Review

**1. Spec coverage** (each spec §mapped to a task):
- §3 Capabilities → Task 1. ✅
- §4.1 ChatMessage ext → Task 4. §4.2 new types → Tasks 2 (participant/presence),
  3 (attachment/reaction), 4 (ref/typing). §4.3 conversation ext → Task 4. ✅
- §5 layered theme + presets → Task 5. ✅
- §6.1 MessageBubble → Task 9. §6.2 TypingIndicator/DateSeparator → Task 8;
  ChatHeader → Task 10. §6.3 ChatThreadView → Task 12. §6.4 Composer → Task 11.
  §6.5 ConversationListView → Task 13. ✅
- Grouping/date logic (implied by §6.1/§6.3) → Task 6. Presence-label formatting
  (§6.2 header) → Task 7. ✅
- §7 example gallery → Task 14. §8 tests → each task's TDD steps + gating tests
  in Tasks 1/9/11/12/13. §9 versioning/README/CHANGELOG → Task 14. ✅
- §10 deferred items → intentionally NOT tasked (own specs). ✅

**2. Placeholder scan:** No "TBD"/"TODO"/"handle edge cases". The README prose
step in Task 14 says "replace with an accurate list" but the CHANGELOG content
is fully specified; README copy is documentation, acceptable to describe.

**3. Type consistency:** `ChatCapabilities` flag names (`reactions, replies,
media, typingIndicator, presence, readReceipts`) are identical across Tasks 1,
9, 10, 11, 12, 13. `buildThreadItems`/`MessageItem.isFirstInGroup`/
`isLastInGroup` (Task 6) match usage in Task 12. `AttachSource` (Task 11) matches
`onAttach` in Task 12/14. `formatPresenceLabel(presence, {required now, labels})`
(Task 7) matches Task 10 usage. `ChatTheme.colors/.motion/.typography/.icons/
.bubbleStyle/.bubbleRadius` (Task 5) match all widget usages. `withValues(alpha:)`
matches the existing codebase style (already used in the current MessageBubble).

No gaps found.
