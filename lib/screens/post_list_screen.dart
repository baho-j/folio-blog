import 'package:flutter/material.dart';

import '../state/post_store.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/post_tile.dart';
import 'post_detail_screen.dart';
import 'post_editor_screen.dart';
import 'search_screen.dart';

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
    _start();
  }

  Future<void> _start() async {
    await _store.load();
    final photo = await _store.recoverLostPhoto();
    if (photo == null || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Your last photo was recovered')));
    _write(recoveredImagePath: photo);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final selecting = _store.selecting;
        return PopScope<void>(
          canPop: !selecting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _store.clearSelection();
          },
          child: Scaffold(
            appBar: selecting ? _buildSelectionBar() : _buildBrowsingBar(),
            body: _buildBody(),
            floatingActionButton: _store.posts.isEmpty || selecting
                ? null
                : FloatingActionButton.extended(
                    onPressed: _write,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('New post'),
                  ),
          ),
        );
      },
    );
  }

  AppBar _buildBrowsingBar() {
    return AppBar(
      title: const Text('Folio'),
      actions: [IconButton(tooltip: 'Search', icon: const Icon(Icons.search), onPressed: _search)],
    );
  }

  AppBar _buildSelectionBar() {
    return AppBar(
      leading: IconButton(
        tooltip: 'Cancel selection',
        icon: const Icon(Icons.close),
        onPressed: _store.clearSelection,
      ),
      title: Text('${_store.selected.length} selected'),
      actions: [
        IconButton(
          tooltip: 'Select all',
          icon: const Icon(Icons.select_all),
          onPressed: _store.selectAll,
        ),
        IconButton(
          tooltip: 'Delete selected',
          icon: const Icon(Icons.delete_outline),
          onPressed: _deleteSelected,
        ),
      ],
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
      return EmptyState(
        icon: Icons.edit_note,
        title: 'Nothing here yet',
        message: 'Posts you write are kept on this device.',
        actionLabel: 'Write your first post',
        onAction: _write,
      );
    }
    final posts = _store.posts;
    return ListView.separated(
      itemCount: posts.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final post = posts[index];
        final id = post.id!;
        return PostTile(
          post: post,
          image: _store.imageOf(post),
          selected: _store.selected.contains(id),
          onTap: () => _store.selecting ? _store.toggle(id) : _open(id),
          onLongPress: () => _store.toggle(id),
        );
      },
    );
  }

  Future<void> _deleteSelected() async {
    final count = _store.selected.length;
    if (!await confirmDelete(context, count: count) || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final deleted = await _store.deleteSelected();
      messenger.showSnackBar(SnackBar(content: Text('${postCount(deleted)} deleted')));
    } on Exception {
      messenger.showSnackBar(const SnackBar(content: Text('The posts could not be deleted')));
    }
  }

  void _write({String? recoveredImagePath}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostEditorScreen(store: _store, initialImagePath: recoveredImagePath),
      ),
    );
  }

  void _search() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => SearchScreen(store: _store)));
  }

  void _open(int id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostDetailScreen(store: _store, postId: id),
      ),
    );
  }
}
