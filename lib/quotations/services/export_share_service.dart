import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/quotation_draft.dart';
import 'pdf_generator_service.dart';

/// Multi-Channel Export and Sharing Service
class ExportShareService {
  /// Print or Open System Print Preview
  static Future<void> printOrPreview(QuotationDraft draft) async {
    final pdfBytes = await PdfGeneratorService.generateQuotationPdf(draft);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: draft.header.safeFilename,
    );
  }

  /// Download and save PDF to device storage
  static Future<String> downloadPdf(QuotationDraft draft) async {
    final pdfBytes = await PdfGeneratorService.generateQuotationPdf(draft);
    Directory? directory;

    try {
      directory = await getDownloadsDirectory();
    } catch (_) {
      directory = null;
    }

    directory ??= await getApplicationDocumentsDirectory();

    final filePath = '${directory.path}/${draft.header.safeFilename}';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes, flush: true);
    return filePath;
  }

  /// Generate temporary PDF file for sharing
  static Future<File> _createTempPdfFile(QuotationDraft draft) async {
    final pdfBytes = await PdfGeneratorService.generateQuotationPdf(draft);
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/${draft.header.safeFilename}';
    final file = File(tempFilePath);
    await file.writeAsBytes(pdfBytes, flush: true);
    return file;
  }

  /// Share Quotation PDF to WhatsApp with pre-filled message
  static Future<void> shareToWhatsApp({
    required BuildContext context,
    required QuotationDraft draft,
  }) async {
    final file = await _createTempPdfFile(draft);
    final message =
        'Dear ${draft.client.name}, Please find attached Quotation ${draft.header.quoteNumber} for ${draft.subject} from ${draft.header.companyName}.';

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        text: message,
        subject: 'Quotation ${draft.header.quoteNumber}',
      ),
    );
  }

  /// Corporate Email Cover Letter text
  static String generateEmailBody(QuotationDraft draft) {
    return '''Dear ${draft.client.name},

Please find attached the formal quotation ${draft.header.quoteNumber} regarding "${draft.subject}" from ${draft.header.companyName} (${draft.header.companyTagline}).

Commercial Summary:
• Grand Total: ${draft.currency} ${PdfGeneratorService.formatAmount(draft.grandTotal)}
• Commercial Conditions: ${draft.taxNote}

Payment Milestones:
${draft.paymentMilestones.map((m) => '• ${m.stage} (${m.percentage.toStringAsFixed(0)}%): ${m.terms}').join('\n')}

Bank Coordinates:
• Beneficiary: ${draft.bankingInstructions.beneficiaryName}
• Bank: ${draft.bankingInstructions.bankName}
• Account: ${draft.bankingInstructions.accountNumber}

Please let us know if you require any clarifications or additional terms.

${draft.signatory.signOff}
${draft.signatory.name}
${draft.signatory.designation}
${draft.header.companyName}
''';
  }

  /// Share to Email (Zoho, Gmail, Outlook, or System Default) with attached PDF
  static Future<void> shareToEmail({
    required BuildContext context,
    required QuotationDraft draft,
    String? emailAppPackage,
  }) async {
    final file = await _createTempPdfFile(draft);
    final subject = 'Quotation: ${draft.header.quoteNumber} - ${draft.subject}';
    final body = generateEmailBody(draft);

    // If specific email package is targeted (Android)
    if (emailAppPackage != null && Platform.isAndroid) {
      final mailtoUri = Uri(
        scheme: 'mailto',
        path: '',
        queryParameters: {
          'subject': subject,
          'body': body,
        },
      );

      try {
        if (await canLaunchUrl(mailtoUri)) {
          await launchUrl(mailtoUri);
          return;
        }
      } catch (_) {
        // Fallback to share sheet
      }
    }

    // Share with attached PDF and pre-filled email metadata
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: subject,
        text: body,
      ),
    );
  }
}
