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
        .split(RegExp(r'\s+'))
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
