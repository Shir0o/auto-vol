import 'package:flutter/material.dart';

class VocusColors {
  static const background = Color(0xFF101415);
  static const surface = Color(0xFF1D2022);
  static const primary = Color(0xFF00F0FF); // Electric Cyan
  static const secondary = Color(0xFF7000FF);
  static const onBackground = Color(0xFFE0E3E5);
  static const onSurface = Color(0xFFE0E3E5);
  static const onPrimary = Color(0xFF00363A);
  static const outline = Color(0xFF849495);
  static const surfaceVariant = Color(0xFF323537);
  
  static const deepSpaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF120B3A),
      Color(0xFF0B0624),
    ],
  );
}

class VocusTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VocusColors.background,
      colorScheme: ColorScheme.dark(
        background: VocusColors.background,
        surface: VocusColors.surface,
        primary: VocusColors.primary,
        secondary: VocusColors.secondary,
        onBackground: VocusColors.onBackground,
        onSurface: VocusColors.onSurface,
        onPrimary: VocusColors.onPrimary,
        outline: VocusColors.outline,
        surfaceVariant: VocusColors.surfaceVariant,
      ),
      fontFamily: 'Inter',
      cardTheme: CardThemeData(
        color: VocusColors.surface.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // rounded-xl (1.5rem)
          side: BorderSide(color: Colors.white.withOpacity(0.15), width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VocusColors.secondary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // rounded-lg (1rem)
          ),
        ),
      ),
    );
  }
}
