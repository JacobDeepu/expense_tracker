import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Swiss International Design Theme.
/// Sharp corners (4px max), no shadows, high contrast, generous whitespace.
abstract final class AppTheme {
  static const double _cornerRadius = 4.0;

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.surfacePrimaryLight,
      colorScheme: ColorScheme.light(
        primary: AppColors.signalBlueLight,
        onPrimary: Colors.white,
        secondary: AppColors.signalBlueLight,
        onSecondary: Colors.white,
        surface: AppColors.surfacePrimaryLight,
        onSurface: AppColors.textPrimaryLight,
        error: AppColors.signalRedLight,
        onError: Colors.white,
        outline: AppColors.borderLight,
      ),
      textTheme: AppTypography.textTheme(
        primaryColor: AppColors.textPrimaryLight,
        secondaryColor: AppColors.textSecondaryLight,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.5,
        ),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        color: AppColors.borderLight,
        space: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.signalBlueLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cornerRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppColors.textPrimaryLight,
          side: const BorderSide(color: AppColors.textPrimaryLight, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cornerRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textPrimaryLight, width: 2),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textPrimaryLight, width: 2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.signalBlueLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        labelStyle: AppTypography.bodyM(AppColors.textSecondaryLight),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cornerRadius),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        color: AppColors.surfacePrimaryLight,
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surfacePrimaryDark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.signalBlueDark,
        onPrimary: Colors.white,
        secondary: AppColors.signalBlueDark,
        onSecondary: Colors.white,
        surface: AppColors.surfacePrimaryDark,
        onSurface: AppColors.textPrimaryDark,
        error: AppColors.signalRedDark,
        onError: Colors.white,
        outline: AppColors.borderDark,
      ),
      textTheme: AppTypography.textTheme(
        primaryColor: AppColors.textPrimaryDark,
        secondaryColor: AppColors.textSecondaryDark,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.5,
        ),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        color: AppColors.borderDark,
        space: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.signalBlueDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cornerRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppColors.textPrimaryDark,
          side: const BorderSide(color: AppColors.textPrimaryDark, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cornerRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textPrimaryDark, width: 2),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textPrimaryDark, width: 2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.signalBlueDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        labelStyle: AppTypography.bodyM(AppColors.textSecondaryDark),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cornerRadius),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        color: AppColors.surfacePrimaryDark,
        margin: EdgeInsets.zero,
      ),
    );
  }
}
