import 'quotation_draft.dart';

/// Represents a Quotation Document entity with full immutable revision history.
///
/// Contains an ordered list of [QuotationDraft] snapshots:
/// e.g. Draft 1 (LHR/SEP/354-1), Draft 2 (LHR/SEP/354-2), Draft 4 (LHR/SEP/354-4).
class QuotationChain {
  /// Unique document chain identifier, e.g. "LHR-SEP-354"
  final String id;

  /// Ordered list of snapshots from Draft 1 to latest
  final List<QuotationDraft> revisions;

  /// Index of the currently active / displayed revision (defaults to latest)
  int activeIndex;

  QuotationChain({
    required this.id,
    required List<QuotationDraft> revisions,
    int? activeIndex,
  })  : revisions = revisions,
        activeIndex = activeIndex ?? (revisions.isNotEmpty ? revisions.length - 1 : 0);

  /// Active revision draft snapshot
  QuotationDraft get activeDraft {
    if (revisions.isEmpty) {
      return QuotationDraft.sampleDraft4();
    }
    final safeIndex = activeIndex.clamp(0, revisions.length - 1);
    return revisions[safeIndex];
  }

  /// Latest revision draft snapshot
  QuotationDraft get latestDraft => revisions.last;

  /// Client name of the active revision
  String get clientName => activeDraft.client.name;

  /// Client organization of the active revision
  String get organization => activeDraft.client.organization;

  /// Formatted quote number of the active revision, e.g. "LHR/SEP/354-4"
  String get quoteNumber => activeDraft.header.quoteNumber;

  /// Creation date of the active revision
  DateTime get date => activeDraft.header.date;

  /// Total amount of the active revision
  double get grandTotal => activeDraft.grandTotal;

  /// Currency code of the active revision
  String get currency => activeDraft.currency;

  /// Number of historical revisions stored
  int get revisionCount => revisions.length;

  /// Subject of the proposal
  String get subject => activeDraft.subject;

  /// Deep copy of the quotation chain
  QuotationChain deepCopy() {
    return QuotationChain(
      id: id,
      revisions: revisions.map((r) => r.deepCopy()).toList(),
      activeIndex: activeIndex,
    );
  }

  /// Creates a copy with optional parameter overrides
  QuotationChain copyWith({
    String? id,
    List<QuotationDraft>? revisions,
    int? activeIndex,
  }) {
    return QuotationChain(
      id: id ?? this.id,
      revisions: revisions ?? this.revisions,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }

  /// Appends a new revision snapshot (auto-increments revision suffix)
  QuotationDraft addNewRevision(QuotationDraft draft) {
    final nextRevNumber = revisions.isNotEmpty
        ? revisions.map((r) => r.header.draftRevision).reduce((a, b) => a > b ? a : b) + 1
        : 1;

    final newSnapshot = draft.deepCopy();
    newSnapshot.header.draftRevision = nextRevNumber;
    newSnapshot.header.date = DateTime.now();

    revisions.add(newSnapshot);
    activeIndex = revisions.length - 1;
    return newSnapshot;
  }

  /// Updates the active revision in-place
  void updateActiveRevision(QuotationDraft updated) {
    if (revisions.isNotEmpty && activeIndex < revisions.length) {
      revisions[activeIndex] = updated.deepCopy();
    }
  }
}
