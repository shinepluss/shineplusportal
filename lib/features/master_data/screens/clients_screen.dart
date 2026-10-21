import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/client_model.dart';
import '../services/master_data_service.dart';
import '../widgets/client_dialog.dart';

/// Screen: Corporate Clients Directory & Management
class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCity = 'All Cities';

  final List<String> _cities = [
    'All Cities',
    'Lahore',
    'Faisalabad',
    'Islamabad',
    'Karachi',
    'Rawalpindi',
    'Multan',
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot initiate phone call to $phone')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open phone dialer: $e')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return;
    // Format for Pakistan international prefix if starts with 0
    String formattedPhone = digitsOnly;
    if (digitsOnly.startsWith('03')) {
      formattedPhone = '92${digitsOnly.substring(1)}';
    }
    final uri = Uri.parse('https://wa.me/$formattedPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch WhatsApp for $phone')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching WhatsApp: $e')),
        );
      }
    }
  }

  void _confirmDelete(ClientModel client) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Client?'),
        content: Text('Are you sure you want to permanently delete "${client.contactName}" (${client.organization})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await MasterDataService.instance.deleteClient(client.id);
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
        final allClients = service.clients;
        final query = _searchController.text.trim().toLowerCase();

        final filtered = allClients.where((c) {
          final matchesSearch = query.isEmpty ||
              c.contactName.toLowerCase().contains(query) ||
              c.organization.toLowerCase().contains(query) ||
              c.designation.toLowerCase().contains(query) ||
              c.city.toLowerCase().contains(query);

          final matchesCity = _selectedCity == 'All Cities' ||
              c.city.toLowerCase() == _selectedCity.toLowerCase();

          return matchesSearch && matchesCity;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            leading: const BackButton(),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clients Directory',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Master Data > Clients',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${allClients.length} Clients',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => ClientDialog.show(context),
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add Client'),
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
                        hintText: 'Search by client name, organization, or city...',
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
                    // City Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _cities.map((city) {
                          final isSelected = _selectedCity == city;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(city),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedCity = city);
                                }
                              },
                              selectedColor: const Color(0xFF2563EB),
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

              // Clients List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.business_outlined, size: 56, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            Text(
                              query.isNotEmpty ? 'No clients match "$query"' : 'No clients found in $_selectedCity',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            const Text('Tap "+ Add Client" to add a new corporate client.', style: TextStyle(color: Color(0xFF64748B))),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final client = filtered[index];
                          return _buildClientCard(client);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClientCard(ClientModel client) {
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
            // Row 1: Avatar, Name & Organization, Edit/Delete
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      client.contactName.isNotEmpty ? client.contactName[0].toUpperCase() : 'C',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.contactName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${client.designation} • ${client.organization}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                      tooltip: 'Edit Client',
                      onPressed: () => ClientDialog.show(context, client: client),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      tooltip: 'Delete Client',
                      onPressed: () => _confirmDelete(client),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 18, thickness: 0.8),

            // Row 2: Location, Contact Details & Direct Call / WhatsApp Actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Location badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(client.city, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    ],
                  ),
                ),

                // Phone & Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (client.phone.isNotEmpty) ...[
                      // Call button
                      OutlinedButton.icon(
                        onPressed: () => _makePhoneCall(client.phone),
                        icon: const Icon(Icons.call_rounded, size: 14),
                        label: Text(client.phone, style: const TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // WhatsApp button
                      IconButton.filledTonal(
                        onPressed: () => _openWhatsApp(client.phone),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        tooltip: 'Open WhatsApp Chat',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFDCFCE7),
                          foregroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.all(6),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

