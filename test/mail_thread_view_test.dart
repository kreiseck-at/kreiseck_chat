// Der Mail-Verlauf: neueste offen, ältere eingeklappt.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

import 'locale_host.dart';

MailMessage m(String id, String body, {int tag = 1}) => MailMessage(
      id: id,
      direction: MailDirection.incoming,
      from: MailAddress(email: '$id@example.at'),
      to: const [MailAddress(email: 'studio@example.at')],
      subject: 'Termin',
      bodyText: body,
      date: DateTime(2026, 8, tag, 10),
    );

Widget host(Widget kind) => MaterialApp(home: Scaffold(body: kind));

void main() {
  testWidgets('die neueste Mail steht oben und offen', (t) async {
    await t.pumpWidget(host(MailThreadView(
      messages: [m('a', 'Erste Nachricht', tag: 1), m('b', 'Zweite', tag: 2)],
    )));
    // Neueste zuerst: die offene Mail steht über der eingeklappten älteren.
    expect(
      t.getTopLeft(find.byType(MailDetailView)).dy,
      lessThan(t.getTopLeft(find.byType(ListTile)).dy),
    );
    // Die jüngste in voller Ansicht …
    expect(find.byType(MailDetailView), findsOneWidget);
    // … die ältere nur als Zeile (Vorschau, kein Detail).
    expect(find.text('Erste Nachricht'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('eine ältere Mail lässt sich aufklappen', (t) async {
    await t.pumpWidget(host(MailThreadView(
      messages: [m('a', 'Erste Nachricht', tag: 1), m('b', 'Zweite', tag: 2)],
    )));
    await t.tap(find.byType(ListTile));
    await t.pumpAndSettle();
    expect(find.byType(MailDetailView), findsNWidgets(2));
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('mit newestFirst: false steht die neueste unten', (t) async {
    await t.pumpWidget(host(MailThreadView(
      messages: [m('a', 'Erste Nachricht', tag: 1), m('b', 'Zweite', tag: 2)],
      newestFirst: false,
    )));
    expect(
      t.getTopLeft(find.byType(MailDetailView)).dy,
      greaterThan(t.getTopLeft(find.byType(ListTile)).dy),
    );
  });

  testWidgets('eine einzelne Mail ist immer offen', (t) async {
    await t.pumpWidget(host(MailThreadView(messages: [m('a', 'Allein')])));
    expect(find.byType(MailDetailView), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('Antwort-Aktionen melden die betroffene Mail', (t) async {
    MailMessage? beantwortet;
    MailMessage? weitergeleitet;
    await t.pumpWidget(host(MailThreadView(
      messages: [m('a', 'Text')],
      strings: const ChatStrings.de(),
      onReply: (x) => beantwortet = x,
      onForward: (x) => weitergeleitet = x,
    )));
    await t.tap(find.byKey(const ValueKey('mail-reply')));
    expect(beantwortet?.id, 'a');
    await t.tap(find.byKey(const ValueKey('mail-forward')));
    expect(weitergeleitet?.id, 'a');
  });

  testWidgets('die Sicherheitsregeln gelten auch im Verlauf', (t) async {
    await t.pumpWidget(host(MailThreadView(
      messages: [
        MailMessage(
          id: 'a',
          direction: MailDirection.incoming,
          from: const MailAddress(email: 'anna@example.at'),
          to: const [MailAddress(email: 'studio@example.at')],
          subject: 'Termin',
          bodyText: 'Text',
          bodyHtml: '<p>Text</p>',
          date: DateTime(2026, 8, 1),
        ),
      ],
      strings: const ChatStrings.de(),
      onAllowRemoteContent: () {},
    )));
    expect(find.text('Bilder wurden nicht geladen.'), findsOneWidget);
  });

  test('MailTheme.fromChat übernimmt die Farben des Chats', () {
    const chat = ChatTheme.light();
    final mail = MailTheme.fromChat(chat);
    expect(mail.background, chat.colors.background);
    expect(mail.accentColor, chat.colors.accent);
    expect(mail.textColor, chat.colors.incomingText);
  });

  testWidgets('ohne Mails steht ein Hinweis statt einer leeren Fläche',
      (t) async {
    await t.pumpWidget(host(const MailThreadView(messages: [])));
    // Eine weiße Fläche sagt der Leserin nicht, ob nichts da ist oder ob
    // etwas hängt.
    expect(find.text('No mail yet'), findsOneWidget);
    expect(find.byType(MailDetailView), findsNothing);
  });

  testWidgets('der Hinweis folgt der Sprache', (t) async {
    await t.pumpWidget(localeHost(
      const MailThreadView(messages: []),
      locale: const Locale('de'),
    ));
    expect(find.text('Noch keine Mails'), findsOneWidget);
  });
}
