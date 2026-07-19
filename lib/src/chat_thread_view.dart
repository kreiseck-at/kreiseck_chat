import 'package:flutter/material.dart';

import 'chat_theme.dart';
import 'composer.dart';
import 'message_bubble.dart';
import 'models.dart';

/// A full chat thread: a scrollable list of [messages] plus a [Composer].
///
/// New messages automatically scroll the list to the bottom. [messages] is
/// expected to be ordered oldest-first; the newest message is rendered at
/// the bottom, closest to the composer.
class ChatThreadView extends StatefulWidget {
  /// Creates a chat thread view.
  const ChatThreadView({
    super.key,
    required this.messages,
    required this.onSend,
    this.header,
    this.composerHint,
    this.theme = const ChatTheme.light(),
  });

  /// Messages to render, oldest first.
  final List<ChatMessage> messages;

  /// Called when the user sends a new message from the composer.
  final ValueChanged<String> onSend;

  /// Optional widget shown above the message list, e.g. a chat header.
  final Widget? header;

  /// Placeholder text for the composer's text field.
  final String? composerHint;

  /// Visual configuration; defaults to [ChatTheme.light].
  final ChatTheme theme;

  @override
  State<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<ChatThreadView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(covariant ChatThreadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages.length != widget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.theme.backgroundColor,
      child: Column(
        children: [
          if (widget.header != null) widget.header!,
          Expanded(
            child: widget.messages.isEmpty
                ? _EmptyState(theme: widget.theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      return MessageBubble(
                        message: widget.messages[index],
                        theme: widget.theme,
                      );
                    },
                  ),
          ),
          Composer(
            onSend: widget.onSend,
            hintText: widget.composerHint,
            theme: widget.theme,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ChatTheme theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No messages yet',
        style: TextStyle(color: theme.incomingTextColor.withValues(alpha: 0.5)),
      ),
    );
  }
}
