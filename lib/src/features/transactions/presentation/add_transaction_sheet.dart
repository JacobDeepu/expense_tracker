import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/local/database.dart'; // Import for Category type
import '../../../data/local/tables.dart'; // For TransactionType/Source enums
import '../data/categories_repository.dart';
import '../data/transactions_repository.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final TextEditingController _amountController = TextEditingController();
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Auto-focus on amount field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final amountText = _amountController.text;
    if (amountText.isEmpty || _selectedCategory == null) {
      // Basic validation feedback
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

    // Save to Database via Repository
    await ref.read(transactionsRepositoryProvider).addTransaction(
          amount: amount,
          merchantName: 'Cash Spend', // Default for manual entry
          date: DateTime.now(),
          source: TransactionSource.manual,
          type: TransactionType.expense,
          categoryId: _selectedCategory!.id,
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
    final signalBlue = isDark
        ? AppColors.signalBlueDark
        : AppColors.signalBlueLight;

    // Watch categories from DB
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ADD EXPENSE',
                      style: AppTypography.captionUppercase(textSecondary),
                    ),
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.close, color: textPrimary),
                    ),
                  ],
                ),

                const SizedBox(height: 64),

                // Amount Input (Massive, centered)
                TextField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: AppTypography.displayXL(
                    textPrimary,
                  ).copyWith(fontSize: 64, letterSpacing: -1),
                  decoration: InputDecoration(
                    hintText: '₹0',
                    hintStyle: AppTypography.displayXL(
                      textSecondary,
                    ).copyWith(fontSize: 64, letterSpacing: -1),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    prefixText: '₹', // Clean currency symbol
                    prefixStyle: AppTypography.displayXL(
                      textPrimary,
                    ).copyWith(fontSize: 64, letterSpacing: -1),
                  ),
                ),

                const SizedBox(height: 64),

                // Category Selection
                Text(
                  'CATEGORY',
                  style: AppTypography.captionUppercase(textSecondary),
                ),
                const SizedBox(height: 16),

                categoriesAsync.when(
                  data: (categories) => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: categories.map((category) {
                      final isSelected = _selectedCategory?.id == category.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? signalBlue
                                : (isDark
                                    ? AppColors.surfaceSecondaryDark
                                    : AppColors.surfaceSecondaryLight),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected
                                  ? signalBlue
                                  : (isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight),
                            ),
                          ),
                          child: Text(
                            category.name,
                            style: AppTypography.bodyM(
                              isSelected ? Colors.white : textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, stack) => Center(
                    child: Text('Error loading categories',
                        style: TextStyle(color: Colors.red)),
                  ),
                ),

                const Spacer(),

                // Save Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      child: const Text('Save'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
