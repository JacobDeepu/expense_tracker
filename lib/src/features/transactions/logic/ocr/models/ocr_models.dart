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

class SpatialLine {
  double top;
  double bottom;
  String text; // Computed text
  final List<TextElement> elements = [];

  SpatialLine({
    required this.top,
    required this.bottom,
    required this.text,
    required double left, // kept for compatibility but computed from elements
    required double right,
  }) {
    // no-op, elements added via addElement
  }

  double get left => elements.isEmpty ? 0 : elements.first.left;
  double get right => elements.isEmpty ? 0 : elements.last.right;
  double get height => bottom - top;

  void addElement(String text, double left, double right) {
    elements.add(TextElement(text: text, left: left, right: right));
    elements.sort((a, b) => a.left.compareTo(b.left));
    this.text = elements.map((e) => e.text).join(' ');
  }
}

class TextElement {
  final String text;
  final double left;
  final double right;

  TextElement({required this.text, required this.left, required this.right});
}

class ReceiptColumn {
  final String name;
  final double left;
  final double right;

  ReceiptColumn({required this.name, required this.left, required this.right});
}

class ItemCandidate {
  final String name;
  final double amount;
  final double position; // Vertical position in image
  final double confidence;

  ItemCandidate({
    required this.name,
    required this.amount,
    required this.position,
    required this.confidence,
  });
}

class SpatialItemCandidate extends ItemCandidate {
  final double lineHeight;

  SpatialItemCandidate({
    required super.name,
    required super.amount,
    required super.position,
    required super.confidence,
    required this.lineHeight,
  });
}
