import 'package:flutter/material.dart';

import 'chat_channel.dart';
import 'chat_theme.dart';

/// Badge showing which channel a message came through.
///
/// [compact] displays only the icon — intended for inline use in rows showing
/// multiple channels. Otherwise displays icon and label on a tinted background.
class ChatChannelBadge extends StatelessWidget {
  /// Creates a channel badge.
  const ChatChannelBadge({
    super.key,
    required this.channel,
    this.compact = false,
    this.theme = const ChatTheme.light(),
  });

  /// The channel being displayed.
  final ChatChannel channel;

  /// Icon only, no label or background.
  final bool compact;

  /// Visual configuration (radius, typography).
  final ChatTheme theme;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Icon(channel.icon, size: 12, color: channel.color),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: channel.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(channel.icon, size: 11, color: channel.color),
          const SizedBox(width: 3),
          Text(
            channel.label,
            style: theme.typography.timestamp.copyWith(
              color: channel.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
