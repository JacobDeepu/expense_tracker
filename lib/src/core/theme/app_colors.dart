import 'package:flutter/material.dart';

/// Swiss International Design System Colors.
/// Light: Stark white canvas, Royal Blue signal (#0044CC)
/// Dark: True black canvas (OLED), Electric Blue signal (#2979FF)
abstract final class AppColors {
  // Light Mode - Surfaces
  static const Color surfacePrimaryLight = Color(0xFFFFFFFF);
  static const Color surfaceSecondaryLight = Color(0xFFF4F4F5);
  static const Color surfaceTertiaryLight = Color(0xFFFAFAFA);
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF71717A);
  static const Color borderLight = Color(0xFFE4E4E7);

  // Dark Mode - Surfaces
  static const Color surfacePrimaryDark = Color(0xFF000000);
  static const Color surfaceSecondaryDark = Color(0xFF18181B);
  static const Color surfaceTertiaryDark = Color(0xFF0A0A0A);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA1A1AA);
  static const Color borderDark = Color(0xFF27272A);

  // Signal Colors (Primary Actions)
  static const Color signalBlueLight = Color(0xFF0044CC);
  static const Color signalBlueDark = Color(0xFF2979FF);
  static const Color signalRedLight = Color(0xFFD92D20);
  static const Color signalRedDark = Color(0xFFF04438);
  static const Color signalGreenLight = Color(0xFF039855);
  static const Color signalGreenDark = Color(0xFF12B76A);

  // Insight Colors (Data Visualization)
  static const Color insightPositiveLight = Color(0xFF10B981); // Green-500
  static const Color insightPositiveDark = Color(0xFF34D399); // Green-400
  static const Color insightNegativeLight = Color(0xFFEF4444); // Red-500
  static const Color insightNegativeDark = Color(0xFFF87171); // Red-400
  static const Color insightWarningLight = Color(0xFFF59E0B); // Amber-500
  static const Color insightWarningDark = Color(0xFFFBBF24); // Amber-400
  static const Color insightNeutralLight = Color(0xFF6366F1); // Indigo-500
  static const Color insightNeutralDark = Color(0xFF818CF8); // Indigo-400
}
