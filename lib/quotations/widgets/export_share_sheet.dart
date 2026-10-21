import 'package:flutter/material.dart';
import '../models/quotation_draft.dart';
import '../services/export_share_service.dart';

/// Opens the Multi-Channel Export and Sharing Bottom Sheet
void showExportShareSheet({
  required BuildContext context,
  required QuotationDraft draft,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Export & Multi-Channel Share',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Draft: ${draft.header.quoteNumber} (PDF Ready)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),

              // Option 1: Print & System Preview
              _buildShareOption(
                icon: Icons.print_rounded,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                title: 'Print / System PDF Preview',
                subtitle: 'Native Android print manager or save as PDF',
                onTap: () {
                  Navigator.pop(sheetContext);
                  ExportShareService.printOrPreview(draft);
                },
              ),

              // Option 2: Download PDF directly to device
              _buildShareOption(
                icon: Icons.download_rounded,
                iconColor: const Color(0xFF059669),
                bgColor: const Color(0xFFECFDF5),
                title: 'Download PDF to Device',
                subtitle: 'Saves as ${draft.header.safeFilename} to storage',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    final path = await ExportShareService.downloadPdf(draft);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF059669),
                          content: Text('Saved: ${draft.header.safeFilename}'),
                          action: SnackBarAction(
                            label: 'Details',
                            textColor: Colors.white,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Saved to: $path')),
                              );
                            },
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save PDF: $e')),
                      );
                    }
                  }
                },
              ),

              // Option 3: WhatsApp
              _buildShareOption(
                icon: Icons.chat_rounded,
                iconColor: const Color(0xFF16A34A),
                bgColor: const Color(0xFFDCFCE7),
                title: 'Share to WhatsApp',
                subtitle: 'Attach PDF with pre-filled formal message',
                onTap: () {
                  Navigator.pop(sheetContext);
                  ExportShareService.shareToWhatsApp(context: context, draft: draft);
                },
              ),

              // Option 4: Email options (Gmail, Zoho, Outlook, Universal)
              _buildShareOption(
                icon: Icons.email_rounded,
                iconColor: const Color(0xFFEA580C),
                bgColor: const Color(0xFFFFEDD5),
                title: 'Share via Email (Gmail / Zoho / Outlook)',
                subtitle: 'Attaches PDF with formal corporate cover letter',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showEmailAppPicker(context, draft);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildShareOption({
  required IconData icon,
  required Color iconColor,
  required Color bgColor,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return ListTile(
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    leading: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 24),
    ),
    title: Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
    ),
    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
  );
}

/// Email Client Picker Dialog
void _showEmailAppPicker(BuildContext context, QuotationDraft draft) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Select Email Channel',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFEE2E2),
                child: Icon(Icons.mail_rounded, color: Colors.red),
              ),
              title: const Text('Gmail', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('com.google.android.gm'),
              onTap: () {
                Navigator.pop(dialogContext);
                ExportShareService.shareToEmail(
                  context: context,
                  draft: draft,
                  emailAppPackage: 'com.google.android.gm',
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.mark_email_read_rounded, color: Colors.blue),
              ),
              title: const Text('Zoho Mail', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('com.zoho.mail'),
              onTap: () {
                Navigator.pop(dialogContext);
                ExportShareService.shareToEmail(
                  context: context,
                  draft: draft,
                  emailAppPackage: 'com.zoho.mail',
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE0F2FE),
                child: Icon(Icons.mail_outline_rounded, color: Color(0xFF0284C7)),
              ),
              title: const Text('Microsoft Outlook', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('com.microsoft.office.outlook'),
              onTap: () {
                Navigator.pop(dialogContext);
                ExportShareService.shareToEmail(
                  context: context,
                  draft: draft,
                  emailAppPackage: 'com.microsoft.office.outlook',
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF1F5F9),
                child: Icon(Icons.send_rounded, color: Color(0xFF475569)),
              ),
              title: const Text('All Email Apps / System Sheet', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Universal share sheet with attachment'),
              onTap: () {
                Navigator.pop(dialogContext);
                ExportShareService.shareToEmail(
                  context: context,
                  draft: draft,
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

