class ParsedTransaction {
  final double amount;
  final String merchant;
  final String originalText;

  ParsedTransaction({
    required this.amount,
    required this.merchant,
    required this.originalText,
  });

  @override
  String toString() => 'Parsed(amount: $amount, merchant: $merchant)';
}

class RegexParser {
  // Matches: ₹ 200, Rs. 200, INR 200.00
  static final RegExp _amountRegex = RegExp(
    r'(?:INR|Rs\.?|₹)\s*(?<amount>[\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // Common payment patterns
  static final List<RegExp> _merchantPatterns = [
    RegExp(r'(?:paid to|sent to|transfer to)\s+(?<merchant>.+?)(?:\s+(?:on|using|via|ref|upi)|$)', caseSensitive: false),
    RegExp(r'(?:at|to)\s+(?<merchant>.+?)(?:\s+(?:on|using|via)|$)', caseSensitive: false),
  ];

  ParsedTransaction? parse(String text) {
    // 1. Extract Amount
    final amountMatch = _amountRegex.firstMatch(text);
    if (amountMatch == null) return null;

    String amountStr = amountMatch.namedGroup('amount')!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null) return null;

    // 2. Extract Merchant
    String merchant = 'Unknown';
    for (final pattern in _merchantPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        merchant = match.namedGroup('merchant')?.trim() ?? 'Unknown';
        // Clean up merchant name (remove trailing punctuation)
        merchant = merchant.replaceAll(RegExp(r'[^\w\s]$'), '');
        break;
      }
    }

    return ParsedTransaction(
      amount: amount,
      merchant: merchant,
      originalText: text,
    );
  }
}
