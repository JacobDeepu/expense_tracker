import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/local/database.dart';
import '../../onboarding/data/onboarding_data.dart';
import '../../onboarding/data/recurring_rules_repository.dart';
import '../../transactions/data/categories_repository.dart';

class RecurringExpensesScreen extends ConsumerWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? AppColors.surfacePrimaryDark
        : AppColors.surfacePrimaryLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final accent = isDark
        ? AppColors.signalBlueDark
        : AppColors.signalBlueLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final rulesAsync = ref.watch(recurringRulesProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: scaffoldBg,
        title: Text(
          'Recurring Expenses',
          style: AppTypography.headingM(textPrimary),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary, size: 24),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAddSheet(context, ref),
            customBorder: const CircleBorder(),
            child: const Center(
              child: Icon(LucideIcons.plus, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),
      body: rulesAsync.when(
        data: (rules) {
          if (rules.isEmpty) {
            return _buildEmptyState(textSecondary, accent, context, ref);
          }

          return categoriesAsync.when(
            data: (categories) {
              final categoryMap = {for (var c in categories) c.id: c};
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: rules.length,
                separatorBuilder: (_, i) => Divider(
                  height: 1,
                  thickness: 1,
                  indent: 24,
                  endIndent: 24,
                  color: border,
                ),
                itemBuilder: (context, index) {
                  final rule = rules[index];
                  final category = categoryMap[rule.categoryId];

                  return Dismissible(
                    key: Key('rule_${rule.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      color: Colors.red.withValues(alpha: 0.08),
                      child: Icon(
                        LucideIcons.trash2,
                        color: Colors.red.shade400,
                        size: 20,
                      ),
                    ),
                    confirmDismiss: (_) => _confirmDelete(context, isDark),
                    onDismissed: (_) {
                      ref
                          .read(recurringRulesRepositoryProvider)
                          .deleteRule(rule.id);
                    },
                    child: _buildRuleTile(
                      context,
                      ref,
                      rule,
                      category,
                      textPrimary,
                      textSecondary,
                      accent,
                      isDark,
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Failed to load categories',
                style: AppTypography.bodyM(Colors.red),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load expenses',
            style: AppTypography.bodyM(Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    Color textSecondary,
    Color accent,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.repeat,
            size: 48,
            color: textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No recurring expenses',
            style: AppTypography.bodyL(textSecondary),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _showAddSheet(context, ref),
            icon: Icon(LucideIcons.plus, size: 18, color: accent),
            label: Text('Add Expense', style: AppTypography.bodyM(accent)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: accent),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleTile(
    BuildContext context,
    WidgetRef ref,
    RecurringRule rule,
    Category? category,
    Color textPrimary,
    Color textSecondary,
    Color accent,
    bool isDark,
  ) {
    final frequencySuffix = _getFrequencySuffix(rule.frequencyDays);

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(LucideIcons.repeat, color: accent, size: 20),
        ),
        title: Text(
          rule.name,
          style: AppTypography.bodyL(
            textPrimary,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            category?.name ?? 'Uncategorized',
            style: AppTypography.bodyM(textSecondary),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${rule.estimatedAmount.toStringAsFixed(0)}',
              style: AppTypography.bodyL(
                textPrimary,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            Text(frequencySuffix, style: AppTypography.caption(textSecondary)),
          ],
        ),
        onTap: () => _showEditSheet(context, ref, rule, category),
      ),
    );
  }

  String _getFrequencySuffix(int days) {
    switch (days) {
      case 1:
        return '/day';
      case 7:
        return '/week';
      case 30:
        return '/month';
      case 365:
        return '/year';
      default:
        return '/$days days';
    }
  }

  Future<bool> _confirmDelete(BuildContext context, bool isDark) async {
    final surface = isDark
        ? AppColors.surfaceSecondaryDark
        : AppColors.surfaceSecondaryLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            title: Text(
              'Delete Expense?',
              style: AppTypography.headingS(textPrimary),
            ),
            content: Text(
              'This will stop tracking this recurring expense.',
              style: AppTypography.bodyM(
                isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
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
        ) ??
        false;
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditExpenseSheet(
        onSave: (name, amount, frequency, categoryId) {
          ref
              .read(recurringRulesRepositoryProvider)
              .addSingleRule(
                name: name,
                amount: amount,
                frequencyDays: frequency.days,
                categoryId: categoryId,
              );
        },
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    RecurringRule rule,
    Category? category,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditExpenseSheet(
        existingRule: rule,
        existingCategory: category,
        onSave: (name, amount, frequency, categoryId) {
          ref
              .read(recurringRulesRepositoryProvider)
              .updateRule(
                id: rule.id,
                name: name,
                amount: amount,
                frequencyDays: frequency.days,
                categoryId: categoryId,
              );
        },
      ),
    );
  }
}

/// Internal bottom sheet for add/edit
class _AddEditExpenseSheet extends ConsumerStatefulWidget {
  final RecurringRule? existingRule;
  final Category? existingCategory;
  final void Function(
    String name,
    double amount,
    ExpenseFrequency frequency,
    int? categoryId,
  )
  onSave;

  const _AddEditExpenseSheet({
    this.existingRule,
    this.existingCategory,
    required this.onSave,
  });

  @override
  ConsumerState<_AddEditExpenseSheet> createState() =>
      _AddEditExpenseSheetState();
}

class _AddEditExpenseSheetState extends ConsumerState<_AddEditExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late ExpenseFrequency _selectedFrequency;
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingRule?.name ?? '',
    );
    _amountController = TextEditingController(
      text: widget.existingRule?.estimatedAmount.toStringAsFixed(0) ?? '',
    );
    _selectedFrequency = _getFrequencyFromDays(
      widget.existingRule?.frequencyDays ?? 30,
    );
    _selectedCategory = widget.existingCategory;
  }

  ExpenseFrequency _getFrequencyFromDays(int days) {
    for (final freq in ExpenseFrequency.values) {
      if (freq.days == days) return freq;
    }
    return ExpenseFrequency.monthly;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave(
        _nameController.text.trim(),
        double.parse(_amountController.text),
        _selectedFrequency,
        _selectedCategory?.id,
      );
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
    final isEditing = widget.existingRule != null;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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
              Text(
                isEditing ? 'Edit Expense' : 'Add Expense',
                style: AppTypography.headingM(textPrimary),
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameController,
                style: AppTypography.bodyL(textPrimary),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: AppTypography.bodyM(textSecondary),
                  hintText: 'e.g., Netflix, Rent',
                  hintStyle: AppTypography.bodyM(
                    textSecondary.withValues(alpha: 0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: AppTypography.bodyL(textPrimary),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: AppTypography.bodyM(textSecondary),
                  prefixText: '₹ ',
                  prefixStyle: AppTypography.bodyL(textPrimary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final amt = double.tryParse(v);
                  if (amt == null || amt <= 0) return 'Invalid';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Frequency
              Text(
                'FREQUENCY',
                style: AppTypography.captionUppercase(
                  textSecondary,
                ).copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ExpenseFrequency.values.map((freq) {
                  final isSelected = freq == _selectedFrequency;
                  return ChoiceChip(
                    label: Text(freq.label),
                    selected: isSelected,
                    onSelected: (s) {
                      if (s) setState(() => _selectedFrequency = freq);
                    },
                    selectedColor: accent.withValues(alpha: 0.15),
                    backgroundColor: Colors.transparent,
                    labelStyle: AppTypography.bodyM(
                      isSelected ? accent : textPrimary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
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

              // Category
              Text(
                'CATEGORY',
                style: AppTypography.captionUppercase(
                  textSecondary,
                ).copyWith(letterSpacing: 1.2),
              ),
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
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    dropdownColor: surface,
                    style: AppTypography.bodyL(textPrimary),
                    items: categories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c.name));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    Text('Error', style: AppTypography.bodyM(Colors.red)),
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
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Add Expense',
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
