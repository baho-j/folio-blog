import 'package:flutter_test/flutter_test.dart';
import 'package:folio/models/post.dart';

void main() {
  final moment = DateTime(2026, 10, 27, 10, 5);
  final post = Post(
    id: 7,
    title: 'Lake Kivu',
    body: 'Morning on the water.',
    entryDate: DateTime(2026, 10, 27),
    imageName: 'kivu.jpg',
    createdAt: moment,
    updatedAt: moment,
  );

  group('draft', () {
    test('is unsaved, empty and dated today without a time', () {
      final draft = Post.draft(moment);
      expect(draft.id, isNull);
      expect(draft.title, isEmpty);
      expect(draft.body, isEmpty);
      expect(draft.imageName, isNull);
      expect(draft.entryDate, DateTime(2026, 10, 27));
    });
  });

  group('database rows', () {
    test('survive a round trip unchanged', () {
      expect(Post.fromRow(post.toRow()), post);
    });

    test('leave out the id until one is assigned', () {
      expect(Post.draft(moment).toRow().containsKey('id'), isFalse);
    });

    test('store dates as milliseconds since the epoch', () {
      expect(post.toRow()['entry_date'], post.entryDate.millisecondsSinceEpoch);
    });
  });

  group('copyWith', () {
    test('replaces only the given fields', () {
      final changed = post.copyWith(title: 'Nyungwe');
      expect(changed.title, 'Nyungwe');
      expect(changed.body, post.body);
      expect(changed.imageName, post.imageName);
    });

    test('keeps the image unless asked to clear it', () {
      expect(post.copyWith().imageName, 'kivu.jpg');
      expect(post.copyWith(clearImage: true).imageName, isNull);
    });
  });

  group('validation', () {
    test('rejects an empty or blank title', () {
      expect(Post.validateTitle(''), isNotNull);
      expect(Post.validateTitle('   '), isNotNull);
      expect(Post.validateTitle(null), isNotNull);
    });

    test('accepts a title at the limit and rejects one beyond it', () {
      expect(Post.validateTitle('a' * Post.maxTitleLength), isNull);
      expect(Post.validateTitle('a' * (Post.maxTitleLength + 1)), isNotNull);
    });

    test('measures a title after trimming spaces', () {
      expect(Post.validateTitle('  ${'a' * Post.maxTitleLength}  '), isNull);
    });

    test('rejects a blank body and accepts text', () {
      expect(Post.validateBody('  \n '), isNotNull);
      expect(Post.validateBody('Some text'), isNull);
    });
  });

  test('excerpt collapses line breaks and repeated spaces', () {
    expect(post.copyWith(body: ' One\n\ntwo   three ').excerpt, 'One two three');
  });

  test('dateOnly removes the time', () {
    expect(Post.dateOnly(moment), DateTime(2026, 10, 27));
  });

  test('posts with equal fields are equal', () {
    expect(post.copyWith(), post);
    expect(post.copyWith().hashCode, post.hashCode);
    expect(post.copyWith(title: 'Other'), isNot(post));
  });
}
