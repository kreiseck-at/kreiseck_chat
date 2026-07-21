import 'package:flutter/material.dart';

import 'bubble_style.dart';
import 'chat_colors.dart';
import 'chat_icons.dart';
import 'chat_motion.dart';
import 'chat_typography.dart';

/// Visual configuration for the chat widgets, composed of independently
/// overridable sub-configs (colors, typography, icons, motion) plus a bubble
/// style preset. Everything has a default; override just what you need.
class ChatTheme {
  /// Creates a theme from sub-configs.
  const ChatTheme({
    this.colors = const ChatColors.light(),
    this.typography = const ChatTypography(),
    this.icons = const ChatIcons(),
    this.motion = const ChatMotion(),
    this.bubbleStyle = BubbleStyle.minimal,
    this.bubbleRadius = 16,
  });

  /// Color set.
  final ChatColors colors;

  /// Text styles.
  final ChatTypography typography;

  /// Icon set.
  final ChatIcons icons;

  /// Animation/haptic config.
  final ChatMotion motion;

  /// Bubble visual preset.
  final BubbleStyle bubbleStyle;

  /// Base corner radius for bubbles.
  final double bubbleRadius;

  /// Light preset (minimal bubbles).
  const factory ChatTheme.light() = ChatTheme._light;

  /// Dark preset (minimal bubbles).
  const factory ChatTheme.dark() = ChatTheme._dark;

  const ChatTheme._light()
      : colors = const ChatColors.light(),
        typography = const ChatTypography(),
        icons = const ChatIcons(),
        motion = const ChatMotion(),
        bubbleStyle = BubbleStyle.minimal,
        bubbleRadius = 16;

  const ChatTheme._dark()
      : colors = const ChatColors.dark(),
        typography = const ChatTypography(),
        icons = const ChatIcons(),
        motion = const ChatMotion(),
        bubbleStyle = BubbleStyle.minimal,
        bubbleRadius = 16;

  /// WhatsApp-flavored preset.
  factory ChatTheme.whatsApp({Brightness brightness = Brightness.light}) {
    final dark = brightness == Brightness.dark;
    final base = dark ? const ChatColors.dark() : const ChatColors.light();
    return ChatTheme(
      colors: base.copyWith(
        outgoingBubble: dark ? const Color(0xFF005C4B) : const Color(0xFFD9FDD3),
        outgoingText: dark ? const Color(0xFFE9EDEF) : const Color(0xFF111B21),
        bubbleTail: dark ? const Color(0xFF005C4B) : const Color(0xFFD9FDD3),
        accent: const Color(0xFF25D366),
        background: dark ? const Color(0xFF0B141A) : const Color(0xFFECE5DD),
      ),
      bubbleStyle: BubbleStyle.whatsApp,
      bubbleRadius: 12,
    );
  }

  /// iMessage-flavored preset.
  factory ChatTheme.iMessage({Brightness brightness = Brightness.light}) {
    final dark = brightness == Brightness.dark;
    final base = dark ? const ChatColors.dark() : const ChatColors.light();
    return ChatTheme(
      colors: base.copyWith(
        outgoingBubble: const Color(0xFF3478F6),
        bubbleTail: dark ? const Color(0xFF2C2C2E) : const Color(0xFFE9E9EB),
        accent: const Color(0xFF3478F6),
      ),
      bubbleStyle: BubbleStyle.iMessage,
      bubbleRadius: 18,
    );
  }

  /// Returns a copy with the given sub-configs replaced.
  ChatTheme copyWith({
    ChatColors? colors,
    ChatTypography? typography,
    ChatIcons? icons,
    ChatMotion? motion,
    BubbleStyle? bubbleStyle,
    double? bubbleRadius,
  }) {
    return ChatTheme(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      icons: icons ?? this.icons,
      motion: motion ?? this.motion,
      bubbleStyle: bubbleStyle ?? this.bubbleStyle,
      bubbleRadius: bubbleRadius ?? this.bubbleRadius,
    );
  }

  // --- Back-compat convenience getters (pre-0.3 flat API) ---

  /// Accent color (send button, read ticks).
  Color get accentColor => colors.accent;

  /// Thread/list background.
  Color get backgroundColor => colors.background;

  /// Composer bar color.
  Color get composerColor => colors.composer;

  /// Incoming bubble color.
  Color get incomingBubbleColor => colors.incomingBubble;

  /// Outgoing bubble color.
  Color get outgoingBubbleColor => colors.outgoingBubble;

  /// Incoming text color.
  Color get incomingTextColor => colors.incomingText;

  /// Outgoing text color.
  Color get outgoingTextColor => colors.outgoingText;
}
