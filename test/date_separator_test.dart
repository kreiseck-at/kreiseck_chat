import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

/// Puts [child] under an ambient [locale] without going through MaterialApp's
/// own locale resolution -- MaterialApp falls back to a different locale for
/// languages its bundled Default*Localizations don't declare as supported
/// (everything but 'en'), so a plain MaterialApp(locale: ...) silently drops
/// the requested language before ChatStrings.of ever sees it.
Widget _localeHost(Locale locale, Widget child) => Localizations(
      locale: locale,
      delegates: const [
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    );

void main() {
  final jetzt = DateTime(2026, 7, 31, 12);

  testWidgets('Heute/Gestern folgen der App-Sprache', (tester) async {
    await tester.pumpWidget(_localeHost(
      const Locale('uk'),
      Column(children: [
        DateSeparator(date: jetzt, theme: const ChatTheme.light(), now: jetzt),
        DateSeparator(
          date: jetzt.subtract(const Duration(days: 1)),
          theme: const ChatTheme.light(),
          now: jetzt,
        ),
      ]),
    ));
    expect(find.text('Сьогодні'), findsOneWidget);
    expect(find.text('Учора'), findsOneWidget);
  });

  testWidgets('unter Locale de bleibt es Heute/Gestern', (tester) async {
    await tester.pumpWidget(_localeHost(
      const Locale('de'),
      DateSeparator(date: jetzt, theme: const ChatTheme.light(), now: jetzt),
    ));
    expect(find.text('Heute'), findsOneWidget);
  });

  testWidgets('labelBuilder gewinnt weiterhin über alles', (tester) async {
    await tester.pumpWidget(_localeHost(
      const Locale('uk'),
      DateSeparator(
        date: jetzt,
        theme: const ChatTheme.light(),
        now: jetzt,
        labelBuilder: (_, _) => 'Eigen',
      ),
    ));
    expect(find.text('Eigen'), findsOneWidget);
  });

  testWidgets('ältere Tage zeigen weiterhin das Datum', (tester) async {
    await tester.pumpWidget(_localeHost(
      const Locale('de'),
      DateSeparator(
        date: DateTime(2026, 7, 1),
        theme: const ChatTheme.light(),
        now: jetzt,
      ),
    ));
    expect(find.text('01.07.2026'), findsOneWidget);
  });
}
