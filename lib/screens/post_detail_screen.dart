import 'package:flutter/material.dart';

import '../models/post.dart';
import '../state/post_store.dart';
import '../theme/app_theme.dart';
import '../util/date_text.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/empty_state.dart';
import 'post_editor_screen.dart';

/// Shows one post in full.
class PostDetailScreen extends StatefulWidget {
  /// Creates the screen for the post with [postId].
  const PostDetailScreen({super.key, required this.store, required this.postId});

  /// Shared state of the application.
  final PostStore store;

  /// Key of the post to show.
  final int postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  // Keeps the screen filled while it closes after a deletion.
  Post? _lastSeen;

  void _edit(Post post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostEditorScreen(store: widget.store, post: post),
      ),
    );
  }

  Future<void> _delete() async {
    if (!await confirmDelete(context, count: 1) || !mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.store.delete(widget.postId);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('1 post deleted')));
    } on Exception {
      messenger.showSnackBar(const SnackBar(content: Text('The post could not be deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final post = widget.store.post(widget.postId) ?? _lastSeen;
        _lastSeen = post;
        return Scaffold(
          appBar: AppBar(
            actions: [
              if (post != null) ...[
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(post),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _delete,
                ),
              ],
            ],
          ),
          body: post == null
              ? const EmptyState(
                  icon: Icons.search_off,
                  title: 'This post is no longer here',
                  message: 'It may have been deleted.',
                )
              : _PostBody(post: post),
        );
      },
    );
  }
}

class _PostBody extends StatelessWidget {
  const _PostBody({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Text(
          longDate(post.entryDate),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.small),
        Text(post.title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.large),
        SelectableText(post.body, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
