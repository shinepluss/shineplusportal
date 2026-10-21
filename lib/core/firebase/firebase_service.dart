import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Centralized Enterprise Firebase Service for Shine Plus Corporate Management
///
/// Handles graceful initialization, collection references, and failover
/// between Cloud Firestore, Firebase Storage, and offline caching.
class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  FirebaseService._internal();

  bool _initialized = false;
  String? _initError;

  bool get isInitialized => _initialized;
  String? get initializationError => _initError;

  FirebaseFirestore? get firestore {
    if (!_initialized) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseStorage? get storage {
    if (!_initialized) return null;
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  /// Initializes Firebase Core with safe fallback for environments without google-services.json
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // Check if already initialized
      if (Firebase.apps.isNotEmpty) {
        _initialized = true;
        _configureFirestoreSettings();
        return true;
      }

      // Initialize with default or platform options
      await Firebase.initializeApp();
      _initialized = true;
      _configureFirestoreSettings();
      debugPrint('[FirebaseService] Successfully connected to Firebase.');
      return true;
    } catch (e) {
      _initError = e.toString();
      debugPrint('[FirebaseService] Firebase initialization notice (Offline / Local Mode active): $e');
      _initialized = false;
      return false;
    }
  }

  void _configureFirestoreSettings() {
    try {
      final db = FirebaseFirestore.instance;
      db.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      debugPrint('[FirebaseService] Firestore settings notice: $e');
    }
  }

  // --- Collection Path Helpers ---

  /// Root quotations collection: `quotations`
  CollectionReference<Map<String, dynamic>>? get quotationsCollection =>
      firestore?.collection('quotations');

  /// Root attendance collection: `attendance`
  CollectionReference<Map<String, dynamic>>? get attendanceCollection =>
      firestore?.collection('attendance');

  /// Root master_data collection: `master_data`
  CollectionReference<Map<String, dynamic>>? get masterDataCollection =>
      firestore?.collection('master_data');

  /// Independent clients collection: `clients`
  CollectionReference<Map<String, dynamic>>? get clientsCollection =>
      firestore?.collection('clients');

  /// Independent services collection: `services`
  CollectionReference<Map<String, dynamic>>? get servicesCollection =>
      firestore?.collection('services');

  /// Independent users collection: `users`
  CollectionReference<Map<String, dynamic>>? get usersCollection =>
      firestore?.collection('users');

  /// Helper to generate document ID: `[location]_[month]_[invoice_num]`
  /// Example: LHR_SEP_354
  static String formatQuotationDocId({
    required String location,
    required String month,
    required int invoiceNum,
  }) {
    final loc = location.trim().toUpperCase();
    final mon = month.trim().toUpperCase();
    return '${loc}_${mon}_$invoiceNum';
  }

  /// Helper to generate revision document ID: `rev_1`, `rev_2`, etc.
  static String formatRevisionDocId(int revision) {
    return 'rev_$revision';
  }

  /// Uploads binary image/file bytes to Firebase Storage and returns download URL
  Future<String?> uploadStorageFile({
    required String path,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final st = storage;
    if (st == null) {
      debugPrint('[FirebaseService] Storage unavailable, using local byte reference.');
      return null;
    }

    try {
      final ref = st.ref().child(path);
      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('[FirebaseService] Storage upload failed: $e');
      return null;
    }
  }
}
