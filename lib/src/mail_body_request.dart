import 'mail_models.dart';

/// What a host needs to draw a mail body itself (see
/// `MailDetailView.bodyBuilder`).
class MailBodyRequest {
  /// Creates a request.
  const MailBodyRequest({
    required this.message,
    required this.remoteContentAllowed,
    required this.openLink,
  });

  /// The mail being drawn.
  final MailMessage message;

  /// Whether remote content (images, fonts, anything fetched over the
  /// network) may be loaded. False means: draw placeholders, fetch nothing.
  final bool remoteContentAllowed;

  /// Opens a link on the reader's behalf. Refuses anything that is not
  /// `https` or `mailto` — a mail is untrusted input, and `javascript:`,
  /// `data:` and `file:` links have no business being followed from one.
  /// Returns whether the link was accepted.
  final bool Function(Uri) openLink;
}

/// Whether a link from a mail may be followed at all.
bool isFollowableMailLink(Uri uri) {
  final schema = uri.scheme.toLowerCase();
  return schema == 'https' || schema == 'mailto';
}
