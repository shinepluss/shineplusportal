import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shineplusinvoice/attendance/attendance.dart';

void main() {
  group('AttendanceRecord Model Tests', () {
    test('Calculates duration and progress accurately for normal shift (< 8h)', () {
      final now = DateTime.now();
      final record = AttendanceRecord(
        id: 'TEST-1',
        employeeName: 'Amir Nawaz',
        employeeId: 'SP-101',
        clockInTime: now.subtract(const Duration(hours: 4)),
        clockOutTime: now,
        latitude: 31.5204,
        longitude: 74.3587,
        address: 'Gulberg III, Lahore',
      );

      expect(record.duration.inHours, 4);
      expect(record.isOvertime, false);
      expect(record.isLimitExceeded, false);
      expect(record.progressTo8Hours, closeTo(0.5, 0.01));
      expect(record.formattedDuration, '04:00:00');
    });

    test('Identifies overtime state (8h - 10h)', () {
      final now = DateTime.now();
      final record = AttendanceRecord(
        id: 'TEST-2',
        employeeName: 'Amir Nawaz',
        employeeId: 'SP-101',
        clockInTime: now.subtract(const Duration(hours: 8, minutes: 45)),
        clockOutTime: now,
        latitude: 31.5204,
        longitude: 74.3587,
        address: 'Gulberg III, Lahore',
      );

      expect(record.isOvertime, true);
      expect(record.isLimitExceeded, false);
      expect(record.progressTo8Hours, 1.0);
      expect(record.formattedDuration, '08:45:00');
    });

    test('Identifies maximum limit exceeded state (> 10h)', () {
      final now = DateTime.now();
      final record = AttendanceRecord(
        id: 'TEST-3',
        employeeName: 'Amir Nawaz',
        employeeId: 'SP-101',
        clockInTime: now.subtract(const Duration(hours: 10, minutes: 30)),
        clockOutTime: now,
        latitude: 31.5204,
        longitude: 74.3587,
        address: 'Gulberg III, Lahore',
      );

      expect(record.isOvertime, true);
      expect(record.isLimitExceeded, true);
      expect(record.progressTo10Hours, 1.0);
      expect(record.formattedDuration, '10:30:00');
    });
  });

  group('AttendanceService Workflow Tests', () {
    test('Clock-in and clock-out transitions correctly', () {
      final service = AttendanceService.instance;

      final initialPastCount = service.pastShifts.length;

      // Clock In
      final frontCapture = CameraService.generateMockCapture(direction: CameraLensDirection.front);
      final backCapture = CameraService.generateMockCapture(direction: CameraLensDirection.back);
      final loc = LocationService.mockFallback;

      final clockInRecord = service.clockIn(
        employeeName: 'Amir Nawaz',
        employeeId: 'SP-101',
        frontCapture: frontCapture,
        backCapture: backCapture,
        location: loc,
      );

      expect(service.isClockedIn, true);
      expect(service.activeShift?.id, clockInRecord.id);

      // Clock Out
      final clockedOut = service.clockOut(notes: 'Completed day tasks successfully.');
      expect(service.isClockedIn, false);
      expect(service.activeShift, null);
      expect(clockedOut?.notes, 'Completed day tasks successfully.');
      expect(service.pastShifts.length, initialPastCount + 1);
    });
  });
}
