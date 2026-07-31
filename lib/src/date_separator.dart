import 'package:flutter/material.dart';

import 'chat_strings.dart';
import 'chat_theme.dart';

/// A centered day-boundary pill ("Heute" / "Gestern" / date).
class DateSeparator extends StatelessWidget {
  /// Creates a date separator.
  const DateSeparator({
    super.key,
    required this.date,
    required this.theme,
    this.now,
    this.labelBuilder,
    this.strings,
  });

  /// The day this separator introduces (date-only).
  final DateTime date;

  /// Visual configuration.
  final ChatTheme theme;

  /// Injectable "now" for testability; defaults to [DateTime.now].
  final DateTime? now;

  /// Optional custom label builder `(date, now) -> String`.
  final String Function(DateTime date, DateTime? now)? labelBuilder;

  /// Overrides the words used by this separator. Left null, they follow the
  /// ambient locale (see [ChatStrings.of]).
  final ChatStrings? strings;

  String _defaultLabel(DateTime d, DateTime ref, ChatStrings strings) {
    final today = DateTime(ref.year, ref.month, ref.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return strings.today;
    if (diff == 1) return strings.yesterday;
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ref = now ?? DateTime.now();
    final resolved = ChatStrings.of(context, override: strings);
    final label =
        labelBuilder?.call(date, now) ?? _defaultLabel(date, ref, resolved);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: theme.colors.dateSeparatorBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: theme.typography.dateSeparator
              .copyWith(color: theme.colors.dateSeparatorText),
        ),
      ),
    );
  }
}
