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
    this.attachments = const [],
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

  /// Body text, including the quoted original when there is one.
  final String body;

  /// Files to send along.
  final List<MailAttachment> attachments;

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
  factory MailDraft.reply(MailMessage source) => MailDraft(
        to: [source.replyTo ?? source.from],
        subject: _prefixed(source.subject, 're', 'Re: '),
        body: _quote(source),
        inReplyTo: source.messageId,
        references: _chain(source),
        mode: MailComposeMode.reply,
      );

  /// An answer to everyone who was on [source] — except [self], who would
  /// otherwise get their own reply.
  factory MailDraft.replyAll(MailMessage source, {MailAddress? self}) {
    final antwortAn = source.replyTo ?? source.from;
    bool fremd(MailAddress a) =>
        a.email.toLowerCase() != (self?.email.toLowerCase() ?? '') &&
        a.email.toLowerCase() != antwortAn.email.toLowerCase();

    final kopie = <MailAddress>[];
    for (final a in [...source.to, ...source.cc]) {
      if (fremd(a) && !kopie.any((b) => b.email == a.email)) kopie.add(a);
    }
    return MailDraft(
      to: [antwortAn],
      cc: kopie,
      subject: _prefixed(source.subject, 're', 'Re: '),
      body: _quote(source),
      inReplyTo: source.messageId,
      references: _chain(source),
      mode: MailComposeMode.replyAll,
    );
  }

  /// [source] passed on: no recipients yet, the original quoted in full.
  factory MailDraft.forward(MailMessage source) => MailDraft(
        subject: _prefixed(source.subject, 'fwd', 'Fwd: '),
        body: _quote(source, withHeader: true),
        mode: MailComposeMode.forward,
      );

  /// Returns a copy with the given fields replaced.
  MailDraft copyWith({
    List<MailAddress>? to,
    List<MailAddress>? cc,
    List<MailAddress>? bcc,
    String? subject,
    String? body,
    List<MailAttachment>? attachments,
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
      attachments: attachments ?? this.attachments,
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
  final zeilen = source.bodyText.split('\n').map((z) => '> $z').join('\n');
  final kopf = withHeader
      ? '--- Weitergeleitete Nachricht ---\n'
          'Von: ${source.from.display}\n'
          'Betreff: ${source.subject}\n\n'
      : '${source.from.display} schrieb:\n';
  return '\n\n$kopf$zeilen\n';
}

List<String> _chain(MailMessage source) => [
      ...source.references,
      if (source.messageId != null) source.messageId!,
    ];
