import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/firebase/firebase_service.dart';
import '../models/client_model.dart';
import '../models/service_model.dart';
import '../models/user_model.dart';
import '../models/custom_list_schema.dart';
import '../models/custom_record_model.dart';

/// Centralized Master Data & Lists Management Service
///
/// Features:
/// - Real-time Cloud Firestore synchronization with resilient offline caching
/// - Built-in System Lists:
///   * `/master_clients/{clientId}`
///   * `/master_services/{serviceId}`
///   * `/master_users/{userId}`
/// - Dynamic Custom Lists Builder Engine:
///   * `/custom_lists_meta/{listName}` -> schema definition
///   * `/custom_lists_data_{listName}/{recordId}` -> dynamic key-value records
class MasterDataService extends ChangeNotifier {
  static final MasterDataService instance = MasterDataService._internal();
  MasterDataService._internal() {
    _loadSeedData();
    _initFirestoreSync();
  }

  // --- In-Memory State Caches ---
  final List<ClientModel> _clients = [];
  final List<ServiceModel> _services = [];
  final List<UserModel> _users = [];
  final List<CustomListSchema> _customSchemas = [];
  final Map<String, List<CustomRecord>> _customRecords = {};

  // --- Subscriptions ---
  StreamSubscription? _clientsSub;
  StreamSubscription? _servicesSub;
  StreamSubscription? _usersSub;
  StreamSubscription? _schemasSub;
  final Map<String, StreamSubscription> _recordsSubs = {};

  // --- Public Getters ---
  List<ClientModel> get clients => List.unmodifiable(_clients);
  List<ServiceModel> get services => List.unmodifiable(_services);
  List<UserModel> get users => List.unmodifiable(_users);
  List<StaffUserModel> get staffUsers => List.unmodifiable(_users);
  List<CustomListSchema> get customListSchemas => List.unmodifiable(_customSchemas);

  int get totalRecordsCount => _clients.length + _services.length + _users.length;
  int get totalCustomListsCount => _customSchemas.length;

  List<CustomRecord> getCustomRecords(String listName) {
    return List.unmodifiable(_customRecords[listName] ?? []);
  }

