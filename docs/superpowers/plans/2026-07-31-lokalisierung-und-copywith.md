# Lokalisierung und leerbares `copyWith` — Implementierungsplan

> **Für agentische Umsetzung:** Aufgabe für Aufgabe abarbeiten
> (`superpowers:subagent-driven-development` oder `superpowers:executing-plans`).
> Schritte nutzen Checkbox-Syntax (`- [ ]`).

**Ziel:** Das Paket spricht fünf Sprachen und wählt sie selbst aus der App —
und `copyWith` kann jedes nullable Feld wieder leeren.

**Architektur:** Ein Wertobjekt `ChatStrings` nach dem Muster von `ChatColors`
trägt fünfzehn Texte, mit `const`-Vorlagen je Sprache. Jedes Widget löst zu
Beginn seiner `build`-Methode einmal auf: ausdrücklich übergebenes `strings:`,
sonst die App-Sprache aus dem `Localizations`-Kontext, sonst Englisch. Für
`copyWith` bekommt jedes nullable Feld einen additiven `clearX`-Schalter.

**Tech-Stack:** Flutter-Paket, reine UI + Wertobjekte, `flutter_test`. **Keine
neue Abhängigkeit** — `Localizations.maybeLocaleOf` steckt in
`package:flutter/widgets.dart`.

**Spec:** [../specs/2026-07-31-lokalisierung-und-copywith-design.md](../specs/2026-07-31-lokalisierung-und-copywith-design.md)

## Globale Vorgaben

- **Arbeitsverzeichnis:** dieses Repo (`kreiseck_chat`). Nichts außerhalb anfassen.
- Doc-Kommentare **englisch**, Commit-Messages **deutsch** — so ist die Historie.
- Keine Hinweise auf Werkzeuge, KI oder Generierung in Code oder Commits.
- **Rein additiv:** Alle neuen Parameter sind optional. Kein bestehender Aufruf
  darf aufhören zu kompilieren oder still sein Verhalten ändern. Einzige
  erlaubte Signaturänderung: `typingLabel` von `String` zu `String?`.
- Keine neue Abhängigkeit, keine Codegenerierung, kein ARB.
- Jedes öffentliche Element bekommt einen `///`-Doc-Kommentar.
- Nach jeder Aufgabe: `flutter test` **komplett** grün und `flutter analyze`
  befundfrei, dann committen.
- Version in `pubspec.yaml` erst in der letzten Aufgabe auf `0.15.0`.

---

## Dateistruktur

| Datei | Verantwortung |
|-------|---------------|
| `lib/src/chat_strings.dart` (neu) | `ChatStrings` mit fünf Sprachvorlagen und Auflösung |
| `lib/kreiseck_chat.dart` (ändern) | Export |
| `lib/src/message_bubble.dart` (ändern) | `reply`, `copy`, `original`, `retry`, `file` |
| `lib/src/date_separator.dart` (ändern) | `today`, `yesterday` |
| `lib/src/composer.dart` (ändern) | `messageHint`, `camera`, `gallery`, `file` |
| `lib/src/chat_header.dart`, `lib/src/conversation_list_view.dart` (ändern) | `typing` |
| `lib/src/mail_composer.dart`, `lib/src/mail_list_view.dart` (ändern) | `to`, `subject`, `send`, `spam` |
| `lib/src/models.dart` (ändern) | `clearX` für `ChatMessage`, `ChatMessageRef`, `ChatConversation` |
| `lib/src/chat_participant.dart`, `chat_attachment.dart`, `mail_models.dart` (ändern) | `clearX` für die übrigen vier Klassen |
| `example/lib/main.dart` (ändern) | Sprachwahl in der Demo |
| `README.md`, `CHANGELOG.md`, `pubspec.yaml` (ändern) | 0.15.0 |

Tests: `test/chat_strings_test.dart` (neu), bestehende Widget- und
Modell-Testdateien erweitern.

---

### Aufgabe 1: `ChatStrings`

**Dateien:**
- Erstellen: `lib/src/chat_strings.dart`
- Ändern: `lib/kreiseck_chat.dart`
- Test: `test/chat_strings_test.dart`

**Schnittstellen:**
- Liefert: `class ChatStrings` mit den Feldern `reply`, `copy`, `original`,
  `retry`, `today`, `yesterday`, `messageHint`, `send`, `camera`, `gallery`,
  `file`, `typing`, `spam`, `subject`, `to` (alle `String`), den
  `const`-Konstruktoren `.en()`, `.de()`, `.hr()`, `.tr()`, `.uk()`,
  `static ChatStrings forLocale(Locale? locale)`,
  `static ChatStrings of(BuildContext context, {ChatStrings? override})`,
  `copyWith(...)`, `operator ==`, `hashCode`.

- [ ] **Schritt 1: Fehlschlagenden Test schreiben**

`test/chat_strings_test.dart`:

```dart
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
        locale: const Locale('uk'),
        supportedLocales: const [Locale('uk'), Locale('en')],
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
}
```

- [ ] **Schritt 2: Test laufen lassen, Fehlschlag prüfen**

Ausführen: `flutter test test/chat_strings_test.dart`
Erwartet: FAIL — `ChatStrings` ist nicht definiert.

- [ ] **Schritt 3: Umsetzen**

`lib/src/chat_strings.dart`:

