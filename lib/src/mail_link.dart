/// Whether a link's visible text points somewhere other than the link itself.
///
/// The oldest trick in phishing: the text says `paypal.com`, the link goes to
/// `paypal.com.evil.tld`. Comparing the two is something every mail client
/// should do, so it lives here rather than in each host.
///
/// Returns false when the text is not a domain at all (`click here`) — there
/// is nothing to contradict then.
bool linkLooksDisguised(String? linkText, Uri target) {
  final text = (linkText ?? '').trim().toLowerCase();
  if (text.isEmpty) return false;

  final behauptet = _domainIn(text);
  if (behauptet == null) return false;

  final echt = registrableDomain(target.host);
  if (echt.isEmpty) return false;
  return registrableDomain(behauptet) != echt;
}

/// The part of a host a person actually reads: `mail.bank.at` → `bank.at`.
///
/// Deliberately naive about multi-part suffixes (`co.uk`) — erring toward
/// "these differ" only ever produces a warning, never a silent pass.
String registrableDomain(String host) {
  final h = host.trim().toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  final teile = h.split('.').where((t) => t.isNotEmpty).toList();
  if (teile.length < 2) return h;
  return teile.sublist(teile.length - 2).join('.');
}

/// Sucht in einem Linktext etwas, das wie eine Domain aussieht.
String? _domainIn(String text) {
  final m = RegExp(
    r'\b((?:[a-z0-9-]+\.)+[a-z]{2,})\b',
  ).firstMatch(text.replaceAll(RegExp(r'^https?://'), ''));
  return m?.group(1);
}
