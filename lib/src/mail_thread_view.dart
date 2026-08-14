import 'package:flutter/material.dart';

import 'chat_strings.dart';
import 'mail_body_request.dart';
import 'mail_detail_view.dart';
import 'mail_models.dart';
import 'mail_theme.dart';

/// A mail conversation: the newest message open, the earlier ones collapsed
/// into one-line rows that expand on tap.
///
/// This is to mail what `ChatThreadView` is to chat — with the difference
/// that mails are long, so only one is worth showing in full at a time.
class MailThreadView extends StatefulWidget {
  /// Creates a thread view for [messages], oldest first.
  const MailThreadView({
    super.key,
    required this.messages,
    this.theme = const MailTheme.light(),
    this.strings,
    this.bodyBuilder,
    this.remoteContentAllowed = false,
    this.onAllowRemoteContent,
    this.hatFernInhalt,
    this.onOpenLink,
    this.onOpenAttachment,
    this.onReply,
    this.onReplyAll,
    this.onForward,
    this.showSubjectOnFirst = true,
    this.bodyPadding = EdgeInsets.zero,
    this.newestFirst = true,
    this.highlightMessageId,
  });

  /// The mails of this conversation, oldest first.
  final List<MailMessage> messages;

  /// Visual configuration; defaults to [MailTheme.light].
  final MailTheme theme;

  /// Overrides the words used by this view and the details it renders.
  final ChatStrings? strings;

  /// Draws a mail's body; forwarded to [MailDetailView.bodyBuilder].
  final Widget Function(BuildContext, MailBodyRequest)? bodyBuilder;

  /// Whether remote content may be loaded — false by default.
  final bool remoteContentAllowed;

  /// Called when the reader allows remote content.
  final VoidCallback? onAllowRemoteContent;

  /// Trägt eine Mail etwas, das erst nachgeladen werden müsste? Wird an
  /// [MailDetailView.hatFernInhalt] durchgereicht.
  final bool Function(MailMessage)? hatFernInhalt;

  /// Called with a link the reader wants to follow.
  final void Function(Uri)? onOpenLink;

  /// Called with an attachment the reader wants to open. The chip shows a
  /// spinner until the returned future completes — including when it
  /// completes with an error, which the chip does not catch; reporting that
  /// failure to the reader is the caller's job.
  final Future<void> Function(MailAttachment)? onOpenAttachment;

  /// Called with the mail the reader wants to answer.
  final void Function(MailMessage)? onReply;

  /// Called with the mail the reader wants to answer to everyone.
  final void Function(MailMessage)? onReplyAll;

  /// Called with the mail the reader wants to pass on.
  final void Function(MailMessage)? onForward;

  /// Whether the subject is printed on the mails. Off where the surrounding
  /// screen already shows it.
  final bool showSubjectOnFirst;

  /// Extra space around each mail's body; forwarded to
  /// [MailDetailView.bodyPadding].
  final EdgeInsets bodyPadding;

  /// Whether the newest mail sits at the top. On by default: in a mail thread
  /// the newest one is what you came for, and scrolling past the history to
  /// reach it is a chore. Pass false for oldest-first (chat order).
  final bool newestFirst;

  /// This mail is expanded, even when it is not the newest one — meant for
  /// arriving from a search hit. `null` keeps the previous behaviour.
  final String? highlightMessageId;

  @override
  State<MailThreadView> createState() => _MailThreadViewState();
}

class _MailThreadViewState extends State<MailThreadView> {
  /// Kennungen der Mails, die der Leser zusätzlich aufgeklappt hat.
  final Set<String> _offen = {};

  /// Die Mails in Anzeige-Reihenfolge: neueste oben, sofern gewünscht.
  List<MailMessage> get _sortiert => widget.newestFirst
      ? widget.messages.reversed.toList(growable: false)
      : widget.messages;

  /// Offen ist die neueste, die hervorgehobene — und alles, was der Leser
  /// aufgeklappt hat.
  bool _istOffen(int index, List<MailMessage> liste) =>
      index == (widget.newestFirst ? 0 : liste.length - 1) ||
      liste[index].id == widget.highlightMessageId ||
      _offen.contains(liste[index].id);

  @override
  Widget build(BuildContext context) {
    final strings = ChatStrings.of(context, override: widget.strings);
    // Ohne Mails bliebe sonst eine weiße Fläche stehen — die sieht aus wie
    // eine hängende Ansicht und sagt nicht, dass hier nichts liegt.
    if (widget.messages.isEmpty) {
      return Material(
        color: widget.theme.background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              strings.noMailYet,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.theme.textColor.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }
    return Material(
      color: widget.theme.background,
      // Tippen in den Verlauf schließt die Tastatur — im Composer gibt es
      // sonst keinen Weg zurück.
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView.builder(
          itemCount: _sortiert.length,
          itemBuilder: (context, i) {
            final liste = _sortiert;
            final m = liste[i];
            if (!_istOffen(i, liste)) {
              return _EingeklappteMail(
                message: m,
                theme: widget.theme,
                strings: strings,
                onTap: () => setState(() => _offen.add(m.id)),
              );
            }
            return MailDetailView(
              message: m,
              theme: widget.theme,
              showSubject: widget.showSubjectOnFirst,
              bodyPadding: widget.bodyPadding,
              strings: widget.strings,
              bodyBuilder: widget.bodyBuilder,
              remoteContentAllowed: widget.remoteContentAllowed,
              onAllowRemoteContent: widget.onAllowRemoteContent,
              hatFernInhalt: widget.hatFernInhalt,
              onOpenLink: widget.onOpenLink,
              onOpenAttachment: widget.onOpenAttachment,
              onReply: widget.onReply == null ? null : () => widget.onReply!(m),
              onReplyAll: widget.onReplyAll == null
                  ? null
                  : () => widget.onReplyAll!(m),
              onForward: widget.onForward == null
                  ? null
                  : () => widget.onForward!(m),
            );
          },
        ),
      ),
    );
  }
}

/// Eine ältere Mail als Zeile: Absender, Datum, Anfang des Textes.
class _EingeklappteMail extends StatelessWidget {
  const _EingeklappteMail({
    required this.message,
    required this.theme,
    required this.strings,
    required this.onTap,
  });

  final MailMessage message;
  final MailTheme theme;
  final ChatStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gedaempft = theme.textColor.withValues(alpha: 0.6);
    return ListTile(
      onTap: onTap,
      title: Text(
        message.from.display,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: theme.textColor, fontSize: 13),
      ),
      subtitle: Text(
        message.bodyText.replaceAll(RegExp(r'\s+'), ' ').trim(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: gedaempft, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.attachments.isNotEmpty)
            Icon(Icons.attach_file, size: 14, color: gedaempft),
          const SizedBox(width: 4),
          Tooltip(
            message: strings.showQuoted,
            child: Icon(Icons.expand_more, size: 18, color: gedaempft),
          ),
        ],
      ),
    );
  }
}
