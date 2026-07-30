import 'dart:math' as math;
import 'dart:ui';

/// Relative luminance of [color] per WCAG 2.1, in the range 0 (black) to
/// 1 (white). Alpha is ignored: colors are assumed to be composited already.
double relativeLuminance(Color color) {
  double channel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// Contrast ratio between two colors per WCAG 2.1, from 1 (identical) to
/// 21 (black on white). Symmetric in its arguments.
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
