import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

// 1x1 transparentes PNG als gültige Bytes für MemoryImage im Test.
final _pixel = MemoryImage(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='));

void main() {
  test('attachment JSON round-trips (thumbnail provider excluded)', () {
    const a = ChatAttachment(
      kind: AttachmentKind.image,
      url: 'https://x/y.jpg',
      thumbnailUrl: 'https://x/y_t.jpg',
      fileName: 'y.jpg',
      sizeBytes: 4096,
      width: 800,
      height: 600,
    );
    final json = a.toJson();
    expect(json['kind'], 'image');
    expect(ChatAttachment.fromJson(json), equals(a));
    expect(json.containsKey('thumbnail'), isFalse);
  });

  test('reaction copyWith bumps count', () {
    const r = MessageReaction(emoji: '❤️');
    expect(r.count, 1);
    expect(r.copyWith(count: 3, reactedByMe: true).count, 3);
    expect(r.copyWith(reactedByMe: true).reactedByMe, isTrue);
  });

  test('reaction value equality', () {
    expect(const MessageReaction(emoji: '👍', count: 2),
        equals(const MessageReaction(emoji: '👍', count: 2)));
  });

  test('jedes nullable Feld von ChatAttachment lässt sich leeren', () {
    final voll = ChatAttachment(
      kind: AttachmentKind.image,
      url: 'https://example.invalid/a.png',
      thumbnail: _pixel,
      thumbnailUrl: 'https://example.invalid/t.png',
      fileName: 'a.png',
      sizeBytes: 1024,
      width: 800,
      height: 600,
    );
    final leer = voll.copyWith(
      clearUrl: true,
      clearThumbnail: true,
      clearThumbnailUrl: true,
      clearFileName: true,
      clearSizeBytes: true,
      clearWidth: true,
      clearHeight: true,
    );
    expect(leer.url, isNull);
    expect(leer.thumbnail, isNull);
    expect(leer.thumbnailUrl, isNull);
    expect(leer.fileName, isNull);
    expect(leer.sizeBytes, isNull);
    expect(leer.width, isNull);
    expect(leer.height, isNull);
    expect(leer.kind, AttachmentKind.image);
  });

  test('ChatAttachment: ohne clear bleiben alle Felder stehen', () {
    final voll = ChatAttachment(
      kind: AttachmentKind.file,
      url: 'https://example.invalid/a.pdf',
      thumbnailUrl: 'https://example.invalid/t.png',
      fileName: 'a.pdf',
      sizeBytes: 2048,
      width: 100,
      height: 200,
    );
    final neu = voll.copyWith(kind: AttachmentKind.file);
    expect(neu.url, 'https://example.invalid/a.pdf');
    expect(neu.thumbnailUrl, 'https://example.invalid/t.png');
    expect(neu.fileName, 'a.pdf');
    expect(neu.sizeBytes, 2048);
    expect(neu.width, 100);
    expect(neu.height, 200);
  });

  test(
      'ChatAttachment: clear zusammen mit einem Wert ist ein Programmierfehler',
      () {
    const voll = ChatAttachment(
      kind: AttachmentKind.file,
      fileName: 'a.pdf',
      sizeBytes: 2048,
    );
    expect(
      () => voll.copyWith(fileName: 'b.pdf', clearFileName: true),
      throwsAssertionError,
    );
    expect(
      () => voll.copyWith(sizeBytes: 4096, clearSizeBytes: true),
      throwsAssertionError,
    );
  });
}
