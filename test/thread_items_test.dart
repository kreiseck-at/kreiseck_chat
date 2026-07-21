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
