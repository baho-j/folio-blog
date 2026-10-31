import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/app.dart';
import 'package:folio/data/blog_database.dart';
import 'package:folio/data/image_store.dart';
import 'package:folio/data/post_repository.dart';
import 'package:folio/data/sqlite_post_repository.dart';
import 'package:folio/state/post_store.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../test/support/fake_photo_picker.dart';
import '../test/support/repository_contract.dart';

/// A real database and image folder in a temporary directory.
class _Device {
  _Device(this.root, this.database, this.images);

  static Future<_Device> create() async {
    final temporary = await getTemporaryDirectory();
    final root = await temporary.createTemp('folio_test');
    final database = await BlogDatabase.open(path: p.join(root.path, BlogDatabase.fileName));
    return _Device(root, database, ImageStore(Directory(p.join(root.path, 'images'))));
  }

  final Directory root;
  Database database;
  final ImageStore images;

  PostRepository get repository => SqlitePostRepository(database, images);

  Future<String> newPhoto() async {
    final file = File(p.join(root.path, 'photo_${DateTime.now().microsecondsSinceEpoch}.jpg'));
    await file.writeAsBytes([1, 2, 3]);
    return file.path;
  }

  Future<void> reopen() async {
    final path = database.path;
    await database.close();
    database = await BlogDatabase.open(path: path);
  }

  Future<void> dispose() async {
    await database.close();
    await root.delete(recursive: true);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _Device device;

  setUp(() async => device = await _Device.create());
  tearDown(() => device.dispose());

  Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  Future<PostStore> pumpFolio(WidgetTester tester, {FakePhotoPicker? photos}) async {
    final store = PostStore(device.repository, photos ?? FakePhotoPicker());
    await tester.pumpWidget(FolioApp(store: store));
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> writePost(WidgetTester tester, String title, String body) async {
    await tester.tap(
      find.text('Write your first post').evaluate().isEmpty
          ? find.text('New post')
          : find.text('Write your first post'),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), title);
    await tester.enterText(find.widgetWithText(TextFormField, 'Post'), body);
    await tester.tap(find.text('Save'));
    await pumpUntil(tester, find.text(title));
    await tester.pumpAndSettle();
  }

  Future<void> confirmDeletion(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  group('SqlitePostRepository', () {
    repositoryContract(
      () async => ContractSubject(
        repository: device.repository,
        newPhoto: device.newPhoto,
        hasImage: (name) => device.images.fileFor(name).exists(),
      ),
    );

    test('a failed save leaves no image file behind', () async {
      final photo = await device.newPhoto();
      await device.database.execute('DROP TABLE posts');
      await expectLater(
        device.repository.save(contractPost('Fails'), pickedImagePath: photo),
        throwsA(isA<Exception>()),
      );
      expect(await device.images.folder.list().isEmpty, isTrue);
    });

    test('posts survive closing and reopening the database', () async {
      final saved = await device.repository.save(contractPost('Kept'));
      await device.reopen();
      final found = await device.repository.find(saved.id!);
      expect(found!.title, 'Kept');
    });

    test('500 posts list and search within 300 milliseconds', () async {
      for (var i = 0; i < 500; i++) {
        await device.repository.save(contractPost('Post $i', body: 'A body of ordinary text $i'));
      }
      final watch = Stopwatch()..start();
      final posts = await device.repository.all();
      final listed = watch.elapsedMilliseconds;
      watch.reset();
      final matches = await device.repository.search('ordinary text 499');
      final searched = watch.elapsedMilliseconds;
      debugPrint('list ${listed}ms, search ${searched}ms');
      expect(posts, hasLength(500));
      expect(matches, hasLength(1));
      expect(listed, lessThan(300));
      expect(searched, lessThan(300));
    });
  });

  testWidgets('create a post and find it after a restart', (tester) async {
    await pumpFolio(tester);
    await writePost(tester, 'Lake Kivu', 'Morning on the water');
    expect(find.text('Lake Kivu'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await device.reopen();
    await pumpFolio(tester);
    await pumpUntil(tester, find.text('Lake Kivu'));
    expect(find.text('Lake Kivu'), findsOneWidget);
  });

  testWidgets('edit a post', (tester) async {
    await pumpFolio(tester);
    await writePost(tester, 'Lake Kivu', 'Morning on the water');
    await tester.tap(find.text('Lake Kivu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Lake Kivu'), 'Lake Muhazi');
    await tester.tap(find.text('Save'));
    await pumpUntil(tester, find.text('Lake Muhazi'));
    expect((await device.repository.all()).single.title, 'Lake Muhazi');
  });

  testWidgets('delete a post with its image', (tester) async {
    final photo = await device.newPhoto();
    final saved = await device.repository.save(contractPost('Going'), pickedImagePath: photo);
    await pumpFolio(tester);
    await pumpUntil(tester, find.text('Going'));
    await tester.tap(find.text('Going'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await confirmDeletion(tester);
    await pumpUntil(tester, find.text('Nothing here yet'));
    expect(await device.repository.all(), isEmpty);
    expect(await device.images.fileFor(saved.imageName!).exists(), isFalse);
  });

  testWidgets('delete a chosen group of posts', (tester) async {
    for (final title in ['One', 'Two', 'Three']) {
      await device.repository.save(contractPost(title));
    }
    await pumpFolio(tester);
    await pumpUntil(tester, find.text('Three'));
    await tester.longPress(find.text('One'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Three'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete selected'));
    await tester.pumpAndSettle();
    expect(find.text('Delete 2 posts?'), findsOneWidget);
    await confirmDeletion(tester);
    await pumpUntil(tester, find.text('2 posts deleted'));
    expect((await device.repository.all()).single.title, 'Two');
  });

  testWidgets('search with a wildcard character and open the only match', (tester) async {
    await device.repository.save(contractPost('Prices', body: 'Up 100% this year'));
    await device.repository.save(contractPost('Weather', body: 'Up on the hill'));
    await pumpFolio(tester);
    await pumpUntil(tester, find.text('Prices'));
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '100%');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await pumpUntil(tester, find.text('Up 100% this year'));
    expect(find.text('Up 100% this year'), findsOneWidget);
  });
}
