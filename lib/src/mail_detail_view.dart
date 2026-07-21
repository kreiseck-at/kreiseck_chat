import 'package:flutter/material.dart';

import 'mail_models.dart';
import 'mail_theme.dart';

/// Renders a single [MailMessage] in full: subject/from/date header, the
/// selectable body text, attachment chips and an optional reply button.
class MailDetailView extends StatelessWidget {
  /// Creates a mail detail view.
  const MailDetailView({
    super.key,
    required this.message,
    this.onReply,
    this.theme = const MailTheme.light(),
  });

  /// Message to display.
  final MailMessage message;

  /// Called when the user taps "Reply". The reply button is hidden when
  /// this is `null`.
  final VoidCallback? onReply;

  /// Visual configuration; defaults to [MailTheme.light].
  final MailTheme theme;

  @override
  Widget build(BuildContext context) {
    final mutedColor = theme.textColor.withValues(alpha: 0.6);

    return Material(
      color: theme.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.spam) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Möglicher Spam',
                  style: TextStyle(
                    color: theme.accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              message.subject,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.from,
              style: TextStyle(color: mutedColor),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(message.date),
              style: TextStyle(color: mutedColor, fontSize: 12),
            ),
            const SizedBox(height: 16),
            SelectableText(
              message.bodyText,
              style: TextStyle(color: theme.textColor),
            ),
            if (message.attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final attachment in message.attachments)
                    Chip(
                      avatar: const Icon(Icons.attach_file, size: 16),
                      label: Text(attachment.name),
                      backgroundColor: theme.surfaceColor,
                      labelStyle: TextStyle(color: theme.textColor),
                    ),
                ],
              ),
            ],
            if (onReply != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onReply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accentColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Antworten'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day.$month.${date.year} $hour:$minute';
}
