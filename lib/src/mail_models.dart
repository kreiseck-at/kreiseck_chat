/// Direction of a mail message relative to the current mailbox.
enum MailDirection {
  /// Mail received into the mailbox.
  incoming,

  /// Mail sent from the mailbox.
  outgoing,
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
  });

  /// File name of the attachment, e.g. `invoice.pdf`.
  final String name;

  /// Size of the attachment in bytes.
  final int sizeBytes;

  /// Optional URL the attachment can be downloaded from.
  final String? url;

  /// Creates a [MailAttachment] from a JSON-decoded map.
  factory MailAttachment.fromJson(Map<String, dynamic> json) {
    return MailAttachment(
      name: json['name'] as String,
      sizeBytes: json['sizeBytes'] as int,
      url: json['url'] as String?,
    );
  }

  /// Converts this attachment to a JSON-encodable map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sizeBytes': sizeBytes,
      if (url != null) 'url': url,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailAttachment &&
        other.name == name &&
        other.sizeBytes == sizeBytes &&
        other.url == url;
  }

  @override
  int get hashCode => Object.hash(name, sizeBytes, url);
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
    this.bodyHtml,
    this.seen = false,
    this.attachments = const [],
    this.spam = false,
  });

  /// Unique identifier of this message.
  final String id;

  /// Whether the message was received or sent.
  final MailDirection direction;

  /// Sender address.
  final String from;

  /// Recipient address.
  final String to;

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

  /// Creates a [MailMessage] from a JSON-decoded map.
  factory MailMessage.fromJson(Map<String, dynamic> json) {
    return MailMessage(
      id: json['id'] as String,
      direction: MailDirection.values.byName(json['direction'] as String),
      from: json['from'] as String,
      to: json['to'] as String,
      subject: json['subject'] as String,
      bodyText: json['bodyText'] as String,
      bodyHtml: json['bodyHtml'] as String?,
      date: DateTime.parse(json['date'] as String),
      seen: json['seen'] as bool? ?? false,
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
    String? from,
    String? to,
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
    return MailMessage(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      from: from ?? this.from,
      to: to ?? this.to,
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
        other.to == to &&
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
        to,
        subject,
        bodyText,
        bodyHtml,
        date,
        seen,
        Object.hashAll(attachments),
        spam,
      );
}

bool _listEquals(List<MailAttachment> a, List<MailAttachment> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
