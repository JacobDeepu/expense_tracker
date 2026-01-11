import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../data/local/database.dart';
import '../../data/categories_repository.dart';
import '../../data/transactions_repository.dart';

class EditTransactionSheet extends ConsumerStatefulWidget {
  final Transaction transaction;

  const EditTransactionSheet({super.key, required this.transaction});

  @override
  ConsumerState<EditTransactionSheet> createState() =>
      _EditTransactionSheetState();
}

class _EditTransactionSheetState extends ConsumerState<EditTransactionSheet> {
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  Category? _selectedCategory;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(0),
    );
    _merchantController = TextEditingController(
      text: widget.transaction.merchantName,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  void _setQuickAmount(int amount) {
    setState(() {
      _amountController.text = amount.toString();
    });
    HapticFeedback.lightImpact();
  }

  void _incrementAmount(int increment) {
    final current = int.tryParse(_amountController.text) ?? 0;
    setState(() {
      _amountController.text = (current + increment).toString();
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _handleSave() async {
    final amountText = _amountController.text;
    if (amountText.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount and select a category'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null) return;

    final updated = widget.transaction.copyWith(
      amount: amount,
      merchantName: _merchantController.text.isEmpty
          ? 'Cash Spend'
          : _merchantController.text,
      categoryId: _selectedCategory!.id,
    );

    await ref.read(transactionsRepositoryProvider).updateTransaction(updated);
    if (mounted) context.pop();
  }

  Future<void> _handleDelete() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.surfaceSecondaryDark
        : AppColors.surfaceSecondaryLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        title: Text(
          'Delete Transaction?',
          style: AppTypography.headingS(textPrimary),
        ),
        content: Text(
          'This action cannot be undone.',
          style: AppTypography.bodyM(
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTypography.bodyM(textPrimary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Delete',
              style: AppTypography.bodyM(
                Colors.red,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(transactionsRepositoryProvider)
          .deleteTransaction(widget.transaction.id);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final surface = isDark
        ? AppColors.surfaceSecondaryDark
        : AppColors.surfaceSecondaryLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final categoriesAsync = ref.watch(categoriesListProvider);

    // Initial category selection
    categoriesAsync.whenData((categories) {
      if (!_initialized) {
        _selectedCategory = categories.firstWhere(
          (c) => c.id == widget.transaction.categoryId,
          orElse: () => categories.first,
        );
        _initialized = true;
        setState(() {});
      }
    });

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.surfacePrimaryDark
          : AppColors.surfacePrimaryLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 42, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Expense',
                    style: AppTypography.headingM(textPrimary),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _handleDelete,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          LucideIcons.trash2,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.pop(),
                        visualDensity: VisualDensity.compact,
                        icon: Icon(LucideIcons.x, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Input Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '₹',
                                style: AppTypography.displayXLTabular(
                                  textPrimary,
                                ).copyWith(fontSize: 48),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  autofocus: true,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: AppTypography.displayXLTabular(
                                    textPrimary,
                                  ).copyWith(fontSize: 48),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: AppTypography.displayXLTabular(
                                      textSecondary,
                                    ).copyWith(fontSize: 48),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Quick Amounts
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [50, 100, 200, 500, 1000].map((amount) {
                              return GestureDetector(
                                onTap: () => _setQuickAmount(amount),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.surfacePrimaryDark
                                        : AppColors.surfacePrimaryLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: border),
                                  ),
                                  child: Text(
                                    '₹$amount',
                                    style: AppTypography.bodyM(
                                      textPrimary,
                                    ).copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          // Increment buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [50, 100, 500].map((amount) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: GestureDetector(
                                  onTap: () => _incrementAmount(amount),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (isDark
                                                  ? AppColors.signalBlueDark
                                                  : AppColors.signalBlueLight)
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '+$amount',
                                      style: AppTypography.bodyM(
                                        isDark
                                            ? AppColors.signalBlueDark
                                            : AppColors.signalBlueLight,
                                      ).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Category Selection
                    Text(
                      'Category',
                      style: AppTypography.bodyM(
                        textSecondary,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),

                    categoriesAsync.when(
                      data: (categories) => Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: categories.map((category) {
                          final isSelected =
                              _selectedCategory?.id == category.id;
                          final categoryIcon = CategoryIcons.getIcon(
                            category.name,
                          );
                          final categoryColor = CategoryIcons.getColor(
                            category.name,
                            isDark,
                          );

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                              HapticFeedback.selectionClick();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? categoryColor : surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? categoryColor : border,
                                  width: isSelected ? 0 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    categoryIcon,
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : categoryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category.name,
                                    style: AppTypography.bodyM(
                                      isSelected ? Colors.white : textPrimary,
                                    ).copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Text(
                        'Error loading categories',
                        style: AppTypography.bodyM(Colors.red),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Merchant Name
                    Text(
                      'Note (optional)',
                      style: AppTypography.bodyM(
                        textSecondary,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _merchantController,
                      style: AppTypography.bodyL(textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Add a description...',
                        hintStyle: AppTypography.bodyL(textSecondary),
                        filled: true,
                        fillColor: surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: Icon(
                          LucideIcons.pencil,
                          color: textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.check, size: 20),
                    const SizedBox(width: 8),
                    const Text('Save Changes'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
