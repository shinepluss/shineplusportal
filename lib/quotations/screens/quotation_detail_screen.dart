import 'package:flutter/material.dart';
import '../../features/master_data/master_data.dart';
import '../models/quotation_draft.dart';
import '../services/pdf_generator_service.dart';
import '../services/export_share_service.dart';
import '../widgets/export_share_sheet.dart';

/// Standalone, interactive, and fully editable Quotation & Invoice Detail Screen.
///
/// Features:
/// - Dynamic Draft Revision Tracking & Numbering ([LOCATION]/[MONTH]/[SEQ]-[REV], e.g. LHR/SEP/354-4)
/// - Historical Draft snapshots preservation with a Version History selector
/// - Material 3 responsive layout (client fields, line items, and milestones never overflow)
/// - Automated PDF generation via `pdf` and `printing`
/// - Multi-channel export and sharing (Download, WhatsApp, Gmail, Zoho Mail, Outlook, Print)
class QuotationDetailScreen extends StatefulWidget {
  /// Optional initial draft to display. If null, loads default sample revisions.
  final QuotationDraft? initialDraft;

  const QuotationDetailScreen({
    super.key,
    this.initialDraft,
  });

  @override
  State<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends State<QuotationDetailScreen> {
  // --- Version Tracking State ---
  late List<QuotationDraft> _draftVersions;
  int _selectedVersionIndex = 0;

  // --- Header Data ---
  late TextEditingController _companyNameController;
  late TextEditingController _companyTaglineController;
  late TextEditingController _locationCodeController;
  late TextEditingController _monthCodeController;
  late TextEditingController _invoiceNumController;
  late TextEditingController _draftRevController;
  late DateTime _quoteDate;

  // --- Client & Letter Data ---
  late TextEditingController _clientNameController;
  late TextEditingController _clientDesignationController;
  late TextEditingController _clientOrgController;
  late TextEditingController _clientCityController;
  late TextEditingController _subjectController;
  late TextEditingController _salutationController;
  late TextEditingController _introTextController;
  String _currency = 'PKR';

  // --- Line Items ---
  late List<QuotationLineItem> _lineItems;

  // --- Financial Summary ---
  late TextEditingController _taxNoteController;

  // --- Payment Milestones ---
  late List<PaymentMilestone> _paymentMilestones;

  // --- Banking Instructions ---
  late TextEditingController _beneficiaryController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late List<String> _paymentModes;

  // --- Signatory ---
  late TextEditingController _signOffController;
  late TextEditingController _signatoryNameController;
  late TextEditingController _signatoryDesignationController;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadHistoricalDrafts();
  }

  void _initControllers() {
    _companyNameController = TextEditingController();
    _companyTaglineController = TextEditingController();
    _locationCodeController = TextEditingController();
    _monthCodeController = TextEditingController();
    _invoiceNumController = TextEditingController();
    _draftRevController = TextEditingController();

    _clientNameController = TextEditingController();
    _clientDesignationController = TextEditingController();
    _clientOrgController = TextEditingController();
    _clientCityController = TextEditingController();
    _subjectController = TextEditingController();
    _salutationController = TextEditingController();
    _introTextController = TextEditingController();

    _lineItems = [];

    _taxNoteController = TextEditingController();
    _paymentMilestones = [];

    _beneficiaryController = TextEditingController();
    _bankNameController = TextEditingController();
    _accountNumberController = TextEditingController();
    _paymentModes = [];

    _signOffController = TextEditingController();
    _signatoryNameController = TextEditingController();
    _signatoryDesignationController = TextEditingController();
  }

  void _loadHistoricalDrafts() {
    if (widget.initialDraft != null) {
      _draftVersions = [widget.initialDraft!.deepCopy()];
      _selectedVersionIndex = 0;
    } else {
      // Build chronological drafts (Draft 1 to 4) leading up to official Draft 4
      final sample4 = QuotationDraft.sampleDraft4();

      final draft1 = sample4.deepCopy();
      draft1.header.draftRevision = 1;
      draft1.header.date = DateTime(2026, 9, 20);
      draft1.lineItems = [sample4.lineItems[0].copyWith(quantity: 1500, customLineTotal: 60000)];
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

      final draft4 = sample4;

      _draftVersions = [draft1, draft2, draft3, draft4];
      _selectedVersionIndex = 3; // Start on latest Draft 4
    }

    _loadDraftIntoForm(_draftVersions[_selectedVersionIndex]);
  }

