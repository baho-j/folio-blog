import 'package:flutter/material.dart';

import 'screens/post_list_screen.dart';
import 'state/post_store.dart';
import 'theme/app_theme.dart';

/// Root widget, which applies the themes and follows the device brightness.
class FolioApp extends StatelessWidget {
  /// Creates the application.
  const FolioApp({super.key, required this.store});

  /// Shared state of the application.
  final PostStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: PostListScreen(store: store),
    );
  }
}
