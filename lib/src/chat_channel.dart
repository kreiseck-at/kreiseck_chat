import 'package:flutter/material.dart';

/// Ein Kanal, über den eine Nachricht laufen kann — SMS, WhatsApp, E-Mail,
/// In-App oder etwas ganz eigenes.
///
/// Das Paket legt keine Kanäle fest: es kennt nur diese Beschreibung und stellt
/// sie einheitlich dar (siehe `ChatChannelBadge`). Die Vorlagen unten decken die
/// Kanäle ab, die viele Apps haben; alles daran lässt sich per [copyWith]
/// überschreiben, damit die Marke zum eigenen Aussehen passt.
@immutable
class ChatChannel {
  /// Erzeugt einen Kanal.
  const ChatChannel({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  /// Stabile Kennung, z. B. `'whatsapp'`. Nicht für die Anzeige gedacht.
  final String id;

  /// Anzeigename, z. B. `'WhatsApp'`.
  final String label;

  /// Symbol für Abzeichen und Listen.
  final IconData icon;

  /// Kennfarbe des Kanals.
  final Color color;

  /// WhatsApp — Markengrün.
  const ChatChannel.whatsApp({this.label = 'WhatsApp'})
      : id = 'whatsapp',
        icon = Icons.chat_rounded,
        color = const Color(0xFF25D366);

  /// SMS.
  const ChatChannel.sms({this.label = 'SMS'})
      : id = 'sms',
        icon = Icons.sms_rounded,
        color = const Color(0xFF6C6C70);

  /// E-Mail.
  const ChatChannel.email({this.label = 'E-Mail'})
      : id = 'email',
        icon = Icons.email_outlined,
        color = const Color(0xFF4A6FA5);

  /// Chat innerhalb der eigenen App.
  const ChatChannel.inApp({this.label = 'In-App'})
      : id = 'inapp',
        icon = Icons.forum_outlined,
        color = const Color(0xFF3478F6);

  /// Telefonat.
  const ChatChannel.voice({this.label = 'Anruf'})
      : id = 'voice',
        icon = Icons.call_rounded,
        color = const Color(0xFF7C4DFF);

  /// Gibt eine Kopie mit ersetzten Feldern zurück.
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
