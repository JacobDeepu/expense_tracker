import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Expandable FAB with radial menu for navigation
/// Long press or drag up to reveal menu items
class ExpandableFab extends StatefulWidget {
  final VoidCallback onAddPressed;
  final VoidCallback onActivityPressed;
  final VoidCallback onInsightsPressed;
  final VoidCallback onSettingsPressed;

  const ExpandableFab({
    required this.onAddPressed,
    required this.onActivityPressed,
    required this.onInsightsPressed,
    required this.onSettingsPressed,
    super.key,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // Pulsing glow animation to hint at long-press
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
        _pulseController.stop();
        HapticFeedback.mediumImpact();
      } else {
        _controller.reverse();
        _pulseController.repeat(reverse: true);
      }
    });
  }

  void _close() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _controller.reverse();
        _pulseController.repeat(reverse: true);
      });
    }
  }

  void _handleAction(VoidCallback action) {
    HapticFeedback.lightImpact();
    _close();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalBlue = isDark
        ? AppColors.signalBlueDark
        : AppColors.signalBlueLight;
    final surface = isDark
        ? AppColors.surfaceSecondaryDark
        : AppColors.surfacePrimaryLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) => Container(
                  color: Colors.black.withValues(
                    alpha: 0.4 * _expandAnimation.value,
                  ),
                ),
              ),
            ),
          ),

        // Menu Items
        Positioned(
          bottom: 80,
          right: 16,
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _expandAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _expandAnimation.value)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuItem(
                        icon: LucideIcons.settings,
                        label: 'Settings',
                        onTap: () => _handleAction(widget.onSettingsPressed),
                        surface: surface,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        delay: 2,
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        icon: LucideIcons.pieChart,
                        label: 'Insights',
                        onTap: () => _handleAction(widget.onInsightsPressed),
                        surface: surface,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        delay: 1,
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        icon: LucideIcons.list,
                        label: 'Activity',
                        onTap: () => _handleAction(widget.onActivityPressed),
                        surface: surface,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        delay: 0,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Main FAB with pulsing glow
        Positioned(
          bottom: 24,
          right: 16,
          child: GestureDetector(
            onLongPress: _toggle,
            onTap: () {
              HapticFeedback.lightImpact();
              if (_isExpanded) {
                _close();
              } else {
                widget.onAddPressed();
              }
            },
            child: AnimatedBuilder(
              animation: Listenable.merge([_expandAnimation, _pulseAnimation]),
              builder: (context, child) {
                final pulseScale = _isExpanded ? 0 : _pulseAnimation.value;
                return Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: signalBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      // Base shadow
                      BoxShadow(
                        color: signalBlue.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      // Pulsing glow
                      if (!_isExpanded)
                        BoxShadow(
                          color: signalBlue.withValues(alpha: 0.3 * pulseScale),
                          blurRadius: (24 + (12 * pulseScale)).toDouble(),
                          spreadRadius: (4 * pulseScale).toDouble(),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: _expandAnimation.value * (math.pi / 4),
                      child: Icon(
                        LucideIcons.plus,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Hint text (appears briefly on first launch)
        if (!_isExpanded)
          Positioned(
            bottom: 88,
            right: 16,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                // Only show hint during pulse peak
                final opacity = _pulseAnimation.value > 0.7
                    ? (_pulseAnimation.value - 0.7) / 0.3 * 0.8
                    : 0.0;
                return Opacity(
                  opacity: opacity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Hold for menu',
                      style: AppTypography.caption(textSecondary),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required int delay,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: AppTypography.bodyM(
                textPrimary,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: textSecondary, size: 20),
          ),
        ],
      ),
    );
  }
}
