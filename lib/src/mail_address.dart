/// A mail address with an optional display name.
///
/// Kept apart from a plain `String` on purpose: a feature-complete mail view
/// has to show the *real* address, because the display name is the one part
/// of a mail a sender can put anything into.
class MailAddress {
  /// Creates an address.
  const MailAddress({required this.email, this.name});

  /// The address itself, e.g. `anna@example.at`.
  final String email;

  /// Optional display name.
  final String? name;

  /// `Anna Muster <anna@example.at>`, or just the address when there is no
  /// name to show.
  String get display {
    final n = name?.trim() ?? '';
    return n.isEmpty ? email : '$n <$email>';
  }

  /// Whether the display name is itself an address other than [email] — the
  /// most common way to make a mail look like it came from someone else.
  /// A name that repeats the real address is not a disguise.
  bool get displayNameLooksLikeAddress {
    final n = name?.trim().toLowerCase() ?? '';
    if (!n.contains('@')) return false;
    return !n.contains(email.toLowerCase());
  }

  /// Reads `Anna Muster <anna@example.at>`, `"Muster, Anna" <a@b.at>` or a
  /// bare address. Null when there is nothing usable.
  static MailAddress? parse(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return null;
    final spitz = RegExp(r'^(.*)<([^>]+)>$').firstMatch(s);
    if (spitz == null) {
      return s.contains('@') ? MailAddress(email: s) : null;
    }
    final name = spitz.group(1)!.trim().replaceAll(RegExp(r'^"|"$'), '').trim();
    return MailAddress(
      email: spitz.group(2)!.trim(),
      name: name.isEmpty ? null : name,
    );
  }

  /// Returns a copy with the given fields replaced.
  MailAddress copyWith({String? email, String? name, bool clearName = false}) {
    assert(!(clearName && name != null),
        'clearName und ein name-Wert schließen sich aus.');
    return MailAddress(
      email: email ?? this.email,
      name: clearName ? null : (name ?? this.name),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailAddress && other.email == email && other.name == name;
  }

  @override
  int get hashCode => Object.hash(email, name);

  @override
  String toString() => display;
}