```dart
import 'package:flutter/widgets.dart';

/// The words the package puts on screen.
///
/// Built like [ChatColors] and [ChatTypography]: one field per string, a
/// `const` preset per language, and `copyWith` to adjust single entries. The
/// widgets resolve it through [ChatStrings.of], so a host that already sets
/// its app locale gets the right language without passing anything.
@immutable
class ChatStrings {
  /// Creates a string set explicitly. Prefer one of the language presets.
  const ChatStrings({
    required this.reply,
    required this.copy,
    required this.original,
    required this.retry,
    required this.today,
    required this.yesterday,
    required this.messageHint,
    required this.send,
    required this.camera,
    required this.gallery,
    required this.file,
    required this.typing,
    required this.spam,
    required this.subject,
    required this.to,
  });

  /// Context-menu entry that quotes a message.
  final String reply;

  /// Context-menu entry that copies a message's text.
  final String copy;

  /// Label shown while a translated message displays its original text.
  final String original;

  /// Action offered next to a failed delivery.
  final String retry;

  /// Day separator for the current day.
  final String today;

  /// Day separator for the previous day.
  final String yesterday;

  /// Placeholder in the composer's input field.
  final String messageHint;

  /// Label of a send button.
  final String send;

  /// Attachment source: the device camera.
  final String camera;

  /// Attachment source: the photo library.
  final String gallery;

  /// Attachment source (and fallback name for an unnamed attachment).
  final String file;

  /// Presence line while someone is typing.
  final String typing;

  /// Tag on a message flagged as junk.
  final String spam;

  /// Mail field: subject line.
  final String subject;

  /// Mail field: recipient.
  final String to;

  /// English — also the fallback for every unsupported language.
  const ChatStrings.en()
      : reply = 'Reply',
        copy = 'Copy',
        original = 'Original',
        retry = 'Send again',
        today = 'Today',
        yesterday = 'Yesterday',
        messageHint = 'Message',
        send = 'Send',
        camera = 'Camera',
        gallery = 'Gallery',
        file = 'File',
        typing = 'typing…',
        spam = 'Spam',
        subject = 'Subject',
        to = 'To';

  /// German.
  const ChatStrings.de()
      : reply = 'Antworten',
        copy = 'Kopieren',
        original = 'Original',
        retry = 'Erneut senden',
        today = 'Heute',
        yesterday = 'Gestern',
        messageHint = 'Nachricht',
        send = 'Senden',
        camera = 'Kamera',
        gallery = 'Galerie',
        file = 'Datei',
        typing = 'tippt…',
        spam = 'Spam',
        subject = 'Betreff',
        to = 'An';

  /// Croatian.
  const ChatStrings.hr()
      : reply = 'Odgovori',
        copy = 'Kopiraj',
        original = 'Izvornik',
        retry = 'Pošalji ponovno',
        today = 'Danas',
        yesterday = 'Jučer',
        messageHint = 'Poruka',
        send = 'Pošalji',
        camera = 'Kamera',
        gallery = 'Galerija',
        file = 'Datoteka',
        typing = 'piše…',
        spam = 'Neželjeno',
        subject = 'Predmet',
        to = 'Za';

  /// Turkish.
  const ChatStrings.tr()
      : reply = 'Yanıtla',
        copy = 'Kopyala',
        original = 'Orijinal',
        retry = 'Yeniden gönder',
        today = 'Bugün',
        yesterday = 'Dün',
        messageHint = 'Mesaj',
        send = 'Gönder',
        camera = 'Kamera',
        gallery = 'Galeri',
        file = 'Dosya',
        typing = 'yazıyor…',
        spam = 'Spam',
        subject = 'Konu',
        to = 'Kime';

  /// Ukrainian.
  const ChatStrings.uk()
      : reply = 'Відповісти',
        copy = 'Копіювати',
        original = 'Оригінал',
        retry = 'Надіслати ще раз',
        today = 'Сьогодні',
        yesterday = 'Учора',
        messageHint = 'Повідомлення',
        send = 'Надіслати',
        camera = 'Камера',
        gallery = 'Галерея',
        file = 'Файл',
        typing = 'пише…',
        spam = 'Спам',
        subject = 'Тема',
        to = 'Кому';

  /// The preset for [locale]'s language, or English when there is none.
  ///
  /// Only `languageCode` is compared — country and script are ignored, so
  /// `de_AT` and `de_DE` share one set.
  static ChatStrings forLocale(Locale? locale) {
    switch (locale?.languageCode) {
      case 'de':
        return const ChatStrings.de();
      case 'hr':
        return const ChatStrings.hr();
      case 'tr':
        return const ChatStrings.tr();
      case 'uk':
        return const ChatStrings.uk();
      default:
        return const ChatStrings.en();
    }
  }

  /// The strings a widget should use: [override] when the host passed one,
  /// otherwise the preset for the ambient locale, otherwise English.
  static ChatStrings of(BuildContext context, {ChatStrings? override}) =>
      override ?? forLocale(Localizations.maybeLocaleOf(context));

  /// Returns a copy with the given fields replaced.
  ChatStrings copyWith({
    String? reply,
    String? copy,
    String? original,
    String? retry,
    String? today,
    String? yesterday,
    String? messageHint,
    String? send,
    String? camera,
    String? gallery,
    String? file,
    String? typing,
    String? spam,
    String? subject,
    String? to,
  }) {
    return ChatStrings(
      reply: reply ?? this.reply,
      copy: copy ?? this.copy,
      original: original ?? this.original,
      retry: retry ?? this.retry,
      today: today ?? this.today,
      yesterday: yesterday ?? this.yesterday,
      messageHint: messageHint ?? this.messageHint,
      send: send ?? this.send,
      camera: camera ?? this.camera,
      gallery: gallery ?? this.gallery,
      file: file ?? this.file,
      typing: typing ?? this.typing,
      spam: spam ?? this.spam,
      subject: subject ?? this.subject,
      to: to ?? this.to,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatStrings &&
        other.reply == reply &&
        other.copy == copy &&
        other.original == original &&
        other.retry == retry &&
        other.today == today &&
        other.yesterday == yesterday &&
        other.messageHint == messageHint &&
        other.send == send &&
        other.camera == camera &&
        other.gallery == gallery &&
        other.file == file &&
        other.typing == typing &&
        other.spam == spam &&
        other.subject == subject &&
        other.to == to;
  }

  @override
  int get hashCode => Object.hash(
        reply, copy, original, retry, today, yesterday, messageHint, send,
        camera, gallery, file, typing, spam, subject, to,
      );
}
```

In `lib/kreiseck_chat.dart` alphabetisch einsortiert ergänzen:

```dart
export 'src/chat_strings.dart';
```

- [ ] **Schritt 4: Test laufen lassen, Erfolg prüfen**

