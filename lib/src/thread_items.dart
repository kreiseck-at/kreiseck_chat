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

    final groupsWithPrev =
        prev != null &&
        _sameDay(prev.at, m.at) &&
        _groupsWith(prev, m, groupWindow);
    final groupsWithNext =
        next != null &&
        _sameDay(next.at, m.at) &&
        _groupsWith(m, next, groupWindow);

    items.add(
      MessageItem(
        message: m,
        isFirstInGroup: !groupsWithPrev,
        isLastInGroup: !groupsWithNext,
      ),
    );
  }
  return items;
}
