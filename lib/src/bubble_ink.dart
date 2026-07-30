import 'package:flutter/material.dart';

import 'contrast.dart';

/// The colors that sit *on* a surface — a bubble fill or the thread
/// background. Derived from that surface so a host only has to pick the
/// surface color and everything on it stays legible.
@immutable
class BubbleInk {
  /// Creates an ink set explicitly. Prefer [BubbleInk.forSurface].
  const BubbleInk({required this.text, required this.muted, required this.line});

  /// Message text and emphasised labels. Reaches at least 4.5:1.
  final Color text;

  /// Timestamps, delivery status, quoted text. Reaches at least 4.5:1 but is
  /// visibly softer than [text].
  final Color muted;

  /// Quote bars, dividers and other non-text marks. Reaches at least 3:1.
  final Color line;

  /// Derives an ink set from [surface]: white or black — whichever contrasts
  /// more — is mixed back towards the surface as far as the target still
  /// holds. The target is therefore a property of the calculation, not a hope.
  factory BubbleInk.forSurface(Color surface) {
    final base = contrastRatio(const Color(0xFFFFFFFF), surface) >=
            contrastRatio(const Color(0xFF000000), surface)
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);
    return BubbleInk(
      text: base,
      muted: _mixUntil(base, surface, 4.5),
      line: _mixUntil(base, surface, 3.0),
    );
  }

  /// Mixes [base] towards [surface] in 5% steps and returns the softest color
  /// that still reaches [target].
  static Color _mixUntil(Color base, Color surface, double target) {
    var result = base;
    for (var t = 0.05; t <= 0.95; t += 0.05) {
      final candidate = Color.lerp(base, surface, t)!;
      if (contrastRatio(candidate, surface) < target) break;
      result = candidate;
    }
    return result;
  }
}

/// Returns [desired] if it already reaches [target] against [surface],
/// otherwise the same hue mixed towards the readable end until it does.
///
/// Used for colors that carry meaning of their own — an error red, a read
/// receipt blue — which must stay recognisable rather than be replaced.
Color readableOn(Color surface, Color desired, {double target = 4.5}) {
  if (contrastRatio(desired, surface) >= target) return desired;
  final towards = relativeLuminance(surface) > 0.5
      ? const Color(0xFF000000)
      : const Color(0xFFFFFFFF);
  for (var t = 0.05; t <= 1.0; t += 0.05) {
    final candidate = Color.lerp(desired, towards, t)!;
    if (contrastRatio(candidate, surface) >= target) return candidate;
  }
  return towards;
}
