/// Model representing a Quotation entity.
///
/// Designed to be self-contained, serializable (JSON/Map), and easily
/// portable to any database or backend service (SQLite, Firebase, REST APIs).
class Quotation {
  /// Unique identifier (e.g., 'QT-1001')
  final String id;

  /// Name of the client or company
  String clientName;

  /// Total estimated amount in quotation
  double amount;

  /// Timestamp of creation
  DateTime createdAt;

  Quotation({
    required this.id,
    required this.clientName,
    required this.amount,
    required this.createdAt,
  });

  /// Create an updated copy with modified fields
  Quotation copyWith({
    String? id,
    String? clientName,
    double? amount,
    DateTime? createdAt,
  }) {
    return Quotation(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serialize to Map (for JSON, SQLite, or NoSQL databases)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Deserialize from Map
  factory Quotation.fromMap(Map<String, dynamic> map) {
    return Quotation(
      id: map['id'] as String,
      clientName: map['clientName'] as String,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
