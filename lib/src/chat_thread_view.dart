import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chat_attachment.dart';
import 'chat_capabilities.dart';
import 'chat_theme.dart';
import 'composer.dart';
import 'date_separator.dart';
import 'message_bubble.dart';
import 'models.dart';
import 'thread_items.dart';
import 'typing_indicator.dart';

/// A scrollable message thread plus a composer. Groups messages, inserts date
/// separators, shows a typing indicator, and auto-scrolls to the newest message.
class ChatThreadView extends StatefulWidget {
  /// Creates a thread view.
  const ChatThreadView({
    super.key,
    required this.messages,
    required this.onSend,
    this.theme = const ChatTheme.light(),
    this.capabilities = const ChatCapabilities.inApp(),
    this.typing = const TypingState(),
    this.hintText,
    this.now,
    this.onAttach,
    this.onTypingChanged,
    this.onReplyRequested,
    this.onReact,
    this.onOpenAttachment,
    this.onOpenImages,
    this.onCopy,
    this.attachmentPreviews = const [],
    this.onRemoveAttachmentAt,
    this.onAddAttachment,
    this.onLoadEarlier,
    this.header,
  });

  /// Messages, oldest first.
  final List<ChatMessage> messages;

  /// Called with text when the user sends.
  final void Function(String) onSend;

  /// Visual configuration.
  final ChatTheme theme;

  /// Which affordances are allowed.
  final ChatCapabilities capabilities;

  /// Who is currently typing.
  final TypingState typing;

  /// Composer placeholder.
  final String? hintText;

  /// Injectable "now" for date separators.
  final DateTime? now;

  /// Called with an attachment source.
  final void Function(AttachSource source)? onAttach;

  /// Called on typing start/stop.
  final void Function(bool isTyping)? onTypingChanged;

  /// Called with a message id when a reply is requested.
  final void Function(String messageId)? onReplyRequested;

  /// Called with a message id + emoji on reaction.
  final void Function(String messageId, String emoji)? onReact;

  /// Called when a non-image attachment is tapped.
  final void Function(ChatAttachment attachment)? onOpenAttachment;

  /// Called when an image is tapped, with the message's images and the tapped
  /// index — for opening a swipeable full-screen gallery.
  final void Function(List<ChatAttachment> images, int index)? onOpenImages;

  /// Called after a message's text was copied to the clipboard (e.g. to show
  /// a confirmation). Copy itself is handled internally.
  final VoidCallback? onCopy;

  /// Pending attachments (picked but not yet sent) shown as thumbnails above
  /// the composer input; enable the send button even with an empty text field.
  final List<ImageProvider> attachmentPreviews;

  /// Called with the index of the pending attachment the user removed.
  final void Function(int index)? onRemoveAttachmentAt;

  /// Called when the "+" tile is tapped to add another attachment.
  final VoidCallback? onAddAttachment;

  /// Called when the user scrolls to the top to load older history.
  final Future<void> Function()? onLoadEarlier;

  /// Optional header widget above the list.
  final Widget? header;

  @override
  State<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<ChatThreadView> {
  final ScrollController _scroll = ScrollController();
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _lastCount = widget.messages.length;
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  @override
  void didUpdateWidget(covariant ChatThreadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != _lastCount) {
      final grew = widget.messages.length > oldWidget.messages.length;
      if (grew &&
          widget.messages.isNotEmpty &&
          widget.messages.last.direction == MessageDirection.incoming &&
          widget.theme.motion.hapticsEnabled &&
          widget.theme.motion.hapticOnReceive) {
        HapticFeedback.lightImpact();
      }
      _lastCount = widget.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels <= 8 && widget.onLoadEarlier != null) {
      widget.onLoadEarlier!();
    }
  }

  void _jumpToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    final target = _scroll.position.maxScrollExtent;
    if (widget.theme.motion.animatedAutoScroll) {
      _scroll.animateTo(
        target,
        duration: widget.theme.motion.autoScrollDuration,
        curve: Curves.easeOut,
      );
    } else {
      _scroll.jumpTo(target);
    }
    // Nachfassen: Bild-Bubbles und das Einklappen der Anhang-Vorschau im
    // Composer verändern die Höhe erst nach diesem Frame -- ein einzelner Sprung
    // träfe dann nicht mehr den echten Boden. Zweimal nachziehen (nächster Frame
    // + kurze Verzögerung) hält den Verlauf zuverlässig ganz unten.
    WidgetsBinding.instance.addPostFrameCallback((_) => _snapToBottom());
    Future.delayed(const Duration(milliseconds: 250), _snapToBottom);
  }

  void _snapToBottom() {
    if (!mounted || !_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    final items = buildThreadItems(widget.messages);
    final showTyping =
        widget.typing.anyoneTyping && widget.capabilities.typingIndicator;
    final childCount = items.length + (showTyping ? 1 : 0);

    return Container(
      color: widget.theme.colors.background,
      child: Column(
        children: [
          if (widget.header != null) widget.header!,
          Expanded(
            // Tippen auf den Verlaufs-Hintergrund schließt die Tastatur.
            // translucent -> Taps auf Bubbles (Longpress/Bild öffnen) bleiben,
            // Scrollen bleibt ebenfalls unbeeinträchtigt.
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: childCount,
              itemBuilder: (context, index) {
                if (showTyping && index == items.length) {
                  return TypingIndicator(theme: widget.theme);
                }
                final item = items[index];
                if (item is DateSeparatorItem) {
                  return DateSeparator(
                    date: item.date,
                    theme: widget.theme,
                    now: widget.now,
                  );
                }
                final mi = item as MessageItem;
                return MessageBubble(
                  key: ValueKey(mi.message.id),
                  message: mi.message,
                  theme: widget.theme,
                  capabilities: widget.capabilities,
                  isFirstInGroup: mi.isFirstInGroup,
                  isLastInGroup: mi.isLastInGroup,
                  animateIn: index >= items.length - 1,
                  onReplyRequested: widget.onReplyRequested == null
                      ? null
                      : () => widget.onReplyRequested!(mi.message.id),
                  onReact: widget.onReact == null
                      ? null
                      : (emoji) => widget.onReact!(mi.message.id, emoji),
                  onOpenAttachment: widget.onOpenAttachment,
                  onOpenImages: widget.onOpenImages,
                  onCopy: widget.onCopy,
                );
              },
              ),
            ),
          ),
          Composer(
            onSend: widget.onSend,
            hintText: widget.hintText,
            theme: widget.theme,
            capabilities: widget.capabilities,
            onAttach: widget.onAttach,
            onTypingChanged: widget.onTypingChanged,
            attachmentPreviews: widget.attachmentPreviews,
            onRemoveAttachmentAt: widget.onRemoveAttachmentAt,
            onAddAttachment: widget.onAddAttachment,
          ),
        ],
      ),
    );
  }
}