  /// Populate all form fields from a specific draft snapshot
  void _loadDraftIntoForm(QuotationDraft draft) {
    _companyNameController.text = draft.header.companyName;
    _companyTaglineController.text = draft.header.companyTagline;
    _locationCodeController.text = draft.header.locationCode;
    _monthCodeController.text = draft.header.monthCode;
    _invoiceNumController.text = draft.header.invoiceNumber.toString();
    _draftRevController.text = draft.header.draftRevision.toString();
    _quoteDate = draft.header.date;

    _clientNameController.text = draft.client.name;
    _clientDesignationController.text = draft.client.designation;
    _clientOrgController.text = draft.client.organization;
    _clientCityController.text = draft.client.city;

    _subjectController.text = draft.subject;
    _salutationController.text = draft.salutation;
    _introTextController.text = draft.introText;
    _currency = draft.currency;

    _lineItems = draft.lineItems.map((item) => item.copyWith()).toList();
    _taxNoteController.text = draft.taxNote;
    _paymentMilestones = draft.paymentMilestones.map((m) => m.copyWith()).toList();

    _beneficiaryController.text = draft.bankingInstructions.beneficiaryName;
    _bankNameController.text = draft.bankingInstructions.bankName;
    _accountNumberController.text = draft.bankingInstructions.accountNumber;
    _paymentModes = List<String>.from(draft.bankingInstructions.paymentModes);

    _signOffController.text = draft.signatory.signOff;
    _signatoryNameController.text = draft.signatory.name;
    _signatoryDesignationController.text = draft.signatory.designation;
  }

