import 'package:flutter/material.dart';

import '../util/search_query.dart';

/// Text with every occurrence of [query] marked in the accent colour.
class HighlightedText extends StatelessWidget {
  /// Creates text that marks [query].
  const HighlightedText(this.text, {super.key, this.query = '', this.style, this.maxLines});

  /// The text to show.
  final String text;

  /// The search text to mark.
  final String query;

  /// Style of the unmarked text.
  final TextStyle? style;

  /// Most lines to show, or null for no limit.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mark = TextStyle(
      backgroundColor: scheme.primaryContainer,
      color: scheme.onPrimaryContainer,
    );
    return Text.rich(
      TextSpan(
        children: [
          for (final part in splitMatches(text, query))
            TextSpan(text: part.text, style: part.isMatch ? mark : null),
        ],
      ),
      style: style,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
