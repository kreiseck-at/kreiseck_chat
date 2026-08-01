import 'package:flutter/material.dart';

import 'chat_strings.dart';
import 'mail_models.dart';
import 'mail_theme.dart';

/// Renders a list of [MailMessage]s, e.g. an inbox overview.
///
/// Each row shows the sender, the subject (bold), the date and an unread
/// dot when the message's [MailMessage.seen] is `false`.
class MailListView extends StatelessWidget {
  /// Creates a mail list view.
  const MailListView({
    super.key,
    required this.messages,
    required this.onOpen,
    this.theme = const MailTheme.light(),
    this.badge,
    this.strings,
  });

  /// Messages to display.
  final List<MailMessage> messages;

  /// Called with the tapped message.
  final ValueChanged<MailMessage> onOpen;

  /// Visual configuration; defaults to [MailTheme.light].
  final MailTheme theme;

  /// Optional small badge (e.g. a channel marker) shown on the bottom-right of
  /// a leading sender avatar. When null, no avatar column is shown.
  final Widget? badge;

  /// Overrides the words used by this view. Left null, they follow the
  /// ambient locale (see [ChatStrings.of]).
  final ChatStrings? strings;

  @override
  Widget build(BuildContext context) {
    final strings = ChatStrings.of(context, override: this.strings);
    if (messages.isEmpty) {
      return Material(
        color: theme.background,
        child: Center(
          child: Text(
            strings.noMailYet,
            style: TextStyle(color: theme.textColor.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    return Material(
      color: theme.background,
      child: ListView.separated(
        itemCount: messages.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: theme.textColor.withValues(alpha: 0.08)),
        itemBuilder: (context, index) {
          final message = messages[index];
          return _MailTile(
            message: message,
            theme: theme,
            badge: badge,
            strings: strings,
            onTap: () => onOpen(message),
          );
        },
      ),
    );
  }
}

class _MailTile extends StatelessWidget {
  const _MailTile({
    required this.message,
    required this.theme,
    required this.badge,
    required this.strings,
    required this.onTap,
  });

  final MailMessage message;
  final MailTheme theme;
  final Widget? badge;
  final ChatStrings strings;
  final VoidCallback onTap;

  String get _initial {
    final s = (message.from.name ?? message.from.email).trim();
    return s.isEmpty ? '?' : s.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final mutedColor = theme.textColor.withValues(alpha: 0.6);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (badge != null) ...[
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.accentColor.withValues(alpha: 0.2),
                    child: Text(
                      _initial,
                      style: TextStyle(color: theme.accentColor),
                    ),
                  ),
                  Positioned(right: -2, bottom: -2, child: badge!),
                ],
              ),
              const SizedBox(width: 12),
            ],
            if (!message.seen) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.unreadDot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
            ] else
              const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.from.display,
                    style: TextStyle(color: mutedColor, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.subject,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (message.spam) ...[
                        const SizedBox(width: 6),
                        _SpamLabel(theme: theme, text: strings.spam),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(message.date),
              style: TextStyle(color: mutedColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small muted "Spam" tag shown next to the subject of a flagged message.
class _SpamLabel extends StatelessWidget {
  const _SpamLabel({required this.theme, required this.text});

  final MailTheme theme;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.accentColor,
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
