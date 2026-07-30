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
}
