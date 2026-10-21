import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/custom_list_schema.dart';
import '../models/custom_record_model.dart';
import '../services/master_data_service.dart';

/// Dynamic Record Dialog that renders appropriate form inputs (Text, Number, Date, Status)
/// based on the runtime CustomListSchema definition
class DynamicRecordDialog extends StatefulWidget {
  final CustomListSchema schema;
  final CustomRecord? existingRecord;

  const DynamicRecordDialog({
    super.key,
    required this.schema,
    this.existingRecord,
  });

  static Future<CustomRecord?> show(
    BuildContext context, {
    required CustomListSchema schema,
    CustomRecord? existingRecord,
  }) {
    return showDialog<CustomRecord>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DynamicRecordDialog(
        schema: schema,
        existingRecord: existingRecord,
      ),
    );
  }

  @override
  State<DynamicRecordDialog> createState() => _DynamicRecordDialogState();
}

class _DynamicRecordDialogState extends State<DynamicRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  bool get isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    final existingData = widget.existingRecord?.data ?? {};

    for (final field in widget.schema.fields) {
      final initialVal = existingData[field.name];
      if (field.type == CustomFieldType.date) {
        String dateStr = '';
        if (initialVal != null) {
          dateStr = initialVal.toString();
        } else {
          dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        }
        _formData[field.name] = dateStr;
        _controllers[field.name] = TextEditingController(text: dateStr);
      } else if (field.type == CustomFieldType.status) {
        final options = field.options.isNotEmpty ? field.options : ['Active', 'Pending', 'Inactive'];
        final currentVal = initialVal?.toString() ?? options.first;
        _formData[field.name] = currentVal;
      } else {
        final strVal = initialVal != null ? initialVal.toString() : '';
        _formData[field.name] = strVal;
        _controllers[field.name] = TextEditingController(text: strVal);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(CustomFieldDefinition field) async {
    DateTime initial = DateTime.now();
    final currentStr = _formData[field.name] as String?;
    if (currentStr != null && currentStr.isNotEmpty) {
      final parsed = DateTime.tryParse(currentStr);
      if (parsed != null) initial = parsed;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        _formData[field.name] = formatted;
        _controllers[field.name]?.text = formatted;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    try {
      final recordId = widget.existingRecord?.id ?? 'rec_${DateTime.now().millisecondsSinceEpoch}';

      final record = CustomRecord(
        id: recordId,
        listName: widget.schema.listName,
        data: Map<String, dynamic>.from(_formData),
        createdAt: widget.existingRecord?.createdAt,
        updatedAt: DateTime.now(),
      );

      await MasterDataService.instance.saveCustomRecord(record);

      if (mounted) {
        Navigator.of(context).pop(record);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Record updated' : 'Record added successfully'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving record: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildFieldWidget(CustomFieldDefinition field) {
    switch (field.type) {
      case CustomFieldType.text:
        return TextFormField(
          controller: _controllers[field.name],
          decoration: InputDecoration(
            labelText: '${field.label}${field.isRequired ? " *" : ""}',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
          validator: (val) {
            if (field.isRequired && (val == null || val.trim().isEmpty)) {
              return '${field.label} is required';
            }
            return null;
          },
          onSaved: (val) => _formData[field.name] = val?.trim() ?? '',
        );

      case CustomFieldType.number:
        return TextFormField(
          controller: _controllers[field.name],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: '${field.label}${field.isRequired ? " *" : ""}',
            hintText: '0.00',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
          validator: (val) {
            if (field.isRequired && (val == null || val.trim().isEmpty)) {
              return '${field.label} is required';
            }
            if (val != null && val.trim().isNotEmpty && num.tryParse(val.trim()) == null) {
              return 'Please enter a valid numeric value';
            }
            return null;
          },
          onSaved: (val) {
            final str = val?.trim() ?? '';
            final parsed = num.tryParse(str);
            _formData[field.name] = parsed ?? str;
          },
        );

      case CustomFieldType.date:
        return TextFormField(
          controller: _controllers[field.name],
          readOnly: true,
          onTap: () => _pickDate(field),
          decoration: InputDecoration(
            labelText: '${field.label}${field.isRequired ? " *" : ""}',
            hintText: 'YYYY-MM-DD',
            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.edit_calendar_rounded, size: 20),
              onPressed: () => _pickDate(field),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
          validator: (val) {
            if (field.isRequired && (val == null || val.trim().isEmpty)) {
              return '${field.label} is required';
            }
            return null;
          },
          onSaved: (val) => _formData[field.name] = val?.trim() ?? '',
        );

      case CustomFieldType.status:
        final options = field.options.isNotEmpty ? field.options : ['Active', 'Pending', 'Inactive'];
        String currentVal = _formData[field.name] as String? ?? options.first;
        if (!options.contains(currentVal)) {
          currentVal = options.first;
          _formData[field.name] = currentVal;
        }

        return DropdownButtonFormField<String>(
          initialValue: currentVal,
          decoration: InputDecoration(
            labelText: '${field.label}${field.isRequired ? " *" : ""}',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
          items: options.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusDotColor(opt),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(opt),
                ],
              ),
            );
          }).toList(),
          onChanged: (newVal) {
            if (newVal != null) {
              setState(() => _formData[field.name] = newVal);
            }
          },
          onSaved: (val) => _formData[field.name] = val ?? options.first,
        );
    }
  }

  Color _getStatusDotColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('active') || lower.contains('operational') || lower.contains('in stock')) {
      return const Color(0xFF10B981);
    } else if (lower.contains('maintenance') || lower.contains('low') || lower.contains('repair')) {
      return const Color(0xFFF59E0B);
    } else if (lower.contains('out') || lower.contains('retired') || lower.contains('inactive')) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 540, maxHeight: screenHeight * 0.85),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.playlist_add_check_rounded, color: Color(0xFF2563EB), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit ${widget.schema.displayName} Item' : 'New ${widget.schema.displayName} Item',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Register: /custom_lists_data_${widget.schema.listName}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 20, thickness: 0.8),

                // Dynamic Form Fields List
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: widget.schema.fields.map((field) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildFieldWidget(field),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        isEditing ? 'Update Record' : 'Save Record',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
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

