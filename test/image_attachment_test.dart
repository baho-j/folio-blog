import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/screens/post_detail_screen.dart';
import 'package:folio/state/post_store.dart';
import 'package:folio/widgets/post_image.dart';

import 'support/fake_photo_picker.dart';
import 'support/pump_app.dart';
import 'support/repository_contract.dart';

void main() {
  late FakePhotoPicker photos;

  setUp(() => photos = FakePhotoPicker());

  Future<PostStore> openNewPost(WidgetTester tester) async {
    final store = await pumpApp(tester, photos: photos);
    await tester.tap(find.text('Write your first post'));
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> choose(WidgetTester tester, String option) async {
    await tester.tap(find.text('Add a photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option));
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSave(WidgetTester tester) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Photo post');
    await tester.enterText(find.widgetWithText(TextFormField, 'Post'), 'Body');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('the sheet offers the camera and the gallery', (tester) async {
    await openNewPost(tester);
    await tester.tap(find.text('Add a photo'));
    await tester.pumpAndSettle();
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
  });

  testWidgets('a camera photo is attached to the saved post', (tester) async {
    final store = await openNewPost(tester);
    await choose(tester, 'Take a photo');
    expect(photos.usedCamera, isTrue);
    await fillAndSave(tester);
    expect(store.posts.single.imageName, isNotNull);
  });

  testWidgets('a gallery photo is attached to the saved post', (tester) async {
    final store = await openNewPost(tester);
    await choose(tester, 'Choose from gallery');
    expect(photos.usedCamera, isFalse);
    await fillAndSave(tester);
    expect(store.posts.single.imageName, isNotNull);
  });

  testWidgets('the preview replaces the prompt once a photo is chosen', (tester) async {
    await openNewPost(tester);
    await choose(tester, 'Choose from gallery');
    expect(find.text('Add a photo'), findsNothing);
  });

  testWidgets('cancelling the picker changes nothing', (tester) async {
    photos.nextPath = null;
    await openNewPost(tester);
    await choose(tester, 'Take a photo');
    expect(find.text('Add a photo'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('a failed picker reports the problem', (tester) async {
    photos.failing = true;
    await openNewPost(tester);
    await choose(tester, 'Take a photo');
    expect(find.text('The camera could not be opened'), findsOneWidget);
  });

  testWidgets('a chosen photo counts as an unsaved change', (tester) async {
    await openNewPost(tester);
    await choose(tester, 'Choose from gallery');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
  });

  testWidgets('a post with a photo still opens on the detail screen', (tester) async {
    await pumpApp(tester, posts: [contractPost('With photo').copyWith(imageName: 'a.jpg')]);
    await tester.tap(find.text('With photo'));
    await tester.pumpAndSettle();
    expect(find.text('With photo'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PostDetailScreen),
        matching: find.byType(PostImage, skipOffstage: false),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });
}
