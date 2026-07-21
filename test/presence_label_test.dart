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
