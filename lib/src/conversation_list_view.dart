import 'package:flutter/material.dart';

import 'chat_theme.dart';
import 'models.dart';

/// Renders a list of [ChatConversation]s, e.g. an inbox overview.
///
/// Each row shows the conversation title (bold), a subtitle/preview line
/// (muted), the timestamp of the last message and an unread badge when
/// [ChatConversation.unread] is greater than zero.
class ConversationListView extends StatelessWidget {
  /// Creates a conversation list view.
  const ConversationListView({
    super.key,
    required this.conversations,
    required this.onOpen,
    this.theme = const ChatTheme.light(),
  });

  /// Conversations to display.
  final List<ChatConversation> conversations;

  /// Called with the tapped conversation.
  final ValueChanged<ChatConversation> onOpen;

  /// Visual configuration; defaults to [ChatTheme.light].
  final ChatTheme theme;

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return Material(
        color: theme.backgroundColor,
        child: Center(
          child: Text(
            'No conversations yet',
            style: TextStyle(
              color: theme.incomingTextColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return Material(
      color: theme.backgroundColor,
      child: ListView.separated(
        itemCount: conversations.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: theme.incomingTextColor.withValues(alpha: 0.08),
        ),
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _ConversationTile(
            conversation: conversation,
            theme: theme,
            onTap: () => onOpen(conversation),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.theme,
    required this.onTap,
  });

  final ChatConversation conversation;
  final ChatTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mutedColor = theme.incomingTextColor.withValues(alpha: 0.6);
    final preview = conversation.lastText ?? conversation.subtitle;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.incomingTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (preview != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      style: TextStyle(color: mutedColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (conversation.lastAt != null)
                  Text(
                    _formatTime(conversation.lastAt!),
                    style: TextStyle(color: mutedColor, fontSize: 12),
                  ),
                const SizedBox(height: 6),
                if (conversation.unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${conversation.unread}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
