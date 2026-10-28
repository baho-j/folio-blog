import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/widgets/confirm_delete_dialog.dart';

import 'support/pump_app.dart';
import 'support/repository_contract.dart';

void main() {
  final post = contractPost(
    'Lake Kivu',
    entryDate: DateTime(2026, 10, 27),
    body: 'First line\nSecond line',
  );

  Future<void> openPost(WidgetTester tester) async {
    await tester.tap(find.text('Lake Kivu'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the stored title, date and full body', (tester) async {
    await pumpApp(tester, posts: [post]);
    await openPost(tester);
    expect(find.text('Lake Kivu'), findsOneWidget);
    expect(find.text('27 October 2026'), findsOneWidget);
    expect(find.text('First line\nSecond line'), findsOneWidget);
  });

  testWidgets('delete asks first and names the number of posts', (tester) async {
    await pumpApp(tester, posts: [post]);
    await openPost(tester);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete 1 post?'), findsOneWidget);
  });

  testWidgets('cancelling keeps the post', (tester) async {
    final store = await pumpApp(tester, posts: [post]);
    await openPost(tester);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.posts, hasLength(1));
    expect(find.text('Lake Kivu'), findsOneWidget);
  });

  testWidgets('confirming removes the post, returns to the list and reports it', (tester) async {
    final store = await pumpApp(tester, posts: [post]);
    await openPost(tester);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(store.posts, isEmpty);
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('1 post deleted'), findsOneWidget);
  });

  test('postCount uses the singular only for one', () {
    expect(postCount(1), '1 post');
    expect(postCount(0), '0 posts');
    expect(postCount(4), '4 posts');
  });
}
