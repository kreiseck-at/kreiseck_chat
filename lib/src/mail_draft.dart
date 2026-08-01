import 'mail_address.dart';
import 'mail_models.dart';

/// What a draft is being written for. Drives the subject prefix, who the
/// recipients are and whether the original is quoted.
enum MailComposeMode {
  /// A new mail from scratch.
  compose,

  /// Answers the sender.
  reply,

  /// Answers the sender and everyone else who was on the mail.
  replyAll,

  /// Passes the mail on to someone new.
  forward,
}

/// Everything a mail needs before it can be sent.
///
/// Passed to `MailComposer` and handed back through its `onSend` — so a host
/// receives one value instead of reassembling fields, and the composer has
/// nothing to know about how mails are actually delivered.
class MailDraft {
  /// Creates a draft.
  const MailDraft({
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    this.subject = '',
    this.body = '',
    this.quotedBody = '',
    this.attachments = const [],
    this.suggestedCc = const [],
    this.inReplyTo,
    this.references = const [],
    this.mode = MailComposeMode.compose,
  });

  /// Recipients.
  final List<MailAddress> to;

  /// Recipients in copy.
  final List<MailAddress> cc;

  /// Recipients in blind copy.
  final List<MailAddress> bcc;

  /// Subject line.
  final String subject;

  /// What the writer types. The quoted original is NOT in here — a reply
  /// starts on an empty line, not in the middle of somebody else's text.
  final String body;

  /// The quoted original, kept apart so the composer can fold it away and
  /// the writer never has to scroll past it. Appended below [body] when the
  /// mail is sent (see [composedBody]).
  final String quotedBody;

  /// What actually goes out: what was typed, then the quoted original.
  String get composedBody =>
      quotedBody.isEmpty ? body : '$body\n\n$quotedBody';

  /// Files to send along.
  final List<MailAttachment> attachments;

  /// Everyone else who was on the original mail. They are NOT recipients —
  /// a reply goes to the sender. The composer offers them as checkboxes, so
  /// keeping someone in copy is one tap instead of a second button whose
  /// meaning ("reply all") has to be learned.
  final List<MailAddress> suggestedCc;

  /// The `messageId` this draft answers, so mail clients keep the thread.
  final String? inReplyTo;

  /// The identifier chain this draft belongs to.
  final List<String> references;

  /// What this draft is for.
  final MailComposeMode mode;

  /// Nothing typed, nothing attached, nobody addressed — safe to throw away.
  bool get isEmpty =>
      to.isEmpty &&
      cc.isEmpty &&
      bcc.isEmpty &&
      subject.trim().isEmpty &&
      body.trim().isEmpty &&
      attachments.isEmpty;

  /// An answer to [source], addressed to whoever should receive replies.
  ///
  /// Everyone else who was on the mail lands in [suggestedCc] — offered, not
  /// added. [self] is your own address, which never needs offering.
  factory MailDraft.reply(MailMessage source, {MailAddress? self}) {
    final an = source.replyTo ?? source.from;
    return MailDraft(
      to: [an],
      suggestedCc: _others(source, self: self, exclude: an),
      subject: _prefixed(source.subject, 're', 'Re: '),
      quotedBody: _quote(source),
      inReplyTo: source.messageId,
      references: _chain(source),
      mode: MailComposeMode.reply,
    );
  }

  /// An answer to everyone who was on [source] — except [self], who would
  /// otherwise get their own reply.
  factory MailDraft.replyAll(MailMessage source, {MailAddress? self}) {
    final antwortAn = source.replyTo ?? source.from;
    return MailDraft(
      to: [antwortAn],
      cc: _others(source, self: self, exclude: antwortAn),
      subject: _prefixed(source.subject, 're', 'Re: '),
      quotedBody: _quote(source),
      inReplyTo: source.messageId,
      references: _chain(source),
      mode: MailComposeMode.replyAll,
    );
  }

  /// [source] passed on: no recipients yet, the original quoted in full.
  factory MailDraft.forward(MailMessage source) => MailDraft(
        subject: _prefixed(source.subject, 'fwd', 'Fwd: '),
        quotedBody: _quote(source, withHeader: true),
        mode: MailComposeMode.forward,
      );

  /// Returns a copy with the given fields replaced.
  MailDraft copyWith({
    List<MailAddress>? to,
    List<MailAddress>? cc,
    List<MailAddress>? bcc,
    String? subject,
    String? body,
    String? quotedBody,
    List<MailAttachment>? attachments,
    List<MailAddress>? suggestedCc,
    String? inReplyTo,
    bool clearInReplyTo = false,
    List<String>? references,
    MailComposeMode? mode,
  }) {
    assert(!(clearInReplyTo && inReplyTo != null),
        'clearInReplyTo und ein inReplyTo-Wert schließen sich aus.');
    return MailDraft(
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      quotedBody: quotedBody ?? this.quotedBody,
      attachments: attachments ?? this.attachments,
      suggestedCc: suggestedCc ?? this.suggestedCc,
      inReplyTo: clearInReplyTo ? null : (inReplyTo ?? this.inReplyTo),
      references: references ?? this.references,
      mode: mode ?? this.mode,
    );
  }
}

/// `Re: ` / `Fwd: ` davor — aber nur einmal, egal in welcher Schreibweise es
/// schon dasteht.
String _prefixed(String subject, String marker, String prefix) {
  final s = subject.trim();
  return RegExp('^$marker:', caseSensitive: false).hasMatch(s)
      ? s
      : '$prefix$s';
}

/// Das Original als zitierter Block. [withHeader] stellt die Kopfdaten voran,
/// wie es beim Weiterleiten üblich ist.
String _quote(MailMessage source, {bool withHeader = false}) {
  // Das ">"-Zeichen ist die Fassung fürs Netz — beim Versand kennt jeder
  // Mail-Client es. Auf dem Schirm zeigt der Composer den Block stattdessen
  // eingeklappt, siehe MailComposer.
  final zeilen = source.bodyText.split('\n').map((z) => '> $z').join('\n');
  final kopf = withHeader
      ? '--- Weitergeleitete Nachricht ---\n'
          'Von: ${source.from.display}\n'
          'Betreff: ${source.subject}\n\n'
      : '${source.from.display} schrieb:\n';
  return '$kopf$zeilen';
}

/// Alle anderen, die auf der Mail standen — ohne die eigene Adresse und ohne
/// die, an die ohnehin geantwortet wird. Doppelte fallen weg.
List<MailAddress> _others(
  MailMessage source, {
  MailAddress? self,
  required MailAddress exclude,
}) {
  final raus = {
    exclude.email.toLowerCase(),
    if (self != null) self.email.toLowerCase(),
  };
  final out = <MailAddress>[];
  for (final a in [...source.to, ...source.cc]) {
    final e = a.email.toLowerCase();
    if (raus.contains(e) || out.any((b) => b.email.toLowerCase() == e)) continue;
    out.add(a);
  }
  return out;
}

List<String> _chain(MailMessage source) => [
      ...source.references,
      if (source.messageId != null) source.messageId!,
    ];