Ausführen: `flutter test test/chat_strings_test.dart`
Erwartet: PASS (7 Tests).

- [ ] **Schritt 5: Committen**

```bash
git add lib/src/chat_strings.dart lib/kreiseck_chat.dart test/chat_strings_test.dart
git commit -m "ChatStrings: fünfzehn Texte in fünf Sprachen mit Auflösung aus dem Kontext"
```

---

### Aufgabe 2: `MessageBubble` spricht die Sprache

**Dateien:**
- Ändern: `lib/src/message_bubble.dart` (Zeilen 158, 163, 279, 357, 573)
- Test: `test/message_bubble_test.dart` (erweitern)

**Schnittstellen:**
- Konsumiert: `ChatStrings.of` (Aufgabe 1).
- Liefert: `MessageBubble.strings` (`ChatStrings?`, Standard `null`).

- [ ] **Schritt 1: Fehlschlagenden Test schreiben**

An `test/message_bubble_test.dart` anhängen:

```dart
  ChatMessage _fehlgeschlagen() => ChatMessage(
        id: 'loc1',
        direction: MessageDirection.outgoing,
        text: 'Hallo',
        at: DateTime(2026, 7, 31, 10),
        status: MessageStatus.failed,
        errorText: 'Grund',
      );

  testWidgets('Texte folgen der App-Sprache', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('uk'),
      supportedLocales: const [Locale('uk'), Locale('en')],
      home: Scaffold(
        body: MessageBubble(message: _fehlgeschlagen(), onRetry: () {}),
      ),
    ));
    expect(find.text('Надіслати ще раз'), findsOneWidget);
  });

  testWidgets('strings-Override gewinnt über die App-Sprache', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('uk'),
      supportedLocales: const [Locale('uk'), Locale('en')],
      home: Scaffold(
        body: MessageBubble(
          message: _fehlgeschlagen(),
          onRetry: () {},
          strings: const ChatStrings.de(),
        ),
      ),
    ));
    expect(find.text('Erneut senden'), findsOneWidget);
  });

  testWidgets('unter Locale de bleibt alles wie bisher', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      supportedLocales: const [Locale('de'), Locale('en')],
      home: Scaffold(
        body: MessageBubble(message: _fehlgeschlagen(), onRetry: () {}),
      ),
    ));
    expect(find.text('Erneut senden'), findsOneWidget);
  });
```

- [ ] **Schritt 2: Test laufen lassen, Fehlschlag prüfen**

Ausführen: `flutter test test/message_bubble_test.dart`
Erwartet: FAIL — benannter Parameter `strings` ist nicht definiert.

- [ ] **Schritt 3: Umsetzen**

1. Import ergänzen: `import 'chat_strings.dart';`
2. Konstruktor und Feld von `MessageBubble`:

```dart
    this.strings,
```
```dart
  /// Overrides the words used by this bubble. Left null, they follow the
  /// ambient locale (see [ChatStrings.of]).
  final ChatStrings? strings;
```

3. In der `build`-Methode des States, bei den übrigen lokalen Aliasen:

```dart
    final strings = ChatStrings.of(context, override: widget.strings);
```

4. Die fünf Fundstellen ersetzen:
   - Z. 158 `'Antworten'` → `strings.reply`
   - Z. 163 `'Kopieren'` → `strings.copy`
   - Z. 279 `'Original'` → `strings.original`
   - Z. 357 `'Erneut senden'` → `strings.retry`
   - Z. 573 `a.fileName ?? 'Datei'` → `a.fileName ?? strings.file`

   Sitzt eine Fundstelle in einer Hilfsmethode ohne Zugriff auf die lokale
   Variable, den aufgelösten `ChatStrings` als Parameter durchreichen — **nicht**
   ein zweites Mal `ChatStrings.of` aufrufen.

- [ ] **Schritt 4: Tests laufen lassen**

Ausführen: `flutter test && flutter analyze`
Erwartet: alles grün, keine Befunde. Bestehende Tests, die auf deutschen
Texten prüfen, müssen weiter grün sein — sie laufen ohne `Localizations`
und bekämen dann Englisch. Schlägt einer fehl, im Test ein
`strings: const ChatStrings.de()` bzw. eine `MaterialApp(locale: Locale('de'))`
ergänzen, **nicht** den erwarteten Text ändern.

- [ ] **Schritt 5: Committen**

```bash
git add lib/src/message_bubble.dart test/message_bubble_test.dart
git commit -m "MessageBubble: Texte aus ChatStrings statt fest verdrahtet"
```

---

### Aufgabe 3: `DateSeparator`

**Dateien:**
- Ändern: `lib/src/date_separator.dart` (Zeilen 28-35)
- Test: `test/` — neue Datei `test/date_separator_test.dart`, falls keine existiert

**Schnittstellen:**
- Konsumiert: `ChatStrings.of` (Aufgabe 1).
- Liefert: `DateSeparator.strings` (`ChatStrings?`, Standard `null`).

- [ ] **Schritt 1: Fehlschlagenden Test schreiben**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  final jetzt = DateTime(2026, 7, 31, 12);

  testWidgets('Heute/Gestern folgen der App-Sprache', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('uk'),
      supportedLocales: const [Locale('uk'), Locale('en')],
      home: Scaffold(
        body: Column(children: [
          DateSeparator(date: jetzt, now: jetzt),
          DateSeparator(date: jetzt.subtract(const Duration(days: 1)), now: jetzt),
        ]),
      ),
    ));
    expect(find.text('Сьогодні'), findsOneWidget);
    expect(find.text('Учора'), findsOneWidget);
  });

  testWidgets('unter Locale de bleibt es Heute/Gestern', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      supportedLocales: const [Locale('de'), Locale('en')],
      home: Scaffold(body: DateSeparator(date: jetzt, now: jetzt)),
    ));
    expect(find.text('Heute'), findsOneWidget);
  });

  testWidgets('labelBuilder gewinnt weiterhin über alles', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('uk'),
      supportedLocales: const [Locale('uk'), Locale('en')],
      home: Scaffold(
        body: DateSeparator(
          date: jetzt,
          now: jetzt,
          labelBuilder: (_, _) => 'Eigen',
        ),
      ),
    ));
    expect(find.text('Eigen'), findsOneWidget);
  });

  testWidgets('ältere Tage zeigen weiterhin das Datum', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      supportedLocales: const [Locale('de'), Locale('en')],
      home: Scaffold(
        body: DateSeparator(
          date: DateTime(2026, 7, 1),
          now: jetzt,
        ),
      ),
    ));
    expect(find.text('01.07.2026'), findsOneWidget);
  });
}
```

- [ ] **Schritt 2: Test laufen lassen, Fehlschlag prüfen**

Ausführen: `flutter test test/date_separator_test.dart`
Erwartet: FAIL — die ukrainischen Texte erscheinen nicht.

- [ ] **Schritt 3: Umsetzen**

1. Import `import 'chat_strings.dart';`
2. Konstruktor/Feld ergänzen:

```dart
    this.strings,
