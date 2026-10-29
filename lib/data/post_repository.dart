import 'dart:io';

import '../models/post.dart';

/// Storage of posts and their images, independent of how they are held.
abstract interface class PostRepository {
  /// Newest date of entry first, then the most recently added.
  Future<List<Post>> all();

  /// Returns the post with [id], or null if there is none.
  Future<Post?> find(int id);

  /// Stores [post], first taking in the photo at [pickedImagePath] if one is given.
  Future<Post> save(Post post, {String? pickedImagePath});

  /// Deletes the posts with the given [ids].
  Future<void> deleteMany(Set<int> ids);

  /// Returns the file for the stored image called [name].
  File imageFile(String name);
}
