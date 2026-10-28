import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/models/post.dart';
import 'package:folio/state/post_store.dart';

import 'support/pump_app.dart';
import 'support/repository_contract.dart';

void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<PostStore> openNewPost(WidgetTester tester) async {
    final store = await pumpApp(tester);
    await tester.tap(find.text('Write your first post'));
    await tester.pumpAndSettle();
    return store;
  }

  Future<PostStore> openExistingPost(WidgetTester tester) async {
    final store = await pumpApp(tester, posts: [contractPost('Lake Kivu', body: 'On the water')]);
    await tester.tap(find.text('Lake Kivu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> pressBack(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  group('new post', () {
    testWidgets('saving an empty form shows an error on each field', (tester) async {
      final store = await openNewPost(tester);
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.text('Enter a title'), findsOneWidget);
      expect(find.text('Write something for this post'), findsOneWidget);
      expect(store.posts, isEmpty);
    });

    testWidgets('a title of spaces is rejected', (tester) async {
      await openNewPost(tester);
      await tester.enterText(field('Title'), '   ');
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.text('Enter a title'), findsOneWidget);
    });

    testWidgets('a valid post is saved, trimmed and listed', (tester) async {
      final store = await openNewPost(tester);
      await tester.enterText(field('Title'), '  Nyungwe  ');
      await tester.enterText(field('Post'), 'The canopy walk.');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(store.posts.single.title, 'Nyungwe');
      expect(find.text('Nyungwe'), findsOneWidget);
    });

    testWidgets('the date defaults to today and cannot be in the future', (tester) async {
      await openNewPost(tester);
      await tester.tap(find.widgetWithText(InkWell, 'Date of entry'));
      await tester.pumpAndSettle();
      final picker = tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
      final today = Post.dateOnly(DateTime.now());
      expect(picker.initialDate, today);
      expect(Post.dateOnly(picker.lastDate), today);
    });

    testWidgets('leaving an untouched form closes it directly', (tester) async {
      await openNewPost(tester);
      await pressBack(tester);
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Nothing here yet'), findsOneWidget);
    });

    testWidgets('leaving with text asks before discarding', (tester) async {
      final store = await openNewPost(tester);
      await tester.enterText(field('Title'), 'Unfinished');
      await pressBack(tester);
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(store.posts, isEmpty);
      expect(find.text('Nothing here yet'), findsOneWidget);
    });

    testWidgets('keep editing returns to the form with the text intact', (tester) async {
      await openNewPost(tester);
      await tester.enterText(field('Title'), 'Unfinished');
      await pressBack(tester);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Unfinished'), findsOneWidget);
    });
  });

  group('existing post', () {
    testWidgets('the form opens with the stored values', (tester) async {
      await openExistingPost(tester);
      expect(find.text('Edit post'), findsOneWidget);
      expect(field('Lake Kivu'), findsOneWidget);
      expect(field('On the water'), findsOneWidget);
    });

    testWidgets('saved changes appear on the detail screen and in the list', (tester) async {
      final store = await openExistingPost(tester);
      await tester.enterText(field('Lake Kivu'), 'Lake Muhazi');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Lake Muhazi'), findsOneWidget);
      expect(store.posts.single.title, 'Lake Muhazi');
      await pressBack(tester);
      expect(find.text('Lake Muhazi'), findsOneWidget);
    });

    testWidgets('discarding leaves the stored post unchanged', (tester) async {
      final store = await openExistingPost(tester);
      await tester.enterText(field('Lake Kivu'), 'Changed');
      await pressBack(tester);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(store.posts.single.title, 'Lake Kivu');
    });
  });
}
