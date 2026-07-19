import 'package:flutter/material.dart';

/// Visual configuration for the chat widgets in this package.
///
/// Widgets never hard-code colors; every color used comes from an instance
/// of this class so that hosting apps can support light/dark mode and their
/// own branding by supplying a custom [ChatTheme].
class ChatTheme {
  /// Creates a chat theme from explicit values.
  const ChatTheme({
    required this.incomingBubbleColor,
    required this.outgoingBubbleColor,
    required this.incomingTextColor,
    required this.outgoingTextColor,
    required this.bubbleRadius,
    required this.backgroundColor,
    required this.composerColor,
    required this.accentColor,
  });

  /// Background color of bubbles for incoming messages.
  final Color incomingBubbleColor;

  /// Background color of bubbles for outgoing messages.
  final Color outgoingBubbleColor;

  /// Text color used inside incoming message bubbles.
  final Color incomingTextColor;

  /// Text color used inside outgoing message bubbles.
  final Color outgoingTextColor;

  /// Corner radius applied to message bubbles.
  final double bubbleRadius;

  /// Background color of the chat surface (thread/list views).
  final Color backgroundColor;

  /// Background color of the message composer bar.
  final Color composerColor;

  /// Accent color, e.g. for the send button and read receipts.
  final Color accentColor;

  /// A light color scheme suitable as a sensible default.
  const factory ChatTheme.light() = ChatTheme._light;

  /// A dark color scheme suitable as a sensible default.
  const factory ChatTheme.dark() = ChatTheme._dark;

  const ChatTheme._light()
      : incomingBubbleColor = const Color(0xFFE9E9EB),
        outgoingBubbleColor = const Color(0xFF3478F6),
        incomingTextColor = const Color(0xFF1C1C1E),
        outgoingTextColor = const Color(0xFFFFFFFF),
        bubbleRadius = 16,
        backgroundColor = const Color(0xFFFAFAFA),
        composerColor = const Color(0xFFFFFFFF),
        accentColor = const Color(0xFF3478F6);

  const ChatTheme._dark()
      : incomingBubbleColor = const Color(0xFF2C2C2E),
        outgoingBubbleColor = const Color(0xFF3478F6),
        incomingTextColor = const Color(0xFFF2F2F7),
        outgoingTextColor = const Color(0xFFFFFFFF),
        bubbleRadius = 16,
        backgroundColor = const Color(0xFF000000),
        composerColor = const Color(0xFF1C1C1E),
        accentColor = const Color(0xFF64A1FF);
}
