import 'package:flutter/material.dart';

import 'chat_theme.dart';
import 'models.dart';

/// Renders a single [ChatMessage] as a chat bubble.
///
/// Incoming messages are aligned to the left, outgoing messages to the
/// right. Outgoing messages additionally show a small status indicator
/// reflecting [ChatMessage.status].
class MessageBubble extends StatelessWidget {
  /// Creates a message bubble for [message].
  const MessageBubble({
    super.key,
    required this.message,
    this.theme = const ChatTheme.light(),
  });

  /// The message to render.
  final ChatMessage message;

  /// Visual configuration; defaults to [ChatTheme.light].
  final ChatTheme theme;

  bool get _isOutgoing => message.direction == MessageDirection.outgoing;

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        _isOutgoing ? theme.outgoingBubbleColor : theme.incomingBubbleColor;
    final textColor =
        _isOutgoing ? theme.outgoingTextColor : theme.incomingTextColor;

    return Align(
      alignment: _isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(theme.bubbleRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.at),
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
                if (_isOutgoing) ...[
                  const SizedBox(width: 4),
                  _StatusIcon(
                    status: message.status,
                    color: textColor,
                    accentColor: theme.accentColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.status,
    required this.color,
    required this.accentColor,
  });

  final MessageStatus status;
  final Color color;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(
          Icons.access_time,
          size: 12,
          color: color.withValues(alpha: 0.7),
        );
      case MessageStatus.sent:
        return Icon(Icons.done, size: 14, color: color.withValues(alpha: 0.7));
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 14,
          color: color.withValues(alpha: 0.7),
        );
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 14, color: accentColor);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 14, color: Colors.red);
    }
  }
}

String _formatTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
