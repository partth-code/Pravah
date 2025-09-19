import 'package:flutter/material.dart';

class AppColors {
  // Primary families: Green, Brown, Mustard (farm-related)
  static const green = Color(0xFF2E8B57);
  static const greenDark = Color(0xFF226A44);
  static const greenLight = Color(0xFFBFE3D0);

  static const brown = Color(0xFF8B5E3C);
  static const brownDark = Color(0xFF6A452C);
  static const brownLight = Color(0xFFE9D8C8);

  static const mustard = Color(0xFFE0B000);
  static const mustardDark = Color(0xFFB68E00);
  static const mustardLight = Color(0xFFF6E6A6);

  static const neutralDark = Color(0xFF0F1724);
  static const neutralGray = Color(0xFFE6EEF2);

  static const accentStart = Color(0xFF1FA2FF);
  static const accentEnd = Color(0xFF12D8A5);
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.green,
      onPrimary: Colors.white,
      secondary: AppColors.brown,
      onSecondary: Colors.white,
      error: const Color(0xFFE53E3E),
      onError: Colors.white,
      background: Colors.white,
      onBackground: AppColors.neutralDark,
      surface: Colors.white,
      onSurface: AppColors.neutralDark,
      primaryContainer: AppColors.greenLight,
      onPrimaryContainer: AppColors.greenDark,
      secondaryContainer: AppColors.brownLight,
      onSecondaryContainer: AppColors.brownDark,
      tertiary: AppColors.mustard,
      onTertiary: AppColors.neutralDark,
      tertiaryContainer: AppColors.mustardLight,
      onTertiaryContainer: AppColors.mustardDark,
      surfaceVariant: AppColors.neutralGray,
      onSurfaceVariant: AppColors.neutralDark,
      outline: AppColors.neutralGray,
      outlineVariant: AppColors.neutralGray,
      inverseSurface: AppColors.neutralDark,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.greenLight,
      scrim: Colors.black.withOpacity(0.5),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 2,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.neutralDark,
      ),
      cardColor: AppColors.neutralGray,
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, color: AppColors.neutralDark),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.neutralDark),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.neutralDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.neutralGray,
        selectedColor: AppColors.green.withOpacity(0.15),
        labelStyle: const TextStyle(color: AppColors.neutralDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dividerColor: AppColors.neutralGray,
    );
  }
}


