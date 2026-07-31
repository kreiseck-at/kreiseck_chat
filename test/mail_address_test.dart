// TEST-FIRST: geschrieben VOR MailAddress/MailDraft.
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

MailMessage mail({
  String id = 'm1',
  MailAddress? from,
  List<MailAddress> to = const [],
  List<MailAddress> cc = const [],
  String subject = 'Termin am Freitag',
  String bodyText = 'Passt Freitag um 10?',
  String? messageId,
}) =>
    MailMessage(
      id: id,
      direction: MailDirection.incoming,
      from: from ?? const MailAddress(email: 'anna@example.at', name: 'Anna'),
      to: to.isEmpty
          ? const [MailAddress(email: 'studio@example.at')]
          : to,
      cc: cc,
      subject: subject,
      bodyText: bodyText,
      date: DateTime(2026, 8, 1, 10),
      messageId: messageId,
    );

void main() {
  group('MailAddress', () {
    test('Anzeige mit und ohne Namen', () {
      expect(const MailAddress(email: 'a@b.at', name: 'Anna Muster').display,
          'Anna Muster <a@b.at>');
      expect(const MailAddress(email: 'a@b.at').display, 'a@b.at');
      // Leerer Name zählt wie kein Name.
      expect(const MailAddress(email: 'a@b.at', name: '  ').display, 'a@b.at');
    });

    test('erkennt einen Anzeigenamen, der eine Adresse vortäuscht', () {
      // Der häufigste Trick: der Name behauptet den echten Absender zu sein.
      expect(
        const MailAddress(email: 'boese@evil.tld', name: 'service@bank.at')
            .displayNameLooksLikeAddress,
        isTrue,
      );
      expect(
        const MailAddress(email: 'a@b.at', name: 'Anna Muster')
            .displayNameLooksLikeAddress,
        isFalse,
      );
      // Steht dieselbe Adresse im Namen, ist nichts vorgetäuscht.
      expect(
        const MailAddress(email: 'a@b.at', name: 'a@b.at')
            .displayNameLooksLikeAddress,
        isFalse,
      );
    });

    test('Wertgleichheit', () {
      expect(const MailAddress(email: 'a@b.at', name: 'A'),
          const MailAddress(email: 'a@b.at', name: 'A'));
      expect(const MailAddress(email: 'a@b.at'),
          isNot(const MailAddress(email: 'c@d.at')));
    });

    test('aus einer Kopfzeile lesen', () {
      expect(MailAddress.parse('Anna Muster <anna@example.at>'),
          const MailAddress(email: 'anna@example.at', name: 'Anna Muster'));
      expect(MailAddress.parse('anna@example.at'),
          const MailAddress(email: 'anna@example.at'));
      expect(MailAddress.parse('"Muster, Anna" <anna@example.at>')?.name,
          'Muster, Anna');
      expect(MailAddress.parse('   '), isNull);
    });
  });

  group('MailAttachment: Einstufung', () {
    test('ohne Angabe gilt unbekannt — nie sicher', () {
      const a = MailAttachment(name: 'x.pdf', sizeBytes: 10);
      expect(a.safety, AttachmentSafety.unknown);
      expect(a.canPreview, isFalse);
    });

    test('Vorschau nur bei sicher und Bild', () {
      const bild = MailAttachment(
        name: 'foto.png',
        sizeBytes: 10,
        url: 'https://x/foto.png',
        contentType: 'image/png',
        safety: AttachmentSafety.safe,
      );
      expect(bild.canPreview, isTrue);

      const pdf = MailAttachment(
        name: 'x.pdf',
        sizeBytes: 10,
        url: 'https://x/x.pdf',
        contentType: 'application/pdf',
        safety: AttachmentSafety.safe,
      );
      expect(pdf.canPreview, isFalse);
    });

    test('gesperrt lässt sich nicht öffnen, auch mit URL nicht', () {
      const a = MailAttachment(
        name: 'foto.png',
        sizeBytes: 10,
        url: 'https://x/foto.png',
        contentType: 'image/png',
        safety: AttachmentSafety.blocked,
        blockedReason: 'Inhalt ist text/html, nicht .png',
      );
      expect(a.canOpen, isFalse);
      expect(a.canPreview, isFalse);
    });

    test('ohne URL gibt es nichts zu öffnen', () {
      const a = MailAttachment(
          name: 'x.pdf', sizeBytes: 10, safety: AttachmentSafety.safe);
      expect(a.canOpen, isFalse);
    });
  });

  group('MailDraft', () {
    test('Antwort geht an den Absender, Betreff bekommt Re:', () {
      final d = MailDraft.reply(mail());
      expect(d.mode, MailComposeMode.reply);
      expect(d.to.single.email, 'anna@example.at');
      expect(d.cc, isEmpty);
      expect(d.subject, 'Re: Termin am Freitag');
    });

    test('Re: wird nicht gestapelt', () {
      final d = MailDraft.reply(mail(subject: 'Re: Termin am Freitag'));
      expect(d.subject, 'Re: Termin am Freitag');
      final gross = MailDraft.reply(mail(subject: 'RE: Termin'));
      expect(gross.subject, 'RE: Termin');
    });

    test('Allen antworten nimmt CC mit, aber nicht die eigene Adresse', () {
      final d = MailDraft.replyAll(
        mail(
          to: const [
            MailAddress(email: 'studio@example.at'),
            MailAddress(email: 'kollegin@example.at'),
          ],
          cc: const [MailAddress(email: 'chefin@example.at')],
        ),
        self: const MailAddress(email: 'studio@example.at'),
      );
      expect(d.mode, MailComposeMode.replyAll);
      expect(d.to.map((a) => a.email), ['anna@example.at']);
      expect(
        d.cc.map((a) => a.email),
        containsAll(['kollegin@example.at', 'chefin@example.at']),
      );
      expect(d.cc.map((a) => a.email), isNot(contains('studio@example.at')));
    });

    test('Weiterleiten hat keine Empfänger und ein Fwd: davor', () {
      final d = MailDraft.forward(mail());
      expect(d.mode, MailComposeMode.forward);
      expect(d.to, isEmpty);
      expect(d.subject, 'Fwd: Termin am Freitag');
      // Das Original steht zitiert im Rumpf.
      expect(d.body, contains('Passt Freitag um 10?'));
      expect(d.body, contains('anna@example.at'));
    });

    test('Antwort zitiert das Original mit >', () {
      final d = MailDraft.reply(mail(bodyText: 'Zeile eins\nZeile zwei'));
      expect(d.body, contains('> Zeile eins'));
      expect(d.body, contains('> Zeile zwei'));
    });

    test('Antwort hängt sich an die Kennung der Vorlage', () {
      final d = MailDraft.reply(mail(messageId: '<abc@mail>'));
      expect(d.inReplyTo, '<abc@mail>');
      // Ohne Kennung bleibt es leer — der Betreff hält den Faden.
      expect(MailDraft.reply(mail()).inReplyTo, isNull);
    });

    test('leer ist leer', () {
      const d = MailDraft();
      expect(d.mode, MailComposeMode.compose);
      expect(d.isEmpty, isTrue);
      expect(d.copyWith(body: 'Hallo').isEmpty, isFalse);
    });

    test('copyWith ersetzt Felder und kann Empfänger leeren', () {
      final d = MailDraft.reply(mail()).copyWith(
        cc: const [MailAddress(email: 'x@y.at')],
        subject: 'Neu',
      );
      expect(d.cc.single.email, 'x@y.at');
      expect(d.subject, 'Neu');
      expect(d.to.single.email, 'anna@example.at');
      expect(d.copyWith(to: const []).to, isEmpty);
    });
  });
}
