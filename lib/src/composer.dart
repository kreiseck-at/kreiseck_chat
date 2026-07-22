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
    this.attachmentPreviews = const [],
    this.onRemoveAttachmentAt,
    this.onAddAttachment,
    this.showMic = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.sendOnEnter = false,
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

  /// Pending attachments the caller has picked but not yet sent. When
  /// non-empty, a row of thumbnails (each with a remove ×) plus a trailing "+"
  /// tile is shown above the input, and the send button becomes active even
  /// with an empty text field. The caller owns the files/upload; on send it
  /// pairs these attachments with [onSend]'s text (as an optional caption).
  final List<ImageProvider> attachmentPreviews;

  /// Called with the index of the thumbnail whose × was tapped.
  final void Function(int index)? onRemoveAttachmentAt;

  /// Called when the "+" tile in the preview row is tapped, to add more.
  final VoidCallback? onAddAttachment;

  /// Whether to show a (placeholder) mic button when the field is empty.
  final bool showMic;

  /// Auto-capitalization for the input; defaults to sentence case.
  final TextCapitalization textCapitalization;

  /// When true, the keyboard's return key sends the message. When false
  /// (default, WhatsApp-style) return inserts a newline and sending is only
  /// via the send button.
  final bool sendOnEnter;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final AnimationController _sendAnim;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onChanged);
    _sendAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _sendAnim.dispose();
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
    if (text.isEmpty && widget.attachmentPreviews.isEmpty) return;
    final motion = widget.theme.motion;
    if (motion.hapticsEnabled && motion.hapticOnSend) {
      HapticFeedback.lightImpact();
    }
    if (motion.sendAnimation) {
      _sendAnim.forward(from: 0).then((_) => _sendAnim.reverse());
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
    final showSend = hasText || widget.attachmentPreviews.isNotEmpty;
    return Material(
      color: theme.colors.composer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.attachmentPreviews.isNotEmpty)
                _AttachmentPreviewRow(
                  images: widget.attachmentPreviews,
                  accent: theme.colors.accent,
                  onRemoveAt: widget.onRemoveAttachmentAt,
                  onAdd: widget.onAddAttachment,
                ),
              Row(
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
                  textCapitalization: widget.textCapitalization,
                  keyboardType: TextInputType.multiline,
                  textInputAction: widget.sendOnEnter
                      ? TextInputAction.send
                      : TextInputAction.newline,
                  onSubmitted: widget.sendOnEnter ? (_) => _submit() : null,
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
              if (showSend)
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 0.8).animate(
                    CurvedAnimation(parent: _sendAnim, curve: Curves.easeInOut),
                  ),
                  child: IconButton(
                    icon: Icon(theme.icons.send, color: theme.colors.accent),
                    onPressed: _submit,
                  ),
                )
              else if (widget.capabilities.media) ...[
                IconButton(
                  icon: Icon(theme.icons.camera, color: theme.colors.accent),
                  onPressed: () => widget.onAttach?.call(AttachSource.camera),
                ),
                if (widget.showMic)
                  IconButton(
                    icon: Icon(theme.icons.mic, color: theme.colors.accent),
                    onPressed: null,
                  ),
              ] else if (widget.showMic)
                IconButton(
                  icon: Icon(theme.icons.mic, color: theme.colors.accent),
                  onPressed: null,
                )
              else
                // Keine Medien-/Mic-Funktion und leeres Feld: Sende-Button
                // sichtbar, aber deaktiviert -- die Leiste wirkt nicht „leer".
                IconButton(
                  icon: Icon(theme.icons.send,
                      color: theme.colors.accent.withValues(alpha: 0.35)),
                  onPressed: null,
                ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A horizontal row of pending-attachment thumbnails (each removable) followed
/// by a "+" tile to add more.
class _AttachmentPreviewRow extends StatelessWidget {
  const _AttachmentPreviewRow({
    required this.images,
    required this.accent,
    required this.onRemoveAt,
    required this.onAdd,
  });

  final List<ImageProvider> images;
  final Color accent;
  final void Function(int index)? onRemoveAt;
  final VoidCallback? onAdd;

  static const double _tile = 64;

  @override
  Widget build(BuildContext context) {
    // Eager Row (statt lazy ListView), damit alle Thumbnails immer gebaut werden.
    final children = <Widget>[];
    for (var i = 0; i < images.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 10));
      children.add(_Thumb(
        image: images[i],
        accent: accent,
        onRemove: onRemoveAt == null ? null : () => onRemoveAt!(i),
      ));
    }
    if (onAdd != null) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 10));
      children.add(_AddTile(accent: accent, onAdd: onAdd));
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 6),
      child: SizedBox(
        height: _tile + 8, // Platz für den überstehenden ×-Knopf.
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.image, required this.accent, required this.onRemove});

  final ImageProvider image;
  final Color accent;
  final VoidCallback? onRemove;

  static const double _pad = 8; // Platz oben/rechts für den ×-Knopf.

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _AttachmentPreviewRow._tile + _pad,
      height: _AttachmentPreviewRow._tile + _pad,
      // Bild unten-links, ×-Knopf oben-rechts -- beide innerhalb der Bounds,
      // damit der Knopf zuverlässig antippbar ist (kein Clip.none-Overflow).
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image(
                image: image,
                width: _AttachmentPreviewRow._tile,
                height: _AttachmentPreviewRow._tile,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.accent, required this.onAdd});

  final Color accent;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _AttachmentPreviewRow._tile + _Thumb._pad,
      height: _AttachmentPreviewRow._tile + _Thumb._pad,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: GestureDetector(
          onTap: onAdd,
          child: Container(
            width: _AttachmentPreviewRow._tile,
            height: _AttachmentPreviewRow._tile,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Icon(Icons.add, color: accent, size: 28),
          ),
        ),
      ),
    );
  }
}
