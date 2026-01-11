import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';

/// Category configuration with Lucide icons and brand colors
class CategoryConfig {
  final IconData icon;
  final Color lightColor;
  final Color darkColor;

  const CategoryConfig({
    required this.icon,
    required this.lightColor,
    required this.darkColor,
  });

  Color getColor(bool isDark) => isDark ? darkColor : lightColor;
}

/// Centralized category icon and color mapping using Lucide icons
abstract final class CategoryIcons {
  static const Map<String, CategoryConfig> _categories = {
    'food': CategoryConfig(
      icon: LucideIcons.utensils,
      lightColor: Color(0xFFF59E0B), // Amber-500
      darkColor: Color(0xFFFBBF24), // Amber-400
    ),
    'transport': CategoryConfig(
      icon: LucideIcons.car,
      lightColor: Color(0xFF3B82F6), // Blue-500
      darkColor: Color(0xFF60A5FA), // Blue-400
    ),
    'shopping': CategoryConfig(
      icon: LucideIcons.shoppingBag,
      lightColor: Color(0xFFEC4899), // Pink-500
      darkColor: Color(0xFFF472B6), // Pink-400
    ),
    'bills': CategoryConfig(
      icon: LucideIcons.receipt,
      lightColor: Color(0xFF8B5CF6), // Violet-500
      darkColor: Color(0xFFA78BFA), // Violet-400
    ),
    'entertainment': CategoryConfig(
      icon: LucideIcons.film,
      lightColor: Color(0xFFF43F5E), // Rose-500
      darkColor: Color(0xFFFB7185), // Rose-400
    ),
    'health': CategoryConfig(
      icon: LucideIcons.heartPulse,
      lightColor: Color(0xFF10B981), // Emerald-500
      darkColor: Color(0xFF34D399), // Emerald-400
    ),
    'education': CategoryConfig(
      icon: LucideIcons.graduationCap,
      lightColor: Color(0xFF06B6D4), // Cyan-500
      darkColor: Color(0xFF22D3EE), // Cyan-400
    ),
    'cash': CategoryConfig(
      icon: LucideIcons.banknote,
      lightColor: Color(0xFF22C55E), // Green-500
      darkColor: Color(0xFF4ADE80), // Green-400
    ),
    'other': CategoryConfig(
      icon: LucideIcons.moreHorizontal,
      lightColor: Color(0xFF6366F1), // Indigo-500
      darkColor: Color(0xFF818CF8), // Indigo-400
    ),
  };

  /// Get icon for category name
  static IconData getIcon(String categoryName) {
    return _getConfigForName(categoryName)?.icon ?? LucideIcons.circle;
  }

  /// Get color for category name
  static Color getColor(String categoryName, bool isDark) {
    final config = _getConfigForName(categoryName);
    if (config == null) {
      return isDark
          ? AppColors.textSecondaryDark
          : AppColors.textSecondaryLight;
    }
    return config.getColor(isDark);
  }

  /// Find config by exact name or keyword
  static CategoryConfig? _getConfigForName(String name) {
    final normalized = name.toLowerCase();

    // 1. Try exact match
    if (_categories.containsKey(normalized)) {
      return _categories[normalized];
    }

    // 2. Try keyword matching
    if (normalized.contains('food') || normalized.contains('dining')) {
      return _categories['food'];
    }
    if (normalized.contains('transport') || normalized.contains('travel')) {
      return _categories['transport'];
    }
    if (normalized.contains('shop')) {
      return _categories['shopping'];
    }
    if (normalized.contains('bill') || normalized.contains('utility')) {
      return _categories['bills'];
    }
    if (normalized.contains('entertain')) {
      return _categories['entertainment'];
    }
    if (normalized.contains('health') || normalized.contains('medical')) {
      return _categories['health'];
    }
    if (normalized.contains('edu')) {
      return _categories['education'];
    }
    if (normalized.contains('cash')) {
      return _categories['cash'];
    }

    return _categories['other'];
  }

  /// Get category config
  static CategoryConfig? getConfig(String categoryName) {
    return _getConfigForName(categoryName);
  }

  /// Get all category names
  static List<String> get allCategories => _categories.keys.toList();
}
