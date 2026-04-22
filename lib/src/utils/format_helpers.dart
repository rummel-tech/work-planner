/// Shared date and time formatting utilities.
///
/// These replace the many `_formatDate` / `_formatTime` helpers that were
/// duplicated across screens.

/// Formats a [DateTime] as `M/D/YYYY`. Returns [fallback] if null.
String formatDate(DateTime? date, {String fallback = 'Not set'}) {
  if (date == null) return fallback;
  return '${date.month}/${date.day}/${date.year}';
}

/// Formats a date range `M/D - M/D`
String formatDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) {
    return 'No dates set';
  }
  final startStr = start != null ? '${start.month}/${start.day}' : '?';
  final endStr = end != null ? '${end.month}/${end.day}' : '?';
  return '$startStr - $endStr';
}

/// Formats a [DateTime] as `H:MM AM/PM`.
String formatTime(DateTime? time) {
  if (time == null) return '';
  final hour = time.hour == 0
      ? 12
      : (time.hour > 12 ? time.hour - 12 : time.hour);
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

/// Formats a [TimeOfDay]-style pair as `H:MM AM/PM`.
String formatTimeOfDay(int hour, int minute) {
  final h = hour == 0
      ? 12
      : (hour > 12 ? hour - 12 : hour);
  final m = minute.toString().padLeft(2, '0');
  final period = hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $period';
}

/// Formats a duration in minutes as `Xh Ym` or `Xm`.
String formatDuration(int? minutes) {
  if (minutes == null) return '';
  if (minutes < 60) return '${minutes}m';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
}

/// Formats an ISO-8601 date string (YYYY-MM-DD) from a [DateTime].
String toDateString(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
