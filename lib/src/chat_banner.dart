import 'package:flutter/material.dart';

import 'chat_theme.dart';

/// Tone of a [ChatBanner] bar.
enum ChatBannerVariant {
  /// Factual notice.
  info,

  /// Warning — something is restricted.
  warning,
}

/// Notice bar above the composer field.
///
/// Intended for states affecting the reply: restricted channel,
/// disconnected connection, locked thread. Use via
/// `ChatThreadView.composerBanner`.
class ChatBanner extends StatelessWidget {
  /// Creates a notice bar.
  const ChatBanner({
    super.key,
    required this.text,
    this.icon,
    this.variant = ChatBannerVariant.info,
    this.theme = const ChatTheme.light(),
  });

  /// Notice text.
  final String text;

  /// Optional icon on the left.
  final IconData? icon;

  /// Tone — determines the color.
  final ChatBannerVariant variant;

  /// Visual configuration.
  final ChatTheme theme;

  @override
  Widget build(BuildContext context) {
    final farbe = variant == ChatBannerVariant.warning
        ? theme.colors.warning
        : theme.colors.accent;
    return DecoratedBox(
      decoration: BoxDecoration(color: farbe.withValues(alpha: 0.10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: farbe),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(text, style: theme.typography.systemMessage),
            ),
          ],
        ),
      ),
    );
  }
}
