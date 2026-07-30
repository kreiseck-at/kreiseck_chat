import 'package:flutter/material.dart';

import 'bubble_ink.dart';
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
    this.surface,
  });

  /// The channel being displayed.
  final ChatChannel channel;

  /// Icon only, no label or background.
  final bool compact;

  /// Visual configuration (typography).
  final ChatTheme theme;

  /// The surface this badge's compact icon is painted directly onto — e.g.
  /// the fill of the bubble it sits in. When set, [channel]'s brand color is
  /// derived via [readableOn] to keep the icon at least 3:1 against it.
  ///
  /// Leave `null` for free-standing use (e.g. a channel strip in a
  /// conversation list row) where no single surface is known — the raw
  /// brand tone is used as-is in that case.
  final Color? surface;

  /// The icon color actually painted: [channel.color] lifted for contrast
  /// against [surface] when one was given, otherwise the raw brand tone.
  Color get _iconColor {
    final onto = surface;
    return onto == null ? channel.color : readableOn(onto, channel.color, target: 3.0);
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Icon(channel.icon, size: 15, color: _iconColor),
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
          Flexible(
            child: Text(
              channel.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.timestamp.copyWith(
                color: channel.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
