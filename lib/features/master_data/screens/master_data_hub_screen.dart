import 'package:flutter/material.dart';
import '../models/custom_list_schema.dart';
import '../services/master_data_service.dart';
import '../widgets/create_custom_list_dialog.dart';
import '../widgets/client_dialog.dart';
import '../widgets/service_dialog.dart';
import '../widgets/user_dialog.dart';
import 'clients_screen.dart';
import 'services_screen.dart';
import 'users_staff_screen.dart';
import 'dynamic_list_detail_screen.dart';

/// Screen: Master Data Hub Screen
///
/// Features:
/// - AppBar Breadcrumb: `Portal > Master Data Hub` with BackButton
/// - Executive KPI metrics: Total Clients, Services, Staff Roster, and Custom Registers
/// - Built-in System Lists Hub Cards (Clients, Services, Users/Staff) with direct navigation and quick add
/// - Dynamic Custom Lists Engine Section with prominent "+ Create New Custom List" button
/// - Full integration with Cloud Firestore and resilient offline caching
class MasterDataHubScreen extends StatelessWidget {
  final int initialTabIndex;

  const MasterDataHubScreen({super.key, this.initialTabIndex = 0});

  IconData _getSchemaIcon(String iconName) {
    switch (iconName) {
      case 'precision_manufacturing':
        return Icons.precision_manufacturing_rounded;
      case 'handyman':
        return Icons.handyman_rounded;
      case 'local_shipping':
        return Icons.local_shipping_rounded;
      case 'business':
        return Icons.business_rounded;
      case 'devices':
        return Icons.devices_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'list_alt':
        return Icons.list_alt_rounded;
      case 'inventory_2':
      default:
        return Icons.inventory_2_rounded;
    }
  }

  void _confirmDeleteSchema(BuildContext context, CustomListSchema schema) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Custom List?'),
        content: Text(
          'Are you sure you want to delete "${schema.displayName}" (/custom_lists_meta/${schema.listName}) and all its associated records?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await MasterDataService.instance.deleteCustomListSchema(schema.listName);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = MasterDataService.instance;

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final clientsCount = service.clients.length;
        final servicesCount = service.services.length;
        final staffCount = service.users.length;
        final customSchemas = service.customListSchemas;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            leading: const BackButton(),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Master Data & Registries',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Portal > Master Data Hub',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Overview Banner
                  _buildHeaderBanner(
                    clientsCount: clientsCount,
                    servicesCount: servicesCount,
                    staffCount: staffCount,
                    customCount: customSchemas.length,
                  ),
                  const SizedBox(height: 24),

                  // Section 1: BUILT-IN SYSTEM CORE LISTS
                  const Text(
                    'CORE SYSTEM REGISTERS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 1. Clients Card
                  _buildSystemRegisterCard(
                    context: context,
                    title: 'Corporate Clients',
                    subtitle: 'Manage client directory, focal persons, cities, and auto-fills for quotations.',
                    badge: '$clientsCount Clients',
                    badgeColor: const Color(0xFF2563EB),
                    icon: Icons.business_rounded,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF2563EB),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const ClientsScreen()),
                    ),
                    onQuickAdd: () => ClientDialog.show(context),
                  ),
                  const SizedBox(height: 12),

                  // 2. Services & Pricing Catalog Card
                  _buildSystemRegisterCard(
                    context: context,
                    title: 'Services & Pricing Catalog',
                    subtitle: 'Manage service catalog, standard company rates (PKR), units, and scope of work.',
                    badge: '$servicesCount Services',
                    badgeColor: const Color(0xFF059669),
                    icon: Icons.cleaning_services_rounded,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF059669),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const ServicesScreen()),
                    ),
                    onQuickAdd: () => ServiceDialog.show(context),
                  ),
                  const SizedBox(height: 12),

                  // 3. Users & Staff Card
                  _buildSystemRegisterCard(
                    context: context,
                    title: 'Users & Staff Roster',
                    subtitle: 'Manage field technicians, supervisors, sales managers and shift clock-in eligibility.',
                    badge: '$staffCount Staff',
                    badgeColor: const Color(0xFF7C3AED),
                    icon: Icons.badge_rounded,
                    iconBg: const Color(0xFFF5F3FF),
                    iconColor: const Color(0xFF7C3AED),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const UsersStaffScreen()),
                    ),
                    onQuickAdd: () => UserDialog.show(context),
                  ),
                  const SizedBox(height: 28),

                  // Section 2: DYNAMIC CUSTOM LISTS
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DYNAMIC CUSTOM REGISTERS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'Runtime administrator schemas stored in Firestore',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => CreateCustomListDialog.show(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('New Custom List', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (customSchemas.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.playlist_add_rounded, size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 10),
                            const Text('No custom lists created yet', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            const Text('Create dynamic lists like Assets, Inventory, or Machines.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => CreateCustomListDialog.show(context),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create First Custom List'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...customSchemas.map((schema) {
                      final recordsCount = service.getCustomRecords(schema.listName).length;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCustomListCard(context, schema, recordsCount),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderBanner({
    required int clientsCount,
    required int servicesCount,
    required int staffCount,
    required int customCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3B82F6), width: 0.8),
                ),
                child: const Text(
                  'MASTER DATA REPOSITORY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF93C5FD),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Text(
                'Firestore Sync',
                style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Enterprise Central Registries',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          const Text(
            'Clients, services catalog, and runtime extensible registers feeding proposals & shift logs.',
            style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1), height: 1.3),
          ),
          const SizedBox(height: 16),

          // Responsive KPI metrics
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildKpiChip('$clientsCount Clients', Icons.business_rounded, const Color(0xFF93C5FD)),
              _buildKpiChip('$servicesCount Services', Icons.cleaning_services_rounded, const Color(0xFFA7F3D0)),
              _buildKpiChip('$staffCount Staff', Icons.badge_rounded, const Color(0xFFDDD6FE)),
              _buildKpiChip('$customCount Custom', Icons.storage_rounded, const Color(0xFFFDE68A)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemRegisterCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
    required VoidCallback onQuickAdd,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Icon(icon, color: iconColor, size: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  tooltip: 'Quick Add',
                  onPressed: onQuickAdd,
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomListCard(BuildContext context, CustomListSchema schema, int recordsCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => DynamicListDetailScreen(schema: schema),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Icon(_getSchemaIcon(schema.iconName), color: const Color(0xFF2563EB), size: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            schema.displayName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$recordsCount Items',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        schema.description.isNotEmpty
                            ? schema.description
                            : 'Schema: /custom_lists_data_${schema.listName}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${schema.fields.length} Columns: ${schema.fields.map((f) => f.label).join(", ")}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
                  onSelected: (val) {
                    if (val == 'open') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => DynamicListDetailScreen(schema: schema),
                        ),
                      );
                    } else if (val == 'delete') {
                      _confirmDeleteSchema(context, schema);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'open', child: Row(children: [Icon(Icons.visibility_outlined, size: 18), SizedBox(width: 8), Text('Open Register')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete Schema', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

