# Lokalisierung und leerbares `copyWith` — Design

- **Datum:** 2026-07-31
- **Ziel-Version:** 0.15.0
- **Status:** specced
- **Umfang:** Paket `kreiseck_chat`. Zwei unabhängige Teile, die zusammen ein
  Release ergeben.

## Ziel

Zwei Lücken schließen, die ein veröffentlichtes Paket nicht haben sollte:

1. **Alle sichtbaren Texte sind fest verdrahtet — und deutsch**, in einem
   ansonsten englisch dokumentierten Paket. Ein Fremdprojekt kann sie weder
   übersetzen noch überschreiben.
2. **`copyWith` kann ein gesetztes nullable Feld nicht wieder leeren**
   (`errorText ?? this.errorText`). Wer eine fehlgeschlagene Nachricht nach
   erfolgreichem Wiederholen aufräumen will, muss sie von Hand neu bauen — und
   verliert dabei leicht ein Feld.

**Erfolgskriterien:**

- Das Paket spricht Englisch, Deutsch, Kroatisch, Türkisch und Ukrainisch und
  wählt die Sprache selbst aus dem `Localizations`-Kontext der App.
- Für bestehende Hosts, die eine Sprache setzen, ändert sich nichts.
- Jedes nullable Feld eines Wertmodells lässt sich über `copyWith` leeren, ohne
  dass ein bestehender Aufruf sein Verhalten ändert oder aufhört zu kompilieren.

## Teil 1 — Lokalisierung

### Ausgangslage

Fünfzehn sichtbare Texte, verteilt über sechs Dateien:

| Text | Datei | Verwendung |
|---|---|---|
| `Antworten` | `message_bubble.dart` | Kontextmenü |
| `Kopieren` | `message_bubble.dart` | Kontextmenü |
| `Original` | `message_bubble.dart` | Übersetzungs-Umschalter |
| `Erneut senden` | `message_bubble.dart` | Wiederholen bei Zustellfehler |
| `Heute` | `date_separator.dart` | Datumstrenner |
| `Gestern` | `date_separator.dart` | Datumstrenner |
| `Nachricht` | `composer.dart` | Platzhalter im Eingabefeld |
| `Senden` | `composer.dart` | Beschriftung/Tooltip |
| `Kamera` | `composer.dart` | Anhang-Auswahl |
| `Galerie` | `composer.dart` | Anhang-Auswahl |
| `Datei` | `composer.dart` | Anhang-Auswahl |
| `tippt…` | `chat_header.dart`, `conversation_list_view.dart` | bereits als Parameter `typingLabel` überschreibbar |
| `Spam` | `mail_list_view.dart` | Kennzeichnung |
| `Betreff` | `mail_composer.dart` | Feldbeschriftung |
| `An` | `mail_composer.dart` | Feldbeschriftung |

Das Paket hat **keine** Lokalisierungs-Abhängigkeit und soll auch keine
bekommen: `Localizations.maybeLocaleOf` steckt in `package:flutter/widgets.dart`.

### `ChatStrings`

Neue Datei `lib/src/chat_strings.dart`, gebaut wie `ChatColors` und
`ChatTypography` — dieselbe Idiomatik wie im übrigen Paket:

```dart
@immutable
class ChatStrings {
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

  const ChatStrings.en();   // …und .de(), .hr(), .tr(), .uk()

  /// Preset for [locale]'s language, falling back to English.
  static ChatStrings forLocale(Locale? locale);

  /// Explicit [override] if given, else the preset for the ambient locale,
  /// else English.
  static ChatStrings of(BuildContext context, {ChatStrings? override});

  ChatStrings copyWith({ /* alle 15 Felder */ });
}
```

Dazu `operator ==` und `hashCode` über alle fünfzehn Felder, wie bei den
übrigen Wertobjekten des Pakets.

### Übersetzungen

