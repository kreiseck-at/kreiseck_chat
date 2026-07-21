import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chat_capabilities.dart';
import 'chat_theme.dart';

/// Where an attachment comes from.
enum AttachSource { gallery, camera, file }

/// A message composer: attach button (gated), auto-growing text field, and a
/// send button. Emits typing changes and fires a send haptic per the theme.
class Composer extends StatefulWidget {
  /// Creates a composer.
  const Composer({
    super.key,
    required this.onSend,
    this.hintText,
    this.theme = const ChatTheme.light(),
    this.capabilities = const ChatCapabilities.inApp(),
    this.onAttach,
    this.onTypingChanged,
    this.showMic = false,
  });

  /// Called with the trimmed message text on submit.
  final void Function(String) onSend;

  /// Placeholder text.
  final String? hintText;

  /// Visual configuration.
  final ChatTheme theme;

  /// Which affordances are allowed.
  final ChatCapabilities capabilities;

  /// Called with a chosen source when the user taps attach.
  final void Function(AttachSource source)? onAttach;

  /// Called when typing starts (true) or stops (false).
  final void Function(bool isTyping)? onTypingChanged;

  /// Whether to show a (placeholder) mic button when the field is empty.
  final bool showMic;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  late final TextEditingController _controller;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final typing = _controller.text.trim().isNotEmpty;
    if (typing != _isTyping) {
      _isTyping = typing;
      widget.onTypingChanged?.call(typing);
    }
    setState(() {});
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final motion = widget.theme.motion;
    if (motion.hapticsEnabled && motion.hapticOnSend) {
      HapticFeedback.lightImpact();
    }
    widget.onSend(text);
    _controller.clear();
  }

  void _openAttachMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(widget.theme.icons.camera),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.of(ctx).pop();
                widget.onAttach?.call(AttachSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () {
                Navigator.of(ctx).pop();
                widget.onAttach?.call(AttachSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(widget.theme.icons.attach),
              title: const Text('Datei'),
              onTap: () {
                Navigator.of(ctx).pop();
                widget.onAttach?.call(AttachSource.file);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final hasText = _controller.text.trim().isNotEmpty;
    return Material(
      color: theme.colors.composer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.capabilities.media)
                IconButton(
                  icon: Icon(theme.icons.attach, color: theme.colors.accent),
                  onPressed: _openAttachMenu,
                ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Nachricht',
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
              const SizedBox(width: 4),
              if (hasText || !widget.showMic)
                IconButton(
                  icon: Icon(theme.icons.send, color: theme.colors.accent),
                  onPressed: _submit,
                )
              else
                IconButton(
                  icon: Icon(theme.icons.mic, color: theme.colors.accent),
                  onPressed: null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
