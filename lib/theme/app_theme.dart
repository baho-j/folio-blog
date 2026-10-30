import 'package:flutter/material.dart';

/// Spacing scale shared by every screen.
abstract final class AppSpacing {
  /// Smallest gap, used inside a group of related text.
  static const double small = 8;

  /// Standard gap between neighbouring elements.
  static const double medium = 16;

  /// Gap between sections of a screen.
  static const double large = 24;

  /// Generous gap around empty states.
  static const double extraLarge = 40;

  /// Widest a column of text grows on a large screen.
  static const double readingWidth = 680;
}

/// Colours, type scale and component styles for the light and dark themes.
abstract final class AppTheme {
  /// The light theme.
  static final ThemeData light = _build(_lightScheme);

  /// The dark theme.
  static final ThemeData dark = _build(_darkScheme);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFB4472E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF6E0D8),
    onPrimaryContainer: Color(0xFF4A1608),
    secondary: Color(0xFFB4472E),
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFFFBF9F5),
    onSurface: Color(0xFF1F1D1A),
    onSurfaceVariant: Color(0xFF5E5A53),
    surfaceContainerLow: Color(0xFFF4F1EB),
    surfaceContainer: Color(0xFFEFEBE4),
    surfaceContainerHigh: Color(0xFFE9E5DD),
    outline: Color(0xFF8A857C),
    outlineVariant: Color(0xFFDDD8CE),
    error: Color(0xFFA8201A),
    onError: Color(0xFFFFFFFF),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFEC9378),
    onPrimary: Color(0xFF451405),
    primaryContainer: Color(0xFF5C2A1B),
    onPrimaryContainer: Color(0xFFF9DED4),
    secondary: Color(0xFFEC9378),
    onSecondary: Color(0xFF451405),
    surface: Color(0xFF161514),
    onSurface: Color(0xFFECE8E1),
    onSurfaceVariant: Color(0xFFB5AFA5),
    surfaceContainerLow: Color(0xFF1E1D1B),
    surfaceContainer: Color(0xFF242321),
    surfaceContainerHigh: Color(0xFF2C2A28),
    outline: Color(0xFF7F7A72),
    outlineVariant: Color(0xFF3B3936),
    error: Color(0xFFF2A49B),
    onError: Color(0xFF5A0E08),
  );

  static const TextTheme _textTheme = TextTheme(
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.25),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
    titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.35),
    bodyLarge: TextStyle(fontSize: 17, height: 1.6),
    bodyMedium: TextStyle(fontSize: 15, height: 1.45),
    bodySmall: TextStyle(fontSize: 13, height: 1.4),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );

  static ThemeData _build(ColorScheme scheme) {
    const minimumTarget = Size(48, 48);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: _textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: shape,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: minimumTarget, shape: shape),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: minimumTarget)),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: minimumTarget)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: shape,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: shape,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
    );
  }
}
