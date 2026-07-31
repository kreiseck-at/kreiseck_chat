import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

import 'locale_host.dart';

MailMessage _m(String id, String subject, {bool seen = false, bool spam = false}) =>
    MailMessage(
      id: id,
      direction: MailDirection.incoming,
      from: 'a@x.at',
      to: 'b@y.at',
      subject: subject,
      bodyText: 'Body $id',
      date: DateTime.utc(2026),
      seen: seen,
      attachments: const [],
      spam: spam,
    );

void main() {
  testWidgets('MailListView zeigt Betreffe und meldet onOpen', (t) async {
    MailMessage? opened;
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MailListView(
      messages: [_m('1', 'Erste'), _m('2', 'Zweite')],
      onOpen: (m) => opened = m,
    ))));
    expect(find.text('Erste'), findsOneWidget);
    await t.tap(find.text('Zweite'));
    await t.pump();
    expect(opened?.id, '2');
  });

  testWidgets('MailListView zeigt Spam-Label nur bei markierten Nachrichten', (t) async {
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MailListView(
      messages: [_m('1', 'Erste', spam: true), _m('2', 'Zweite')],
      onOpen: (_) {},
    ))));
    expect(find.text('Spam'), findsOneWidget);
  });

  testWidgets('MailListView zeigt kein Spam-Label ohne markierte Nachrichten', (t) async {
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MailListView(
      messages: [_m('1', 'Erste'), _m('2', 'Zweite')],
      onOpen: (_) {},
    ))));
    expect(find.text('Spam'), findsNothing);
  });

  testWidgets('MailComposer onSend feuert mit Eingaben', (t) async {
    String? to, subj, body;
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MailComposer(
      onSend: (a, s, b) {
        to = a;
        subj = s;
        body = b;
      },
      initialTo: 'x@y.at',
    ))));
    await t.enterText(find.byKey(const ValueKey('mail-subject')), 'Betr');
    await t.enterText(find.byKey(const ValueKey('mail-body')), 'Inhalt');
    await t.tap(find.byKey(const ValueKey('mail-send')));
    await t.pump();
    expect(to, 'x@y.at');
    expect(subj, 'Betr');
    expect(body, 'Inhalt');
  });

  testWidgets('Mail-Felder folgen der App-Sprache', (tester) async {
    await tester.pumpWidget(localeHost(
      MailComposer(onSend: (String to, String subject, String body) {}),
      locale: const Locale('uk'),
    ));
    expect(find.text('Кому'), findsOneWidget);
    expect(find.text('Тема'), findsOneWidget);
    expect(find.text('Надіслати'), findsOneWidget);
  });

  testWidgets('Spam-Kennzeichnung folgt der App-Sprache', (tester) async {
    await tester.pumpWidget(localeHost(
      MailListView(
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
      locale: const Locale('uk'),
    ));
    expect(find.text('Спам'), findsOneWidget);
  });

  testWidgets('MailDetailView folgt der App-Sprache', (tester) async {
    await tester.pumpWidget(localeHost(
      MailDetailView(
        message: MailMessage(
          id: 'm1',
          direction: MailDirection.incoming,
          from: 'ada@example.invalid',
          to: 'ich@example.invalid',
          subject: 'Angebot',
          bodyText: 'Text',
          date: DateTime(2026, 7, 31, 10),
          spam: true,
        ),
        onReply: () {},
      ),
      locale: const Locale('uk'),
    ));
    expect(find.text('Відповісти'), findsOneWidget);
    expect(find.text('Можливий спам'), findsOneWidget);
  });
}
