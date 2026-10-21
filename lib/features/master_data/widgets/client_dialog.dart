import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../services/master_data_service.dart';

/// Modal dialog for Adding or Editing Client in Master Data
class ClientDialog extends StatefulWidget {
  final ClientModel? client;

  const ClientDialog({super.key, this.client});

  static Future<ClientModel?> show(BuildContext context, {ClientModel? client}) {
    return showDialog<ClientModel>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ClientDialog(client: client),
    );
  }

  @override
  State<ClientDialog> createState() => _ClientDialogState();
}

class _ClientDialogState extends State<ClientDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _designationController;
  late TextEditingController _orgController;
  late TextEditingController _cityController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  bool get isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.contactName ?? '');
    _designationController = TextEditingController(text: widget.client?.designation ?? '');
    _orgController = TextEditingController(text: widget.client?.organization ?? '');
    _cityController = TextEditingController(text: widget.client?.city ?? 'Lahore');
    _phoneController = TextEditingController(text: widget.client?.phone ?? '');
    _emailController = TextEditingController(text: widget.client?.email ?? '');
    _addressController = TextEditingController(text: widget.client?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _orgController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.client?.id ?? 'client_${DateTime.now().millisecondsSinceEpoch}';
    final updated = ClientModel(
      id: id,
      contactName: _nameController.text.trim(),
      designation: _designationController.text.trim(),
      organization: _orgController.text.trim(),
      city: _cityController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
    );

    await MasterDataService.instance.saveClient(updated);
    if (mounted) {
      Navigator.of(context).pop(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.business_rounded, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Corporate Client' : 'Add New Corporate Client',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Person Name',
                      hintText: 'e.g. Mr. Junaid Imran',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Contact Name is required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _designationController,
                    decoration: const InputDecoration(
                      labelText: 'Designation / Title',
                      hintText: 'e.g. General Manager / Procurement Head',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Designation is required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _orgController,
                    decoration: const InputDecoration(
                      labelText: 'Organization / Company',
                      hintText: 'e.g. Circle Club, Pearl Continental Hotel',
                      prefixIcon: Icon(Icons.domain_rounded),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Organization is required' : null,
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cityField = TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          hintText: 'e.g. Faisalabad / Lahore',
                          prefixIcon: Icon(Icons.location_city_rounded),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'City is required' : null,
                      );

                      final phoneField = TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone / WhatsApp',
                          hintText: '+92 300 1234567',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      );

                      if (constraints.maxWidth < 400) {
                        return Column(
                          children: [
                            cityField,
                            const SizedBox(height: 14),
                            phoneField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: cityField),
                          const SizedBox(width: 12),
                          Expanded(child: phoneField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address (Optional)',
                      hintText: 'e.g. contact@client.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Address / Location Notes (Optional)',
                      hintText: 'e.g. Complex VIP Road, Lahore',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.place_outlined),
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
                        label: Text(isEditing ? 'Save Changes' : 'Create Client'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
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
