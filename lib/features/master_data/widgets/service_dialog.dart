import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../services/master_data_service.dart';

/// Modal dialog for Adding or Editing Service in Master Data
class ServiceDialog extends StatefulWidget {
  final ServiceModel? service;

  const ServiceDialog({super.key, this.service});

  static Future<ServiceModel?> show(BuildContext context, {ServiceModel? service}) {
    return showDialog<ServiceModel>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ServiceDialog(service: service),
    );
  }

  @override
  State<ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<ServiceDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _unitController;
  late TextEditingController _rateController;
  late TextEditingController _descController;

  final List<String> _suggestedUnits = [
    'Sq. Ft.',
    'Washroom',
    'Kitchen Unit',
    'Room',
    'Job / Lump Sum',
    'Hour',
    'Day',
  ];

  bool get isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.service?.title ?? '');
    _unitController = TextEditingController(text: widget.service?.defaultUnit ?? 'Sq. Ft.');
    _rateController = TextEditingController(
      text: widget.service != null ? widget.service!.standardCompanyRate.toString() : '',
    );
    _descController = TextEditingController(text: widget.service?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _unitController.dispose();
    _rateController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.service?.id ?? 'svc_${DateTime.now().millisecondsSinceEpoch}';
    final rate = double.tryParse(_rateController.text.trim()) ?? 0.0;

    final updated = ServiceModel(
      id: id,
      title: _titleController.text.trim(),
      defaultUnit: _unitController.text.trim(),
      standardCompanyRate: rate,
      description: _descController.text.trim(),
    );

    await MasterDataService.instance.saveService(updated);
    if (mounted) {
      Navigator.of(context).pop(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cleaning_services_rounded, color: Color(0xFF059669)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Service & Rate' : 'Add Catalog Service',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Service Title',
                      hintText: 'e.g. Marble Cutting, Gridding & Polishing- Mosques',
                      prefixIcon: Icon(Icons.cleaning_services_outlined),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Service title is required' : null,
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final unitField = TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Default Unit',
                          hintText: 'e.g. Sq. Ft., Washroom',
                          prefixIcon: Icon(Icons.straighten_rounded),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Unit is required' : null,
                      );

                      final rateField = TextFormField(
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Standard Rate (PKR)',
                          hintText: 'e.g. 40.0',
                          prefixText: 'PKR ',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Rate is required';
                          if (double.tryParse(val) == null) return 'Valid number required';
                          return null;
                        },
                      );

                      if (constraints.maxWidth < 400) {
                        return Column(
                          children: [
                            unitField,
                            const SizedBox(height: 14),
                            rateField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: unitField),
                          const SizedBox(width: 12),
                          Expanded(child: rateField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _suggestedUnits.map((u) {
                      return ActionChip(
                        label: Text(u, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          setState(() {
                            _unitController.text = u;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description / Scope of Work',
                      hintText: 'e.g. Complete diamond pad cut, chemical crystallization and sealing.',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(isEditing ? 'Save Changes' : 'Add to Catalog'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
