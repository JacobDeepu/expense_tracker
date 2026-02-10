import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/category_icons.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables.dart';
import '../data/categories_repository.dart';
import '../data/transactions_repository.dart';
import '../logic/ocr/receipt_scanner_service.dart';

class OcrReviewSheet extends ConsumerStatefulWidget {
  final ReceiptScanResult scanResult;
  final int? recurringRuleId;

  const OcrReviewSheet({
    required this.scanResult,
    this.recurringRuleId,
    super.key,
  });

  @override
  ConsumerState<OcrReviewSheet> createState() => _OcrReviewSheetState();
}

class _OcrReviewSheetState extends ConsumerState<OcrReviewSheet> {
  late final TextEditingController _merchantController;
  late final TextEditingController _totalController;
  late DateTime _selectedDate;
  late List<ReceiptLineItem> _items;
  Category? _selectedCategory;
  final TransactionType _type = TransactionType.expense;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.scanResult.merchantName ?? '',
    );
    _totalController = TextEditingController(
      text: widget.scanResult.totalAmount?.toStringAsFixed(2) ?? '',
    );
    _selectedDate = widget.scanResult.date ?? DateTime.now();
    _items = List.from(widget.scanResult.items);
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  void _addManualItem() {
    setState(() {
      _items.add(
        ReceiptLineItem(name: 'New Item', amount: 0.0, confidence: 1.0),
      );
    });
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
      // Recalculate total if no explicit total
      if (widget.scanResult.totalAmount == null && _items.isNotEmpty) {
        final sum = _items.fold(0.0, (sum, item) => sum + item.amount);
        _totalController.text = sum.toStringAsFixed(2);
      }
    });
  }

  void _updateItem(int index, ReceiptLineItem newItem) {
    setState(() {
      _items[index] = newItem;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  double? get _calculatedItemsSum {
    if (_items.isEmpty) return null;
    return _items.fold<double>(0.0, (sum, item) => sum + item.amount);
  }

  bool get _hasAmountMismatch {
    final total = double.tryParse(_totalController.text);
    final itemsSum = _calculatedItemsSum;
    if (total == null || itemsSum == null) return false;

    final difference = (total - itemsSum).abs();
    return difference > (total * 0.01); // 1% tolerance
  }

  Future<void> _handleSave() async {
    final total = double.tryParse(_totalController.text);
    if (total == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount and select a category'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(transactionsRepositoryProvider)
          .addTransaction(
            amount: total,
            merchantName: _merchantController.text.isEmpty
                ? 'Receipt Scan'
                : _merchantController.text,
            date: _selectedDate,
            source: TransactionSource.ocr,
            type: _type,
            categoryId: _selectedCategory!.id,
            recurringRuleId: widget.recurringRuleId,
            rawText: widget.scanResult.rawText,
            items: _items.isEmpty ? null : _items,
          );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
                children: [
                  Icon(LucideIcons.scanLine, color: textPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Scanned Receipt',
                          style: AppTypography.headingM(textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.scanResult.confidence > 0)
                          Text(
                            'Confidence: ${(widget.scanResult.confidence * 100).toStringAsFixed(0)}%',
                            style: AppTypography.bodyS(textSecondary),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(LucideIcons.x, color: textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
                    // Merchant Name
                    _buildSectionLabel('Merchant', textSecondary),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _merchantController,
                      style: AppTypography.bodyL(textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter merchant name',
                        hintStyle: AppTypography.bodyL(textSecondary),
                        filled: true,
                        fillColor: surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Date
                    _buildSectionLabel('Date', textSecondary),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              color: textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: AppTypography.bodyL(textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Line Items
                    if (_items.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionLabel(
                            'Items (${_items.length})',
                            textSecondary,
                          ),
                          TextButton.icon(
                            onPressed: _addManualItem,
                            icon: const Icon(LucideIcons.plus, size: 16),
                            label: const Text('Add Item'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_items.length, (index) {
                        return _ItemRow(
                          item: _items[index],
                          onUpdate: (newItem) => _updateItem(index, newItem),
                          onDelete: () => _deleteItem(index),
                          isDark: isDark,
                        );
                      }),

                      // Items Sum
                      if (_calculatedItemsSum != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Items Total:',
                                style: AppTypography.bodyM(
                                  textSecondary,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '₹${_calculatedItemsSum!.toStringAsFixed(2)}',
                                style: AppTypography.bodyM(
                                  textPrimary,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 8),
                    ],

                    // Total Amount
                    _buildSectionLabel('Total Amount', textSecondary),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _totalController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      style: AppTypography.displayL(textPrimary),
                      decoration: InputDecoration(
                        prefix: Text(
                          '₹ ',
                          style: AppTypography.displayL(textSecondary),
                        ),
                        hintText: '0.00',
                        hintStyle: AppTypography.displayL(textSecondary),
                        filled: true,
                        fillColor: surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),

                    // Mismatch Warning
                    if (_hasAmountMismatch)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? AppColors.insightWarningDark
                                        : AppColors.insightWarningLight)
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.insightWarningDark
                                  : AppColors.insightWarningLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.alertTriangle,
                                size: 16,
                                color: isDark
                                    ? AppColors.insightWarningDark
                                    : AppColors.insightWarningLight,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Total doesn\'t match items sum (taxes/discounts may apply)',
                                  style: AppTypography.bodyS(
                                    isDark
                                        ? AppColors.insightWarningDark
                                        : AppColors.insightWarningLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Category Selection
                    _buildSectionLabel('Category', textSecondary),
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
                              setState(() => _selectedCategory = category);
                              HapticFeedback.selectionClick();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? categoryColor : surface,
                                borderRadius: BorderRadius.circular(12),
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
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : categoryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    category.name,
                                    style: AppTypography.bodyS(
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
                      error: (_, _) => const Text('Error loading categories'),
                    ),
                  ],
                ),
              ),
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        side: BorderSide(color: border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.check, size: 18),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Save Transaction',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color) {
    return Text(
      label,
      style: AppTypography.bodyM(color).copyWith(fontWeight: FontWeight.w500),
    );
  }
}

class _ItemRow extends StatefulWidget {
  final ReceiptLineItem item;
  final Function(ReceiptLineItem) onUpdate;
  final VoidCallback onDelete;
  final bool isDark;

  const _ItemRow({
    required this.item,
    required this.onUpdate,
    required this.onDelete,
    required this.isDark,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _amountController = TextEditingController(
      text: widget.item.amount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateItem() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    widget.onUpdate(
      widget.item.copyWith(name: _nameController.text, amount: amount),
    );
  }

  Color _getConfidenceColor() {
    if (widget.item.confidence >= 0.7) {
      return widget.isDark
          ? AppColors.insightPositiveDark
          : AppColors.insightPositiveLight;
    } else if (widget.item.confidence >= 0.4) {
      return widget.isDark
          ? AppColors.insightWarningDark
          : AppColors.insightWarningLight;
    } else {
      return widget.isDark ? AppColors.signalRedDark : AppColors.signalRedLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = widget.isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final surface = widget.isDark
        ? AppColors.surfaceSecondaryDark
        : AppColors.surfaceSecondaryLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Confidence indicator
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: _getConfidenceColor(),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Item name
          Expanded(
            child: TextField(
              controller: _nameController,
              onChanged: (_) => _updateItem(),
              style: AppTypography.bodyM(textPrimary),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Item name',
                hintStyle: AppTypography.bodyM(textSecondary),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Amount
          Container(
            width: 90, // Increased width for better visibility
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.black12 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextField(
              controller: _amountController,
              onChanged: (_) => _updateItem(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              textAlign: TextAlign.right,
              style: AppTypography.bodyM(
                textPrimary,
              ).copyWith(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                prefixText: '₹', // Changed to prefixText for better layout
                prefixStyle: AppTypography.bodyS(textSecondary),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Delete button
          IconButton(
            onPressed: widget.onDelete,
            icon: Icon(LucideIcons.trash2, size: 16, color: textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
