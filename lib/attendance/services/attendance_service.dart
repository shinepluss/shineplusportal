import 'package:flutter/material.dart';
import '../../features/attendance/services/firestore_attendance_service.dart';
import '../models/attendance_record.dart';
import 'camera_service.dart';
import 'location_service.dart';

/// Centralized state manager for Attendance, Active Shifts, and Verification Logs.
///
/// Features:
/// - Active Shift tracking
/// - Past shift history logs
/// - Real-time state broadcasting via [ChangeNotifier]
/// - Pre-populated sample completed shifts for instant preview
class AttendanceService extends ChangeNotifier {
  /// Singleton instance
  static final AttendanceService instance = AttendanceService._internal();

  AttendanceService._internal() {
    _initSampleData();
  }

  AttendanceRecord? _activeShift;
  final List<AttendanceRecord> _pastShifts = [];

  /// Current active shift (null if user is clocked out)
  AttendanceRecord? get activeShift => _activeShift;

  /// Whether the employee is currently clocked in
  bool get isClockedIn => _activeShift != null;

  /// Unmodifiable list of historical shifts (newest first)
  List<AttendanceRecord> get pastShifts => List.unmodifiable(_pastShifts);

  /// Clock in with captured front selfie, back site photo, and GPS location
  AttendanceRecord clockIn({
    required String employeeName,
    required String employeeId,
    required CameraCaptureResult frontCapture,
    required CameraCaptureResult backCapture,
    required LocationResult location,
    DateTime? customStartTime,
  }) {
    final now = customStartTime ?? DateTime.now();
    final id = 'ATT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    final record = AttendanceRecord(
      id: id,
      employeeName: employeeName,
      employeeId: employeeId,
      clockInTime: now,
      frontSelfiePath: frontCapture.path,
      backSitePhotoPath: backCapture.path,
      frontSelfieBytes: frontCapture.bytes,
      backSitePhotoBytes: backCapture.bytes,
      latitude: location.latitude,
      longitude: location.longitude,
      address: location.address,
      isMock: frontCapture.isMock || backCapture.isMock || location.isMock,
    );

    _activeShift = record;
    notifyListeners();
    FirestoreAttendanceService.instance.saveAttendanceRecord(record);
    return record;
  }

  /// Clock out and end the current shift
  AttendanceRecord? clockOut({String? notes}) {
    if (_activeShift == null) return null;

    final completed = _activeShift!.copyWith(
      clockOutTime: DateTime.now(),
      notes: notes,
    );

    _pastShifts.insert(0, completed);
    _activeShift = null;
    notifyListeners();
    FirestoreAttendanceService.instance.saveAttendanceRecord(completed);
    return completed;
  }

  /// Sets a simulated active shift for testing (e.g. 7 hours in, or 8.5 hours in for overtime testing)
  void setSimulatedActiveShift(Duration elapsed) {
    final clockIn = DateTime.now().subtract(elapsed);
    _activeShift = AttendanceRecord(
      id: 'ATT-ACTIVE-SIM',
      employeeName: 'Amir Nawaz',
      employeeId: 'SP-101',
      clockInTime: clockIn,
      latitude: 31.5204,
      longitude: 74.3587,
      address: 'Circle Club Commercial Site, Faisalabad',
      isMock: true,
    );
    notifyListeners();
  }

  /// Trigger a notifyListeners tick (useful for periodic timer updates)
  void tick() {
    if (_activeShift != null) {
      notifyListeners();
    }
  }

  /// Reset all state to defaults
  void reset() {
    _activeShift = null;
    _pastShifts.clear();
    _initSampleData();
    notifyListeners();
  }

  void _initSampleData() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayClockIn = DateTime(yesterday.year, yesterday.month, yesterday.day, 9, 0);
    final yesterdayClockOut = yesterdayClockIn.add(const Duration(hours: 8, minutes: 15));

    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    final twoDaysAgoClockIn = DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day, 8, 45);
    final twoDaysAgoClockOut = twoDaysAgoClockIn.add(const Duration(hours: 7, minutes: 50));

    _pastShifts.addAll([
      AttendanceRecord(
        id: 'ATT-20260929-01',
        employeeName: 'Amir Nawaz',
        employeeId: 'SP-101',
        clockInTime: yesterdayClockIn,
        clockOutTime: yesterdayClockOut,
        latitude: 31.4187,
        longitude: 73.0791,
        address: 'Circle Club Facility, Faisalabad, Punjab',
        isMock: true,
        notes: 'Marble polishing & washroom restoration shift completed.',
      ),
      AttendanceRecord(
        id: 'ATT-20260928-01',
        employeeName: 'Amir Nawaz',
        employeeId: 'SP-101',
        clockInTime: twoDaysAgoClockIn,
        clockOutTime: twoDaysAgoClockOut,
        latitude: 31.5204,
        longitude: 74.3587,
        address: 'Pearl Continental Hotel, Mall Road, Lahore',
        isMock: true,
        notes: 'Lobby diamond crystallization shift.',
      ),
    ]);
  }
}

