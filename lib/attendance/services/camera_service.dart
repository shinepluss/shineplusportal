import 'dart:typed_data';
import 'package:camera/camera.dart';

/// Result of a camera snapshot capture
class CameraCaptureResult {
  final String? path;
  final Uint8List? bytes;
  final CameraLensDirection direction;
  final bool isMock;

  const CameraCaptureResult({
    this.path,
    this.bytes,
    required this.direction,
    this.isMock = false,
  });

  bool get hasImage => (path != null && path!.isNotEmpty) || (bytes != null && bytes!.isNotEmpty);
}

/// Service to manage front and back camera initialization and capture with mock fallbacks
class CameraService {
  static List<CameraDescription>? _availableCameras;

  /// Cache and retrieve list of available hardware cameras
  static Future<List<CameraDescription>> getCameras() async {
    if (_availableCameras != null) return _availableCameras!;
    try {
      _availableCameras = await availableCameras();
      return _availableCameras ?? [];
    } catch (_) {
      _availableCameras = [];
      return [];
    }
  }

  /// Get the front-facing camera for verification selfies
  static Future<CameraDescription?> getFrontCamera() async {
    final cameras = await getCameras();
    try {
      return cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
      );
    } catch (_) {
      return cameras.isNotEmpty ? cameras.first : null;
    }
  }

  /// Get the back-facing camera for work environment / site snapshots
  static Future<CameraDescription?> getBackCamera() async {
    final cameras = await getCameras();
    try {
      return cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
      );
    } catch (_) {
      return cameras.isNotEmpty ? cameras.last : null;
    }
  }

  /// Generates a mock capture result for testing in emulators or when permissions are missing
  static CameraCaptureResult generateMockCapture({
    required CameraLensDirection direction,
  }) {
    return CameraCaptureResult(
      direction: direction,
      isMock: true,
      path: null,
      bytes: null,
    );
  }
}
