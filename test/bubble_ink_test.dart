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

  group('BubbleInk.forSurface with textColor', () {
    test('without textColor, behaviour is unchanged from plain forSurface',
        () {
      // Belegt die Zusicherung, dass der neue Parameter optional ist: ohne
      // ihn liefert forSurface exakt dasselbe Ergebnis wie zuvor -- auf dem
      // Standard-Blau also weiterhin Schwarz als Basis (höherer Kontrast).
      for (final surface in _surfaces) {
        expect(BubbleInk.forSurface(surface),
            equals(BubbleInk.forSurface(surface, textColor: null)));
      }
      final onBlue = BubbleInk.forSurface(const Color(0xFF3478F6));
      expect(relativeLuminance(onBlue.text), lessThan(0.5));
    });

    test(
        'white text on the standard blue keeps every derived tone light, '
        'even though black would contrast more', () {
      // Kern der Owner-Entscheidung: ohne textColor gewinnt hier Schwarz
      // (5,16:1 gegen 4,07:1 für Weiß) -- mit weißer Textfarbe muss die
      // Ableitung trotzdem bei Weiß bleiben, sonst stünde weißer
      // Nachrichtentext neben fast schwarzer Uhrzeit/Reply-Name auf
      // derselben Bubble. Dieser Test schlägt ohne die Änderung fehl, weil
      // forSurface dann Schwarz wählt.
      const surface = Color(0xFF3478F6);
      const white = Color(0xFFFFFFFF);
      final ink = BubbleInk.forSurface(surface, textColor: white);

      expect(relativeLuminance(ink.text), greaterThan(0.5));
      expect(relativeLuminance(ink.muted), greaterThan(0.5));
      expect(relativeLuminance(ink.line), greaterThan(0.5));
      // Bewusst in Kauf genommene Obergrenze: Weiß erreicht auf diesem Blau
      // nur ~4,07:1, nicht die üblichen 4,5:1.
      expect(contrastRatio(ink.text, surface), greaterThanOrEqualTo(4.0));
      expect(contrastRatio(ink.text, surface), lessThan(4.5));
    });

    test('dark text on a light bubble gets dark derived tones', () {
      const surface = Color(0xFFE9E9EB);
      const darkText = Color(0xFF1C1C1E);
      final ink = BubbleInk.forSurface(surface, textColor: darkText);

      expect(relativeLuminance(ink.text), lessThan(0.5));
      expect(relativeLuminance(ink.muted), lessThan(0.5));
      expect(relativeLuminance(ink.line), lessThan(0.5));
      expect(contrastRatio(ink.text, surface), greaterThanOrEqualTo(4.5));
    });

    test(
        'white text on a white bubble still yields readable, dark tones '
        'instead of collapsing to invisible white-on-white', () {
      // Ausnahmefall: Weiß kann auf Weiß nicht einmal ansatzweise (< 3:1)
      // lesbar werden -- die andere Polung (Schwarz) gewinnt dann trotz
      // angeforderter weißer Textfarbe.
      const surface = Color(0xFFFFFFFF);
      const white = Color(0xFFFFFFFF);
      final ink = BubbleInk.forSurface(surface, textColor: white);

      expect(relativeLuminance(ink.text), lessThan(0.5));
      expect(contrastRatio(ink.text, surface), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(ink.muted, surface), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(ink.line, surface), greaterThanOrEqualTo(3.0));
    });
  });

  group('BubbleInk equality', () {
    test('two separately-derived instances with equal fields compare equal',
        () {
      // Built via forSurface (not `const` literals) so the compiler cannot
      // canonicalize the two into the same object -- that would let a plain
      // identity-based `==` pass by accident and hide the missing override.
      final a = BubbleInk.forSurface(const Color(0xFF3478F6));
      final b = BubbleInk.forSurface(const Color(0xFF3478F6));
      expect(identical(a, b), isFalse);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differing fields compare unequal', () {
      final a = BubbleInk.forSurface(const Color(0xFF3478F6));
      final b = BubbleInk.forSurface(const Color(0xFF25D366));
      expect(a, isNot(equals(b)));
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

    test('picks the higher-contrast direction on a mid-gray surface', () {
      // Regression: the surface luminance (~0.32) sits above the true WCAG
      // crossover (~0.179) but below the naive 0.5 threshold, so a
      // luminance>0.5 check picks the wrong mix direction and stalls short
      // of the target.
      const surface = Color(0xFF999999);
      const red = Color(0xFFB5374A);
      final fixed = readableOn(surface, red);

      expect(contrastRatio(fixed, surface), greaterThanOrEqualTo(4.5));
      expect(fixed.r, greaterThan(fixed.g));
      expect(fixed.r, greaterThan(fixed.b));
    });

    test('picks the higher-contrast direction on a blue surface', () {
      const surface = Color(0xFF3478F6);
      const red = Color(0xFFB5374A);
      final fixed = readableOn(surface, red);

      expect(contrastRatio(fixed, surface), greaterThanOrEqualTo(4.5));
      expect(fixed.r, greaterThan(fixed.g));
      expect(fixed.r, greaterThan(fixed.b));
    });

    test('reaches the default target across the full brightness range', () {
      const errorRed = Color(0xFFB5374A);
      const surfaces = <Color>[
        Color(0xFF000000),
        Color(0xFF1C1C1E),
        Color(0xFF2C2C2E),
        Color(0xFF4A4A4C),
        Color(0xFF6E6E70),
        Color(0xFF999999),
        Color(0xFFB5B5B5),
        Color(0xFFD0D0D0),
        Color(0xFFE9E9EB),
        Color(0xFFF5F5F5),
        Color(0xFFFFFFFF),
      ];
      for (final surface in surfaces) {
        final fixed = readableOn(surface, errorRed);
        expect(contrastRatio(fixed, surface), greaterThanOrEqualTo(4.5),
            reason: 'auf $surface');
      }
    });

    // Regression: the loop used to accumulate `t` by repeatedly adding 0.05,
    // which drifts far enough that it never lands on t == 1.0 — the pure
    // black/white endpoint, i.e. the highest-contrast candidate reachable at
    // all. That silently dropped exactly the candidate needed whenever only
    // the endpoint itself reaches the target. Every case below reaches 4.5:1
    // only at the endpoint.
    test('reaches the target when only the pure black/white endpoint does', () {
      const cases = <(Color surface, Color desired)>[
        (Color(0xFF0066FF), Color(0xFF000000)),
        (Color(0xFF0066FF), Color(0xFF001A33)),
        (Color(0xFF0066FF), Color(0xFF0D0D0D)),
        (Color(0xFF0066FF), Color(0xFF003300)),
        (Color(0xFF0066FF), Color(0xFF1A001A)),
      ];
      for (final (surface, desired) in cases) {
        final fixed = readableOn(surface, desired, target: 4.5);
        expect(contrastRatio(fixed, surface), greaterThanOrEqualTo(4.5),
            reason: 'surface=$surface desired=$desired');
      }
    });

    test(
        'reaches any target that pure black or white can reach against the surface',
        () {
      // The real assurance: readableOn must never fall short of a target
      // that is mathematically reachable. Black or white touching the target
      // is proof of reachability (they are the highest-contrast candidates
      // possible against any surface), so whenever either one does, the
      // function's own result must reach it too. Swept across a grid
      // spanning the color space rather than enumerating specific colors.
      const steps = <int>[0, 32, 64, 96, 128, 160, 192, 224, 255];
      const target = 4.5;
      var checked = 0;
      for (final sr in steps) {
        for (final sg in steps) {
          for (final sb in steps) {
            final surface = Color.fromARGB(255, sr, sg, sb);
            final blackContrast =
                contrastRatio(const Color(0xFF000000), surface);
            final whiteContrast =
                contrastRatio(const Color(0xFFFFFFFF), surface);
            if (blackContrast < target && whiteContrast < target) {
              // Target is not reachable against this surface at all — skip,
              // readableOn is only required to hit reachable targets.
              continue;
            }
            // A desired color that itself fails the target, so readableOn
            // is forced to mix. Derived from the surface so it varies across
            // the grid instead of being a single fixed probe color.
            final desired = Color.fromARGB(
              255,
              (sr + 96) % 256,
              (sg + 48) % 256,
              (sb + 160) % 256,
            );
            if (contrastRatio(desired, surface) >= target) continue;

            checked++;
            final fixed = readableOn(surface, desired, target: target);
            expect(contrastRatio(fixed, surface), greaterThanOrEqualTo(target),
                reason: 'surface=$surface desired=$desired');
          }
        }
      }
      // Sanity check: the sweep actually exercised a meaningful number of
      // mixing cases rather than skipping almost everything.
      expect(checked, greaterThanOrEqualTo(200));
    });
  });
}
