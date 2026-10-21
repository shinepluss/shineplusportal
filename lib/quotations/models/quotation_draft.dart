/// Header metadata including structured location, month, sequence, and draft revision
class QuotationHeader {
  String companyName;
  String companyTagline;
  String locationCode; // e.g. LHR, ISB, KHI, FSD
  String monthCode; // e.g. SEP, OCT
  int invoiceNumber; // e.g. 354
  int draftRevision; // e.g. 1, 2, 3, 4
  DateTime date;

  QuotationHeader({
    required this.companyName,
    required this.companyTagline,
    required this.locationCode,
    required this.monthCode,
    required this.invoiceNumber,
    required this.draftRevision,
    required this.date,
  });

  /// Formatted quote number: [LOCATION]/[MONTH]/[INVOICE_NUM]-[REVISION]
  String get quoteNumber =>
      '${locationCode.toUpperCase()}/${monthCode.toUpperCase()}/$invoiceNumber-$draftRevision';

  /// Safe filename without slashes (e.g. LHR_SEP_354-4.pdf)
  String get safeFilename =>
      '${locationCode.toUpperCase()}_${monthCode.toUpperCase()}_$invoiceNumber-$draftRevision.pdf';

  QuotationHeader copyWith({
    String? companyName,
    String? companyTagline,
    String? locationCode,
    String? monthCode,
    int? invoiceNumber,
    int? draftRevision,
    DateTime? date,
  }) {
    return QuotationHeader(
      companyName: companyName ?? this.companyName,
      companyTagline: companyTagline ?? this.companyTagline,
      locationCode: locationCode ?? this.locationCode,
      monthCode: monthCode ?? this.monthCode,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      draftRevision: draftRevision ?? this.draftRevision,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'company_name': companyName,
      'company_tagline': companyTagline,
      'location_code': locationCode,
      'month_code': monthCode,
      'invoice_number': invoiceNumber,
      'draft_revision': draftRevision,
      'quote_number': quoteNumber,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    };
  }

  factory QuotationHeader.fromMap(Map<String, dynamic> map) {
    return QuotationHeader(
      companyName: map['company_name'] as String? ?? 'Shine Plus (Private) Limited',
      companyTagline: map['company_tagline'] as String? ?? 'A Startup Established by Hashoo Foundation',
      locationCode: map['location_code'] as String? ?? 'LHR',
      monthCode: map['month_code'] as String? ?? 'SEP',
      invoiceNumber: map['invoice_number'] as int? ?? 354,
      draftRevision: map['draft_revision'] as int? ?? 1,
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
    );
  }
}

/// Client Information
class ClientInfo {
  String name;
  String designation;
  String organization;
  String city;

  ClientInfo({
    required this.name,
    required this.designation,
    required this.organization,
    required this.city,
  });

  ClientInfo copyWith({
    String? name,
    String? designation,
    String? organization,
    String? city,
  }) {
    return ClientInfo(
      name: name ?? this.name,
      designation: designation ?? this.designation,
      organization: organization ?? this.organization,
      city: city ?? this.city,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'designation': designation,
      'organization': organization,
      'city': city,
    };
  }

  factory ClientInfo.fromMap(Map<String, dynamic> map) {
    return ClientInfo(
      name: map['name'] as String? ?? '',
      designation: map['designation'] as String? ?? '',
      organization: map['organization'] as String? ?? '',
      city: map['city'] as String? ?? '',
    );
  }
}

/// Individual Quotation Line Item
class QuotationLineItem {
  int srNo;
  String description;
  String unit;
  double companyRate;
  double discountedRate;
  double quantity;
  double? customLineTotal;

  QuotationLineItem({
    required this.srNo,
    required this.description,
    required this.unit,
    required this.companyRate,
    required this.discountedRate,
    required this.quantity,
    this.customLineTotal,
  });

  /// Computed or custom overridden line total
  double get lineTotal => customLineTotal ?? (discountedRate * quantity);

  QuotationLineItem copyWith({
    int? srNo,
    String? description,
    String? unit,
    double? companyRate,
    double? discountedRate,
    double? quantity,
    double? customLineTotal,
  }) {
    return QuotationLineItem(
      srNo: srNo ?? this.srNo,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      companyRate: companyRate ?? this.companyRate,
      discountedRate: discountedRate ?? this.discountedRate,
      quantity: quantity ?? this.quantity,
      customLineTotal: customLineTotal ?? this.customLineTotal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sr_no': srNo,
      'description': description,
      'unit': unit,
      'company_rate': companyRate,
      'discounted_rate': discountedRate,
      'quantity': quantity,
      'line_total': lineTotal,
    };
  }

