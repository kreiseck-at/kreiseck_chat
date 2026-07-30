import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  group('relativeLuminance', () {
    test('black is 0, white is 1', () {
      expect(relativeLuminance(const Color(0xFF000000)), closeTo(0.0, 0.0001));
      expect(relativeLuminance(const Color(0xFFFFFFFF)), closeTo(1.0, 0.0001));
    });

    test('mid grey sits below the midpoint (sRGB is not linear)', () {
      final grey = relativeLuminance(const Color(0xFF808080));
      expect(grey, greaterThan(0.2));
      expect(grey, lessThan(0.25));
    });
  });

  group('contrastRatio', () {
    test('black on white is the maximum 21:1', () {
      expect(
        contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21.0, 0.01),
      );
    });

    test('a color against itself is 1:1', () {
      expect(
        contrastRatio(const Color(0xFF3478F6), const Color(0xFF3478F6)),
        closeTo(1.0, 0.0001),
      );
    });

    test('order does not matter', () {
      const a = Color(0xFF3478F6);
      const b = Color(0xFFFAFAFA);
      expect(contrastRatio(a, b), closeTo(contrastRatio(b, a), 0.0001));
    });

    test('matches known reference values', () {
      // Die heutige Fehlerfarbe auf hellem und dunklem Hintergrund.
      expect(
        contrastRatio(const Color(0xFFB5374A), const Color(0xFFFAFAFA)),
        closeTo(5.57, 0.05),
      );
      expect(
        contrastRatio(const Color(0xFFB5374A), const Color(0xFF1C1C1E)),
        closeTo(2.93, 0.05),
      );
    });
  });
}
