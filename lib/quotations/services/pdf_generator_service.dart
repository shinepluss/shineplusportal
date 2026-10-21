import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/quotation_draft.dart';

/// PDF Generation Service for Corporate Quotations & Invoices
class PdfGeneratorService {
  /// Helper to format currency numbers with commas
  static String formatAmount(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = intPart.replaceAllMapped(regExp, (m) => '${m[1]},');
    return decPart == '00' ? formatted : '$formatted.$decPart';
  }

  /// Helper to format dates (YYYY-MM-DD)
  static String formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Generates a high-quality PDF document Uint8List bytes
  static Future<Uint8List> generateQuotationPdf(QuotationDraft draft) async {
    final pdf = pw.Document();

    final primaryBlue = PdfColor.fromHex('#1E3A8A');
    final textDark = PdfColor.fromHex('#0F172A');
    final textMuted = PdfColor.fromHex('#475569');
    final borderGray = PdfColor.fromHex('#CBD5E1');
    final headerBg = PdfColor.fromHex('#F1F5F9');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${draft.header.companyName} • ${draft.header.quoteNumber}',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                ),
              ],
            ),
          );
        },
        build: (context) => [
          // --- HEADER SECTION ---
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    draft.header.companyName.toUpperCase(),
                    style: pw.TextStyle(
                      color: primaryBlue,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    draft.header.companyTagline,
                    style: pw.TextStyle(
                      color: textMuted,
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: primaryBlue,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      draft.header.quoteNumber,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Date: ${formatDate(draft.header.date)}',
                    style: pw.TextStyle(color: textDark, fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: primaryBlue, thickness: 1.5),
          pw.SizedBox(height: 8),

          // --- RECIPIENT / CLIENT BLOCK ---
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: headerBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: borderGray, width: 0.5),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'QUOTATION TO:',
                        style: pw.TextStyle(
                          color: primaryBlue,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        draft.client.name,
                        style: pw.TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (draft.client.designation.isNotEmpty)
                        pw.Text(
                          draft.client.designation,
                          style: pw.TextStyle(color: textMuted, fontSize: 9),
                        ),
                      pw.Text(
                        '${draft.client.organization}, ${draft.client.city}',
                        style: pw.TextStyle(
                          color: textDark,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // --- SUBJECT & SALUTATION ---
          pw.Text(
            'Subject: ${draft.subject}',
            style: pw.TextStyle(
              color: textDark,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            draft.salutation,
            style: pw.TextStyle(color: textDark, fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            draft.introText,
            style: pw.TextStyle(color: textMuted, fontSize: 8.5, lineSpacing: 2),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 12),

          // --- LINE ITEMS TABLE ---
          pw.Text(
            'SCOPE OF SERVICES & COST BREAKDOWN',
            style: pw.TextStyle(
              color: primaryBlue,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 4),

          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: borderGray, width: 0.5),
            headerStyle: pw.TextStyle(
              color: primaryBlue,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: pw.BoxDecoration(color: headerBg),
            headerHeight: 22,
            cellHeight: 20,
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
            },
            headers: [
              'Sr#',
              'Description of Work',
              'Unit',
              'Std Rate (${draft.currency})',
              'Offered (${draft.currency})',
              'Qty',
              'Total (${draft.currency})'
            ],
            data: draft.lineItems.map((item) {
              return [
                '${item.srNo}',
                item.description,
                item.unit,
                formatAmount(item.companyRate),
                formatAmount(item.discountedRate),
                formatAmount(item.quantity),
                formatAmount(item.lineTotal),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 6),

          // --- TOTAL & TAX NOTE ---
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Note: ${draft.taxNote}',
                  style: pw.TextStyle(color: textMuted, fontSize: 8, fontStyle: pw.FontStyle.italic),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: primaryBlue,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      'GRAND TOTAL:  ',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '${draft.currency} ${formatAmount(draft.grandTotal)}',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // --- PAYMENT MILESTONES ---
          pw.Text(
            'PAYMENT MILESTONES & TERMS',
            style: pw.TextStyle(
              color: primaryBlue,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 4),

          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: borderGray, width: 0.5),
            headerStyle: pw.TextStyle(color: primaryBlue, fontSize: 8, fontWeight: pw.FontWeight.bold),
            headerDecoration: pw.BoxDecoration(color: headerBg),
            headerHeight: 20,
            cellHeight: 18,
            cellStyle: const pw.TextStyle(fontSize: 8),
            headers: ['Stage', 'Percentage', 'Commercial Conditions'],
            data: draft.paymentMilestones.map((m) {
              return [
                m.stage,
                '${m.percentage.toStringAsFixed(0)}%',
                m.terms,
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 14),

          // --- BANKING INSTRUCTIONS ---
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: headerBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: borderGray, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BANKING DETAILS FOR WIRE TRANSFER / CHEQUES',
                  style: pw.TextStyle(color: primaryBlue, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text(
                      'Beneficiary Name: ',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textDark),
                    ),
                    pw.Text(draft.bankingInstructions.beneficiaryName, style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(width: 14),
                    pw.Text(
                      'Bank: ',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textDark),
                    ),
                    pw.Text(draft.bankingInstructions.bankName, style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(width: 14),
                    pw.Text(
                      'Account #: ',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textDark),
                    ),
                    pw.Text(
                      draft.bankingInstructions.accountNumber,
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text('Acceptable Payment Modes:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ...draft.bankingInstructions.paymentModes.map(
                  (mode) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8, top: 1),
                    child: pw.Text('• $mode', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // --- SIGNATORY BLOCK ---
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    draft.signatory.signOff,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.SizedBox(height: 24), // Signature gap
                  pw.Text(
                    draft.signatory.name,
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark),
                  ),
                  pw.Text(
                    draft.signatory.designation,
                    style: pw.TextStyle(fontSize: 8.5, color: textMuted),
                  ),
                  pw.Text(
                    draft.header.companyName,
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: primaryBlue),
                  ),
                ],
              ),
              pw.Container(
                width: 100,
                height: 50,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderGray, style: pw.BorderStyle.dashed),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Official Stamp / Signature',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }
}

