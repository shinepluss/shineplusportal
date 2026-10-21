import 'package:flutter/material.dart';
import '../models/quotation_model.dart';
import '../services/quotation_service.dart';

/// Reusable Card component for displaying a Quotation item in lists.
class QuotationCard extends StatelessWidget {
  final Quotation quotation;
  final bool isDeleteMode;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const QuotationCard({
    super.key,
    required this.quotation,
    required this.isDeleteMode,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading: Circular avatar representing invoice/document
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // Soft blue tint
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Title & Subtitle: Client Name & Formatted Date + Amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (Client Name - Bold 16px)
                    Text(
                      quotation.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtitle: Date formatted & estimated amount
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          QuotationService.formatDate(quotation.createdAt),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '•',
                          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          QuotationService.formatCurrency(quotation.amount),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981), // Emerald green
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Trailing Section: ID Pill Badge + Optional Red Delete Button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Distinctive Quotation ID Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      quotation.id,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Red Trash Icon (Only shown when Delete Mode is active)
                  if (isDeleteMode) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 22,
                      ),
                      tooltip: 'Delete ${quotation.id}',
                      splashRadius: 20,
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
