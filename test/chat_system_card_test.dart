import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  testWidgets('zeigt Inhalt und optionales Symbol', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ChatSystemCard(
          icon: Icons.info_outline_rounded,
          child: Text('Anruf verpasst'),
        ),
      ),
    ));
    expect(find.text('Anruf verpasst'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
  });

  testWidgets('ohne Symbol wird keins gerendert', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: ChatSystemCard(child: Text('Hinweis'))),
    ));
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('onTap wird ausgelöst', (tester) async {
    var getippt = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatSystemCard(
          onTap: () => getippt = true,
          child: const Text('Antippen'),
        ),
      ),
    ));
    await tester.tap(find.text('Antippen'));
    expect(getippt, isTrue);
  });

  testWidgets('langer Textinhalt wird umgebrochen, ohne Fehler',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 120,
            child: ChatSystemCard(
              icon: Icons.info_outline_rounded,
              child: Text('A' * 80),
            ),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
  });

  testWidgets(
      'abweichendes ChatTheme ändert Hintergrund-/Textfarbe und bubbleRadius',
      (tester) async {
    const theme = ChatTheme(colors: ChatColors.dark(), bubbleRadius: 4);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ChatSystemCard(
          icon: Icons.info_outline_rounded,
          theme: theme,
          child: Text('Hinweis'),
        ),
      ),
    ));

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, theme.colors.dateSeparatorBackground);
    expect(
      decoration.color,
      isNot(const ChatTheme.light().colors.dateSeparatorBackground),
    );
    expect(decoration.borderRadius, BorderRadius.circular(4));

    final icon =
        tester.widget<Icon>(find.byIcon(Icons.info_outline_rounded));
    expect(icon.color, theme.colors.dateSeparatorText);
  });
}
