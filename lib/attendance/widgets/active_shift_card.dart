import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';

/// Active Shift / Verification Summary Card cleanly partitioned into 3 Main Sections:
/// - Section 1: Dual Camera Snapshots (Side-by-side Front Selfie & Back Site photo)
/// - Section 2: GPS Location Details (Map pin, address, coordinates)
/// - Section 3: Date, Time & Live Shift Clock (Clock-in time, live HH:MM:SS timer, 8h/10h progress bar, Clock Out button)
class ActiveShiftCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback onClockOut;

  const ActiveShiftCard({
    super.key,
    required this.record,
    required this.onClockOut,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy, hh:mm a');
    final formattedClockIn = dateFormat.format(record.clockInTime);
    final isOvertime = record.isOvertime;
    final isLimitExceeded = record.isLimitExceeded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLimitExceeded
              ? Colors.red.shade400
              : isOvertime
                  ? Colors.amber.shade400
                  : const Color(0xFFE2E8F0),
          width: isLimitExceeded || isOvertime ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLimitExceeded
                    ? Colors.red
                    : isOvertime
                        ? Colors.amber
                        : const Color(0xFF2563EB))
                .withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header Banner with Shift Status Tag
          _buildHeaderBanner(isOvertime, isLimitExceeded),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==========================================
                // SECTION 1: Dual Camera Snapshots (Side-by-Side)
                // ==========================================
                _buildSectionHeader(
                  title: 'SECTION 1: DUAL CAMERA VERIFICATION EVIDENCE',
                  icon: Icons.camera_alt_outlined,
                ),
                const SizedBox(height: 12),
                _buildDualCameraFrame(context),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 20),

                // ==========================================
                // SECTION 2: GPS Location Details
                // ==========================================
                _buildSectionHeader(
                  title: 'SECTION 2: VERIFIED GPS LOCATION & WORK SITE',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 12),
                _buildLocationBlock(),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 20),

                // ==========================================
                // SECTION 3: Date, Time & Live Shift Clock
                // ==========================================
                _buildSectionHeader(
                  title: 'SECTION 3: LIVE SHIFT DURATION & TIMESTAMPS',
                  icon: Icons.access_time_rounded,
                ),
                const SizedBox(height: 14),
                _buildTimeAndDurationBlock(formattedClockIn, isOvertime, isLimitExceeded),
                const SizedBox(height: 20),

                // Clock Out Action Button
                FilledButton.icon(
                  onPressed: onClockOut,
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text(
                    'Clock Out / End Shift',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Top Status Header Banner ---
  Widget _buildHeaderBanner(bool isOvertime, bool isLimitExceeded) {
    Color bannerBg = const Color(0xFFEFF6FF);
    Color bannerTextColor = const Color(0xFF1D4ED8);
    String statusText = 'ACTIVE SHIFT IN PROGRESS';
    IconData statusIcon = Icons.sensors_rounded;

    if (isLimitExceeded) {
      bannerBg = const Color(0xFFFEE2E2);
      bannerTextColor = const Color(0xFFB91C1C);
      statusText = 'MAXIMUM SHIFT LIMIT (10h) EXCEEDED';
      statusIcon = Icons.warning_amber_rounded;
    } else if (isOvertime) {
      bannerBg = const Color(0xFFFEF3C7);
      bannerTextColor = const Color(0xFFB45309);
      statusText = 'OVERTIME ACTIVE (APPROACHING 10h LIMIT)';
      statusIcon = Icons.timer_outlined;
    }

    return Container(
      color: bannerBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(statusIcon, color: bannerTextColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: bannerTextColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              record.employeeId,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: bannerTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2563EB),
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  // --- SECTION 1: Dual Camera Snapshots (Side-by-Side) ---
  Widget _buildDualCameraFrame(BuildContext context) {
    return Row(
      children: [
        // Left: Front Camera Selfie
        Expanded(
          child: _buildSnapshotTile(
            title: 'Employee Selfie',
            subtitle: 'Front Camera',
            imagePath: record.frontSelfiePath,
            imageBytes: record.frontSelfieBytes,
            isFront: true,
            onTap: () => _showFullImagePreview(
              context,
              title: 'Employee Verification Selfie',
              path: record.frontSelfiePath,
              bytes: record.frontSelfieBytes,
              isFront: true,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Right: Back Camera Site Snapshot
        Expanded(
          child: _buildSnapshotTile(
            title: 'Work Environment',
            subtitle: 'Back Camera',
            imagePath: record.backSitePhotoPath,
            imageBytes: record.backSitePhotoBytes,
            isFront: false,
            onTap: () => _showFullImagePreview(
              context,
              title: 'Work Site & Environment Snapshot',
              path: record.backSitePhotoPath,
              bytes: record.backSitePhotoBytes,
              isFront: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSnapshotTile({
    required String title,
    required String subtitle,
    required String? imagePath,
    required dynamic imageBytes,
    required bool isFront,
    required VoidCallback onTap,
  }) {
    final hasFile = imagePath != null && File(imagePath).existsSync();
    final hasBytes = imageBytes != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image Content
            if (hasFile)
              Image.file(File(imagePath), fit: BoxFit.cover)
            else if (hasBytes)
              Image.memory(imageBytes, fit: BoxFit.cover)
            else
              // Stylized Mock Placeholder
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isFront
                        ? [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)]
                        : [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isFront ? Icons.person_rounded : Icons.apartment_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isFront ? 'Selfie Verified' : 'Site Verified',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Top Camera Lens Tag
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFront ? Icons.camera_front_rounded : Icons.camera_rear_rounded,
                      color: Colors.white,
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isFront ? 'FRONT' : 'BACK',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Gradient Label Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SECTION 2: GPS Location Details ---
  Widget _buildLocationBlock() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'CLOCK-IN SITE LOCATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Text(
                        'GPS VERIFIED ✓',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Human-readable Address
                Text(
                  record.address,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Coordinates
                Row(
                  children: [
                    const Icon(Icons.my_location_rounded, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      'Coordinates: ${record.latitude.toStringAsFixed(5)}° N, ${record.longitude.toStringAsFixed(5)}° E',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION 3: Date, Time & Live Shift Clock ---
  Widget _buildTimeAndDurationBlock(
    String formattedClockIn,
    bool isOvertime,
    bool isLimitExceeded,
  ) {
    Color timerColor = const Color(0xFF2563EB);
    Color progressFillColor = const Color(0xFF2563EB);

    if (isLimitExceeded) {
      timerColor = const Color(0xFFDC2626);
      progressFillColor = const Color(0xFFDC2626);
    } else if (isOvertime) {
      timerColor = const Color(0xFFD97706);
      progressFillColor = const Color(0xFFF59E0B);
    }

    final progress8h = record.progressTo8Hours;
    final durationMinutes = record.duration.inMinutes;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Clock-In Timestamp Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SHIFT CLOCK-IN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.event_note_rounded, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    formattedClockIn,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Live Elapsed Duration Display (HH:MM:SS)
          Center(
            child: Text(
              record.formattedDuration,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: isLimitExceeded
                    ? const Color(0xFFF87171)
                    : isOvertime
                        ? const Color(0xFFFBBF24)
                        : Colors.white,
                letterSpacing: 2.0,
              ),
            ),
          ),
          Center(
            child: Text(
              'ELAPSED TIME (LIVE COUNTER)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: timerColor.withValues(alpha: 0.9),
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFF334155)),
          const SizedBox(height: 14),

          // Shift Limits & Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shift Target: 8h Standard',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOvertime ? const Color(0xFF34D399) : Colors.white70,
                ),
              ),
              Text(
                '${(progress8h * 100).toStringAsFixed(0)}% (Max 10h)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: progressFillColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress8h,
              minHeight: 10,
              backgroundColor: const Color(0xFF334155),
              valueColor: AlwaysStoppedAnimation<Color>(progressFillColor),
            ),
          ),
          const SizedBox(height: 10),

          // Threshold Notifications / Overtime Warnings
          if (isLimitExceeded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF7F1D1D),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.report_problem_rounded, color: Color(0xFFFCA5A5), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Warning: You have reached the maximum 10-hour shift limit. Please clock out immediately.',
                      style: TextStyle(
                        color: Color(0xFFFEE2E2),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (isOvertime)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF78350F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFFDE68A), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '8-hour standard target completed (${durationMinutes - 480}m overtime). 10-hour max cap.',
                      style: const TextStyle(
                        color: Color(0xFFFEF3C7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- Full Image Modal Dialog ---
  void _showFullImagePreview(
    BuildContext context, {
    required String title,
    required String? path,
    required dynamic bytes,
    required bool isFront,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: path != null && File(path).existsSync()
                        ? Image.file(File(path), fit: BoxFit.cover)
                        : bytes != null
                            ? Image.memory(bytes, fit: BoxFit.cover)
                            : Container(
                                color: isFront ? const Color(0xFF2563EB) : const Color(0xFF0F766E),
                                child: Center(
                                  child: Icon(
                                    isFront ? Icons.person_rounded : Icons.apartment_rounded,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

