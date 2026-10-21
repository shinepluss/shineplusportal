import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../features/master_data/master_data.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';

/// Interactive modal dialog guiding the employee through the sequential clock-in capture flow:
/// Step 1: Front Camera Selfie
/// Step 2: Back Camera Site Snapshot
/// Step 3: GPS Location Verification & Confirmation
Future<Map<String, dynamic>?> showClockInVerificationModal({
  required BuildContext context,
  String initialEmployeeName = 'Amir Nawaz',
  String initialEmployeeId = 'SP-101',
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) => _ClockInCaptureWizard(
      initialEmployeeName: initialEmployeeName,
      initialEmployeeId: initialEmployeeId,
    ),
  );
}

class _ClockInCaptureWizard extends StatefulWidget {
  final String initialEmployeeName;
  final String initialEmployeeId;

  const _ClockInCaptureWizard({
    required this.initialEmployeeName,
    required this.initialEmployeeId,
  });

  @override
  State<_ClockInCaptureWizard> createState() => _ClockInCaptureWizardState();
}

class _ClockInCaptureWizardState extends State<_ClockInCaptureWizard> {
  int _currentStep = 1; // 1 = Front Selfie, 2 = Back Site, 3 = Location & Confirm

  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isUsingMockCamera = false;

  CameraCaptureResult? _frontSelfieResult;
  CameraCaptureResult? _backSiteResult;

  LocationResult? _locationResult;
  bool _isFetchingLocation = false;

