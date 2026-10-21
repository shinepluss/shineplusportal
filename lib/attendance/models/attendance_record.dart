import 'dart:typed_data';

/// Verification status for attendance and shifts
enum ShiftStatus {
  active,
  completed,
  overtime,
  limitExceeded,
}

/// Standalone Attendance & Shift Verification record model.
///
/// Encapsulates:
/// - Front Camera Verification Selfie
/// - Back Camera Work Site/Environment Snapshot
/// - GPS Coordinates & Reverse-Geocoded Address
/// - Exact Clock-In and Clock-Out Timestamps
/// - Live Duration & Shift Target Calculations (8h standard / 10h max limit)
class AttendanceRecord {
  final String id;
  final String employeeName;
  final String employeeId;
  final DateTime clockInTime;
  DateTime? clockOutTime;

  /// File path or asset URI of the employee verification selfie
  final String? frontSelfiePath;

  /// File path or asset URI of the work environment / site snapshot
  final String? backSitePhotoPath;

  /// Optional in-memory image bytes (useful for instant previews or mock data)
  final Uint8List? frontSelfieBytes;
  final Uint8List? backSitePhotoBytes;

  /// GPS Coordinates
  final double latitude;
  final double longitude;

  /// Human-readable address (e.g. "Gulberg III, Lahore, Punjab")
  final String address;

  /// Whether the verification used mock fallbacks (e.g. emulator without camera)
  final bool isMock;

  /// Optional shift remarks or site notes
  final String? notes;

  AttendanceRecord({
    required this.id,
    required this.employeeName,
    required this.employeeId,
    required this.clockInTime,
    this.clockOutTime,
    this.frontSelfiePath,
    this.backSitePhotoPath,
    this.frontSelfieBytes,
    this.backSitePhotoBytes,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.isMock = false,
    this.notes,
  });

  /// Whether this shift is currently active (clocked in and not yet clocked out)
  bool get isActive => clockOutTime == null;

  /// Total duration of the shift (elapsed time if active, or total completed duration)
  Duration get duration {
    final end = clockOutTime ?? DateTime.now();
    return end.difference(clockInTime);
  }

  /// Shift progress relative to standard 8-hour target (0.0 to 1.0)
  double get progressTo8Hours {
    const targetSeconds = 8 * 3600;
    final elapsedSeconds = duration.inSeconds;
    return (elapsedSeconds / targetSeconds).clamp(0.0, 1.0);
  }

  /// Shift progress relative to maximum 10-hour threshold (0.0 to 1.0)
  double get progressTo10Hours {
    const maxSeconds = 10 * 3600;
    final elapsedSeconds = duration.inSeconds;
    return (elapsedSeconds / maxSeconds).clamp(0.0, 1.0);
  }

  /// Whether the shift has surpassed the 8-hour target
  bool get isOvertime => duration.inMinutes >= 8 * 60;

  /// Whether the shift has reached or exceeded the 10-hour maximum threshold
  bool get isLimitExceeded => duration.inMinutes >= 10 * 60;

  /// Current shift status
  ShiftStatus get status {
    if (!isActive) return ShiftStatus.completed;
    if (isLimitExceeded) return ShiftStatus.limitExceeded;
    if (isOvertime) return ShiftStatus.overtime;
    return ShiftStatus.active;
  }

  /// Formatted elapsed duration string: HH:MM:SS
  String get formattedDuration {
    final d = duration;
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  AttendanceRecord copyWith({
    String? id,
    String? employeeName,
    String? employeeId,
    DateTime? clockInTime,
    DateTime? clockOutTime,
    String? frontSelfiePath,
    String? backSitePhotoPath,
    Uint8List? frontSelfieBytes,
    Uint8List? backSitePhotoBytes,
    double? latitude,
    double? longitude,
    String? address,
    bool? isMock,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeName: employeeName ?? this.employeeName,
      employeeId: employeeId ?? this.employeeId,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      frontSelfiePath: frontSelfiePath ?? this.frontSelfiePath,
      backSitePhotoPath: backSitePhotoPath ?? this.backSitePhotoPath,
      frontSelfieBytes: frontSelfieBytes ?? this.frontSelfieBytes,
      backSitePhotoBytes: backSitePhotoBytes ?? this.backSitePhotoBytes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      isMock: isMock ?? this.isMock,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_name': employeeName,
      'employee_id': employeeId,
      'clock_in_time': clockInTime.toIso8601String(),
      'clock_out_time': clockOutTime?.toIso8601String(),
      'front_selfie_path': frontSelfiePath,
      'back_site_photo_path': backSitePhotoPath,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'is_mock': isMock,
      'notes': notes,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as String? ?? 'ATT-${DateTime.now().millisecondsSinceEpoch}',
      employeeName: map['employee_name'] as String? ?? 'Amir Nawaz',
      employeeId: map['employee_id'] as String? ?? 'SP-101',
      clockInTime: DateTime.parse(map['clock_in_time'] as String),
      clockOutTime: map['clock_out_time'] != null
          ? DateTime.parse(map['clock_out_time'] as String)
          : null,
      frontSelfiePath: map['front_selfie_path'] as String?,
      backSitePhotoPath: map['back_site_photo_path'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 31.5204,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 74.3587,
      address: map['address'] as String? ?? 'Gulberg III, Lahore, Punjab',
      isMock: map['is_mock'] as bool? ?? false,
      notes: map['notes'] as String?,
    );
  }
}

