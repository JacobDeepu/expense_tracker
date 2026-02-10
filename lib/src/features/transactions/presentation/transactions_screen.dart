import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/category_icons.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables.dart';
import '../data/transactions_repository.dart';
import 'widgets/edit_transaction_sheet.dart';

/// Filter options for transactions
enum TransactionFilter { all, today, thisWeek, thisMonth }

/// Transactions list screen with date-wise grouping and filters
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionFilter _currentFilter = TransactionFilter.all;

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

    final transactionsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.surfacePrimaryDark
          : AppColors.surfacePrimaryLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
        ),
        title: Text('Activity', style: AppTypography.headingM(textPrimary)),
        actions: [
          IconButton(
            onPressed: () => _showFilterSheet(context),
            icon: Icon(
              LucideIcons.filter,
              color: _currentFilter != TransactionFilter.all
                  ? AppColors.signalBlueLight
                  : textSecondary,
            ),
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          final filtered = _filterTransactions(transactions);
          if (filtered.isEmpty) {
            return _buildEmptyState(textSecondary);
          }

          final grouped = _groupByDate(filtered);

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final dateKey = grouped.keys.elementAt(index);
              final dayTransactions = grouped[dateKey]!;

              return _buildDateSection(
                context,
                dateKey,
                dayTransactions,
                isDark,
                textPrimary,
                textSecondary,
                surface,
                border,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_currentFilter) {
      case TransactionFilter.all:
        return transactions;
      case TransactionFilter.today:
        return transactions.where((t) {
          final txDate = DateTime(t.date.year, t.date.month, t.date.day);
          return txDate == today;
        }).toList();
      case TransactionFilter.thisWeek:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return transactions.where((t) {
          final txDate = DateTime(t.date.year, t.date.month, t.date.day);
          return txDate.isAfter(weekStart.subtract(const Duration(days: 1)));
        }).toList();
      case TransactionFilter.thisMonth:
        return transactions.where((t) {
          return t.date.year == now.year && t.date.month == now.month;
        }).toList();
    }
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final tx in transactions) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String key;

      if (txDate == today) {
        key = 'Today';
      } else if (txDate == yesterday) {
        key = 'Yesterday';
      } else if (txDate.year == now.year) {
        key = DateFormat('EEEE, d MMM').format(txDate);
      } else {
        key = DateFormat('d MMM yyyy').format(txDate);
      }

      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return grouped;
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.inbox, size: 48, color: textSecondary),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: AppTypography.bodyL(textSecondary),
          ),
          if (_currentFilter != TransactionFilter.all) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentFilter = TransactionFilter.all;
                });
              },
              child: const Text('Clear filter'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateSection(
    BuildContext context,
    String dateKey,
    List<Transaction> transactions,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surface,
    Color border,
  ) {
    // Calculate net total for the day (Income - Expense)
    final netTotal = transactions.fold<double>(0, (sum, tx) {
      if (tx.type == TransactionType.income) return sum + tx.amount;
      return sum - tx.amount;
    });

    final isPositive = netTotal >= 0;
    final signalGreen = isDark
        ? AppColors.insightPositiveDark
        : AppColors.insightPositiveLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateKey.toUpperCase(),
                style: AppTypography.captionUppercase(textSecondary),
              ),
              Text(
                '${isPositive ? '+' : '-'}₹${netTotal.abs().toStringAsFixed(0)}',
                style: AppTypography.bodyMTabular(
                  isPositive ? signalGreen : textSecondary,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceSecondaryDark
                : AppColors.surfacePrimaryLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            children: transactions.asMap().entries.map((entry) {
              final index = entry.key;
              final tx = entry.value;

              return Column(
                children: [
                  _buildTransactionRow(
                    context,
                    tx,
                    isDark,
                    textPrimary,
                    textSecondary,
                    isFirst: index == 0,
                    isLast: index == transactions.length - 1,
                  ),
                  if (index < transactions.length - 1)
                    Divider(height: 1, indent: 70, color: border),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTransactionRow(
    BuildContext context,
    Transaction tx,
    bool isDark,
    Color textPrimary,
    Color textSecondary, {
    required bool isFirst,
    required bool isLast,
  }) {
    final categoryIcon = CategoryIcons.getIcon('other');
    final categoryColor = CategoryIcons.getColor('other', isDark);

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => EditTransactionSheet(transaction: tx),
        );
      },
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(categoryIcon, size: 20, color: categoryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.merchantName,
                    style: AppTypography.bodyM(
                      textPrimary,
                    ).copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('h:mm a').format(tx.date),
                    style: AppTypography.caption(textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              '${tx.type == TransactionType.income ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}',
              style: AppTypography.bodyMTabular(
                tx.type == TransactionType.income
                    ? (isDark
                          ? AppColors.insightPositiveDark
                          : AppColors.insightPositiveLight)
                    : textPrimary,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
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

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter by', style: AppTypography.headingM(textPrimary)),
                const SizedBox(height: 20),
                ...TransactionFilter.values.map((filter) {
                  final isSelected = filter == _currentFilter;
                  final label = switch (filter) {
                    TransactionFilter.all => 'All transactions',
                    TransactionFilter.today => 'Today',
                    TransactionFilter.thisWeek => 'This week',
                    TransactionFilter.thisMonth => 'This month',
                  };

                  return ListTile(
                    onTap: () {
                      setState(() {
                        _currentFilter = filter;
                      });
                      Navigator.pop(context);
                    },
                    leading: Icon(
                      isSelected
                          ? LucideIcons.checkCircle2
                          : LucideIcons.circle,
                      color: isSelected ? signalBlue : textSecondary,
                    ),
                    title: Text(
                      label,
                      style: AppTypography.bodyL(
                        isSelected ? signalBlue : textPrimary,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Provider for all transactions sorted by date descending
final allTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final repository = ref.watch(transactionsRepositoryProvider);
  return repository.watchAllTransactions();
});
