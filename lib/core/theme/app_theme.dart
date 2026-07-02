import 'package:flutter/material.dart';

/// Color tokens lifted from the web app's CSS variables (resources/views/
/// layouts/app.blade.php :root / [data-theme="dark"]) so the mobile app
/// reads as the same product, not a separate skin.
class AppColors {
  static const accent = Color(0xFF6366F1); // --ac
  static const ok = Color(0xFF10B981); // --ok
  static const bad = Color(0xFFEF4444); // --bad
  static const warn = Color(0xFFF59E0B); // --warn
}

class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
      error: AppColors.bad,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0D0F1A), // --bg
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF141728), // --bg2
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF141728),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C2035), // --bg3
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
      error: AppColors.bad,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    );
  }
}
