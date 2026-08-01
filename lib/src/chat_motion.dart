import 'package:flutter/animation.dart';

/// Animation and haptic configuration. Everything defaults to on; use
/// [ChatMotion.none] to disable all motion and haptics at once, or toggle
/// individual flags.
class ChatMotion {
  /// Creates a motion config (all effects enabled by default).
  const ChatMotion({
    this.bubbleEntrance = true,
    this.sendAnimation = true,
    this.animatedAutoScroll = true,
    this.hapticsEnabled = true,
    this.hapticOnSend = true,
    this.hapticOnReceive = false,
    this.hapticOnLongPress = true,
    this.hapticOnReaction = true,
    this.bubbleEntranceDuration = const Duration(milliseconds: 220),
    this.autoScrollDuration = const Duration(milliseconds: 300),
    this.entranceCurve = Curves.easeOutCubic,
  });

  /// All motion and haptics off.
  const ChatMotion.none()
    : bubbleEntrance = false,
      sendAnimation = false,
      animatedAutoScroll = false,
      hapticsEnabled = false,
      hapticOnSend = false,
      hapticOnReceive = false,
      hapticOnLongPress = false,
      hapticOnReaction = false,
      bubbleEntranceDuration = Duration.zero,
      autoScrollDuration = Duration.zero,
      entranceCurve = Curves.linear;

  /// Animate new bubbles in.
  final bool bubbleEntrance;

  /// Animate the send button on submit.
  final bool sendAnimation;

  /// Animate auto-scroll to newest (vs jump).
  final bool animatedAutoScroll;

  /// Master switch for haptics.
  final bool hapticsEnabled;

  /// Haptic on send.
  final bool hapticOnSend;

  /// Haptic when a new incoming message arrives.
  final bool hapticOnReceive;

  /// Haptic on bubble long-press.
  final bool hapticOnLongPress;

  /// Haptic when toggling a reaction.
  final bool hapticOnReaction;

  /// Bubble entrance duration.
  final Duration bubbleEntranceDuration;

  /// Auto-scroll animation duration.
  final Duration autoScrollDuration;

  /// Bubble entrance curve.
  final Curve entranceCurve;

  /// Returns a copy with the given fields replaced.
  ChatMotion copyWith({
    bool? bubbleEntrance,
    bool? sendAnimation,
    bool? animatedAutoScroll,
    bool? hapticsEnabled,
    bool? hapticOnSend,
    bool? hapticOnReceive,
    bool? hapticOnLongPress,
    bool? hapticOnReaction,
    Duration? bubbleEntranceDuration,
    Duration? autoScrollDuration,
    Curve? entranceCurve,
  }) {
    return ChatMotion(
      bubbleEntrance: bubbleEntrance ?? this.bubbleEntrance,
      sendAnimation: sendAnimation ?? this.sendAnimation,
      animatedAutoScroll: animatedAutoScroll ?? this.animatedAutoScroll,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      hapticOnSend: hapticOnSend ?? this.hapticOnSend,
      hapticOnReceive: hapticOnReceive ?? this.hapticOnReceive,
      hapticOnLongPress: hapticOnLongPress ?? this.hapticOnLongPress,
      hapticOnReaction: hapticOnReaction ?? this.hapticOnReaction,
      bubbleEntranceDuration:
          bubbleEntranceDuration ?? this.bubbleEntranceDuration,
      autoScrollDuration: autoScrollDuration ?? this.autoScrollDuration,
      entranceCurve: entranceCurve ?? this.entranceCurve,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMotion &&
        other.bubbleEntrance == bubbleEntrance &&
        other.sendAnimation == sendAnimation &&
        other.animatedAutoScroll == animatedAutoScroll &&
        other.hapticsEnabled == hapticsEnabled &&
        other.hapticOnSend == hapticOnSend &&
        other.hapticOnReceive == hapticOnReceive &&
        other.hapticOnLongPress == hapticOnLongPress &&
        other.hapticOnReaction == hapticOnReaction &&
        other.bubbleEntranceDuration == bubbleEntranceDuration &&
        other.autoScrollDuration == autoScrollDuration &&
        other.entranceCurve == entranceCurve;
  }

  @override
  int get hashCode => Object.hashAll([
    bubbleEntrance,
    sendAnimation,
    animatedAutoScroll,
    hapticsEnabled,
    hapticOnSend,
    hapticOnReceive,
    hapticOnLongPress,
    hapticOnReaction,
    bubbleEntranceDuration,
    autoScrollDuration,
    entranceCurve,
  ]);
}
