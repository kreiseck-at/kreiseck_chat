import 'package:flutter/material.dart';

import 'chat_theme.dart';

/// Visual configuration for the mail widgets in this package.
///
/// Widgets never hard-code colors; every color used comes from an instance
/// of this class so that hosting apps can support light/dark mode and their
/// own branding by supplying a custom [MailTheme].
class MailTheme {
  /// Creates a mail theme from explicit values.
  const MailTheme({
    required this.background,
    required this.surfaceColor,
    required this.textColor,
    required this.unreadDot,
    required this.accentColor,
  });

  /// Background color of the mail surface (list/detail views).
  final Color background;

  /// Background color of surfaces such as the composer bar.
  final Color surfaceColor;

  /// Primary text color.
  final Color textColor;

  /// Color of the unread indicator dot.
  final Color unreadDot;

  /// Accent color, e.g. for the send/reply button.
  final Color accentColor;

  /// Derives the mail colors from a [ChatTheme], so a host that already
  /// styled its chat gets a matching mail view without configuring anything
  /// twice.
  factory MailTheme.fromChat(ChatTheme chat) => MailTheme(
        background: chat.colors.background,
        surfaceColor: chat.colors.composer,
        textColor: chat.colors.incomingText,
        unreadDot: chat.colors.accent,
        accentColor: chat.colors.accent,
      );

  /// A light color scheme suitable as a sensible default.
  const factory MailTheme.light() = MailTheme._light;

  /// A dark color scheme suitable as a sensible default.
  const factory MailTheme.dark() = MailTheme._dark;

  const MailTheme._light()
      : background = const Color(0xFFFAFAFA),
        surfaceColor = const Color(0xFFFFFFFF),
        textColor = const Color(0xFF1C1C1E),
        unreadDot = const Color(0xFF3478F6),
        accentColor = const Color(0xFF3478F6);

  const MailTheme._dark()
      : background = const Color(0xFF000000),
        surfaceColor = const Color(0xFF1C1C1E),
        textColor = const Color(0xFFF2F2F7),
        unreadDot = const Color(0xFF64A1FF),
        accentColor = const Color(0xFF64A1FF);
}
