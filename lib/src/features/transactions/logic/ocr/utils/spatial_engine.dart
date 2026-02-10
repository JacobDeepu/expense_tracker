import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/ocr_models.dart';

class SpatialEngine {
  /// Group lines by their vertical position (Y-coordinate)
  List<SpatialLine> groupLinesByVerticalPosition(
    RecognizedText recognizedText,
  ) {
    final List<SpatialLine> lines = [];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final top = line.boundingBox.top;
        final bottom = line.boundingBox.bottom;
        final mid = (top + bottom) / 2;

        bool found = false;
        for (final sl in lines) {
          // If vertical overlap is significant, they belong to the same spatial line
          if (mid >= sl.top && mid <= sl.bottom) {
            sl.addElement(
              line.text,
              line.boundingBox.left.toDouble(),
              line.boundingBox.right.toDouble(),
            );
            // Expand vertical bounds if needed
            if (top < sl.top) sl.top = top.toDouble();
            if (bottom > sl.bottom) sl.bottom = bottom.toDouble();

            found = true;
            break;
          }
        }

        if (!found) {
          final newItem = SpatialLine(
            top: top.toDouble(),
            bottom: bottom.toDouble(),
            text: line.text,
            left: line.boundingBox.left.toDouble(),
            right: line.boundingBox.right.toDouble(),
          );
          newItem.addElement(
            line.text,
            line.boundingBox.left.toDouble(),
            line.boundingBox.right.toDouble(),
          );
          lines.add(newItem);
        }
      }
    }

    lines.sort((a, b) => a.top.compareTo(b.top));
    return lines;
  }

  /// Detect columns based on headers
  /// Returns a map of column types to column definitions
  Map<String, ReceiptColumn> detectColumns(List<SpatialLine> lines) {
    final Map<String, ReceiptColumn> columns = {};

    // Prioritize specific headers over generic ones
    final headerCategories = {
      'amount': [
        'amount',
        'total',
        'net amount',
        'payable',
        'value',
        'extension',
      ],
      'unit_price': ['rate', 'price', 'mrp', 'unit', 'sp', 'unit price'],
      'item': ['item', 'description', 'particulars', 'desc', 'product', 'name'],
      'qty': ['qty', 'quantity', 'count', 'nos', 'unit'],
      'discount': ['disc', 'discount', 'less'],
    };

    // Only look in top 40% of lines for headers
    final limit = (lines.length * 0.4).floor();
    for (int i = 0; i < lines.length && i < limit; i++) {
      final line = lines[i];

      // Check for headers in this line
      // We look at individual text elements to get better column bounds
      for (final element in line.elements) {
        final text = element.text.toLowerCase();

        for (final category in headerCategories.keys) {
          for (final keyword in headerCategories[category]!) {
            if (text == keyword || text.contains(keyword)) {
              // Heuristic: If we already found an 'amount' column, and this is another one,
              // we prefer the one further to the right as the "Total Amount" column usually
              if (category == 'amount' && columns.containsKey('amount')) {
                if (element.left > columns['amount']!.left) {
                  columns[category] = ReceiptColumn(
                    name: category,
                    left: element.left,
                    right: element.right,
                  );
                }
              } else {
                columns[category] = ReceiptColumn(
                  name: category,
                  left: element.left,
                  right: element.right,
                );
              }
            }
          }
        }
      }
    }

    // Post-processing: If we found 'unit_price' but not 'amount', and 'unit_price' is clearly
    // to the left of some other number column, we might want to search harder.
    // But typically if we find 'amount', we use it.
    // If we only find 'unit_price' (like Rate), we might accidentally use it as amount.
    // Ideally we want the 'amount' key to represent the LINE TOTAL.

    // If we have both 'unit_price' and 'amount', we are good.
    // If we have 'unit_price' and NO 'amount', valid line items might just imply amount is the last number.

    return columns;
  }

  String? getTextInColumn(SpatialLine line, ReceiptColumn col) {
    // Return text elements that fall largely within the column bounds
    final inColElements = line.elements.where((e) {
      final eMid = (e.left + e.right) / 2;
      // Allow some slack (e.g. 15% of column width)
      final margin = (col.right - col.left) * 0.15;
      return eMid >= (col.left - margin) && eMid <= (col.right + margin);
    }).toList();

    if (inColElements.isEmpty) return null;

    return inColElements.map((e) => e.text).join(' ');
  }

  String getTextToLeftOfColumn(SpatialLine line, ReceiptColumn col) {
    // Return text elements that are strictly to the left of the column
    final leftElements = line.elements.where((e) {
      return e.right <= col.left + 20; // 20px buffer
    }).toList();

    return leftElements.map((e) => e.text).join(' ');
  }
}
