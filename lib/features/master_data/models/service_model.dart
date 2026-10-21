/// Master Data Service & Pricing Catalog Model
class ServiceModel {
  final String id;
  final String title;
  final String defaultUnit;
  final double standardCompanyRate;
  final String description; // Description / Scope of Work

  ServiceModel({
    required this.id,
    required this.title,
    required this.defaultUnit,
    required this.standardCompanyRate,
    this.description = '',
  });

  ServiceModel copyWith({
    String? id,
    String? title,
    String? defaultUnit,
    double? standardCompanyRate,
    String? description,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      title: title ?? this.title,
      defaultUnit: defaultUnit ?? this.defaultUnit,
      standardCompanyRate: standardCompanyRate ?? this.standardCompanyRate,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'default_unit': defaultUnit,
      'standard_company_rate': standardCompanyRate,
      'description': description,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rateRaw = map['standard_company_rate'] ?? map['standard_rate'] ?? 0;
    final rate = rateRaw is num ? rateRaw.toDouble() : (double.tryParse(rateRaw.toString()) ?? 0.0);

    return ServiceModel(
      id: docId ?? (map['id'] as String? ?? ''),
      title: (map['title'] ?? '') as String,
      defaultUnit: (map['default_unit'] ?? map['unit'] ?? 'Sq. Ft.') as String,
      standardCompanyRate: rate,
      description: (map['description'] ?? '') as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
