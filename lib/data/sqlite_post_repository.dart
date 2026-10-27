// Third-party: sqflite (BSD-2-Clause), the standard SQLite plugin for Flutter
import 'package:sqflite/sqflite.dart';

import '../models/post.dart';
import 'post_repository.dart';

/// Stores posts in the SQLite database.
class SqlitePostRepository implements PostRepository {
  /// Creates a repository over the open database [_db].
  SqlitePostRepository(this._db);

  static const String _table = 'posts';
  static const String _newestFirst = 'entry_date DESC, id DESC';

  final Database _db;

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
  Future<Post> save(Post post) {
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
    await _db.transaction(
      (txn) => txn.delete(_table, where: 'id IN ($slots)', whereArgs: ids.toList()),
    );
  }
}
