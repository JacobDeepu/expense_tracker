import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/ocr_models.dart';
import 'utils/ocr_parser_utils.dart';
import 'utils/spatial_engine.dart';

class ReceiptLineItem {
  final String name;
  final double amount;
  final int quantity;
  final double confidence; // 0.0 to 1.0

  ReceiptLineItem({
    required this.name,
    required this.amount,
    this.quantity = 1,
    this.confidence = 1.0,
  });

  ReceiptLineItem copyWith({
    String? name,
    double? amount,
    int? quantity,
    double? confidence,
  }) {
    return ReceiptLineItem(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      quantity: quantity ?? this.quantity,
      confidence: confidence ?? this.confidence,
    );
  }
}

class ReceiptScanResult {
  final double? totalAmount;
  final DateTime? date;
  final String? merchantName;
  final List<ReceiptLineItem> items;
  final String rawText;
  final String imagePath;
  final double confidence; // Overall confidence score

  ReceiptScanResult({
    this.totalAmount,
    this.date,
    this.merchantName,
    required this.items,
    required this.rawText,
    required this.imagePath,
    this.confidence = 0.0,
  });
}

class ReceiptScannerService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  final SpatialEngine _spatialEngine = SpatialEngine();

  Future<ReceiptScanResult?> scanReceipt() async {
    // 1. Pick Image
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    // 2. OCR
    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText = await _recognizer.processImage(
      inputImage,
    );
    final String text = recognizedText.text;

    // 3. Extract structured data
    final List<ReceiptLineItem> items = _extractLineItems(recognizedText);
    final String? merchantName = OcrParserUtils.extractMerchantName(text);
    final DateTime? date = OcrParserUtils.extractDate(text);
    final double? totalAmount = _extractTotalAmount(text, items);

    // 4. Calculate confidence
    final double confidence = _calculateConfidence(
      items: items,
      totalAmount: totalAmount,
      merchantName: merchantName,
      date: date,
    );

    return ReceiptScanResult(
      totalAmount: totalAmount,
      date: date,
      merchantName: merchantName,
      items: items,
      rawText: text,
      imagePath: image.path,
      confidence: confidence,
    );
  }

  /// Extract line items using spatial analysis
  List<ReceiptLineItem> _extractLineItems(RecognizedText recognizedText) {
    // 1. Group all lines vertically
    final List<SpatialLine> spatialLines = _spatialEngine
        .groupLinesByVerticalPosition(recognizedText);

    // 2. Detect headers and columns
    final Map<String, ReceiptColumn> columns = _spatialEngine.detectColumns(
      spatialLines,
    );

    final List<ReceiptLineItem> items = [];
    final List<SpatialItemCandidate> candidates = [];

    // Keywords to exclude specifically from being item names
    final excludeKeywords = [
      'total',
      'subtotal',
      'tax',
      'gst',
      'cgst',
      'sgst',
      'vat',
      'discount',
      'cash',
      'card',
      'change',
      'balance',
      'items',
      'qty',
      'rate',
      'price',
      'amount',
      'net',
      'payable',
      'savings',
      'thank',
      'visit',
      'round off',
      'you have saved',
      'total savings',
      'savings',
      'saved',
    ];

    // 3. Strategy Selection: Tabular vs. Heuristic
    bool useTabular = false;
    ReceiptColumn? amountCol;
    ReceiptColumn? nameCol;

    if (columns.containsKey('amount')) {
      amountCol = columns['amount'];
      nameCol = columns['item'];
      useTabular = true;
    }

    if (useTabular && amountCol != null) {
      // 3a. Tabular Extraction
      for (final line in spatialLines) {
        // Skip header lines
        if (line.text.toLowerCase().contains('amount') ||
            line.text.toLowerCase().contains('price') ||
            line.text.toLowerCase().contains('item') ||
            line.text.toLowerCase().contains('saved') ||
            line.text.toLowerCase().contains('saving')) {
          continue;
        }

        // Try to find amount strictly in the amount column
        final amountText = _spatialEngine.getTextInColumn(line, amountCol);
        if (amountText == null) continue;

        final amount = OcrParserUtils.parseAmount(amountText);
        if (amount != null && amount > 0) {
          String name = '';
          if (nameCol != null) {
            name = _spatialEngine.getTextInColumn(line, nameCol) ?? '';
          }

          if (name.isEmpty) {
            // Fallback: take all text to the left of amount
            name = _spatialEngine.getTextToLeftOfColumn(line, amountCol);
          }

          if (name.isNotEmpty &&
              !excludeKeywords.any((k) => name.toLowerCase().contains(k))) {
            candidates.add(
              SpatialItemCandidate(
                name: name.trim(),
                amount: amount,
                position: line.top,
                confidence: 0.9,
                lineHeight: line.height,
              ),
            );
          }
        }
      }
    } else {
      // 3b. Fallback Heuristic Extraction
      for (final line in spatialLines) {
        final text = line.text;

        // Rigorous filtering
        if (text.toLowerCase().contains('saved') ||
            text.toLowerCase().contains('saving') ||
            text.toLowerCase().contains('you have')) {
          continue;
        }

        // Find all amounts in the line
        final validAmounts = _findAllAmountsInLine(line.text);

        if (validAmounts.isEmpty) continue;

        // Heuristic: The Right-Most Amount is usually the line total
        // (Item Name, Rate, Qty, Amount)
        // We take the last one.
        final double amount = validAmounts.last;

        if (amount > 0) {
          final name = OcrParserUtils.extractItemName(text);
          if (name.isNotEmpty &&
              name.length > 2 &&
              !excludeKeywords.any((k) => name.toLowerCase().contains(k))) {
            final confidence = _calculateItemConfidence(text, name, amount);
            candidates.add(
              SpatialItemCandidate(
                name: name,
                amount: amount,
                position: line.top,
                confidence: confidence,
                lineHeight: line.height,
              ),
            );
          }
        }
      }
    }

    // Sort by vertical position
    candidates.sort((a, b) => a.position.compareTo(b.position));

    // Dedup and build final list
    for (final candidate in candidates) {
      if (items.any(
        (item) =>
            (item.name == candidate.name && item.amount == candidate.amount),
      )) {
        continue;
      }

      items.add(
        ReceiptLineItem(
          name: candidate.name,
          amount: candidate.amount,
          confidence: candidate.confidence,
        ),
      );
    }

    return items;
  }

  // Helper to find all valid amounts in a line, returning them in order of appearance
  List<double> _findAllAmountsInLine(String line) {
    final regex = RegExp(
      r'(?:₹|Rs\.?|INR|\$)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})|\d+(?:\.\d{2}))(?!\d)',
      caseSensitive: false,
    );
    final matches = regex.allMatches(line);
    final List<double> amounts = [];

    for (final match in matches) {
      String numStr = match.group(1)?.replaceAll(',', '') ?? '';
      final amount = double.tryParse(numStr);
      if (amount != null && amount > 0 && amount < 100000) {
        // Skip years
        if (amount >= 2020 && amount <= 2030 && !line.contains('.')) continue;
        amounts.add(amount);
      }
    }
    return amounts;
  }

  /// Calculate confidence for the overall scan result
  double _calculateConfidence({
    required List<ReceiptLineItem> items,
    double? totalAmount,
    String? merchantName,
    DateTime? date,
  }) {
    double score = 0.0;
    int factors = 0;

    if (items.isNotEmpty) {
      score += 0.4;
      factors++;
      final double avgItemConfidence =
          items.fold(0.0, (sum, item) => sum + item.confidence) / items.length;
      score += avgItemConfidence * 0.3;
      factors++;
    }

    if (totalAmount != null) {
      score += 0.2;
      factors++;
      if (items.isNotEmpty) {
        final double sumOfItems = items.fold(
          0.0,
          (sum, item) => sum + item.amount,
        );
        if ((totalAmount - sumOfItems).abs() < 0.1) {
          score += 0.1;
          factors++;
        }
      }
    }

    if (merchantName != null && merchantName.isNotEmpty) {
      score += 0.1;
      factors++;
    }

    if (date != null) {
      score += 0.1;
      factors++;
    }

    if (factors > 0) {
      score = score / (factors * 0.2);
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculate confidence for an extracted item
  double _calculateItemConfidence(String line, String itemName, double amount) {
    double score = 0.5;
    if (line.contains('₹') || line.toLowerCase().contains('rs')) score += 0.2;
    if (itemName.length > 3 && RegExp(r'[a-zA-Z]{3,}').hasMatch(itemName)) {
      score += 0.2;
    }
    if (itemName.length < 3) score -= 0.3;
    return score.clamp(0.0, 1.0);
  }

  /// Improved total amount extraction with item validation
  double? _extractTotalAmount(String text, List<ReceiptLineItem> items) {
    final lines = text.split('\n');
    double? detectedTotal;

    final totalKeywords = [
      'total',
      'grand total',
      'net amount',
      'amount payable',
      'payable',
      'bill amount',
      'total due',
      'net to pay',
      'final amount',
      'total amt',
      'total (incl tax)',
    ];

    // 1. Look for explicit total keywords
    for (final line in lines.reversed) {
      final lowerLine = line.toLowerCase();
      bool hasKeyword = totalKeywords.any((k) => lowerLine.contains(k));

      if (hasKeyword) {
        final amount = OcrParserUtils.parseAmount(line);
        if (amount != null) {
          detectedTotal = amount;
          break;
        }
      }
    }

    // 2. If we have items but no total, sum the items
    if (detectedTotal == null && items.isNotEmpty) {
      detectedTotal = items.fold<double>(0.0, (sum, item) => sum + item.amount);
    }

    // 3. Fallback: largest amount in bottom 50%
    if (detectedTotal == null) {
      final int startIdx = (lines.length * 0.5).floor();
      double? maxAmount;

      for (int i = startIdx; i < lines.length; i++) {
        final amount = OcrParserUtils.parseAmount(lines[i]);
        if (amount != null && amount > 0) {
          if (maxAmount == null || amount > maxAmount) {
            maxAmount = amount;
          }
        }
      }
      detectedTotal = maxAmount;
    }

    return detectedTotal;
  }

  void dispose() {
    _recognizer.close();
  }
}

final receiptScannerServiceProvider = Provider<ReceiptScannerService>((ref) {
  final service = ReceiptScannerService();
  ref.onDispose(() => service.dispose());
  return service;
});