  factory QuotationLineItem.fromMap(Map<String, dynamic> map) {
    return QuotationLineItem(
      srNo: map['sr_no'] as int? ?? 1,
      description: map['description'] as String? ?? '',
      unit: map['unit'] as String? ?? 'Unit',
      companyRate: (map['company_rate'] as num?)?.toDouble() ?? 0.0,
      discountedRate: (map['discounted_rate'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      customLineTotal: (map['line_total'] as num?)?.toDouble(),
    );
  }
}

/// Commercial Payment Milestone
class PaymentMilestone {
  double percentage;
  String stage;
  String terms;

  PaymentMilestone({
    required this.percentage,
    required this.stage,
    required this.terms,
  });

  PaymentMilestone copyWith({
    double? percentage,
    String? stage,
    String? terms,
  }) {
    return PaymentMilestone(
      percentage: percentage ?? this.percentage,
      stage: stage ?? this.stage,
      terms: terms ?? this.terms,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'percentage': percentage,
      'stage': stage,
      'terms': terms,
    };
  }

  factory PaymentMilestone.fromMap(Map<String, dynamic> map) {
    return PaymentMilestone(
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      stage: map['stage'] as String? ?? '',
      terms: map['terms'] as String? ?? '',
    );
  }
}

/// Banking Instructions
class BankingInstructions {
  String beneficiaryName;
  String bankName;
  String accountNumber;
  List<String> paymentModes;

  BankingInstructions({
    required this.beneficiaryName,
    required this.bankName,
    required this.accountNumber,
    required this.paymentModes,
  });

  BankingInstructions copyWith({
    String? beneficiaryName,
    String? bankName,
    String? accountNumber,
    List<String>? paymentModes,
  }) {
    return BankingInstructions(
      beneficiaryName: beneficiaryName ?? this.beneficiaryName,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      paymentModes: paymentModes ?? List<String>.from(this.paymentModes),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'beneficiary_name': beneficiaryName,
      'bank_name': bankName,
      'account_number': accountNumber,
      'payment_modes': paymentModes,
    };
  }

  factory BankingInstructions.fromMap(Map<String, dynamic> map) {
    return BankingInstructions(
      beneficiaryName: map['beneficiary_name'] as String? ?? '',
      bankName: map['bank_name'] as String? ?? '',
      accountNumber: map['account_number'] as String? ?? '',
      paymentModes: (map['payment_modes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// Signatory Information
class SignatoryInfo {
  String signOff;
  String name;
  String designation;

  SignatoryInfo({
    required this.signOff,
    required this.name,
    required this.designation,
  });

  SignatoryInfo copyWith({
    String? signOff,
    String? name,
    String? designation,
  }) {
    return SignatoryInfo(
      signOff: signOff ?? this.signOff,
      name: name ?? this.name,
      designation: designation ?? this.designation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sign_off': signOff,
      'name': name,
      'designation': designation,
    };
  }

  factory SignatoryInfo.fromMap(Map<String, dynamic> map) {
    return SignatoryInfo(
      signOff: map['sign_off'] as String? ?? 'Sincerely Yours,',
      name: map['name'] as String? ?? '',
      designation: map['designation'] as String? ?? '',
    );
  }
}

/// Complete Quotation Draft Document with revision support
class QuotationDraft {
  QuotationHeader header;
  ClientInfo client;
  String subject;
  String salutation;
  String introText;
  String currency;
  List<QuotationLineItem> lineItems;
  String taxNote;
  List<PaymentMilestone> paymentMilestones;
  BankingInstructions bankingInstructions;
  SignatoryInfo signatory;

  QuotationDraft({
    required this.header,
    required this.client,
    required this.subject,
    required this.salutation,
    required this.introText,
    required this.currency,
    required this.lineItems,
    required this.taxNote,
    required this.paymentMilestones,
    required this.bankingInstructions,
    required this.signatory,
  });

  /// Grand Total calculation
  double get grandTotal => lineItems.fold(0.0, (sum, item) => sum + item.lineTotal);

  /// Total milestone percentage
  double get totalMilestonePercentage =>
      paymentMilestones.fold(0.0, (sum, m) => sum + m.percentage);

  /// Deep copy of the entire quotation
  QuotationDraft deepCopy() {
    return QuotationDraft(
      header: header.copyWith(),
      client: client.copyWith(),
      subject: subject,
      salutation: salutation,
      introText: introText,
      currency: currency,
      lineItems: lineItems.map((item) => item.copyWith()).toList(),
      taxNote: taxNote,
      paymentMilestones: paymentMilestones.map((m) => m.copyWith()).toList(),
      bankingInstructions: bankingInstructions.copyWith(),
      signatory: signatory.copyWith(),
    );
  }

  /// Create a new revision snapshot (auto-increments draft_revision)
  QuotationDraft createNextRevision() {
    final copy = deepCopy();
    copy.header.draftRevision = header.draftRevision + 1;
    copy.header.date = DateTime.now();
    return copy;
  }

  Map<String, dynamic> toMap() {
    return {
      'quotation': {
        'header': header.toMap(),
        'client': client.toMap(),
        'subject': subject,
        'salutation': salutation,
        'intro_text': introText,
        'currency': currency,
        'line_items': lineItems.map((e) => e.toMap()).toList(),
        'financial_summary': {
          'grand_total': grandTotal,
          'tax_note': taxNote,
        },
        'payment_milestones': paymentMilestones.map((e) => e.toMap()).toList(),
        'banking_instructions': bankingInstructions.toMap(),
        'signatory': signatory.toMap(),
      }
    };
  }

  factory QuotationDraft.fromMap(Map<String, dynamic> rawMap) {
    final map = rawMap['quotation'] is Map<String, dynamic>
        ? rawMap['quotation'] as Map<String, dynamic>
        : rawMap;

    return QuotationDraft(
      header: map['header'] != null
          ? QuotationHeader.fromMap(map['header'] as Map<String, dynamic>)
          : QuotationHeader(
              companyName: 'Shine Plus (Private) Limited',
              companyTagline: 'A Startup Established by Hashoo Foundation',
              locationCode: 'LHR',
              monthCode: 'SEP',
              invoiceNumber: 1,
              draftRevision: 1,
              date: DateTime.now(),
            ),
      client: map['client'] != null
          ? ClientInfo.fromMap(map['client'] as Map<String, dynamic>)
          : ClientInfo(name: '', designation: '', organization: '', city: ''),
      subject: map['subject'] as String? ?? '',
      salutation: map['salutation'] as String? ?? 'Dear Sir,',
      introText: map['intro_text'] as String? ?? '',
      currency: map['currency'] as String? ?? 'PKR',
      lineItems: (map['line_items'] as List<dynamic>?)
              ?.map((item) => QuotationLineItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      taxNote: (map['financial_summary'] is Map<String, dynamic>
              ? (map['financial_summary'] as Map<String, dynamic>)['tax_note'] as String?
              : map['tax_note'] as String?) ??
          'The above rates are inclusive of all taxes.',
      paymentMilestones: (map['payment_milestones'] as List<dynamic>?)
              ?.map((m) => PaymentMilestone.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      bankingInstructions: map['banking_instructions'] != null
          ? BankingInstructions.fromMap(map['banking_instructions'] as Map<String, dynamic>)
          : BankingInstructions(
              beneficiaryName: '',
              bankName: '',
              accountNumber: '',
              paymentModes: [],
            ),
      signatory: map['signatory'] != null
          ? SignatoryInfo.fromMap(map['signatory'] as Map<String, dynamic>)
          : SignatoryInfo(signOff: 'Sincerely Yours,', name: '', designation: ''),
    );
  }

  /// Initial sample payload matching the project requirements
  factory QuotationDraft.sampleDraft4() {
    return QuotationDraft(
      header: QuotationHeader(
        companyName: 'Shine Plus (Private) Limited',
        companyTagline: 'A Startup Established by Hashoo Foundation',
        locationCode: 'LHR',
        monthCode: 'SEP',
        invoiceNumber: 354,
        draftRevision: 4,
        date: DateTime(2026, 9, 30),
      ),
      client: ClientInfo(
        name: 'Mr. Junaid Imran',
        designation: 'Managing Director',
        organization: 'Circle Club',
        city: 'Faisalabad',
      ),
      subject: 'Quotation for "Polishing Service"',
      salutation: 'Dear Sir,',
      introText:
          'Shine Plus (Private) Limited is a startup established by Hashoo Foundation, '
          'providing high quality services that includes marble/granite, chips cutting, '
          'grinding, repolishing along with Tile cleaning & grouting, Glass cleaning '
          'and Brass/SS polishing along-with Fumigation & sanitization services for '
          'commercial and domestic clients. Our major clients are PC Hotels, Marriott Hotels, '
          'Hotel One, Movenpick Hotel, Double Tree by Hilton, Islamabad Hotel, and Islamabad Club etc.',
      currency: 'PKR',
      lineItems: [
        QuotationLineItem(
          srNo: 1,
          description: 'Marble Cutting, Gridding & Polishing- Mosques',
          unit: 'Sq. Ft.',
          companyRate: 45,
          discountedRate: 40,
          quantity: 2047,
          customLineTotal: 81880,
        ),
        QuotationLineItem(
          srNo: 2,
          description: "Guest Room's Washroom (Complete Deep Cleaning)",
          unit: 'Washroom',
          companyRate: 8000,
          discountedRate: 7000,
          quantity: 40,
          customLineTotal: 280000,
        ),
      ],
      taxNote: 'The above rates are inclusive of all taxes.',
      paymentMilestones: [
        PaymentMilestone(
          percentage: 50,
          stage: 'Advance Payment',
          terms: 'Due at the start of the project.',
        ),
        PaymentMilestone(
          percentage: 25,
          stage: 'Progress Payment',
          terms: 'Payable upon 50% completion of the project.',
        ),
        PaymentMilestone(
          percentage: 25,
          stage: 'Final Payment',
          terms: 'Due upon full completion and delivery of the project',
        ),
      ],
      bankingInstructions: BankingInstructions(
        beneficiaryName: 'Shine Plus (Private) Limited',
        bankName: 'BALF',
        accountNumber: '0035-1007161602',
        paymentModes: [
          'Online Cash Deposit in Company Account (BALF Account # 0035-1007161602)',
          'Crossed Cheque in the name of Shine Plus (Pvt) Ltd',
          'Purchase order/Cheque will be issued in the name of Shine Plus (Private) Limited',
        ],
      ),
      signatory: SignatoryInfo(
        signOff: 'Sincerely Yours,',
        name: 'Amir Nawaz',
        designation: 'Manager Sales',
      ),
    );
  }
}

