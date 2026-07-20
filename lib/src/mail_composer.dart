import 'package:flutter/material.dart';

import 'mail_theme.dart';

/// A composer for a new mail: recipient, subject and body fields plus a
/// send button.
///
/// The send button is disabled while the recipient or body field is empty.
class MailComposer extends StatefulWidget {
  /// Creates a mail composer that calls [onSend] with the entered
  /// recipient, subject and body.
  const MailComposer({
    super.key,
    required this.onSend,
    this.initialTo = '',
    this.initialSubject = '',
    this.initialBody = '',
    this.theme = const MailTheme.light(),
  });

  /// Called with (to, subject, body) when the user submits the mail.
  final void Function(String to, String subject, String body) onSend;

  /// Initial value of the recipient field.
  final String initialTo;

  /// Initial value of the subject field.
  final String initialSubject;

  /// Initial value of the body field.
  final String initialBody;

  /// Visual configuration; defaults to [MailTheme.light].
  final MailTheme theme;

  @override
  State<MailComposer> createState() => _MailComposerState();
}

class _MailComposerState extends State<MailComposer> {
  late final TextEditingController _toController;
  late final TextEditingController _subjectController;
  late final TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _toController = TextEditingController(text: widget.initialTo);
    _subjectController = TextEditingController(text: widget.initialSubject);
    _bodyController = TextEditingController(text: widget.initialBody);
    _toController.addListener(_onChanged);
    _bodyController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  bool get _canSend =>
      _toController.text.trim().isNotEmpty &&
      _bodyController.text.trim().isNotEmpty;

  void _submit() {
    if (!_canSend) return;
    widget.onSend(
      _toController.text.trim(),
      _subjectController.text.trim(),
      _bodyController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Material(
      color: theme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _toController,
              key: const ValueKey('mail-to'),
              decoration: const InputDecoration(labelText: 'An'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              key: const ValueKey('mail-subject'),
              decoration: const InputDecoration(labelText: 'Betreff'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              key: const ValueKey('mail-body'),
              minLines: 3,
              maxLines: 10,
              decoration: const InputDecoration(labelText: 'Text'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const ValueKey('mail-send'),
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canSend
                    ? theme.accentColor
                    : theme.accentColor.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
              ),
              child: const Text('Senden'),
            ),
          ],
        ),
      ),
    );
  }
}
