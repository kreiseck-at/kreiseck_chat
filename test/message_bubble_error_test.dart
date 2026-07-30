import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

ChatMessage _failed() => ChatMessage(
      id: 'm1',
      direction: MessageDirection.outgoing,
      text: 'Bin in fünf Minuten da',
      at: DateTime(2026, 1, 1, 14, 32),
      errorText: 'Nicht zugestellt',
    );

void main() {
  testWidgets('the error line is readable on the dark background', (tester) async {
    const theme = ChatTheme.dark();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(messages: [_failed()], theme: theme, onSend: (_) {}),
      ),
    ));
    await tester.pump();

    final text = tester.widget<Text>(find.text('Nicht zugestellt'));
    expect(contrastRatio(text.style!.color!, theme.colors.background),
        greaterThanOrEqualTo(4.5));
  });

  testWidgets('with onRetry a retry action appears and calls back', (tester) async {
    var retried = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: [_failed()],
          theme: const ChatTheme.light(),
          onSend: (_) {},
          onRetry: (_) => retried++,
        ),
      ),
    ));
    // pumpAndSettle: the last (here, only) bubble in a ChatThreadView plays a
    // slide/fade entrance animation, so a bare pump() would still be mid-flight
    // and land the tap outside the button.
    await tester.pumpAndSettle();

    await tester.tap(find.text('Erneut senden'));
    await tester.pump();
    expect(retried, 1);
  });

  testWidgets('without onRetry only the reason is shown', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: [_failed()],
          theme: const ChatTheme.light(),
          onSend: (_) {},
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Nicht zugestellt'), findsOneWidget);
    expect(find.text('Erneut senden'), findsNothing);
  });
}
