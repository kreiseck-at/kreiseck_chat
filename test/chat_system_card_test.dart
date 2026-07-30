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

  testWidgets('langes Textinhalt wird gekürzt, ohne Fehler', (tester) async {
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
}
