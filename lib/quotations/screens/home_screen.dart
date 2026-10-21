import 'package:flutter/material.dart';
import 'package:shineplusinvoice/attendance/attendance.dart';
import '../../features/master_data/master_data.dart';
import '../models/quotation_chain.dart';
import '../services/quotation_repository.dart';
import '../services/pdf_generator_service.dart';
import 'quotations_dashboard_screen.dart';
import 'quotation_detail_screen.dart';

/// Screen 1: Main Home Screen (Default Corporate Entry Point).
///
/// Executive dashboard landing page featuring:
/// - Corporate header: Shine Plus (Private) Limited / Hashoo Foundation branding
/// - Live KPI metrics (Active Quotations, Total Pipeline, Draft Revisions)
/// - Prominent highlighted "Quotations" navigation card (navigating to Screen 2)
/// - Quick Action cards (New Proposal, Client Directory, Services)
/// - Recent Proposals activity feed
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = QuotationRepository.instance;

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final totalQuotations = repository.totalQuotationsCount;
        final totalPipeline = repository.totalPipelineValue;
        final totalRevisions = repository.totalRevisionsCount;
        final recentChains = repository.chains.take(3).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            elevation: 0,
            scrolledUnderElevation: 1,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Shine Plus Portal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Hashoo Foundation Startup',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      
                      const SizedBox(height: 24),

                      // Module Navigation Section Heading
                      const Text(
                        'CORE MODULES & WORKFLOWS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Prominent Quotations Navigation Card (Screen 1 ➔ Screen 2)
                      _buildProminentQuotationsCard(context, totalQuotations),
                      const SizedBox(height: 12),

                      // Attendance & Shift Verification Module Card
                      _buildAttendanceModuleCard(context),
                      const SizedBox(height: 12),

                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }




  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- Prominent Highlighted Quotations Navigation Card (Screen 1 ➔ Screen 2) ---
  Widget _buildProminentQuotationsCard(BuildContext context, int activeCount) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Seamless navigation to Quotations Dashboard (/quotations)
          Navigator.pushNamed(context, '/quotations');
        },
        splashColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF0F7FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Large Primary Icon Avatar
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.description_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Title, Subtitle, and Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'Quotations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        // Active Count Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$activeCount Active',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage, create & share corporate proposals with full revision history.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Forward Navigation Arrow
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Attendance & Shift Verification Module Card ---
  Widget _buildAttendanceModuleCard(BuildContext context) {
    return ListenableBuilder(
      listenable: AttendanceService.instance,
      builder: (context, _) {
        final service = AttendanceService.instance;
        final isOnShift = service.isClockedIn;
        final activeRecord = service.activeShift;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOnShift
                  ? (activeRecord?.isLimitExceeded == true
                      ? Colors.red.shade400
                      : activeRecord?.isOvertime == true
                          ? Colors.amber.shade500
                          : const Color(0xFF10B981))
                  : const Color(0xFFE2E8F0),
              width: isOnShift ? 1.6 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isOnShift ? const Color(0xFF0D9488) : const Color(0xFF0F172A))
                    .withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Seamless navigation to Attendance & Shifts (/attendance)
                Navigator.pushNamed(context, '/attendance');
              },
              splashColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOnShift
                        ? [Colors.white, const Color(0xFFF0FDF4)]
                        : [Colors.white, const Color(0xFFF8FAFC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Icon Avatar
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOnShift
                              ? (activeRecord?.isLimitExceeded == true
                                  ? [const Color(0xFFDC2626), const Color(0xFF991B1B)]
                                  : [const Color(0xFF0D9488), const Color(0xFF047857)])
                              : [const Color(0xFF0F766E), const Color(0xFF134E4A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isOnShift ? const Color(0xFF0D9488) : const Color(0xFF0F766E))
                                .withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.fingerprint_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Title, Subtitle, and Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              const Text(
                                'Attendance & Shifts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isOnShift
                                      ? (activeRecord?.isLimitExceeded == true
                                          ? const Color(0xFFDC2626)
                                          : activeRecord?.isOvertime == true
                                              ? const Color(0xFFD97706)
                                              : const Color(0xFF047857))
                                      : const Color(0xFF64748B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isOnShift
                                      ? 'ON SHIFT (${activeRecord?.formattedDuration ?? ""})'
                                      : 'OFF DUTY',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Dual-camera verification, GPS site tagging & 8-10h shift timer.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Forward Navigation Arrow
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF0D9488),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

 
  // --- Client Directory Modal ---
  void _showClientDirectoryModal(BuildContext context) {
    final chains = QuotationRepository.instance.chains;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text(
                'Major Corporate Clients',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Shine Plus (Private) Limited client portfolio',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ...chains.map((c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(Icons.business_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    title: Text(c.organization, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text('${c.clientName} (${c.activeDraft.client.city})', style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuotationDetailScreen(initialDraft: c.latestDraft),
                        ),
                      );
                    },
                  )),
            ],
          ),
        );
      },
    );
  }
}
