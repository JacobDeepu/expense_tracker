import '../../../data/local/tables.dart';

class ParsedTransaction {
  final double amount;
  final String merchant;
  final TransactionType type;
  final String originalText;

  ParsedTransaction({
    required this.amount,
    required this.merchant,
    required this.type,
    required this.originalText,
  });

  @override
  String toString() =>
      'Parsed(amount: $amount, merchant: $merchant, type: $type)';
}

class RegexParser {
  // Matches: ₹ 200, Rs. 200, INR 200.00
  static final RegExp _amountRegex = RegExp(
    r'(?:INR|Rs\.?|₹)\s*(?<amount>[\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // Common payment patterns
  static final List<RegExp> _expensePatterns = [
    RegExp(
      r'(?:paid to|sent to|transfer to)\s+(?<merchant>.+?)(?:\s+(?:on|using|via|ref|upi)|$)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:spent|at|to)\s+(?<merchant>.+?)(?:\s+(?:on|using|via)|$)',
      caseSensitive: false,
    ),
  ];

  // Common income patterns
  static final List<RegExp> _incomePatterns = [
    RegExp(
      r'(?:credited with|received|deposited)\s+(?:amount of\s*)?(?:INR|Rs\.?|₹)\s*(?:[\d,]+(?:\.\d{1,2})?)?\s*(?:from|by)\s+(?<merchant>.+?)(?:\s+(?:on|using|via|ref|upi)|$)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?<merchant>.+?)\s+(?:has credited|sent|deposited)\s+(?:INR|Rs\.?|₹)',
      caseSensitive: false,
    ),
  ];

  ParsedTransaction? parse(String text) {
    // 1. Extract Amount
    final amountMatch = _amountRegex.firstMatch(text);
    if (amountMatch == null) return null;

    String amountStr = amountMatch.namedGroup('amount')!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null) return null;

    // 2. Identify Type and Merchant
    // Check Income first
    for (final pattern in _incomePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return ParsedTransaction(
          amount: amount,
          merchant: _cleanMerchant(match.namedGroup('merchant') ?? 'Income'),
          type: TransactionType.income,
          originalText: text,
        );
      }
    }

    // Check Expense
    String merchant = 'Unknown';
    for (final pattern in _expensePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        merchant = _cleanMerchant(match.namedGroup('merchant') ?? 'Unknown');
        break;
      }
    }

    return ParsedTransaction(
      amount: amount,
      merchant: merchant,
      type: TransactionType.expense,
      originalText: text,
    );
  }

  String _cleanMerchant(String merchantName) {
    var cleaned = merchantName.trim();
    // Remove trailing punctuation
    cleaned = cleaned.replaceAll(RegExp(r'[^\w\s]$'), '');
    return cleaned;
  }
}
