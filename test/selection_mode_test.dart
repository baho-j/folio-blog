import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/state/post_store.dart';

import 'support/pump_app.dart';
import 'support/repository_contract.dart';

void main() {
  final posts = [
    contractPost('First', entryDate: DateTime(2026, 10, 3)),
    contractPost('Second', entryDate: DateTime(2026, 10, 2)),
    contractPost('Third', entryDate: DateTime(2026, 10, 1)),
  ];

  Future<PostStore> startSelecting(WidgetTester tester) async {
    final store = await pumpApp(tester, posts: posts);
    await tester.longPress(find.text('First'));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('a long press starts selection with that post chosen', (tester) async {
    final store = await startSelecting(tester);
    expect(find.text('1 selected'), findsOneWidget);
    expect(store.selected, hasLength(1));
    expect(find.text('New post'), findsNothing);
  });

  testWidgets('a tap in selection mode changes the selection, not the screen', (tester) async {
    await startSelecting(tester);
    await tester.tap(find.text('Second'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    expect(find.byTooltip('Edit'), findsNothing);
  });

  testWidgets('removing the last selected post leaves selection mode', (tester) async {
    await startSelecting(tester);
    await tester.tap(find.text('First'));
    await tester.pumpAndSettle();
    expect(find.text('Folio'), findsOneWidget);
  });

  testWidgets('select all chooses every post', (tester) async {
    await startSelecting(tester);
    await tester.tap(find.byTooltip('Select all'));
    await tester.pumpAndSettle();
    expect(find.text('3 selected'), findsOneWidget);
  });

  testWidgets('the close button cancels selection', (tester) async {
    final store = await startSelecting(tester);
    await tester.tap(find.byTooltip('Cancel selection'));
    await tester.pumpAndSettle();
    expect(store.selecting, isFalse);
    expect(find.text('Folio'), findsOneWidget);
  });

  testWidgets('the back button cancels selection and stays on the list', (tester) async {
    final store = await startSelecting(tester);
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(store.selecting, isFalse);
    expect(find.text('First'), findsOneWidget);
  });

  testWidgets('delete confirms and states the number of posts', (tester) async {
    await startSelecting(tester);
    await tester.tap(find.text('Third'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete selected'));
    await tester.pumpAndSettle();
    expect(find.text('Delete 2 posts?'), findsOneWidget);
  });

  testWidgets('cancelling the dialog keeps the posts and the selection', (tester) async {
    final store = await startSelecting(tester);
    await tester.tap(find.byTooltip('Delete selected'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.posts, hasLength(3));
    expect(find.text('1 selected'), findsOneWidget);
  });

  testWidgets('confirming deletes exactly the selected posts', (tester) async {
    final store = await startSelecting(tester);
    await tester.tap(find.text('Third'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete selected'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(store.posts.single.title, 'Second');
    expect(find.text('2 posts deleted'), findsOneWidget);
    expect(find.text('Folio'), findsOneWidget);
  });

  testWidgets('deleting every post shows the empty state', (tester) async {
    await startSelecting(tester);
    await tester.tap(find.byTooltip('Select all'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete selected'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet'), findsOneWidget);
  });
}
