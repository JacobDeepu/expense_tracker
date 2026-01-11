import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/preferences_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;

  final List<String> _categories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Utilities',
    'Health & Fitness',
    'Groceries',
  ];

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
    if (_amountController.text.isEmpty) {
      return;
    }

    // Save logged date (mock for Phase 2)
    final prefsService = PreferencesService();
    await prefsService.saveLastLoggedDate(DateTime.now());

    // TODO: Save transaction to database
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
                  ),
                ),

                const SizedBox(height: 64),

                // Category Selection
                Text(
                  'CATEGORY',
                  style: AppTypography.captionUppercase(textSecondary),
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
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
                          category,
                          style: AppTypography.bodyM(
                            isSelected ? Colors.white : textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
