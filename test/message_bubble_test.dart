import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

ChatMessage _out(String text, {MessageStatus status = MessageStatus.read}) {
  return ChatMessage(
    id: 't',
    direction: MessageDirection.outgoing,
    text: text,
    at: DateTime(2026, 7, 21, 14, 32),
    status: status,
  );
}

void main() {
  testWidgets('renders text and time', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MessageBubble(message: _out('hallo'))),
    ));
    expect(find.text('hallo'), findsOneWidget);
    expect(find.text('14:32'), findsOneWidget);
  });

  testWidgets('reactions hidden when capability off', (tester) async {
    final msg = _out('x').copyWith(
      reactions: const [MessageReaction(emoji: '👍', count: 2)],
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: msg,
          capabilities: const ChatCapabilities.twilioSms(),
        ),
      ),
    ));
    expect(find.text('👍'), findsNothing);
  });

  testWidgets('reactions shown when capability on', (tester) async {
    final msg = _out('x').copyWith(
      reactions: const [MessageReaction(emoji: '👍', count: 2)],
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: msg,
          capabilities: const ChatCapabilities.inApp(),
        ),
      ),
    ));
    expect(find.text('👍'), findsOneWidget);
  });

  testWidgets('read receipt capped at delivered when readReceipts off',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: _out('x', status: MessageStatus.read),
          capabilities: const ChatCapabilities.twilioSms(),
          theme: const ChatTheme.light(),
        ),
      ),
    ));
    // The read icon uses accentColor; when capped it must not be the accent.
    final icon = tester.widget<Icon>(find.byType(Icon).last);
    expect(icon.color, isNot(const ChatTheme.light().accentColor));
  });

  testWidgets('reply quote shown when present and replies enabled',
      (tester) async {
    final msg = _out('reply body').copyWith(
      replyTo: const ChatMessageRef(id: 'p', snippet: 'quoted text', senderLabel: 'Ada'),
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: msg,
          capabilities: const ChatCapabilities.inApp(),
        ),
      ),
    ));
    expect(find.text('quoted text'), findsOneWidget);
  });
}
