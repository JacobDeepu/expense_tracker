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
    // Look for lines containing "Total" and a number
    final lines = text.split('\n');
    for (final line in lines.reversed) { // Totals are usually at the bottom
      if (line.toLowerCase().contains('total')) {
        // Regex to find number
        final match = RegExp(r'(?:[\d,]+\.\d{2})').firstMatch(line);
        if (match != null) {
           String numStr = match.group(0)!.replaceAll(',', '');
           return double.tryParse(numStr);
        }
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
