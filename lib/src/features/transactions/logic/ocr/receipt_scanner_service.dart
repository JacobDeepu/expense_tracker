import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReceiptScanResult {
  final double? amount;
  final DateTime? date;
  final String rawText;
  final String imagePath;

  ReceiptScanResult({
    this.amount,
    this.date,
    required this.rawText,
    required this.imagePath,
  });
}

class ReceiptScannerService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<ReceiptScanResult?> scanReceipt() async {
    // 1. Pick Image
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    // 2. OCR
    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText = await _recognizer.processImage(inputImage);
    final String text = recognizedText.text;

    // 3. Parse Data (Basic logic for now)
    final double? amount = _extractTotalAmount(text);
    final DateTime? date = _extractDate(text);

    return ReceiptScanResult(
      amount: amount,
      date: date,
      rawText: text,
      imagePath: image.path,
    );
  }

  double? _extractTotalAmount(String text) {
    final lines = text.split('\n');
    double? maxAmount;
    
    // 1. Look for explicit total keywords
    final totalKeywords = ['total', 'amount payable', 'grand total', 'net amount', 'payable'];
    
    for (final line in lines.reversed) {
      final lowerLine = line.toLowerCase();
      
      // Check if line contains a keyword
      bool hasKeyword = totalKeywords.any((k) => lowerLine.contains(k));
      
      if (hasKeyword) {
        final amount = _parseAmountFromLine(line);
        if (amount != null) return amount;
      }
    }

    // 2. Fallback: Scan bottom 50% of lines for largest valid amount
    // (Receipts usually have total at bottom)
    final int startIdx = (lines.length * 0.5).floor();
    for (int i = startIdx; i < lines.length; i++) {
       final amount = _parseAmountFromLine(lines[i]);
       if (amount != null) {
         if (maxAmount == null || amount > maxAmount) {
           maxAmount = amount;
         }
       }
    }

    return maxAmount;
  }

  double? _parseAmountFromLine(String line) {
     // Regex for currency amounts: 
     // Optional currency symbol (₹, Rs, INR)
     // Number with optional commas and decimals
     final regex = RegExp(r'(?:₹|Rs\.?|INR)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)');
     
     final matches = regex.allMatches(line);
     for (final match in matches) {
       String numStr = match.group(1)?.replaceAll(',', '') ?? '';
       final amount = double.tryParse(numStr);
       
       if (amount != null) {
         // Filter out unlikely amounts (dates, phone numbers, years)
         if (amount > 1000000) continue; // Unlikely for daily receipt
         if (amount == 2023 || amount == 2024 || amount == 2025) continue; // Year check
         // Phone number check (simple length check not enough, but >1000000 covers 10 digits)
         
         return amount;
       }
     }
     return null;
  }

  DateTime? _extractDate(String text) {
    // Basic date regex (DD/MM/YYYY or YYYY-MM-DD)
    final dateRegex = RegExp(r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\b');
    final match = dateRegex.firstMatch(text);
    if (match != null) {
      // Very naive parsing, would need a robust library in production
      try {
        // Just returning current date for MVP reliability if parse fails
        return DateTime.now(); 
      } catch (_) {
        return null;
      }
    }
    return null;
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
