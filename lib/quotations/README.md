# Quotations Module for Flutter (Material 3)

A fully self-contained, responsive, clean, and modern **Quotations Management Module** built for Flutter. This folder is structured so you can copy and drop the entire `quotations/` folder directly into any other Flutter application without any external package dependencies.

---

## 📁 Directory Structure

```text
quotations/
├── models/
│   └── quotation_model.dart             # Quotation entity with serialization (JSON/Map)
├── services/
│   └── quotation_service.dart           # Business logic: sorting, filtering, ID generation, formatters
├── widgets/
│   ├── quotation_card.dart              # Material 3 list tile card widget
│   ├── quotation_form_sheet.dart        # Create & edit modal bottom sheet
│   └── delete_confirmation_dialog.dart  # Safety delete confirmation alert dialog
├── screens/
│   └── quotations_dashboard_screen.dart # Main quotations dashboard screen
├── quotations.dart                      # Barrel export file for easy single-line import
└── README.md                            # Documentation and integration guide (this file)
```

---

## 🚀 How to Move & Use in Another App

### Step 1: Copy Folder
Copy the entire `quotations/` folder into your destination Flutter project's `lib/` directory:
```text
your_app/lib/quotations/
```

### Step 2: Zero Dependencies
This module uses pure Flutter Material 3 widgets and standard Dart utilities. You **do not** need to add any third-party packages to your `pubspec.yaml`.

### Step 3: Single Import
Import the module via the barrel file:
```dart
import 'package:your_app_name/quotations/quotations.dart';
```

### Step 4: Show the Screen
```dart
// As your home screen:
home: const QuotationsDashboardScreen(),

// Or via Navigator:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const QuotationsDashboardScreen(),
  ),
);
```

---

## 🛠️ Detailed Functions & Classes Reference

### 1. Model: `quotation_model.dart`

Represents a single quotation record.

| Property | Type | Description |
| :--- | :--- | :--- |
| `id` | `String` | Unique identifier (e.g. `'QT-1001'`). |
| `clientName` | `String` | Client or company name. |
| `amount` | `double` | Total quotation amount. |
| `createdAt` | `DateTime` | Timestamp of creation. |

#### Methods:
- **`copyWith(...)`**: Creates an updated copy of the quotation without mutating the original.
- **`toMap()`**: Serializes the quotation into a `Map<String, dynamic>`. Perfect for SQLite, Hive, Firebase Firestore, or `jsonEncode`.
- **`Quotation.fromMap(Map<String, dynamic> map)`**: Factory constructor to reconstruct a `Quotation` from a database query or REST API response.

---

### 2. Business Logic: `quotation_service.dart`

Encapsulates all calculations, formatting, sorting, and data operations so they are separated from the UI widgets.

| Function | Type | Description |
| :--- | :--- | :--- |
| `generateNextId()` | Instance | Auto-increments and returns the next unique ID (e.g. `QT-1006`). |
| `syncCounterWithList(list)` | Instance | Scans an existing list of quotations and synchronizes the auto-increment counter to avoid duplicate IDs. |
| `filterAndSort(...)` | Instance | Filters quotations by Client Name or ID (case-insensitive) and sorts chronologically descending (newest date first). |
| `createQuotation(...)` | Instance | Instantiates a new `Quotation` with auto-assigned ID and timestamp. |
| `QuotationService.formatCurrency(double)` | Static | Formats numbers to currency strings (e.g. `3450.75` ➔ `"$3,450.75"`) without requiring `intl`. |
| `QuotationService.formatDate(DateTime)` | Static | Formats a `DateTime` into `YYYY-MM-DD` (e.g. `"2026-09-30"`). |
| `QuotationService.getMockQuotations()` | Static | Returns 5 realistic mock quotations for instant previews and test environments. |

---

### 3. Screen: `quotations_dashboard_screen.dart`

The complete Material 3 dashboard screen.

#### Features:
- **Screen Title**: "Quotations Dashboard".
- **Delete Mode Safety Switch**: Toggle in the AppBar.
  - When **OFF**: Delete icons are hidden to prevent accidental deletion.
  - When **ON**: Red trash icons appear on each quotation card.
- **Sticky Search Bar**: Pinned at the top with clear (`X`) button and live real-time filtering.
- **Results Counter**: Displays total and matching counts (e.g. `All Quotations (5)` or `Matching (2 of 5)`).
- **Chronological Sorting**: Automatically displays newest quotations at the top.
- **Clean Empty State**: Shows a stylized placeholder and a "Clear Search Filter" button when no results match.
- **Floating Action Button**: Prominent `FloatingActionButton.extended` ("Create Quotation").

#### Optional Constructor Parameter:
```dart
// You can pass an initial list of quotations (e.g., loaded from a database or API):
QuotationsDashboardScreen(
  initialQuotations: myQuotationsFromDatabase,
)
```

---

### 4. Widgets:

#### `quotation_card.dart`
- Component widget that renders a single quotation tile.
- **Leading**: Document/invoice circular avatar with soft blue tint.
- **Title**: Bold 16px client name.
- **Subtitle**: Formatted date + emerald green formatted currency.
- **Trailing**: Monospace accent pill badge showing ID (`QT-1001`) and conditional red delete button.

#### `quotation_form_sheet.dart`
- **`showQuotationFormBottomSheet(...)`**: Displays a Material 3 bottom modal sheet for **Creating** or **Editing** quotations.
- Automatically handles keyboard insets (`MediaQuery.viewInsets`), safe area padding, and form validations (non-empty client name and valid numeric amounts).

#### `delete_confirmation_dialog.dart`
- **`showDeleteConfirmationDialog(...)`**: Displays a styled alert dialog confirming deletion of quotation ID and client name before deleting.

---

## 🔌 Connecting to Backends & Databases

### Example: Saving to SQLite / SharedPreferences / Hive
```dart
// Converting list of quotations to JSON string for local storage:
final jsonList = quotations.map((q) => q.toMap()).toList();
final jsonString = jsonEncode(jsonList);

// Restoring quotations from local storage:
final List<dynamic> raw = jsonDecode(jsonString);
final quotations = raw.map((item) => Quotation.fromMap(item)).toList();
```

### Example: Connecting to Firebase Cloud Firestore
```dart
// Create / Insert:
await FirebaseFirestore.instance
    .collection('quotations')
    .doc(quotation.id)
    .set(quotation.toMap());

// Read / Stream:
FirebaseFirestore.instance
    .collection('quotations')
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => Quotation.fromMap(doc.data())).toList());
```

---

## 🎨 Customizing Styles & Currencies

- **Change Currency Symbol**: Edit `QuotationService.formatCurrency` in `services/quotation_service.dart` to change `$` to `€`, `£`, `₹`, or any currency symbol.
- **Change ID Prefix**: Edit `generateNextId` in `services/quotation_service.dart` to change `QT-` to `INV-`, `EST-`, or any desired prefix.
- **Color Scheme**: The UI automatically adopts your app's `ThemeData` (`Theme.of(context).colorScheme`).
