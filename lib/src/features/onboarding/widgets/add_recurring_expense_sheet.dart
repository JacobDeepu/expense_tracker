import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/local/database.dart';
import '../../transactions/data/categories_repository.dart';
import '../data/onboarding_data.dart';

/// Bottom sheet for adding custom recurring expenses
class AddRecurringExpenseSheet extends ConsumerStatefulWidget {
  final void Function(OnboardingCard) onSave;

  const AddRecurringExpenseSheet({super.key, required this.onSave});

  @override
  ConsumerState<AddRecurringExpenseSheet> createState() =>
      _AddRecurringExpenseSheetState();
}

class _AddRecurringExpenseSheetState
    extends ConsumerState<AddRecurringExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  ExpenseFrequency _selectedFrequency = ExpenseFrequency.monthly;
  Category? _selectedCategory;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final card = OnboardingCard(
        name: _nameController.text.trim(),
        estimatedAmount: double.parse(_amountController.text),
        category: _selectedCategory?.name ?? 'Other',
        frequency: _selectedFrequency,
        description: 'Custom expense',
      );
      widget.onSave(card);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.surfaceSecondaryDark
        : AppColors.surfaceSecondaryLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final accent = isDark
        ? AppColors.signalBlueDark
        : AppColors.signalBlueLight;

    final categoriesAsync = ref.watch(categoriesListProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Add Expense', style: AppTypography.headingM(textPrimary)),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                style: AppTypography.bodyL(textPrimary),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: AppTypography.bodyM(textSecondary),
                  hintText: 'e.g., Netflix, Gym, Rent',
                  hintStyle: AppTypography.bodyM(
                    textSecondary.withValues(alpha: 0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTypography.bodyL(textPrimary),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: AppTypography.bodyM(textSecondary),
                  prefixText: '₹ ',
                  prefixStyle: AppTypography.bodyL(textPrimary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Amount is required';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Frequency selector
              Text('Frequency', style: AppTypography.bodyM(textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ExpenseFrequency.values.map((freq) {
                  final isSelected = freq == _selectedFrequency;
                  return ChoiceChip(
                    label: Text(freq.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFrequency = freq);
                      }
                    },
                    selectedColor: accent.withValues(alpha: 0.2),
                    labelStyle: AppTypography.bodyM(
                      isSelected ? accent : textPrimary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? accent
                            : textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Category dropdown
              Text('Category', style: AppTypography.bodyM(textSecondary)),
              const SizedBox(height: 8),
              categoriesAsync.when(
                data: (categories) {
                  _selectedCategory ??= categories.isNotEmpty
                      ? categories.first
                      : null;
                  return DropdownButtonFormField<Category>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    dropdownColor: surface,
                    style: AppTypography.bodyL(textPrimary),
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Text(
                  'Failed to load categories',
                  style: AppTypography.bodyM(Colors.red),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add Expense',
                    style: AppTypography.bodyL(
                      Colors.white,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show the add expense bottom sheet
Future<void> showAddExpenseSheet(
  BuildContext context,
  void Function(OnboardingCard) onSave,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddRecurringExpenseSheet(onSave: onSave),
  );
}
