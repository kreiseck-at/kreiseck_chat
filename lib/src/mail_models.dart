import 'mail_address.dart';

/// Direction of a mail message relative to the current mailbox.
enum MailDirection {
  /// Mail received into the mailbox.
  incoming,

  /// Mail sent from the mailbox.
  outgoing,
}

/// How far an attachment has been vetted before it reached the UI.
///
/// The widgets do not classify anything themselves — they have no idea what
/// a file contains. They only act on the verdict a host supplies, which is
/// where file-type sniffing and block lists belong.
enum AttachmentSafety {
  /// Content was checked and matches what the file claims to be.
  safe,

  /// Nothing is known about it. Downloadable, but never previewed and never
  /// opened without asking first.
  unknown,

  /// Refused. Not openable at all; [MailAttachment.blockedReason] says why.
  blocked,
}

/// A file attached to a [MailMessage].
///
/// This type is intentionally backend-agnostic: it carries no information
/// about how the attachment is stored or fetched beyond an optional [url].
class MailAttachment {
  /// Creates a mail attachment.
  const MailAttachment({
    required this.name,
    required this.sizeBytes,
    this.url,
    this.contentType,
    this.safety = AttachmentSafety.unknown,
    this.blockedReason,
  });

  /// File name of the attachment, e.g. `invoice.pdf`.
  final String name;

  /// Size of the attachment in bytes.
  final int sizeBytes;

  /// Optional URL the attachment can be downloaded from.
  final String? url;

  /// The type the content actually is — not what the mail claimed.
  final String? contentType;

  /// The host's verdict. Defaults to [AttachmentSafety.unknown]: an
  /// attachment nobody vouched for is not safe.
  final AttachmentSafety safety;

  /// Only set for [AttachmentSafety.blocked]: why it was refused.
  final String? blockedReason;

  /// Whether this attachment may be opened at all.
  bool get canOpen =>
      safety != AttachmentSafety.blocked && (url?.isNotEmpty ?? false);

  /// Whether it may be shown as a picture. Only a vetted image qualifies —
  /// rendering an unchecked file is exactly how a disguised one gets its
  /// chance.
  bool get canPreview =>
      canOpen &&
      safety == AttachmentSafety.safe &&
      (contentType?.startsWith('image/') ?? false);

  /// Creates a [MailAttachment] from a JSON-decoded map.
  factory MailAttachment.fromJson(Map<String, dynamic> json) {
    return MailAttachment(
      name: json['name'] as String,
      sizeBytes: json['sizeBytes'] as int,
      url: json['url'] as String?,
      contentType: json['contentType'] as String?,
      safety: AttachmentSafety.values.asNameMap()[json['safety'] as String?] ??
          AttachmentSafety.unknown,
      blockedReason: json['blockedReason'] as String?,
    );
  }

  /// Converts this attachment to a JSON-encodable map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sizeBytes': sizeBytes,
      if (url != null) 'url': url,
      if (contentType != null) 'contentType': contentType,
      'safety': safety.name,
      if (blockedReason != null) 'blockedReason': blockedReason,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailAttachment &&
        other.name == name &&
        other.sizeBytes == sizeBytes &&
        other.url == url &&
        other.contentType == contentType &&
        other.safety == safety &&
        other.blockedReason == blockedReason;
  }

  @override
  int get hashCode =>
      Object.hash(name, sizeBytes, url, contentType, safety, blockedReason);
}

/// Reference to a mail account, as shown e.g. in an account picker.
class MailAccountRef {
  /// Creates a mail account reference.
  const MailAccountRef({
    required this.id,
    required this.email,
    this.displayName,
  });

  /// Unique identifier of this account.
  final String id;

  /// Mail address of this account.
  final String email;

  /// Optional display name shown instead of the raw address.
  final String? displayName;

  /// Creates a [MailAccountRef] from a JSON-decoded map.
  factory MailAccountRef.fromJson(Map<String, dynamic> json) {
    return MailAccountRef(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailAccountRef &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName;
  }

  @override
  int get hashCode => Object.hash(id, email, displayName);
}

/// A single mail message within a mailbox.
///
/// This type is intentionally backend-agnostic: it carries no information
/// about how it was transported or persisted (e.g. no IMAP/SMTP details).
class MailMessage {
  /// Creates a mail message.
  const MailMessage({
    required this.id,
    required this.direction,
    required this.from,
    required this.to,
    required this.subject,
    required this.bodyText,
    required this.date,
    this.cc = const [],
    this.bcc = const [],
    this.replyTo,
    this.bodyHtml,
    this.seen = false,
    this.attachments = const [],
    this.spam = false,
    this.messageId,
    this.inReplyTo,
    this.references = const [],
    this.senderVerified,
  });

  /// Unique identifier of this message.
  final String id;

  /// Whether the message was received or sent.
  final MailDirection direction;

  /// Sender address.
  final MailAddress from;

  /// Recipients.
  final List<MailAddress> to;

  /// Recipients in copy.
  final List<MailAddress> cc;

  /// Recipients in blind copy. Only ever set on a mail you sent yourself —
  /// a received mail cannot know them.
  final List<MailAddress> bcc;

  /// Where a reply should go when it is not [from].
  final MailAddress? replyTo;

  /// Subject line.
  final String subject;

  /// Plain-text body.
  final String bodyText;

  /// Optional HTML body, if available.
  final String? bodyHtml;

  /// Timestamp the message was sent/received at.
  final DateTime date;

  /// Whether the message has been read.
  final bool seen;

  /// Attachments carried by this message.
  final List<MailAttachment> attachments;

  /// Whether the mailbox flagged this message as possible spam.
  final bool spam;

