import 'package:flutter/material.dart';

import 'app.dart';
import 'data/blog_database.dart';
import 'data/sqlite_post_repository.dart';
import 'state/post_store.dart';

/// Starts the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await BlogDatabase.open();
  runApp(FolioApp(store: PostStore(SqlitePostRepository(database))));
}
