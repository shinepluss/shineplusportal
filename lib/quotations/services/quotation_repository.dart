import 'package:flutter/material.dart';
import '../../features/quotations/services/firestore_quotation_service.dart';
import '../models/quotation_chain.dart';
import '../models/quotation_draft.dart';

/// Centralized state repository for Quotation documents and multi-revision history.
///
/// Implements [ChangeNotifier] to ensure seamless, real-time synchronization
/// across Screen 1 (Home Screen), Screen 2 (Dashboard), and Screen 3 (Editor).
class QuotationRepository extends ChangeNotifier {
  /// Singleton instance
  static final QuotationRepository instance = QuotationRepository._internal();

  QuotationRepository._internal() {
    _chains = _buildDefaultChains();
  }

  late List<QuotationChain> _chains;

  /// Unmodifiable view of all quotation chains
  List<QuotationChain> get chains => List.unmodifiable(_chains);

  /// Total count of active quotation documents
  int get totalQuotationsCount => _chains.length;

  /// Cumulative financial value across all active quotations
  double get totalPipelineValue =>
      _chains.fold(0.0, (sum, chain) => sum + chain.grandTotal);

  /// Total count of stored draft revisions across all documents
  int get totalRevisionsCount =>
      _chains.fold(0, (sum, chain) => sum + chain.revisionCount);

  /// Filters and sorts quotations by client name or quotation number (e.g. LHR/SEP/354-4)
  List<QuotationChain> searchAndSort({
    required String query,
    bool newestFirst = true,
  }) {
    final cleanQuery = query.trim().toLowerCase();

    final filtered = _chains.where((chain) {
      if (cleanQuery.isEmpty) return true;
      final clientMatch = chain.clientName.toLowerCase().contains(cleanQuery);
      final orgMatch = chain.organization.toLowerCase().contains(cleanQuery);
      final quoteNumMatch = chain.quoteNumber.toLowerCase().contains(cleanQuery);
      final subjectMatch = chain.subject.toLowerCase().contains(cleanQuery);
      return clientMatch || orgMatch || quoteNumMatch || subjectMatch;
    }).toList();

    filtered.sort((a, b) {
      final comp = b.date.compareTo(a.date);
      return newestFirst ? comp : -comp;
    });

    return filtered;
  }

  /// Adds a newly created quotation document chain
  void addChain(QuotationChain chain) {
    _chains.insert(0, chain);
    notifyListeners();
    FirestoreQuotationService.instance.saveQuotationAndRevision(chain.activeDraft);
  }

  /// Updates an existing quotation document chain
  void updateChain(QuotationChain updatedChain) {
    final index = _chains.indexWhere((c) => c.id == updatedChain.id);
    if (index != -1) {
      _chains[index] = updatedChain;
      notifyListeners();
    } else {
      addChain(updatedChain);
      return;
    }
    FirestoreQuotationService.instance.saveQuotationAndRevision(updatedChain.activeDraft);
  }

