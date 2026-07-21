import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

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
}
