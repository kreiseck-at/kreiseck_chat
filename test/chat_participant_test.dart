import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

// 1x1 transparentes PNG als gültige Bytes für MemoryImage im Test.
final _pixel = MemoryImage(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='));

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

  test('jedes nullable Feld von ChatPresence lässt sich leeren', () {
    final voll = ChatPresence(
      state: PresenceState.online,
      lastSeen: DateTime(2026, 7, 31, 9),
      customLabel: 'Gerade aktiv',
    );
    final leer = voll.copyWith(
      clearLastSeen: true,
      clearCustomLabel: true,
    );
    expect(leer.lastSeen, isNull);
    expect(leer.customLabel, isNull);
    expect(leer.state, PresenceState.online);
  });

  test('ChatPresence: ohne clear bleiben lastSeen und customLabel stehen', () {
    final voll = ChatPresence(
      state: PresenceState.online,
      lastSeen: DateTime(2026, 7, 31, 9),
      customLabel: 'Gerade aktiv',
    );
    final neu = voll.copyWith(state: PresenceState.offline);
    expect(neu.lastSeen, DateTime(2026, 7, 31, 9));
    expect(neu.customLabel, 'Gerade aktiv');
    expect(neu.state, PresenceState.offline);
  });

  test(
      'ChatPresence: clear zusammen mit einem Wert ist ein Programmierfehler',
      () {
    final mitLastSeen = ChatPresence(lastSeen: DateTime(2026, 7, 31, 9));
    expect(
      () => mitLastSeen.copyWith(
        lastSeen: DateTime(2026, 7, 31, 10),
        clearLastSeen: true,
      ),
      throwsAssertionError,
    );
    const mitLabel = ChatPresence(customLabel: 'Aktiv');
    expect(
      () => mitLabel.copyWith(customLabel: 'Neu', clearCustomLabel: true),
      throwsAssertionError,
    );
  });

  test('jedes nullable Feld von ChatParticipant lässt sich leeren', () {
    final voll = ChatParticipant(
      id: '1',
      displayName: 'Ada',
      avatar: _pixel,
      avatarUrl: 'https://example.invalid/a.png',
      presence: const ChatPresence.online(),
      color: const Color(0xFF3478F6),
    );
    final leer = voll.copyWith(
      clearAvatar: true,
      clearAvatarUrl: true,
      clearPresence: true,
      clearColor: true,
    );
    expect(leer.avatar, isNull);
    expect(leer.avatarUrl, isNull);
    expect(leer.presence, isNull);
    expect(leer.color, isNull);
    expect(leer.id, '1');
    expect(leer.displayName, 'Ada');
  });

  test(
      'ChatParticipant: ohne clear bleiben avatarUrl, presence und color stehen',
      () {
    final voll = ChatParticipant(
      id: '1',
      displayName: 'Ada',
      avatarUrl: 'https://example.invalid/a.png',
      presence: const ChatPresence.online(),
      color: const Color(0xFF3478F6),
    );
    final neu = voll.copyWith(displayName: 'Ada Lovelace');
    expect(neu.avatarUrl, 'https://example.invalid/a.png');
    expect(neu.presence, const ChatPresence.online());
    expect(neu.color, const Color(0xFF3478F6));
    expect(neu.displayName, 'Ada Lovelace');
  });

  test(
      'ChatParticipant: clear zusammen mit einem Wert ist ein Programmierfehler',
      () {
    final mitAvatarUrl = ChatParticipant(
      id: '1',
      displayName: 'Ada',
      avatarUrl: 'https://example.invalid/a.png',
    );
    expect(
      () => mitAvatarUrl.copyWith(
        avatarUrl: 'https://example.invalid/b.png',
        clearAvatarUrl: true,
      ),
      throwsAssertionError,
    );
    final mitColor = ChatParticipant(
      id: '1',
      displayName: 'Ada',
      color: const Color(0xFF112233),
    );
    expect(
      () => mitColor.copyWith(
        color: const Color(0xFF445566),
        clearColor: true,
      ),
      throwsAssertionError,
    );
  });
}
