import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  test('MailMessage.fromJson liest Felder + Anhänge', () {
    final m = MailMessage.fromJson({
      'id': 'm1', 'direction': 'incoming', 'from': 'a@x.at', 'to': 'b@y.at',
      'subject': 'Hallo', 'bodyText': 'Text', 'date': '2026-07-20T10:00:00Z',
      'seen': false, 'attachments': [{'name': 'f.pdf', 'sizeBytes': 12, 'url': 'u'}],
    });
    expect(m.direction, MailDirection.incoming);
    expect(m.subject, 'Hallo');
    expect(m.attachments.single.name, 'f.pdf');
    expect(m.seen, false);
  });
  test('MailMessage.copyWith überschreibt seen', () {
    final m = MailMessage(id: 'm1', direction: MailDirection.outgoing, from: 'a', to: 'b',
      subject: 's', bodyText: 't', date: DateTime.utc(2026), seen: false, attachments: const []);
    expect(m.copyWith(seen: true).seen, true);
  });
  test('MailMessage.fromJson liest spam (true/false/fehlend)', () {
    Map<String, dynamic> base() => {
      'id': 'm1', 'direction': 'incoming', 'from': 'a@x.at', 'to': 'b@y.at',
      'subject': 'Hallo', 'bodyText': 'Text', 'date': '2026-07-20T10:00:00Z',
    };
    expect(MailMessage.fromJson({...base(), 'spam': true}).spam, true);
    expect(MailMessage.fromJson({...base(), 'spam': false}).spam, false);
    expect(MailMessage.fromJson(base()).spam, false);
  });
  test('MailMessage.copyWith und Gleichheit berücksichtigen spam', () {
    final m = MailMessage(id: 'm1', direction: MailDirection.outgoing, from: 'a', to: 'b',
      subject: 's', bodyText: 't', date: DateTime.utc(2026), attachments: const []);
    expect(m.spam, false);
    final spamMsg = m.copyWith(spam: true);
    expect(spamMsg.spam, true);
    expect(spamMsg == m, false);
    expect(spamMsg, m.copyWith(spam: true));
  });

  test('bodyHtml von MailMessage lässt sich leeren', () {
    final voll = MailMessage(
      id: 'm1',
      direction: MailDirection.incoming,
      from: 'ada@example.invalid',
      to: 'ich@example.invalid',
      subject: 'Angebot',
      bodyText: 'Text',
      date: DateTime(2026, 7, 31, 10),
      bodyHtml: '<p>Text</p>',
    );
    final leer = voll.copyWith(clearBodyHtml: true);
    expect(leer.bodyHtml, isNull);
    expect(leer.subject, 'Angebot');
  });

  test('MailMessage: ohne clear bleibt bodyHtml stehen', () {
    final voll = MailMessage(
      id: 'm1',
      direction: MailDirection.incoming,
      from: 'ada@example.invalid',
      to: 'ich@example.invalid',
      subject: 'Angebot',
      bodyText: 'Text',
      date: DateTime(2026, 7, 31, 10),
      bodyHtml: '<p>Text</p>',
    );
    final neu = voll.copyWith(subject: 'Neues Angebot');
    expect(neu.bodyHtml, '<p>Text</p>');
    expect(neu.subject, 'Neues Angebot');
  });

  test(
      'MailMessage: clear zusammen mit einem Wert ist ein Programmierfehler',
      () {
    final voll = MailMessage(
      id: 'm1',
      direction: MailDirection.incoming,
      from: 'ada@example.invalid',
      to: 'ich@example.invalid',
      subject: 'Angebot',
      bodyText: 'Text',
      date: DateTime(2026, 7, 31, 10),
      bodyHtml: '<p>Text</p>',
    );
    expect(
      () => voll.copyWith(bodyHtml: '<p>Neu</p>', clearBodyHtml: true),
      throwsAssertionError,
    );
  });
}