  // --- Initial Seed Data ---
  void _loadSeedData() {
    // 1. Corporate Clients
    _clients.addAll([
      ClientModel(
        id: 'client_1',
        contactName: 'Mr. Junaid Imran',
        designation: 'General Manager',
        organization: 'Circle Club',
        city: 'Faisalabad',
        phone: '+92 300 8472910',
        email: 'junaid.imran@circleclub.pk',
        address: 'Circle Club Complex, VIP Road, Faisalabad',
      ),
      ClientModel(
        id: 'client_2',
        contactName: 'Syed Tariq Mehmood',
        designation: 'Head of Facilities & Infrastructure',
        organization: 'Pearl Continental Hotel',
        city: 'Lahore',
        phone: '+92 321 4455667',
        email: 'tariq.facilities@pchotels.com',
        address: 'Mall Road, GOR 1, Lahore',
      ),
      ClientModel(
        id: 'client_3',
        contactName: 'Mrs. Ayesha Malik',
        designation: 'Procurement Director',
        organization: 'Marriott Hotel',
        city: 'Islamabad',
        phone: '+92 333 5566778',
        email: 'ayesha.malik@marriott.isb',
        address: 'Aga Khan Road, Sector F-5/1, Islamabad',
      ),
      ClientModel(
        id: 'client_4',
        contactName: 'Dr. Usman Farooq',
        designation: 'Chief Administrator',
        organization: 'Hashoo Foundation Secretariat',
        city: 'Islamabad',
        phone: '+92 302 9988776',
        email: 'usman.farooq@hashoofoundation.org',
        address: 'Hashoo Complex, Blue Area, Islamabad',
      ),
      ClientModel(
        id: 'client_5',
        contactName: 'Engr. Bilal Sheikh',
        designation: 'Site Operations Manager',
        organization: 'Serena Business Complex',
        city: 'Faisalabad',
        phone: '+92 345 1122334',
        email: 'bilal.sheikh@serenabusiness.com',
        address: 'Civil Lines, Club Chowk, Faisalabad',
      ),
      ClientModel(
        id: 'client_6',
        contactName: 'Chaudhry Nadeem Akhtar',
        designation: 'Secretary General',
        organization: 'Islamabad Club',
        city: 'Islamabad',
        phone: '+92 300 5544332',
        email: 'secgen@islamabadclub.org.pk',
        address: 'Murree Road, Islamabad Club Enclave, Islamabad',
      ),
    ]);

    // 2. Services & Standard Rates Catalog
    _services.addAll([
      ServiceModel(
        id: 'svc_1',
        title: 'Marble Cutting, Gridding & Polishing- Mosques',
        defaultUnit: 'Sq. Ft.',
        standardCompanyRate: 40.0,
        description: 'Complete diamond pad cut, leveling, chemical crystallization and high-gloss sealing.',
      ),
      ServiceModel(
        id: 'svc_2',
        title: 'Marble Polishing & Restoration- Halls & Corridors',
        defaultUnit: 'Sq. Ft.',
        standardCompanyRate: 45.0,
        description: 'High-traffic commercial floor restoration with scratch removal and Italian wax polish.',
      ),
      ServiceModel(
        id: 'svc_3',
        title: 'Carpet Deep Cleaning & Shampooing',
        defaultUnit: 'Sq. Ft.',
        standardCompanyRate: 15.0,
        description: 'Industrial hot-water extraction, antimicrobial shampooing and rapid fiber drying.',
      ),
      ServiceModel(
        id: 'svc_4',
        title: 'Washroom Deep Cleaning & Sanitization',
        defaultUnit: 'Washroom',
        standardCompanyRate: 3500.0,
        description: 'Descaling fixtures, steam sterilization, grouting whitening and odor elimination.',
      ),
      ServiceModel(
        id: 'svc_5',
        title: 'Commercial Kitchen Degreasing & Steam Treatment',
        defaultUnit: 'Per Unit',
        standardCompanyRate: 12000.0,
        description: 'Exhaust hood degreasing, stainless steel buffing and floor scrubbing.',
      ),
      ServiceModel(
        id: 'svc_6',
        title: 'Façade Glass High-Rise Jet Wash',
        defaultUnit: 'Sq. Ft.',
        standardCompanyRate: 18.0,
        description: 'Exterior spider-rig wash with demineralized spot-free water technology.',
      ),
    ]);

    // 3. Users & Staff Roster
    _users.addAll([
      UserModel(
        id: 'usr_1',
        employeeId: 'SP-101',
        fullName: 'Amir Nawaz',
        role: 'Manager Sales',
        phone: '+92 300 7711223',
        status: 'Active',
      ),
      UserModel(
        id: 'usr_2',
        employeeId: 'SP-102',
        fullName: 'Muhammad Usman',
        role: 'Field Supervisor',
        phone: '+92 321 8822334',
        status: 'Active',
      ),
      UserModel(
        id: 'usr_3',
        employeeId: 'SP-103',
        fullName: 'Rashid Ali',
        role: 'Floor Specialist / Lead',
        phone: '+92 333 9933445',
        status: 'Active',
      ),
      UserModel(
        id: 'usr_4',
        employeeId: 'SP-104',
        fullName: 'Hamza Khan',
        role: 'Equipment Operator',
        phone: '+92 312 6644556',
        status: 'Active',
      ),
      UserModel(
        id: 'usr_5',
        employeeId: 'SP-105',
        fullName: 'Kamran Shah',
        role: 'Quality Assurance Inspector',
        phone: '+92 345 5566778',
        status: 'On Leave',
      ),
      UserModel(
        id: 'usr_6',
        employeeId: 'SP-106',
        fullName: 'Zahid Hussain',
        role: 'Deep Cleaning Technician',
        phone: '+92 301 4433221',
        status: 'Active',
      ),
    ]);

    // 4. Dynamic Custom Lists Seed (Company Assets & Chemical Inventory)
    final assetsSchema = CustomListSchema(
      id: 'schema_assets',
      listName: 'company_assets',
      displayName: 'Company Assets & Equipment',
      description: 'Heavy machinery, generators, single-disc polishers and extractors',
      iconName: 'precision_manufacturing',
      fields: [
        CustomFieldDefinition(name: 'asset_tag', label: 'Asset Tag', type: CustomFieldType.text, isRequired: true),
        CustomFieldDefinition(name: 'machine_model', label: 'Machine Model / Brand', type: CustomFieldType.text, isRequired: true),
        CustomFieldDefinition(name: 'assigned_branch', label: 'Assigned Branch', type: CustomFieldType.text),
        CustomFieldDefinition(name: 'purchase_date', label: 'Purchase Date', type: CustomFieldType.date),
        CustomFieldDefinition(
          name: 'condition',
          label: 'Condition / Status',
          type: CustomFieldType.status,
          options: ['Operational', 'Needs Maintenance', 'Under Repair', 'Decommissioned'],
        ),
      ],
    );

    final chemicalSchema = CustomListSchema(
      id: 'schema_chemicals',
      listName: 'chemical_inventory',
      displayName: 'Chemicals & Consumables',
      description: 'Diamond crystallization fluids, sealing waxes, and concentrated degreasers',
      iconName: 'science',
      fields: [
        CustomFieldDefinition(name: 'sku_code', label: 'SKU / Batch Code', type: CustomFieldType.text, isRequired: true),
        CustomFieldDefinition(name: 'item_name', label: 'Product Name', type: CustomFieldType.text, isRequired: true),
        CustomFieldDefinition(name: 'unit', label: 'Packaging Unit', type: CustomFieldType.text),
        CustomFieldDefinition(name: 'stock_quantity', label: 'In-Stock Quantity', type: CustomFieldType.number),
        CustomFieldDefinition(
          name: 'stock_status',
          label: 'Inventory Status',
          type: CustomFieldType.status,
          options: ['In Stock', 'Low Stock', 'Reordered', 'Out of Stock'],
        ),
      ],
    );

    _customSchemas.addAll([assetsSchema, chemicalSchema]);

    // 5. Dynamic Custom Records Seed
    _customRecords['company_assets'] = [
      CustomRecord(
        id: 'rec_asset_1',
        listName: 'company_assets',
        data: {
          'asset_tag': 'SP-POL-01',
          'machine_model': 'Klindex Levighetor 640 Italian Polisher',
          'assigned_branch': 'Lahore Hub',
          'purchase_date': '2025-03-12',
          'condition': 'Operational',
        },
      ),
      CustomRecord(
        id: 'rec_asset_2',
        listName: 'company_assets',
        data: {
          'asset_tag': 'SP-EXT-04',
          'machine_model': 'Kärcher Puzzi 10/1 Spray-Extraction',
          'assigned_branch': 'Faisalabad Hub',
          'purchase_date': '2025-06-18',
          'condition': 'Operational',
        },
      ),
      CustomRecord(
        id: 'rec_asset_3',
        listName: 'company_assets',
        data: {
          'asset_tag': 'SP-SCR-02',
          'machine_model': 'Nilfisk Viper Floor Scrubber Dryer',
          'assigned_branch': 'Islamabad Depot',
          'purchase_date': '2024-11-05',
          'condition': 'Needs Maintenance',
        },
      ),
    ];

    _customRecords['chemical_inventory'] = [
      CustomRecord(
        id: 'rec_chem_1',
        listName: 'chemical_inventory',
        data: {
          'sku_code': 'CHEM-CRY-01',
          'item_name': 'Bellinzoni K2 Liquid Crystallizer',
          'unit': '5 Liter Canister',
          'stock_quantity': 45,
          'stock_status': 'In Stock',
        },
      ),
      CustomRecord(
        id: 'rec_chem_2',
        listName: 'chemical_inventory',
        data: {
          'sku_code': 'CHEM-PAD-03',
          'item_name': 'Twister Diamond Polishing Disc #3000',
          'unit': 'Box of 10 Discs',
          'stock_quantity': 8,
          'stock_status': 'Low Stock',
        },
      ),
      CustomRecord(
        id: 'rec_chem_3',
        listName: 'chemical_inventory',
        data: {
          'sku_code': 'CHEM-DEG-02',
          'item_name': 'Industrial Alkaline Kitchen Degreaser',
          'unit': '20 Liter Drum',
          'stock_quantity': 32,
          'stock_status': 'In Stock',
        },
      ),
    ];
  }

