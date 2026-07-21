import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  test('twilioSms is text-only', () {
    const c = ChatCapabilities.twilioSms();
    expect(c.reactions, isFalse);
    expect(c.replies, isFalse);
    expect(c.media, isFalse);
    expect(c.typingIndicator, isFalse);
    expect(c.presence, isFalse);
    expect(c.readReceipts, isFalse);
  });

  test('twilioWhatsApp enables media/reactions/replies/readReceipts but not typing/presence', () {
    const c = ChatCapabilities.twilioWhatsApp();
    expect(c.media, isTrue);
    expect(c.reactions, isTrue);
    expect(c.replies, isTrue);
    expect(c.readReceipts, isTrue);
    expect(c.typingIndicator, isFalse);
    expect(c.presence, isFalse);
  });

  test('inApp enables everything', () {
    const c = ChatCapabilities.inApp();
    expect(
      [c.reactions, c.replies, c.media, c.typingIndicator, c.presence, c.readReceipts],
      everyElement(isTrue),
    );
  });

  test('copyWith overrides a single flag and keeps the rest', () {
    const base = ChatCapabilities.twilioSms();
    final withMedia = base.copyWith(media: true);
    expect(withMedia.media, isTrue);
    expect(withMedia.reactions, isFalse);
    expect(withMedia, isNot(equals(base)));
  });

  test('value equality', () {
    expect(const ChatCapabilities.inApp(),
        equals(const ChatCapabilities.custom(
          reactions: true, replies: true, media: true,
          typingIndicator: true, presence: true, readReceipts: true,
        )));
  });
}
