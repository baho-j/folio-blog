import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/app.dart';
import 'package:folio/state/post_store.dart';
import 'package:folio/widgets/post_tile.dart';

import 'support/fake_photo_picker.dart';
import 'support/in_memory_post_repository.dart';
import 'support/repository_contract.dart';

void main() {
  final post = contractPost('Lake Kivu', body: 'Morning on the water ' * 10);

  Future<void> pumpWith(WidgetTester tester, Brightness brightness, {double scale = 1}) async {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final repository = InMemoryPostRepository();
    await repository.save(post);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: FolioApp(store: PostStore(repository, FakePhotoPicker())),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> meetsGuidelines(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  for (final brightness in Brightness.values) {
    group('${brightness.name} theme', () {
      testWidgets('the list meets the guidelines', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpWith(tester, brightness);
        await meetsGuidelines(tester);
        semantics.dispose();
      });

      testWidgets('selection mode meets the guidelines', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpWith(tester, brightness);
        await tester.longPress(find.text('Lake Kivu'));
        await tester.pumpAndSettle();
        await meetsGuidelines(tester);
        semantics.dispose();
      });

      testWidgets('the detail screen meets the guidelines', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpWith(tester, brightness);
        await tester.tap(find.text('Lake Kivu'));
        await tester.pumpAndSettle();
        await meetsGuidelines(tester);
        semantics.dispose();
      });

      testWidgets('the editor meets the guidelines', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpWith(tester, brightness);
        await tester.tap(find.text('New post'));
        await tester.pumpAndSettle();
        await meetsGuidelines(tester);
        semantics.dispose();
      });
    });
  }

  testWidgets('double text size lays out the list without overflow', (tester) async {
    await pumpWith(tester, Brightness.light, scale: 2);
    expect(tester.takeException(), isNull);
    expect(find.byType(PostTile), findsOneWidget);
  });

  testWidgets('double text size lays out the editor without overflow', (tester) async {
    await pumpWith(tester, Brightness.light, scale: 2);
    await tester.tap(find.text('New post'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a post tile reports its selected state', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpWith(tester, Brightness.light);
    await tester.longPress(find.text('Lake Kivu'));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.byType(PostTile)), isSemantics(isSelected: true));
    semantics.dispose();
  });
}
