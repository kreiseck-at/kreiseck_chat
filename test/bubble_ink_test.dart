import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

/// Farben, an denen sich die Ableitung beweisen muss — Marken-Blau, Grün,
/// Gelb (hell!), Schwarz, Weiß und ein knalliges Pink.
const _surfaces = <Color>[
  Color(0xFF3478F6),
  Color(0xFF25D366),
  Color(0xFFFFD60A),
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFFFF2D95),
  Color(0xFFE9E9EB),
  Color(0xFF2C2C2E),
];

void main() {
  group('BubbleInk.forSurface', () {
    test('text and muted reach 4.5:1 on every surface', () {
      for (final surface in _surfaces) {
        final ink = BubbleInk.forSurface(surface);
        expect(contrastRatio(ink.text, surface), greaterThanOrEqualTo(4.5),
            reason: 'text auf $surface');
        expect(contrastRatio(ink.muted, surface), greaterThanOrEqualTo(4.5),
            reason: 'muted auf $surface');
      }
    });

    test('line reaches 3:1 on every surface', () {
      for (final surface in _surfaces) {
        final ink = BubbleInk.forSurface(surface);
        expect(contrastRatio(ink.line, surface), greaterThanOrEqualTo(3.0),
            reason: 'line auf $surface');
      }
    });

    test('muted is softer than text, line softer than muted', () {
      for (final surface in _surfaces) {
        final ink = BubbleInk.forSurface(surface);
        expect(contrastRatio(ink.text, surface),
            greaterThanOrEqualTo(contrastRatio(ink.muted, surface)),
            reason: 'auf $surface');
        expect(contrastRatio(ink.muted, surface),
            greaterThanOrEqualTo(contrastRatio(ink.line, surface)),
            reason: 'auf $surface');
      }
    });

    test('dark surfaces get light ink, light surfaces get dark ink', () {
      expect(relativeLuminance(BubbleInk.forSurface(const Color(0xFF000000)).text),
          greaterThan(0.5));
      expect(relativeLuminance(BubbleInk.forSurface(const Color(0xFFFFFFFF)).text),
          lessThan(0.5));
    });
  });

  group('readableOn', () {
    test('keeps a color that already passes', () {
      const surface = Color(0xFFFAFAFA);
      const red = Color(0xFFB5374A);
      expect(readableOn(surface, red), red);
    });

    test('lifts a color that fails, keeping it recognisably red', () {
      const darkSurface = Color(0xFF1C1C1E);
      const red = Color(0xFFB5374A);
      final fixed = readableOn(darkSurface, red);

      expect(contrastRatio(fixed, darkSurface), greaterThanOrEqualTo(4.5));
      // Rot bleibt rot: der Rotkanal dominiert weiterhin.
      expect(fixed.r, greaterThan(fixed.g));
      expect(fixed.r, greaterThan(fixed.b));
    });

    test('honours a lower target for icons', () {
      const surface = Color(0xFF3478F6);
      const readReceipt = Color(0xFF34B7F1);
      final fixed = readableOn(surface, readReceipt, target: 3.0);
      expect(contrastRatio(fixed, surface), greaterThanOrEqualTo(3.0));
    });
  });
}
