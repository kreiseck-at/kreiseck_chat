import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bubble_style.dart';
import 'bubble_tail_painter.dart';
import 'chat_attachment.dart';
import 'chat_capabilities.dart';
import 'chat_reaction.dart';
import 'chat_theme.dart';
import 'models.dart';

/// Renders a single [ChatMessage] as a chat bubble, honoring the theme's
/// [BubbleStyle], the [ChatCapabilities], and grouping flags.
class MessageBubble extends StatelessWidget {
  /// Creates a message bubble.
  const MessageBubble({
    super.key,
    required this.message,
    this.theme = const ChatTheme.light(),
    this.capabilities = const ChatCapabilities.inApp(),
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.animateIn = false,
    this.onReplyRequested,
    this.onReact,
    this.onOpenAttachment,
  });

  /// The message to render.
  final ChatMessage message;

  /// Visual configuration.
  final ChatTheme theme;

  /// Which affordances are allowed.
  final ChatCapabilities capabilities;

  /// First message of its group; adds top spacing to separate groups.
  final bool isFirstInGroup;

  /// Last message of its group (shows tail + timestamp).
  final bool isLastInGroup;

  /// Whether to run the entrance animation (also gated by motion config).
  final bool animateIn;

  /// Called when the user requests to reply to this message.
  final void Function()? onReplyRequested;

  /// Called with an emoji when the user reacts.
  final void Function(String emoji)? onReact;

  /// Called when the user taps an attachment.
  final void Function(ChatAttachment attachment)? onOpenAttachment;

  bool get _isOutgoing => message.direction == MessageDirection.outgoing;

  MessageStatus get _effectiveStatus {
    if (!capabilities.readReceipts && message.status == MessageStatus.read) {
      return MessageStatus.delivered;
    }
    return message.status;
  }

  void _openActions(BuildContext context) {
    if (theme.motion.hapticsEnabled && theme.motion.hapticOnLongPress) {
      HapticFeedback.mediumImpact();
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              if (capabilities.reactions)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: ['👍', '❤️', '😂', '😮', '😢']
                        .map((e) => Expanded(
                              child: IconButton(
                                icon: Text(e, style: const TextStyle(fontSize: 24)),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  if (theme.motion.hapticsEnabled &&
                                      theme.motion.hapticOnReaction) {
                                    HapticFeedback.selectionClick();
                                  }
                                  onReact?.call(e);
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),
              if (capabilities.replies)
                ListTile(
                  leading: Icon(theme.icons.reply),
                  title: const Text('Antworten'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onReplyRequested?.call();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    final bubbleColor =
        _isOutgoing ? colors.outgoingBubble : colors.incomingBubble;
    final textColor = _isOutgoing ? colors.outgoingText : colors.incomingText;

    Widget bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: _borderRadius(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.replyTo != null && capabilities.replies)
            _ReplyQuote(refText: message.replyTo!, theme: theme),
          if (capabilities.media && message.attachments.isNotEmpty)
            _Attachments(
              attachments: message.attachments,
              onOpen: onOpenAttachment,
            ),
          if (message.text.isNotEmpty)
            Text(message.text, style: theme.typography.body.copyWith(color: textColor)),
          const SizedBox(height: 4),
          _MetaRow(
            time: _formatTime(message.at),
            isOutgoing: _isOutgoing,
            showStatus: _isOutgoing && isLastInGroup,
            status: _effectiveStatus,
            theme: theme,
            textColor: textColor,
          ),
        ],
      ),
    );

    final showTail = theme.bubbleStyle != BubbleStyle.minimal && isLastInGroup;
    if (showTail) {
      bubble = Stack(
        clipBehavior: Clip.none,
        children: [
          bubble,
          Positioned(
            bottom: 0,
            left: _isOutgoing ? null : -6,
            right: _isOutgoing ? -6 : null,
            child: CustomPaint(
              size: const Size(10, 12),
              painter: BubbleTailPainter(color: bubbleColor, isOutgoing: _isOutgoing),
            ),
          ),
        ],
      );
    }

    Widget content = Column(
      crossAxisAlignment:
          _isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        bubble,
        if (capabilities.reactions && message.reactions.isNotEmpty)
          _Reactions(reactions: message.reactions, theme: theme),
      ],
    );

    content = GestureDetector(
      onLongPress: (capabilities.reactions || capabilities.replies)
          ? () => _openActions(context)
          : null,
      onHorizontalDragEnd: capabilities.replies
          ? (details) {
              final v = details.primaryVelocity ?? 0;
              if ((_isOutgoing && v < -200) || (!_isOutgoing && v > 200)) {
                onReplyRequested?.call();
              }
            }
          : null,
      child: content,
    );

    final aligned = Align(
      alignment: _isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: isFirstInGroup ? 6 : 2,
          bottom: 2,
        ),
        child: content,
      ),
    );

