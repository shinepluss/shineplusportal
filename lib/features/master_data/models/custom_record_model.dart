/// Represents a dynamic row / record inside `/custom_lists_data_{listName}/{recordId}`
class CustomRecord {
  final String id;
  final String listName;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomRecord({
    required this.id,
    required this.listName,
    required this.data,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  CustomRecord copyWith({
    String? id,
    String? listName,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomRecord(
      id: id ?? this.id,
      listName: listName ?? this.listName,
      data: data ?? Map<String, dynamic>.from(this.data),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'list_name': listName,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CustomRecord.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rawData = map['data'] is Map<String, dynamic>
        ? map['data'] as Map<String, dynamic>
        : Map<String, dynamic>.from(map)
          ..remove('id')
          ..remove('created_at')
          ..remove('updated_at');

    return CustomRecord(
      id: docId ?? (map['id'] as String? ?? ''),
      listName: (map['list_name'] ?? '') as String,
      data: rawData,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

