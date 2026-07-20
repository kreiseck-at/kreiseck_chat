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
}
