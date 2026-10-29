import 'dart:io';

// Third-party: sqflite (BSD-2-Clause), the standard SQLite plugin for Flutter
import 'package:sqflite/sqflite.dart';

import '../models/post.dart';
import 'image_store.dart';
import 'post_repository.dart';

/// Stores posts in SQLite and their images through [ImageStore].
class SqlitePostRepository implements PostRepository {
  /// Creates the repository over its storage.
  SqlitePostRepository(this._db, this._images);

  static const String _table = 'posts';
  static const String _newestFirst = 'entry_date DESC, id DESC';

  final Database _db;
  final ImageStore _images;

  @override
  Future<List<Post>> all() async {
    final rows = await _db.query(_table, orderBy: _newestFirst);
    return rows.map(Post.fromRow).toList();
  }

  @override
  Future<Post?> find(int id) async {
    final rows = await _db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Post.fromRow(rows.single);
  }

  @override
  Future<Post> save(Post post, {String? pickedImagePath}) async {
    final previous = post.id == null ? null : (await find(post.id!))?.imageName;
    final newImage = pickedImagePath == null ? null : await _images.import(pickedImagePath);
    final Post saved;
    try {
      saved = await _write(post.copyWith(imageName: newImage));
    } on Exception {
      if (newImage != null) await _images.delete(newImage);
      rethrow;
    }
    if (previous != null && previous != saved.imageName) await _removeFile(previous);
    return saved;
  }

  Future<Post> _write(Post post) {
    final now = DateTime.now();
    final stamped = post.copyWith(updatedAt: now, createdAt: post.id == null ? now : null);
    return _db.transaction((txn) async {
      if (stamped.id == null) {
        return stamped.copyWith(id: await txn.insert(_table, stamped.toRow()));
      }
      await txn.update(_table, stamped.toRow(), where: 'id = ?', whereArgs: [stamped.id]);
      return stamped;
    });
  }

  @override
  Future<void> deleteMany(Set<int> ids) async {
    if (ids.isEmpty) return;
    final slots = List.filled(ids.length, '?').join(', ');
    final where = 'id IN ($slots)';
    final args = ids.toList();
    final rows = await _db.query(_table, columns: ['image_name'], where: where, whereArgs: args);
    await _db.transaction((txn) => txn.delete(_table, where: where, whereArgs: args));
    for (final row in rows) {
      final name = row['image_name'] as String?;
      if (name != null) await _removeFile(name);
    }
  }

  /// The rows are already committed, so a leftover file must not fail the operation.
  Future<void> _removeFile(String name) async {
    try {
      await _images.delete(name);
    } on FileSystemException {
      return;
    }
  }

  @override
  File imageFile(String name) => _images.fileFor(name);
}
