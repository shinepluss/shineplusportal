import 'package:flutter/material.dart';
import '../models/custom_list_schema.dart';
import '../models/custom_record_model.dart';
import '../services/master_data_service.dart';
import '../widgets/dynamic_record_dialog.dart';

/// Generic Dynamic List Screen that automatically renders records for any defined CustomListSchema
class DynamicListDetailScreen extends StatefulWidget {
  final CustomListSchema schema;

  const DynamicListDetailScreen({super.key, required this.schema});

  @override
  State<DynamicListDetailScreen> createState() => _DynamicListDetailScreenState();
}

class _DynamicListDetailScreenState extends State<DynamicListDetailScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDeleteRecord(CustomRecord record) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Custom Record?'),
        content: const Text('Are you sure you want to permanently delete this record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await MasterDataService.instance.deleteCustomRecord(widget.schema.listName, record.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final masterService = MasterDataService.instance;

    return ListenableBuilder(
      listenable: masterService,
      builder: (context, _) {
        final records = masterService.getCustomRecords(widget.schema.listName);
        final query = _searchController.text.trim().toLowerCase();

        final filtered = records.where((r) {
          if (query.isEmpty) return true;
          // Search across all dynamic field values
          return r.data.values.any((val) => val.toString().toLowerCase().contains(query));
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            leading: const BackButton(),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.schema.displayName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Master Data > Custom Lists > ${widget.schema.displayName}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
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
                  '${records.length} Records',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => DynamicRecordDialog.show(context, schema: widget.schema),
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Item'),
          ),
          body: Column(
            children: [
              // Schema Overview Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_getSchemaIcon(widget.schema.iconName), color: const Color(0xFF2563EB), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.schema.description.isNotEmpty
                                    ? widget.schema.description
                                    : 'Dynamic collection: /custom_lists_data_${widget.schema.listName}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.schema.fields.length} Columns: ${widget.schema.fields.map((f) => f.label).join(", ")}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search input
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search across all ${widget.schema.displayName} fields...',
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
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

              // Records List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 56, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            Text(
                              query.isNotEmpty ? 'No items match "$query"' : 'No items recorded in ${widget.schema.displayName}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              query.isNotEmpty ? 'Try adjusting your search query' : 'Tap below to add the first record',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => DynamicRecordDialog.show(context, schema: widget.schema),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Record'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final record = filtered[index];
                          return _buildRecordCard(record);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordCard(CustomRecord record) {
    // Determine a primary title from the first non-empty field
    String primaryTitle = 'Record #${record.id.substring(record.id.length > 6 ? record.id.length - 6 : 0)}';
    if (widget.schema.fields.isNotEmpty) {
      final firstFieldName = widget.schema.fields.first.name;
      final val = record.data[firstFieldName];
      if (val != null && val.toString().isNotEmpty) {
        primaryTitle = val.toString();
      }
    }

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    primaryTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                      tooltip: 'Edit Record',
                      onPressed: () => DynamicRecordDialog.show(
                        context,
                        schema: widget.schema,
                        existingRecord: record,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      tooltip: 'Delete Record',
                      onPressed: () => _confirmDeleteRecord(record),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16, thickness: 0.8),
            // Render all defined fields
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: widget.schema.fields.map((field) {
                final val = record.data[field.name];
                return _buildFieldDisplay(field, val);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldDisplay(CustomFieldDefinition field, dynamic value) {
    final displayStr = value != null ? value.toString() : '—';

    if (field.type == CustomFieldType.status) {
      Color bg = const Color(0xFFF1F5F9);
      Color text = const Color(0xFF334155);
      final lower = displayStr.toLowerCase();
      if (lower.contains('active') || lower.contains('operational') || lower.contains('in stock')) {
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF047857);
      } else if (lower.contains('maintenance') || lower.contains('low') || lower.contains('repair')) {
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFB45309);
      } else if (lower.contains('out') || lower.contains('decommissioned') || lower.contains('retired')) {
        bg = const Color(0xFFFEF2F2);
        text = const Color(0xFFDC2626);
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${field.label}: ',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text.withValues(alpha: 0.8)),
            ),
            Text(
              displayStr,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: text),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            field.label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 1),
          Text(
            displayStr,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}

