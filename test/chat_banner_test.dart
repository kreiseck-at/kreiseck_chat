import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  testWidgets('zeigt Text und Symbol', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ChatBanner(
          text: 'Verbindung getrennt',
          icon: Icons.info_outline_rounded,
        ),
      ),
    ));
    expect(find.text('Verbindung getrennt'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
  });

  testWidgets('Warnvariante nutzt eine andere Farbe als Info', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          ChatBanner(text: 'A', variant: ChatBannerVariant.info),
          ChatBanner(text: 'B', variant: ChatBannerVariant.warning),
        ]),
      ),
    ));
    final flaechen = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => (d.decoration as BoxDecoration).color)
        .toList();
    expect(flaechen.length >= 2, isTrue);
    expect(flaechen[0], isNot(flaechen[1]));
  });

  testWidgets('langer Text bricht um statt überzulaufen', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          child: ChatBanner(text: 'Sehr langer Hinweis ' * 10),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
