import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  test('Standardwerte: keine Kanäle, nicht angepinnt', () {
    const c = ChatConversation(id: 'c1', title: 'Ada');
    expect(c.channels, isEmpty);
    expect(c.pinned, isFalse);
  });

  test('Kanäle und Anpinnen werden übernommen', () {
    const c = ChatConversation(
      id: 'c1',
      title: 'Ada',
      channels: [ChatChannel.whatsApp(), ChatChannel.sms()],
      pinned: true,
    );
    expect(c.channels.length, 2);
    expect(c.channels.first.id, 'whatsapp');
    expect(c.pinned, isTrue);
  });

  test('copyWith ersetzt die neuen Felder', () {
    const c = ChatConversation(id: 'c1', title: 'Ada');
    final neu = c.copyWith(
      channels: const [ChatChannel.email()],
      pinned: true,
    );
    expect(neu.channels.single.id, 'email');
    expect(neu.pinned, isTrue);
    expect(neu.title, 'Ada');
  });

  test('Wertgleichheit berücksichtigt die neuen Felder', () {
    const a = ChatConversation(id: 'c1', title: 'Ada');
    const b = ChatConversation(id: 'c1', title: 'Ada', pinned: true);
    const c = ChatConversation(
      id: 'c1',
      title: 'Ada',
      channels: [ChatChannel.sms()],
    );
    expect(a == b, isFalse);
    expect(a == c, isFalse);
    expect(a, const ChatConversation(id: 'c1', title: 'Ada'));
  });

  test('separat erzeugte, inhaltlich gleiche channels-Listen gelten als gleich',
      () {
    const a = ChatConversation(
      id: 'c1',
      title: 'Ada',
      channels: [ChatChannel.whatsApp(), ChatChannel.sms()],
    );
    final b = ChatConversation(
      id: 'c1',
      title: 'Ada',
      channels:
          List<ChatChannel>.of(const [ChatChannel.whatsApp(), ChatChannel.sms()]),
    );
    expect(identical(a.channels, b.channels), isFalse);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('jedes nullable Feld von ChatConversation lässt sich leeren', () {
    final voll = ChatConversation(
      id: 'c1',
      title: 'Ada',
      subtitle: 'Untertitel',
      channelLabel: 'SMS',
      lastText: 'Text',
      lastAt: DateTime(2026, 7, 31, 10),
      avatarUrl: 'https://example.invalid/a.png',
      presence: const ChatPresence.online(),
    );
    final leer = voll.copyWith(
      clearSubtitle: true,
      clearChannelLabel: true,
      clearLastText: true,
      clearLastAt: true,
      clearAvatar: true,
      clearAvatarUrl: true,
      clearPresence: true,
    );
    expect(leer.subtitle, isNull);
    expect(leer.channelLabel, isNull);
    expect(leer.lastText, isNull);
    expect(leer.lastAt, isNull);
    expect(leer.avatar, isNull);
    expect(leer.avatarUrl, isNull);
    expect(leer.presence, isNull);
    expect(leer.title, 'Ada');
  });

  test('ChatMessageRef: senderLabel lässt sich leeren', () {
    const voll = ChatMessageRef(id: 'x', snippet: 'y', senderLabel: 'Ada');
    expect(voll.copyWith(clearSenderLabel: true).senderLabel, isNull);
    expect(voll.copyWith(snippet: 'z').senderLabel, 'Ada');
  });

  test('ChatMessageRef: clear zusammen mit einem Wert ist ein Programmierfehler',
      () {
    const voll = ChatMessageRef(id: 'x', snippet: 'y', senderLabel: 'Ada');
    expect(
      () => voll.copyWith(senderLabel: 'Bea', clearSenderLabel: true),
      throwsAssertionError,
    );
  });

  test(
      'ChatConversation: clear zusammen mit einem Wert ist ein Programmierfehler '
      '(String- und DateTime-Feld)', () {
    final voll = ChatConversation(
      id: 'c1',
      title: 'Ada',
      subtitle: 'Untertitel',
      lastAt: DateTime(2026, 7, 31, 10),
    );
    expect(
      () => voll.copyWith(subtitle: 'Neu', clearSubtitle: true),
      throwsAssertionError,
    );
    expect(
      () => voll.copyWith(lastAt: DateTime(2026, 7, 31, 11), clearLastAt: true),
      throwsAssertionError,
    );
  });

  test('ChatConversation: ein normaler Aufruf behält subtitle und lastText',
      () {
    final voll = ChatConversation(
      id: 'c1',
      title: 'Ada',
      subtitle: 'Untertitel',
      lastText: 'Text',
    );
    final neu = voll.copyWith(title: 'Neu');
    expect(neu.subtitle, 'Untertitel');
    expect(neu.lastText, 'Text');
    expect(neu.title, 'Neu');
  });
}
