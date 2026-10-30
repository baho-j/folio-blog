import 'dart:io';

import 'package:flutter/material.dart';

import '../models/post.dart';
import '../theme/app_theme.dart';
import '../util/date_text.dart';
import '../util/search_query.dart';
import 'highlighted_text.dart';
import 'post_image.dart';

/// Row of the post list, with a square thumbnail, title, date and excerpt.
class PostTile extends StatelessWidget {
  /// Creates a row for [post].
  const PostTile({
    super.key,
    required this.post,
    this.image,
    this.query = '',
    this.onTap,
    this.onLongPress,
  });

  /// Side of the square thumbnail.
  static const double thumbnailSize = 64;

  /// The post to show.
  final Post post;

  /// Thumbnail file, or null when the post has no image.
  final File? image;

  /// Search text to mark, empty outside search.
  final String query;

  /// Called when the row is tapped.
  final VoidCallback? onTap;

  /// Called when the row is held.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.medium,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(image: image),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HighlightedText(
                    post.title,
                    query: query,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shortDate(post.entryDate),
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  HighlightedText(
                    excerptAround(post.excerpt, query),
                    query: query,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.image});

  final File? image;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: PostTile.thumbnailSize,
        child: image == null
            ? ColoredBox(
                color: scheme.surfaceContainer,
                child: Icon(Icons.notes, color: scheme.onSurfaceVariant),
              )
            : PostImage(
                file: image!,
                width: PostTile.thumbnailSize,
                height: PostTile.thumbnailSize,
                cacheWidth: 256,
              ),
      ),
    );
  }
}
