import 'package:flutter/material.dart';

import 'chat_theme.dart';

/// A simple message composer: a text field with a send button.
///
/// The field is cleared after a successful send and empty (whitespace-only)
/// text is never submitted.
class Composer extends StatefulWidget {
  /// Creates a composer that calls [onSend] with the trimmed text.
  const Composer({
    super.key,
    required this.onSend,
    this.hintText,
    this.theme = const ChatTheme.light(),
  });

  /// Called with the message text when the user submits it.
  final ValueChanged<String> onSend;

  /// Placeholder text shown when the field is empty.
  final String? hintText;

  /// Visual configuration; defaults to [ChatTheme.light].
  final ChatTheme theme;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Material(
      color: theme.composerColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send, color: theme.accentColor),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
