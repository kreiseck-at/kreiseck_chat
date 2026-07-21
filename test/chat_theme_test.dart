import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  test('presets pick the right bubble style', () {
    expect(ChatTheme.whatsApp().bubbleStyle, BubbleStyle.whatsApp);
    expect(ChatTheme.iMessage().bubbleStyle, BubbleStyle.iMessage);
    expect(const ChatTheme.light().bubbleStyle, BubbleStyle.minimal);
  });

  test('ChatMotion.none disables everything', () {
    const m = ChatMotion.none();
    expect(m.bubbleEntrance, isFalse);
    expect(m.sendAnimation, isFalse);
    expect(m.animatedAutoScroll, isFalse);
    expect(m.hapticsEnabled, isFalse);
  });

  test('default ChatMotion is all-on', () {
    const m = ChatMotion();
    expect(m.hapticsEnabled, isTrue);
    expect(m.bubbleEntrance, isTrue);
  });

  test('copyWith swaps a single sub-config, keeps the rest', () {
    final base = ChatTheme.iMessage();
    final quiet = base.copyWith(motion: const ChatMotion.none());
    expect(quiet.motion.hapticsEnabled, isFalse);
    expect(quiet.bubbleStyle, BubbleStyle.iMessage);
    expect(quiet.colors, base.colors);
  });

  test('back-compat getters still resolve', () {
    const t = ChatTheme.light();
    expect(t.accentColor, isA<Color>());
    expect(t.bubbleRadius, greaterThan(0));
  });

  test('typography from text theme fills body', () {
    final typo = ChatTypography.fromTextTheme(ThemeData.light().textTheme);
    expect(typo.body, isA<TextStyle>());
  });
}
