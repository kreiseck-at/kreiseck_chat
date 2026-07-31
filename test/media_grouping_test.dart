import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

ChatMessage bild(
  String id, {
  int minute = 0,
  MessageDirection direction = MessageDirection.incoming,
  String text = '',
  MessageStatus status = MessageStatus.sent,
}) =>
    ChatMessage(
      id: id,
      direction: direction,
      text: text,
      at: DateTime(2026, 7, 31, 10, minute),
      status: status,
      attachments: [
        ChatAttachment(kind: AttachmentKind.image, url: 'https://x/$id.jpg'),
      ],
    );

ChatMessage text(String id, {int minute = 0}) => ChatMessage(
      id: id,
      direction: MessageDirection.incoming,
      text: 'Hallo',
      at: DateTime(2026, 7, 31, 10, minute),
    );

void main() {
  test('aufeinanderfolgende Bilder werden ein Album', () {
    final r = groupMediaRuns([
      bild('a', minute: 0),
      bild('b', minute: 1),
      bild('c', minute: 2),
    ]);
    expect(r.length, 1);
    // Die Kennung der ersten bleibt — sonst wechselt der Schlüssel der Blase,
    // während weitere Fotos eintreffen.
    expect(r.single.id, 'a');
    expect(r.single.attachments.length, 3);
    // Zeitstempel und Zustand kommen vom jüngsten Bild.
    expect(r.single.at, DateTime(2026, 7, 31, 10, 2));
  });

  test('Text dazwischen trennt die Alben', () {
    final r = groupMediaRuns([
      bild('a', minute: 0),
      bild('b', minute: 1),
      text('t', minute: 2),
      bild('c', minute: 3),
      bild('d', minute: 4),
    ]);
    expect(r.map((m) => m.id).toList(), ['a', 't', 'c']);
    expect(r.first.attachments.length, 2);
    expect(r.last.attachments.length, 2);
  });

  test('Richtungswechsel trennt', () {
    final r = groupMediaRuns([
      bild('a', minute: 0),
      bild('b', minute: 1, direction: MessageDirection.outgoing),
    ]);
    expect(r.length, 2);
  });

  test('zu großer Abstand trennt', () {
    final r = groupMediaRuns([bild('a', minute: 0), bild('b', minute: 30)]);
    expect(r.length, 2);

    final eng = groupMediaRuns(
      [bild('a', minute: 0), bild('b', minute: 30)],
      window: const Duration(hours: 1),
    );
    expect(eng.length, 1);
  });

  test('Bild mit Bildunterschrift bleibt für sich', () {
    final r = groupMediaRuns([
      bild('a', minute: 0),
      bild('b', minute: 1, text: 'Schau mal'),
      bild('c', minute: 2),
    ]);
    expect(r.map((m) => m.id).toList(), ['a', 'b', 'c']);
  });

  test('Zustand des jüngsten Bildes gewinnt — ein Album, das noch sendet', () {
    final r = groupMediaRuns([
      bild('a', minute: 0),
      bild('b', minute: 1, status: MessageStatus.sending),
    ]);
    expect(r.single.status, MessageStatus.sending);
  });

  test('leere Liste und Einzelbild bleiben unverändert', () {
    expect(groupMediaRuns([]), isEmpty);
    final einzeln = groupMediaRuns([bild('a')]);
    expect(einzeln.single.id, 'a');
    expect(einzeln.single.attachments.length, 1);
  });
}
