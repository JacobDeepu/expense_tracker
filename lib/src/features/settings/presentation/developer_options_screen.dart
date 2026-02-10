import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/local/tables.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/logic/regex_parser.dart';

class DeveloperOptionsScreen extends ConsumerStatefulWidget {
  const DeveloperOptionsScreen({super.key});

  @override
  ConsumerState<DeveloperOptionsScreen> createState() =>
      _DeveloperOptionsScreenState();
}

class _DeveloperOptionsScreenState
    extends ConsumerState<DeveloperOptionsScreen> {
  final TextEditingController _textController = TextEditingController();
  ParsedTransaction? _result;
  final _parser = RegexParser();

  void _handleParse() {
    setState(() {
      _result = _parser.parse(_textController.text);
    });
  }

  Future<void> _handleSave() async {
    if (_result == null) return;

    await ref
        .read(transactionsRepositoryProvider)
        .addTransaction(
          amount: _result!.amount,
          merchantName: _result!.merchant,
          date: DateTime.now(),
          source: TransactionSource.autoNotification,
          type: _result!.type,
          rawText: _result!.originalText,
        );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction saved!')));
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

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.surfacePrimaryDark
          : AppColors.surfacePrimaryLight,
      appBar: AppBar(
        title: Text(
          'Developer Options',
          style: AppTypography.headingS(textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Simulation',
              style: AppTypography.headingS(textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Paste an SMS or notification text to test the regex parser.',
              style: AppTypography.bodyM(textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              maxLines: 5,
              style: AppTypography.bodyM(textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g., Paid ₹500 to Starbucks using UPI...',
                hintStyle: AppTypography.bodyM(textSecondary),
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: border),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleParse,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Parse Notification'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 32),
              Text(
                'Parsing Result',
                style: AppTypography.headingS(textPrimary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    _ResultRow(
                      label: 'Amount',
                      value: '₹${_result!.amount}',
                      isDark: isDark,
                    ),
                    const Divider(height: 24),
                    _ResultRow(
                      label: 'Merchant',
                      value: _result!.merchant,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),
                    _ResultRow(
                      label: 'Type',
                      value: _result!.type == TransactionType.income
                          ? 'Income'
                          : 'Expense',
                      valueColor: _result!.type == TransactionType.income
                          ? Colors.green
                          : Colors.red,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _handleSave,
                icon: const Icon(LucideIcons.save, size: 20),
                label: const Text('Save to Transactions'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: border),
                ),
              ),
            ] else if (_textController.text.isNotEmpty) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Could not parse text. Check your regex patterns.',
                        style: AppTypography.bodyM(Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 48),
            Text('Sample Phrases', style: AppTypography.headingS(textPrimary)),
            const SizedBox(height: 12),
            _SampleChip(
              text: 'Paid ₹250 to Zomato for order',
              onTap: (val) => setState(() => _textController.text = val),
            ),
            _SampleChip(
              text: 'Credited with ₹50,000 from HDFC Bank',
              onTap: (val) => setState(() => _textController.text = val),
            ),
            _SampleChip(
              text: 'Salary of ₹85,000 deposited by Tech Corp',
              onTap: (val) => setState(() => _textController.text = val),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _ResultRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyM(
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyM(
            valueColor ??
                (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight),
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SampleChip extends StatelessWidget {
  final String text;
  final Function(String) onTap;

  const _SampleChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ActionChip(
        label: Text(text),
        onPressed: () => onTap(text),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceSecondaryDark
            : AppColors.surfaceSecondaryLight,
      ),
    );
  }
}
