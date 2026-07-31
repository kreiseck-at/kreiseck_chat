import 'package:flutter/material.dart';

import 'chat_avatar.dart';
import 'chat_capabilities.dart';
import 'chat_channel_badge.dart';
import 'chat_participant.dart';
import 'chat_strings.dart';
import 'chat_theme.dart';
import 'models.dart';

/// How an unread conversation is marked in the list.
enum UnreadStyle {
  /// A circle with the number of unread messages.
  count,

  /// A small dot — for hosts whose unread state is a yes/no, where a "1"
  /// would only ever be a "1".
  dot,
}

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
    this.typingLabel,
    this.channelBadge,
    this.onLongPress,
    this.titleBadgeBuilder,
    this.strings,
    this.timeLabelBuilder,
    this.unreadStyle = UnreadStyle.count,
  });

  /// Conversations to display.
  final List<ChatConversation> conversations;

  /// Called when a conversation is tapped.
  final void Function(ChatConversation conversation) onOpen;

  /// Visual configuration.
  final ChatTheme theme;

  /// Which affordances are allowed.
  final ChatCapabilities capabilities;

  /// Preview label shown while the counterpart is typing. Left null, it
  /// follows [ChatStrings.typing] for the ambient locale (see [strings]).
  final String? typingLabel;

  /// Optional small badge overlaid on the bottom-right of each avatar (e.g. a
  /// channel marker). When provided, the textual channel label is hidden.
  ///
  /// Also takes precedence over the compact channel-badge row built from
  /// [ChatConversation.channels].
  final Widget? Function(ChatConversation conversation)? channelBadge;

  /// Called on a long press of a conversation row, e.g. to open an action
  /// sheet. When null, rows only respond to taps, unchanged from before.
  final void Function(ChatConversation conversation)? onLongPress;

  /// Builds an optional badge shown right before the title, e.g. a spam
  /// marker.
  final Widget? Function(ChatConversation conversation)? titleBadgeBuilder;

  /// Overrides the words used by this list. Left null, they follow the
  /// ambient locale (see [ChatStrings.of]).
  final ChatStrings? strings;

  /// Builds the time shown at the end of a row, e.g. `'14:30'` or
  /// `'3. Feb'`. Left null, no time is shown — date formatting is the host's
  /// business, and this package brings no date library of its own.
  final String? Function(ChatConversation conversation)? timeLabelBuilder;

  /// Whether an unread conversation shows a count or a plain dot.
  final UnreadStyle unreadStyle;

  @override
  Widget build(BuildContext context) {
    final resolved = ChatStrings.of(context, override: strings);
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
            typingLabel: typingLabel ?? resolved.typing,
            badge: channelBadge?.call(c),
            titleBadge: titleBadgeBuilder?.call(c),
            timeLabel: timeLabelBuilder?.call(c),
            unreadStyle: unreadStyle,
            onTap: () => onOpen(c),
            onLongPress:
                onLongPress == null ? null : () => onLongPress!(c),
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
    required this.badge,
    required this.titleBadge,
    required this.timeLabel,
    required this.unreadStyle,
    required this.onTap,
    required this.onLongPress,
  });

  final ChatConversation conversation;
  final ChatTheme theme;
  final ChatCapabilities capabilities;
  final String typingLabel;
  final Widget? badge;
  final Widget? titleBadge;
  final String? timeLabel;
  final UnreadStyle unreadStyle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  bool get _online =>
      capabilities.presence &&
      conversation.presence?.state == PresenceState.online;

  bool get _typing =>
      capabilities.typingIndicator && conversation.typing;

  /// Time and unread marker at the end of the row. Null when there is
  /// neither — the row then ends after the preview, as before.
  Widget? _trailing() {
    final ungelesen = conversation.unread > 0;
    if (timeLabel == null && !ungelesen) return null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (timeLabel != null)
          Text(timeLabel!,
              style: theme.typography.timestamp
                  .copyWith(color: theme.colors.dateSeparatorText)),
        if (ungelesen) ...[
          if (timeLabel != null) const SizedBox(height: 4),
          if (unreadStyle == UnreadStyle.dot)
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                  color: theme.colors.accent, shape: BoxShape.circle),
            )
          else
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colors.accent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${conversation.unread}',
                style:
                    TextStyle(color: theme.colors.outgoingText, fontSize: 11),
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _typing ? typingLabel : (conversation.lastText ?? '');

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          ChatAvatar(
            name: conversation.title,
            theme: theme,
            image: conversation.avatar,
            avatarUrl: conversation.avatarUrl,
            radius: 24,
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
            )
          else if (badge != null)
            Positioned(right: -2, bottom: -2, child: badge!),
        ],
      ),
      title: Row(
        children: [
          if (titleBadge != null) ...[
            titleBadge!,
            const SizedBox(width: 6),
          ],
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
          if (badge == null && conversation.channels.isNotEmpty) ...[
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: conversation.channels
                    .map((c) => ChatChannelBadge(
                          channel: c,
                          compact: true,
                          theme: theme,
                          surface: theme.colors.background,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(width: 2),
          ] else if (badge == null && conversation.channelLabel != null) ...[
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
      trailing: _trailing(),
    );
  }
}