```
```dart
  /// Overrides the words used by this separator. Left null, they follow the
  /// ambient locale (see [ChatStrings.of]).
  final ChatStrings? strings;
```

3. `_defaultLabel` bekommt die aufgelösten Texte als Parameter:

```dart
  String _defaultLabel(DateTime d, DateTime ref, ChatStrings strings) {
    final today = DateTime(ref.year, ref.month, ref.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return strings.today;
    if (diff == 1) return strings.yesterday;
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
```

4. In `build` auflösen und durchreichen:

```dart
    final resolved = ChatStrings.of(context, override: strings);
```
und den Aufruf von `_defaultLabel(...)` um `resolved` erweitern. `labelBuilder`
behält Vorrang wie bisher.

- [ ] **Schritt 4: Tests laufen lassen**

Ausführen: `flutter test && flutter analyze`
Erwartet: alles grün, keine Befunde.

- [ ] **Schritt 5: Committen**

```bash
git add lib/src/date_separator.dart test/date_separator_test.dart
git commit -m "DateSeparator: Heute/Gestern aus ChatStrings"
```

---

### Aufgabe 4: `Composer`

**Dateien:**
- Ändern: `lib/src/composer.dart` (Zeilen 135, 143, 151, 209)
- Test: `test/composer_test.dart` (erweitern)

**Schnittstellen:**
- Konsumiert: `ChatStrings.of` (Aufgabe 1).
- Liefert: `Composer.strings` (`ChatStrings?`, Standard `null`).

- [ ] **Schritt 1: Fehlschlagenden Test schreiben**

An `test/composer_test.dart` anhängen:

```dart
  testWidgets('Platzhalter folgt der App-Sprache', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('uk'),
      supportedLocales: const [Locale('uk'), Locale('en')],
      home: Scaffold(body: Composer(onSend: (_) {})),
    ));
    expect(find.text('Повідомлення'), findsOneWidget);
  });

  testWidgets('hintText gewinnt weiterhin über die Sprache', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('uk'),
      supportedLocales: const [Locale('uk'), Locale('en')],
      home: Scaffold(
        body: Composer(onSend: (_) {}, hintText: 'Eigener Platzhalter'),
      ),
    ));
    expect(find.text('Eigener Platzhalter'), findsOneWidget);
  });

  testWidgets('Anhang-Auswahl folgt der App-Sprache', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('uk'),
      supportedLocales: const [Locale('uk'), Locale('en')],
      home: Scaffold(
        body: Composer(
          onSend: (_) {},
          onAttach: (_) {},
          capabilities: const ChatCapabilities.inApp(),
        ),
      ),
    ));
    await tester.tap(find.byIcon(const ChatIcons().attach).last);
    await tester.pumpAndSettle();
    expect(find.text('Камера'), findsOneWidget);
    expect(find.text('Галерея'), findsOneWidget);
    expect(find.text('Файл'), findsOneWidget);
  });
```

> `theme.icons.attach` erscheint zweimal: als Knopf in der Eingabezeile
> (`composer.dart:194`) und als Symbol des Eintrags „Datei" im Blatt
> (`composer.dart:150`). Vor dem Öffnen gibt es nur den Knopf, deshalb genügt
> hier `.last` nicht zwingend — schlägt der Finder fehl, `find.byIcon(...)`
> ohne `.last` verwenden. Der Knopf erscheint nur bei `capabilities.media`.

- [ ] **Schritt 2: Test laufen lassen, Fehlschlag prüfen**

Ausführen: `flutter test test/composer_test.dart`
Erwartet: FAIL — die ukrainischen Texte erscheinen nicht.

- [ ] **Schritt 3: Umsetzen**

1. Import `import 'chat_strings.dart';`
2. Konstruktor/Feld:

```dart
    this.strings,
```
```dart
  /// Overrides the words used by this composer. Left null, they follow the
  /// ambient locale (see [ChatStrings.of]).
  final ChatStrings? strings;
```

3. In `build` auflösen:

```dart
    final strings = ChatStrings.of(context, override: widget.strings);
