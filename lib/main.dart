import 'package:flutter/material.dart';

import 'app.dart';
import 'data/blog_database.dart';
import 'data/image_store.dart';
import 'data/photo_picker.dart';
import 'data/sqlite_post_repository.dart';
import 'state/post_store.dart';

/// Starts the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await BlogDatabase.open();
  final images = await ImageStore.open();
  final repository = SqlitePostRepository(database, images);
  runApp(FolioApp(store: PostStore(repository, PhotoPicker())));
}
