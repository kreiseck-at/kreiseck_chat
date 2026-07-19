import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  testWidgets('shows messages, sends new text and clears the field',
      (tester) async {
    final messages = [
      ChatMessage(
        id: '1',
        direction: MessageDirection.incoming,
        text: 'Hello',
        at: DateTime(2026, 1, 1, 10),
      ),
      ChatMessage(
        id: '2',
        direction: MessageDirection.outgoing,
        text: 'Hi back',
        at: DateTime(2026, 1, 1, 10, 1),
      ),
    ];
    String? sent;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatThreadView(
            messages: messages,
            onSend: (text) => sent = text,
          ),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Hi back'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'New message');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(sent, 'New message');
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('shows an empty state without crashing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatThreadView(
            messages: const [],
            onSend: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ChatThreadView), findsOneWidget);
  });
}
