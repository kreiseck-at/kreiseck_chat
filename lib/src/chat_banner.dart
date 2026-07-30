import 'package:flutter/material.dart';

import 'bubble_ink.dart';
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
    final color = variant == ChatBannerVariant.warning
        ? theme.colors.warning
        : theme.colors.accent;
    // The tint above is only ever a faint (10%) wash of [color] over
    // [theme.colors.background] -- the icon and text painted on top still
    // need to be legible against that background, not against the raw brand
    // tone. [warningOnBackground] already exists for the warning tone; the
    // info variant's accent isn't guarded by a named getter of its own, so
    // it's derived here the same way.
    final onBackground = variant == ChatBannerVariant.warning
        ? theme.colors.warningOnBackground
        : readableOn(theme.colors.background, theme.colors.accent);
    return DecoratedBox(
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: onBackground),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(text,
                  style:
                      theme.typography.systemMessage.copyWith(color: onBackground)),
            ),
          ],
        ),
      ),
    );
  }
}
