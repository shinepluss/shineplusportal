import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../services/master_data_service.dart';
import '../widgets/user_dialog.dart';

/// Screen: Users & Staff Roster Screen
class UsersStaffScreen extends StatefulWidget {
  const UsersStaffScreen({super.key});

  @override
  State<UsersStaffScreen> createState() => _UsersStaffScreenState();
}

class _UsersStaffScreenState extends State<UsersStaffScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All Staff';

  final List<String> _statusFilters = [
    'All Staff',
    'Active',
    'On Leave',
    'Inactive',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return;
    final uri = Uri.parse('tel:$cleaned');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _confirmDelete(UserModel user) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff Member?'),
        content: Text('Are you sure you want to delete "${user.fullName}" (${user.employeeId})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await MasterDataService.instance.deleteUser(user.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getStatusBg(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('active')) return const Color(0xFFECFDF5);
    if (lower.contains('leave')) return const Color(0xFFFFFBEB);
    return const Color(0xFFFEF2F2);
  }

  Color _getStatusText(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('active')) return const Color(0xFF047857);
    if (lower.contains('leave')) return const Color(0xFFB45309);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final service = MasterDataService.instance;

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final allUsers = service.users;
        final query = _searchController.text.trim().toLowerCase();

        final filtered = allUsers.where((u) {
          final matchesSearch = query.isEmpty ||
              u.fullName.toLowerCase().contains(query) ||
              u.employeeId.toLowerCase().contains(query) ||
              u.role.toLowerCase().contains(query);

          final matchesStatus = _selectedStatus == 'All Staff' ||
              u.status.toLowerCase() == _selectedStatus.toLowerCase();

          return matchesSearch && matchesStatus;
        }).toList();

        final activeCount = allUsers.where((u) => u.status.toLowerCase() == 'active').length;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            leading: const BackButton(),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Users & Staff Roster',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Master Data > Users & Staff',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$activeCount / ${allUsers.length} Active',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => UserDialog.show(context),
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Register Staff'),
          ),
          body: Column(
            children: [
              // Search & Filter Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search staff by name, code (SP-101), or role...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Status Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _statusFilters.map((st) {
                          final isSelected = _selectedStatus == st;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(st),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedStatus = st);
                                }
                              },
                              selectedColor: const Color(0xFF7C3AED),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : const Color(0xFF334155),
                              ),
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

              // Staff List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.badge_outlined, size: 56, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            Text(
                              query.isNotEmpty ? 'No staff match "$query"' : 'No staff found with status $_selectedStatus',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            const Text('Tap "+ Register Staff" to add staff eligible for shifts.', style: TextStyle(color: Color(0xFF64748B))),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final user = filtered[index];
                          return _buildStaffCard(user);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaffCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED)),
                    ),
                  ),
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
                            user.fullName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.employeeId,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.role,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF7C3AED)),
                      tooltip: 'Edit Staff',
                      onPressed: () => UserDialog.show(context, user: user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      tooltip: 'Delete Staff',
                      onPressed: () => _confirmDelete(user),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 18, thickness: 0.8),

            // Status and Phone Row (Responsive)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getStatusBg(user.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStatusText(user.status),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.status,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _getStatusText(user.status)),
                      ),
                    ],
                  ),
                ),

                // Phone button
                if (user.phone.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(user.phone),
                    icon: const Icon(Icons.call_rounded, size: 14),
                    label: Text(user.phone, style: const TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

