import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Swiss International typography using Inter font.
/// Sizes: Display XL (48), Display L (32), Heading M (24),
/// Body L (18), Body M (16), Caption (12)
abstract final class AppTypography {
  static TextStyle _baseStyle(Color color) {
    return GoogleFonts.inter(color: color, fontWeight: FontWeight.w400);
  }

  static TextStyle displayXL(Color color) {
    return _baseStyle(color).copyWith(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.5,
    );
  }

  static TextStyle displayL(Color color) {
    return _baseStyle(color).copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.5,
    );
  }

  static TextStyle headingM(Color color) {
    return _baseStyle(
      color,
    ).copyWith(fontSize: 24, fontWeight: FontWeight.w600, height: 1.3);
  }

  static TextStyle headingS(Color color) {
    return _baseStyle(
      color,
    ).copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);
  }

  static TextStyle bodyL(Color color) {
    return _baseStyle(
      color,
    ).copyWith(fontSize: 18, fontWeight: FontWeight.w400, height: 1.5);
  }

  static TextStyle bodyM(Color color) {
    return _baseStyle(
      color,
    ).copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  }

  static TextStyle caption(Color color) {
    return _baseStyle(
      color,
    ).copyWith(fontSize: 12, fontWeight: FontWeight.w500, height: 1.5);
  }

  static TextStyle captionUppercase(Color color) {
    return caption(color).copyWith(letterSpacing: 1.2);
  }

  static TextStyle bodyS(Color color) {
    return _baseStyle(
      color,
    ).copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  }

  // Tabular numerals for financial data alignment
  static TextStyle displayXLTabular(Color color) {
    return displayXL(
      color,
    ).copyWith(fontFeatures: [const FontFeature.tabularFigures()]);
  }

  static TextStyle bodyMTabular(Color color) {
    return bodyM(
      color,
    ).copyWith(fontFeatures: [const FontFeature.tabularFigures()]);
  }

  static TextTheme textTheme({
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return TextTheme(
      displayLarge: displayXL(primaryColor),
      displayMedium: displayL(primaryColor),
      headlineMedium: headingM(primaryColor),
      titleLarge: bodyL(primaryColor),
      bodyLarge: bodyL(primaryColor),
      bodyMedium: bodyM(primaryColor),
      bodySmall: caption(secondaryColor),
      labelSmall: captionUppercase(secondaryColor),
    );
  }
}
