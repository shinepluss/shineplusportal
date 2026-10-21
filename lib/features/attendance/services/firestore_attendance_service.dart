import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/firebase/firebase_service.dart';
import '../../../attendance/models/attendance_record.dart';

/// Cloud Firestore & Storage Service for Attendance and Shift Verification.
///
/// Implements root `attendance/` collection:
/// Fields: `employee_id`, `employee_name`, `clock_in_time`, `clock_out_time`,
///         `shift_duration_minutes`, `latitude`, `longitude`, `address`,
///         `front_photo_url`, `back_photo_url`, `status`.
class FirestoreAttendanceService {
  static final FirestoreAttendanceService instance = FirestoreAttendanceService._internal();
  FirestoreAttendanceService._internal();

  final FirebaseService _firebaseService = FirebaseService.instance;

  /// Uploads verification photos (if bytes are available) and saves/updates attendance record
  Future<bool> saveAttendanceRecord(AttendanceRecord record) async {
    final firestore = _firebaseService.firestore;
    final docId = record.id;

    String frontPhotoUrl = record.frontSelfiePath ?? '';
    String backPhotoUrl = record.backSitePhotoPath ?? '';

    // Upload front photo to Firebase Storage if bytes are present
    if (record.frontSelfieBytes != null) {
      final uploadedUrl = await _firebaseService.uploadStorageFile(
        path: 'attendance/$docId/front_selfie.jpg',
        bytes: record.frontSelfieBytes!,
      );
      if (uploadedUrl != null) {
        frontPhotoUrl = uploadedUrl;
      }
    }

    // Upload back site photo to Firebase Storage if bytes are present
    if (record.backSitePhotoBytes != null) {
      final uploadedUrl = await _firebaseService.uploadStorageFile(
        path: 'attendance/$docId/back_site.jpg',
        bytes: record.backSitePhotoBytes!,
      );
      if (uploadedUrl != null) {
        backPhotoUrl = uploadedUrl;
      }
    }

    if (firestore == null) {
      debugPrint('[FirestoreAttendanceService] Cloud Firestore offline, stored locally.');
      return false;
    }

    try {
      final data = {
        'employee_id': record.employeeId,
        'employee_name': record.employeeName,
        'clock_in_time': record.clockInTime.toIso8601String(),
        'clock_out_time': record.clockOutTime?.toIso8601String(),
        'shift_duration_minutes': record.duration.inMinutes,
        'latitude': record.latitude,
        'longitude': record.longitude,
        'address': record.address,
        'front_photo_url': frontPhotoUrl,
        'back_photo_url': backPhotoUrl,
        'status': record.status.name,
        'notes': record.notes,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await firestore.collection('attendance').doc(docId).set(
            {
              ...data,
              'created_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

      debugPrint('[FirestoreAttendanceService] Attendance record $docId synced with Cloud Firestore.');
      return true;
    } catch (e) {
      debugPrint('[FirestoreAttendanceService] Failed to sync attendance to Firestore: $e');
      return false;
    }
  }

  /// Real-time stream of all attendance logs
  Stream<QuerySnapshot<Map<String, dynamic>>>? streamAttendanceRecords() {
    return _firebaseService.attendanceCollection
        ?.orderBy('clock_in_time', descending: true)
        .snapshots();
  }

  /// Delete attendance record
  Future<bool> deleteAttendanceRecord(String id) async {
    final firestore = _firebaseService.firestore;
    if (firestore == null) return false;

    try {
      await firestore.collection('attendance').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('[FirestoreAttendanceService] Error deleting record: $e');
      return false;
    }
  }
}
