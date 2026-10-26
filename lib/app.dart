import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

/// Root widget, which applies the themes and follows the device brightness.
class FolioApp extends StatelessWidget {
  /// Creates the application.
  const FolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: Scaffold(
        appBar: AppBar(title: const Text('Folio')),
        body: const Center(child: Text('Your posts will appear here.')),
      ),
    );
  }
}
