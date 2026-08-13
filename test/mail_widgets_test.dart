import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

import 'locale_host.dart';

MailMessage _m(String id, String subject, {bool seen = false, bool spam = false}) =>
    MailMessage(
      id: id,
      direction: MailDirection.incoming,
      from: const MailAddress(email: 'a@x.at'),
      to: const [MailAddress(email: 'b@y.at')],
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

  testWidgets('MailComposer onSend feuert mit dem fertigen Entwurf', (t) async {
    MailDraft? gesendet;
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MailComposer(
      onSend: (d) => gesendet = d,
      draft: const MailDraft(to: [MailAddress(email: 'x@y.at')]),
    ))));
    await t.enterText(find.byKey(const ValueKey('mail-subject')), 'Betr');
    await t.enterText(find.byKey(const ValueKey('mail-body')), 'Inhalt');
    // Der Knopf ist bis zur nächsten Bildfolge gesperrt — leer abzuschicken
    // soll gar nicht erst gehen.
    await t.pump();
    await t.tap(find.byKey(const ValueKey('mail-send')));
    await t.pump();
    expect(gesendet?.to.single.email, 'x@y.at');
    expect(gesendet?.subject, 'Betr');
    expect(gesendet?.body, 'Inhalt');
  });

  testWidgets('Mail-Felder folgen der App-Sprache', (tester) async {
    await tester.pumpWidget(localeHost(
      MailComposer(onSend: (_) {}),
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
            from: const MailAddress(email: 'ada@example.invalid'),
            to: const [MailAddress(email: 'ich@example.invalid')],
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
          from: const MailAddress(email: 'ada@example.invalid'),
          to: const [MailAddress(email: 'ich@example.invalid')],
          subject: 'Angebot',
          bodyText: 'Text',
          date: DateTime(2026, 7, 31, 10),
          spam: true,
        ),
        onReply: () {},
      ),
      locale: const Locale('uk'),
    ));
    // Die Aktionen sind Symbole; das Wort steht im Tooltip.
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('mail-reply')))
          .tooltip,
      'Відповісти',
    );
    expect(find.text('Можливий спам'), findsOneWidget);
  });

  testWidgets('Anhang-Chip zeigt während des Öffnens einen Ladepunkt',
      (t) async {
    final fertig = Completer<void>();
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MailDetailView(
          message: MailMessage(
            id: 'm1',
            direction: MailDirection.incoming,
            from: const MailAddress(email: 'a@b.at'),
            to: const [MailAddress(email: 'studio@v.at')],
            subject: 'Rechnung',
            bodyText: 'Anbei',
            date: DateTime(2026, 8, 14),
            attachments: const [
              MailAttachment(
                name: 'rechnung.pdf',
                sizeBytes: 1024,
                url: 'https://example.at/r.pdf',
                contentType: 'application/pdf',
                safety: AttachmentSafety.safe,
              ),
            ],
          ),
          onOpenAttachment: (_) => fertig.future,
        ),
      ),
    ));

    // Vorher: Büroklammer, kein Ladepunkt.
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await t.tap(find.byType(ActionChip));
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    fertig.complete();
    await t.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('während des Öffnens ist der Chip nicht erneut tippbar',
      (t) async {
    final fertig = Completer<void>();
    var aufrufe = 0;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MailDetailView(
          message: MailMessage(
            id: 'm2',
            direction: MailDirection.incoming,
            from: const MailAddress(email: 'a@b.at'),
            to: const [MailAddress(email: 'studio@v.at')],
            subject: 'Rechnung',
            bodyText: 'Anbei',
            date: DateTime(2026, 8, 14),
            attachments: const [
              MailAttachment(
                name: 'rechnung.pdf',
                sizeBytes: 1024,
                url: 'https://example.at/r.pdf',
                contentType: 'application/pdf',
                safety: AttachmentSafety.safe,
              ),
            ],
          ),
          onOpenAttachment: (_) {
            aufrufe++;
            return fertig.future;
          },
        ),
      ),
    ));

    await t.tap(find.byType(ActionChip));
    await t.pump();
    await t.tap(find.byType(ActionChip), warnIfMissed: false);
    await t.pump();
    expect(aufrufe, 1);

    fertig.complete();
    await t.pumpAndSettle();
  });
}
