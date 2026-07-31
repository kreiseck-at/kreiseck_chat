import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bubble_ink.dart';
import 'bubble_style.dart';
import 'bubble_tail_painter.dart';
import 'chat_attachment.dart';
import 'chat_capabilities.dart';
import 'chat_channel.dart';
import 'chat_channel_badge.dart';
import 'chat_reaction.dart';
import 'chat_theme.dart';
import 'models.dart';

/// Renders a single [ChatMessage] as a chat bubble, honoring the theme's
/// [BubbleStyle], the [ChatCapabilities], and grouping flags.
///
/// Tapping the message text toggles between the original and its
/// [ChatMessage.translation], when one is set.
class MessageBubble extends StatefulWidget {
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
    this.onOpenImages,
    this.onCopy,
    this.onRetry,
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

  /// Called when the user taps a non-image attachment (e.g. a file).
  final void Function(ChatAttachment attachment)? onOpenAttachment;

  /// Called when the user taps an image in the album, with the message's full
  /// list of image attachments and the tapped index — so the host can open a
  /// swipeable full-screen gallery.
  final void Function(List<ChatAttachment> images, int index)? onOpenImages;

  /// Called after the message text was copied to the clipboard (e.g. to show
  /// a confirmation). Copy itself is handled internally.
  final VoidCallback? onCopy;

  /// Called when the user taps the retry action on a failed message. Null
  /// hides the action, leaving only the failure reason.
  final VoidCallback? onRetry;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  /// Shows the translation instead of the original text.
  bool _showTranslation = false;

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A widget of this type can be reused for a different message (e.g. an
    // unkeyed ListView.builder recycling list items) — reset the toggle so a
    // stale translation state doesn't leak onto the new message.
    if (oldWidget.message.id != widget.message.id) {
      _showTranslation = false;
    }
  }

  bool get _isOutgoing => widget.message.direction == MessageDirection.outgoing;

  MessageStatus get _effectiveStatus {
    if (!widget.capabilities.readReceipts &&
        widget.message.status == MessageStatus.read) {
      return MessageStatus.delivered;
    }
    return widget.message.status;
  }

  /// The text currently shown: the translation while toggled on, the
  /// original otherwise.
  String get _displayText {
    final t = widget.message.translation;
    if (t != null && _showTranslation) return t.text;
    return widget.message.text;
  }

