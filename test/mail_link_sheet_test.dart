import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

Future<BuildContext> host(WidgetTester t) async {
  late BuildContext ctx;
  await t.pumpWidget(MaterialApp(
    home: Builder(builder: (c) {
      ctx = c;
      return const Scaffold(body: SizedBox());
    }),
  ));
  return ctx;
}

void main() {
  testWidgets('zeigt Domain groß und den ganzen Link klein', (t) async {
    final ctx = await host(t);
    showMailLinkSheet(ctx,
        uri: Uri.parse('https://mail.bank.at/login?x=1&y=2'),
        strings: const ChatStrings.de());
    await t.pumpAndSettle();

    expect(find.text('bank.at'), findsOneWidget);
    expect(find.text('https://mail.bank.at/login?x=1&y=2'), findsOneWidget);
    expect(find.text('Der Text nennt eine andere Adresse als der Link. Vorsicht.'),
        findsNothing);
  });

  testWidgets('verkleideter Link warnt und macht das Öffnen unauffällig',
      (t) async {
    final ctx = await host(t);
    showMailLinkSheet(ctx,
        uri: Uri.parse('https://bank.at.evil.tld/login'),
        linkText: 'bank.at',
        strings: const ChatStrings.de());
    await t.pumpAndSettle();

    expect(find.text('evil.tld'), findsOneWidget);
    expect(find.text('Der Text nennt eine andere Adresse als der Link. Vorsicht.'),
        findsOneWidget);
    // Kein hervorgehobener Öffnen-Knopf, sondern der zurückhaltende.
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.text('Trotzdem öffnen'), findsOneWidget);
  });

  testWidgets('Abbrechen liefert false, Öffnen true', (t) async {
    final ctx = await host(t);
    var ergebnis = showMailLinkSheet(ctx,
        uri: Uri.parse('https://bank.at/'), strings: const ChatStrings.de());
    await t.pumpAndSettle();
    await t.tap(find.text('Abbrechen'));
    await t.pumpAndSettle();
    expect(await ergebnis, isFalse);

    ergebnis = showMailLinkSheet(ctx,
        uri: Uri.parse('https://bank.at/'), strings: const ChatStrings.de());
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('mail-link-open')));
    await t.pumpAndSettle();
    expect(await ergebnis, isTrue);
  });

  testWidgets('Knopf heißt nicht wie die Überschrift', (t) async {
    final ctx = await host(t);
    showMailLinkSheet(ctx,
        uri: Uri.parse('https://bank.at/'), strings: const ChatStrings.de());
    await t.pumpAndSettle();
    expect(find.text('Link öffnen?'), findsOneWidget); // nur die Überschrift
    expect(find.text('Öffnen'), findsOneWidget); // der Knopf
  });

  testWidgets('Telefonnummer bietet Anrufen, Adresse bietet Schreiben',
      (t) async {
    final ctx = await host(t);
    showMailLinkSheet(ctx,
        uri: Uri.parse('tel:+436601234567'), strings: const ChatStrings.de());
    await t.pumpAndSettle();
    expect(find.text('Anrufen'), findsWidgets);
    expect(find.text('+436601234567'), findsOneWidget);
    await t.tap(find.text('Abbrechen'));
    await t.pumpAndSettle();

    showMailLinkSheet(ctx,
        uri: Uri.parse('mailto:anna@example.at'),
        strings: const ChatStrings.de());
    await t.pumpAndSettle();
    expect(find.text('E-Mail schreiben'), findsWidgets);
    expect(find.text('anna@example.at'), findsOneWidget);
  });

  test('Telefon- und Mail-Links sind folgbar, Gefährliches nicht', () {
    expect(isFollowableMailLink(Uri.parse('tel:+43660')), isTrue);
    expect(isFollowableMailLink(Uri.parse('mailto:a@b.at')), isTrue);
    expect(isFollowableMailLink(Uri.parse('javascript:alert(1)')), isFalse);
    expect(mailLinkAction(Uri.parse('tel:+43660')), MailLinkAction.call);
    expect(mailLinkAction(Uri.parse('mailto:a@b.at')), MailLinkAction.writeMail);
    expect(mailLinkAction(Uri.parse('https://x.at')), MailLinkAction.open);
  });
}
