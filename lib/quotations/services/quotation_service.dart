import '../models/quotation_model.dart';

/// Service and Business Logic layer for Quotations.
///
/// Encapsulates all data operations, filtering, sorting, ID generation,
/// and display formatting. Can be used as a standalone helper or injected
/// into state management solutions (Provider, Riverpod, Bloc, etc.).
class QuotationService {
  int _nextIdCounter = 1006;

  /// Generate the next unique Quotation ID (e.g. QT-1006)
  String generateNextId() {
    final newId = 'QT-$_nextIdCounter';
    _nextIdCounter++;
    return newId;
  }

  /// Get the next ID preview number without incrementing
  int get currentNextIdNumber => _nextIdCounter;

  /// Manually sync the counter with existing quotations (useful when loading from DB)
  void syncCounterWithList(List<Quotation> quotations) {
    for (final q in quotations) {
      final match = RegExp(r'\d+').firstMatch(q.id);
      if (match != null) {
        final parsed = int.tryParse(match.group(0)!);
        if (parsed != null && parsed >= _nextIdCounter) {
          _nextIdCounter = parsed + 1;
        }
      }
    }
  }

  /// Filter and sort quotations chronologically descending (newest first).
  ///
  /// Matches case-insensitively against [Quotation.clientName] or [Quotation.id].
  List<Quotation> filterAndSort({
    required List<Quotation> quotations,
    required String searchQuery,
    bool newestFirst = true,
  }) {
    final query = searchQuery.trim().toLowerCase();

    final filtered = quotations.where((item) {
      if (query.isEmpty) return true;
      final matchesClient = item.clientName.toLowerCase().contains(query);
      final matchesId = item.id.toLowerCase().contains(query);
      return matchesClient || matchesId;
    }).toList();

    filtered.sort((a, b) {
      return newestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt);
    });

    return filtered;
  }

  /// Create a new quotation entity with auto-assigned ID and timestamp
  Quotation createQuotation({
    required String clientName,
    required double amount,
    DateTime? createdAt,
  }) {
    return Quotation(
      id: generateNextId(),
      clientName: clientName.trim(),
      amount: amount,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Format numeric amount as clean currency string (e.g. $1,250.00)
  ///
  /// Does not depend on external packages like `intl`, keeping this module
  /// completely lightweight and dependency-free.
  static String formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInt = integerPart.replaceAllMapped(regExp, (Match m) => '${m[1]},');
    return '\$$formattedInt.$decimalPart';
  }

  /// Format DateTime into clean YYYY-MM-DD format
  static String formatDate(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Get initial realistic mock data for preview and testing
  static List<Quotation> getMockQuotations() {
    return [
      Quotation(
        id: 'QT-1005',
        clientName: 'Zenith Retail Group',
        amount: 740.00,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Quotation(
        id: 'QT-1004',
        clientName: 'Sunrise Healthcare',
        amount: 5600.00,
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
      Quotation(
        id: 'QT-1003',
        clientName: 'Apex Digital Solutions',
        amount: 8900.50,
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      ),
      Quotation(
        id: 'QT-1002',
        clientName: 'Blue Wave Logistics',
        amount: 1280.00,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      Quotation(
        id: 'QT-1001',
        clientName: 'Starlight Enterprise',
        amount: 3450.75,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }
}
