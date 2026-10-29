import 'package:flutter_test/flutter_test.dart';
import 'package:folio/app.dart';
import 'package:folio/models/post.dart';
import 'package:folio/state/post_store.dart';

import 'support/fake_photo_picker.dart';
import 'support/in_memory_post_repository.dart';
import 'support/pump_app.dart';
import 'support/repository_contract.dart';

class _FailingRepository extends InMemoryPostRepository {
  bool failing = true;

  @override
  Future<List<Post>> all() async {
    if (failing) throw Exception('storage unavailable');
    return super.all();
  }
}

void main() {
  testWidgets('shows an empty state when there are no posts', (tester) async {
    await pumpApp(tester);
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('shows a loading state before the posts arrive', (tester) async {
    await tester.pumpWidget(
      FolioApp(store: PostStore(InMemoryPostRepository(), FakePhotoPicker())),
    );
    expect(find.text('Opening your posts'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('recovers from a failed load through the retry action', (tester) async {
    final repository = _FailingRepository();
    await tester.pumpWidget(FolioApp(store: PostStore(repository, FakePhotoPicker())));
    await tester.pumpAndSettle();
    expect(find.text('Your posts could not be opened'), findsOneWidget);

    repository.failing = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('shows the title, date and excerpt of each post', (tester) async {
    await pumpApp(
      tester,
      posts: [
        contractPost('Lake Kivu', entryDate: DateTime(2026, 10, 27), body: 'Morning\non the water'),
      ],
    );
    expect(find.text('Lake Kivu'), findsOneWidget);
    expect(find.text('27 Oct 2026'), findsOneWidget);
    expect(find.text('Morning on the water'), findsOneWidget);
  });

  testWidgets('lists the newest post first', (tester) async {
    await pumpApp(
      tester,
      posts: [
        contractPost('Older', entryDate: DateTime(2026, 1, 1)),
        contractPost('Newer', entryDate: DateTime(2026, 6, 1)),
      ],
    );
    final newer = tester.getTopLeft(find.text('Newer')).dy;
    final older = tester.getTopLeft(find.text('Older')).dy;
    expect(newer, lessThan(older));
  });
}
