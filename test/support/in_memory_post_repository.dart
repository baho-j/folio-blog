import 'dart:io';

import 'package:folio/data/post_repository.dart';
import 'package:folio/models/post.dart';

/// Repository held in memory, which gives the tests the behaviour of the real one.
class InMemoryPostRepository implements PostRepository {
  final Map<int, Post> _posts = {};
  int _nextId = 1;
  int _nextImage = 1;

  /// Names of the image files that would exist on a device.
  final Set<String> imageNames = {};

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
  Future<Post> save(Post post, {String? pickedImagePath}) async {
    final previous = post.id == null ? null : _posts[post.id!]?.imageName;
    final newImage = pickedImagePath == null ? null : 'image_${_nextImage++}.jpg';
    if (newImage != null) imageNames.add(newImage);
    final now = DateTime.now();
    final stored = post.copyWith(
      id: post.id ?? _nextId++,
      imageName: newImage,
      createdAt: post.id == null ? now : null,
      updatedAt: now,
    );
    if (previous != stored.imageName) imageNames.remove(previous);
    return _posts[stored.id!] = stored;
  }

  @override
  Future<void> deleteMany(Set<int> ids) async {
    for (final id in ids) {
      imageNames.remove(_posts.remove(id)?.imageName);
    }
  }

  @override
  File imageFile(String name) => File(name);
}
