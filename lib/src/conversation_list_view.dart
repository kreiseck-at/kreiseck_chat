import 'package:flutter/material.dart';

import 'chat_capabilities.dart';
import 'chat_participant.dart';
import 'chat_theme.dart';
import 'models.dart';

/// A conversation inbox list with avatars, presence dots, unread badges, and
/// typing previews.
class ConversationListView extends StatelessWidget {
  /// Creates a conversation list.
  const ConversationListView({
    super.key,
    required this.conversations,
    required this.onOpen,
    this.theme = const ChatTheme.light(),
    this.capabilities = const ChatCapabilities.inApp(),
    this.typingLabel = 'tippt…',
  });

  /// Conversations to display.
  final List<ChatConversation> conversations;

  /// Called when a conversation is tapped.
  final void Function(ChatConversation conversation) onOpen;

  /// Visual configuration.
  final ChatTheme theme;

  /// Which affordances are allowed.
  final ChatCapabilities capabilities;

  /// Preview label shown while the counterpart is typing.
  final String typingLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colors.background,
      child: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final c = conversations[index];
          return _ConversationTile(
            conversation: c,
            theme: theme,
            capabilities: capabilities,
            typingLabel: typingLabel,
            onTap: () => onOpen(c),
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
    required this.capabilities,
    required this.typingLabel,
    required this.onTap,
  });

  final ChatConversation conversation;
  final ChatTheme theme;
  final ChatCapabilities capabilities;
  final String typingLabel;
  final VoidCallback onTap;

  bool get _online =>
      capabilities.presence &&
      conversation.presence?.state == PresenceState.online;

  bool get _typing =>
      capabilities.typingIndicator && conversation.typing;

  @override
  Widget build(BuildContext context) {
    final provider = conversation.avatar ??
        (conversation.avatarUrl != null
            ? NetworkImage(conversation.avatarUrl!)
            : null);
    final preview = _typing ? typingLabel : (conversation.lastText ?? '');

    return ListTile(
      onTap: onTap,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colors.accent.withValues(alpha: 0.2),
            backgroundImage: provider,
            child: provider == null
                ? Text(
                    ChatParticipant(
                            id: conversation.id, displayName: conversation.title)
                        .initials,
                    style: TextStyle(color: theme.colors.accent),
                  )
                : null,
          ),
          if (_online)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: theme.colors.presenceOnline,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colors.background, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.headerTitle
                  .copyWith(color: theme.colors.incomingText),
            ),
          ),
          if (conversation.pinned)
            Icon(Icons.push_pin, size: 14, color: theme.colors.dateSeparatorText),
          if (conversation.muted)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.volume_off,
                  size: 14, color: theme.colors.dateSeparatorText),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          if (conversation.channelLabel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(conversation.channelLabel!,
                  style: theme.typography.timestamp
                      .copyWith(color: theme.colors.accent)),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.headerSubtitle.copyWith(
                color: _typing
                    ? theme.colors.accent
                    : theme.colors.incomingText.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
      trailing: conversation.unread > 0
          ? SizedBox(
              width: 34,
              height: 34,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colors.accent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${conversation.unread}',
                    style:
                        TextStyle(color: theme.colors.outgoingText, fontSize: 11),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