    if (animateIn && theme.motion.bubbleEntrance) {
      return _EntranceAnimation(
        duration: theme.motion.bubbleEntranceDuration,
        curve: theme.motion.entranceCurve,
        isOutgoing: _isOutgoing,
        child: aligned,
      );
    }
    return aligned;
  }

  BorderRadius _borderRadius() {
    final r = theme.bubbleRadius;
    if (theme.bubbleStyle == BubbleStyle.minimal) {
      return BorderRadius.circular(r);
    }
    const small = Radius.circular(5);
    final big = Radius.circular(r);
    // Tighten the corner nearest the tail when it is the last in the group.
    if (_isOutgoing) {
      return BorderRadius.only(
        topLeft: big,
        topRight: big,
        bottomLeft: big,
        bottomRight: isLastInGroup ? small : big,
      );
    }
    return BorderRadius.only(
      topLeft: big,
      topRight: big,
      bottomLeft: isLastInGroup ? small : big,
      bottomRight: big,
    );
  }
}

class _EntranceAnimation extends StatefulWidget {
  const _EntranceAnimation({
    required this.child,
    required this.duration,
    required this.curve,
    required this.isOutgoing,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool isOutgoing;

  @override
  State<_EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<_EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: widget.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(widget.isOutgoing ? 0.15 : -0.15, 0.1),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}

class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({required this.refText, required this.theme});

  final ChatMessageRef refText;
  final ChatTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colors.replyAccent, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (refText.senderLabel != null)
            Text(refText.senderLabel!,
                style: theme.typography.senderName
                    .copyWith(color: theme.colors.replyAccent)),
          Text(refText.snippet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.replyQuote),
        ],
      ),
    );
  }
}

class _Attachments extends StatelessWidget {
  const _Attachments({required this.attachments, required this.onOpen});

  final List<ChatAttachment> attachments;
  final void Function(ChatAttachment)? onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: attachments.map((a) {
        final provider = a.thumbnail ??
            (a.thumbnailUrl != null ? NetworkImage(a.thumbnailUrl!) : null);
        final isImage = a.kind == AttachmentKind.image && provider != null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GestureDetector(
            onTap: onOpen == null ? null : () => onOpen!(a),
            child: isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image(
                      image: provider,
                      width: 200,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, size: 20),
                      const SizedBox(width: 6),
                      Text(a.fileName ?? 'Datei'),
                    ],
                  ),
          ),
        );
      }).toList(),
    );
  }
}

class _Reactions extends StatelessWidget {
  const _Reactions({required this.reactions, required this.theme});

  final List<MessageReaction> reactions;
  final ChatTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: 4,
        children: reactions.map((r) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colors.reactionChipBackground,
              borderRadius: BorderRadius.circular(12),
              border: r.reactedByMe
                  ? Border.all(color: theme.colors.accent, width: 1)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  r.emoji,
                  style: theme.typography.timestamp
                      .copyWith(color: theme.colors.reactionChipText),
                ),
                if (r.count > 1) ...[
                  const SizedBox(width: 2),
                  Text(
                    '${r.count}',
                    style: theme.typography.timestamp
                        .copyWith(color: theme.colors.reactionChipText),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.time,
    required this.isOutgoing,
    required this.showStatus,
    required this.status,
    required this.theme,
    required this.textColor,
  });

  final String time;
  final bool isOutgoing;
  final bool showStatus;
  final MessageStatus status;
  final ChatTheme theme;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          time,
          style: theme.typography.timestamp
              .copyWith(color: textColor.withValues(alpha: 0.7)),
        ),
        if (showStatus) ...[
          const SizedBox(width: 4),
          _StatusIcon(status: status, color: textColor, theme: theme),
        ],
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.status,
    required this.color,
    required this.theme,
  });

  final MessageStatus status;
  final Color color;
  final ChatTheme theme;

  @override
  Widget build(BuildContext context) {
    final icons = theme.icons;
    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: 12, color: color.withValues(alpha: 0.7));
      case MessageStatus.sent:
        return Icon(icons.sent, size: 14, color: color.withValues(alpha: 0.7));
      case MessageStatus.delivered:
        return Icon(icons.delivered, size: 14, color: color.withValues(alpha: 0.7));
      case MessageStatus.read:
        return Icon(icons.read, size: 14, color: theme.colors.accent);
      case MessageStatus.failed:
        return Icon(icons.error, size: 14, color: Colors.red);
    }
  }
}

String _formatTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
