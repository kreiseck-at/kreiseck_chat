import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('tail painter present for whatsApp style when last in group',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: _out('x'),
          theme: ChatTheme.whatsApp(),
          isLastInGroup: true,
        ),
      ),
    ));
    final tails = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((c) => c.painter is BubbleTailPainter);
    expect(tails, isNotEmpty);
  });

  testWidgets('no tail painter for minimal style', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: _out('x'),
          theme: const ChatTheme.light(),
          isLastInGroup: true,
        ),
      ),
    ));
    final tails = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((c) => c.painter is BubbleTailPainter);
    expect(tails, isEmpty);
  });

  testWidgets('long-press fires a haptic when capabilities allow actions',
      (tester) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String? ?? '');
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: _out('long press me'),
          capabilities: const ChatCapabilities.inApp(),
        ),
      ),
    ));

    await tester.longPress(find.text('long press me'));
    await tester.pumpAndSettle();

    expect(haptics, isNotEmpty);
  });

  testWidgets('reacting fires a reaction haptic and does not disturb send path',
      (tester) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String? ?? '');
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final reacted = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: _out('react to me'),
          capabilities: const ChatCapabilities.inApp(),
          onReact: reacted.add,
        ),
      ),
    ));

    await tester.longPress(find.text('react to me'));
    await tester.pumpAndSettle();
    haptics.clear();

    await tester.tap(find.text('👍').first);
    await tester.pumpAndSettle();

    expect(reacted, ['👍']);
    expect(haptics, isNotEmpty);
  });

  testWidgets('read tick uses the blue readReceipt color, not the accent',
      (tester) async {
    final theme = ChatTheme.whatsApp(); // accent is green here
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: _out('x', status: MessageStatus.read),
          theme: theme,
          capabilities: const ChatCapabilities.inApp(),
        ),
      ),
    ));
    final icon = tester.widget<Icon>(find.byType(Icon).last);
    expect(icon.color, theme.colors.readReceipt);
    expect(icon.color, isNot(theme.colors.accent));
  });
}
