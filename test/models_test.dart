import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  group('ChatMessage', () {
    final at = DateTime(2026, 1, 1, 12);

    test('applies defaults', () {
      final message = ChatMessage(
        id: '1',
        direction: MessageDirection.incoming,
        text: 'hello',
        at: at,
      );

      expect(message.status, MessageStatus.sent);
      expect(message.attachments, isEmpty);
    });

    test('copyWith overrides only the given fields', () {
      final message = ChatMessage(
        id: '1',
        direction: MessageDirection.outgoing,
        text: 'hello',
        at: at,
        status: MessageStatus.sending,
      );

      final updated = message.copyWith(status: MessageStatus.delivered);

      expect(updated.status, MessageStatus.delivered);
      expect(updated.id, message.id);
      expect(updated.direction, message.direction);
      expect(updated.text, message.text);
      expect(updated.at, message.at);
    });

    test('equality is value-based', () {
      final a = ChatMessage(
        id: '1',
        direction: MessageDirection.incoming,
        text: 'hi',
        at: at,
      );
      final b = ChatMessage(
        id: '1',
        direction: MessageDirection.incoming,
        text: 'hi',
        at: at,
      );
      final c = a.copyWith(text: 'other');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('ChatConversation', () {
    test('applies defaults', () {
      const conversation = ChatConversation(id: '1', title: 'Alice');
      expect(conversation.unread, 0);
      expect(conversation.subtitle, isNull);
    });

    test('copyWith overrides only the given fields', () {
      const conversation = ChatConversation(
        id: '1',
        title: 'Alice',
        unread: 2,
      );

      final updated = conversation.copyWith(unread: 0);

      expect(updated.unread, 0);
      expect(updated.title, conversation.title);
      expect(updated.id, conversation.id);
    });

    test('equality is value-based', () {
      const a = ChatConversation(id: '1', title: 'Alice', unread: 3);
      const b = ChatConversation(id: '1', title: 'Alice', unread: 3);
      final c = a.copyWith(unread: 0);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