  /// Whether anyone besides the sender would receive a reply-all — the only
  /// case in which offering that action is not just noise.
  bool get hasOtherRecipients => cc.isNotEmpty || to.length > 1;

  /// The mail's own identifier, used to hang replies onto it.
  final String? messageId;

  /// The [messageId] this mail replies to.
  final String? inReplyTo;

  /// The chain of identifiers this mail belongs to.
  final List<String> references;

  /// Whether the sender's origin could be verified (SPF/DKIM/DMARC or
  /// whatever the host uses). Null means "not checked" — which is not the
  /// same as "failed", and the UI says so.
  final bool? senderVerified;

  /// Creates a [MailMessage] from a JSON-decoded map.
  factory MailMessage.fromJson(Map<String, dynamic> json) {
    return MailMessage(
      id: json['id'] as String,
      direction: MailDirection.values.byName(json['direction'] as String),
      from: MailAddress.parse(json['from'] as String?) ??
          const MailAddress(email: ''),
      to: _addresses(json['to']),
      cc: _addresses(json['cc']),
      bcc: _addresses(json['bcc']),
      replyTo: MailAddress.parse(json['replyTo'] as String?),
      subject: json['subject'] as String,
      bodyText: json['bodyText'] as String,
      bodyHtml: json['bodyHtml'] as String?,
      date: DateTime.parse(json['date'] as String),
      seen: json['seen'] as bool? ?? false,
      messageId: json['messageId'] as String?,
      inReplyTo: json['inReplyTo'] as String?,
      references: (json['references'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      senderVerified: json['senderVerified'] as bool?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => MailAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      spam: json['spam'] as bool? ?? false,
    );
  }

  /// Returns a copy of this message with the given fields replaced.
  ///
  /// For each nullable field there is a matching `clearX` flag: passing
  /// `clearX: true` sets that field to null, passing a value for the field
  /// sets it, and passing neither keeps the current value. Passing both a
  /// value and the matching `clearX: true` for the same field is a
  /// programming error and triggers an assertion.
  MailMessage copyWith({
    String? id,
    MailDirection? direction,
    MailAddress? from,
    List<MailAddress>? to,
    List<MailAddress>? cc,
    List<MailAddress>? bcc,
    MailAddress? replyTo,
    bool clearReplyTo = false,
    String? messageId,
    bool clearMessageId = false,
    String? inReplyTo,
    bool clearInReplyTo = false,
    List<String>? references,
    bool? senderVerified,
    bool clearSenderVerified = false,
    String? subject,
    String? bodyText,
    String? bodyHtml,
    bool clearBodyHtml = false,
    DateTime? date,
    bool? seen,
    List<MailAttachment>? attachments,
    bool? spam,
  }) {
    assert(
      !(clearBodyHtml && bodyHtml != null),
      'clearBodyHtml und ein bodyHtml-Wert schließen sich aus.',
    );
    assert(!(clearReplyTo && replyTo != null),
        'clearReplyTo und ein replyTo-Wert schließen sich aus.');
    assert(!(clearMessageId && messageId != null),
        'clearMessageId und ein messageId-Wert schließen sich aus.');
    assert(!(clearInReplyTo && inReplyTo != null),
        'clearInReplyTo und ein inReplyTo-Wert schließen sich aus.');
    assert(!(clearSenderVerified && senderVerified != null),
        'clearSenderVerified und ein senderVerified-Wert schließen sich aus.');
    return MailMessage(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      from: from ?? this.from,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      replyTo: clearReplyTo ? null : (replyTo ?? this.replyTo),
      messageId: clearMessageId ? null : (messageId ?? this.messageId),
      inReplyTo: clearInReplyTo ? null : (inReplyTo ?? this.inReplyTo),
      references: references ?? this.references,
      senderVerified:
          clearSenderVerified ? null : (senderVerified ?? this.senderVerified),
      subject: subject ?? this.subject,
      bodyText: bodyText ?? this.bodyText,
      bodyHtml: clearBodyHtml ? null : (bodyHtml ?? this.bodyHtml),
      date: date ?? this.date,
      seen: seen ?? this.seen,
      attachments: attachments ?? this.attachments,
      spam: spam ?? this.spam,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailMessage &&
        other.id == id &&
        other.direction == direction &&
        other.from == from &&
        _addrEquals(other.to, to) &&
        _addrEquals(other.cc, cc) &&
        _addrEquals(other.bcc, bcc) &&
        other.replyTo == replyTo &&
        other.messageId == messageId &&
        other.inReplyTo == inReplyTo &&
        other.senderVerified == senderVerified &&
        other.subject == subject &&
        other.bodyText == bodyText &&
        other.bodyHtml == bodyHtml &&
        other.date == date &&
        other.seen == seen &&
        _listEquals(other.attachments, attachments) &&
        other.spam == spam;
  }

  @override
  int get hashCode => Object.hash(
        id,
        direction,
        from,
        Object.hashAll(to),
        Object.hashAll(cc),
        Object.hashAll(bcc),
        replyTo,
        messageId,
        inReplyTo,
        senderVerified,
        subject,
        bodyText,
        bodyHtml,
        date,
        seen,
        Object.hashAll(attachments),
        spam,
      );
}

/// Adressen aus einer JSON-Liste bzw. einer einzelnen Kopfzeile.
List<MailAddress> _addresses(dynamic value) {
  if (value is List) {
    return [
      for (final e in value) ?MailAddress.parse(e?.toString()),
    ];
  }
  final einzeln = MailAddress.parse(value?.toString());
  return einzeln == null ? const [] : [einzeln];
}

bool _addrEquals(List<MailAddress> a, List<MailAddress> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _listEquals(List<MailAttachment> a, List<MailAttachment> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
