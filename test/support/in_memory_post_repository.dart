import 'package:folio/data/post_repository.dart';
import 'package:folio/models/post.dart';

/// Repository held in memory, which gives the tests the behaviour of the real one.
class InMemoryPostRepository implements PostRepository {
  final Map<int, Post> _posts = {};
  int _nextId = 1;

  @override
  Future<List<Post>> all() async {
    return _posts.values.toList()..sort((a, b) {
      final byDate = b.entryDate.compareTo(a.entryDate);
      return byDate != 0 ? byDate : b.id!.compareTo(a.id!);
    });
  }

  @override
  Future<Post?> find(int id) async => _posts[id];

  @override
  Future<Post> save(Post post) async {
    final now = DateTime.now();
    final stored = post.copyWith(
      id: post.id ?? _nextId++,
      createdAt: post.id == null ? now : null,
      updatedAt: now,
    );
    return _posts[stored.id!] = stored;
  }

  @override
  Future<void> deleteMany(Set<int> ids) async => _posts.removeWhere((id, _) => ids.contains(id));
}
