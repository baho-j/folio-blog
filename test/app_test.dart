import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/theme/app_theme.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('shows the application title', (tester) async {
    await pumpApp(tester);
    expect(find.text('Folio'), findsOneWidget);
  });

  testWidgets('follows the device brightness', (tester) async {
    await pumpApp(tester);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.theme, AppTheme.light);
    expect(app.darkTheme, AppTheme.dark);
  });

  test('both themes use one accent colour', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      expect(theme.colorScheme.secondary, theme.colorScheme.primary);
    }
  });
}
