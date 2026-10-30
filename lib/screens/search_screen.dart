import 'dart:async';

import 'package:flutter/material.dart';

import '../models/post.dart';
import '../state/post_store.dart';
import '../widgets/empty_state.dart';
import '../widgets/post_tile.dart';
import 'post_detail_screen.dart';

/// Searches the title and body of every post as the user types.
class SearchScreen extends StatefulWidget {
  /// Creates the search screen.
  const SearchScreen({super.key, required this.store});

  /// Shared state of the application.
  final PostStore store;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const Duration _pause = Duration(milliseconds: 250);

  final _field = TextEditingController();
  Timer? _timer;
  List<Post> _results = const [];
  String _query = '';
  int _latestSearch = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _field.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _timer?.cancel();
    if (text.trim().isEmpty) {
      _clear();
    } else {
      _timer = Timer(_pause, () => _search(text));
    }
  }

  void _clear() {
    _latestSearch++;
    setState(() {
      _query = '';
      _results = const [];
    });
  }

  Future<List<Post>> _search(String text) async {
    final search = ++_latestSearch;
    final results = await widget.store.search(text);
    if (mounted && search == _latestSearch) {
      setState(() {
        _query = text.trim();
        _results = results;
      });
    }
    return results;
  }

  Future<void> _onSubmitted(String text) async {
    _timer?.cancel();
    if (text.trim().isEmpty) return;
    final results = await _search(text);
    if (results.length == 1) await _open(results.single);
  }

  Future<void> _open(Post post) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostDetailScreen(store: widget.store, postId: post.id!),
      ),
    );
    if (mounted && _field.text.trim().isNotEmpty) await _search(_field.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _field,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search posts',
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: _onChanged,
          onSubmitted: _onSubmitted,
        ),
        actions: [
          ListenableBuilder(
            listenable: _field,
            builder: (context, _) => _field.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _field.clear();
                      _onChanged('');
                    },
                  ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: 'Search your posts',
        message: 'Type a word from the title or the text of any post.',
      );
    }
    if (_results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No posts match',
        message: 'Nothing contains "$_query". Try a different word.',
      );
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final post = _results[index];
        return PostTile(
          post: post,
          image: widget.store.imageOf(post),
          query: _query,
          onTap: () => _open(post),
        );
      },
    );
  }
}
