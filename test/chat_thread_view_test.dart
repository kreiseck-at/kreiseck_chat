import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

List<ChatMessage> _seed() => [
      ChatMessage(
          id: '1',
          direction: MessageDirection.incoming,
          text: 'Hallo',
          at: DateTime(2026, 7, 21, 9, 0)),
      ChatMessage(
          id: '2',
          direction: MessageDirection.outgoing,
          text: 'Servus',
          at: DateTime(2026, 7, 21, 9, 1)),
    ];

void main() {
  testWidgets('renders messages and a date separator', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: _seed(),
          onSend: (_) {},
          now: DateTime(2026, 7, 21, 10),
        ),
      ),
    ));
    expect(find.text('Hallo'), findsOneWidget);
    expect(find.text('Servus'), findsOneWidget);
    expect(find.byType(DateSeparator), findsOneWidget);
  });

  testWidgets('shows typing indicator when enabled and typing', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: _seed(),
          onSend: (_) {},
          capabilities: const ChatCapabilities.inApp(),
          typing: const TypingState(
              participants: [ChatParticipant(id: 'a', displayName: 'Ada')]),
          now: DateTime(2026, 7, 21, 10),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byType(TypingIndicator), findsOneWidget);
  });

  testWidgets('no typing indicator when capability off', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: _seed(),
          onSend: (_) {},
          capabilities: const ChatCapabilities.twilioSms(),
          typing: const TypingState(
              participants: [ChatParticipant(id: 'a', displayName: 'Ada')]),
          now: DateTime(2026, 7, 21, 10),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byType(TypingIndicator), findsNothing);
  });
}
