import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

// 1x1 transparentes PNG als gültige Bytes für MemoryImage im Test.
final _pixel = MemoryImage(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='));

ChatMessage _out(String text, {MessageStatus status = MessageStatus.read}) {
  return ChatMessage(
    id: 't',
    direction: MessageDirection.outgoing,
    text: text,
    at: DateTime(2026, 7, 21, 14, 32),
    status: status,
  );
}

ChatMessage _withImages(int n, {String text = ''}) {
  return ChatMessage(
    id: 't',
    direction: MessageDirection.outgoing,
    text: text,
    at: DateTime(2026, 7, 21, 14, 32),
    attachments: [
      for (var i = 0; i < n; i++)
        ChatAttachment(kind: AttachmentKind.image, thumbnail: _pixel),
    ],
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

  // Album-Kacheln füllen die Höhe der Bubble; im Scrollview kann der feste
  // Test-Viewport nicht überlaufen.
  Widget _scrolled(Widget child) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('single image renders one tile', (tester) async {
    await tester.pumpWidget(_scrolled(
      MessageBubble(
        message: _withImages(1),
        capabilities: const ChatCapabilities.inApp(),
      ),
    ));
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('album caps at 4 tiles with a "+N" overlay for extras',
      (tester) async {
    await tester.pumpWidget(_scrolled(
      MessageBubble(
        message: _withImages(6),
        capabilities: const ChatCapabilities.inApp(),
      ),
    ));
    // At most 4 image tiles shown, and a "+2" overlay for the remaining two.
    expect(find.byType(Image), findsNWidgets(4));
    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('tapping an album image fires onOpenImages with images + index',
      (tester) async {
    List<ChatAttachment>? gotImages;
    int? gotIndex;
    await tester.pumpWidget(_scrolled(
      MessageBubble(
        message: _withImages(3),
        capabilities: const ChatCapabilities.inApp(),
        onOpenImages: (images, index) {
          gotImages = images;
          gotIndex = index;
        },
      ),
    ));
    // Second tile (index 1).
    await tester.tap(find.byType(Image).at(1));
    await tester.pump();
    expect(gotImages, isNotNull);
    expect(gotImages!.length, 3);
    expect(gotIndex, 1);
  });

  testWidgets('long-press opens a context menu with Kopieren (no bottom sheet)',
      (tester) async {
    var copied = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: _out('kopier mich'),
          // Like the SMS/WhatsApp profile: no reactions/replies, just copy.
          capabilities: const ChatCapabilities.custom(readReceipts: true),
          onCopy: () => copied++,
        ),
      ),
    ));

    await tester.longPress(find.text('kopier mich'));
    await tester.pumpAndSettle();
    expect(find.text('Kopieren'), findsOneWidget);

    await tester.tap(find.text('Kopieren'));
    await tester.pumpAndSettle();
    expect(copied, 1);
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

  ChatMessage m({
    String text = 'Hallo',
    String? headline,
    ChatChannel? channel,
    String? errorText,
    ChatTranslation? translation,
  }) =>
      ChatMessage(
        id: 'm1',
        direction: MessageDirection.incoming,
        text: text,
        at: DateTime(2026, 7, 30, 10),
        headline: headline,
        channel: channel,
        errorText: errorText,
        translation: translation,
      );

  testWidgets('Betreffzeile erscheint über dem Text', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MessageBubble(message: m(headline: 'Rechnung'))),
    ));
    expect(find.text('Rechnung'), findsOneWidget);
    expect(find.text('Hallo'), findsOneWidget);
  });

  testWidgets('Kanal-Marke erscheint in der Metazeile', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(message: m(channel: const ChatChannel.sms())),
      ),
    ));
    expect(find.byType(ChatChannelBadge), findsOneWidget);
  });

  testWidgets('ohne Kanal keine Marke', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MessageBubble(message: m())),
    ));
    expect(find.byType(ChatChannelBadge), findsNothing);
  });

  testWidgets('Fehlergrund erscheint unter der Blase', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: m(errorText: 'Fenster geschlossen'),
        ),
      ),
    ));
    expect(find.text('Fenster geschlossen'), findsOneWidget);
  });

  testWidgets('Antippen schaltet zwischen Original und Übersetzung',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: m(
            text: 'Привіт',
            translation:
                const ChatTranslation(text: 'Hallo dort', languageLabel: 'DE'),
          ),
        ),
      ),
    ));
    expect(find.text('Привіт'), findsOneWidget);
    await tester.tap(find.text('Привіт'));
    await tester.pumpAndSettle();
    expect(find.text('Hallo dort'), findsOneWidget);
    await tester.tap(find.text('Hallo dort'));
    await tester.pumpAndSettle();
    expect(find.text('Привіт'), findsOneWidget);
  });
}
