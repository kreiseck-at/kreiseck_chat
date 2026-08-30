import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

ChatMessage _quoted() => ChatMessage(
      id: 'm2',
      direction: MessageDirection.incoming,
      text: 'Ja passt',
      at: DateTime(2026, 8, 30, 12),
      replyTo: const ChatMessageRef(
        id: 'm1',
        snippet: 'Sind Sie um 8 da?',
        senderLabel: 'Wir',
      ),
    );

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('Zitat erscheint auch ohne onReplyRequested', (tester) async {
    await tester.pumpWidget(_host(MessageBubble(
      message: _quoted(),
      capabilities: const ChatCapabilities.twilioWhatsApp(),
    )));
    expect(find.text('Sind Sie um 8 da?'), findsOneWidget);
  });

  testWidgets('ohne onReplyRequested bietet das Menue kein Antworten an', (tester) async {
    await tester.pumpWidget(_host(MessageBubble(
      message: _quoted(),
      capabilities: const ChatCapabilities.twilioWhatsApp(),
    )));
    await tester.longPress(find.text('Ja passt'));
    await tester.pumpAndSettle();
    expect(find.text(const ChatStrings.en().reply), findsNothing);
    expect(find.text(const ChatStrings.en().copy), findsOneWidget);
  });

  testWidgets('mit onReplyRequested bietet das Menue Antworten an', (tester) async {
    await tester.pumpWidget(_host(MessageBubble(
      message: _quoted(),
      capabilities: const ChatCapabilities.twilioWhatsApp(),
      onReplyRequested: () {},
    )));
    await tester.longPress(find.text('Ja passt'));
    await tester.pumpAndSettle();
    expect(find.text(const ChatStrings.en().reply), findsOneWidget);
  });
}
