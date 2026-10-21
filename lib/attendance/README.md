# Attendance & Shift Verification Module (`lib/features/attendance/`)

A modular, production-ready, and fully exportable **Attendance & Shift Verification Module** for Flutter. This feature folder is 100% decoupled and can be dropped directly into any Flutter mobile application.

---

## 🌟 Key Features

1. **Sequential Clock-In Evidence Capture Flow:**
   - **Step 1 (Front Camera):** Verification selfie of the employee.
   - **Step 2 (Back Camera):** Snapshot of the work site or customer environment.
   - **Step 3 (GPS Location Fetch):** Captures high-accuracy coordinates (Latitude, Longitude) and reverse-geocodes them to a human-readable address (Street, Area, City, Province).
   - **Step 4 (Timestamping):** Records the exact date and clock-in timestamp.

2. **Live Shift Duration Timer & Limit Alerts:**
   - Real-time continuous shift timer updating in `HH:MM:SS`.
   - **Standard Shift Target (8 Hours):** Visual green progress bar toward the 8-hour shift goal.
   - **Overtime Alert (8 to 10 Hours):** Transitions to amber warning state with overtime badge.
   - **Maximum Threshold Exceeded (>10 Hours):** Transitions to critical red alert with pulsating badge urging clock out.

3. **Active Shift Summary Card (Structured 3-Section Partition):**
   - **Section 1: Dual Camera Snapshots:** Side-by-side or split visual frame displaying the Front Selfie and Back Site snapshot with tap-to-zoom modal preview.
   - **Section 2: GPS Location Details:** Map pin icon, reverse-geocoded readable address, city, and GPS coordinates (Latitude / Longitude).
   - **Section 3: Date, Time & Live Shift Clock:** Clock-in date/time, live running timer, 8–10 hour visual progress bar, and "Clock Out / End Shift" button with optional shift handover notes.

4. **Historical Shift Verification Logs:**
   - Saved history of past completed shifts sorted with newest first.
   - Tap any past shift to inspect full verification evidence, dual photos, GPS address, and duration logs.

5. **Built-in QA & Testing Simulator:**
   - AppBar beaker icon opens a simulation menu to fast-forward active shifts to:
     - 15 mins (Normal)
     - 8 hrs 35 mins (Overtime warning)
     - 10 hrs 15 mins (Maximum limit exceeded alert)
   - Enables instant QA testing and client demos without waiting 8 hours.

6. **Zero-Crash Emulator & Hardware Fallback:**
   - Automatic graceful fallback generating simulated verification photos and valid location coordinates if camera or GPS hardware is unavailable or permissions are denied on test devices.

---

## 📁 File Structure

```
lib/features/attendance/
├── attendance.dart                 # Barrel export file for the feature
├── README.md                       # Integration documentation & guide
├── models/
│   └── attendance_record.dart      # Attendance data model, calculations & serialization
├── services/
│   ├── attendance_service.dart     # Singleton ChangeNotifier state manager
│   ├── camera_service.dart         # Camera initialization & mock capture fallback
│   └── location_service.dart       # GPS geolocator & reverse-geocoding service
├── widgets/
│   ├── active_shift_card.dart      # 3-section Active Shift Summary Card widget
│   └── camera_capture_dialog.dart  # Multi-step sequential clock-in modal wizard
└── screens/
    └── attendance_screen.dart      # Main attendance dashboard & shift history screen
```

---

## 🚀 How to Drop into Another Project

### Step 1: Add Dependencies
In your destination project's `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: ^0.12.1
  geolocator: ^14.1.1
  geocoding: ^5.0.0
  intl: ^0.20.3
```
Then run:
```bash
flutter pub get
```

### Step 2: Copy the Feature Folder
Copy `lib/features/attendance/` directly into your destination project's `lib/features/` directory.

### Step 3: Configure Native Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Camera Permissions -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.front" android:required="false" />

    <!-- Location Permissions -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    ...
```

#### iOS (`ios/Runner/Info.plist`):
```xml
<dict>
    <key>NSCameraUsageDescription</key>
    <string>Camera access is required for employee identity selfie and work site verification.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Location access is required to verify the employee work site during clock-in.</string>
    ...
```

---

## 💻 Code Usage Examples

### 1. Open the Full Attendance Dashboard
```dart
import 'package:your_app/features/attendance/attendance.dart';

Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const AttendanceScreen(
      defaultEmployeeName: 'Amir Nawaz',
      defaultEmployeeId: 'SP-101',
    ),
  ),
);
```

### 2. Embed the 3-Section Active Shift Card into Any Custom Screen
```dart
import 'package:your_app/features/attendance/attendance.dart';

ListenableBuilder(
  listenable: AttendanceService.instance,
  builder: (context, _) {
    final activeShift = AttendanceService.instance.activeShift;
    if (activeShift == null) {
      return const Text("No active shift.");
    }
    return ActiveShiftCard(
      record: activeShift,
      onClockOut: () => AttendanceService.instance.clockOut(),
    );
  },
);
```

### 3. Programmatically Trigger Sequential Clock-In
```dart
import 'package:your_app/features/attendance/attendance.dart';

final result = await showClockInVerificationModal(
  context: context,
  initialEmployeeName: 'Junaid Imran',
  initialEmployeeId: 'SP-204',
);

if (result != null) {
  AttendanceService.instance.clockIn(
    employeeName: result['employee_name'],
    employeeId: result['employee_id'],
    frontCapture: result['front_capture'],
    backCapture: result['back_capture'],
    location: result['location'],
  );
}
```

