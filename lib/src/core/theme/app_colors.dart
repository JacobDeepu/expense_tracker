import 'package:flutter/material.dart';

/// Swiss International Design System Colors.
/// Light: Stark white canvas, Royal Blue signal (#0044CC)
/// Dark: True black canvas (OLED), Electric Blue signal (#2979FF)
abstract final class AppColors {
  // Light Mode
  static const Color surfacePrimaryLight = Color(0xFFFFFFFF);
  static const Color surfaceSecondaryLight = Color(0xFFF4F4F5);
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF71717A);
  static const Color borderLight = Color(0xFFE4E4E7);

  // Dark Mode
  static const Color surfacePrimaryDark = Color(0xFF000000);
  static const Color surfaceSecondaryDark = Color(0xFF18181B);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA1A1AA);
  static const Color borderDark = Color(0xFF27272A);

  // Signal Colors
  static const Color signalBlueLight = Color(0xFF0044CC);
  static const Color signalBlueDark = Color(0xFF2979FF);
  static const Color signalRedLight = Color(0xFFD92D20);
  static const Color signalRedDark = Color(0xFFF04438);
  static const Color signalGreenLight = Color(0xFF039855);
  static const Color signalGreenDark = Color(0xFF12B76A);
}
