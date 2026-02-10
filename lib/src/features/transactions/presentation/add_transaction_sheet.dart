import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/category_icons.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables.dart';
import '../data/categories_repository.dart';
import '../data/transactions_repository.dart';
import '../logic/ocr/receipt_scanner_service.dart';
import 'ocr_review_sheet.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final int? recurringRuleId;
  final String? initialAmount;
  final String? initialMerchant;
  final int? initialCategoryId;

  const AddTransactionSheet({
    this.recurringRuleId,
    this.initialAmount,
    this.initialMerchant,
    this.initialCategoryId,
    super.key,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  Category? _selectedCategory;
  TransactionType _type = TransactionType.expense;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.initialAmount);
    _merchantController = TextEditingController(text: widget.initialMerchant);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCategory == null && widget.initialCategoryId != null) {
      ref.watch(categoriesListProvider).whenData((categories) {
        setState(() {
          _selectedCategory = categories.firstWhere(
            (c) => c.id == widget.initialCategoryId,
            orElse: () => categories.first,
          );
        });
      });
    }
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

  Future<void> _handleScan() async {
    setState(() => _isScanning = true);
    try {
      final result = await ref
          .read(receiptScannerServiceProvider)
          .scanReceipt();

      if (result != null) {
        // Close current sheet
        if (mounted) context.pop();

        // Navigate to review sheet
        if (mounted) {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => OcrReviewSheet(
              scanResult: result,
              recurringRuleId: widget.recurringRuleId,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Scan error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Scan error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
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

    final merchantName = _merchantController.text.isEmpty
        ? (_type == TransactionType.income ? 'Income' : 'Cash Spend')
        : _merchantController.text;

    await ref
        .read(transactionsRepositoryProvider)
        .addTransaction(
          amount: amount,
          merchantName: merchantName,
          date: DateTime.now(),
          source: TransactionSource.manual,
          type: _type,
          categoryId: _selectedCategory!.id,
          recurringRuleId: widget.recurringRuleId,
        );

    if (mounted) {
      context.pop();
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
    final signalGreen = isDark
        ? AppColors.insightPositiveDark
        : AppColors.insightPositiveLight;
    final signalRed = isDark
        ? AppColors.signalRedDark
        : AppColors.signalRedLight;

    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.surfacePrimaryDark
          : AppColors.surfacePrimaryLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Transaction',
                    style: AppTypography.headingM(textPrimary),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(LucideIcons.x, color: textSecondary),
                  ),
                ],
              ),
            ),

            // Type Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _type = TransactionType.expense),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _type == TransactionType.expense
                                ? signalRed
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Expense',
                            style: AppTypography.bodyM(
                              _type == TransactionType.expense
                                  ? Colors.white
                                  : textSecondary,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _type = TransactionType.income),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _type == TransactionType.income
                                ? signalGreen
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Income',
                            style: AppTypography.bodyM(
                              _type == TransactionType.income
                                  ? Colors.white
                                  : textSecondary,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                          // Quick Amounts (set)
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
                          // Increment buttons (+add to current)
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
                      error: (err, stack) => Text('Error loading categories'),
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

                    // Scan Receipt Button
                    OutlinedButton.icon(
                      onPressed: _isScanning ? null : _handleScan,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.scan, size: 20),
                      label: const Text('Scan Receipt'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        side: BorderSide(color: border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
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
                    Text(
                      _type == TransactionType.expense
                          ? 'Save Expense'
                          : 'Save Income',
                    ),
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
