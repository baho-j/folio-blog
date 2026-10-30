/// Part of a text, marked if it matches the search.
typedef TextPart = ({String text, bool isMatch});

/// Turns [text] into a LIKE pattern in which `%` and `_` are matched literally.
String likePattern(String text) {
  final escaped = text.trim().replaceAllMapped(RegExp(r'[\\%_]'), (match) => '\\${match[0]}');
  return '%$escaped%';
}

/// Splits [text] around each case-insensitive occurrence of [query].
List<TextPart> splitMatches(String text, String query) {
  final needle = query.trim().toLowerCase();
  final haystack = text.toLowerCase();
  if (needle.isEmpty || haystack.length != text.length) return [(text: text, isMatch: false)];

  final parts = <TextPart>[];
  var start = 0;
  var index = haystack.indexOf(needle);
  while (index != -1) {
    if (index > start) parts.add((text: text.substring(start, index), isMatch: false));
    start = index + needle.length;
    parts.add((text: text.substring(index, start), isMatch: true));
    index = haystack.indexOf(needle, start);
  }
  if (start < text.length) parts.add((text: text.substring(start), isMatch: false));
  return parts;
}

/// Shortens the start of [text] so that the first match of [query] stays visible.
String excerptAround(String text, String query, {int lead = 30}) {
  final index = text.toLowerCase().indexOf(query.trim().toLowerCase());
  if (index <= lead) return text;
  final start = text.indexOf(' ', index - lead);
  return '…${text.substring(start == -1 || start >= index ? index : start + 1)}';
}