```

4. Z. 209 `widget.hintText ?? 'Nachricht'` → `widget.hintText ?? strings.messageHint`

5. Das Anhang-Blatt (`showModalBottomSheet`, ab Z. 128) bekommt die
   aufgelösten Texte **von außen** gereicht — der Blatt-Kontext ist ein
   anderer, und ein zweiter Aufruf von `ChatStrings.of` dort wäre eine zweite
   Quelle der Wahrheit. Also die Methode, die das Blatt öffnet, um einen
   Parameter `ChatStrings strings` erweitern und beim Aufruf den bereits
   aufgelösten Wert übergeben. Dann:
   - Z. 135 `const Text('Kamera')` → `Text(strings.camera)`
   - Z. 143 `const Text('Galerie')` → `Text(strings.gallery)`
   - Z. 151 `const Text('Datei')` → `Text(strings.file)`

   Das `const` muss dabei jeweils entfallen.

- [ ] **Schritt 4: Tests laufen lassen**

Ausführen: `flutter test && flutter analyze`
Erwartet: alles grün, keine Befunde.

- [ ] **Schritt 5: Committen**

```bash
git add lib/src/composer.dart test/composer_test.dart
git commit -m "Composer: Platzhalter und Anhang-Auswahl aus ChatStrings"
```

---

### Aufgabe 5: `ChatHeader` und `ConversationListView`

**Dateien:**
- Ändern: `lib/src/chat_header.dart` (Zeilen 24, 58, 61)
- Ändern: `lib/src/conversation_list_view.dart` (Zeile 20 und die Weitergabe an die Zeile)
- Test: `test/chat_header_test.dart`, `test/conversation_list_view_test.dart` (erweitern)

**Schnittstellen:**
- Konsumiert: `ChatStrings.of` (Aufgabe 1).
- Liefert: an beiden Widgets `strings` (`ChatStrings?`) und `typingLabel` mit
  geändertem Typ `String?` (vorher `String` mit Standard `'tippt…'`).

- [ ] **Schritt 1: Fehlschlagenden Test schreiben**

An `test/chat_header_test.dart` anhängen:

```dart
  testWidgets('Tipp-Hinweis folgt der App-Sprache', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('uk'),
      supportedLocales: [Locale('uk'), Locale('en')],
      home: Scaffold(
        body: ChatHeader(title: 'Ada', typing: true),
      ),
    ));
    expect(find.text('пише…'), findsOneWidget);
  });

  testWidgets('typingLabel gewinnt weiterhin', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('uk'),
      supportedLocales: [Locale('uk'), Locale('en')],
      home: Scaffold(
        body: ChatHeader(title: 'Ada', typing: true, typingLabel: 'schreibt'),
      ),
    ));
    expect(find.text('schreibt'), findsOneWidget);
  });
```

An `test/conversation_list_view_test.dart` anhängen:

```dart
  testWidgets('Tipp-Vorschau folgt der App-Sprache', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('uk'),
      supportedLocales: const [Locale('uk'), Locale('en')],
      home: Scaffold(
        body: ConversationListView(
          conversations: const [
            ChatConversation(id: 'c1', title: 'Ada', typing: true),
          ],
          onOpen: (_) {},
        ),
      ),
    ));
    expect(find.text('пише…'), findsOneWidget);
  });
```

> Erscheint die Tipp-Vorschau nicht: sie hängt an
> `capabilities.typingIndicator`. Dann im Test die passenden `capabilities`
> mitgeben.

- [ ] **Schritt 2: Tests laufen lassen, Fehlschlag prüfen**

Ausführen: `flutter test test/chat_header_test.dart test/conversation_list_view_test.dart`
Erwartet: FAIL — der ukrainische Text erscheint nicht.

- [ ] **Schritt 3: Umsetzen**

In **beiden** Dateien:

1. Import `import 'chat_strings.dart';`
2. `typingLabel` von `String typingLabel = 'tippt…'` zu `String? typingLabel`
   ändern (Standardwert entfällt) und den Doc-Kommentar anpassen: ohne Wert
   kommt der Text aus [ChatStrings].
3. Feld `strings` ergänzen:

```dart
    this.strings,
```
```dart
  /// Overrides the words used here. Left null, they follow the ambient
  /// locale (see [ChatStrings.of]).
  final ChatStrings? strings;
```

4. Dort, wo `typingLabel` verwendet wird, auflösen:

```dart
    final resolved = ChatStrings.of(context, override: strings);
    // …
    if (typing && capabilities.typingIndicator) {
      return typingLabel ?? resolved.typing;
    }
```

In `conversation_list_view.dart` reicht das interne Zeilen-Widget den
aufgelösten Wert als Feld weiter — **nicht** dort erneut auflösen.

- [ ] **Schritt 4: Tests laufen lassen**

Ausführen: `flutter test && flutter analyze`
Erwartet: alles grün, keine Befunde. Bestehende Tests, die `'tippt…'`
erwarten, laufen ohne `Localizations` und bekommen jetzt `'typing…'` — in
diesen Tests eine `MaterialApp(locale: Locale('de'))` ergänzen, **nicht** die
Erwartung ändern.

- [ ] **Schritt 5: Committen**

```bash
git add lib/src/chat_header.dart lib/src/conversation_list_view.dart test/chat_header_test.dart test/conversation_list_view_test.dart
git commit -m "ChatHeader und ConversationListView: Tipp-Hinweis aus ChatStrings"
```

---

### Aufgabe 6: Die Mail-Widgets

**Dateien:**
- Ändern: `lib/src/mail_composer.dart` (Zeilen 94, 100, 120)
- Ändern: `lib/src/mail_list_view.dart` (Zeile 183)
- Test: `test/mail_composer_test.dart`, `test/mail_list_view_test.dart` (erweitern oder neu)

**Schnittstellen:**
- Konsumiert: `ChatStrings.of` (Aufgabe 1).
- Liefert: an beiden Widgets `strings` (`ChatStrings?`, Standard `null`).

- [ ] **Schritt 1: Fehlschlagenden Test schreiben**

```dart
  testWidgets('Mail-Felder folgen der App-Sprache', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('uk'),
      supportedLocales: const [Locale('uk'), Locale('en')],
      home: Scaffold(
        body: MailComposer(onSend: (String to, String subject, String body) {}),
      ),
    ));
    expect(find.text('Кому'), findsOneWidget);
    expect(find.text('Тема'), findsOneWidget);
    expect(find.text('Надіслати'), findsOneWidget);
  });
```


Für die Liste:

```dart
  testWidgets('Spam-Kennzeichnung folgt der App-Sprache', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('uk'),
      supportedLocales: const [Locale('uk'), Locale('en')],
      home: Scaffold(
        body: MailListView(
          messages: [
            MailMessage(
              id: 'm1',
              direction: MailDirection.incoming,
              from: 'ada@example.invalid',
              to: 'ich@example.invalid',
              subject: 'Angebot',
              bodyText: 'Text',
              date: DateTime(2026, 7, 31, 10),
              spam: true,
            ),
          ],
          onOpen: (_) {},
        ),
      ),
    ));
    expect(find.text('Спам'), findsOneWidget);
  });
