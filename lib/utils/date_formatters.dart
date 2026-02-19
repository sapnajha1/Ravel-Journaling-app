const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String formatDayMonth(DateTime date) {
  return '${date.day} ${_months[date.month - 1]}';
}

/// Returns ordinal suffix for day, e.g. 1 -> "1st", 2 -> "2nd".
String ordinal(int day) {
  if (day >= 11 && day <= 13) return '${day}th';
  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}

/// Section label for history lists, e.g. "Today, 19th February 2025" or "19th February 2025".
String formatSectionLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final isToday = date == today;
  final monthName = _monthsLong[date.month - 1];
  final label = '${ordinal(date.day)} $monthName ${date.year}';
  return isToday ? 'Today, $label' : label;
}

/// Full date label for detail screens, e.g. "19th Feb 2025".
String formatFullDate(DateTime date) {
  return '${ordinal(date.day)} ${_months[date.month - 1]} ${date.year}';
}

/// Top bar date for detail: "Today · 19th Feb" or "19th Feb 2025".
String formatDetailDateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final entryDay = DateTime(date.year, date.month, date.day);
  final part = '${ordinal(date.day)} ${_months[date.month - 1]}';
  return entryDay == today ? 'Today · $part' : '$part ${date.year}';
}
