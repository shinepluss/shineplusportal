import 'package:flutter/material.dart';
import '../models/quotation_model.dart';
import '../services/quotation_service.dart';

/// Displays a safety confirmation dialog before permanently deleting a quotation.
Future<bool?> showDeleteConfirmationDialog({
  required BuildContext context,
  required Quotation quotation,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_forever_rounded,
            color: Colors.red,
            size: 32,
          ),
        ),
        title: const Text(
          'Delete Quotation?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to permanently delete quotation ${quotation.id} for "${quotation.clientName}"?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Amount: ${QuotationService.formatCurrency(quotation.amount)} • Date: ${QuotationService.formatDate(quotation.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}