| Feld | en | de | hr | tr | uk |
|---|---|---|---|---|---|
| `reply` | Reply | Antworten | Odgovori | Yanıtla | Відповісти |
| `copy` | Copy | Kopieren | Kopiraj | Kopyala | Копіювати |
| `original` | Original | Original | Izvornik | Orijinal | Оригінал |
| `retry` | Send again | Erneut senden | Pošalji ponovno | Yeniden gönder | Надіслати ще раз |
| `today` | Today | Heute | Danas | Bugün | Сьогодні |
| `yesterday` | Yesterday | Gestern | Jučer | Dün | Учора |
| `messageHint` | Message | Nachricht | Poruka | Mesaj | Повідомлення |
| `send` | Send | Senden | Pošalji | Gönder | Надіслати |
| `camera` | Camera | Kamera | Kamera | Kamera | Камера |
| `gallery` | Gallery | Galerie | Galerija | Galeri | Галерея |
| `file` | File | Datei | Datoteka | Dosya | Файл |
| `typing` | typing… | tippt… | piše… | yazıyor… | пише… |
| `spam` | Spam | Spam | Neželjeno | Spam | Спам |
| `subject` | Subject | Betreff | Predmet | Konu | Тема |
| `to` | To | An | Za | Kime | Кому |

Kroatisch, Türkisch und Ukrainisch sollte am Ende ein Muttersprachler
gegenlesen — die Begriffe sind kurz und gängig, aber „Neželjeno" für Spam und
die Auslassungspunkte bei `typing` sind Geschmacksfragen.

### Auflösung

`ChatStrings.of(context, override: …)` in dieser Reihenfolge:

1. `override` — ein ausdrücklich am Widget übergebenes `strings:`
2. `ChatStrings.forLocale(Localizations.maybeLocaleOf(context))` — Abgleich
   allein über `languageCode`, Land und Schrift werden ignoriert (`de_AT` und
   `de_DE` teilen sich dieselben Texte)
3. `ChatStrings.en()` — auch wenn die App gar keine `Localizations` hat

Jedes betroffene Widget bekommt einen optionalen Parameter
`ChatStrings? strings` und löst zu Beginn seiner `build`-Methode einmal auf.

### Zwei bewusste Ausnahmen

- **`typingLabel`** existiert bereits als Parameter mit deutschem Standard in
  `ChatHeader` und `ConversationListView`. Der Parameter bleibt erhalten, sein
  Typ wird von `String` zu `String?`. Wer ihn setzt, gewinnt wie bisher; wer
  ihn wegläßt, bekommt `strings.typing` statt des festen `'tippt…'`. Für
  bestehende Aufrufer ist das quellkompatibel.
- **Die Kanal-Vorlagen** (`ChatChannel.voice({label = 'Anruf'})` und die
  übrigen) bleiben unverändert. Es sind `const`-Konstruktoren, die keinen
  Kontext lesen können, und ein Kanalname ist eher Datum als Oberflächentext.
  Der Weg zur Übersetzung ist der bereits dokumentierte `label:`-Parameter.

## Teil 2 — Leerbares `copyWith`

### Regel

**Jedes nullable Feld bekommt einen `clearX`-Schalter.** Keine Ausnahmen —
sonst muss man an jeder Aufrufstelle überlegen, ob dieses Feld dazugehört.

```dart
ChatMessage copyWith({
  /* … bestehende Parameter unverändert … */
  bool clearErrorText = false,
  bool clearTranslation = false,
  /* … */
}) {
  assert(
    !(clearErrorText && errorText != null),
    'clearErrorText und ein errorText-Wert schließen sich aus.',
  );
  return ChatMessage(
    errorText: clearErrorText ? null : (errorText ?? this.errorText),
    /* … */
  );
}
```

Rein additiv: kein bestehender Aufruf ändert sein Verhalten, keiner hört auf zu
kompilieren. `clearX: true` zusammen mit einem Wert für dasselbe Feld ist ein
Programmierfehler und wird per `assert` gemeldet — im Produktivbau gewinnt
`clear`.

### Betroffene Klassen — 31 Felder in 7 Klassen

