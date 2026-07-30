import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

/// Baut eine ausgehende Nachricht mit Zitat und liefert alle gefundenen
/// Textfarben zurück.
///
/// Rendert die [MessageBubble] direkt statt in einer [ChatThreadView]: Ein
/// Thread stellt vor der ersten Nachricht des Tages stets einen
/// [DateSeparator] voran, dessen Label fest in `dateSeparatorText` steht --
/// eine eigene, hier nicht betroffene Farbe auf einem eigenen Untergrund, die
/// jeden Kontrast-Sweep gegen die Bubble verfälschen würde.
///
/// Der Nachrichtentext bleibt leer: er wird weiterhin aus dem bestehenden
/// `outgoingText`/`incomingText`-Feld gefärbt, nicht aus `ink` (siehe
/// Abgrenzung in Aufgabe 4) und ist deshalb kein Prüfgegenstand dieses Tests.
Future<List<Color>> _textColors(WidgetTester tester,
    {required ChatTheme theme}) async {
  final message = ChatMessage(
    id: 'm1',
    direction: MessageDirection.outgoing,
    text: '',
    at: DateTime(2026, 1, 1, 14, 32),
    replyTo: const ChatMessageRef(
      id: 'p1',
      snippet: 'Wann kommst du?',
      senderLabel: 'Anna',
    ),
  );
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: MessageBubble(
        message: message,
        theme: theme,
        capabilities: const ChatCapabilities.custom(replies: true),
      ),
    ),
  ));
  await tester.pump();
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.style?.color)
      .whereType<Color>()
      .toList();
}

void main() {
  testWidgets('nothing on the outgoing bubble is drawn in the bubble color',
      (tester) async {
    const theme = ChatTheme.light();
    final colors = await _textColors(tester, theme: theme);

    expect(colors, isNotEmpty);
    for (final c in colors) {
      expect(c, isNot(theme.colors.outgoingBubble),
          reason: 'eine Farbe entspricht der Bubble und wäre unsichtbar');
    }
  });

  testWidgets('every text on the outgoing bubble reaches 4.5:1', (tester) async {
    const theme = ChatTheme.light();
    final colors = await _textColors(tester, theme: theme);

    for (final c in colors) {
      expect(contrastRatio(c, theme.colors.outgoingBubble),
          greaterThanOrEqualTo(4.5),
          reason: 'Farbe $c auf der Bubble');
    }
  });

  testWidgets('a green bubble gets ink of its own, not the blue defaults',
      (tester) async {
    final theme = const ChatTheme.light().copyWith(
      colors:
          const ChatColors.light().copyWith(outgoingBubble: const Color(0xFF25D366)),
    );
    final colors = await _textColors(tester, theme: theme);

    for (final c in colors) {
      expect(contrastRatio(c, const Color(0xFF25D366)), greaterThanOrEqualTo(4.5),
          reason: 'Farbe $c auf der grünen Bubble');
    }
  });
}