  /// Construct a QuotationDraft object from current form values
  QuotationDraft _buildCurrentDraft() {
    final invNum = int.tryParse(_invoiceNumController.text.trim()) ?? 354;
    final revNum = int.tryParse(_draftRevController.text.trim()) ?? 1;

    return QuotationDraft(
      header: QuotationHeader(
        companyName: _companyNameController.text.trim(),
        companyTagline: _companyTaglineController.text.trim(),
        locationCode: _locationCodeController.text.trim().toUpperCase(),
        monthCode: _monthCodeController.text.trim().toUpperCase(),
        invoiceNumber: invNum,
        draftRevision: revNum,
        date: _quoteDate,
      ),
      client: ClientInfo(
        name: _clientNameController.text.trim(),
        designation: _clientDesignationController.text.trim(),
        organization: _clientOrgController.text.trim(),
        city: _clientCityController.text.trim(),
      ),
      subject: _subjectController.text.trim(),
      salutation: _salutationController.text.trim(),
      introText: _introTextController.text.trim(),
      currency: _currency,
      lineItems: _lineItems.map((e) => e.copyWith()).toList(),
      taxNote: _taxNoteController.text.trim(),
      paymentMilestones: _paymentMilestones.map((e) => e.copyWith()).toList(),
      bankingInstructions: BankingInstructions(
        beneficiaryName: _beneficiaryController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        paymentModes: List<String>.from(_paymentModes),
      ),
      signatory: SignatoryInfo(
        signOff: _signOffController.text.trim(),
        name: _signatoryNameController.text.trim(),
        designation: _signatoryDesignationController.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyTaglineController.dispose();
    _locationCodeController.dispose();
    _monthCodeController.dispose();
    _invoiceNumController.dispose();
    _draftRevController.dispose();

    _clientNameController.dispose();
    _clientDesignationController.dispose();
    _clientOrgController.dispose();
    _clientCityController.dispose();
    _subjectController.dispose();
    _salutationController.dispose();
    _introTextController.dispose();

    _taxNoteController.dispose();

    _beneficiaryController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();

    _signOffController.dispose();
    _signatoryNameController.dispose();
    _signatoryDesignationController.dispose();
    super.dispose();
  }

  // --- Calculations ---
  double get _grandTotal {
    return _lineItems.fold(0.0, (sum, item) => sum + item.lineTotal);
  }

  double get _totalMilestonePercentage {
    return _paymentMilestones.fold(0.0, (sum, m) => sum + m.percentage);
  }

  String _formatAmount(double amount) {
    return PdfGeneratorService.formatAmount(amount);
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  // --- Date Picker Action ---
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _quoteDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _quoteDate = picked;
      });
    }
  }

  // --- Draft Versioning Actions ---

  /// Save changes as an immutable new revision (e.g. increments -4 to -5)
  void _saveAsNewRevision() {
    final current = _buildCurrentDraft();
    final newRevision = current.createNextRevision();

    setState(() {
      _draftVersions.add(newRevision);
      _selectedVersionIndex = _draftVersions.length - 1;
      _loadDraftIntoForm(newRevision);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.bookmark_added_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Created & Saved as Draft ${newRevision.header.draftRevision} (${newRevision.header.quoteNumber})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Update the currently active draft in-memory
  void _updateActiveDraft() {
    final updated = _buildCurrentDraft();
    setState(() {
      _draftVersions[_selectedVersionIndex] = updated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2563EB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(
          'Updated Draft ${updated.header.draftRevision} (${updated.header.quoteNumber}) successfully.',
        ),
      ),
    );
  }

  /// Switch the active version from the Version History dropdown
  void _switchVersion(int newIndex) {
    if (newIndex >= 0 && newIndex < _draftVersions.length) {
      setState(() {
        _selectedVersionIndex = newIndex;
        _loadDraftIntoForm(_draftVersions[_selectedVersionIndex]);
      });
    }
  }

  // --- Line Item Modal Actions ---
  void _openLineItemModal([QuotationLineItem? existingItem, int? index]) {
    final isEditing = existingItem != null;
    final descController = TextEditingController(text: existingItem?.description ?? '');
    final unitController = TextEditingController(text: existingItem?.unit ?? 'Sq. Ft.');
    final companyRateController = TextEditingController(
      text: existingItem != null ? existingItem.companyRate.toString() : '',
    );
    final discountedRateController = TextEditingController(
      text: existingItem != null ? existingItem.discountedRate.toString() : '',
    );
    final quantityController = TextEditingController(
      text: existingItem != null ? existingItem.quantity.toString() : '1',
    );
    final customTotalController = TextEditingController(
      text: existingItem?.customLineTotal != null ? existingItem!.customLineTotal.toString() : '',
    );

    bool useCustomTotal = existingItem?.customLineTotal != null;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final keyboardInset = MediaQuery.of(modalContext).viewInsets.bottom;

            double calcDiscounted = double.tryParse(discountedRateController.text) ?? 0;
            double calcQty = double.tryParse(quantityController.text) ?? 0;
            double calculatedTotal = calcDiscounted * calcQty;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: keyboardInset + 24,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEditing ? 'Edit Line Item' : 'Add Line Item',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final created = await ServiceDialog.show(modalContext);
                                if (created != null) {
                                  setModalState(() {
                                    descController.text = created.title;
                                    unitController.text = created.defaultUnit;
                                    companyRateController.text = created.standardCompanyRate.toString();
                                    discountedRateController.text = created.standardCompanyRate.toString();
                                  });
                                }
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                              label: const Text('+ Add New Service'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF059669),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Service Catalog Quick Dropdown
                        ListenableBuilder(
                          listenable: MasterDataService.instance,
                          builder: (context, _) {
                            final services = MasterDataService.instance.services;
                            if (services.isEmpty) return const SizedBox.shrink();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<ServiceModel>(
                                  isExpanded: true,
                                  hint: const Row(
                                    children: [
                                      Icon(Icons.cleaning_services_rounded, size: 16, color: Color(0xFF059669)),
                                      SizedBox(width: 8),
                                      Text(
                                        'Select from Service Catalog (Auto-Fill)',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF047857)),
                                      ),
                                    ],
                                  ),
                                  items: services.map((s) {
                                    return DropdownMenuItem<ServiceModel>(
                                      value: s,
                                      child: Text(
                                        '${s.title} • PKR ${s.standardCompanyRate.toStringAsFixed(0)} / ${s.defaultUnit}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (selected) {
                                    if (selected != null) {
                                      setModalState(() {
                                        descController.text = selected.title;
                                        unitController.text = selected.defaultUnit;
                                        companyRateController.text = selected.standardCompanyRate.toString();
                                        discountedRateController.text = selected.standardCompanyRate.toString();
                                      });
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),

                        TextFormField(
                          controller: descController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Description / Scope of Work',
                            alignLabelWithHint: true,
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty) ? 'Please enter description' : null,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: unitController,
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                  hintText: 'e.g. Sq. Ft., Washroom',
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty) ? 'Enter unit' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: quantityController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Quantity',
                                ),
                                onChanged: (_) => setModalState(() {}),
                                validator: (val) {
                                  if (val == null || double.tryParse(val) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: companyRateController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Company Rate ($_currency)',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: discountedRateController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Discounted Rate ($_currency)',
                                ),
                                onChanged: (_) => setModalState(() {}),
                                validator: (val) {
                                  if (val == null || double.tryParse(val) == null) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Custom / Override Total',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  Switch(
                                    value: useCustomTotal,
                                    onChanged: (val) {
                                      setModalState(() {
                                        useCustomTotal = val;
                                        if (!val) customTotalController.clear();
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (useCustomTotal)
                                TextFormField(
                                  controller: customTotalController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Total Override ($_currency)',
                                    hintText: 'e.g. 81880',
                                  ),
                                )
                              else
                                Text(
                                  'Computed Line Total: $_currency ${_formatAmount(calculatedTotal)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        FilledButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;

                            final desc = descController.text.trim();
                            final unit = unitController.text.trim();
                            final compRate = double.tryParse(companyRateController.text) ?? 0.0;
                            final discRate = double.parse(discountedRateController.text);
                            final qty = double.parse(quantityController.text);
                            final customTot = useCustomTotal && customTotalController.text.isNotEmpty
                                ? double.tryParse(customTotalController.text)
                                : null;

                            setState(() {
                              if (isEditing && index != null) {
                                _lineItems[index] = _lineItems[index].copyWith(
                                  description: desc,
                                  unit: unit,
                                  companyRate: compRate,
                                  discountedRate: discRate,
                                  quantity: qty,
                                  customLineTotal: customTot,
                                );
                              } else {
                                final nextSrNo = _lineItems.isEmpty
                                    ? 1
                                    : _lineItems.map((e) => e.srNo).reduce((a, b) => a > b ? a : b) + 1;
                                _lineItems.add(
                                  QuotationLineItem(
                                    srNo: nextSrNo,
                                    description: desc,
                                    unit: unit,
                                    companyRate: compRate,
                                    discountedRate: discRate,
                                    quantity: qty,
                                    customLineTotal: customTot,
                                  ),
                                );
                              }
                            });

                            Navigator.pop(ctx);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            isEditing ? 'Save Changes' : 'Add Item to Quotation',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteLineItem(int index) {
    setState(() {
      _lineItems.removeAt(index);
      for (int i = 0; i < _lineItems.length; i++) {
        _lineItems[i].srNo = i + 1;
      }
    });
  }

  // --- Payment Milestone Modal Actions ---
  void _openPaymentMilestoneModal([PaymentMilestone? existing, int? index]) {
    final isEditing = existing != null;
    final stageController = TextEditingController(text: existing?.stage ?? '');
    final pctController = TextEditingController(
      text: existing != null ? existing.percentage.toStringAsFixed(0) : '',
    );
    final termsController = TextEditingController(text: existing?.terms ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'Edit Commercial Milestone' : 'Add Commercial Milestone'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: stageController,
                    decoration: const InputDecoration(labelText: 'Stage Title', hintText: 'e.g. Advance Payment'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: pctController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Percentage (%)', hintText: 'e.g. 50'),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0 || n > 100) return 'Enter 1-100';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: termsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Commercial Terms',
                      hintText: 'e.g. Due upon contract signing',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final pct = double.parse(pctController.text);
                final stg = stageController.text.trim();
                final trm = termsController.text.trim();

                setState(() {
                  if (isEditing && index != null) {
                    _paymentMilestones[index] = PaymentMilestone(percentage: pct, stage: stg, terms: trm);
                  } else {
                    _paymentMilestones.add(PaymentMilestone(percentage: pct, stage: stg, terms: trm));
                  }
                });
                Navigator.pop(dialogCtx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // --- Payment Mode Dialog ---
  void _openPaymentModeModal([String? currentMode, int? index]) {
    final isEditing = currentMode != null;
    final controller = TextEditingController(text: currentMode ?? '');

    showDialog<void>(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'Edit Payment Method' : 'Add Payment Method'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'e.g. Online Cash Deposit, Crossed Cheque, PO',
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                setState(() {
                  if (isEditing && index != null) {
                    _paymentModes[index] = controller.text.trim();
                  } else {
                    _paymentModes.add(controller.text.trim());
                  }
                });
                Navigator.pop(dCtx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // BUILD METHOD & SCAFFOLD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final currentDraft = _buildCurrentDraft();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Formal Quotation Details',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              currentDraft.header.quoteNumber,
              style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          // Native Print / PDF Preview Button
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Print / System PDF Preview',
            onPressed: () => ExportShareService.printOrPreview(currentDraft),
          ),
          // Multi-Channel Share & Export Toolbar
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF16A34A)),
            tooltip: 'Export & Multi-Channel Share',
            onPressed: () => showExportShareSheet(context: context, draft: currentDraft),
          ),
          // Save Menu (Save New Revision vs Update)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Options',
            onSelected: (val) {
              if (val == 'new_revision') {
                _saveAsNewRevision();
              } else if (val == 'update_active') {
                _updateActiveDraft();
              } else if (val == 'reset') {
                setState(() {
                  _loadHistoricalDrafts();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reset to original sample data.')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_revision',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 8),
                    Text('Save as New Revision (Draft +1)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'update_active',
                child: Row(
                  children: [
                    Icon(Icons.save_outlined, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 8),
                    Text('Update Current Draft'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt_rounded, color: Color(0xFF64748B), size: 20),
                    SizedBox(width: 8),
                    Text('Reset to Initial Sample'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- SECTION 0: Dynamic Draft Revision History Banner ---
                  _buildVersionHistoryBanner(),
                  const SizedBox(height: 16),

                  // --- SECTION 1: Company Header & Quote Meta ---
                  _buildCompanyHeaderCard(),
                  const SizedBox(height: 16),

                  // --- SECTION 2: Client Information & Letter Intro ---
                  _buildClientInfoCard(),
                  const SizedBox(height: 16),

                  // --- SECTION 3: Line Items Table / List ---
                  _buildLineItemsCard(),
                  const SizedBox(height: 16),

                  // --- SECTION 4: Financial Summary & Tax Note ---
                  _buildFinancialSummaryCard(),
                  const SizedBox(height: 16),

                  // --- SECTION 5: Payment Milestones & Commercial Terms ---
                  _buildPaymentMilestonesCard(),
                  const SizedBox(height: 16),

                  // --- SECTION 6: Banking Details & Payment Instructions ---
                  _buildBankingInstructionsCard(),
                  const SizedBox(height: 16),

                  // --- SECTION 7: Official Signatory Closing ---
                  _buildSignatoryCard(),
                  const SizedBox(height: 24),

                  // Bottom Action Buttons
                  _buildBottomActionButtons(currentDraft),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION BUILDERS
  // ==========================================

  /// Section 0: Dynamic Version History Dropdown & Revision Controls
  Widget _buildVersionHistoryBanner() {
    final activeDraft = _draftVersions[_selectedVersionIndex];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 20, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Text(
                'VERSION HISTORY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_draftVersions.length} Saved Snapshots',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dropdown Selector for all saved Draft versions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _selectedVersionIndex,
                icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF2563EB)),
                items: List.generate(_draftVersions.length, (idx) {
                  final d = _draftVersions[idx];
                  final isLatest = idx == _draftVersions.length - 1;
                  return DropdownMenuItem<int>(
                    value: idx,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Draft ${d.header.draftRevision}: ${d.header.quoteNumber}',
                            style: TextStyle(
                              fontWeight: idx == _selectedVersionIndex ? FontWeight.w800 : FontWeight.w500,
                              color: const Color(0xFF0F172A),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isLatest ? '(Active Latest)' : _formatDate(d.header.date),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isLatest ? const Color(0xFF10B981) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                onChanged: (newIdx) {
                  if (newIdx != null) _switchVersion(newIdx);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _saveAsNewRevision,
                icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                label: Text('Save as Draft ${activeDraft.header.draftRevision + 1}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _updateActiveDraft,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Update Active Draft'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section 1: Company Header, Tagline, Quote Number & Date
  Widget _buildCompanyHeaderCard() {
    final currentDraft = _buildCurrentDraft();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 420;
                final logoWidget = ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 52,
                    height: 52,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 28),
                      ),
                    ),
                  ),
                );

                final companyInfo = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _companyNameController,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: 'Company Name',
                      ),
                    ),
                    const SizedBox(height: 3),
                    TextFormField(
                      controller: _companyTaglineController,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: 'Company Tagline or Subtitle',
                      ),
                    ),
                  ],
                );

                final quotePill = Column(
                  crossAxisAlignment: isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        currentDraft.header.quoteNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(_quoteDate),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          logoWidget,
                          const SizedBox(width: 14),
                          Expanded(child: companyInfo),
                        ],
                      ),
                      const SizedBox(height: 12),
                      quotePill,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    logoWidget,
                    const SizedBox(width: 14),
                    Expanded(child: companyInfo),
                    const SizedBox(width: 12),
                    quotePill,
                  ],
                );
              },
            ),
            const Divider(height: 28, thickness: 1, color: Color(0xFFF1F5F9)),

            // Structured Quote Numbering Form: [LOCATION]/[MONTH]/[SEQ]-[REV]
            const Text(
              'QUOTE NUMBERING & METADATA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    controller: _locationCodeController,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'LHR',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    controller: _monthCodeController,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      hintText: 'SEP',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    controller: _invoiceNumController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Seq #',
                      hintText: '354',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: TextFormField(
                    controller: _draftRevController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Draft',
                      hintText: '4',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date Row
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'QUOTATION DATE (TAP TO CHANGE)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          _formatDate(_quoteDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section 2: Client Information, Subject & Intro Paragraph
  /// Fully responsive with full-width fields so client names & titles are never cut off
  Widget _buildClientInfoCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CLIENT INFORMATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                    letterSpacing: 0.8,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final created = await ClientDialog.show(context);
                    if (created != null) {
                      setState(() {
                        _clientNameController.text = created.contactName;
                        _clientDesignationController.text = created.designation;
                        _clientOrgController.text = created.organization;
                        _clientCityController.text = created.city;
                      });
                    }
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text('+ Add New Client'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Master Data Client Auto-Fill Selector
            ListenableBuilder(
              listenable: MasterDataService.instance,
              builder: (context, _) {
                final clients = MasterDataService.instance.clients;
                if (clients.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ClientModel>(
                      isExpanded: true,
                      hint: const Row(
                        children: [
                          Icon(Icons.search_rounded, size: 18, color: Color(0xFF2563EB)),
                          SizedBox(width: 8),
                          Text(
                            'Select Registered Client (Auto-Fill)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                          ),
                        ],
                      ),
                      items: clients.map((c) {
                        return DropdownMenuItem<ClientModel>(
                          value: c,
                          child: Text(
                            '${c.contactName} (${c.organization}) • ${c.city}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (selectedClient) {
                        if (selectedClient != null) {
                          setState(() {
                            _clientNameController.text = selectedClient.contactName;
                            _clientDesignationController.text = selectedClient.designation;
                            _clientOrgController.text = selectedClient.organization;
                            _clientCityController.text = selectedClient.city;
                          });
                        }
                      },
                    ),
                  ),
                );
              },
            ),

            // Client Name: Full width so full name is clearly visible while typing
            TextFormField(
              controller: _clientNameController,
              decoration: const InputDecoration(
                labelText: 'Client Name',
                hintText: 'e.g. Mr. Junaid Imran',
              ),
            ),
            const SizedBox(height: 12),

            // Designation: Full width
            TextFormField(
              controller: _clientDesignationController,
              decoration: const InputDecoration(
                labelText: 'Designation',
                hintText: 'e.g. Managing Director',
              ),
            ),
            const SizedBox(height: 12),

            // Organization: Full width
            TextFormField(
              controller: _clientOrgController,
              decoration: const InputDecoration(
                labelText: 'Organization / Company',
                hintText: 'e.g. Circle Club',
              ),
            ),
            const SizedBox(height: 12),

            // City: Full width
            TextFormField(
              controller: _clientCityController,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'e.g. Faisalabad',
              ),
            ),
            const SizedBox(height: 16),

            // Subject Line
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject Line',
                hintText: 'e.g. Quotation for "Polishing Service"',
              ),
            ),
            const SizedBox(height: 12),

            // Salutation
            TextFormField(
              controller: _salutationController,
              decoration: const InputDecoration(
                labelText: 'Salutation',
                hintText: 'e.g. Dear Sir,',
              ),
            ),
            const SizedBox(height: 12),

            // Intro & Profile Paragraph
            TextFormField(
              controller: _introTextController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Introduction & Company Profile Paragraph',
                alignLabelWithHint: true,
              ),
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  /// Section 3: Line Items Table / List with responsive Wrap header so "Add Item" never overflows
  Widget _buildLineItemsCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive Wrap Header prevents horizontal overflow on narrow mobile screens
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'LINE ITEMS & SCOPE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_lineItems.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _openLineItemModal(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Item'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_lineItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: const Text(
                  'No line items added yet. Click "Add Item" above.',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _lineItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _lineItems[index];
                  return _buildLineItemTile(item, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Individual Line Item Tile
  Widget _buildLineItemTile(QuotationLineItem item, int index) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  '${item.srNo}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Unit: ${item.unit}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF2563EB)),
                    tooltip: 'Edit item',
                    splashRadius: 18,
                    onPressed: () => _openLineItemModal(item, index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                    tooltip: 'Delete item',
                    splashRadius: 18,
                    onPressed: () => _deleteLineItem(index),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFE2E8F0)),

          // Responsive Pricing Breakdown
          Wrap(
            spacing: 14,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (item.companyRate > 0)
                Text(
                  'Std: $_currency ${_formatAmount(item.companyRate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Rate: ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Text(
                    '$_currency ${_formatAmount(item.discountedRate)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Qty: ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Text(
                    '${_formatAmount(item.quantity)} ${item.unit}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  'Total: $_currency ${_formatAmount(item.lineTotal)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section 4: Financial Summary Box & Tax Note
  Widget _buildFinancialSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GRAND TOTAL',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_lineItems.length} Line Items',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            '$_currency ${_formatAmount(_grandTotal)}',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFF334155)),

          TextFormField(
            controller: _taxNoteController,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              labelText: 'Tax Clause (Editable)',
              labelStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              prefixIcon: Icon(Icons.info_outline_rounded, color: Color(0xFF94A3B8), size: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// Section 5: Payment Milestones & Commercial Terms
  Widget _buildPaymentMilestonesCard() {
    final totalPercentage = _totalMilestonePercentage;
    final is100Percent = totalPercentage == 100.0;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PAYMENT MILESTONES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total Split: ${totalPercentage.toStringAsFixed(0)}% ${is100Percent ? '✓' : '(Must equal 100%)'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: is100Percent ? const Color(0xFF10B981) : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _openPaymentMilestoneModal(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Stage'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _paymentMilestones.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final milestone = _paymentMilestones[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          '${milestone.percentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              milestone.stage,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              milestone.terms,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                            onPressed: () => _openPaymentMilestoneModal(milestone, index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _paymentMilestones.removeAt(index);
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Section 6: Banking Details & Payment Instructions
  Widget _buildBankingInstructionsCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BANKING & PAYMENT INSTRUCTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 14),

            // Beneficiary
            TextFormField(
              controller: _beneficiaryController,
              decoration: const InputDecoration(
                labelText: 'Beneficiary Name',
              ),
            ),
            const SizedBox(height: 12),

            // Bank Name
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Bank Name',
              ),
            ),
            const SizedBox(height: 12),

            // Account Number
            TextFormField(
              controller: _accountNumberController,
              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Account / IBAN Number',
              ),
            ),
            const SizedBox(height: 16),

            // Payment Modes
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text(
                  'Acceptable Payment Modes:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                ),
                TextButton.icon(
                  onPressed: () => _openPaymentModeModal(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Mode'),
                ),
              ],
            ),
            const SizedBox(height: 6),

            ...List.generate(_paymentModes.length, (index) {
              final mode = _paymentModes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mode,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                      onPressed: () => _openPaymentModeModal(mode, index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _paymentModes.removeAt(index);
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Section 7: Signatory Closing
  Widget _buildSignatoryCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OFFICIAL SIGNATORY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _signOffController,
              decoration: const InputDecoration(
                labelText: 'Sign-off Phrase',
                hintText: 'e.g. Sincerely Yours,',
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _signatoryNameController,
              decoration: const InputDecoration(
                labelText: 'Signatory Name',
                hintText: 'e.g. Amir Nawaz',
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _signatoryDesignationController,
              decoration: const InputDecoration(
                labelText: 'Signatory Designation',
                hintText: 'e.g. Manager Sales',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Multi-Channel Export and Action Toolbar
  Widget _buildBottomActionButtons(QuotationDraft currentDraft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary Action: Export & Multi-Channel Share
        FilledButton.icon(
          onPressed: () => showExportShareSheet(context: context, draft: currentDraft),
          icon: const Icon(Icons.share_rounded, size: 20),
          label: const Text(
            'Export & Multi-Channel Share',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            // Print / Preview Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ExportShareService.printOrPreview(currentDraft),
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('Print Preview'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Save as New Revision
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saveAsNewRevision,
                icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                label: const Text('Save Revision'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  side: const BorderSide(color: Color(0xFF059669)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
