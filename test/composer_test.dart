import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  testWidgets('attach button hidden when media capability off', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Composer(
          onSend: (_) {},
          capabilities: const ChatCapabilities.twilioSms(),
        ),
      ),
    ));
    expect(find.byIcon(const ChatIcons().attach), findsNothing);
  });

  testWidgets('attach button shown when media capability on', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Composer(
          onSend: (_) {},
          capabilities: const ChatCapabilities.inApp(),
          onAttach: (_) {},
        ),
      ),
    ));
    expect(find.byIcon(const ChatIcons().attach), findsOneWidget);
  });

  testWidgets('send clears field and calls onSend', (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Composer(onSend: sent.add)),
    ));
    await tester.enterText(find.byType(TextField), 'hallo');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(sent, ['hallo']);
    expect(find.text('hallo'), findsNothing);
  });

  testWidgets('onTypingChanged fires true then false', (tester) async {
    final events = <bool>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Composer(onSend: (_) {}, onTypingChanged: events.add)),
    ));
    await tester.enterText(find.byType(TextField), 'h');
    await tester.enterText(find.byType(TextField), '');
    expect(events.first, isTrue);
    expect(events.last, isFalse);
  });
}
