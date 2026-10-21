/// Supported dynamic field types for custom schemas
enum CustomFieldType {
  text,
  number,
  date,
  status;

  String get label {
    switch (this) {
      case CustomFieldType.text:
        return 'Text / String';
      case CustomFieldType.number:
        return 'Number / Decimal';
      case CustomFieldType.date:
        return 'Date';
      case CustomFieldType.status:
        return 'Status / Dropdown';
    }
  }

  static CustomFieldType fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'number':
      case 'numeric':
      case 'decimal':
        return CustomFieldType.number;
      case 'date':
      case 'datetime':
        return CustomFieldType.date;
      case 'status':
      case 'dropdown':
      case 'select':
        return CustomFieldType.status;
      case 'text':
      default:
        return CustomFieldType.text;
    }
  }
}

/// Defines a single field/column within a dynamic custom list
class CustomFieldDefinition {
  final String name; // Machine key in record map (e.g., asset_tag)
  final String label; // UI display label (e.g., Asset Tag)
  final CustomFieldType type;
  final List<String> options; // For dropdown / status types
  final bool isRequired;

  CustomFieldDefinition({
    required this.name,
    required this.label,
    required this.type,
    this.options = const [],
    this.isRequired = false,
  });

  CustomFieldDefinition copyWith({
    String? name,
    String? label,
    CustomFieldType? type,
    List<String>? options,
    bool? isRequired,
  }) {
    return CustomFieldDefinition(
      name: name ?? this.name,
      label: label ?? this.label,
      type: type ?? this.type,
      options: options ?? List.from(this.options),
      isRequired: isRequired ?? this.isRequired,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'label': label,
      'type': type.name,
      'options': options,
      'is_required': isRequired,
    };
  }

  factory CustomFieldDefinition.fromMap(Map<String, dynamic> map) {
    return CustomFieldDefinition(
      name: (map['name'] ?? '') as String,
      label: (map['label'] ?? map['name'] ?? '') as String,
      type: CustomFieldType.fromString((map['type'] ?? 'text') as String),
      options: (map['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isRequired: (map['is_required'] ?? false) as bool,
    );
  }
}

/// Dynamic schema definition stored in `/custom_lists_meta/{listName}`
class CustomListSchema {
  final String id;
  final String listName; // e.g. company_assets
  final String displayName; // e.g. Company Assets
  final String description;
  final String iconName; // e.g. inventory_2, construction, devices
  final List<CustomFieldDefinition> fields;
  final DateTime createdAt;

  CustomListSchema({
    required this.id,
    required this.listName,
    required this.displayName,
    required this.description,
    this.iconName = 'inventory_2',
    required this.fields,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  CustomListSchema copyWith({
    String? id,
    String? listName,
    String? displayName,
    String? description,
    String? iconName,
    List<CustomFieldDefinition>? fields,
    DateTime? createdAt,
  }) {
    return CustomListSchema(
      id: id ?? this.id,
      listName: listName ?? this.listName,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      fields: fields ?? List.from(this.fields),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'list_name': listName,
      'display_name': displayName,
      'description': description,
      'icon_name': iconName,
      'fields': fields.map((f) => f.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CustomListSchema.fromMap(Map<String, dynamic> map, [String? docId]) {
    final fieldsRaw = (map['fields'] as List<dynamic>?) ?? [];
    return CustomListSchema(
      id: docId ?? (map['id'] as String? ?? ''),
      listName: (map['list_name'] ?? map['name'] ?? '') as String,
      displayName: (map['display_name'] ?? map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      iconName: (map['icon_name'] ?? 'inventory_2') as String,
      fields: fieldsRaw.map((f) => CustomFieldDefinition.fromMap(f as Map<String, dynamic>)).toList(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

