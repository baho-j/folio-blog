import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/widgets/highlighted_text.dart';

import 'support/pump_app.dart';
import 'support/repository_contract.dart';

void main() {
  final posts = [
    contractPost('Lake Kivu', body: 'Morning on the water'),
    contractPost('Lake Muhazi', body: 'Evening by the shore'),
    contractPost('Nyungwe', body: 'The canopy walk'),
  ];

  Future<void> openSearch(WidgetTester tester) async {
    await pumpApp(tester, posts: posts);
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  testWidgets('starts with a prompt', (tester) async {
    await openSearch(tester);
    expect(find.text('Search your posts'), findsOneWidget);
  });

  testWidgets('waits for a pause in typing before searching', (tester) async {
    await openSearch(tester);
    await tester.enterText(find.byType(TextField), 'lake');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(HighlightedText), findsNothing);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(find.byType(HighlightedText), findsWidgets);
  });

  testWidgets('lists every match', (tester) async {
    await openSearch(tester);
    await type(tester, 'lake');
    expect(find.text('Lake Kivu'), findsOneWidget);
    expect(find.text('Lake Muhazi'), findsOneWidget);
    expect(find.text('Nyungwe'), findsNothing);
  });

  testWidgets('finds text in the body and ignores letter case', (tester) async {
    await openSearch(tester);
    await type(tester, 'CANOPY');
    expect(find.text('Nyungwe'), findsOneWidget);
  });

  testWidgets('shows a designed state when nothing matches', (tester) async {
    await openSearch(tester);
    await type(tester, 'volcano');
    expect(find.text('No posts match'), findsOneWidget);
  });

  testWidgets('submitting with one match opens that post', (tester) async {
    await openSearch(tester);
    await tester.enterText(find.byType(TextField), 'canopy');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('The canopy walk'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('submitting with several matches stays on the list', (tester) async {
    await openSearch(tester);
    await tester.enterText(find.byType(TextField), 'lake');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Lake Kivu'), findsOneWidget);
    expect(find.text('Lake Muhazi'), findsOneWidget);
  });

  testWidgets('a result opens its post', (tester) async {
    await openSearch(tester);
    await type(tester, 'lake');
    await tester.tap(find.text('Lake Kivu'));
    await tester.pumpAndSettle();
    expect(find.text('Morning on the water'), findsOneWidget);
  });

  testWidgets('a post deleted from a result leaves the results', (tester) async {
    await openSearch(tester);
    await type(tester, 'lake');
    await tester.tap(find.text('Lake Kivu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Lake Kivu'), findsNothing);
    expect(find.text('Lake Muhazi'), findsOneWidget);
  });

  testWidgets('clearing the field returns to the prompt', (tester) async {
    await openSearch(tester);
    await type(tester, 'lake');
    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Search your posts'), findsOneWidget);
  });
}
