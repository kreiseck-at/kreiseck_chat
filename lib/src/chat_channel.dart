import 'package:flutter/material.dart';

/// A channel a message can travel over — SMS, WhatsApp, email, in-app, or
/// something entirely custom.
///
/// The package doesn't fix a set of channels: it only knows this description
/// and renders it consistently (see `ChatChannelBadge`). The templates below
/// cover the channels most apps have; everything on them can be overridden
/// via [copyWith] so the brand matches the host app's own look.
@immutable
class ChatChannel {
  /// Creates a channel.
  const ChatChannel({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  /// Stable identifier, e.g. `'whatsapp'`. Not meant for display.
  final String id;

  /// Display name, e.g. `'WhatsApp'`.
  final String label;

  /// Icon for badges and lists.
  final IconData icon;

  /// The channel's brand color.
  final Color color;

  /// WhatsApp — brand green.
  const ChatChannel.whatsApp({this.label = 'WhatsApp'})
      : id = 'whatsapp',
        icon = Icons.chat_rounded,
        color = const Color(0xFF25D366);

  /// SMS.
  const ChatChannel.sms({this.label = 'SMS'})
      : id = 'sms',
        icon = Icons.sms_rounded,
        color = const Color(0xFF6C6C70);

  /// Email.
  const ChatChannel.email({this.label = 'E-Mail'})
      : id = 'email',
        icon = Icons.email_outlined,
        color = const Color(0xFF4A6FA5);

  /// Chat within the host app itself.
  const ChatChannel.inApp({this.label = 'In-App'})
      : id = 'inapp',
        icon = Icons.forum_outlined,
        color = const Color(0xFF3478F6);

  /// Phone call.
  const ChatChannel.voice({this.label = 'Anruf'})
      : id = 'voice',
        icon = Icons.call_rounded,
        color = const Color(0xFF7C4DFF);

  /// Returns a copy with the given fields replaced.
  ChatChannel copyWith({
    String? id,
    String? label,
    IconData? icon,
    Color? color,
  }) {
    return ChatChannel(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatChannel &&
        other.id == id &&
        other.label == label &&
        other.icon == icon &&
        other.color == color;
  }

  @override
  int get hashCode => Object.hash(id, label, icon, color);
}
