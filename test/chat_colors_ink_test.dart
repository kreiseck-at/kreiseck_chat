import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  test('inkFor derives from the given bubble color', () {
    const colors = ChatColors.light();
    final ink = colors.inkFor(colors.outgoingBubble);
    expect(contrastRatio(ink.text, colors.outgoingBubble),
        greaterThanOrEqualTo(4.5));
  });

  test('an explicitly set ink wins over the derived one', () {
    const custom = BubbleInk(
      text: Color(0xFF00FF00),
      muted: Color(0xFF00FF00),
      line: Color(0xFF00FF00),
    );
    const colors = ChatColors.light(outgoingInk: custom);
    expect(colors.inkFor(colors.outgoingBubble).text, const Color(0xFF00FF00));
    // Für die eingehende Bubble bleibt es bei der Ableitung.
    expect(colors.inkFor(colors.incomingBubble).text, isNot(const Color(0xFF00FF00)));
  });

  test('the error tone is readable on both backgrounds', () {
    const light = ChatColors.light();
    const dark = ChatColors.dark();
    expect(contrastRatio(light.errorOnBackground, light.background),
        greaterThanOrEqualTo(4.5));
    expect(contrastRatio(dark.errorOnBackground, dark.background),
        greaterThanOrEqualTo(4.5));
  });

  test('the raw warning color still fails on the light background', () {
    // Belegt, dass die Ableitung tatsächlich etwas bewirkt: anders als die
    // Fehlerfarbe unterschreitet die Warnfarbe im hellen Preset 4.5:1.
    const light = ChatColors.light();
    expect(contrastRatio(light.warning, light.background), lessThan(4.5));
  });

  test('copyWith carries the ink overrides', () {
    const custom = BubbleInk(
      text: Color(0xFF112233),
      muted: Color(0xFF112233),
      line: Color(0xFF112233),
    );
    final copied = const ChatColors.light().copyWith(incomingInk: custom);
    expect(copied.incomingInk, custom);
    expect(copied.outgoingInk, isNull);
  });
}
