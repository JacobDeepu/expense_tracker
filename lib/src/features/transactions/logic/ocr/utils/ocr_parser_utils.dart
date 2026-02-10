import 'package:intl/intl.dart';

class OcrParserUtils {
  /// Parse amount from a line of text
  static double? parseAmount(String line) {
    // Improved regex for currency amounts:
    // 1. Optional currency symbols
    // 2. Digits with possible commas (thousands separator)
    // 3. Mandatory or optional decimal part
    final regex = RegExp(
      r'(?:₹|Rs\.?|INR|\$)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})|\d+(?:\.\d{2}))(?!\d)',
      caseSensitive: false,
    );

    // Fallback regex if first one misses (simpler but might match years)
    final fallbackRegex = RegExp(r'(\d+(?:\.\d{2})|\d{2,}\.?\d{0,2})');

    final matches = regex.allMatches(line);
    for (final match in matches) {
      String numStr = match.group(1)?.replaceAll(',', '') ?? '';
      final amount = double.tryParse(numStr);

      if (amount != null) {
        // Filter out unlikely amounts or years unless it's clearly an amount
        if (amount > 1000000) continue;

        final yearRegex = RegExp(r'\b(20[2-9]\d)\b');
        if (yearRegex.hasMatch(line) &&
            line.contains(amount.toStringAsFixed(0))) {
          // If the amount is found inside a year string, ignore it
          if (amount >= 2020 && amount <= 2030) continue;
        }

        return amount;
      }
    }

    // Try fallback
    final fallbackMatches = fallbackRegex.allMatches(line);
    for (final match in fallbackMatches) {
      String numStr = match.group(1)?.replaceAll(',', '') ?? '';
      final amount = double.tryParse(numStr);
      if (amount != null && amount > 0) {
        if (amount >= 2020 && amount <= 2030 && !line.contains('.')) continue;
        return amount;
      }
    }

    return null;
  }

  /// Extract item name from a line containing both name and amount
  static String extractItemName(String line) {
    // Remove amount pattern from line to get item name
    final amountRegex = RegExp(
      r'(?:₹|Rs\.?|INR)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)',
    );
    final cleanLine = line.replaceAll(amountRegex, '').trim();

    // Remove common quantity patterns (e.g., "2x", "3 x", "@ 2")
    final qtyPattern = RegExp(r'\d+\s*[x@]|\@\s*\d+', caseSensitive: false);
    final withoutQty = cleanLine.replaceAll(qtyPattern, '').trim();

    return withoutQty.isEmpty ? cleanLine : withoutQty;
  }

  /// Try to parse a date from a string
  static DateTime? extractDate(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      final dateMatch = _parseDateLine(line);
      if (dateMatch != null) return dateMatch;
    }
    return null; // Fallback handled by caller
  }

  static DateTime? _parseDateLine(String text) {
    // Date patterns
    final patterns = [
      RegExp(r'\b(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4})\b'),
      RegExp(
        r'\b(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4})\b',
        caseSensitive: false,
      ),
    ];

    final dateFormats = [
      DateFormat('dd/MM/yyyy'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('dd.MM.yyyy'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('dd/MM/yy'),
      DateFormat('dd-MM-yy'),
      DateFormat('dd MMM yyyy'),
      DateFormat('dd MMM yy'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final dateStr = match.group(1)!;

        for (final format in dateFormats) {
          try {
            return format.parseStrict(dateStr);
          } catch (_) {
            continue;
          }
        }
      }
    }

    return null;
  }

  /// Extract merchant/store name (usually at top of receipt)
  static String? extractMerchantName(String text) {
    final lines = text.split('\n');

    // Look in first 5 lines for merchant name
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i].trim();

      // Skip very short lines or lines with dates/numbers
      if (line.length < 3) continue;
      if (RegExp(r'^\d').hasMatch(line)) continue;
      if (_parseDateLine(line) != null) continue;

      // Look for lines with merchant-like patterns
      if (line.length >= 5 && line.length <= 50) {
        // Prefer lines that are mostly alphabetic
        final alphaRatio =
            line.replaceAll(RegExp(r'[^a-zA-Z]'), '').length / line.length;
        if (alphaRatio > 0.5) {
          return line;
        }
      }
    }

    return null;
  }
}
