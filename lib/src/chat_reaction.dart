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
