import 'package:flutter/material.dart';
import 'quotations/quotations.dart';
import 'attendance/attendance.dart';
import 'features/master_data/master_data.dart';

export 'quotations/quotations.dart';
export 'attendance/attendance.dart';
export 'features/master_data/master_data.dart';

void main() {
  runApp(const MyApp());
}

/// Root Application Widget with Material 3 styling & Deep Link routing
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB), // Professional royal blue
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Formal Quotation & Invoice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/quotations': (context) => const QuotationsDashboardScreen(),
        '/quotations/editor': (context) => const QuotationDetailScreen(),
        '/attendance': (context) => const AttendanceScreen(),
        '/master-data': (context) => const MasterDataHubScreen(),
        '/master-data/clients': (context) => const ClientsScreen(),
        '/master-data/services': (context) => const ServicesScreen(),
        '/master-data/users': (context) => const UsersStaffScreen(),
      },
    );
  }
}
