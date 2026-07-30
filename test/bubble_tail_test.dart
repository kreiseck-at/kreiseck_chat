import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

Future<void> _pumpThread(WidgetTester tester, ChatTheme theme) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: ChatThreadView(
        messages: [
          ChatMessage(
            id: 'm1',
            text: 'Hallo',
            direction: MessageDirection.outgoing,
            at: DateTime(2026, 1, 1, 14, 32),
          ),
        ],
        theme: theme,
        onSend: (_) {},
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('no tail by default, not even in the iMessage preset',
      (tester) async {
    await _pumpThread(tester, ChatTheme.iMessage(brightness: Brightness.light));
    expect(find.byType(CustomPaint).evaluate().where((e) {
      final widget = e.widget as CustomPaint;
      return widget.painter is BubbleTailPainter;
    }), isEmpty);
  });

  testWidgets('the tail appears when switched on', (tester) async {
    await _pumpThread(
      tester,
      ChatTheme.iMessage(brightness: Brightness.light).copyWith(showBubbleTail: true),
    );
    expect(find.byType(CustomPaint).evaluate().where((e) {
      final widget = e.widget as CustomPaint;
      return widget.painter is BubbleTailPainter;
    }), isNotEmpty);
  });
}
