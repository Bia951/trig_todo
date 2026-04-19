import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TrigTheme {
  static const Color _fallbackSeed = Colors.orange;

  static ThemeData light(ColorScheme? dynamicScheme) {
    return _buildTheme(
      brightness: Brightness.light,
      dynamicScheme: dynamicScheme,
    );
  }

  static ThemeData dark(ColorScheme? dynamicScheme) {
    return _buildTheme(
      brightness: Brightness.dark,
      dynamicScheme: dynamicScheme,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    ColorScheme? dynamicScheme,
  }) {
    final shouldUseAndroidDynamicColor =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final colorScheme = shouldUseAndroidDynamicColor && dynamicScheme != null
        ? dynamicScheme
        : ColorScheme.fromSeed(
            seedColor: _fallbackSeed,
            brightness: brightness,
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHigh,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        floatingLabelStyle: TextStyle(color: colorScheme.primary),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
