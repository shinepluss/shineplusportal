import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../models/service_model.dart';
import '../models/user_model.dart';
import '../services/master_data_service.dart';
import '../widgets/client_dialog.dart';
import '../widgets/service_dialog.dart';
import '../widgets/user_dialog.dart';

/// Screen: Master Data Management Module (Clients, Services, Staff)
class MasterDataScreen extends StatefulWidget {
  final int initialTabIndex;

  const MasterDataScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = MasterDataService.instance;

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final clients = _filterClients(service.clients);
        final services = _filterServices(service.services);
        final users = _filterUsers(service.users);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            elevation: 0,
            scrolledUnderElevation: 1,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Master Data Repository',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                ),
                Text(
                  '${service.totalRecordsCount} Total Active Corporate Entities',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF2563EB),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(
                  icon: const Icon(Icons.business_rounded, size: 20),
                  text: 'Clients (${service.clients.length})',
                ),
                Tab(
                  icon: const Icon(Icons.cleaning_services_rounded, size: 20),
                  text: 'Catalog (${service.services.length})',
                ),
                Tab(
                  icon: const Icon(Icons.badge_rounded, size: 20),
                  text: 'Staff & Users (${service.users.length})',
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Top Search Bar & Counter
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                          decoration: InputDecoration(
                            hintText: _getSearchHint(),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () => _openAddDialogForCurrentTab(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(_getAddButtonLabel()),
                        style: FilledButton.styleFrom(
                          backgroundColor: _getCurrentTabColor(),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Tab Content Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildClientsTab(clients),
                      _buildServicesTab(services),
                      _buildUsersTab(users),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getSearchHint() {
    switch (_tabController.index) {
      case 0:
        return 'Search client by name, organization, or city...';
      case 1:
        return 'Search service title or unit...';
      case 2:
        return 'Search staff by name, ID, or designation...';
      default:
        return 'Search master records...';
    }
  }

  String _getAddButtonLabel() {
    switch (_tabController.index) {
      case 0:
        return 'Add Client';
      case 1:
        return 'Add Service';
      case 2:
        return 'Add Staff';
      default:
        return 'Add New';
    }
  }

  Color _getCurrentTabColor() {
    switch (_tabController.index) {
      case 0:
        return const Color(0xFF2563EB);
      case 1:
        return const Color(0xFF059669);
      case 2:
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF2563EB);
    }
  }

  void _openAddDialogForCurrentTab() {
    switch (_tabController.index) {
      case 0:
        ClientDialog.show(context);
        break;
      case 1:
        ServiceDialog.show(context);
        break;
      case 2:
        UserDialog.show(context);
        break;
    }
  }

  // --- FILTERS ---

  List<ClientModel> _filterClients(List<ClientModel> all) {
    if (_searchQuery.isEmpty) return all;
    return all.where((c) {
      return c.contactName.toLowerCase().contains(_searchQuery) ||
          c.organization.toLowerCase().contains(_searchQuery) ||
          c.city.toLowerCase().contains(_searchQuery) ||
          c.designation.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  List<ServiceModel> _filterServices(List<ServiceModel> all) {
    if (_searchQuery.isEmpty) return all;
    return all.where((s) {
      return s.title.toLowerCase().contains(_searchQuery) ||
          s.defaultUnit.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  List<UserModel> _filterUsers(List<UserModel> all) {
    if (_searchQuery.isEmpty) return all;
    return all.where((u) {
      return u.fullName.toLowerCase().contains(_searchQuery) ||
          u.employeeId.toLowerCase().contains(_searchQuery) ||
          u.role.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  // --- TAB 1: CLIENTS ---

  Widget _buildClientsTab(List<ClientModel> clients) {
    if (clients.isEmpty) {
      return _buildEmptyState('No clients found matching "$_searchQuery"');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: clients.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final client = clients[index];
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      client.organization.isNotEmpty ? client.organization[0].toUpperCase() : 'C',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
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
                          Expanded(
                            child: Text(
                              client.contactName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              client.city,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${client.designation} • ${client.organization}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                      ),
                      if (client.phone.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          client.phone,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      ClientDialog.show(context, client: client);
                    } else if (val == 'delete') {
                      _confirmDelete(
                        title: 'Delete Client',
                        message: 'Are you sure you want to delete ${client.contactName} (${client.organization})?',
                        onConfirm: () => MasterDataService.instance.deleteClient(client.id),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                          SizedBox(width: 8),
                          Text('Edit Client'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                          SizedBox(width: 8),
                          Text('Delete Client'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- TAB 2: SERVICES & PRICING CATALOG ---

  Widget _buildServicesTab(List<ServiceModel> services) {
    if (services.isEmpty) {
      return _buildEmptyState('No catalog services found matching "$_searchQuery"');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final service = services[index];
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.cleaning_services_rounded, color: Color(0xFF059669), size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'PKR ${service.standardCompanyRate.toStringAsFixed(0)} / ${service.defaultUnit}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Unit: ${service.defaultUnit}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      ServiceDialog.show(context, service: service);
                    } else if (val == 'delete') {
                      _confirmDelete(
                        title: 'Delete Service',
                        message: 'Are you sure you want to remove "${service.title}" from pricing catalog?',
                        onConfirm: () => MasterDataService.instance.deleteService(service.id),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF059669)),
                          SizedBox(width: 8),
                          Text('Edit Service'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                          SizedBox(width: 8),
                          Text('Delete Service'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- TAB 3: USERS & EMPLOYEES ---

  Widget _buildUsersTab(List<UserModel> users) {
    if (users.isEmpty) {
      return _buildEmptyState('No staff members found matching "$_searchQuery"');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = users[index];
        final isActive = user.status == 'active';

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.badge_rounded, color: Color(0xFF7C3AED), size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.fullName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isActive ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              user.employeeId,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6D28D9)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user.role,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      UserDialog.show(context, user: user);
                    } else if (val == 'delete') {
                      _confirmDelete(
                        title: 'Delete Staff Member',
                        message: 'Are you sure you want to remove ${user.fullName} (${user.employeeId})?',
                        onConfirm: () => MasterDataService.instance.deleteUser(user.id),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF7C3AED)),
                          SizedBox(width: 8),
                          Text('Edit Staff'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                          SizedBox(width: 8),
                          Text('Delete Staff'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
