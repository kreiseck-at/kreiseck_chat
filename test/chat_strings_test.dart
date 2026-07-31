import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

/// Every field of [s], for completeness checks.
List<String> _all(ChatStrings s) => [
      s.reply, s.copy, s.original, s.retry, s.today, s.yesterday,
      s.messageHint, s.send, s.camera, s.gallery, s.file, s.typing,
      s.spam, s.subject, s.to,
    ];

void main() {
  const presets = <String, ChatStrings>{
    'en': ChatStrings.en(),
    'de': ChatStrings.de(),
    'hr': ChatStrings.hr(),
    'tr': ChatStrings.tr(),
    'uk': ChatStrings.uk(),
  };

  test('jede Sprache füllt alle fünfzehn Felder', () {
    for (final entry in presets.entries) {
      final werte = _all(entry.value);
      expect(werte.length, 15, reason: entry.key);
      expect(
        werte.where((w) => w.trim().isEmpty),
        isEmpty,
        reason: '${entry.key} hat leere Felder',
      );
    }
  });

  test('jede Sprache unterscheidet sich deutlich von Englisch', () {
    const en = ChatStrings.en();
    for (final entry in presets.entries) {
      if (entry.key == 'en') continue;
      final eigen = _all(entry.value);
      final englisch = _all(en);
      var verschieden = 0;
      for (var i = 0; i < eigen.length; i++) {
        if (eigen[i] != englisch[i]) verschieden++;
      }
      // Einzelne Gleichstände sind erlaubt (Kamera/Camera, Spam/Spam),
      // aber eine Vorlage, die überwiegend Englisch enthält, ist ein Fehler.
      expect(verschieden, greaterThanOrEqualTo(10), reason: entry.key);
    }
  });

  test('forLocale trifft die Sprache und fällt sonst auf Englisch zurück', () {
    expect(ChatStrings.forLocale(const Locale('de')), const ChatStrings.de());
    expect(ChatStrings.forLocale(const Locale('uk')), const ChatStrings.uk());
    expect(ChatStrings.forLocale(const Locale('hr')), const ChatStrings.hr());
    expect(ChatStrings.forLocale(const Locale('tr')), const ChatStrings.tr());
    // Land und Schrift spielen keine Rolle.
    expect(
      ChatStrings.forLocale(const Locale('de', 'AT')),
      const ChatStrings.de(),
    );
    // Nicht gepflegt bzw. gar keine Sprache.
    expect(ChatStrings.forLocale(const Locale('fr')), const ChatStrings.en());
    expect(ChatStrings.forLocale(null), const ChatStrings.en());
  });

  testWidgets('of: Kontext-Sprache gewinnt, override gewinnt darüber',
      (tester) async {
    late ChatStrings ausKontext;
    late ChatStrings mitOverride;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            ausKontext = ChatStrings.of(context);
            mitOverride =
                ChatStrings.of(context, override: const ChatStrings.de());
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(ausKontext, const ChatStrings.en());
    expect(mitOverride, const ChatStrings.de());
  });

  testWidgets('of: ohne Localizations kommt Englisch', (tester) async {
    late ChatStrings aufgeloest;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          aufgeloest = ChatStrings.of(context);
          return const SizedBox.shrink();
        },
      ),
    );
    expect(aufgeloest, const ChatStrings.en());
  });

  test('copyWith ersetzt nur das Angegebene', () {
    const de = ChatStrings.de();
    final eigen = de.copyWith(reply: 'Zurückschreiben');
    expect(eigen.reply, 'Zurückschreiben');
    expect(eigen.copy, de.copy);
  });

  test('Wertgleichheit', () {
    expect(const ChatStrings.de(), const ChatStrings.de());
    expect(const ChatStrings.de().hashCode, const ChatStrings.de().hashCode);
    expect(const ChatStrings.de() == const ChatStrings.en(), isFalse);
  });
}
