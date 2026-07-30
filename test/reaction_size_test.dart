import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  testWidgets('a reaction chip is at least 28 logical pixels tall and its emoji at least 16',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: [
            ChatMessage(
              id: 'm1',
              direction: MessageDirection.outgoing,
              text: 'Hallo',
              at: DateTime(2026, 1, 1, 14, 32),
              reactions: const [MessageReaction(emoji: '👍', count: 2)],
            ),
          ],
          theme: const ChatTheme.light(),
          capabilities: const ChatCapabilities.custom(reactions: true),
          onSend: (_) {},
        ),
      ),
    ));
    await tester.pump();

    final emoji = tester.widget<Text>(find.text('👍'));
    expect(emoji.style!.fontSize, greaterThanOrEqualTo(16));

    final chip = tester.getSize(find.ancestor(
      of: find.text('👍'),
      matching: find.byType(Container),
    ).first);
    expect(chip.height, greaterThanOrEqualTo(28));
  });
}