  // --- Real-Time Firestore Synchronization ---
  void _initFirestoreSync() {
    final fb = FirebaseService.instance;
    final fs = fb.firestore;
    if (fs == null) return;

    try {
      // 1. Clients listener (`/master_clients` and `/clients`)
      _clientsSub = fs.collection('master_clients').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final cloudClients = snapshot.docs.map((doc) => ClientModel.fromMap(doc.data(), doc.id)).toList();
          _clients.clear();
          _clients.addAll(cloudClients);
          notifyListeners();
        }
      }, onError: (e) => debugPrint('[MasterData] Master Clients sync notice: $e'));

      // 2. Services listener (`/master_services` and `/services`)
      _servicesSub = fs.collection('master_services').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final cloudServices = snapshot.docs.map((doc) => ServiceModel.fromMap(doc.data(), doc.id)).toList();
          _services.clear();
          _services.addAll(cloudServices);
          notifyListeners();
        }
      }, onError: (e) => debugPrint('[MasterData] Master Services sync notice: $e'));

      // 3. Users listener (`/master_users` and `/users`)
      _usersSub = fs.collection('master_users').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final cloudUsers = snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
          _users.clear();
          _users.addAll(cloudUsers);
          notifyListeners();
        }
      }, onError: (e) => debugPrint('[MasterData] Master Users sync notice: $e'));

      // 4. Custom Lists Meta listener (`/custom_lists_meta`)
      _schemasSub = fs.collection('custom_lists_meta').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final cloudSchemas = snapshot.docs.map((doc) => CustomListSchema.fromMap(doc.data(), doc.id)).toList();
          _customSchemas.clear();
          _customSchemas.addAll(cloudSchemas);
          for (final schema in _customSchemas) {
            _listenToCustomRecords(schema.listName);
          }
          notifyListeners();
        }
      }, onError: (e) => debugPrint('[MasterData] Custom Lists Meta sync notice: $e'));

      // Listen to initially configured schemas
      for (final schema in _customSchemas) {
        _listenToCustomRecords(schema.listName);
      }
    } catch (e) {
      debugPrint('[MasterData] Firestore sync initialization error: $e');
    }
  }

  void _listenToCustomRecords(String listName) {
    if (_recordsSubs.containsKey(listName)) return;
    final fs = FirebaseService.instance.firestore;
    if (fs == null) return;

    try {
      final sub = fs.collection('custom_lists_data_$listName').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final records = snapshot.docs.map((doc) => CustomRecord.fromMap(doc.data(), doc.id)).toList();
          _customRecords[listName] = records;
          notifyListeners();
        }
      }, onError: (e) => debugPrint('[MasterData] Record sync error for $listName: $e'));
      _recordsSubs[listName] = sub;
    } catch (e) {
      debugPrint('[MasterData] Error setting up record listener for $listName: $e');
    }
  }

  // ==================== CLIENTS CRUD ====================

  Future<void> saveClient(ClientModel client) async {
    final idx = _clients.indexWhere((c) => c.id == client.id);
    if (idx != -1) {
      _clients[idx] = client;
    } else {
      _clients.insert(0, client);
    }
    notifyListeners();

    final fs = FirebaseService.instance.firestore;
    if (fs != null) {
      try {
        await fs.collection('master_clients').doc(client.id).set(client.toMap());
        // Mirror to fallback collections
        await fs.collection('clients').doc(client.id).set(client.toMap());
      } catch (e) {
        debugPrint('[MasterData] Firestore saveClient failed: $e');
      }
    }
  }

  Future<void> deleteClient(String id) async {
    _clients.removeWhere((c) => c.id == id);
    notifyListeners();

    final fs = FirebaseService.instance.firestore;
    if (fs != null) {
      try {
        await fs.collection('master_clients').doc(id).delete();
        await fs.collection('clients').doc(id).delete();
      } catch (e) {
        debugPrint('[MasterData] Firestore deleteClient failed: $e');
      }
    }
  }

  // ==================== SERVICES CRUD ====================

  Future<void> saveService(ServiceModel service) async {
    final idx = _services.indexWhere((s) => s.id == service.id);
    if (idx != -1) {
      _services[idx] = service;
    } else {
      _services.insert(0, service);
    }
    notifyListeners();

    final fs = FirebaseService.instance.firestore;
    if (fs != null) {
      try {
        await fs.collection('master_services').doc(service.id).set(service.toMap());
        await fs.collection('services').doc(service.id).set(service.toMap());
      } catch (e) {
        debugPrint('[MasterData] Firestore saveService failed: $e');
      }
    }
  }

  Future<void> deleteService(String id) async {
    _services.removeWhere((s) => s.id == id);
    notifyListeners();

    final fs = FirebaseService.instance.firestore;
    if (fs != null) {
      try {
        await fs.collection('master_services').doc(id).delete();
        await fs.collection('services').doc(id).delete();
      } catch (e) {
        debugPrint('[MasterData] Firestore deleteService failed: $e');
      }
    }
  }

  // ==================== USERS & STAFF CRUD ====================

  Future<void> saveUser(UserModel user) async {
    final idx = _users.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      _users[idx] = user;
    } else {
      _users.insert(0, user);
    }
    notifyListeners();

    final fs = FirebaseService.instance.firestore;
    if (fs != null) {
      try {
        await fs.collection('master_users').doc(user.id).set(user.toMap());
        await fs.collection('users').doc(user.id).set(user.toMap());
      } catch (e) {
        debugPrint('[MasterData] Firestore saveUser failed: $e');
      }
    }
  }

  Future<void> saveStaffUser(StaffUserModel user) => saveUser(user);

  Future<void> deleteUser(String id) async {
    _users.removeWhere((u) => u.id == id);
    notifyListeners();

    final fs = FirebaseService.instance.firestore;
    if (fs != null) {
      try {
        await fs.collection('master_users').doc(id).delete();
        await fs.collection('users').doc(id).delete();
      } catch (e) {
        debugPrint('[MasterData] Firestore deleteUser failed: $e');
      }
    }
  }

  Future<void> deleteStaffUser(String id) => deleteUser(id);

  // ==================== DYNAMIC CUSTOM LIST SCHEMAS ====================

  Future<void> saveCustomListSchema(CustomListSchema schema) async {
    final idx = _customSchemas.indexWhere((s) => s.listName == schema.listName || s.id == schema.id);
    if (idx != -1) {
      _customSchemas[idx] = schema;
    } else {
      _customSchemas.add(schema);
    }
    _listenToCustomRecords(schema.listName);
    notifyListeners();

    final fs = FirebaseService.instance.firestore;
    if (fs != null) {
      try {
        await fs.collection('custom_lists_meta').doc(schema.listName).set(schema.toMap());
      } catch (e) {
        debugPrint('[MasterData] Firestore saveCustomListSchema failed: $e');
      }
    }
  }

  Future<void> deleteCustomListSchema(String listName) async {
    _customSchemas.removeWhere((s) => s.listName == listName);
    _customRecords.remove(listName);
    _recordsSubs[listName]?.cancel();
    _recordsSubs.remove(listName);
    notifyListeners();

    final fs = FirebaseService.instance.firestore;
    if (fs != null) {
      try {
        await fs.collection('custom_lists_meta').doc(listName).delete();
      } catch (e) {
        debugPrint('[MasterData] Firestore deleteCustomListSchema failed: $e');
      }
    }
  }

  // ==================== DYNAMIC CUSTOM RECORDS ====================

  Future<void> saveCustomRecord(CustomRecord record) async {
    final list = _customRecords.putIfAbsent(record.listName, () => []);
    final idx = list.indexWhere((r) => r.id == record.id);
    if (idx != -1) {
      list[idx] = record;
    } else {
      list.insert(0, record);
    }
    notifyListeners();

    final fs = FirebaseService.instance.firestore;
    if (fs != null) {
      try {
        await fs.collection('custom_lists_data_${record.listName}').doc(record.id).set(record.toMap());
      } catch (e) {
        debugPrint('[MasterData] Firestore saveCustomRecord failed: $e');
      }
    }
  }

  Future<void> deleteCustomRecord(String listName, String recordId) async {
    final list = _customRecords[listName];
    if (list != null) {
      list.removeWhere((r) => r.id == recordId);
      notifyListeners();
    }

    final fs = FirebaseService.instance.firestore;
    if (fs != null) {
      try {
        await fs.collection('custom_lists_data_$listName').doc(recordId).delete();
      } catch (e) {
        debugPrint('[MasterData] Firestore deleteCustomRecord failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _clientsSub?.cancel();
    _servicesSub?.cancel();
    _usersSub?.cancel();
    _schemasSub?.cancel();
    for (final sub in _recordsSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
