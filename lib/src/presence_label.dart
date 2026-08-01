import 'chat_participant.dart';
import 'chat_strings.dart';

/// Customizable label strings for presence formatting (German defaults, kept
/// unchanged for backward compatibility with existing direct callers of
/// [formatPresenceLabel] — a host that wants these to follow the ambient
/// locale should build this via [PresenceLabels.fromStrings] instead, as
/// [ChatHeader] does).
class PresenceLabels {
  /// Creates label strings.
  const PresenceLabels({
    this.online = 'Online',
    this.lastSeenTodayPrefix = 'zuletzt gesehen um ',
    this.lastSeenYesterdayPrefix = 'zuletzt gesehen gestern um ',
    this.lastSeenDatePrefix = 'zuletzt gesehen am ',
    this.lastSeenAtJoiner = ' um ',
  });

  /// Builds label strings from a [ChatStrings]' presence fields, so a host
  /// that already resolves [ChatStrings] (see [ChatStrings.of]) gets a
  /// matching [PresenceLabels] instead of maintaining a separate translation.
  factory PresenceLabels.fromStrings(ChatStrings strings) => PresenceLabels(
    online: strings.online,
    lastSeenTodayPrefix: strings.lastSeenTodayPrefix,
    lastSeenYesterdayPrefix: strings.lastSeenYesterdayPrefix,
    lastSeenDatePrefix: strings.lastSeenDatePrefix,
    lastSeenAtJoiner: strings.lastSeenAtJoiner,
  );

  /// Shown when online.
  final String online;

  /// Prefix before a HH:MM time for a same-day last-seen.
  final String lastSeenTodayPrefix;

  /// Prefix before a HH:MM time for a yesterday last-seen.
  final String lastSeenYesterdayPrefix;

  /// Prefix before a `DD.MM.YYYY` for an older last-seen, followed by
  /// [lastSeenAtJoiner] and the HH:MM time.
  final String lastSeenDatePrefix;

  /// Joiner between the date and the HH:MM time for an older last-seen,
  /// e.g. `' um '` in `'zuletzt gesehen am 3.2.2026 um 14:30'`.
  final String lastSeenAtJoiner;
}

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _ddmmyyyy(DateTime t) =>
    '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';

/// Formats a presence into a human-readable label, or null when there is
/// nothing meaningful to show. [now] is injected for testability.
String? formatPresenceLabel(
  ChatPresence? presence, {
  required DateTime now,
  PresenceLabels labels = const PresenceLabels(),
}) {
  if (presence == null) return null;
  if (presence.customLabel != null) return presence.customLabel;
  if (presence.state == PresenceState.online) return labels.online;

  final seen = presence.lastSeen;
  if (seen == null) return null;

  final today = DateTime(now.year, now.month, now.day);
  final seenDay = DateTime(seen.year, seen.month, seen.day);
  final daysAgo = today.difference(seenDay).inDays;

  if (daysAgo == 0) return '${labels.lastSeenTodayPrefix}${_hhmm(seen)}';
  if (daysAgo == 1) return '${labels.lastSeenYesterdayPrefix}${_hhmm(seen)}';
  return '${labels.lastSeenDatePrefix}${_ddmmyyyy(seen)}'
      '${labels.lastSeenAtJoiner}${_hhmm(seen)}';
}
