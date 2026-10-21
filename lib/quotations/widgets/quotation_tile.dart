import 'package:flutter/material.dart';
import '../models/quotation_chain.dart';
import '../services/pdf_generator_service.dart';

/// Interactive quotation card tile used in the Quotations Dashboard.
///
/// Features:
/// - Client Name (Heading, 16px bold)
/// - Subheading: Creation Date and Client Organization
/// - Right-aligned Quote Number pill badge (e.g. LHR/SEP/354-4)
/// - Revision indicator (e.g. 4 Revisions)
/// - Highlighted Grand Total
/// - Conditional red delete button when Delete Mode is active
class QuotationTile extends StatelessWidget {
  final QuotationChain chain;
  final bool isDeleteMode;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const QuotationTile({
    super.key,
    required this.chain,
    required this.isDeleteMode,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = chain.activeDraft;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Leading avatar, Client Name, and Quote Number Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading Document Icon Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.description_rounded,
                        color: Color(0xFF2563EB),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Heading: Client Name & Organization
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chain.clientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          chain.organization,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Trailing: Right-Aligned Quote Number Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                    ),
                    child: Text(
                      chain.quoteNumber,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // Bottom Row: Date, Version badge, Amount & Delete Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Creation Date & Revisions
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatDate(chain.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Revisions Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${chain.revisionCount} Rev${chain.revisionCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Grand Total & Delete Button
                  Row(
                    children: [
                      Text(
                        '${active.currency} ${PdfGeneratorService.formatAmount(chain.grandTotal)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (isDeleteMode) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          onPressed: onDelete,
                          tooltip: 'Delete Quotation',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
