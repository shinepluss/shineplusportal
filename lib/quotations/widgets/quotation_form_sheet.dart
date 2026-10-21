import 'package:flutter/material.dart';
import '../../features/master_data/master_data.dart';
import '../models/quotation_model.dart';

/// Callback signature when user submits a quotation form
typedef OnQuotationSaveCallback = void Function(String clientName, double amount);

/// Opens a Material 3 Modal Bottom Sheet for creating or editing a quotation.
///
/// Automatically handles keyboard insets, safe area, and input validation.
void showQuotationFormBottomSheet({
  required BuildContext context,
  Quotation? quotationToEdit,
  int? nextIdNumber,
  required OnQuotationSaveCallback onSave,
}) {
  final isEditing = quotationToEdit != null;
  final nameController = TextEditingController(text: quotationToEdit?.clientName ?? '');
  final amountController = TextEditingController(
    text: quotationToEdit != null ? quotationToEdit.amount.toStringAsFixed(2) : '',
  );
  final formKey = GlobalKey<FormState>();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (bottomSheetContext) {
      final theme = Theme.of(bottomSheetContext);
      final keyboardInset = MediaQuery.of(bottomSheetContext).viewInsets.bottom;

      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: keyboardInset + 24,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                          color: theme.colorScheme.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Quotation' : 'New Quotation',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              isEditing
                                  ? 'Updating ${quotationToEdit.id}'
                                  : (nextIdNumber != null
                                      ? 'Assigns unique ID (QT-$nextIdNumber)'
                                      : 'Creates new quotation'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(bottomSheetContext),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Auto-fill Client from Master Data
                  if (MasterDataService.instance.clients.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ClientModel>(
                          isExpanded: true,
                          hint: const Row(
                            children: [
                              Icon(Icons.person_search_rounded, size: 16, color: Color(0xFF2563EB)),
                              SizedBox(width: 8),
                              Text(
                                'Select Client from Master Data (Auto-fill)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                              ),
                            ],
                          ),
                          items: MasterDataService.instance.clients.map((c) {
                            return DropdownMenuItem<ClientModel>(
                              value: c,
                              child: Text(
                                '${c.contactName} (${c.organization})',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (selectedClient) {
                            if (selectedClient != null) {
                              nameController.text = '${selectedClient.contactName} (${selectedClient.organization})';
                            }
                          },
                        ),
                      ),
                    ),
                  ],

                  // Client Name Field
                  const Text(
                    'Client Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    autofocus: !isEditing,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Acme Corp / John Doe',
                      prefixIcon: Icon(Icons.business_rounded, color: Color(0xFF94A3B8)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a client name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Amount Field
                  const Text(
                    'Estimated Amount / Total',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      prefixText: '\$ ',
                      prefixStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                      prefixIcon: Icon(Icons.attach_money_rounded, color: Color(0xFF94A3B8)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an estimated amount';
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed < 0) {
                        return 'Please enter a valid positive amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(bottomSheetContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            final name = nameController.text.trim();
                            final amount = double.parse(amountController.text.trim());

                            onSave(name, amount);
                            Navigator.pop(bottomSheetContext);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(isEditing ? Icons.check_circle_outline : Icons.add_circle_outline),
                          label: Text(
                            isEditing ? 'Save Changes' : 'Create Quotation',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
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
    },
  );
}
