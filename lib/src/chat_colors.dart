import 'package:flutter/material.dart';

/// All colors used by the chat widgets. Every widget reads from here so hosts
/// can rebrand and support light/dark without forking widgets.
class ChatColors {
  /// Creates a color set from explicit values.
  const ChatColors({
    required this.incomingBubble,
    required this.outgoingBubble,
    required this.incomingText,
    required this.outgoingText,
    required this.background,
    required this.composer,
    required this.accent,
    required this.bubbleTail,
    required this.reactionChipBackground,
    required this.reactionChipText,
    required this.presenceOnline,
    required this.typingDot,
    required this.dateSeparatorBackground,
    required this.dateSeparatorText,
    required this.replyAccent,
    this.readReceipt = const Color(0xFF34B7F1),
  });

  /// Incoming bubble fill.
  final Color incomingBubble;

  /// Outgoing bubble fill.
  final Color outgoingBubble;

  /// Incoming text.
  final Color incomingText;

  /// Outgoing text.
  final Color outgoingText;

  /// Thread/list surface.
  final Color background;

  /// Composer bar fill.
  final Color composer;

  /// Accent (send button, read ticks).
  final Color accent;

  /// Fallback tail color (defaults to the matching bubble fill when equal).
  final Color bubbleTail;

  /// Reaction chip fill.
  final Color reactionChipBackground;

  /// Reaction chip text/emoji-count color.
  final Color reactionChipText;

  /// Online presence dot.
  final Color presenceOnline;

  /// Typing indicator dots.
  final Color typingDot;

  /// Date separator pill fill.
  final Color dateSeparatorBackground;

  /// Date separator text.
  final Color dateSeparatorText;

  /// Reply quote accent bar.
  final Color replyAccent;

  /// Color of the "read" double-check (WhatsApp-style blue), independent of
  /// [accent] so a green/branded accent doesn't tint read receipts.
  final Color readReceipt;

  /// Sensible light palette.
  const ChatColors.light()
      : incomingBubble = const Color(0xFFE9E9EB),
        outgoingBubble = const Color(0xFF3478F6),
        incomingText = const Color(0xFF1C1C1E),
        outgoingText = const Color(0xFFFFFFFF),
        background = const Color(0xFFFAFAFA),
        composer = const Color(0xFFFFFFFF),
        accent = const Color(0xFF3478F6),
        bubbleTail = const Color(0xFFE9E9EB),
        reactionChipBackground = const Color(0xFFFFFFFF),
        reactionChipText = const Color(0xFF1C1C1E),
        presenceOnline = const Color(0xFF34C759),
        typingDot = const Color(0xFF8E8E93),
        dateSeparatorBackground = const Color(0x14000000),
        dateSeparatorText = const Color(0xFF6C6C70),
        replyAccent = const Color(0xFF3478F6),
        readReceipt = const Color(0xFF34B7F1);

  /// Sensible dark palette.
  const ChatColors.dark()
      : incomingBubble = const Color(0xFF2C2C2E),
        outgoingBubble = const Color(0xFF3478F6),
        incomingText = const Color(0xFFF2F2F7),
        outgoingText = const Color(0xFFFFFFFF),
        background = const Color(0xFF000000),
        composer = const Color(0xFF1C1C1E),
        accent = const Color(0xFF64A1FF),
        bubbleTail = const Color(0xFF2C2C2E),
        reactionChipBackground = const Color(0xFF3A3A3C),
        reactionChipText = const Color(0xFFF2F2F7),
        presenceOnline = const Color(0xFF32D74B),
        typingDot = const Color(0xFF98989F),
        dateSeparatorBackground = const Color(0x33FFFFFF),
        dateSeparatorText = const Color(0xFFC7C7CC),
        replyAccent = const Color(0xFF64A1FF),
        readReceipt = const Color(0xFF53BDEB);

  /// Returns a copy with the given fields replaced.
  ChatColors copyWith({
    Color? incomingBubble,
    Color? outgoingBubble,
    Color? incomingText,
    Color? outgoingText,
    Color? background,
    Color? composer,
    Color? accent,
    Color? bubbleTail,
    Color? reactionChipBackground,
    Color? reactionChipText,
    Color? presenceOnline,
    Color? typingDot,
    Color? dateSeparatorBackground,
    Color? dateSeparatorText,
    Color? replyAccent,
    Color? readReceipt,
  }) {
    return ChatColors(
      incomingBubble: incomingBubble ?? this.incomingBubble,
      outgoingBubble: outgoingBubble ?? this.outgoingBubble,
      incomingText: incomingText ?? this.incomingText,
      outgoingText: outgoingText ?? this.outgoingText,
      background: background ?? this.background,
      composer: composer ?? this.composer,
      accent: accent ?? this.accent,
      bubbleTail: bubbleTail ?? this.bubbleTail,
      reactionChipBackground:
          reactionChipBackground ?? this.reactionChipBackground,
      reactionChipText: reactionChipText ?? this.reactionChipText,
      presenceOnline: presenceOnline ?? this.presenceOnline,
      typingDot: typingDot ?? this.typingDot,
      dateSeparatorBackground:
          dateSeparatorBackground ?? this.dateSeparatorBackground,
      dateSeparatorText: dateSeparatorText ?? this.dateSeparatorText,
      replyAccent: replyAccent ?? this.replyAccent,
      readReceipt: readReceipt ?? this.readReceipt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatColors &&
        other.incomingBubble == incomingBubble &&
        other.outgoingBubble == outgoingBubble &&
        other.incomingText == incomingText &&
        other.outgoingText == outgoingText &&
        other.background == background &&
        other.composer == composer &&
        other.accent == accent &&
        other.bubbleTail == bubbleTail &&
        other.reactionChipBackground == reactionChipBackground &&
        other.reactionChipText == reactionChipText &&
        other.presenceOnline == presenceOnline &&
        other.typingDot == typingDot &&
        other.dateSeparatorBackground == dateSeparatorBackground &&
        other.dateSeparatorText == dateSeparatorText &&
        other.replyAccent == replyAccent &&
        other.readReceipt == readReceipt;
  }

  @override
  int get hashCode => Object.hashAll([
        incomingBubble,
        outgoingBubble,
        incomingText,
        outgoingText,
        background,
        composer,
        accent,
        bubbleTail,
        reactionChipBackground,
        reactionChipText,
        presenceOnline,
        typingDot,
        dateSeparatorBackground,
        dateSeparatorText,
        replyAccent,
        readReceipt,
      ]);
}