  /// Opens a context menu anchored at the long-press position (not a bottom
  /// sheet), like a native message dropdown.
  Future<void> _openActions(BuildContext context, Offset globalPosition) async {
    if (widget.theme.motion.hapticsEnabled &&
        widget.theme.motion.hapticOnLongPress) {
      HapticFeedback.mediumImpact();
    }
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );
    final menuColor = widget.theme.colors.incomingText;
    final selected = await showMenu<String>(
      context: context,
      position: position,
      color: widget.theme.colors.composer,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: [
        if (widget.capabilities.reactions)
          PopupMenuItem<String>(
            enabled: false,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: ['👍', '❤️', '😂', '😮', '😢']
                  .map((e) => IconButton(
                        icon: Text(e, style: const TextStyle(fontSize: 22)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (widget.theme.motion.hapticsEnabled &&
                              widget.theme.motion.hapticOnReaction) {
                            HapticFeedback.selectionClick();
                          }
                          widget.onReact?.call(e);
                        },
                      ))
                  .toList(),
            ),
          ),
        if (widget.capabilities.replies)
          PopupMenuItem<String>(
            value: 'reply',
            child: _menuRow(widget.theme.icons.reply, 'Antworten', menuColor),
          ),
        if (widget.message.text.isNotEmpty)
          PopupMenuItem<String>(
            value: 'copy',
            child: _menuRow(widget.theme.icons.copy, 'Kopieren', menuColor),
          ),
      ],
    );
    if (selected == 'reply') {
      widget.onReplyRequested?.call();
    } else if (selected == 'copy') {
      Clipboard.setData(ClipboardData(text: widget.message.text));
      widget.onCopy?.call();
    }
  }

  Widget _menuRow(IconData icon, String label, Color color) {
    return Row(children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(color: color)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final message = widget.message;
    final capabilities = widget.capabilities;
    final colors = theme.colors;
    final bubbleColor =
        _isOutgoing ? colors.outgoingBubble : colors.incomingBubble;
    final textColor = _isOutgoing ? colors.outgoingText : colors.incomingText;
    final ink = colors.inkFor(bubbleColor, isOutgoing: _isOutgoing);

    final hasMedia = capabilities.media && message.attachments.isNotEmpty;
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;

    Widget bubble = Container(
      // Bei Fotos ein sehr knapper Rahmen -- das Bild soll die Bubble fast füllen.
      padding: hasMedia
          ? const EdgeInsets.all(3)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: _borderRadius(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.replyTo != null && capabilities.replies)
            Padding(
              padding: hasMedia
                  ? const EdgeInsets.fromLTRB(8, 6, 8, 0)
                  : EdgeInsets.zero,
              child: _ReplyQuote(refText: message.replyTo!, theme: theme, ink: ink),
            ),
          if (hasMedia)
            ClipRRect(
              borderRadius: BorderRadius.circular((theme.bubbleRadius - 3).clamp(0, theme.bubbleRadius)),
              child: _Album(
                attachments: message.attachments,
                onOpen: widget.onOpenAttachment,
                onOpenImages: widget.onOpenImages,
                theme: theme,
              ),
            ),
          if ((message.headline ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message.headline!,
                style: theme.typography.body.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (message.text.isNotEmpty)
            Padding(
              padding: hasMedia
                  ? const EdgeInsets.fromLTRB(8, 6, 8, 0)
                  : EdgeInsets.zero,
              child: message.translation == null
                  ? Text(_displayText,
                      style: theme.typography.body.copyWith(color: textColor))
                  : GestureDetector(
                      onTap: () => setState(
                          () => _showTranslation = !_showTranslation),
                      child: Text(_displayText,
                          style: theme.typography.body
                              .copyWith(color: textColor)),
                    ),
            ),
          Padding(
            padding: hasMedia
                ? const EdgeInsets.fromLTRB(8, 3, 6, 3)
                : const EdgeInsets.only(top: 4),
            child: _MetaRow(
              time: _formatTime(message.at),
              isOutgoing: _isOutgoing,
              showStatus: _isOutgoing,
              status: _effectiveStatus,
              theme: theme,
              ink: ink,
              bubbleColor: bubbleColor,
              channel: message.channel,
            ),
          ),
          // The translated-language / "Original" label only makes sense next
          // to the text it toggles — hidden along with it when there is no
          // text to show (e.g. a media-only message).
          if (message.translation != null && message.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _showTranslation
                    ? message.translation!.languageLabel
                    : 'Original',
                style: theme.typography.timestamp.copyWith(color: ink.muted),
              ),
            ),
        ],
      ),
    );

    final showTail = theme.showBubbleTail && widget.isLastInGroup;
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
        // Rendered below the bubble, not inside it: the bubble's fill color
        // is themed for the message text, not for an error color — placing
        // it inside risked low-contrast text (e.g. red error on a blue
        // outgoing bubble).
        if ((message.errorText ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 14, color: theme.colors.errorOnBackground),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    message.errorText!,
                    // Truncated rather than wrapped without limit: an
                    // unbreakable long word (or just a long reason on a
                    // narrow screen) must not be able to force this row
                    // wider than the retry action below, which needs to
                    // keep its own size regardless of how long the reason
                    // gets.
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.timestamp.copyWith(
                      fontSize: (theme.typography.timestamp.fontSize ?? 11) + 1,
                      color: theme.colors.errorOnBackground,
                    ),
                  ),
                ),
                if (widget.onRetry != null) ...[
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: widget.onRetry,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      // Kept visually as a plain text link (no chip, no
                      // border), but the tappable box itself is floored to
                      // the commonly recommended 44x44 minimum touch target.
                      // shrinkWrap avoids adding Material's own 48dp platform
                      // margin on top of that floor.
                      minimumSize: const Size(44, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Erneut senden',
                      style: theme.typography.timestamp.copyWith(
                        fontSize: (theme.typography.timestamp.fontSize ?? 11) + 1,
                        color: theme.colors.errorOnBackground,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (capabilities.reactions && message.reactions.isNotEmpty)
          _Reactions(reactions: message.reactions, theme: theme),
      ],
    );

    final canAct =
        capabilities.reactions || capabilities.replies || message.text.isNotEmpty;
    content = GestureDetector(
      onLongPressStart:
          canAct ? (details) => _openActions(context, details.globalPosition) : null,
      onHorizontalDragEnd: capabilities.replies
          ? (details) {
              final v = details.primaryVelocity ?? 0;
              if ((_isOutgoing && v < -200) || (!_isOutgoing && v > 200)) {
                widget.onReplyRequested?.call();
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
          top: widget.isFirstInGroup ? 6 : 2,
          bottom: 2,
        ),
        child: content,
      ),
    );

    if (widget.animateIn && theme.motion.bubbleEntrance) {
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
    final theme = widget.theme;
    final r = theme.bubbleRadius;
    if (theme.bubbleStyle == BubbleStyle.minimal) {
      return BorderRadius.circular(r);
    }
    const small = Radius.circular(5);
    final big = Radius.circular(r);
    // Tighten the corner nearest the tail when it is the last in the group --
    // but only when a tail is actually painted there (see showBubbleTail):
    // with no tail, tightening the corner would leave a stray asymmetric
    // corner with nothing to justify it.
    final tightenCorner = theme.showBubbleTail && widget.isLastInGroup;
    if (_isOutgoing) {
      return BorderRadius.only(
        topLeft: big,
        topRight: big,
        bottomLeft: big,
        bottomRight: tightenCorner ? small : big,
      );
    }
    return BorderRadius.only(
      topLeft: big,
      topRight: big,
      bottomLeft: tightenCorner ? small : big,
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
  const _ReplyQuote({required this.refText, required this.theme, required this.ink});

  final ChatMessageRef refText;
  final ChatTheme theme;

  /// Colors of the bubble this quote is drawn on -- not derived from
  /// [theme.colors] directly, so the quote stays legible regardless of which
  /// bubble (incoming/outgoing, or a custom host color) it lands on.
  final BubbleInk ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: ink.line, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (refText.senderLabel != null)
            Text(refText.senderLabel!,
                style: theme.typography.senderName.copyWith(color: ink.text)),
          Text(refText.snippet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.replyQuote.copyWith(color: ink.muted)),
        ],
      ),
    );
  }
}

