import 'package:flutter/material.dart';

import '../state/post_store.dart';
import '../widgets/empty_state.dart';
import '../widgets/post_tile.dart';
import 'post_detail_screen.dart';

/// Home screen, which lists every post, newest first.
class PostListScreen extends StatefulWidget {
  /// Creates the home screen.
  const PostListScreen({super.key, required this.store});

  /// Shared state of the application.
  final PostStore store;

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  PostStore get _store => widget.store;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Folio')),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_store.loading) {
      return const EmptyState(
        icon: Icons.hourglass_empty,
        title: 'Opening your posts',
        message: 'This takes a moment.',
      );
    }
    if (_store.loadFailed) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Your posts could not be opened',
        message: 'They are still on this device. Try opening them again.',
        actionLabel: 'Try again',
        onAction: _store.load,
      );
    }
    if (_store.posts.isEmpty) {
      return const EmptyState(
        icon: Icons.edit_note,
        title: 'Nothing here yet',
        message: 'Posts you write are kept on this device.',
      );
    }
    final posts = _store.posts;
    return ListView.separated(
      itemCount: posts.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final post = posts[index];
        return PostTile(post: post, onTap: () => _open(post.id!));
      },
    );
  }

  void _open(int id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostDetailScreen(store: _store, postId: id),
      ),
    );
  }
}
