import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chat_attachment.dart';
import 'chat_audio.dart';
import 'chat_capabilities.dart';
import 'chat_strings.dart';
import 'chat_system_card.dart';
import 'chat_theme.dart';
import 'composer.dart';
import 'date_separator.dart';
import 'media_grouping.dart';
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
    this.onRetry,
    this.attachmentPreviews = const [],
    this.onRemoveAttachmentAt,
    this.onAddAttachment,
    this.onLoadEarlier,
    this.header,
    this.customMessageBuilder,
    this.composerBanner,
    this.composerLeading,
    this.readOnly = false,
    this.strings,
    this.textBuilder,
    this.groupMedia = true,
    this.highlightMessageId,
    this.audioController,
  });

  /// Holds voice playback for this thread. Provide one to make audio
  /// attachments playable; without it they render as inert voice bubbles.
  final ChatAudioPlaybackController? audioController;

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

  /// Called with a failed message when the user taps its retry action. Null
  /// hides the action on every bubble, leaving only the failure reason.
  final void Function(ChatMessage message)? onRetry;

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

  /// Custom rendering for messages with [ChatMessageKind.custom]. If the
  /// builder returns `null`, the normal bubble is rendered instead.
  ///
  /// The returned widget is inset like a bubble (12 to each side, a little
  /// air above and below), so it lines up with the rest of the thread.
  ///
  /// The returned widget is not given a `ValueKey` by `ChatThreadView`, so a
  /// stateful widget should set its own `ValueKey` (e.g. from the message
  /// id) to avoid having its state recycled onto a different message.
  final Widget? Function(ChatMessage message)? customMessageBuilder;

  /// Notice bar shown directly above the composer field.
  final Widget? composerBanner;

  /// Widget to the left in the composer field, e.g. a channel picker.
  final Widget? composerLeading;

  /// Hides the composer field — for archive or supervisory views.
  final bool readOnly;

  /// Overrides the words used by this view and the sub-widgets it renders
  /// (`MessageBubble`, `DateSeparator`, `Composer`). Left null, they follow
  /// the ambient locale (see [ChatStrings.of]).
  final ChatStrings? strings;

  /// Renders the body of every bubble; forwarded to
  /// [MessageBubble.textBuilder]. Left null, bubbles draw plain text.
  final Widget Function(String text, TextStyle style)? textBuilder;

  /// Whether consecutive image-only messages are folded into one album (see
  /// [groupMediaRuns]). On by default — channels that send one photo per
  /// message would otherwise fill the thread with single-image bubbles.
  final bool groupMedia;

  /// This message is scrolled to on build, and briefly tinted — meant for
  /// arriving from a search hit. `null` keeps the previous behaviour of
  /// jumping to the end.
  final String? highlightMessageId;

  @override
  State<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<ChatThreadView> {
  /// The list is reversed: offset 0 IS the newest message. That single fact
  /// removes every scroll correction a chat usually needs -- opening lands at
  /// the bottom, a new message pushes the older ones up without moving the
  /// viewport, and an opening keyboard shrinks the viewport from the top
  /// instead of scrolling the newest message out of sight. Images that finish
  /// loading late grow upward for the same reason.
  final ScrollController _scroll = ScrollController();
  int _lastCount = 0;

  /// Schlüssel der hervorgehobenen Nachricht — über ihn findet
  /// `Scrollable.ensureVisible` die Stelle, ohne dass die Liste feste
  /// Zeilenhöhen bräuchte.
  final GlobalKey _hervorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _lastCount = widget.messages.length;
    _scroll.addListener(_onScroll);
    widget.audioController?.addListener(_onAudio);
    // Der reversed ListView landet von selbst am Boden (offset 0); nur ein
    // Sprung zu einer hervorgehobenen Nachricht braucht einen expliziten
    // Scroll nach dem ersten Bild.
    if (widget.highlightMessageId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _zurHervorhebung());
    }
  }

  void _zurHervorhebung() {
    final ctx = _hervorKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300),
        alignment: 0.3);
  }

  @override
  void didUpdateWidget(covariant ChatThreadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.audioController != oldWidget.audioController) {
      oldWidget.audioController?.removeListener(_onAudio);
      widget.audioController?.addListener(_onAudio);
    }
    if (widget.messages.length != _lastCount) {
      final grew = widget.messages.length > oldWidget.messages.length;
      if (grew &&
          widget.messages.isNotEmpty &&
          widget.messages.last.direction == MessageDirection.incoming &&
          widget.theme.motion.hapticsEnabled &&
          widget.theme.motion.hapticOnReceive) {
        HapticFeedback.lightImpact();
      }
      // Wer gerade weiter oben liest, wird nicht weggerissen -- nur wer ohnehin
      // unten steht (oder selbst gesendet hat) folgt der neuen Nachricht.
      if (grew) _scrollToBottom();
      _lastCount = widget.messages.length;
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    widget.audioController?.removeListener(_onAudio);
    super.dispose();
  }

  /// Der Controller meldet Fortschritt -- die Sprachblasen neu zeichnen.
  void _onAudio() {
    if (mounted) setState(() {});
  }

  /// In a reversed list the OLDEST message sits at the maximum offset -- so
  /// "scrolled to the top" means near the end of the scroll extent.
  void _onScroll() {
    if (widget.onLoadEarlier == null || !_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 8) widget.onLoadEarlier!();
  }

  /// Back to the newest message, i.e. offset 0. Only needed when the reader
  /// had scrolled away; standing at the bottom, the list stays there by
  /// itself.
  void _scrollToBottom() {
    if (!_scroll.hasClients || _scroll.position.pixels <= 0) return;
    if (widget.theme.motion.animatedAutoScroll) {
      _scroll.animateTo(
        0,
        duration: widget.theme.motion.autoScrollDuration,
        curve: Curves.easeOut,
      );
    } else {
      _scroll.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = buildThreadItems(
      widget.groupMedia ? groupMediaRuns(widget.messages) : widget.messages,
    );
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
                // Umgekehrt gezeichnet: der Boden ist Offset 0 (siehe _scroll).
                reverse: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: childCount,
                itemBuilder: (context, reversed) {
                  if (showTyping && reversed == 0) {
                    return TypingIndicator(theme: widget.theme);
                  }
                  final index =
                      items.length - 1 - (showTyping ? reversed - 1 : reversed);
                  final item = items[index];
                  if (item is DateSeparatorItem) {
                    return DateSeparator(
                      date: item.date,
                      theme: widget.theme,
                      now: widget.now,
                      strings: widget.strings,
                    );
                  }
                  final mi = item as MessageItem;
                  Widget? zeile;
                  if (mi.message.kind == ChatMessageKind.system) {
                    zeile = ChatSystemCard(
                      theme: widget.theme,
                      child: Text(
                        mi.message.text,
                        style: widget.theme.typography.systemMessage,
                      ),
                    );
                  }
                  if (zeile == null && mi.message.kind == ChatMessageKind.custom) {
                    final custom = widget.customMessageBuilder?.call(
                      mi.message,
                    );
                    // Ein eigenes Widget bekommt dieselben Ränder wie eine Blase,
                    // damit es in der Spalte steht statt am Rand zu kleben.
                    if (custom != null) {
                      zeile = Padding(
                        padding: EdgeInsets.fromLTRB(
                          12,
                          mi.isFirstInGroup ? 6 : 2,
                          12,
                          2,
                        ),
                        child: custom,
                      );
                    }
                  }
                  zeile ??= MessageBubble(
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
                    onRetry: widget.onRetry == null
                        ? null
                        : () => widget.onRetry!(mi.message),
                    audioPlayback: widget.audioController?.current,
                    onToggleAudio: widget.audioController == null
                        ? null
                        : (attachment, index) {
                            final url = attachment.url;
                            if (url == null) return;
                            widget.audioController!.toggle(
                              mi.message.id,
                              url,
                              attachmentIndex: index,
                            );
                          },
                    onSeekAudio: widget.audioController?.seek,
                    onAudioSpeed: widget.audioController?.setSpeed,
                    strings: widget.strings,
                    textBuilder: widget.textBuilder,
                  );
                  if (mi.message.id == widget.highlightMessageId) {
                    return TweenAnimationBuilder<double>(
                      key: const ValueKey('hervorgehoben'),
                      tween: Tween(begin: 1, end: 0),
                      duration: const Duration(seconds: 2),
                      builder: (context, t, kind) => Container(
                        key: _hervorKey,
                        color: widget.theme.colors.accent.withValues(
                          alpha: 0.18 * t,
                        ),
                        child: kind,
                      ),
                      child: zeile,
                    );
                  }
                  return zeile;
                },
              ),
            ),
          ),
          if (widget.composerBanner != null) widget.composerBanner!,
          if (!widget.readOnly)
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
              leading: widget.composerLeading,
              strings: widget.strings,
            ),
        ],
      ),
    );
  }
}
