import 'package:flutter/material.dart';

/// Writes a number of posts in words, such as `1 post` or `3 posts`.
String postCount(int count) => count == 1 ? '1 post' : '$count posts';

/// Asks the user to confirm deleting [count] posts, and returns their answer.
Future<bool> confirmDelete(BuildContext context, {required int count}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDeleteDialog(count: count),
  );
  return confirmed ?? false;
}

/// Dialog that states how many posts a deletion will remove.
class ConfirmDeleteDialog extends StatelessWidget {
  /// Creates a dialog for [count] posts.
  const ConfirmDeleteDialog({super.key, required this.count});

  /// Number of posts the deletion will remove.
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text('Delete ${postCount(count)}?'),
      content: Text(
        count == 1
            ? 'The post and its image will be removed from this device. This cannot be undone.'
            : 'These posts and their images will be removed from this device. '
                  'This cannot be undone.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
