import 'package:flutter_test/flutter_test.dart';
import 'package:shineplusinvoice/core/firebase/firebase_service.dart';
import 'package:shineplusinvoice/features/master_data/master_data.dart';
import 'package:shineplusinvoice/quotations/models/quotation_draft.dart';

void main() {
  group('Firebase Document ID Formatting Tests', () {
    test('Formats quotation document ID correctly: [location]_[month]_[invoice_num]', () {
      final docId = FirebaseService.formatQuotationDocId(
        location: 'LHR',
        month: 'SEP',
        invoiceNum: 354,
      );
      expect(docId, equals('LHR_SEP_354'));

      final docIdWithSpaces = FirebaseService.formatQuotationDocId(
        location: ' isb ',
        month: 'oct ',
        invoiceNum: 12,
      );
      expect(docIdWithSpaces, equals('ISB_OCT_12'));
    });

    test('Formats revision document ID correctly: rev_[revision_num]', () {
      expect(FirebaseService.formatRevisionDocId(1), equals('rev_1'));
      expect(FirebaseService.formatRevisionDocId(4), equals('rev_4'));
    });
  });

  group('Master Data Models & Serialization Tests', () {
    test('ClientModel serialization and copyWith', () {
      final client = ClientModel(
        id: 'c1',
        contactName: 'Mr. Junaid Imran',
        organization: 'Circle Club',
        designation: 'Managing Director',
        city: 'Faisalabad',
        phone: '+92 300 1234567',
      );

      final map = client.toMap();
      expect(map['contact_name'], equals('Mr. Junaid Imran'));
      expect(map['organization'], equals('Circle Club'));

      final restored = ClientModel.fromMap(map, 'c1');
      expect(restored.contactName, equals(client.contactName));
      expect(restored.city, equals('Faisalabad'));

      final updated = client.copyWith(city: 'Lahore');
      expect(updated.city, equals('Lahore'));
      expect(updated.organization, equals('Circle Club'));
    });

    test('ServiceModel serialization and copyWith', () {
      final service = ServiceModel(
        id: 's1',
        title: 'Marble Polishing',
        defaultUnit: 'Sq. Ft.',
        standardCompanyRate: 45.0,
      );

      final map = service.toMap();
      expect(map['title'], equals('Marble Polishing'));
      expect(map['default_unit'], equals('Sq. Ft.'));
      expect(map['standard_company_rate'], equals(45.0));

      final restored = ServiceModel.fromMap(map, 's1');
      expect(restored.title, equals(service.title));
      expect(restored.standardCompanyRate, equals(45.0));

      final updated = service.copyWith(standardCompanyRate: 50.0);
      expect(updated.standardCompanyRate, equals(50.0));
      expect(updated.title, equals('Marble Polishing'));
    });

    test('UserModel serialization and copyWith', () {
      final user = UserModel(
        id: 'u1',
        employeeId: 'EMP-101',
        fullName: 'Muhammad Ali',
        role: 'Supervisor',
        status: 'Active',
      );

      final map = user.toMap();
      expect(map['employee_id'], equals('EMP-101'));
      expect(map['full_name'], equals('Muhammad Ali'));
      expect(map['role'], equals('Supervisor'));

      final restored = UserModel.fromMap(map, 'u1');
      expect(restored.fullName, equals(user.fullName));
      expect(restored.employeeId, equals('EMP-101'));

      final updated = user.copyWith(status: 'Inactive');
      expect(updated.status, equals('Inactive'));
    });
  });

  group('MasterDataService CRUD & In-Memory Logic Tests', () {
    late MasterDataService service;

    setUp(() {
      service = MasterDataService.instance;
    });

    test('Loads default initial seeded data', () {
      expect(service.clients.isNotEmpty, isTrue);
      expect(service.services.isNotEmpty, isTrue);
      expect(service.users.isNotEmpty, isTrue);
      expect(service.totalRecordsCount, equals(service.clients.length + service.services.length + service.users.length));
    });

    test('Add, update, and remove client', () async {
      final newClient = ClientModel(
        id: '',
        contactName: 'Test Client',
        organization: 'Test Org',
        designation: 'Manager',
        city: 'Islamabad',
        phone: '+92 321 0000000',
      );

      final initialCount = service.clients.length;
      await service.saveClient(newClient);
      expect(service.clients.length, equals(initialCount + 1));

      final added = service.clients.firstWhere((c) => c.contactName == 'Test Client');
      expect(added.organization, equals('Test Org'));

      final modified = added.copyWith(organization: 'Updated Org');
      await service.saveClient(modified);
      final fetched = service.clients.firstWhere((c) => c.id == added.id);
      expect(fetched.organization, equals('Updated Org'));

      await service.deleteClient(added.id);
      expect(service.clients.any((c) => c.id == added.id), isFalse);
    });

    test('Add, update, and remove service', () async {
      final newService = ServiceModel(
        id: '',
        title: 'Glass Facade Cleaning',
        defaultUnit: 'Sq. Ft.',
        standardCompanyRate: 35.0,
      );

      final initialCount = service.services.length;
      await service.saveService(newService);
      expect(service.services.length, equals(initialCount + 1));

      final added = service.services.firstWhere((s) => s.title == 'Glass Facade Cleaning');
      final modified = added.copyWith(standardCompanyRate: 40.0);
      await service.saveService(modified);
      final fetched = service.services.firstWhere((s) => s.id == added.id);
      expect(fetched.standardCompanyRate, equals(40.0));

      await service.deleteService(added.id);
      expect(service.services.any((s) => s.id == added.id), isFalse);
    });

    test('Add, update, and remove user', () async {
      final newUser = UserModel(
        id: '',
        employeeId: 'EMP-999',
        fullName: 'Test Worker',
        role: 'Technician',
        status: 'Active',
      );

      final initialCount = service.users.length;
      await service.saveUser(newUser);
      expect(service.users.length, equals(initialCount + 1));

      final added = service.users.firstWhere((u) => u.employeeId == 'EMP-999');
      final modified = added.copyWith(role: 'Senior Technician');
      await service.saveUser(modified);
      final fetched = service.users.firstWhere((u) => u.id == added.id);
      expect(fetched.role, equals('Senior Technician'));

      await service.deleteUser(added.id);
      expect(service.users.any((u) => u.id == added.id), isFalse);
    });
  });

  group('Quotation Draft Serialization Snapshot Tests', () {
    test('QuotationDraft fromMap and toMap round-trip preserves data', () {
      final sample = QuotationDraft.sampleDraft4();
      final map = sample.toMap();

      final restored = QuotationDraft.fromMap(map);
      expect(restored.header.quoteNumber, equals(sample.header.quoteNumber));
      expect(restored.client.name, equals(sample.client.name));
      expect(restored.lineItems.length, equals(sample.lineItems.length));
      expect(restored.lineItems.first.description, equals(sample.lineItems.first.description));
      expect(restored.grandTotal, equals(sample.grandTotal));
      expect(restored.paymentMilestones.length, equals(sample.paymentMilestones.length));
      expect(restored.bankingInstructions.bankName, equals(sample.bankingInstructions.bankName));
    });
  });
}

