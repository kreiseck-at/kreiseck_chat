import 'package:flutter/material.dart';

import 'chat_theme.dart';

/// Centered card in the thread for non-message content: system notes, logged
/// events, summaries.
///
/// Messages with [ChatMessageKind.system] are rendered by [ChatThreadView]
/// automatically with this card; the card can also be used directly for
/// custom content.
class ChatSystemCard extends StatelessWidget {
  /// Creates a system card.
  const ChatSystemCard({
    super.key,
    required this.child,
    this.icon,
    this.onTap,
    this.theme = const ChatTheme.light(),
  });

  /// The card content.
  final Widget child;

  /// Optional icon to the left of the content.
  final IconData? icon;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Visual configuration.
  final ChatTheme theme;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colors.dateSeparatorBackground,
        borderRadius: BorderRadius.circular(theme.bubbleRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: theme.colors.dateSeparatorText),
            const SizedBox(width: 8),
          ],
          Flexible(child: child),
        ],
      ),
    );
    if (onTap == null) return Center(child: content);
    return Center(
      child: GestureDetector(onTap: onTap, child: content),
    );
  }
}
