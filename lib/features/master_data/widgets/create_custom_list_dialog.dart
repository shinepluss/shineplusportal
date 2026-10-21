import 'package:flutter/material.dart';
import '../models/custom_list_schema.dart';
import '../services/master_data_service.dart';

/// Modal dialog for defining or editing a Dynamic Custom List Schema
class CreateCustomListDialog extends StatefulWidget {
  final CustomListSchema? existingSchema;

  const CreateCustomListDialog({super.key, this.existingSchema});

  static Future<CustomListSchema?> show(BuildContext context, {CustomListSchema? existingSchema}) {
    return showDialog<CustomListSchema>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CreateCustomListDialog(existingSchema: existingSchema),
    );
  }

  @override
  State<CreateCustomListDialog> createState() => _CreateCustomListDialogState();
}

class _FieldItemState {
  final TextEditingController labelController;
  CustomFieldType type;
  final TextEditingController optionsController;
  bool isRequired;

  _FieldItemState({
    required String label,
    this.type = CustomFieldType.text,
    String options = '',
    this.isRequired = false,
  })  : labelController = TextEditingController(text: label),
        optionsController = TextEditingController(text: options);

  void dispose() {
    labelController.dispose();
    optionsController.dispose();
  }
}

class _CreateCustomListDialogState extends State<CreateCustomListDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _displayNameController;
  late TextEditingController _listNameController;
  late TextEditingController _descController;
  late String _selectedIcon;
  final List<_FieldItemState> _fieldDrafts = [];
  bool _manualListNameEdited = false;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _iconChoices = [
    {'name': 'inventory_2', 'icon': Icons.inventory_2_rounded, 'label': 'Inventory'},
    {'name': 'precision_manufacturing', 'icon': Icons.precision_manufacturing_rounded, 'label': 'Machinery'},
    {'name': 'handyman', 'icon': Icons.handyman_rounded, 'label': 'Equipment'},
    {'name': 'local_shipping', 'icon': Icons.local_shipping_rounded, 'label': 'Logistics'},
    {'name': 'business', 'icon': Icons.business_rounded, 'label': 'Vendors'},
    {'name': 'devices', 'icon': Icons.devices_rounded, 'label': 'Hardware'},
    {'name': 'science', 'icon': Icons.science_rounded, 'label': 'Chemicals'},
    {'name': 'list_alt', 'icon': Icons.list_alt_rounded, 'label': 'Registry'},
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.existingSchema;
    _displayNameController = TextEditingController(text: s?.displayName ?? '');
    _listNameController = TextEditingController(text: s?.listName ?? '');
    _descController = TextEditingController(text: s?.description ?? '');
    _selectedIcon = s?.iconName ?? 'inventory_2';

    if (s != null && s.fields.isNotEmpty) {
      for (final f in s.fields) {
        _fieldDrafts.add(
          _FieldItemState(
            label: f.label,
            type: f.type,
            options: f.options.join(', '),
            isRequired: f.isRequired,
          ),
        );
      }
    } else {
      // Default starter fields for new custom list
      _fieldDrafts.add(
        _FieldItemState(label: 'Item Name', type: CustomFieldType.text, isRequired: true),
      );
      _fieldDrafts.add(
        _FieldItemState(label: 'Identifier / Tag', type: CustomFieldType.text),
      );
      _fieldDrafts.add(
        _FieldItemState(
          label: 'Status',
          type: CustomFieldType.status,
          options: 'Active, In Repair, Retired',
          isRequired: true,
        ),
      );
    }

    _displayNameController.addListener(_onDisplayNameChanged);
  }

  void _onDisplayNameChanged() {
    if (!_manualListNameEdited && widget.existingSchema == null) {
      final slug = _displayNameController.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
      _listNameController.text = slug;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _listNameController.dispose();
    _descController.dispose();
    for (final f in _fieldDrafts) {
      f.dispose();
    }
    super.dispose();
  }

  void _addField() {
    setState(() {
      _fieldDrafts.add(_FieldItemState(label: ''));
    });
  }

  void _removeField(int index) {
    if (_fieldDrafts.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one column is required.')),
      );
      return;
    }
    setState(() {
      _fieldDrafts[index].dispose();
      _fieldDrafts.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fieldDrafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one column/field.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final listName = _listNameController.text.trim().toLowerCase().replaceAll(' ', '_');
      final displayName = _displayNameController.text.trim();
      final description = _descController.text.trim();

      final fields = <CustomFieldDefinition>[];
      final seenNames = <String>{};

      for (int i = 0; i < _fieldDrafts.length; i++) {
        final draft = _fieldDrafts[i];
        final label = draft.labelController.text.trim();
        var keyName = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
        if (keyName.isEmpty) keyName = 'col_${i + 1}';

        // Ensure key is unique
        String uniqueKey = keyName;
        int counter = 1;
        while (seenNames.contains(uniqueKey)) {
          uniqueKey = '${keyName}_$counter';
          counter++;
        }
        seenNames.add(uniqueKey);

        List<String> options = [];
        if (draft.type == CustomFieldType.status) {
          options = draft.optionsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (options.isEmpty) {
            options = ['Active', 'Pending', 'Inactive'];
          }
        }

        fields.add(
          CustomFieldDefinition(
            name: uniqueKey,
            label: label,
            type: draft.type,
            options: options,
            isRequired: draft.isRequired,
          ),
        );
      }

      final schema = CustomListSchema(
        id: listName,
        listName: listName,
        displayName: displayName,
        description: description,
        iconName: _selectedIcon,
        fields: fields,
      );

      await MasterDataService.instance.saveCustomListSchema(schema);

      if (mounted) {
        Navigator.of(context).pop(schema);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Custom List "$displayName" saved successfully!'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving custom list: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingSchema != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenWidth < 500;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: screenHeight * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                      child: const Icon(Icons.playlist_add_rounded, color: Color(0xFF2563EB), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Custom List Schema' : 'Create Dynamic Custom List',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Define runtime collection metadata and dynamic fields',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display Name
                        TextFormField(
                          controller: _displayNameController,
                          decoration: InputDecoration(
                            labelText: 'List Display Name *',
                            hintText: 'e.g. Machinery & Equipment, Chemical Inventory',
                            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'List display name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // System Collection Identifier
                        TextFormField(
                          controller: _listNameController,
                          enabled: !isEditing,
                          onChanged: (_) => _manualListNameEdited = true,
                          decoration: InputDecoration(
                            labelText: 'Firestore Collection ID (Unique Slug) *',
                            hintText: 'e.g. machinery_equipment',
                            prefixIcon: const Icon(Icons.code_rounded, size: 20),
                            helperText: isEditing
                                ? 'Collection identifier is immutable'
                                : 'Stores data under /custom_lists_data_{slug}',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: isEditing ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Collection ID is required';
                            }
                            if (!RegExp(r'^[a-z0-9_]+$').hasMatch(val.trim())) {
                              return 'Only lowercase letters, numbers, and underscores';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Description
                        TextFormField(
                          controller: _descController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Scope / Description (Optional)',
                            hintText: 'Purpose of this register (e.g. tracking physical tools at sites)',
                            prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Icon Selector
                        const Text(
                          'Category Icon',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _iconChoices.map((choice) {
                              final isSelected = _selectedIcon == choice['name'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedIcon = choice['name'] as String);
                                    }
                                  },
                                  avatar: Icon(
                                    choice['icon'] as IconData,
                                    size: 18,
                                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                                  ),
                                  label: Text(choice['label'] as String),
                                  selectedColor: const Color(0xFF2563EB),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : const Color(0xFF334155),
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Field / Column Schema Definition Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Columns / Fields Schema',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                                Text(
                                  '${_fieldDrafts.length} fields configured for this register',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: _addField,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Column'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Dynamic Field Cards (Responsive)
                        ...List.generate(_fieldDrafts.length, (index) {
                          final draft = _fieldDrafts[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isCompact) ...[
                                  // Compact layout: Label on top row with delete button
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 11,
                                        backgroundColor: const Color(0xFFE2E8F0),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          controller: draft.labelController,
                                          decoration: InputDecoration(
                                            labelText: 'Column Label *',
                                            hintText: 'e.g. Asset Tag',
                                            isDense: true,
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) {
                                              return 'Column label required';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                                        tooltip: 'Remove Column',
                                        onPressed: () => _removeField(index),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<CustomFieldType>(
                                    initialValue: draft.type,
                                    decoration: InputDecoration(
                                      labelText: 'Data Type',
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    items: CustomFieldType.values.map((t) {
                                      return DropdownMenuItem(
                                        value: t,
                                        child: Text(t.label, style: const TextStyle(fontSize: 12)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => draft.type = val);
                                      }
                                    },
                                  ),
                                ] else ...[
                                  // Wider layout: Side by side
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: const Color(0xFFE2E8F0),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 3,
                                        child: TextFormField(
                                          controller: draft.labelController,
                                          decoration: InputDecoration(
                                            labelText: 'Column Label *',
                                            hintText: 'e.g. Asset Tag, Model',
                                            isDense: true,
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) {
                                              return 'Column label required';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 2,
                                        child: DropdownButtonFormField<CustomFieldType>(
                                          initialValue: draft.type,
                                          decoration: InputDecoration(
                                            labelText: 'Data Type',
                                            isDense: true,
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          items: CustomFieldType.values.map((t) {
                                            return DropdownMenuItem(
                                              value: t,
                                              child: Text(t.label, style: const TextStyle(fontSize: 12)),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => draft.type = val);
                                            }
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                                        tooltip: 'Remove Column',
                                        onPressed: () => _removeField(index),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),

                                // If type == status, show dropdown options textfield
                                if (draft.type == CustomFieldType.status) ...[
                                  TextFormField(
                                    controller: draft.optionsController,
                                    decoration: InputDecoration(
                                      labelText: 'Dropdown Options (comma-separated) *',
                                      hintText: 'e.g. Active, In Repair, Retired, Standby',
                                      helperText: 'Enter options separated by comma',
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    validator: (val) {
                                      if (draft.type == CustomFieldType.status && (val == null || val.trim().isEmpty)) {
                                        return 'Provide at least 2 dropdown options';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                ],

                                // Is Required switch
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: draft.isRequired,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        onChanged: (val) {
                                          setState(() => draft.isRequired = val ?? false);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Mandatory field (required to fill)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons
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
                        isEditing ? 'Save Schema' : 'Create Custom List',
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

