import 'dart:io';

import 'package:flutter/material.dart';

/// Shows an image file, with a placeholder if the file cannot be read.
class PostImage extends StatelessWidget {
  /// Creates a view of [file].
  const PostImage({
    super.key,
    required this.file,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.label,
  });

  /// The image file to show.
  final File file;

  /// Width of the image, or null to take it from the parent.
  final double? width;

  /// Height of the image, or null to take it from the file.
  final double? height;

  /// How the image fills its space.
  final BoxFit fit;

  /// Width to decode at, which saves memory for thumbnails.
  final int? cacheWidth;

  /// Description read out by screen readers.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      semanticLabel: label,
      errorBuilder: (_, _, _) => Container(
        width: width,
        height: height ?? 200,
        color: scheme.surfaceContainer,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
