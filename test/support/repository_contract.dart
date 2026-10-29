import 'package:flutter_test/flutter_test.dart';
import 'package:folio/data/post_repository.dart';
import 'package:folio/models/post.dart';

/// Builds an unsaved post for the contract tests.
Post contractPost(String title, {DateTime? entryDate, String body = 'Body text'}) {
  final moment = DateTime(2026, 10, 27, 12);
  return Post(
    title: title,
    body: body,
    entryDate: entryDate ?? DateTime(2026, 10, 27),
    createdAt: moment,
    updatedAt: moment,
  );
}

/// A repository under test, with the means to create and find its photos.
class ContractSubject {
  /// Creates a subject from its three parts.
  const ContractSubject({required this.repository, required this.newPhoto, required this.hasImage});

  /// The repository under test.
  final PostRepository repository;

  /// Creates a photo file and returns its path.
  final Future<String> Function() newPhoto;

  /// Whether a stored image called [name] exists.
  final Future<bool> Function(String name) hasImage;
}

/// Defines the behaviour every [PostRepository] must show.
void repositoryContract(Future<ContractSubject> Function() create) {
  late ContractSubject subject;
  late PostRepository repository;

  setUp(() async {
    subject = await create();
    repository = subject.repository;
  });

  test('save assigns an id and stores every field', () async {
    final saved = await repository.save(contractPost('First', body: 'Exact text'));
    expect(saved.id, isNotNull);
    final found = await repository.find(saved.id!);
    expect(found!.title, 'First');
    expect(found.body, 'Exact text');
    expect(found.entryDate, DateTime(2026, 10, 27));
  });

  test('save updates an existing post without adding another', () async {
    final saved = await repository.save(contractPost('Before'));
    await repository.save(saved.copyWith(title: 'After'));
    final posts = await repository.all();
    expect(posts.single.title, 'After');
  });

  test('save keeps the creation time and moves the update time', () async {
    final saved = await repository.save(contractPost('Post'));
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final updated = await repository.save(saved.copyWith(title: 'Changed'));
    expect(updated.createdAt, saved.createdAt);
    expect(updated.updatedAt.isAfter(saved.updatedAt), isTrue);
  });

  test('all returns the newest date of entry first', () async {
    await repository.save(contractPost('Old', entryDate: DateTime(2026, 1, 1)));
    await repository.save(contractPost('New', entryDate: DateTime(2026, 10, 1)));
    await repository.save(contractPost('Middle', entryDate: DateTime(2026, 5, 1)));
    final titles = (await repository.all()).map((post) => post.title);
    expect(titles, ['New', 'Middle', 'Old']);
  });

  test('all places the later post first on the same date', () async {
    await repository.save(contractPost('Earlier'));
    await repository.save(contractPost('Later'));
    final titles = (await repository.all()).map((post) => post.title);
    expect(titles, ['Later', 'Earlier']);
  });

  test('find returns null for an unknown id', () async {
    expect(await repository.find(999), isNull);
  });

  test('deleteMany removes exactly the given posts', () async {
    final first = await repository.save(contractPost('First'));
    final second = await repository.save(contractPost('Second'));
    final third = await repository.save(contractPost('Third'));
    await repository.deleteMany({first.id!, third.id!});
    final posts = await repository.all();
    expect(posts.single.id, second.id);
  });

  test('deleteMany accepts an empty set', () async {
    await repository.save(contractPost('Kept'));
    await repository.deleteMany({});
    expect(await repository.all(), hasLength(1));
  });

  test('save takes in a picked photo and stores only its file name', () async {
    final saved = await repository.save(
      contractPost('With photo'),
      pickedImagePath: await subject.newPhoto(),
    );
    final name = saved.imageName!;
    expect(name, isNot(contains('/')));
    expect(name, isNot(contains(r'\')));
    expect(await subject.hasImage(name), isTrue);
    expect((await repository.find(saved.id!))!.imageName, name);
  });

  Future<Post> savedWithPhoto() async =>
      repository.save(contractPost('With photo'), pickedImagePath: await subject.newPhoto());

  test('replacing an image deletes the previous file', () async {
    final saved = await savedWithPhoto();
    final replaced = await repository.save(saved, pickedImagePath: await subject.newPhoto());
    expect(replaced.imageName, isNot(saved.imageName));
    expect(await subject.hasImage(saved.imageName!), isFalse);
    expect(await subject.hasImage(replaced.imageName!), isTrue);
  });

  test('removing an image deletes its file', () async {
    final saved = await savedWithPhoto();
    final cleared = await repository.save(saved.copyWith(clearImage: true));
    expect(cleared.imageName, isNull);
    expect(await subject.hasImage(saved.imageName!), isFalse);
  });

  test('editing the text keeps the image file', () async {
    final saved = await savedWithPhoto();
    await repository.save(saved.copyWith(title: 'Renamed'));
    expect(await subject.hasImage(saved.imageName!), isTrue);
  });

  test('deleting a post deletes its image file', () async {
    final saved = await savedWithPhoto();
    await repository.deleteMany({saved.id!});
    expect(await subject.hasImage(saved.imageName!), isFalse);
  });

  test('deleting a group deletes only the images of that group', () async {
    final first = await savedWithPhoto();
    final second = await savedWithPhoto();
    final kept = await savedWithPhoto();
    await repository.deleteMany({first.id!, second.id!});
    expect(await subject.hasImage(first.imageName!), isFalse);
    expect(await subject.hasImage(second.imageName!), isFalse);
    expect(await subject.hasImage(kept.imageName!), isTrue);
  });
}