```


- [ ] **Schritt 2: Tests laufen lassen, Fehlschlag prüfen**

Ausführen: `flutter test test/mail_composer_test.dart test/mail_list_view_test.dart`
Erwartet: FAIL — die ukrainischen Texte erscheinen nicht.

- [ ] **Schritt 3: Umsetzen**

In beiden Dateien Import, Feld `strings` und Auflösung in `build` wie in den
vorigen Aufgaben, dann:
- `mail_composer.dart` Z. 94 `labelText: 'An'` → `labelText: strings.to`
- `mail_composer.dart` Z. 100 `labelText: 'Betreff'` → `labelText: strings.subject`
- `mail_composer.dart` Z. 120 `const Text('Senden')` → `Text(strings.send)`
- `mail_list_view.dart` Z. 183 `'Spam'` → `strings.spam`

`_SpamLabel` ist ein eigenes Widget: den aufgelösten Text als Feld
hineinreichen, nicht dort erneut auflösen. Die `const` an den betroffenen
Stellen entfallen.

- [ ] **Schritt 4: Tests laufen lassen**

Ausführen: `flutter test && flutter analyze`
Erwartet: alles grün, keine Befunde.

- [ ] **Schritt 5: Committen**

```bash
git add lib/src/mail_composer.dart lib/src/mail_list_view.dart test/
git commit -m "Mail-Widgets: Beschriftungen aus ChatStrings"
```

---

### Aufgabe 7: `clearX` in `models.dart`

**Dateien:**
- Ändern: `lib/src/models.dart` — `ChatMessage`, `ChatMessageRef`, `ChatConversation`
- Test: `test/chat_message_fields_test.dart`, `test/chat_conversation_fields_test.dart` (erweitern)

**Schnittstellen:**
- Liefert: je nullable Feld einen Parameter `clear<FeldName>` (`bool`, Standard
  `false`) an `copyWith`:
  - `ChatMessage`: `clearSender`, `clearReplyTo`, `clearEditedAt`,
    `clearDeliveredAt`, `clearReadAt`, `clearChannel`, `clearErrorText`,
    `clearTranslation`, `clearHeadline`
  - `ChatMessageRef`: `clearSenderLabel`
  - `ChatConversation`: `clearSubtitle`, `clearChannelLabel`, `clearLastText`,
    `clearLastAt`, `clearAvatar`, `clearAvatarUrl`, `clearPresence`

- [ ] **Schritt 1: Fehlschlagenden Test schreiben**

An `test/chat_message_fields_test.dart` anhängen:

```dart
  test('clearErrorText leert, ein normaler Aufruf behält', () {
    final mitFehler = basis(errorText: 'Grund');
    expect(mitFehler.copyWith(clearErrorText: true).errorText, isNull);
    // Der Regressionsfall: ohne clear bleibt der Wert stehen.
    expect(mitFehler.copyWith(status: MessageStatus.sent).errorText, 'Grund');
  });

  test('jedes nullable Feld von ChatMessage lässt sich leeren', () {
    final voll = ChatMessage(
      id: 'm1',
      direction: MessageDirection.outgoing,
      text: 'Hallo',
      at: DateTime(2026, 7, 31, 10),
      sender: const ChatParticipant(id: 'a', displayName: 'Ada'),
      replyTo: const ChatMessageRef(id: 'x', snippet: 'y'),
      editedAt: DateTime(2026, 7, 31, 11),
      deliveredAt: DateTime(2026, 7, 31, 12),
      readAt: DateTime(2026, 7, 31, 13),
      channel: const ChatChannel.sms(),
      errorText: 'Grund',
      translation: const ChatTranslation(text: 'Hi', languageLabel: 'EN'),
      headline: 'Betreff',
    );
    final leer = voll.copyWith(
      clearSender: true,
      clearReplyTo: true,
      clearEditedAt: true,
      clearDeliveredAt: true,
      clearReadAt: true,
      clearChannel: true,
      clearErrorText: true,
      clearTranslation: true,
      clearHeadline: true,
    );
    expect(leer.sender, isNull);
    expect(leer.replyTo, isNull);
    expect(leer.editedAt, isNull);
    expect(leer.deliveredAt, isNull);
    expect(leer.readAt, isNull);
    expect(leer.channel, isNull);
    expect(leer.errorText, isNull);
    expect(leer.translation, isNull);
    expect(leer.headline, isNull);
    // Nicht-nullable Felder bleiben unangetastet.
    expect(leer.id, 'm1');
    expect(leer.text, 'Hallo');
  });

  test('clear zusammen mit einem Wert ist ein Programmierfehler', () {
    expect(
      () => basis().copyWith(errorText: 'x', clearErrorText: true),
      throwsAssertionError,
    );
  });
```

An `test/chat_conversation_fields_test.dart` anhängen:

```dart
  test('jedes nullable Feld von ChatConversation lässt sich leeren', () {
    final voll = ChatConversation(
      id: 'c1',
      title: 'Ada',
      subtitle: 'Untertitel',
      channelLabel: 'SMS',
      lastText: 'Text',
      lastAt: DateTime(2026, 7, 31, 10),
      avatarUrl: 'https://example.invalid/a.png',
      presence: const ChatPresence.online(),
    );
    final leer = voll.copyWith(
      clearSubtitle: true,
      clearChannelLabel: true,
      clearLastText: true,
      clearLastAt: true,
      clearAvatar: true,
      clearAvatarUrl: true,
      clearPresence: true,
    );
    expect(leer.subtitle, isNull);
    expect(leer.channelLabel, isNull);
    expect(leer.lastText, isNull);
    expect(leer.lastAt, isNull);
    expect(leer.avatar, isNull);
    expect(leer.avatarUrl, isNull);
    expect(leer.presence, isNull);
    expect(leer.title, 'Ada');
  });

  test('ChatMessageRef: senderLabel lässt sich leeren', () {
    const voll = ChatMessageRef(id: 'x', snippet: 'y', senderLabel: 'Ada');
    expect(voll.copyWith(clearSenderLabel: true).senderLabel, isNull);
    expect(voll.copyWith(snippet: 'z').senderLabel, 'Ada');
  });
