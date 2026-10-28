import 'package:flutter_test/flutter_test.dart';
import 'package:folio/data/post_repository.dart';
import 'package:folio/models/post.dart';
import 'package:folio/state/post_store.dart';

import 'support/in_memory_post_repository.dart';
import 'support/repository_contract.dart';

class _FailingRepository extends InMemoryPostRepository {
  @override
  Future<List<Post>> all() async => throw Exception('storage unavailable');
}

void main() {
  late PostRepository repository;
  late PostStore store;
  late int notifications;

  setUp(() {
    repository = InMemoryPostRepository();
    store = PostStore(repository);
    notifications = 0;
    store.addListener(() => notifications++);
  });

  Future<List<int>> seed(int count) async {
    final ids = <int>[];
    for (var i = 0; i < count; i++) {
      ids.add((await store.save(contractPost('Post $i'))).id!);
    }
    return ids;
  }

  group('load', () {
    test('starts in the loading state', () {
      expect(store.loading, isTrue);
    });

    test('fills the list and ends the loading state', () async {
      await repository.save(contractPost('Stored'));
      await store.load();
      expect(store.loading, isFalse);
      expect(store.loadFailed, isFalse);
      expect(store.posts.single.title, 'Stored');
    });

    test('reports a failure and can be retried', () async {
      final failing = PostStore(_FailingRepository());
      await failing.load();
      expect(failing.loadFailed, isTrue);
      expect(failing.loading, isFalse);
    });
  });

  group('save', () {
    test('adds a new post to the list and notifies listeners', () async {
      final saved = await store.save(contractPost('New'));
      expect(store.post(saved.id!), saved);
      expect(notifications, greaterThan(0));
    });

    test('keeps the list in date order', () async {
      await store.save(contractPost('Old', entryDate: DateTime(2026, 1, 1)));
      await store.save(contractPost('New', entryDate: DateTime(2026, 9, 1)));
      expect(store.posts.map((post) => post.title), ['New', 'Old']);
    });
  });

  group('delete', () {
    test('removes one post', () async {
      final ids = await seed(2);
      await store.delete(ids.first);
      expect(store.post(ids.first), isNull);
      expect(store.posts, hasLength(1));
    });

    test('removes a deleted post from the selection', () async {
      final ids = await seed(2);
      store.toggle(ids.first);
      await store.delete(ids.first);
      expect(store.selected, isEmpty);
    });
  });

  group('selection', () {
    test('toggle adds and removes a post', () async {
      final ids = await seed(1);
      store.toggle(ids.single);
      expect(store.selected, {ids.single});
      expect(store.selecting, isTrue);
      store.toggle(ids.single);
      expect(store.selected, isEmpty);
      expect(store.selecting, isFalse);
    });

    test('selectAll selects every post', () async {
      final ids = await seed(3);
      store.selectAll();
      expect(store.selected, ids.toSet());
    });

    test('clearSelection leaves selection mode', () async {
      await seed(2);
      store.selectAll();
      store.clearSelection();
      expect(store.selecting, isFalse);
    });

    test('deleteSelected removes exactly the chosen posts and counts them', () async {
      final ids = await seed(3);
      store.toggle(ids[0]);
      store.toggle(ids[2]);
      expect(await store.deleteSelected(), 2);
      expect(store.posts.single.id, ids[1]);
      expect(store.selecting, isFalse);
    });
  });
}
