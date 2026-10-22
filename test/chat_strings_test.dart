import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

/// Every field of [s], for completeness checks.
List<String> _all(ChatStrings s) => [
      s.reply, s.copy, s.original, s.retry, s.today, s.yesterday,
      s.messageHint, s.send, s.camera, s.gallery, s.file, s.typing,
      s.spam, s.subject, s.to, s.possibleSpam,
      s.online, s.lastSeenTodayPrefix, s.lastSeenYesterdayPrefix,
      s.lastSeenDatePrefix, s.lastSeenAtJoiner, s.noMailYet, s.body,
    ];

/// Every field of [s] except [ChatStrings.lastSeenAtJoiner], for the
/// trim-based emptiness check below. [lastSeenAtJoiner] is excluded on
/// purpose: for Turkish it is deliberately a single space (Turkish uses no
/// connecting word between an older last-seen date and its time --
/// "son görülme 31.07.2026 14:30" reads correctly on its own), so
/// `.trim().isEmpty` would misreport that intentional value as a forgotten
/// translation. It gets its own, less strict check instead.
List<String> _allExceptJoiner(ChatStrings s) => [
      s.reply, s.copy, s.original, s.retry, s.today, s.yesterday,
      s.messageHint, s.send, s.camera, s.gallery, s.file, s.typing,
      s.spam, s.subject, s.to, s.possibleSpam,
      s.online, s.lastSeenTodayPrefix, s.lastSeenYesterdayPrefix,
      s.lastSeenDatePrefix, s.noMailYet, s.body,
    ];

void main() {
  const presets = <String, ChatStrings>{
    'en': ChatStrings.en(),
    'de': ChatStrings.de(),
    'hr': ChatStrings.hr(),
    'tr': ChatStrings.tr(),
    'uk': ChatStrings.uk(),
  };

  test('jede Sprache füllt alle dreiundzwanzig Felder', () {
    for (final entry in presets.entries) {
      final werte = _all(entry.value);
      expect(werte.length, 23, reason: entry.key);
      expect(
        _allExceptJoiner(entry.value).where((w) => w.trim().isEmpty),
        isEmpty,
        reason: '${entry.key} hat leere Felder',
      );
      // lastSeenAtJoiner darf gezielt aus Leerraum bestehen (siehe
      // _allExceptJoiner) -- geprüft wird hier nur, dass es überhaupt
      // gesetzt ist, nicht dass es nicht-Leerraum enthält.
      expect(entry.value.lastSeenAtJoiner, isNotNull, reason: entry.key);
      expect(entry.value.lastSeenAtJoiner, isNotEmpty, reason: entry.key);
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
      Localizations(
        locale: const Locale('uk'),
        delegates: const [
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        child: Builder(
          builder: (context) {
            ausKontext = ChatStrings.of(context);
            mitOverride =
                ChatStrings.of(context, override: const ChatStrings.de());
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(ausKontext, const ChatStrings.uk());
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

  test('jede Sprache hat einen eigenen Text fuer Sprachnachricht', () {
    const presets = [
      ChatStrings.en(),
      ChatStrings.de(),
      ChatStrings.hr(),
      ChatStrings.tr(),
      ChatStrings.uk(),
    ];
    for (final s in presets) {
      expect(s.voiceMessage.trim(), isNotEmpty);
      expect(s.playbackSpeed.trim(), isNotEmpty);
      expect(s.voicePlaybackFailed.trim(), isNotEmpty);
      expect(s.transcriptLabel.trim(), isNotEmpty);
      expect(s.transcribing.trim(), isNotEmpty);
      expect(s.transcriptUnavailable.trim(), isNotEmpty);
    }
    expect(const ChatStrings.de().voiceMessage, 'Sprachnachricht');
    expect(const ChatStrings.en().voiceMessage, 'Voice message');
    expect(const ChatStrings.en().transcriptLabel, 'Transcript');
    expect(const ChatStrings.de().transcriptLabel, 'Abschrift');
    expect(const ChatStrings.en().voicePlaybackFailed, "Can't play");
    expect(const ChatStrings.de().voicePlaybackFailed, 'Kann nicht abgespielt werden');
  });
}
