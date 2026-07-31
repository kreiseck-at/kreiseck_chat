// Die Sicherheitsregeln der Mail-Ansicht: was gerendert, geladen, geöffnet und
// verlinkt werden darf.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

MailMessage mail({
  String? bodyHtml,
  List<MailAttachment> attachments = const [],
  bool? senderVerified,
  MailAddress? from,
}) =>
    MailMessage(
      id: 'm1',
      direction: MailDirection.incoming,
      from: from ?? const MailAddress(email: 'anna@example.at', name: 'Anna'),
      to: const [MailAddress(email: 'studio@example.at')],
      subject: 'Termin',
      bodyText: 'Passt Freitag?',
      bodyHtml: bodyHtml,
      date: DateTime(2026, 8, 1, 10),
      attachments: attachments,
      senderVerified: senderVerified,
    );

Widget host(Widget kind) => MaterialApp(home: Scaffold(body: kind));

void main() {
  testWidgets('ohne bodyBuilder wird nur der Text gezeichnet', (tester) async {
    await tester.pumpWidget(host(MailDetailView(message: mail())));
    expect(find.text('Passt Freitag?'), findsOneWidget);
  });

  testWidgets('bodyBuilder bekommt die Freigabe für Fernbilder durchgereicht',
      (tester) async {
    bool? gereicht;
    Future<void> zeige(bool erlaubt) => tester.pumpWidget(host(MailDetailView(
          message: mail(bodyHtml: '<p>Hallo</p>'),
          remoteContentAllowed: erlaubt,
          bodyBuilder: (_, r) {
            gereicht = r.remoteContentAllowed;
            return const Text('gebaut');
          },
        )));

    await zeige(false);
    expect(gereicht, isFalse);
    expect(find.text('gebaut'), findsOneWidget);

    await zeige(true);
    expect(gereicht, isTrue);
  });

  testWidgets('HTML-Mail zeigt die Leiste, bis Bilder freigegeben sind',
      (tester) async {
    var freigegeben = false;
    await tester.pumpWidget(host(MailDetailView(
      message: mail(bodyHtml: '<p>Hallo</p>'),
      strings: const ChatStrings.de(),
      onAllowRemoteContent: () => freigegeben = true,
    )));
    expect(find.text('Bilder wurden nicht geladen.'), findsOneWidget);
    await tester.tap(find.text('Bilder laden'));
    expect(freigegeben, isTrue);

    // Freigegeben verschwindet die Leiste.
    await tester.pumpWidget(host(MailDetailView(
      message: mail(bodyHtml: '<p>Hallo</p>'),
      strings: const ChatStrings.de(),
      remoteContentAllowed: true,
      onAllowRemoteContent: () {},
    )));
    expect(find.text('Bilder wurden nicht geladen.'), findsNothing);
  });

  testWidgets('reine Textmail zeigt keine Bilder-Leiste', (tester) async {
    await tester.pumpWidget(host(MailDetailView(
      message: mail(),
      strings: const ChatStrings.de(),
      onAllowRemoteContent: () {},
    )));
    expect(find.text('Bilder wurden nicht geladen.'), findsNothing);
  });

  group('Link-Schranke', () {
    test('nur https und mailto sind folgbar', () {
      expect(isFollowableMailLink(Uri.parse('https://example.at')), isTrue);
      expect(isFollowableMailLink(Uri.parse('mailto:a@b.at')), isTrue);
      expect(isFollowableMailLink(Uri.parse('http://example.at')), isFalse);
      expect(isFollowableMailLink(Uri.parse('javascript:alert(1)')), isFalse);
      expect(isFollowableMailLink(Uri.parse('data:text/html,<b>x')), isFalse);
      expect(isFollowableMailLink(Uri.parse('file:///etc/passwd')), isFalse);
    });

    testWidgets('openLink nimmt Gefährliches gar nicht erst an',
        (tester) async {
      final geoeffnet = <Uri>[];
      late MailBodyRequest anfrage;
      await tester.pumpWidget(host(MailDetailView(
        message: mail(),
        onOpenLink: geoeffnet.add,
        bodyBuilder: (_, r) {
          anfrage = r;
          return const Text('gebaut');
        },
      )));

      expect(anfrage.openLink(Uri.parse('javascript:alert(1)')), isFalse);
      expect(geoeffnet, isEmpty);
      expect(anfrage.openLink(Uri.parse('https://example.at')), isTrue);
      expect(geoeffnet.single.host, 'example.at');
    });
  });

  group('Anhänge', () {
    const gesperrt = MailAttachment(
      name: 'rechnung.pdf.exe',
      sizeBytes: 10,
      url: 'https://x/a',
      safety: AttachmentSafety.blocked,
      blockedReason: 'Doppelendung',
    );
    const geprueft = MailAttachment(
      name: 'foto.png',
      sizeBytes: 10,
      url: 'https://x/b',
      contentType: 'image/png',
      safety: AttachmentSafety.safe,
    );
    const ungeprueft = MailAttachment(
      name: 'angebot.docx',
      sizeBytes: 10,
      url: 'https://x/c',
    );

    testWidgets('gesperrter Anhang lässt sich nicht öffnen', (tester) async {
      final geoeffnet = <MailAttachment>[];
      await tester.pumpWidget(host(MailDetailView(
        message: mail(attachments: const [gesperrt]),
        strings: const ChatStrings.de(),
        onOpenAttachment: geoeffnet.add,
      )));
      expect(find.textContaining('Gesperrt'), findsOneWidget);
      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();
      expect(geoeffnet, isEmpty);
    });

    testWidgets('ungeprüfter Anhang ist als solcher markiert, aber öffenbar',
        (tester) async {
      final geoeffnet = <MailAttachment>[];
      await tester.pumpWidget(host(MailDetailView(
        message: mail(attachments: const [ungeprueft]),
        strings: const ChatStrings.de(),
        onOpenAttachment: geoeffnet.add,
      )));
      expect(find.textContaining('Ungeprüft'), findsOneWidget);
      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();
      expect(geoeffnet.single.name, 'angebot.docx');
    });

    testWidgets('geprüfter Anhang trägt keine Marke', (tester) async {
      await tester.pumpWidget(host(MailDetailView(
        message: mail(attachments: const [geprueft]),
        strings: const ChatStrings.de(),
        onOpenAttachment: (_) {},
      )));
      expect(find.text('foto.png'), findsOneWidget);
    });
  });

  group('Absender', () {
    testWidgets('fehlgeschlagene Herkunftsprüfung warnt', (tester) async {
      await tester.pumpWidget(host(MailDetailView(
        message: mail(senderVerified: false),
        strings: const ChatStrings.de(),
      )));
      expect(find.text('Absender konnte nicht bestätigt werden.'),
          findsOneWidget);
    });

    testWidgets('nicht geprüft behauptet nichts', (tester) async {
      await tester.pumpWidget(host(MailDetailView(
        message: mail(),
        strings: const ChatStrings.de(),
      )));
      expect(find.text('Absender konnte nicht bestätigt werden.'), findsNothing);
    });

    testWidgets('vorgetäuschter Anzeigename warnt ebenfalls', (tester) async {
      await tester.pumpWidget(host(MailDetailView(
        message: mail(
          from: const MailAddress(
              email: 'boese@evil.tld', name: 'service@bank.at'),
        ),
        strings: const ChatStrings.de(),
      )));
      expect(find.text('Absender konnte nicht bestätigt werden.'),
          findsOneWidget);
      // Die echte Adresse steht da, nicht nur der Name.
      expect(find.textContaining('boese@evil.tld'), findsOneWidget);
    });
  });
}
