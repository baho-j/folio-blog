import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:folio/data/image_store.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late ImageStore store;
  late File source;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('folio_images');
    store = ImageStore(Directory(p.join(root.path, 'images')));
    source = File(p.join(root.path, 'picked.JPG'));
    await source.writeAsBytes([1, 2, 3]);
  });

  tearDown(() => root.delete(recursive: true));

  test('import copies the file and returns a name rather than a path', () async {
    final name = await store.import(source.path);
    expect(p.basename(name), name);
    expect(await store.fileFor(name).readAsBytes(), [1, 2, 3]);
    expect(await source.exists(), isTrue);
  });

  test('import gives every file its own name', () async {
    final first = await store.import(source.path);
    final second = await store.import(source.path);
    expect(first, isNot(second));
  });

  test('import keeps the extension in lower case', () async {
    expect(p.extension(await store.import(source.path)), '.jpg');
  });

  test('import reports a missing source and leaves nothing behind', () async {
    await expectLater(
      store.import(p.join(root.path, 'missing.jpg')),
      throwsA(isA<FileSystemException>()),
    );
    expect(await store.folder.list().isEmpty, isTrue);
  });

  test('delete removes the file', () async {
    final name = await store.import(source.path);
    await store.delete(name);
    expect(await store.fileFor(name).exists(), isFalse);
  });

  test('delete ignores a file that does not exist', () async {
    await expectLater(store.delete('missing.jpg'), completes);
  });
}