| Datei · Klasse | nullable Felder |
|---|---|
| `models.dart` · `ChatMessage` | `sender`, `replyTo`, `editedAt`, `deliveredAt`, `readAt`, `channel`, `errorText`, `translation`, `headline` |
| `models.dart` · `ChatMessageRef` | `senderLabel` |
| `models.dart` · `ChatConversation` | `subtitle`, `channelLabel`, `lastText`, `lastAt`, `avatar`, `avatarUrl`, `presence` |
| `mail_models.dart` · `MailMessage` | `bodyHtml` |
| `chat_participant.dart` · `ChatPresence` | `lastSeen`, `customLabel` |
| `chat_participant.dart` · `ChatParticipant` | `avatar`, `avatarUrl`, `presence`, `color` |
| `chat_attachment.dart` · `ChatAttachment` | `url`, `thumbnail`, `thumbnailUrl`, `fileName`, `sizeBytes`, `width`, `height` |

`ChatColors.incomingInk`/`outgoingInk` bleiben außen vor: `ChatColors` ist
Konfiguration, kein aus Serverdaten wiederaufgebautes Modell, und ein leerer
Ink bedeutet dort bereits „ableiten".

## Test-Strategie

**Lokalisierung** (`test/chat_strings_test.dart`, neu):
- je Sprache: alle fünfzehn Felder sind nicht leer
- `de`, `hr`, `tr`, `uk` unterscheiden sich von `en` in mindestens zehn
  Feldern (einzelne Gleichstände wie `Kamera`/`Camera` sind erlaubt)
- `forLocale`: `de` → deutsch, `de_AT` → deutsch, `uk` → ukrainisch,
  `fr` → englisch, `null` → englisch
- `of`: `override` gewinnt vor dem Kontext; ohne `Localizations` kommt Englisch
- Widget-Test je betroffenem Widget: unter `Localizations` mit `Locale('uk')`
  erscheint der ukrainische Text, mit `strings:`-Override der übergebene
- Regressionstest: unter `Locale('de')` erscheinen exakt die heutigen deutschen
  Texte — die Zusage „für bestehende Hosts ändert sich nichts"

**`copyWith`** (bestehende Modell-Testdateien erweitern):
- je Klasse: `clearX: true` leert das Feld
- je Klasse: ein Aufruf ohne `clearX` behält das Feld (Regression gegen ein
  versehentlich invertiertes `clear`)
- je Klasse: `clearX: true` zusammen mit einem Wert löst den `assert` aus

## Umsetzungsreihenfolge

1. `ChatStrings` mit allen fünf Sprachen, `forLocale`, `of`, `copyWith`,
   Wertgleichheit — für sich testbar, ohne ein Widget anzufassen.
2. Widgets nacheinander anschließen: `message_bubble`, `date_separator`,
   `composer`, `chat_header`, `conversation_list_view`, `mail_list_view`,
   `mail_composer`.
3. `copyWith`-Schalter, Klasse für Klasse.
4. Beispiel-Galerie um eine Sprachwahl erweitern, README und CHANGELOG,
   Version auf 0.15.0.

## Änderungsprotokoll — was hinein muss

**Verhaltensänderung:** Hosts, die **keine** Sprache setzen (keine
`Localizations` oder eine nicht gepflegte Sprache), sehen die Oberfläche
künftig auf **Englisch** statt auf Deutsch. Wer Deutsch behalten will, setzt
entweder die App-Sprache oder übergibt `strings: const ChatStrings.de()`.

Kein Bruch der Schnittstelle: alle neuen Parameter sind optional,
`typingLabel` wird lediglich von `String` zu `String?`.

## Abgrenzung

- Keine Codegenerierung, kein ARB, kein `flutter_localizations` — fünfzehn
  Begriffe rechtfertigen keine Werkzeugkette, und eine Abhängigkeit würde jedem
  Fremdprojekt aufgezwungen.
- Keine Pluralformen, keine Geschlechtsformen, keine Datumsformatierung. Die
  Datumsformate in `date_separator.dart` und `mail_list_view.dart` bleiben wie
  sie sind; sie zu lokalisieren wäre ein eigenes Vorhaben mit `intl`.
- Keine Übersetzung der Kanalnamen (siehe Ausnahme oben).
- Keine weiteren Sprachen. Fünf reichen für die Projekte, die es nutzen.
