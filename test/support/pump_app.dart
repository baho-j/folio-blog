import 'package:flutter_test/flutter_test.dart';
import 'package:folio/app.dart';
import 'package:folio/data/photo_picker.dart';
import 'package:folio/models/post.dart';
import 'package:folio/state/post_store.dart';

import 'fake_photo_picker.dart';
import 'in_memory_post_repository.dart';

/// Starts the application over a repository holding [posts].
Future<PostStore> pumpApp(
  WidgetTester tester, {
  List<Post> posts = const [],
  PhotoPicker? photos,
}) async {
  final repository = InMemoryPostRepository();
  for (final post in posts) {
    await repository.save(post);
  }
  final store = PostStore(repository, photos ?? FakePhotoPicker());
  await tester.pumpWidget(FolioApp(store: store));
  await tester.pumpAndSettle();
  return store;
}
