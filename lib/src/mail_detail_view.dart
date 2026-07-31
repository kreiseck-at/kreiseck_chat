import 'package:flutter/material.dart';

import 'chat_strings.dart';
import 'mail_body_request.dart';
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
    this.onReplyAll,
    this.onForward,
    this.theme = const MailTheme.light(),
    this.strings,
    this.bodyBuilder,
    this.remoteContentAllowed = false,
    this.onAllowRemoteContent,
    this.onOpenLink,
    this.onOpenAttachment,
  });

  /// Message to display.
  final MailMessage message;

  /// Called when the user taps "Reply". The reply button is hidden when
  /// this is `null`.
  final VoidCallback? onReply;

  /// Called when the user answers everyone. Hidden when null.
  final VoidCallback? onReplyAll;

  /// Called when the user passes the mail on. Hidden when null.
  final VoidCallback? onForward;

  /// Draws the mail body. Left null, [MailMessage.bodyText] is drawn as
  /// selectable text — HTML stays the host's business, so this package needs
  /// no HTML engine of its own.
  final Widget Function(BuildContext, MailBodyRequest)? bodyBuilder;

  /// Whether images and other remote content may be fetched. **False by
  /// default**: a mail that loads a remote image tells its sender when and
  /// where it was read. Passed to [bodyBuilder]; while false, a notice with
  /// a "load images" button is shown.
  final bool remoteContentAllowed;

  /// Called when the reader taps "load images". Without it the notice has no
  /// button — for hosts that never allow remote content.
  final VoidCallback? onAllowRemoteContent;

  /// Called with a link the reader wants to follow. Links are never opened
  /// by this widget; and anything that is not `https` or `mailto` is not
  /// offered at all (see [MailBodyRequest.openLink]), so a `javascript:`
  /// link stays inert text.
  final void Function(Uri)? onOpenLink;

  /// Called with an attachment the reader wants to open. Only ever called
  /// for attachments that may be opened (see [MailAttachment.canOpen]).
  final void Function(MailAttachment)? onOpenAttachment;

  /// Visual configuration; defaults to [MailTheme.light].
  final MailTheme theme;

  /// Overrides the words used by this view. Left null, they follow the
  /// ambient locale (see [ChatStrings.of]).
  final ChatStrings? strings;

  /// Reicht einen Link nach draußen — aber nur, wenn er überhaupt gefolgt
  /// werden darf. Rückgabe: ob er angenommen wurde.
  bool _openLink(Uri uri) {
    if (!isFollowableMailLink(uri)) return false;
    final auf = onOpenLink;
    if (auf == null) return false;
    auf(uri);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final strings = ChatStrings.of(context, override: this.strings);
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
                  strings.possibleSpam,
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
            // Immer die echte Adresse, nicht nur den Anzeigenamen: der Name
            // ist der eine Teil einer Mail, in den der Absender schreiben
            // kann, was er will.
            Text(
              message.from.display,
              style: TextStyle(color: mutedColor),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(message.date),
              style: TextStyle(color: mutedColor, fontSize: 12),
            ),
            // Herkunft nicht bestätigt: das gehört über den Text, nicht
            // darunter. `null` heißt "nicht geprüft" — dann wird nichts
            // behauptet.
            // Herkunft ausdrücklich fehlgeschlagen ODER der Anzeigename
            // täuscht eine fremde Adresse vor. `senderVerified == null` heißt
            // "nicht geprüft" — dann wird nichts behauptet.
            if (message.senderVerified == false ||
                message.from.displayNameLooksLikeAddress) ...[
              const SizedBox(height: 12),
              _Hinweis(
                theme: theme,
                icon: Icons.gpp_maybe_outlined,
                text: strings.senderUnverified,
              ),
            ],
            if (!remoteContentAllowed && message.bodyHtml != null) ...[
              const SizedBox(height: 12),
              _Hinweis(
                theme: theme,
                icon: Icons.image_not_supported_outlined,
                text: strings.remoteContentBlocked,
                action: onAllowRemoteContent == null
                    ? null
                    : TextButton(
                        onPressed: onAllowRemoteContent,
                        child: Text(strings.loadImages),
                      ),
              ),
            ],
            const SizedBox(height: 16),
            bodyBuilder?.call(
                  context,
                  MailBodyRequest(
                    message: message,
                    remoteContentAllowed: remoteContentAllowed,
                    openLink: _openLink,
                  ),
                ) ??
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
                    _AnhangChip(
                      attachment: attachment,
                      theme: theme,
                      strings: strings,
                      onOpen: onOpenAttachment,
                    ),
                ],
              ),
            ],
            if (onReply != null || onReplyAll != null || onForward != null) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onReply != null)
                    ElevatedButton(
                      onPressed: onReply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accentColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(strings.reply),
                    ),
                  if (onReplyAll != null)
                    OutlinedButton(
                        onPressed: onReplyAll, child: Text(strings.replyAll)),
                  if (onForward != null)
                    OutlinedButton(
                        onPressed: onForward, child: Text(strings.forward)),
                ],
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


/// Warn- bzw. Hinweisleiste über dem Text.
class _Hinweis extends StatelessWidget {
  const _Hinweis({
    required this.theme,
    required this.icon,
    required this.text,
    this.action,
  });

  final MailTheme theme;
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(color: theme.textColor, fontSize: 12)),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Ein Anhang. Was sich öffnen lässt und was nicht, entscheidet allein die
/// Einstufung — siehe [MailAttachment.canOpen].
class _AnhangChip extends StatelessWidget {
  const _AnhangChip({
    required this.attachment,
    required this.theme,
    required this.strings,
    this.onOpen,
  });

  final MailAttachment attachment;
  final MailTheme theme;
  final ChatStrings strings;
  final void Function(MailAttachment)? onOpen;

  @override
  Widget build(BuildContext context) {
    final gesperrt = attachment.safety == AttachmentSafety.blocked;
    final ungeprueft = attachment.safety == AttachmentSafety.unknown;
    final marke = gesperrt
        ? strings.attachmentBlocked
        : ungeprueft
            ? strings.attachmentUnknown
            : null;
    return Tooltip(
      message: attachment.blockedReason ?? '',
      child: ActionChip(
        avatar: Icon(gesperrt ? Icons.block : Icons.attach_file, size: 16),
        label: Text(
          marke == null ? attachment.name : '${attachment.name} · $marke',
        ),
        backgroundColor: theme.surfaceColor,
        labelStyle: TextStyle(
          color: gesperrt
              ? theme.textColor.withValues(alpha: 0.5)
              : theme.textColor,
        ),
        onPressed: attachment.canOpen && onOpen != null
            ? () => onOpen!(attachment)
            : null,
      ),
    );
  }
}
