import 'package:flutter/material.dart';

import 'chat_strings.dart';
import 'mail_address.dart';
import 'mail_draft.dart';
import 'mail_theme.dart';

/// Writes a mail: recipients, copy and blind copy, subject, body and
/// attachments.
///
/// The composer owns the text fields but not the mail — it starts from a
/// [MailDraft] and hands a complete one back through [onSend], so a host has
/// one value to deal with instead of a handful of strings, and reply,
/// reply-all and forward differ only in the draft they start from.
class MailComposer extends StatefulWidget {
  /// Creates a composer for [draft].
  const MailComposer({
    super.key,
    required this.onSend,
    this.draft = const MailDraft(),
    this.theme = const MailTheme.light(),
    this.strings,
    this.onPickAttachment,
    this.onRemoveAttachmentAt,
    this.sending = false,
    this.errorText,
  });

  /// Called with the finished draft when the user sends.
  final void Function(MailDraft draft) onSend;

  /// What the composer starts from — recipients, subject, quoted original.
  final MailDraft draft;

  /// Visual configuration; defaults to [MailTheme.light].
  final MailTheme theme;

  /// Overrides the words used by this composer. Left null, they follow the
  /// ambient locale (see [ChatStrings.of]).
  final ChatStrings? strings;

  /// Called when the user wants to attach a file. Picking files is the
  /// host's business — this package neither reads disks nor uploads. Null
  /// hides the attach button.
  final VoidCallback? onPickAttachment;

  /// Called with the index of an attachment the user removed.
  final void Function(int index)? onRemoveAttachmentAt;

  /// Whether a send is in flight — disables the button and shows a spinner.
  final bool sending;

  /// Why the last send failed. Shown above the button; the text the user
  /// typed stays where it is.
  final String? errorText;

  @override
  State<MailComposer> createState() => _MailComposerState();
}

class _MailComposerState extends State<MailComposer> {
  late final TextEditingController _to;
  late final TextEditingController _cc;
  late final TextEditingController _bcc;
  late final TextEditingController _subject;
  late final TextEditingController _body;

  /// Copy fields stay out of the way until they are needed — most mails
  /// never use them.
  bool _kopieOffen = false;

  /// Das Zitat ist zugeklappt: Man antwortet auf eine Mail, man liest sie
  /// nicht noch einmal im Eingabefeld.
  bool _zitatOffen = false;

  @override
  void initState() {
    super.initState();
    _to = TextEditingController(text: _joined(widget.draft.to));
    _cc = TextEditingController(text: _joined(widget.draft.cc));
    _bcc = TextEditingController(text: _joined(widget.draft.bcc));
    _subject = TextEditingController(text: widget.draft.subject);
    _body = TextEditingController(text: widget.draft.body);
    _kopieOffen = widget.draft.cc.isNotEmpty || widget.draft.bcc.isNotEmpty;
    _to.addListener(_geaendert);
    _body.addListener(_geaendert);
  }

