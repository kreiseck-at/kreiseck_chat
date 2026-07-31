// Der Composer: Kopie-Felder, Anhänge, Zustände.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

Widget host(Widget kind) => MaterialApp(home: Scaffold(body: kind));

const _anhang = MailAttachment(name: 'foto.png', sizeBytes: 10);

void main() {
  testWidgets('Kopie-Felder bleiben weg, bis man sie braucht', (t) async {
    await t.pumpWidget(host(MailComposer(
      onSend: (_) {},
      strings: const ChatStrings.de(),
    )));
    expect(find.byKey(const ValueKey('mail-cc')), findsNothing);

    await t.tap(find.byKey(const ValueKey('mail-cc-toggle')));
    await t.pump();
    expect(find.byKey(const ValueKey('mail-cc')), findsOneWidget);
    expect(find.byKey(const ValueKey('mail-bcc')), findsOneWidget);
  });

  testWidgets('ein Entwurf mit CC öffnet die Felder von sich aus', (t) async {
    await t.pumpWidget(host(MailComposer(
      onSend: (_) {},
      draft: const MailDraft(cc: [MailAddress(email: 'a@b.at')]),
    )));
    expect(find.byKey(const ValueKey('mail-cc')), findsOneWidget);
    expect(find.byKey(const ValueKey('mail-cc-toggle')), findsNothing);
  });

  testWidgets('mehrere Empfänger, komma- oder strichpunktgetrennt', (t) async {
    MailDraft? gesendet;
    await t.pumpWidget(host(MailComposer(onSend: (d) => gesendet = d)));
    await t.enterText(
        find.byKey(const ValueKey('mail-to')), 'a@b.at, c@d.at; e@f.at');
    await t.enterText(find.byKey(const ValueKey('mail-body')), 'Text');
    await t.pump();
    await t.tap(find.byKey(const ValueKey('mail-send')));
    await t.pump();
    expect(gesendet?.to.map((a) => a.email),
        ['a@b.at', 'c@d.at', 'e@f.at']);
  });

  testWidgets('ohne Empfänger lässt sich nicht senden', (t) async {
    await t.pumpWidget(host(MailComposer(onSend: (_) {})));
    await t.enterText(find.byKey(const ValueKey('mail-body')), 'Text');
    await t.pump();
    final knopf =
        t.widget<ElevatedButton>(find.byKey(const ValueKey('mail-send')));
    expect(knopf.onPressed, isNull);
  });

  testWidgets('ein Anhang allein genügt zum Senden', (t) async {
    MailDraft? gesendet;
    await t.pumpWidget(host(MailComposer(
      onSend: (d) => gesendet = d,
      draft: const MailDraft(
        to: [MailAddress(email: 'a@b.at')],
        attachments: [_anhang],
      ),
    )));
    await t.tap(find.byKey(const ValueKey('mail-send')));
    await t.pump();
    expect(gesendet?.attachments.single.name, 'foto.png');
  });

  testWidgets('Anhänge lassen sich entfernen', (t) async {
    int? entfernt;
    await t.pumpWidget(host(MailComposer(
      onSend: (_) {},
      draft: const MailDraft(attachments: [_anhang]),
      onRemoveAttachmentAt: (i) => entfernt = i,
    )));
    expect(find.text('foto.png'), findsOneWidget);
    await t.tap(find.byIcon(Icons.cancel));
    await t.pump();
    expect(entfernt, 0);
  });

  testWidgets('Anhang-Knopf erscheint nur, wenn der Host ihn bedienen kann',
      (t) async {
    await t.pumpWidget(host(MailComposer(onSend: (_) {})));
    expect(find.byKey(const ValueKey('mail-attach')), findsNothing);

    await t.pumpWidget(host(MailComposer(
      onSend: (_) {},
      onPickAttachment: () {},
    )));
    expect(find.byKey(const ValueKey('mail-attach')), findsOneWidget);
  });

  testWidgets('während des Sendens ist der Knopf gesperrt', (t) async {
    await t.pumpWidget(host(MailComposer(
      onSend: (_) {},
      draft: const MailDraft(
          to: [MailAddress(email: 'a@b.at')], body: 'Text'),
      sending: true,
    )));
    final knopf =
        t.widget<ElevatedButton>(find.byKey(const ValueKey('mail-send')));
    expect(knopf.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Fehlgeschlagenes Senden zeigt den Grund, der Text bleibt',
      (t) async {
    await t.pumpWidget(host(MailComposer(
      onSend: (_) {},
      draft: const MailDraft(
          to: [MailAddress(email: 'a@b.at')], body: 'Mein Text'),
      errorText: 'Postfach nicht erreichbar',
    )));
    expect(find.text('Postfach nicht erreichbar'), findsOneWidget);
    expect(
      t.widget<TextField>(find.byKey(const ValueKey('mail-body')))
          .controller
          ?.text,
      'Mein Text',
    );
  });

  testWidgets('eine Antwort startet mit Empfänger, Betreff und Zitat',
      (t) async {
    final quelle = MailMessage(
      id: 'm1',
      direction: MailDirection.incoming,
      from: const MailAddress(email: 'anna@example.at', name: 'Anna'),
      to: const [MailAddress(email: 'studio@example.at')],
      subject: 'Termin',
      bodyText: 'Passt Freitag?',
      date: DateTime(2026, 8, 1),
    );
    await t.pumpWidget(host(MailComposer(
      onSend: (_) {},
      draft: MailDraft.reply(quelle),
    )));
    expect(
      t.widget<TextField>(find.byKey(const ValueKey('mail-to'))).controller?.text,
      'anna@example.at',
    );
    expect(
      t.widget<TextField>(find.byKey(const ValueKey('mail-subject')))
          .controller
          ?.text,
      'Re: Termin',
    );
    expect(
      t.widget<TextField>(find.byKey(const ValueKey('mail-body')))
          .controller
          ?.text,
      contains('> Passt Freitag?'),
    );
  });
}
