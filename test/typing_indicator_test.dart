import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  testWidgets('TypingIndicator renders three dots and animates', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: TypingIndicator(theme: ChatTheme.light())),
    ));
    expect(find.byType(TypingIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    // Does not throw while animating; dispose cleanly.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('DateSeparator shows "Heute" for today', (tester) async {
    final now = DateTime(2026, 7, 21, 12);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DateSeparator(
          date: DateTime(2026, 7, 21),
          theme: const ChatTheme.light(),
          now: now,
        ),
      ),
    ));
    expect(find.text('Heute'), findsOneWidget);
  });

  testWidgets('DateSeparator shows "Gestern"', (tester) async {
    final now = DateTime(2026, 7, 21, 12);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DateSeparator(
          date: DateTime(2026, 7, 20),
          theme: const ChatTheme.light(),
          now: now,
        ),
      ),
    ));
    expect(find.text('Gestern'), findsOneWidget);
  });
}
