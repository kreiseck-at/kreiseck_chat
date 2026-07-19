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

/// A single message within a chat thread.
///
/// This type is intentionally backend-agnostic: it carries no information
/// about how it was transported or persisted.
class ChatMessage {
  /// Creates a chat message.
  const ChatMessage({
    required this.id,
    required this.direction,
    required this.text,
    required this.at,
    this.status = MessageStatus.sent,
    this.attachments = const [],
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

  /// Optional attachment references (e.g. file paths or URLs).
  final List<String> attachments;

  /// Returns a copy of this message with the given fields replaced.
  ChatMessage copyWith({
    String? id,
    MessageDirection? direction,
    String? text,
    DateTime? at,
    MessageStatus? status,
    List<String>? attachments,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      text: text ?? this.text,
      at: at ?? this.at,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
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
        _listEquals(other.attachments, attachments);
  }

  @override
  int get hashCode => Object.hash(
        id,
        direction,
        text,
        at,
        status,
        Object.hashAll(attachments),
      );
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

  /// Returns a copy of this conversation with the given fields replaced.
  ChatConversation copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? channelLabel,
    String? lastText,
    DateTime? lastAt,
    int? unread,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      channelLabel: channelLabel ?? this.channelLabel,
      lastText: lastText ?? this.lastText,
      lastAt: lastAt ?? this.lastAt,
      unread: unread ?? this.unread,
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
        other.unread == unread;
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
      );
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
