import 'package:flutter/widgets.dart';

import 'chat_attachment.dart';
import 'chat_channel.dart';
import 'chat_participant.dart';
import 'chat_reaction.dart';

/// Direction of a chat message relative to the current user.
enum MessageDirection {
  /// Message received from the other side of the conversation.
  incoming,

  /// Message sent by the current user.
  outgoing,
}

/// Delivery/read status of an outgoing message.
enum MessageStatus {
  /// The message is still being sent.
  sending,

  /// The message left the device successfully.
  sent,

  /// The message was delivered to the recipient.
  delivered,

  /// The recipient has read the message.
  read,

  /// Sending the message failed.
  failed,
}

/// The kind of a message — determines how it is rendered.
enum ChatMessageKind {
  /// Regular speech bubble.
  normal,

  /// System notice; rendered centered as a `ChatSystemCard`.
  system,

  /// Built by the app itself; `ChatThreadView.customMessageBuilder` decides
  /// how it is rendered.
  custom,
}

/// A translation of a message's text.
///
/// When set, the bubble becomes tappable to toggle between the original and
/// the translation.
@immutable
class ChatTranslation {
  /// Creates a translation.
  const ChatTranslation({required this.text, required this.languageLabel});

  /// The translated text.
  final String text;

  /// Short language label, e.g. `'UK'` or `'German'`.
  final String languageLabel;

  /// Returns a copy of this translation with the given fields replaced.
  ChatTranslation copyWith({String? text, String? languageLabel}) =>
      ChatTranslation(
        text: text ?? this.text,
        languageLabel: languageLabel ?? this.languageLabel,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatTranslation &&
        other.text == text &&
        other.languageLabel == languageLabel;
  }

  @override
  int get hashCode => Object.hash(text, languageLabel);
}

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
    this.channel,
    this.errorText,
    this.kind = ChatMessageKind.normal,
    this.translation,
    this.headline,
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

  /// Which channel this message travelled over. Null when unknown or the
  /// thread is single-channel — no badge is shown then.
  final ChatChannel? channel;

  /// Reason a delivery failed, shown below the bubble.
  final String? errorText;

  /// The kind of message (normal, system notice, custom rendering).
  final ChatMessageKind kind;

  /// Translation of the text, toggleable in the bubble.
  final ChatTranslation? translation;

  /// Bold first line above the text, e.g. an email subject.
  final String? headline;

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
    ChatChannel? channel,
    String? errorText,
    ChatMessageKind? kind,
    ChatTranslation? translation,
    String? headline,
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
      channel: channel ?? this.channel,
      errorText: errorText ?? this.errorText,
      kind: kind ?? this.kind,
      translation: translation ?? this.translation,
      headline: headline ?? this.headline,
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
        other.readAt == readAt &&
        other.channel == channel &&
        other.errorText == errorText &&
        other.kind == kind &&
        other.translation == translation &&
        other.headline == headline;
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
        channel,
        errorText,
        kind,
        translation,
        headline,
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

  /// Returns a copy of this reference with the given fields replaced.
  ChatMessageRef copyWith({String? id, String? snippet, String? senderLabel}) {
    return ChatMessageRef(
      id: id ?? this.id,
      snippet: snippet ?? this.snippet,
      senderLabel: senderLabel ?? this.senderLabel,
    );
  }

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

  /// Returns a copy of this typing state with the given fields replaced.
  TypingState copyWith({List<ChatParticipant>? participants}) {
    return TypingState(participants: participants ?? this.participants);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TypingState && _listEquals(other.participants, participants);
  }

  @override
  int get hashCode => Object.hashAll(participants);
}

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

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
