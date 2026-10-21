import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/master_data_service.dart';

/// Modal dialog for Adding or Editing Staff Member / User in Master Data
class UserDialog extends StatefulWidget {
  final UserModel? user;

  const UserDialog({super.key, this.user});

  static Future<UserModel?> show(BuildContext context, {UserModel? user}) {
    return showDialog<UserModel>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UserDialog(user: user),
    );
  }

  @override
  State<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _staffIdController;
  late TextEditingController _roleController;
  late TextEditingController _phoneController;
  String _status = 'Active';

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.fullName ?? '');
    _staffIdController = TextEditingController(text: widget.user?.employeeId ?? 'SP-');
    _roleController = TextEditingController(text: widget.user?.role ?? 'Floor Specialist');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');

    final rawStatus = widget.user?.status ?? 'Active';
    if (rawStatus.toLowerCase().contains('leave')) {
      _status = 'On Leave';
    } else if (rawStatus.toLowerCase().contains('inactive')) {
      _status = 'Inactive';
    } else {
      _status = 'Active';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _staffIdController.dispose();
    _roleController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.user?.id ?? 'usr_${DateTime.now().millisecondsSinceEpoch}';

    final updated = UserModel(
      id: id,
      employeeId: _staffIdController.text.trim().toUpperCase(),
      fullName: _nameController.text.trim(),
      role: _roleController.text.trim(),
      phone: _phoneController.text.trim(),
      status: _status,
    );

    await MasterDataService.instance.saveUser(updated);
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
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.badge_rounded, color: Color(0xFF7C3AED)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Staff Member' : 'Register Staff Member',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final staffIdField = TextFormField(
                        controller: _staffIdController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Staff ID / Employee Code',
                          hintText: 'e.g. SP-106',
                          prefixIcon: Icon(Icons.tag_rounded),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Staff ID is required' : null,
                      );

                      final statusField = DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.circle_rounded, size: 16),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Active', child: Text('Active')),
                          DropdownMenuItem(value: 'On Leave', child: Text('On Leave')),
                          DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      );

                      if (constraints.maxWidth < 380) {
                        return Column(
                          children: [
                            staffIdField,
                            const SizedBox(height: 14),
                            statusField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: staffIdField),
                          const SizedBox(width: 12),
                          Expanded(child: statusField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. Muhammad Aslam',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Full name is required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _roleController,
                    decoration: const InputDecoration(
                      labelText: 'Designation / Operational Role',
                      hintText: 'e.g. Floor Specialist, Field Supervisor',
                      prefixIcon: Icon(Icons.work_outline_rounded),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Designation is required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+92 300 1234567',
                      prefixIcon: Icon(Icons.phone_rounded),
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
                        label: Text(isEditing ? 'Save Changes' : 'Register Staff'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
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
