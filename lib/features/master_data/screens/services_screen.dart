import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../services/master_data_service.dart';
import '../widgets/service_dialog.dart';

/// Screen: Services & Pricing Catalog Screen
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedUnit = 'All Units';

  final List<String> _units = [
    'All Units',
    'Sq. Ft.',
    'Washroom',
    'Kitchen Unit',
    'Room',
    'Job / Lump Sum',
    'Hour',
    'Day',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(ServiceModel service) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Service?'),
        content: Text('Are you sure you want to delete "${service.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await MasterDataService.instance.deleteService(service.id);
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
        final allServices = service.services;
        final query = _searchController.text.trim().toLowerCase();

        final filtered = allServices.where((s) {
          final matchesSearch = query.isEmpty ||
              s.title.toLowerCase().contains(query) ||
              s.description.toLowerCase().contains(query) ||
              s.defaultUnit.toLowerCase().contains(query);

          final matchesUnit = _selectedUnit == 'All Units' ||
              s.defaultUnit.toLowerCase() == _selectedUnit.toLowerCase();

          return matchesSearch && matchesUnit;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            leading: const BackButton(),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Services & Pricing Catalog',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Master Data > Services',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${allServices.length} Services',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => ServiceDialog.show(context),
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Service'),
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
                        hintText: 'Search services, rates, or scope of work...',
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
                    // Unit Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _units.map((unit) {
                          final isSelected = _selectedUnit == unit;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(unit),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedUnit = unit);
                                }
                              },
                              selectedColor: const Color(0xFF059669),
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

              // Services List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cleaning_services_outlined, size: 56, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            Text(
                              query.isNotEmpty ? 'No services match "$query"' : 'No services found for unit $_selectedUnit',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            const Text('Tap "+ Add Service" to add a new catalog item.', style: TextStyle(color: Color(0xFF64748B))),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _buildServiceCard(item);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceCard(ServiceModel item) {
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
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.cleaning_services_rounded, color: Color(0xFF059669), size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF059669)),
                      tooltip: 'Edit Service',
                      onPressed: () => ServiceDialog.show(context, service: item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      tooltip: 'Delete Service',
                      onPressed: () => _confirmDelete(item),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 18, thickness: 0.8),

            // Rate and Unit Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Unit: ${item.defaultUnit}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    'PKR ${item.standardCompanyRate.toStringAsFixed(0)} / ${item.defaultUnit}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
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

