import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/photo_picker.dart';
import '../data/post_repository.dart';
import '../models/post.dart';

/// Shared state of the application, and the only object the screens talk to.
class PostStore extends ChangeNotifier {
  /// Creates the store over its repository.
  PostStore(this._repository, this._photos);

  final PostRepository _repository;
  final PhotoPicker _photos;

  List<Post> _posts = const [];
  final Set<int> _selected = {};
  bool _loading = true;
  bool _loadFailed = false;

  /// Every post, newest first.
  List<Post> get posts => List.unmodifiable(_posts);

  /// Keys of the posts chosen in selection mode.
  Set<int> get selected => Set.unmodifiable(_selected);

  /// Whether posts are being loaded.
  bool get loading => _loading;

  /// Whether the last load failed.
  bool get loadFailed => _loadFailed;

  /// Whether selection mode is active.
  bool get selecting => _selected.isNotEmpty;

  /// Returns the post with [id], or null if it is not in the list.
  Post? post(int id) {
    for (final post in _posts) {
      if (post.id == id) return post;
    }
    return null;
  }

  /// Loads every post from storage and notifies the screens.
  Future<void> load() async {
    _loading = true;
    _loadFailed = false;
    notifyListeners();
    try {
      _posts = await _repository.all();
    } on Exception {
      _loadFailed = true;
    }
    _loading = false;
    notifyListeners();
  }

  /// Returns the file for the image of [post], or null if it has none.
  File? imageOf(Post post) {
    final name = post.imageName;
    return name == null ? null : _repository.imageFile(name);
  }

  /// Asks the user for a photo from the camera or the gallery.
  Future<String?> pickPhoto({required bool fromCamera}) => _photos.pick(fromCamera: fromCamera);

  /// Returns a photo lost when Android ended the application, if there is one.
  Future<String?> recoverLostPhoto() => _photos.recoverLost();

  /// Saves [post] and refreshes the list.
  Future<Post> save(Post post, {String? pickedImagePath}) async {
    final saved = await _repository.save(post, pickedImagePath: pickedImagePath);
    await _refresh();
    return saved;
  }

  /// Deletes the post with [id] and refreshes the list.
  Future<void> delete(int id) async {
    await _repository.deleteMany({id});
    _selected.remove(id);
    await _refresh();
  }

  /// Deletes the selected posts and returns how many were removed.
  Future<int> deleteSelected() async {
    final ids = Set<int>.of(_selected);
    await _repository.deleteMany(ids);
    _selected.clear();
    await _refresh();
    return ids.length;
  }

  /// Returns the posts that match [text].
  Future<List<Post>> search(String text) => _repository.search(text);

  /// Adds or removes the post with [id] from the selection.
  void toggle(int id) {
    if (!_selected.remove(id)) _selected.add(id);
    notifyListeners();
  }

  /// Selects every post.
  void selectAll() {
    _selected.addAll(_posts.map((post) => post.id!));
    notifyListeners();
  }

  /// Empties the selection, which ends selection mode.
  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  Future<void> _refresh() async {
    _posts = await _repository.all();
    notifyListeners();
  }
}
