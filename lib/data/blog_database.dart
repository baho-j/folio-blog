// Third-party: path (BSD-3-Clause), joins file paths the same way on both platforms
import 'package:path/path.dart' as p;
// Third-party: path_provider (BSD-3-Clause), locates the documents directory on each platform
import 'package:path_provider/path_provider.dart';
// Third-party: sqflite (BSD-2-Clause), the standard SQLite plugin for Flutter
import 'package:sqflite/sqflite.dart';

/// Opens the SQLite database and defines its schema.
abstract final class BlogDatabase {
  /// Name of the database file in the documents directory.
  static const String fileName = 'folio.db';

  /// Current schema version, recorded in SQLite's `user_version`.
  static const int version = 1;

  /// Statement that creates the posts table.
  static const String createPostsTable = '''
    CREATE TABLE posts (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      title       TEXT    NOT NULL,
      body        TEXT    NOT NULL,
      entry_date  INTEGER NOT NULL,
      image_name  TEXT,
      created_at  INTEGER NOT NULL,
      updated_at  INTEGER NOT NULL
    )
  ''';

  /// Statement that indexes posts by date of entry, newest first.
  static const String createEntryDateIndex =
      'CREATE INDEX idx_posts_entry_date ON posts (entry_date DESC)';

  /// Opens the database at [path], or at the default location when it is null.
  static Future<Database> open({String? path}) async {
    final location = path ?? p.join((await getApplicationDocumentsDirectory()).path, fileName);
    return openDatabase(location, version: version, onCreate: onCreate);
  }

  /// Creates the schema in a new database.
  static Future<void> onCreate(Database db, int version) async {
    await db.execute(createPostsTable);
    await db.execute(createEntryDateIndex);
  }
}