```

> Baut `basis(...)` in `chat_message_fields_test.dart` nicht alle hier
> genutzten Felder, die vorhandene Hilfsfunktion entsprechend erweitern.

- [ ] **Schritt 2: Tests laufen lassen, Fehlschlag prüfen**

Ausführen: `flutter test test/chat_message_fields_test.dart test/chat_conversation_fields_test.dart`
Erwartet: FAIL — benannter Parameter `clearErrorText` ist nicht definiert.

- [ ] **Schritt 3: Umsetzen**

Für jedes nullable Feld nach diesem Muster — hier an `errorText` gezeigt:

```dart
  ChatMessage copyWith({
    /* … bestehende Parameter unverändert … */
    bool clearErrorText = false,
  }) {
    assert(
      !(clearErrorText && errorText != null),
      'clearErrorText und ein errorText-Wert schließen sich aus.',
    );
    return ChatMessage(
      /* … */
      errorText: clearErrorText ? null : (errorText ?? this.errorText),
    );
  }
```

Die bestehenden Parameter, ihre Reihenfolge und alle nicht-nullable Felder
bleiben unverändert. Doc-Kommentar an `copyWith` (englisch) ergänzen: ein
`clearX` leert das Feld, ein Wert setzt es, beides zusammen ist ein
Programmierfehler.

- [ ] **Schritt 4: Tests laufen lassen**

Ausführen: `flutter test && flutter analyze`
Erwartet: alles grün, keine Befunde.

- [ ] **Schritt 5: Committen**

```bash
git add lib/src/models.dart test/chat_message_fields_test.dart test/chat_conversation_fields_test.dart
git commit -m "copyWith: nullable Felder von ChatMessage, ChatMessageRef und ChatConversation leerbar"
```

---

### Aufgabe 8: `clearX` in den übrigen vier Klassen

**Dateien:**
- Ändern: `lib/src/chat_participant.dart` — `ChatPresence`, `ChatParticipant`
- Ändern: `lib/src/chat_attachment.dart` — `ChatAttachment`
- Ändern: `lib/src/mail_models.dart` — `MailMessage`
- Test: `test/chat_participant_test.dart`, `test/chat_attachment_test.dart`,
  `test/mail_models_test.dart` (erweitern)

**Schnittstellen:**
- Konsumiert: dasselbe Muster wie Aufgabe 7.
- Liefert:
  - `ChatPresence`: `clearLastSeen`, `clearCustomLabel`
  - `ChatParticipant`: `clearAvatar`, `clearAvatarUrl`, `clearPresence`, `clearColor`
  - `ChatAttachment`: `clearUrl`, `clearThumbnail`, `clearThumbnailUrl`,
    `clearFileName`, `clearSizeBytes`, `clearWidth`, `clearHeight`
  - `MailMessage`: `clearBodyHtml`

- [ ] **Schritt 1: Fehlschlagenden Test schreiben**

Je Klasse ein Test nach diesem Muster (hier `ChatAttachment`):

```dart
  test('jedes nullable Feld von ChatAttachment lässt sich leeren', () {
    const voll = ChatAttachment(
      kind: AttachmentKind.image,
      url: 'https://example.invalid/a.png',
      thumbnailUrl: 'https://example.invalid/t.png',
      fileName: 'a.png',
      sizeBytes: 1024,
      width: 800,
      height: 600,
    );
    final leer = voll.copyWith(
      clearUrl: true,
      clearThumbnail: true,
      clearThumbnailUrl: true,
      clearFileName: true,
      clearSizeBytes: true,
      clearWidth: true,
      clearHeight: true,
    );
    expect(leer.url, isNull);
    expect(leer.thumbnail, isNull);
    expect(leer.thumbnailUrl, isNull);
    expect(leer.fileName, isNull);
    expect(leer.sizeBytes, isNull);
    expect(leer.width, isNull);
    expect(leer.height, isNull);
    expect(leer.kind, AttachmentKind.image);
  });

  test('ohne clear bleibt der Wert stehen', () {
    const voll = ChatAttachment(kind: AttachmentKind.file, fileName: 'a.pdf');
    expect(voll.copyWith(sizeBytes: 10).fileName, 'a.pdf');
  });
```

Dasselbe für die drei übrigen Klassen — jeweils mit einem vollständig
gefüllten Exemplar, einem Aufruf, der alle `clearX` setzt, und einem
Gegentest ohne `clear`. Die Konstruktoren:

```dart
// ChatParticipant (chat_participant.dart:64)
const ChatParticipant(
  id: 'a',
  displayName: 'Ada',
  avatarUrl: 'https://example.invalid/a.png',
  presence: ChatPresence.online(),
  color: Color(0xFF3478F6),
);
// → clearAvatar, clearAvatarUrl, clearPresence, clearColor

// ChatPresence (chat_participant.dart:10) — Felder lastSeen, customLabel
// → clearLastSeen, clearCustomLabel

// MailMessage (mail_models.dart:107)
MailMessage(
  id: 'm1',
  direction: MailDirection.incoming,
  from: 'ada@example.invalid',
  to: 'ich@example.invalid',
  subject: 'Angebot',
  bodyText: 'Text',
  date: DateTime(2026, 7, 31, 10),
  bodyHtml: '<p>Text</p>',
);
// → clearBodyHtml
```

Existiert für eine Klasse noch keine Testdatei, eine neue nach dem Muster der
vorhandenen anlegen.

- [ ] **Schritt 2: Tests laufen lassen, Fehlschlag prüfen**

Ausführen: `flutter test`
Erwartet: FAIL — die `clearX`-Parameter sind nicht definiert.

- [ ] **Schritt 3: Umsetzen**

Dasselbe Muster wie in Aufgabe 7, je Feld:

```dart
    bool clearFileName = false,
```
```dart
    assert(
      !(clearFileName && fileName != null),
      'clearFileName und ein fileName-Wert schließen sich aus.',
    );
