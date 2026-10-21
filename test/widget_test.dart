import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shineplusinvoice/quotations/quotations.dart';

void main() {
  testWidgets('Formal Quotation Details renders correctly and shows draft versioning', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(
        home: QuotationDetailScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Header
    expect(find.text('Formal Quotation Details'), findsOneWidget);
    expect(find.text('LHR/SEP/354-4'), findsAtLeastNWidgets(1));

    // Verify Client Info
    expect(find.text('Mr. Junaid Imran'), findsOneWidget);
    expect(find.text('Circle Club'), findsOneWidget);

    // Verify Line Items
    expect(find.text('Marble Cutting, Gridding & Polishing- Mosques'), findsOneWidget);

    // Verify Grand Total
    expect(find.text('PKR 361,880'), findsOneWidget);
  });
}
