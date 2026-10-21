import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../widgets/active_shift_card.dart';
import '../widgets/camera_capture_dialog.dart';

/// Standalone, fully exportable Attendance & Shift Verification Dashboard Screen.
///
/// Features:
/// - Sequential Evidence Capture Clock-In Wizard (Selfie ➔ Site ➔ GPS)
/// - Live persistent Shift Timer with 8h Standard Target and 10h Maximum Limit alerts
/// - Visual 3-Section Active Shift Verification Summary Card
/// - Historical Shift Logs with expandable verification proof & photo modals
/// - Developer/QA Simulation tools for instant verification of 8h and 10h alert states
class AttendanceScreen extends StatefulWidget {
  final String defaultEmployeeName;
  final String defaultEmployeeId;

  const AttendanceScreen({
    super.key,
    this.defaultEmployeeName = 'Amir Nawaz',
    this.defaultEmployeeId = 'SP-101',
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _service = AttendanceService.instance;
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);

    // Live 1-second interval timer for real-time HH:MM:SS update
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _service.isClockedIn) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  // --- Clock In Flow ---
  Future<void> _handleClockIn() async {
    final result = await showClockInVerificationModal(
      context: context,
      initialEmployeeName: widget.defaultEmployeeName,
      initialEmployeeId: widget.defaultEmployeeId,
    );

    if (result != null && mounted) {
      final record = _service.clockIn(
        employeeName: result['employee_name'] as String,
        employeeId: result['employee_id'] as String,
        frontCapture: result['front_capture'] as CameraCaptureResult,
        backCapture: result['back_capture'] as CameraCaptureResult,
        location: result['location'] as LocationResult,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Shift Started! Verified clock-in at ${DateFormat('hh:mm a').format(record.clockInTime)}.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0D9488),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // --- Clock Out Flow ---
  Future<void> _handleClockOut() async {
    final active = _service.activeShift;
    if (active == null) return;

    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 10),
            Text('Clock Out Confirmation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to end your shift? You have been active for ${active.formattedDuration}.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Shift Handover / Notes (Optional):',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g., Completed Mosque grinding and tile sealing...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Confirm Clock Out', style: TextStyle(fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final finished = _service.clockOut(notes: notesController.text.trim());
      if (finished != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.task_alt_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Shift ended. Total duration logged: ${finished.formattedDuration}.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // --- Show Simulation Menu (for QA & testing 8h / 10h states) ---
  void _showSimulationBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.science_outlined, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shift Testing & Simulation Tool',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        'Fast-forward timers to test overtime & limit warnings',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: Color(0xFF0D9488)),
                title: const Text('Simulate Fresh Shift (15 minutes in)', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Normal shift progress (< 8 hrs)'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: const Color(0xFFF8FAFC),
                onTap: () {
                  Navigator.pop(ctx);
                  _service.setSimulatedActiveShift(const Duration(minutes: 15));
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                title: const Text('Simulate Overtime (8 hrs 35 mins)', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Triggers standard 8h target reached warning'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: const Color(0xFFFFFBEB),
                onTap: () {
                  Navigator.pop(ctx);
                  _service.setSimulatedActiveShift(const Duration(hours: 8, minutes: 35));
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.error_outline_rounded, color: Colors.red),
                title: const Text('Simulate Max Limit Exceeded (10 hrs 15 mins)', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Triggers 10h critical maximum threshold alert'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: const Color(0xFFFEF2F2),
                onTap: () {
                  Navigator.pop(ctx);
                  _service.setSimulatedActiveShift(const Duration(hours: 10, minutes: 15));
                },
              ),
              if (_service.isClockedIn) ...[
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.clear_rounded, color: Color(0xFF64748B)),
                  title: const Text('Clear Active Shift', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Reset back to Clocked Out state'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: const Color(0xFFF1F5F9),
                  onTap: () {
                    Navigator.pop(ctx);
                    _service.clockOut(notes: 'Reset via QA tool');
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeShift = _service.activeShift;
    final pastShifts = _service.pastShifts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance & Shift Clock',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.2,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Verified Clock-In & Location Logging',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'QA & Shift Simulation Tool',
            onPressed: _showSimulationBottomSheet,
            icon: const Icon(Icons.science_outlined, color: Color(0xFF475569)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Employee Header Info Card
          _buildEmployeeHeaderCard(),
          const SizedBox(height: 20),

          // Active Shift Summary Card OR Clock In Hero
          if (activeShift != null) ...[
            ActiveShiftCard(
              record: activeShift,
              onClockOut: _handleClockOut,
            ),
          ] else ...[
            _buildClockInHeroCard(),
          ],

          const SizedBox(height: 28),

          // Past Shifts Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_rounded, size: 20, color: Color(0xFF0F172A)),
                  const SizedBox(width: 8),
                  const Text(
                    'Past Shift Verification Logs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${pastShifts.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // List of past shifts
          if (pastShifts.isEmpty)
            _buildEmptyLogs()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pastShifts.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) => _buildShiftHistoryTile(pastShifts[index]),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Employee Info Banner ---
  Widget _buildEmployeeHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'SP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.defaultEmployeeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.defaultEmployeeId,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Field Specialist • Shine Plus (Pvt) Ltd',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _service.isClockedIn
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _service.isClockedIn
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _service.isClockedIn
                        ? const Color(0xFF10B981)
                        : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _service.isClockedIn ? 'ON SHIFT' : 'OFF DUTY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _service.isClockedIn
                        ? const Color(0xFF047857)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Clock In Hero Banner (Shown when off duty) ---
  Widget _buildClockInHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF38BDF8), size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to Start Shift',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Requires dual-camera and GPS verification',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3-step verification requirement chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildVerificationBadge(Icons.face_rounded, 'Selfie Proof'),
                const Text('➔', style: TextStyle(color: Colors.white38)),
                _buildVerificationBadge(Icons.location_city_rounded, 'Work Site'),
                const Text('➔', style: TextStyle(color: Colors.white38)),
                _buildVerificationBadge(Icons.gps_fixed_rounded, 'GPS Tag'),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Big Clock In Action Button
          FilledButton.icon(
            onPressed: _handleClockIn,
            icon: const Icon(Icons.camera_alt_rounded, size: 22),
            label: const Text(
              'Clock In / Verify Attendance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --- Shift History Tile ---
  Widget _buildShiftHistoryTile(AttendanceRecord record) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final durationStr = record.formattedDuration;
    final isOvertime = record.isOvertime;
    final isLimitExceeded = record.isLimitExceeded;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showShiftDetailModal(record),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top line: Date and Duration Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.event_note_rounded, size: 18, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFormat.format(record.clockInTime),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '${timeFormat.format(record.clockInTime)} - ${record.clockOutTime != null ? timeFormat.format(record.clockOutTime!) : 'Ongoing'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLimitExceeded
                          ? const Color(0xFFFEF2F2)
                          : isOvertime
                              ? const Color(0xFFFFFBEB)
                              : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLimitExceeded
                            ? const Color(0xFFFECACA)
                            : isOvertime
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFFA7F3D0),
                      ),
                    ),
                    child: Text(
                      durationStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isLimitExceeded
                            ? const Color(0xFFDC2626)
                            : isOvertime
                                ? const Color(0xFFB45309)
                                : const Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Location snippet
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      record.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Evidence indicator bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF0D9488)),
                        const SizedBox(width: 6),
                        Text(
                          record.isMock ? 'Simulated Proof' : 'GPS & Dual Camera Verified',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: record.isMock ? const Color(0xFF64748B) : const Color(0xFF0D9488),
                          ),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Text(
                          'View Evidence',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF2563EB)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Show Past Shift Verification Details Modal ---
  void _showShiftDetailModal(AttendanceRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shift Record ${record.id}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    Text(
                      'Employee: ${record.employeeName} (${record.employeeId})',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                children: [
                  // Dual Photos
                  const Text(
                    'VERIFICATION EVIDENCE (DUAL CAMERA)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailImagePreview('Front Selfie', record.frontSelfiePath, record.frontSelfieBytes),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailImagePreview('Site Environment', record.backSitePhotoPath, record.backSitePhotoBytes),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Location details
                  const Text(
                    'GPS LOCATION DETAILS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFDC2626), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                record.address,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Coordinates: ${record.latitude.toStringAsFixed(6)}°, ${record.longitude.toStringAsFixed(6)}°',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Duration & Timestamps
                  const Text(
                    'SHIFT TIMINGS & DURATION',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildTimingRow(
                          'Clocked In',
                          DateFormat('dd-MMM-yyyy, hh:mm a').format(record.clockInTime),
                          Icons.login_rounded,
                        ),
                        const Divider(height: 16),
                        _buildTimingRow(
                          'Clocked Out',
                          record.clockOutTime != null
                              ? DateFormat('dd-MMM-yyyy, hh:mm a').format(record.clockOutTime!)
                              : 'Still in progress',
                          Icons.logout_rounded,
                        ),
                        const Divider(height: 16),
                        _buildTimingRow(
                          'Total Duration',
                          record.formattedDuration,
                          Icons.hourglass_bottom_rounded,
                          highlightColor: record.isLimitExceeded
                              ? Colors.red
                              : record.isOvertime
                                  ? Colors.amber.shade800
                                  : const Color(0xFF047857),
                        ),
                      ],
                    ),
                  ),

                  if (record.notes != null && record.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'EMPLOYEE NOTES',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        record.notes!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF78350F)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailImagePreview(String title, String? path, List<int>? bytes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (path != null && File(path).existsSync())
                Image.file(File(path), fit: BoxFit.cover)
              else if (bytes != null && bytes.isNotEmpty)
                Image.memory(Uint8List.fromList(bytes), fit: BoxFit.cover)
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        title.contains('Selfie') ? Icons.person_rounded : Icons.apartment_rounded,
                        color: Colors.white54,
                        size: 36,
                      ),
                      const SizedBox(height: 4),
                      Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimingRow(String label, String value, IconData icon, {Color? highlightColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: highlightColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // --- Empty History ---
  Widget _buildEmptyLogs() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.assignment_outlined, size: 40, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'No Prior Shifts Logged',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B)),
          ),
          SizedBox(height: 4),
          Text(
            'Completed shifts with verification evidence will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