/// Renders a message's attachments as a WhatsApp-style album: a single large
/// image, or a 2-column grid for multiple, with a "+N" overlay past four.
/// Non-image attachments fall back to a file row.
class _Album extends StatelessWidget {
  const _Album({
    required this.attachments,
    required this.onOpen,
    required this.onOpenImages,
    required this.theme,
  });

  final List<ChatAttachment> attachments;
  final void Function(ChatAttachment)? onOpen;
  final void Function(List<ChatAttachment> images, int index)? onOpenImages;
  final ChatTheme theme;

  static const double _gap = 2;

  ImageProvider? _providerFor(ChatAttachment a) =>
      a.thumbnail ??
      (a.thumbnailUrl != null
          ? NetworkImage(a.thumbnailUrl!)
          : (a.url != null ? NetworkImage(a.url!) : null));

  @override
  Widget build(BuildContext context) {
    final images = attachments
        .where((a) => a.kind == AttachmentKind.image && _providerFor(a) != null)
        .toList();

    if (images.isEmpty) {
      // File/other attachments: simple rows.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: attachments
            .map((a) => Padding(
                  padding: const EdgeInsets.all(6),
                  child: GestureDetector(
                    onTap: onOpen == null ? null : () => onOpen!(a),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.insert_drive_file_outlined, size: 20),
                      const SizedBox(width: 6),
                      Flexible(child: Text(a.fileName ?? 'Datei')),
                    ]),
                  ),
                ))
            .toList(),
      );
    }

    void open(int index) => onOpenImages?.call(images, index);

    // Ein Bild: breit über die Bubble, leicht liegendes Format.
    if (images.length == 1) {
      return AspectRatio(
          aspectRatio: 1.6, child: _tile(images.first, onTap: () => open(0)));
    }

    // Mehrere: 2-Spalten-Grid quadratischer Kacheln (Expanded -> passt sich der
    // echten Bubble-Breite an, kein Overflow); ab dem 5. Bild "+N" auf der 4.
    final show = images.length > 4 ? 4 : images.length;
    final plusMore = images.length > 4 ? images.length - 4 : 0;
    final rows = <Widget>[];
    for (var i = 0; i < show; i += 2) {
      final hasRight = i + 1 < show;
      final li = i;
      final ri = i + 1;
      rows.add(Padding(
        padding: EdgeInsets.only(top: i == 0 ? 0 : _gap),
        child: hasRight
            ? Row(children: [
                Expanded(
                    child: AspectRatio(
                        aspectRatio: 1,
                        child: _tile(images[li], onTap: () => open(li)))),
                const SizedBox(width: _gap),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    // "+N" liegt auf dem 4. sichtbaren Bild (Index 3).
                    child: _tile(images[ri],
                        onTap: () => open(ri), plusMore: ri == 3 ? plusMore : 0),
                  ),
                ),
              ])
            // Ungerade Anzahl: letztes Bild über die volle Breite (liegend).
            : AspectRatio(
                aspectRatio: 2, child: _tile(images[li], onTap: () => open(li))),
      ));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  Widget _tile(ChatAttachment a, {VoidCallback? onTap, int plusMore = 0}) {
    final provider = _providerFor(a)!;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Platzhalterfläche, damit die Bubble sofort steht und das Bild
          // sauber einblendet, statt „leer -> plopp".
          Container(color: theme.colors.incomingBubble),
          Image(
            image: provider,
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, wasSyncLoaded) {
              if (wasSyncLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: child,
              );
            },
          ),
          if (plusMore > 0)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Text('+$plusMore',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  style: theme.typography.reaction
                      .copyWith(color: theme.colors.reactionChipText),
                ),
                if (r.count > 1) ...[
                  const SizedBox(width: 2),
                  Text(
                    '${r.count}',
                    style: theme.typography.reaction
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
    required this.ink,
    required this.bubbleColor,
    this.channel,
  });

  final String time;
  final bool isOutgoing;
  final bool showStatus;
  final MessageStatus status;
  final ChatTheme theme;

  /// Colors of the bubble this row sits inside.
  final BubbleInk ink;

  /// Fill color of the bubble this row sits inside, needed to keep the read
  /// receipt tick's own hue readable via [readableOn].
  final Color bubbleColor;

  /// The channel this message travelled over, if known — shown as a compact
  /// badge before the timestamp.
  final ChatChannel? channel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (channel != null)
          ChatChannelBadge(
            channel: channel!,
            compact: true,
            theme: theme,
            surface: bubbleColor,
          ),
        Text(
          time,
          style: theme.typography.timestamp.copyWith(color: ink.muted),
        ),
        if (showStatus) ...[
          const SizedBox(width: 4),
          _StatusIcon(
              status: status, ink: ink, bubbleColor: bubbleColor, theme: theme),
        ],
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.status,
    required this.ink,
    required this.bubbleColor,
    required this.theme,
  });

  final MessageStatus status;
  final BubbleInk ink;
  final Color bubbleColor;
  final ChatTheme theme;

  @override
  Widget build(BuildContext context) {
    final icons = theme.icons;
    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: 12, color: ink.muted);
      case MessageStatus.sent:
        return Icon(icons.sent, size: 14, color: ink.muted);
      case MessageStatus.delivered:
        return Icon(icons.delivered, size: 14, color: ink.muted);
      case MessageStatus.read:
        return Icon(icons.read,
            size: 14,
            color: readableOn(bubbleColor, theme.colors.readReceipt, target: 3.0));
      case MessageStatus.failed:
        return Icon(icons.error,
            size: 14,
            color: readableOn(bubbleColor, theme.colors.error, target: 3.0));
    }
  }
}

String _formatTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
