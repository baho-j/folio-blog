import '../models/post.dart';

/// Storage of posts, independent of how they are held.
abstract interface class PostRepository {
  /// Newest date of entry first, then the most recently added.
  Future<List<Post>> all();

  /// Returns the post with [id], or null if there is none.
  Future<Post?> find(int id);

  /// Stores [post] and returns the saved version.
  Future<Post> save(Post post);

  /// Deletes the posts with the given [ids].
  Future<void> deleteMany(Set<int> ids);
}
