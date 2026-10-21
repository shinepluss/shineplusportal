/// Master Data Staff / User Model (StaffUserModel)
class UserModel {
  final String id;
  final String employeeId; // e.g. EMP-104
  final String fullName; // Full Name (required)
  final String role; // Designation / Job Role (e.g. Manager Sales, Site Supervisor, Field Technician)
  final String phone; // Phone number
  final String status; // Active, On Leave, Inactive

  UserModel({
    required this.id,
    required this.employeeId,
    required this.fullName,
    required this.role,
    this.phone = '',
    this.status = 'Active',
  });

  /// Alias for role matching designation
  String get designation => role;

  UserModel copyWith({
    String? id,
    String? employeeId,
    String? fullName,
    String? role,
    String? phone,
    String? status,
  }) {
    return UserModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'full_name': fullName,
      'role': role,
      'designation': role,
      'phone': phone,
      'status': status,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return UserModel(
      id: docId ?? (map['id'] as String? ?? ''),
      employeeId: (map['employee_id'] ?? map['staff_id'] ?? '') as String,
      fullName: (map['full_name'] ?? map['name'] ?? '') as String,
      role: (map['role'] ?? map['designation'] ?? 'Field Technician') as String,
      phone: (map['phone'] ?? '') as String,
      status: (map['status'] ?? 'Active') as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Type alias for enterprise naming consistency
typedef StaffUserModel = UserModel;
