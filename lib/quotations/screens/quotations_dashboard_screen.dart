import 'package:flutter/material.dart';
import '../models/quotation_model.dart';
import '../services/quotation_service.dart';
import '../widgets/quotation_card.dart';
import '../widgets/quotation_form_sheet.dart';
import '../widgets/delete_confirmation_dialog.dart';

/// The Quotations Dashboard Screen.
///
/// Features:
/// - Sticky search & real-time filter bar
/// - Safety toggle switch for Delete Mode in the AppBar
/// - Chronological descending sorting (newest first)
/// - Counter showing total & filtered results
/// - Clean empty state illustration
/// - Create & Edit Modal Bottom Sheet
class QuotationsDashboardScreen extends StatefulWidget {
  /// Optional initial quotations list. If omitted, default mock data is loaded.
  final List<Quotation>? initialQuotations;

  const QuotationsDashboardScreen({
    super.key,
    this.initialQuotations,
  });

  @override
  State<QuotationsDashboardScreen> createState() => _QuotationsDashboardScreenState();
}

class _QuotationsDashboardScreenState extends State<QuotationsDashboardScreen> {
  // Quotation business logic service
  final QuotationService _service = QuotationService();

  // Safety toggle switch: Delete Mode (ON/OFF)
  bool _isDeleteMode = false;

  // Search input controller and state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // In-memory quotations list
  late List<Quotation> _quotations;

  @override
  void initState() {
    super.initState();
    _quotations = widget.initialQuotations != null
        ? List<Quotation>.from(widget.initialQuotations!)
        : QuotationService.getMockQuotations();

    _service.syncCounterWithList(_quotations);

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter and sort items using the QuotationService
  List<Quotation> get _displayedQuotations {
    return _service.filterAndSort(
      quotations: _quotations,
      searchQuery: _searchQuery,
      newestFirst: true,
    );
  }

  // Open the create/edit modal bottom sheet
  void _openQuotationForm([Quotation? quotation]) {
    showQuotationFormBottomSheet(
      context: context,
      quotationToEdit: quotation,
      nextIdNumber: _service.currentNextIdNumber,
      onSave: (clientName, amount) {
        setState(() {
          if (quotation != null) {
            quotation.clientName = clientName;
            quotation.amount = amount;
          } else {
            final newQuotation = _service.createQuotation(
              clientName: clientName,
              amount: amount,
            );
            _quotations.insert(0, newQuotation);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              quotation != null
                  ? 'Updated ${quotation.id} successfully'
                  : 'Created new quotation successfully',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  // Confirm and delete quotation
  Future<void> _handleDelete(Quotation quotation) async {
    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      quotation: quotation,
    );

    if (confirmed == true && mounted) {
      setState(() {
        _quotations.removeWhere((item) => item.id == quotation.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text('Deleted quotation ${quotation.id}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedList = _displayedQuotations;
    final totalCount = _quotations.length;
    final filteredCount = displayedList.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotations Dashboard'),
        actions: [
          // Safety Toggle Switch: Delete Mode (ON/OFF)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isDeleteMode ? Colors.red.shade50 : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isDeleteMode ? Colors.red.shade200 : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isDeleteMode ? Icons.delete_forever_rounded : Icons.security_rounded,
                  size: 16,
                  color: _isDeleteMode ? Colors.red.shade700 : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  'Delete Mode',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isDeleteMode ? Colors.red.shade700 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: 0.8,
                  child: Switch.adaptive(
                    value: _isDeleteMode,
                    activeThumbColor: Colors.red,
                    activeTrackColor: Colors.red.shade200,
                    onChanged: (val) {
                      setState(() {
                        _isDeleteMode = val;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sticky Header Section: Search & Filter Bar + Counter
                Container(
                  color: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sticky Search Bar
                      Material(
                        elevation: 1,
                        shadowColor: Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by Client Name or Quotation ID...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF64748B),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.cancel_rounded,
                                      color: Color(0xFF94A3B8),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                    tooltip: 'Clear search',
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Results Counter & Chronological Sort Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Total / Filtered Count Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'All Quotations ($totalCount)'
                                  : 'Matching ($filteredCount of $totalCount)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),

                          // Sort Badge
                          const Row(
                            children: [
                              Icon(
                                Icons.swap_vert_rounded,
                                size: 16,
                                color: Color(0xFF64748B),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Sorted by Newest First',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Quotation List View or Empty State
                Expanded(
                  child: displayedList.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88), // Bottom padding for FAB
                          itemCount: displayedList.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final quotation = displayedList[index];
                            return QuotationCard(
                              quotation: quotation,
                              isDeleteMode: _isDeleteMode,
                              onTap: () => _openQuotationForm(quotation),
                              onDelete: () => _handleDelete(quotation),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Prominent Create Quotation FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openQuotationForm(),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          'Create Quotation',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
    );
  }

  // Clean empty state widget
  Widget _buildEmptyState() {
    final hasSearch = _searchQuery.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
              ),
              child: Icon(
                hasSearch ? Icons.search_off_rounded : Icons.receipt_long_outlined,
                size: 48,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasSearch ? 'No matching quotations found' : 'No quotations yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'No results found for "$_searchQuery". Try checking spelling or using a quotation ID.'
                  : 'Start by creating your first quotation using the button below.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (hasSearch)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear Search Filter'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            else
              FilledButton.icon(
                onPressed: () => _openQuotationForm(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create First Quotation'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
