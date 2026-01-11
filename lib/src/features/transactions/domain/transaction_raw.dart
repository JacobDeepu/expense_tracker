class TransactionRaw {
  final String packageName;
  final String title;
  final String body;
  final DateTime timestamp;

  TransactionRaw({
    required this.packageName,
    required this.title,
    required this.body,
    required this.timestamp,
  });

  factory TransactionRaw.fromMap(Map<dynamic, dynamic> map) {
    return TransactionRaw(
      packageName: map['package'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['text'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  String toString() => 'TransactionRaw(package: $packageName, title: $title, body: $body)';
}