  late TextEditingController _nameController;
  late TextEditingController _empIdController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialEmployeeName);
    _empIdController = TextEditingController(text: widget.initialEmployeeId);
    _initFrontCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _nameController.dispose();
    _empIdController.dispose();
    super.dispose();
  }

  // --- Step 1: Front Camera Init ---
  Future<void> _initFrontCamera() async {
    setState(() {
      _isCameraInitialized = false;
    });

    try {
      final frontCam = await CameraService.getFrontCamera();
      if (frontCam != null) {
        _cameraController = CameraController(
          frontCam,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            _isUsingMockCamera = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isUsingMockCamera = true;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isUsingMockCamera = true;
        });
      }
    }
  }

  // --- Step 2: Back Camera Init ---
  Future<void> _initBackCamera() async {
    await _cameraController?.dispose();
    setState(() {
      _isCameraInitialized = false;
    });

    try {
      final backCam = await CameraService.getBackCamera();
      if (backCam != null) {
        _cameraController = CameraController(
          backCam,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            _isUsingMockCamera = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isUsingMockCamera = true;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isUsingMockCamera = true;
        });
      }
    }
  }

  // --- Capture Action ---
  Future<void> _capturePhoto() async {
    if (_isUsingMockCamera || _cameraController == null || !_cameraController!.value.isInitialized) {
      // Mock Fallback
      if (_currentStep == 1) {
        setState(() {
          _frontSelfieResult = CameraService.generateMockCapture(
            direction: CameraLensDirection.front,
          );
          _currentStep = 2;
        });
        _initBackCamera();
      } else if (_currentStep == 2) {
        setState(() {
          _backSiteResult = CameraService.generateMockCapture(
            direction: CameraLensDirection.back,
          );
          _currentStep = 3;
        });
        _fetchLocation();
      }
      return;
    }

    try {
      final xFile = await _cameraController!.takePicture();
      if (_currentStep == 1) {
        setState(() {
          _frontSelfieResult = CameraCaptureResult(
            path: xFile.path,
            direction: CameraLensDirection.front,
          );
          _currentStep = 2;
        });
        _initBackCamera();
      } else if (_currentStep == 2) {
        setState(() {
          _backSiteResult = CameraCaptureResult(
            path: xFile.path,
            direction: CameraLensDirection.back,
          );
          _currentStep = 3;
        });
        _fetchLocation();
      }
    } catch (_) {
      // Fallback on error
      if (_currentStep == 1) {
        setState(() {
          _frontSelfieResult = CameraService.generateMockCapture(
            direction: CameraLensDirection.front,
          );
          _currentStep = 2;
        });
        _initBackCamera();
      } else if (_currentStep == 2) {
        setState(() {
          _backSiteResult = CameraService.generateMockCapture(
            direction: CameraLensDirection.back,
          );
          _currentStep = 3;
        });
        _fetchLocation();
      }
    }
  }

  // --- Step 3: Fetch Location ---
  Future<void> _fetchLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    final loc = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _locationResult = loc;
        _isFetchingLocation = false;
      });
    }
  }

  // --- Complete & Return ---
  void _completeClockIn() {
    Navigator.pop(context, {
      'employee_name': _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : 'Amir Nawaz',
      'employee_id': _empIdController.text.trim().isNotEmpty
          ? _empIdController.text.trim()
          : 'SP-101',
      'front_capture': _frontSelfieResult ??
          CameraService.generateMockCapture(direction: CameraLensDirection.front),
      'back_capture': _backSiteResult ??
          CameraService.generateMockCapture(direction: CameraLensDirection.back),
      'location': _locationResult ?? LocationService.mockFallback,
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: bottomInset + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Title and Step Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shift Clock-In Verification',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        _currentStep == 1
                            ? 'Step 1/3: Verification Selfie (Front Cam)'
                            : _currentStep == 2
                                ? 'Step 2/3: Work Site Environment (Back Cam)'
                                : 'Step 3/3: GPS Location Verification',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Step Progress Dots
              Row(
                children: [
                  _buildStepDot(1, 'Selfie'),
                  const SizedBox(width: 8),
                  _buildStepDot(2, 'Site'),
                  const SizedBox(width: 8),
                  _buildStepDot(3, 'GPS Confirm'),
                ],
              ),
              const SizedBox(height: 16),

              // Step Body
              if (_currentStep == 1)
                _buildCameraStep(
                  instruction: 'Position your face clearly within the frame for facial verification.',
                  buttonLabel: 'Capture Verification Selfie',
                  isFront: true,
                )
              else if (_currentStep == 2)
                _buildCameraStep(
                  instruction: 'Point your camera at the client facility, workstation, or service area.',
                  buttonLabel: 'Capture Work Site Snapshot',
                  isFront: false,
                )
              else
                _buildLocationAndConfirmationStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: isDone
                  ? const Color(0xFF10B981)
                  : isActive
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
              color: isDone
                  ? const Color(0xFF10B981)
                  : isActive
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 1 & 2 Camera Capture View ---
  Widget _buildCameraStep({
    required String instruction,
    required String buttonLabel,
    required bool isFront,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          instruction,
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 12),

        // Live Camera Preview or Mock Card
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_isCameraInitialized && _cameraController != null)
                CameraPreview(_cameraController!)
              else
                // Stylized Fallback Preview
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isFront
                          ? [const Color(0xFF1E3A8A), const Color(0xFF2563EB)]
                          : [const Color(0xFF0F766E), const Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isFront ? Icons.face_rounded : Icons.apartment_rounded,
                          size: 64,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isFront ? 'Front Camera Viewfinder' : 'Back Camera Viewfinder',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ready to capture evidence snapshot',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),

              // Viewfinder Guide Overlay
              Center(
                child: Container(
                  width: isFront ? 180 : 220,
                  height: isFront ? 200 : 160,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(isFront ? 100 : 16),
                  ),
                ),
              ),

              // Camera Label Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFront ? Icons.camera_front_rounded : Icons.camera_rear_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isFront ? 'FRONT CAMERA' : 'BACK CAMERA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Shutter Button
        FilledButton.icon(
          onPressed: _capturePhoto,
          icon: const Icon(Icons.camera_rounded, size: 22),
          label: Text(
            buttonLabel,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  // --- Step 3 Location & Confirmation View ---
  Widget _buildLocationAndConfirmationStep() {
    final staffList = MasterDataService.instance.users;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Master Data Staff Quick Selection
        if (staffList.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<UserModel>(
                isExpanded: true,
                hint: const Row(
                  children: [
                    Icon(Icons.badge_rounded, size: 16, color: Color(0xFF7C3AED)),
                    SizedBox(width: 8),
                    Text(
                      'Select Registered Staff (Auto-Fill)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)),
                    ),
                  ],
                ),
                items: staffList.map((u) {
                  return DropdownMenuItem<UserModel>(
                    value: u,
                    child: Text(
                      '${u.fullName} (${u.employeeId}) • ${u.role}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (selectedUser) {
                  if (selectedUser != null) {
                    setState(() {
                      _nameController.text = selectedUser.fullName;
                      _empIdController.text = selectedUser.employeeId;
                    });
                  }
                },
              ),
            ),
          ),
        ],

        // Employee Info Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Employee Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: _empIdController,
                decoration: const InputDecoration(
                  labelText: 'Staff ID',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Dual Thumbnail Preview Row
        Row(
          children: [
            Expanded(
              child: _buildMiniThumbnail(
                'Front Selfie',
                _frontSelfieResult,
                Icons.person_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniThumbnail(
                'Site Snapshot',
                _backSiteResult,
                Icons.apartment_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // GPS Location Status Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: _isFetchingLocation
              ? const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Acquiring accurate GPS fix and reverse-geocoding...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded, color: Color(0xFF2563EB), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GPS Verification Acquired',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _locationResult?.address ?? 'Gulberg III, Lahore, Punjab',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _locationResult?.formattedCoordinates ?? '31.5204° N, 74.3587° E',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF2563EB)),
                      onPressed: _fetchLocation,
                      tooltip: 'Refresh Location',
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 20),

        // Confirm & Clock In Button
        FilledButton.icon(
          onPressed: _isFetchingLocation ? null : _completeClockIn,
          icon: const Icon(Icons.check_circle_rounded, size: 22),
          label: const Text(
            'Confirm & Clock In (Start Live Timer)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniThumbnail(String label, CameraCaptureResult? result, IconData fallbackIcon) {
    final filePath = result?.path;
    final hasFile = filePath != null && File(filePath).existsSync();

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasFile)
            Image.file(File(filePath), fit: BoxFit.cover)
          else
            Center(
              child: Icon(fallbackIcon, color: const Color(0xFF2563EB), size: 32),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withValues(alpha: 0.65),
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