```
```dart
      fileName: clearFileName ? null : (fileName ?? this.fileName),
```

- [ ] **Schritt 4: Tests laufen lassen**

Ausführen: `flutter test && flutter analyze`
Erwartet: alles grün, keine Befunde.

- [ ] **Schritt 5: Committen**

```bash
git add lib/src/chat_participant.dart lib/src/chat_attachment.dart lib/src/mail_models.dart test/
git commit -m "copyWith: nullable Felder von Presence, Participant, Attachment und MailMessage leerbar"
```

---

### Aufgabe 9: Beispiel, Doku und Version 0.15.0

**Dateien:**
- Ändern: `example/lib/main.dart`
- Ändern: `README.md`, `CHANGELOG.md`, `pubspec.yaml`

**Schnittstellen:**
- Konsumiert: alles aus den Aufgaben 1–8.

- [ ] **Schritt 1: Sprachwahl in die Demo einbauen**

In `example/lib/main.dart` ein Feld `Locale _locale = const Locale('de');`
ergänzen, in der `MaterialApp` `locale: _locale` und
`supportedLocales: const [Locale('en'), Locale('de'), Locale('hr'), Locale('tr'), Locale('uk')]`
setzen, und in `_controls()` ein `DropdownButton<Locale>` mit diesen fünf
Einträgen. Nichts an den Widgets selbst übergeben — genau das ist der Punkt:
Die Demo zeigt, dass die Sprache allein aus der App kommt.

- [ ] **Schritt 2: Beispiel prüfen**

Ausführen: `cd example && flutter analyze`
Erwartet: keine Befunde.

Ausführen: `cd example && flutter build apk --debug`
Erwartet: Bau erfolgreich.

- [ ] **Schritt 3: README ergänzen**

Im Abschnitt „Features" einen Punkt zu `ChatStrings` aufnehmen, mit diesem
Beispiel:

```dart
// Nothing to pass: the widgets follow the app's locale.
MaterialApp(
  locale: const Locale('uk'),
  supportedLocales: const [Locale('uk'), Locale('en')],
  home: ChatThreadView(messages: messages, onSend: send),
);

// Or override a single word:
ChatThreadView(
  messages: messages,
  onSend: send,
  strings: const ChatStrings.de().copyWith(retry: 'Nochmal versuchen'),
);
```

Dazu ein Satz zu `copyWith`: `clearX: true` leert ein nullable Feld.

- [ ] **Schritt 4: CHANGELOG und Version**

`CHANGELOG.md` oben ergänzen:

```markdown
## 0.15.0

**Behavior change:** hosts that set **no** locale (no `Localizations` ancestor,
or a language the package doesn't ship) now see the UI in **English** instead
of German. Set your app's locale, or pass
`strings: const ChatStrings.de()`, to keep German.

* New `ChatStrings` — the fifteen words the package puts on screen, with
  `const` presets for English, German, Croatian, Turkish and Ukrainian, plus
  `copyWith`. Widgets resolve it through `ChatStrings.of`: an explicit
  `strings:` wins, otherwise the ambient locale decides, otherwise English.
  No new dependency, no code generation.
* Every widget that showed text gained an optional `strings` parameter:
  `MessageBubble`, `DateSeparator`, `Composer`, `ChatHeader`,
  `ConversationListView`, `MailComposer`, `MailListView`.
* `typingLabel` on `ChatHeader`/`ConversationListView` changed from `String`
  to `String?`; left null it now follows `ChatStrings.typing`. Passing a value
  works exactly as before.
* `copyWith` on `ChatMessage`, `ChatMessageRef`, `ChatConversation`,
  `ChatParticipant`, `ChatPresence`, `ChatAttachment` and `MailMessage` gained
  a `clear<Field>` flag for every nullable field, so a set value can be
  removed again — previously `copyWith(errorText: null)` meant "keep".
  Existing calls are unaffected.
```

In `pubspec.yaml`: `version: 0.15.0`.

- [ ] **Schritt 5: Vollständige Prüfung**

Ausführen: `flutter analyze && flutter test`
Erwartet: keine Befunde, alle Tests grün.

Ausführen: `flutter pub publish --dry-run`
Erwartet: keine neuen Warnungen gegenüber vorher.

- [ ] **Schritt 6: Committen**

```bash
git add example README.md CHANGELOG.md pubspec.yaml
git commit -m "Beispiel mit Sprachwahl, README und CHANGELOG für 0.15.0"
```

---

## Test-Checkliste für dich (Nutzer)

In der Beispiel-App (`cd example && flutter run`):

1. Sprachwahl auf **Ukrainisch**: Eingabefeld-Platzhalter, Datumstrenner und
   Tipp-Hinweis wechseln mit.
2. Auf eine Nachricht lange drücken: Kontextmenü zeigt „Відповісти" und
   „Копіювати".
3. Die fehlgeschlagene Nachricht: die Wiederholen-Aktion heißt
   „Надіслати ще раз".
4. Die übersetzte Nachricht antippen: das Label wechselt zwischen „Оригінал"
   und dem Sprachkürzel.
5. Anhang-Knopf: Kamera/Galerie/Datei auf Ukrainisch.
6. Auf **Kroatisch** und **Türkisch** dasselbe stichprobenartig — hier bitte
   besonders auf Formulierungen achten, die dir schief vorkommen.
7. Auf **Deutsch** zurückschalten: alles steht wieder exakt wie vor diesem
   Release.
8. Eine Sprache wählen, die es nicht gibt (im Code kurz `Locale('fr')`
   eintragen): alles erscheint auf Englisch, nichts bleibt leer.

## Externe TODOs

- **Muttersprachliche Durchsicht** von Kroatisch, Türkisch und Ukrainisch.
  Diskutabel sind vor allem „Neželjeno" für Spam, die Auslassungspunkte bei
  `piše…`/`yazıyor…`/`пише…` und die Länge von „Надіслати ще раз" auf einem
  Textknopf.
- **Veröffentlichen** (`flutter pub publish`) nach deiner Abnahme.
