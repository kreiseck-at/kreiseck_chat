import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

import 'locale_host.dart';

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

ChatMessage _fehlgeschlagen() => ChatMessage(
      id: 'loc1',
      direction: MessageDirection.outgoing,
      text: 'Hallo',
      at: DateTime(2026, 7, 31, 10),
      status: MessageStatus.failed,
      errorText: 'Grund',
    );

// MaterialApp(locale: ...) allein reicht nicht: ohne echte
// MaterialLocalizations-Übersetzung für die gewünschte Sprache meldet
// Flutter eine "not supported by all of its localization delegates"-
// Warnung und der Test schlägt fehl, bevor er überhaupt prüft. `localeHost`
// (siehe `locale_host.dart`) überschreibt für seine Nachfahren gezielt nur
// die Locale, während Directionality/MediaQuery/Navigator/Material weiter
// von der äußeren MaterialApp kommen.
Widget _withLocale(Locale locale, Widget child) =>
    localeHost(child, locale: locale);

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

  testWidgets(
      'no tail painter for whatsApp style by default (opt-in switch is off)',
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
    expect(tails, isEmpty);
  });

  testWidgets('tail painter present for whatsApp style once switched on',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: _out('x'),
          theme: ChatTheme.whatsApp().copyWith(showBubbleTail: true),
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
  Widget scrolled(Widget child) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('single image renders one tile', (tester) async {
    await tester.pumpWidget(scrolled(
      MessageBubble(
        message: _withImages(1),
        capabilities: const ChatCapabilities.inApp(),
      ),
    ));
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('album caps at 4 tiles with a "+N" overlay for extras',
      (tester) async {
    await tester.pumpWidget(scrolled(
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
    await tester.pumpWidget(scrolled(
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
          strings: const ChatStrings.de(),
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
    // On the WhatsApp bubble the raw readReceipt blue itself falls short of
    // 3:1, so the tick is the readable-lifted variant of it, not the raw
    // value -- still recognisably the readReceipt hue, never the accent.
    expect(icon.color,
        readableOn(theme.colors.outgoingBubble, theme.colors.readReceipt, target: 3.0));
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

  testWidgets('Betreffzeile erscheint über dem Text und ist fett', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MessageBubble(message: m(headline: 'Rechnung'))),
    ));
    expect(find.text('Rechnung'), findsOneWidget);
    expect(find.text('Hallo'), findsOneWidget);
    // "über dem Text" heißt: geometrisch oberhalb, nicht nur "irgendwo vorhanden".
    final headlineTop = tester.getTopLeft(find.text('Rechnung')).dy;
    final bodyTop = tester.getTopLeft(find.text('Hallo')).dy;
    expect(headlineTop, lessThan(bodyTop));
    final headlineStyle = tester.widget<Text>(find.text('Rechnung')).style;
    expect(headlineStyle?.fontWeight, FontWeight.w700);
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

  testWidgets('Fehlergrund erscheint unter der Blase in der Fehlerfarbe',
      (tester) async {
    final theme = const ChatTheme.light();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: m(errorText: 'Fenster geschlossen'),
          theme: theme,
        ),
      ),
    ));
    expect(find.text('Fenster geschlossen'), findsOneWidget);
    final style = tester.widget<Text>(find.text('Fenster geschlossen')).style;
    expect(style?.color, theme.colors.error);
  });

  testWidgets(
      'Fehlergrund auf ausgehender Blase liegt außerhalb des farbigen Containers',
      (tester) async {
    // Regression: der Fehlergrund muss auf dem Seitenhintergrund sitzen, nicht
    // auf der (farbigen) Bubble-Fläche — sonst ist die Fehlerfarbe auf
    // ausgehenden Blasen kaum lesbar.
    final msg = ChatMessage(
      id: 'm3',
      direction: MessageDirection.outgoing,
      text: 'Hallo',
      at: DateTime(2026, 7, 30, 10),
      errorText: 'Fenster geschlossen',
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MessageBubble(message: msg)),
    ));
    final container = tester.widget<Container>(find.descendant(
      of: find.byType(MessageBubble),
      matching: find.byType(Container),
    ).first);
    final containerBottom = tester
        .getBottomLeft(find.byWidget(container))
        .dy;
    final errorTop = tester.getTopLeft(find.text('Fenster geschlossen')).dy;
    expect(errorTop, greaterThanOrEqualTo(containerBottom));
  });

  testWidgets(
      'ohne Übersetzung gibt es in der Blase genau einen GestureDetector',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MessageBubble(message: m())),
    ));
    expect(find.byType(GestureDetector), findsOneWidget);
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
    expect(find.text('Original'), findsOneWidget);
    await tester.tap(find.text('Привіт'));
    await tester.pumpAndSettle();
    expect(find.text('Hallo dort'), findsOneWidget);
    expect(find.text('DE'), findsOneWidget);
    expect(find.text('Original'), findsNothing);
    await tester.tap(find.text('Hallo dort'));
    await tester.pumpAndSettle();
    expect(find.text('Привіт'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);
  });

  testWidgets(
      'Sprach-/Original-Label bleibt bei leerem Originaltext verborgen',
      (tester) async {
    // Ohne Text gibt es keinen antippbaren Bereich zum Umschalten — dann darf
    // auch kein Label suggerieren, es gäbe eine erreichbare Übersetzung.
    await tester.pumpWidget(scrolled(
      MessageBubble(
        message: _withImages(1).copyWith(
          translation:
              const ChatTranslation(text: 'Hallo dort', languageLabel: 'DE'),
        ),
      ),
    ));
    expect(find.text('Original'), findsNothing);
    expect(find.text('DE'), findsNothing);
  });

  testWidgets(
      'Long-Press öffnet weiterhin das Menü, wenn eine Übersetzung vorhanden ist',
      (tester) async {
    var copied = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: m(
            text: 'Привіт',
            translation:
                const ChatTranslation(text: 'Hallo dort', languageLabel: 'DE'),
          ),
          onCopy: () => copied++,
          strings: const ChatStrings.de(),
        ),
      ),
    ));
    await tester.longPress(find.text('Привіт'));
    await tester.pumpAndSettle();
    expect(find.text('Kopieren'), findsOneWidget);
    await tester.tap(find.text('Kopieren'));
    await tester.pumpAndSettle();
    expect(copied, 1);
  });

  testWidgets(
      'Wisch-Antwort feuert weiterhin, wenn eine Übersetzung vorhanden ist',
      (tester) async {
    var replied = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: m(
            text: 'Привіт',
            translation:
                const ChatTranslation(text: 'Hallo dort', languageLabel: 'DE'),
          ),
          onReplyRequested: () => replied++,
        ),
      ),
    ));
    await tester.fling(find.text('Привіт'), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(replied, 1);
  });

  testWidgets(
      'Umschalt-Zustand wird bei Nachrichtenwechsel ohne Key zurückgesetzt',
      (tester) async {
    // Simuliert einen Fremd-Aufrufer, der MessageBubble in einer Liste ohne
    // Key wiederverwendet (z.B. ListView.builder ohne ValueKey).
    const translation =
        ChatTranslation(text: 'Hallo dort', languageLabel: 'DE');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: m(text: 'Привіт', translation: translation),
        ),
      ),
    ));
    await tester.tap(find.text('Привіт'));
    await tester.pumpAndSettle();
    expect(find.text('Hallo dort'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: ChatMessage(
            id: 'm4',
            direction: MessageDirection.incoming,
            text: 'Servus',
            at: DateTime(2026, 7, 30, 10),
            translation: translation,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Servus'), findsOneWidget);
    expect(find.text('Hallo dort'), findsNothing);
    expect(find.text('Original'), findsOneWidget);
  });

  testWidgets(
      'Betreffzeile trägt dieselbe Farbe wie der Nachrichtentext (ausgehende Blase)',
      (tester) async {
    final msg = ChatMessage(
      id: 'm2',
      direction: MessageDirection.outgoing,
      text: 'Hallo',
      at: DateTime(2026, 7, 30, 10),
      headline: 'Rechnung',
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MessageBubble(message: msg)),
    ));
    final headlineText = tester.widget<Text>(find.text('Rechnung'));
    final bodyText = tester.widget<Text>(find.text('Hallo'));
    expect(headlineText.style?.color, bodyText.style?.color);
  });

  testWidgets('failed status icon is readable, not raw red', (tester) async {
    // Pink bubble from the audit: raw Colors.red measured 1.06:1 on it.
    final theme = const ChatTheme.light().copyWith(
      colors: const ChatColors.light()
          .copyWith(outgoingBubble: const Color(0xFFFF2D95)),
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: _out('x', status: MessageStatus.failed),
          theme: theme,
        ),
      ),
    ));
    final icon = tester.widget<Icon>(find.byType(Icon).last);
    expect(icon.color, isNot(Colors.red));
    expect(contrastRatio(icon.color!, theme.colors.outgoingBubble),
        greaterThanOrEqualTo(3.0));
  });

  testWidgets('Original-Label nutzt ink.muted statt gedimmten Text',
      (tester) async {
    // Grüne Blase aus der Prüfung: 70% Deckkraft auf Weiß ergab dort 1,59:1.
    final theme = const ChatTheme.light().copyWith(
      colors: const ChatColors.light()
          .copyWith(outgoingBubble: const Color(0xFF25D366)),
    );
    final msg = ChatMessage(
      id: 'm5',
      direction: MessageDirection.outgoing,
      text: 'Привіт',
      at: DateTime(2026, 7, 30, 10),
      translation:
          const ChatTranslation(text: 'Hallo dort', languageLabel: 'DE'),
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MessageBubble(message: msg, theme: theme)),
    ));
    final label = tester.widget<Text>(find.text('Original'));
    final ink = theme.colors.inkFor(theme.colors.outgoingBubble);
    expect(label.style?.color, ink.muted);
  });

  testWidgets('Ecken bleiben gleichmäßig, wenn kein Zipfel gemalt wird',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: _out('x'),
          // showBubbleTail ist hier (wie in jedem Preset) standardmäßig aus.
          theme: ChatTheme.whatsApp(),
          isLastInGroup: true,
        ),
      ),
    ));
    final container = tester
        .widgetList<Container>(find.descendant(
          of: find.byType(MessageBubble),
          matching: find.byType(Container),
        ))
        .first;
    final radius =
        (container.decoration as BoxDecoration).borderRadius as BorderRadius;
    expect(radius.bottomRight, radius.topRight);
    expect(radius.bottomLeft, radius.topLeft);
  });

  testWidgets('Texte folgen der App-Sprache', (tester) async {
    await tester.pumpWidget(_withLocale(
      const Locale('uk'),
      MessageBubble(message: _fehlgeschlagen(), onRetry: () {}),
    ));
    expect(find.text('Надіслати ще раз'), findsOneWidget);
  });

  testWidgets('strings-Override gewinnt über die App-Sprache', (tester) async {
    await tester.pumpWidget(_withLocale(
      const Locale('uk'),
      MessageBubble(
        message: _fehlgeschlagen(),
        onRetry: () {},
        strings: const ChatStrings.de(),
      ),
    ));
    expect(find.text('Erneut senden'), findsOneWidget);
  });

  testWidgets('unter Locale de bleibt alles wie bisher', (tester) async {
    await tester.pumpWidget(_withLocale(
      const Locale('de'),
      MessageBubble(message: _fehlgeschlagen(), onRetry: () {}),
    ));
    expect(find.text('Erneut senden'), findsOneWidget);
  });

  testWidgets(
      'Anhang ohne Dateinamen fällt unter ukrainischem Kontext auf "Файл" zurück',
      (tester) async {
    final msg = ChatMessage(
      id: 'm6',
      direction: MessageDirection.incoming,
      text: '',
      at: DateTime(2026, 7, 31, 10),
      attachments: const [ChatAttachment(kind: AttachmentKind.file)],
    );
    await tester.pumpWidget(_withLocale(
      const Locale('uk'),
      MessageBubble(message: msg),
    ));
    expect(find.text('Файл'), findsOneWidget);
  });
}
