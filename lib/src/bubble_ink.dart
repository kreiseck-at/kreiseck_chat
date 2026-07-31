import 'package:flutter/material.dart';

import 'contrast.dart';

/// The colors that sit *on* a surface — a bubble fill or the thread
/// background. Derived from that surface so a host only has to pick the
/// surface color and everything on it stays legible.
@immutable
class BubbleInk {
  /// Creates an ink set explicitly. Prefer [BubbleInk.forSurface].
  const BubbleInk({required this.text, required this.muted, required this.line});

  /// Message text and emphasised labels. Reaches at least 4.5:1 — unless
  /// [BubbleInk.forSurface] was given a `textColor` whose polarity itself
  /// can't reach it (the accepted standard-blue trade-off; see there).
  final Color text;

  /// Timestamps, delivery status, quoted text. Reaches at least 4.5:1 (with
  /// the same `textColor` caveat as [text]) but is visibly softer than
  /// [text].
  final Color muted;

  /// Quote bars, dividers and other non-text marks. Reaches at least 3:1.
  final Color line;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BubbleInk &&
        other.text == text &&
        other.muted == muted &&
        other.line == line;
  }

  @override
  int get hashCode => Object.hash(text, muted, line);

  /// Derives an ink set from [surface]: white or black is mixed back towards
  /// the surface as far as the target still holds. The target is therefore a
  /// property of the calculation, not a hope.
  ///
  /// Which of white or black is picked as the base depends on [textColor]:
  ///
  /// * Left `null` (the default), the base is whichever of the two reaches
  ///   the higher contrast against [surface]. This is the original behaviour
  ///   and is unchanged by [textColor] — callers that never pass it see no
  ///   difference.
  /// * Given a color, the base instead follows that color's polarity: a
  ///   light [textColor] (relative luminance ≥ 0.5) picks white, a dark one
  ///   picks black. This exists so a surface's derived timestamp, quote bar
  ///   and reply name match the message text actually painted on it, rather
  ///   than independently chasing whichever of black/white contrasts more —
  ///   the two can disagree (e.g. on the standard blue `#3478F6`, black
  ///   reaches 5.16:1 against white's 4.07:1), and when they do, painting the
  ///   text one way and everything else the other way reads as a rendering
  ///   bug, not a considered choice. On the standard blue with a white
  ///   [textColor], this deliberately caps [text] around 4.07:1 instead of
  ///   the usual 4.5:1 — a known, accepted trade-off in favour of one
  ///   consistent tone across the bubble.
  ///
  ///   Exception: if that polarity's extreme point — pure white or pure
  ///   black itself, before any mixing towards [surface] — can't even reach
  ///   3:1 against [surface] (the same floor [line] targets below, and
  ///   WCAG's own minimum for large text/UI components), it is treated as
  ///   unusable and the other polarity wins regardless of how it compares.
  ///   3:1 rather than [text]'s own 4.5:1 target is deliberate: using 4.5:1
  ///   here would reject the standard-blue trade-off above too, defeating
  ///   the point of following [textColor] at all. 3:1 instead marks the
  ///   point below which a tone is not "a bit low contrast" but effectively
  ///   invisible — e.g. white ink on a white surface.
  factory BubbleInk.forSurface(Color surface, {Color? textColor}) {
    final base = _resolveBase(surface, textColor);
    return BubbleInk(
      text: base,
      muted: _mixUntil(base, surface, 4.5),
      line: _mixUntil(base, surface, 3.0),
    );
  }

  /// The floor an extreme point (pure white or pure black) must clear for
  /// its polarity to be considered usable at all when [textColor] steers the
  /// choice. See the "Exception" paragraph on [forSurface].
  static const double _minimumUsableContrast = 3.0;

  static Color _resolveBase(Color surface, Color? textColor) {
    const white = Color(0xFFFFFFFF);
    const black = Color(0xFF000000);
    final whiteContrast = contrastRatio(white, surface);
    final blackContrast = contrastRatio(black, surface);

    if (textColor == null) {
      return whiteContrast >= blackContrast ? white : black;
    }

    final wantsLight = relativeLuminance(textColor) >= 0.5;
    final preferred = wantsLight ? white : black;
    final preferredContrast = wantsLight ? whiteContrast : blackContrast;
    final other = wantsLight ? black : white;
    final otherContrast = wantsLight ? blackContrast : whiteContrast;

    if (preferredContrast < _minimumUsableContrast &&
        otherContrast >= _minimumUsableContrast) {
      return other;
    }
    return preferred;
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