  @override
  void dispose() {
    _to.dispose();
    _cc.dispose();
    _bcc.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  void _geaendert() => setState(() {});

  static String _joined(List<MailAddress> a) => a.map((x) => x.email).join(', ');

  /// Kommagetrennte Eingabe zu Adressen. Was keine Adresse ist, fällt weg —
  /// der Server prüft ohnehin noch einmal.
  static List<MailAddress> _parsed(String raw) => [
        for (final teil in raw.split(RegExp(r'[,;]')))
          ?MailAddress.parse(teil.trim()),
      ];

  bool get _kannSenden =>
      !widget.sending &&
      _parsed(_to.text).isNotEmpty &&
      (_body.text.trim().isNotEmpty || widget.draft.attachments.isNotEmpty);

  void _senden() {
    if (!_kannSenden) return;
    widget.onSend(widget.draft.copyWith(
      to: _parsed(_to.text),
      cc: _parsed(_cc.text),
      bcc: _parsed(_bcc.text),
      subject: _subject.text.trim(),
      body: _body.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final strings = ChatStrings.of(context, override: widget.strings);
    return Material(
      color: theme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _to,
                    key: const ValueKey('mail-to'),
                    decoration: InputDecoration(labelText: strings.to),
                  ),
                ),
                if (!_kopieOffen)
                  TextButton(
                    key: const ValueKey('mail-cc-toggle'),
                    onPressed: () => setState(() => _kopieOffen = true),
                    child: Text('${strings.cc}/${strings.bcc}'),
                  ),
              ],
            ),
            if (_kopieOffen) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _cc,
                key: const ValueKey('mail-cc'),
                decoration: InputDecoration(labelText: strings.cc),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bcc,
                key: const ValueKey('mail-bcc'),
                decoration: InputDecoration(labelText: strings.bcc),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _subject,
              key: const ValueKey('mail-subject'),
              decoration: InputDecoration(labelText: strings.subject),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _body,
              key: const ValueKey('mail-body'),
              minLines: 3,
              maxLines: 10,
              decoration: InputDecoration(labelText: strings.body),
            ),
            if (widget.draft.quotedBody.isNotEmpty) ...[
              const SizedBox(height: 8),
              _Zitat(
                text: widget.draft.quotedBody,
                theme: theme,
                strings: strings,
                offen: _zitatOffen,
                onToggle: () => setState(() => _zitatOffen = !_zitatOffen),
              ),
            ],
            if (widget.draft.attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (i, a) in widget.draft.attachments.indexed)
                    Chip(
                      key: ValueKey('mail-attachment-$i'),
                      avatar: const Icon(Icons.attach_file, size: 16),
                      label: Text(a.name),
                      backgroundColor: theme.background,
                      labelStyle: TextStyle(color: theme.textColor),
                      onDeleted: widget.onRemoveAttachmentAt == null
                          ? null
                          : () => widget.onRemoveAttachmentAt!(i),
                    ),
                ],
              ),
            ],
            if (widget.errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.errorText!,
                key: const ValueKey('mail-error'),
                style: const TextStyle(color: Color(0xFFB5374A), fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.onPickAttachment != null)
                  IconButton(
                    key: const ValueKey('mail-attach'),
                    onPressed: widget.sending ? null : widget.onPickAttachment,
                    icon: const Icon(Icons.attach_file),
                    color: theme.accentColor,
                  ),
                Expanded(
                  child: ElevatedButton(
                    key: const ValueKey('mail-send'),
                    onPressed: _kannSenden ? _senden : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kannSenden
                          ? theme.accentColor
                          : theme.accentColor.withValues(alpha: 0.4),
                      foregroundColor: Colors.white,
                    ),
                    child: widget.sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(strings.send),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Das zitierte Original: zugeklappt eine Zeile, aufgeklappt der Text —
/// beides außerhalb des Eingabefelds, damit niemand daran vorbeitippen muss.
class _Zitat extends StatelessWidget {
  const _Zitat({
    required this.text,
    required this.theme,
    required this.strings,
    required this.offen,
    required this.onToggle,
  });

  final String text;
  final MailTheme theme;
  final ChatStrings strings;
  final bool offen;
  final VoidCallback onToggle;

  /// Die ">"-Zeichen sind Netz-Konvention, keine Typografie — auf dem Schirm
  /// macht das die Linie am Rand.
  String get _ohneMarker =>
      text.split('\n').map((z) => z.replaceFirst(RegExp(r'^>\s?'), '')).join('\n');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          key: const ValueKey('mail-quote-toggle'),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(offen ? Icons.expand_less : Icons.expand_more,
                    size: 18, color: theme.textColor.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  offen ? strings.quotedMessage : strings.showQuoted,
                  style: TextStyle(
                    color: theme.textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (offen)
          Container(
            key: const ValueKey('mail-quote'),
            width: double.infinity,
            padding: const EdgeInsets.only(left: 10, top: 2, bottom: 2),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                    color: theme.accentColor.withValues(alpha: 0.5), width: 2),
              ),
            ),
            child: Text(
              _ohneMarker,
              style: TextStyle(
                color: theme.textColor.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }
}
