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
    this.hatFernInhalt,
    this.onOpenLink,
    this.onOpenAttachment,
    this.showSubject = true,
    this.padding = const EdgeInsets.all(16),
    this.bodyPadding = EdgeInsets.zero,
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

  /// Trägt diese Mail überhaupt etwas, das erst nachgeladen werden müsste?
  /// Ohne den Prüfer erscheint die Leiste bei jeder Mail mit HTML — eine
  /// Frage ohne Gegenstand, wenn gar nichts nachzuladen ist. Das Paket sieht
  /// sich das HTML bewusst nicht selbst an; das bleibt Sache des Aufrufers.
  final bool Function(MailMessage)? hatFernInhalt;

  /// Called with a link the reader wants to follow. Links are never opened
  /// by this widget; and anything that is not `https` or `mailto` is not
  /// offered at all (see [MailBodyRequest.openLink]), so a `javascript:`
  /// link stays inert text.
  final void Function(Uri)? onOpenLink;

  /// Called with an attachment the reader wants to open. Only ever called
  /// for attachments that may be opened (see [MailAttachment.canOpen]). The
  /// chip shows a spinner until the returned future completes — including
  /// when it completes with an error, which the chip does not catch;
  /// reporting that failure to the reader is the caller's job.
  final Future<void> Function(MailAttachment)? onOpenAttachment;

  /// Whether the subject is shown. Turn it off where the surrounding screen
  /// already carries it — a subject printed twice is a subject nobody reads.
  final bool showSubject;

  /// Space around the whole mail.
  final EdgeInsets padding;

  /// Extra space around the body only. Zero by default so an HTML mail can
  /// use the full width — mails bring their own margins, and a second set
  /// squeezes tables and images.
  final EdgeInsets bodyPadding;

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
        padding: padding,
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
            if (showSubject)
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
            Text(message.from.display, style: TextStyle(color: mutedColor)),
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
            if (!remoteContentAllowed &&
                message.bodyHtml != null &&
                (hatFernInhalt?.call(message) ?? true)) ...[
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
            Padding(
              padding: bodyPadding,
              child:
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
            if (onReply != null || onForward != null) ...[
              const SizedBox(height: 16),
              // Symbole statt Wörter — so kennt man es aus jedem Mail-Programm,
              // und drei Wortknöpfe nebeneinander sprengen jede schmale Zeile.
              Row(
                children: [
                  if (onReply != null)
                    IconButton(
                      key: const ValueKey('mail-reply'),
                      tooltip: strings.reply,
                      onPressed: onReply,
                      color: theme.accentColor,
                      icon: const Icon(Icons.reply_rounded),
                    ),
                  if (onReplyAll != null && message.hasOtherRecipients)
                    IconButton(
                      key: const ValueKey('mail-reply-all'),
                      tooltip: strings.replyAll,
                      onPressed: onReplyAll,
                      color: theme.accentColor,
                      icon: const Icon(Icons.reply_all_rounded),
                    ),
                  if (onForward != null)
                    IconButton(
                      key: const ValueKey('mail-forward'),
                      tooltip: strings.forward,
                      onPressed: onForward,
                      color: theme.accentColor,
                      icon: const Icon(Icons.forward_rounded),
                    ),
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
            child: Text(
              text,
              style: TextStyle(color: theme.textColor, fontSize: 12),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Ein Anhang. Was sich öffnen lässt und was nicht, entscheidet allein die
/// Einstufung — siehe [MailAttachment.canOpen].
class _AnhangChip extends StatefulWidget {
  const _AnhangChip({
    required this.attachment,
    required this.theme,
    required this.strings,
    this.onOpen,
  });

  final MailAttachment attachment;
  final MailTheme theme;
  final ChatStrings strings;
  final Future<void> Function(MailAttachment)? onOpen;

  @override
  State<_AnhangChip> createState() => _AnhangChipState();
}

class _AnhangChipState extends State<_AnhangChip> {
  /// Läuft gerade ein Öffnen? Eine große Datei braucht Sekunden; ohne
  /// Rückmeldung sieht der Chip aus, als hätte er den Tipp verschluckt.
  bool _laedt = false;

  Future<void> _oeffnen() async {
    final onOpen = widget.onOpen;
    if (onOpen == null || _laedt) return;
    setState(() => _laedt = true);
    try {
      await onOpen(widget.attachment);
    } finally {
      if (mounted) setState(() => _laedt = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachment;
    final theme = widget.theme;
    final gesperrt = attachment.safety == AttachmentSafety.blocked;
    final ungeprueft = attachment.safety == AttachmentSafety.unknown;
    final marke = gesperrt
        ? widget.strings.attachmentBlocked
        : ungeprueft
        ? widget.strings.attachmentUnknown
        : null;
    return Tooltip(
      message: attachment.blockedReason ?? '',
      child: ActionChip(
        avatar: _laedt
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.textColor.withValues(alpha: 0.6),
                ),
              )
            : Icon(gesperrt ? Icons.block : Icons.attach_file, size: 16),
        label: Text(
          marke == null ? attachment.name : '${attachment.name} · $marke',
        ),
        backgroundColor: theme.surfaceColor,
        labelStyle: TextStyle(
          color: gesperrt
              ? theme.textColor.withValues(alpha: 0.5)
              : theme.textColor,
        ),
        onPressed:
            attachment.canOpen && widget.onOpen != null && !_laedt
            ? _oeffnen
            : null,
      ),
    );
  }
}
