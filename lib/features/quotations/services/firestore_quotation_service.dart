import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/firebase/firebase_service.dart';
import '../../../quotations/models/quotation_draft.dart';

/// Cloud Firestore Persistence Service for Quotations and Draft Revisions.
///
/// Implements the enterprise schema:
/// - Root collection: `quotations/`
///   Document ID: `[location]_[month]_[invoice_num]` (e.g., `LHR_SEP_354`)
///   Fields: `quote_number`, `client_name`, `organization`, `date`, `grand_total`,
///           `current_revision`, `created_at`, `updated_at`.
/// - Subcollection: `draft_revisions/`
///   Document ID: `rev_1`, `rev_2`, etc.
///   Contains immutable full snapshots of line items, payment terms, and banking instructions.
class FirestoreQuotationService {
  static final FirestoreQuotationService instance = FirestoreQuotationService._internal();
  FirestoreQuotationService._internal();

  final FirebaseService _firebaseService = FirebaseService.instance;

  /// Saves or updates a quotation root document and creates an immutable draft revision snapshot
  Future<bool> saveQuotationAndRevision(QuotationDraft draft) async {
    final firestore = _firebaseService.firestore;
    if (firestore == null) {
      debugPrint('[FirestoreQuotationService] Firestore offline, saved to local cache only.');
      return false;
    }

    try {
      final loc = draft.header.locationCode.trim().toUpperCase();
      final mon = draft.header.monthCode.trim().toUpperCase();
      final invNum = draft.header.invoiceNumber;
      final revNum = draft.header.draftRevision;

      final docId = FirebaseService.formatQuotationDocId(
        location: loc,
        month: mon,
        invoiceNum: invNum,
      );

      final quotationRef = firestore.collection('quotations').doc(docId);
      final revisionRef = quotationRef.collection('draft_revisions').doc(
            FirebaseService.formatRevisionDocId(revNum),
          );

      final batch = firestore.batch();

      // Root Quotation Document
      final rootData = {
        'quote_number': draft.header.quoteNumber,
        'client_name': draft.client.name,
        'organization': draft.client.organization,
        'date': draft.header.date.toIso8601String(),
        'grand_total': draft.grandTotal,
        'current_revision': revNum,
        'updated_at': FieldValue.serverTimestamp(),
      };

      batch.set(
        quotationRef,
        {
          ...rootData,
          'created_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Subcollection draft_revisions document (Immutable JSON Snapshot)
      final revisionData = {
        'revision_number': revNum,
        'quote_number': draft.header.quoteNumber,
        'date': draft.header.date.toIso8601String(),
        'grand_total': draft.grandTotal,
        'snapshot_json': draft.toMap(),
        'line_items': draft.lineItems.map((item) => item.toMap()).toList(),
        'payment_milestones': draft.paymentMilestones.map((m) => m.toMap()).toList(),
        'banking_instructions': draft.bankingInstructions.toMap(),
        'signatory': draft.signatory.toMap(),
        'client': draft.client.toMap(),
        'created_at': FieldValue.serverTimestamp(),
      };

      batch.set(revisionRef, revisionData);

      await batch.commit();
      debugPrint('[FirestoreQuotationService] Successfully saved $docId / rev_$revNum to Cloud Firestore.');
      return true;
    } catch (e) {
      debugPrint('[FirestoreQuotationService] Error saving quotation to Firestore: $e');
      return false;
    }
  }

  /// Deletes a quotation and its subcollection revisions
  Future<bool> deleteQuotation(String location, String month, int invoiceNum) async {
    final firestore = _firebaseService.firestore;
    if (firestore == null) return false;

    try {
      final docId = FirebaseService.formatQuotationDocId(
        location: location,
        month: month,
        invoiceNum: invoiceNum,
      );

      final quotationRef = firestore.collection('quotations').doc(docId);

      // Delete revision documents
      final revisionsSnapshot = await quotationRef.collection('draft_revisions').get();
      final batch = firestore.batch();
      for (final doc in revisionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(quotationRef);
      await batch.commit();

      debugPrint('[FirestoreQuotationService] Deleted $docId from Firestore.');
      return true;
    } catch (e) {
      debugPrint('[FirestoreQuotationService] Error deleting quotation: $e');
      return false;
    }
  }

  /// Stream of root quotations in real-time
  Stream<QuerySnapshot<Map<String, dynamic>>>? streamQuotations() {
    return _firebaseService.quotationsCollection
        ?.orderBy('updated_at', descending: true)
        .snapshots();
  }

  /// Fetches all revisions for a specific quotation doc ID
  Future<List<QuotationDraft>> fetchRevisionsForQuotation(String docId) async {
    final firestore = _firebaseService.firestore;
    if (firestore == null) return [];

    try {
      final snapshots = await firestore
          .collection('quotations')
          .doc(docId)
          .collection('draft_revisions')
          .orderBy('revision_number', descending: false)
          .get();

      final drafts = <QuotationDraft>[];
      for (final doc in snapshots.docs) {
        final data = doc.data();
        if (data.containsKey('snapshot_json') && data['snapshot_json'] is Map<String, dynamic>) {
          drafts.add(QuotationDraft.fromMap(data['snapshot_json'] as Map<String, dynamic>));
        }
      }
      return drafts;
    } catch (e) {
      debugPrint('[FirestoreQuotationService] Error fetching revisions: $e');
      return [];
    }
  }
}
