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
  /// that still reaches [target]. Steps are counted as integers so the last
  /// step is reached exactly, with no floating-point drift.
  static Color _mixUntil(Color base, Color surface, double target) {
    var result = base;
    for (var i = 1; i <= 19; i++) {
      final t = i / 20;
      final candidate = Color.lerp(base, surface, t)!;
      if (contrastRatio(candidate, surface) < target) break;
      result = candidate;
    }
    return result;
  }
}

/// Returns [desired] if it already reaches [target] against [surface],
/// otherwise the same hue mixed towards whichever endpoint — black or white —
/// contrasts more against [surface], stepped only as far as needed to reach
/// [target] again.
///
/// Used for colors that carry meaning of their own — an error red, a read
/// receipt blue — which must stay recognisable rather than be replaced.
///
/// [target] is an abort condition of the calculation, not a hope: whenever a
/// mix towards either endpoint can reach it, the result reaches it. Only when
/// that is mathematically impossible — an unreachable [target], or a
/// [surface] that leaves no headroom — does this fall back to the candidate
/// with the highest contrast actually measured along the way.
Color readableOn(Color surface, Color desired, {double target = 4.5}) {
  if (contrastRatio(desired, surface) >= target) return desired;
  final towards = contrastRatio(const Color(0xFFFFFFFF), surface) >=
          contrastRatio(const Color(0xFF000000), surface)
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF000000);

  var best = desired;
  var bestContrast = contrastRatio(desired, surface);
  // Steps are counted as integers (1..20) rather than accumulated by adding
  // 0.05 repeatedly, so the loop reaches t == 1.0 exactly — the pure
  // black/white endpoint, which is the candidate with the highest contrast
  // that can possibly be reached. Floating-point drift on a `+=` loop would
  // otherwise stop just short of it and silently skip that candidate.
  for (var i = 1; i <= 20; i++) {
    final t = i / 20;
    final candidate = Color.lerp(desired, towards, t)!;
    final contrast = contrastRatio(candidate, surface);
    if (contrast >= target) return candidate;
    if (contrast > bestContrast) {
      best = candidate;
      bestContrast = contrast;
    }
  }
  return best;
}
