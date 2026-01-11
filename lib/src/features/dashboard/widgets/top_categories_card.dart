import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/category_icons.dart';

/// Category data for top categories display
class CategoryData {
  final String name;
  final double amount;
  final double percentage;

  const CategoryData({
    required this.name,
    required this.amount,
    required this.percentage,
  });
}

/// Top categories card with animated horizontal bars
class TopCategoriesCard extends StatelessWidget {
  final List<CategoryData> categories;
  final VoidCallback? onSeeMore;

  const TopCategoriesCard({
    required this.categories,
    this.onSeeMore,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final maxAmount = categories.isEmpty
        ? 1.0
        : categories.fold<double>(
            0,
            (max, c) => c.amount > max ? c.amount : max,
          );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceSecondaryDark
            : AppColors.surfacePrimaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.trendingUp, size: 16, color: textSecondary),
              const SizedBox(width: 6),
              Text(
                'Top Spending',
                style: AppTypography.caption(
                  textSecondary,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (onSeeMore != null)
                GestureDetector(
                  onTap: onSeeMore,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See more',
                        style: AppTypography.caption(
                          isDark
                              ? AppColors.signalBlueDark
                              : AppColors.signalBlueLight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 14,
                        color: isDark
                            ? AppColors.signalBlueDark
                            : AppColors.signalBlueLight,
                      ),
                    ],
                  ),
                )
              else
                Text('This month', style: AppTypography.caption(textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No spending data yet',
                  style: AppTypography.bodyM(textSecondary),
                ),
              ),
            )
          else
            ...categories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < categories.length - 1 ? 12 : 0,
                ),
                child: _AnimatedCategoryBar(
                  index: index,
                  category: category,
                  maxAmount: maxAmount,
                  isDark: isDark,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AnimatedCategoryBar extends StatefulWidget {
  final int index;
  final CategoryData category;
  final double maxAmount;
  final bool isDark;

  const _AnimatedCategoryBar({
    required this.index,
    required this.category,
    required this.maxAmount,
    required this.isDark,
  });

  @override
  State<_AnimatedCategoryBar> createState() => _AnimatedCategoryBarState();
}

class _AnimatedCategoryBarState extends State<_AnimatedCategoryBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _widthAnimation = Tween<double>(
      begin: 0,
      end: widget.category.amount / widget.maxAmount,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = widget.isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final categoryColor = CategoryIcons.getColor(
      widget.category.name,
      widget.isDark,
    );
    final categoryIcon = CategoryIcons.getIcon(widget.category.name);
    final bgColor = widget.isDark
        ? const Color(0xFF374151)
        : const Color(0xFFE5E7EB);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Row(
            children: [
              // Category icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(categoryIcon, size: 16, color: categoryColor),
              ),
              const SizedBox(width: 12),
              // Name and bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.category.name,
                          style: AppTypography.bodyM(
                            textPrimary,
                          ).copyWith(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                        Text(
                          '₹${_formatAmount(widget.category.amount)}',
                          style: AppTypography.bodyMTabular(
                            textSecondary,
                          ).copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Animated bar
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _widthAnimation.value.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: categoryColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }
}
