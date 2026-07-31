import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  test('inkFor derives from the given bubble color', () {
    const colors = ChatColors.light();
    final ink = colors.inkFor(colors.incomingBubble);
    expect(contrastRatio(ink.text, colors.incomingBubble),
        greaterThanOrEqualTo(4.5));
  });

  test('inkFor follows the polarity of the text painted on the bubble', () {
    // The light preset's outgoing bubble is the standard blue #3478F6, and
    // outgoingText is white, which only reaches 4.07:1 against it -- below
    // the usual 4.5:1 target. inkFor still follows that polarity (rather
    // than switching to higher-contrast black) so the timestamp, reply name
    // and quote bar all read as light, matching the message text instead of
    // clashing with it. See BubbleInk.forSurface for the accepted trade-off.
    const colors = ChatColors.light();
    final ink = colors.inkFor(colors.outgoingBubble);
    expect(relativeLuminance(ink.text), greaterThan(0.5));
    expect(relativeLuminance(ink.muted), greaterThan(0.5));
    expect(relativeLuminance(ink.line), greaterThan(0.5));
    expect(contrastRatio(ink.text, colors.outgoingBubble),
        greaterThanOrEqualTo(4.0));
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

  test(
      'a set incomingInk still wins when incoming and outgoing bubbles share '
      'a color', () {
    // Regression: inkFor used to return unconditionally as soon as bubble ==
    // outgoingBubble, so once both bubbles share a fill color a set
    // incomingInk was silently ignored -- the caller must pass isOutgoing to
    // disambiguate, since bubble color equality can no longer do it.
    const incomingInk = BubbleInk(
      text: Color(0xFF00FF00),
      muted: Color(0xFF00FF00),
      line: Color(0xFF00FF00),
    );
    const base = ChatColors.light();
    final colors =
        base.copyWith(outgoingBubble: base.incomingBubble, incomingInk: incomingInk);
    expect(colors.incomingBubble, colors.outgoingBubble);

    expect(colors.inkFor(colors.incomingBubble, isOutgoing: false), incomingInk);
    // The outgoing bubble must not pick up incomingInk just because the
    // colors match, nor should it fall back to incomingText's polarity.
    expect(colors.inkFor(colors.outgoingBubble, isOutgoing: true), isNot(incomingInk));
  });

  test(
      'the incoming bubble derives from incomingText, not outgoingText, when '
      'both bubbles share a color', () {
    // Regression: with incomingBubble == outgoingBubble, inkFor used to
    // treat every call as the outgoing bubble and derive from outgoingText's
    // polarity regardless of which bubble was actually meant.
    const base = ChatColors.light();
    // The light preset already has a dark incomingText and a light
    // outgoingText -- share the outgoing bubble's blue so a bug that
    // defaults to outgoingText's polarity is visible as light (not dark)
    // derived tones.
    final colors = base.copyWith(incomingBubble: base.outgoingBubble);
    expect(colors.incomingBubble, colors.outgoingBubble);

    final ink = colors.inkFor(colors.incomingBubble, isOutgoing: false);
    expect(relativeLuminance(ink.text), lessThan(0.5));
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
