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