  /// Deletes a quotation document chain by ID
  void deleteChain(String id) {
    final targetIndex = _chains.indexWhere((c) => c.id == id);
    if (targetIndex != -1) {
      final draft = _chains[targetIndex].activeDraft;
      FirestoreQuotationService.instance.deleteQuotation(
        draft.header.locationCode,
        draft.header.monthCode,
        draft.header.invoiceNumber,
      );
    }
    _chains.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// Generates the next sequential invoice number for a given location
  int generateNextInvoiceNumber(String locationCode) {
    int maxNum = 350;
    for (final chain in _chains) {
      for (final rev in chain.revisions) {
        if (rev.header.locationCode.toUpperCase() == locationCode.toUpperCase()) {
          if (rev.header.invoiceNumber > maxNum) {
            maxNum = rev.header.invoiceNumber;
          }
        }
      }
    }
    return maxNum + 1;
  }

  /// Resets repository to default mock dataset
  void resetToDefaults() {
    _chains = _buildDefaultChains();
    notifyListeners();
  }

  // ==========================================
  // DEFAULT CORPORATE CHAINS (MOCK DATA)
  // ==========================================

  static List<QuotationChain> _buildDefaultChains() {
    // 1. Circle Club - Mr. Junaid Imran (Full 4-revision history matching exact JSON spec)
    final sample4 = QuotationDraft.sampleDraft4();

    final draft1 = sample4.deepCopy();
    draft1.header.draftRevision = 1;
    draft1.header.date = DateTime(2026, 9, 20);
    draft1.lineItems = [
      sample4.lineItems[0].copyWith(quantity: 1500, customLineTotal: 60000),
    ];
    draft1.paymentMilestones = [
      PaymentMilestone(percentage: 50, stage: 'Advance Payment', terms: 'Due at contract signing.'),
      PaymentMilestone(percentage: 50, stage: 'Final Settlement', terms: 'Due on completion.'),
    ];

    final draft2 = sample4.deepCopy();
    draft2.header.draftRevision = 2;
    draft2.header.date = DateTime(2026, 9, 24);
    draft2.lineItems = [
      sample4.lineItems[0].copyWith(quantity: 2047, customLineTotal: 81880),
    ];

    final draft3 = sample4.deepCopy();
    draft3.header.draftRevision = 3;
    draft3.header.date = DateTime(2026, 9, 28);
    draft3.lineItems = List.from(sample4.lineItems);

    final chainCircleClub = QuotationChain(
      id: 'LHR-SEP-354',
      revisions: [draft1, draft2, draft3, sample4],
      activeIndex: 3, // Point to Draft 4
    );

    // 2. Pearl Continental Hotel (PC)
    final chainPC = QuotationChain(
      id: 'LHR-SEP-355',
      revisions: [
        QuotationDraft(
          header: QuotationHeader(
            companyName: 'Shine Plus (Private) Limited',
            companyTagline: 'A Startup Established by Hashoo Foundation',
            locationCode: 'LHR',
            monthCode: 'SEP',
            invoiceNumber: 355,
            draftRevision: 1,
            date: DateTime(2026, 9, 22),
          ),
          client: ClientInfo(
            name: 'Mr. Tariq Mehmood',
            designation: 'General Manager',
            organization: 'Pearl Continental Hotel (PC)',
            city: 'Lahore',
          ),
          subject: 'Quotation for "Lobby Marble Crystallization & Repolishing"',
          salutation: 'Dear Mr. Tariq,',
          introText: sample4.introText,
          currency: 'PKR',
          lineItems: [
            QuotationLineItem(
              srNo: 1,
              description: 'Italian Marble Diamond Grinding & Mirror Polish',
              unit: 'Sq. Ft.',
              companyRate: 65,
              discountedRate: 55,
              quantity: 8000,
              customLineTotal: 440000,
            ),
            QuotationLineItem(
              srNo: 2,
              description: 'Brass & Stainless Steel Railings Buffing & Sealing',
              unit: 'Rft.',
              companyRate: 350,
              discountedRate: 300,
              quantity: 200,
              customLineTotal: 60000,
            ),
          ],
          taxNote: 'All rates are inclusive of prevailing federal and provincial taxes.',
          paymentMilestones: [
            PaymentMilestone(percentage: 50, stage: 'Advance Payment', terms: 'Due upon signing.'),
            PaymentMilestone(percentage: 50, stage: 'Final Payment', terms: 'Upon satisfactory inspection.'),
          ],
          bankingInstructions: sample4.bankingInstructions,
          signatory: sample4.signatory,
        ),
        QuotationDraft(
          header: QuotationHeader(
            companyName: 'Shine Plus (Private) Limited',
            companyTagline: 'A Startup Established by Hashoo Foundation',
            locationCode: 'LHR',
            monthCode: 'SEP',
            invoiceNumber: 355,
            draftRevision: 2,
            date: DateTime(2026, 9, 29),
          ),
          client: ClientInfo(
            name: 'Mr. Tariq Mehmood',
            designation: 'General Manager',
            organization: 'Pearl Continental Hotel (PC)',
            city: 'Lahore',
          ),
          subject: 'Quotation for "Lobby Marble Crystallization & Repolishing"',
          salutation: 'Dear Mr. Tariq,',
          introText: sample4.introText,
          currency: 'PKR',
          lineItems: [
            QuotationLineItem(
              srNo: 1,
              description: 'Italian Marble Diamond Grinding & Mirror Polish',
              unit: 'Sq. Ft.',
              companyRate: 65,
              discountedRate: 55,
              quantity: 8000,
              customLineTotal: 440000,
            ),
            QuotationLineItem(
              srNo: 2,
              description: 'Brass & Stainless Steel Railings Buffing & Sealing',
              unit: 'Rft.',
              companyRate: 350,
              discountedRate: 300,
              quantity: 200,
              customLineTotal: 60000,
            ),
            QuotationLineItem(
              srNo: 3,
              description: 'High-Touch Surface Sanitization & Fumigation',
              unit: 'Lobby Area',
              companyRate: 25000,
              discountedRate: 20000,
              quantity: 1,
              customLineTotal: 20000,
            ),
          ],
          taxNote: 'The above rates are inclusive of all taxes.',
          paymentMilestones: [
            PaymentMilestone(percentage: 40, stage: 'Advance Payment', terms: 'Due at project mobilization.'),
            PaymentMilestone(percentage: 30, stage: 'Midway Stage', terms: 'Due at 50% milestone delivery.'),
            PaymentMilestone(percentage: 30, stage: 'Final Delivery', terms: 'Upon handover.'),
          ],
          bankingInstructions: sample4.bankingInstructions,
          signatory: sample4.signatory,
        ),
      ],
      activeIndex: 1,
    );

    // 3. Islamabad Club
    final chainIslamabadClub = QuotationChain(
      id: 'ISB-SEP-102',
      revisions: [
        QuotationDraft(
          header: QuotationHeader(
            companyName: 'Shine Plus (Private) Limited',
            companyTagline: 'A Startup Established by Hashoo Foundation',
            locationCode: 'ISB',
            monthCode: 'SEP',
            invoiceNumber: 102,
            draftRevision: 1,
            date: DateTime(2026, 9, 27),
          ),
          client: ClientInfo(
            name: 'Brig. (R) Asim Malik',
            designation: 'Project Director',
            organization: 'Islamabad Club',
            city: 'Islamabad',
          ),
          subject: 'Quotation for "Clubhouse Deep Cleaning & Fumigation"',
          salutation: 'Dear Brig. Asim,',
          introText: sample4.introText,
          currency: 'PKR',
          lineItems: [
            QuotationLineItem(
              srNo: 1,
              description: 'Banquet Hall Carpet Extraction & Grout Cleaning',
              unit: 'Sq. Ft.',
              companyRate: 35,
              discountedRate: 28,
              quantity: 5000,
              customLineTotal: 140000,
            ),
            QuotationLineItem(
              srNo: 2,
              description: 'Complete Facility Fumigation & Sanitization',
              unit: 'Block',
              companyRate: 120000,
              discountedRate: 105000,
              quantity: 1,
              customLineTotal: 105000,
            ),
          ],
          taxNote: 'The above rates are inclusive of all taxes.',
          paymentMilestones: [
            PaymentMilestone(percentage: 50, stage: 'Advance Payment', terms: 'Due at start.'),
            PaymentMilestone(percentage: 50, stage: 'Completion Settlement', terms: 'Due within 7 days of invoice.'),
          ],
          bankingInstructions: sample4.bankingInstructions,
          signatory: sample4.signatory,
        ),
      ],
      activeIndex: 0,
    );

    // 4. Marriott Hotel Islamabad
    final chainMarriott = QuotationChain(
      id: 'ISB-AUG-089',
      revisions: [
        QuotationDraft(
          header: QuotationHeader(
            companyName: 'Shine Plus (Private) Limited',
            companyTagline: 'A Startup Established by Hashoo Foundation',
            locationCode: 'ISB',
            monthCode: 'AUG',
            invoiceNumber: 89,
            draftRevision: 3,
            date: DateTime(2026, 8, 30),
          ),
          client: ClientInfo(
            name: 'Eng. Farhan Akhtar',
            designation: 'Director Facilities',
            organization: 'Marriott Hotel',
            city: 'Islamabad',
          ),
          subject: 'Quotation for "Exterior Glass Facade Cleaning & Grouting"',
          salutation: 'Dear Eng. Farhan,',
          introText: sample4.introText,
          currency: 'PKR',
          lineItems: [
            QuotationLineItem(
              srNo: 1,
              description: 'High-Rise Spider Kit Glass Cleaning & Spot Removal',
              unit: 'Sq. Ft.',
              companyRate: 25,
              discountedRate: 20,
              quantity: 16000,
              customLineTotal: 320000,
            ),
            QuotationLineItem(
              srNo: 2,
              description: 'Silicone Weather Sealing & Joint Grouting',
              unit: 'Running Mtr',
              companyRate: 200,
              discountedRate: 180,
              quantity: 500,
              customLineTotal: 90000,
            ),
          ],
          taxNote: 'The above rates are inclusive of all taxes.',
          paymentMilestones: [
            PaymentMilestone(percentage: 50, stage: 'Mobilization', terms: 'Advance upon signing.'),
            PaymentMilestone(percentage: 25, stage: 'Progress', terms: '50% completion inspection.'),
            PaymentMilestone(percentage: 25, stage: 'Handover', terms: 'Final sign-off.'),
          ],
          bankingInstructions: sample4.bankingInstructions,
          signatory: sample4.signatory,
        ),
      ],
      activeIndex: 0,
    );

    // 5. Hotel One Faisalabad
    final chainHotelOne = QuotationChain(
      id: 'FSD-AUG-044',
      revisions: [
        QuotationDraft(
          header: QuotationHeader(
            companyName: 'Shine Plus (Private) Limited',
            companyTagline: 'A Startup Established by Hashoo Foundation',
            locationCode: 'FSD',
            monthCode: 'AUG',
            invoiceNumber: 44,
            draftRevision: 1,
            date: DateTime(2026, 8, 15),
          ),
          client: ClientInfo(
            name: 'Ms. Sana Tariq',
            designation: 'Operations Lead',
            organization: 'Hotel One',
            city: 'Faisalabad',
          ),
          subject: 'Quotation for "Kitchen Deep Degreasing & Washroom Grouting"',
          salutation: 'Dear Ms. Sana,',
          introText: sample4.introText,
          currency: 'PKR',
          lineItems: [
            QuotationLineItem(
              srNo: 1,
              description: 'Commercial Kitchen Hood & Tile Chemical Degreasing',
              unit: 'Kitchen',
              companyRate: 120000,
              discountedRate: 100000,
              quantity: 1,
              customLineTotal: 100000,
            ),
            QuotationLineItem(
              srNo: 2,
              description: 'Guest Washrooms Epoxy Regrouting & Polishing',
              unit: 'Washroom',
              companyRate: 5000,
              discountedRate: 4000,
              quantity: 20,
              customLineTotal: 80000,
            ),
          ],
          taxNote: 'The above rates are inclusive of all taxes.',
          paymentMilestones: [
            PaymentMilestone(percentage: 60, stage: 'Advance Mobilization', terms: 'Due at start.'),
            PaymentMilestone(percentage: 40, stage: 'Final Delivery', terms: 'Due upon completion.'),
          ],
          bankingInstructions: sample4.bankingInstructions,
          signatory: sample4.signatory,
        ),
      ],
      activeIndex: 0,
    );

    return [
      chainCircleClub,
      chainPC,
      chainIslamabadClub,
      chainMarriott,
      chainHotelOne,
    ];
  }
}
