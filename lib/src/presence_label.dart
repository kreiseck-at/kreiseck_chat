import 'chat_participant.dart';

/// Customizable label strings for presence formatting (German defaults).
class PresenceLabels {
  /// Creates label strings.
  const PresenceLabels({
    this.online = 'Online',
    this.lastSeenTodayPrefix = 'zuletzt gesehen um ',
    this.lastSeenYesterdayPrefix = 'zuletzt gesehen gestern um ',
    this.lastSeenDatePrefix = 'zuletzt gesehen am ',
  });

  /// Shown when online.
  final String online;

  /// Prefix before a HH:MM time for a same-day last-seen.
  final String lastSeenTodayPrefix;

  /// Prefix before a HH:MM time for a yesterday last-seen.
  final String lastSeenYesterdayPrefix;

  /// Prefix before a `DD.MM.YYYY um HH:MM` for older last-seen.
  final String lastSeenDatePrefix;
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
  return '${labels.lastSeenDatePrefix}${_ddmmyyyy(seen)} um ${_hhmm(seen)}';
}
