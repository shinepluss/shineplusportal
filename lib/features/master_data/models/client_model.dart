/// Master Data Client Model
class ClientModel {
  final String id;
  final String contactName; // Client Name / Focal Person (required)
  final String organization; // Organization / Company (e.g. Circle Club)
  final String designation; // Designation (e.g. Managing Director)
  final String city; // City (Lahore, Islamabad, Faisalabad, etc.)
  final String phone; // Phone / WhatsApp number
  final String email; // Email address (optional)
  final String address; // Address / Location notes (multi-line)

  ClientModel({
    required this.id,
    required this.contactName,
    required this.organization,
    required this.designation,
    required this.city,
    required this.phone,
    this.email = '',
    this.address = '',
  });

  ClientModel copyWith({
    String? id,
    String? contactName,
    String? organization,
    String? designation,
    String? city,
    String? phone,
    String? email,
    String? address,
  }) {
    return ClientModel(
      id: id ?? this.id,
      contactName: contactName ?? this.contactName,
      organization: organization ?? this.organization,
      designation: designation ?? this.designation,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contact_name': contactName,
      'organization': organization,
      'designation': designation,
      'city': city,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ClientModel(
      id: docId ?? (map['id'] as String? ?? ''),
      contactName: (map['contact_name'] ?? map['name'] ?? '') as String,
      organization: (map['organization'] ?? '') as String,
      designation: (map['designation'] ?? '') as String,
      city: (map['city'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      address: (map['address'] ?? '') as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
