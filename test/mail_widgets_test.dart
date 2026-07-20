import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

MailMessage _m(String id, String subject, {bool seen = false}) => MailMessage(
      id: id,
      direction: MailDirection.incoming,
      from: 'a@x.at',
      to: 'b@y.at',
      subject: subject,
      bodyText: 'Body $id',
      date: DateTime.utc(2026),
      seen: seen,
      attachments: const [],
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
}
