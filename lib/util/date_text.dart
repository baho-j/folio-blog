const List<String> _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Formats a date as `27 October 2026`.
String longDate(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';

/// Formats a date as `27 Oct 2026`.
String shortDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1].substring(0, 3)} ${date.year}';
