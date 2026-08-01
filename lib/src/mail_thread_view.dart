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
    this.onOpenLink,
    this.onOpenAttachment,
    this.onReply,
    this.onReplyAll,
    this.onForward,
    this.showSubjectOnFirst = true,
    this.bodyPadding = EdgeInsets.zero,
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

  /// Called with a link the reader wants to follow.
  final void Function(Uri)? onOpenLink;

  /// Called with an attachment the reader wants to open.
  final void Function(MailAttachment)? onOpenAttachment;

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

  @override
  State<MailThreadView> createState() => _MailThreadViewState();
}

class _MailThreadViewState extends State<MailThreadView> {
  /// Kennungen der Mails, die der Leser zusätzlich aufgeklappt hat.
  final Set<String> _offen = {};

  bool _istOffen(int index) =>
      index == widget.messages.length - 1 ||
      _offen.contains(widget.messages[index].id);

  @override
  Widget build(BuildContext context) {
    final strings = ChatStrings.of(context, override: widget.strings);
    return Material(
      color: widget.theme.background,
      // Tippen in den Verlauf schließt die Tastatur — im Composer gibt es
      // sonst keinen Weg zurück.
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView.builder(
          itemCount: widget.messages.length,
          itemBuilder: (context, i) {
            final m = widget.messages[i];
            if (!_istOffen(i)) {
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
