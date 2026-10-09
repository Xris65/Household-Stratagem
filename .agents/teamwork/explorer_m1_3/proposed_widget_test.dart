import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_stratagem/main.dart';

void main() {
  testWidgets('HouseholdStratagemApp smoke test mounts cleanly', (WidgetTester tester) async {
    // Build root app widget and trigger a frame.
    await tester.pumpWidget(HouseholdStratagemApp());

    // Verify MaterialApp mounts properly
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify initial screen content is rendered
    expect(find.text('STRATAGEM DEPLOYMENT'), findsOneWidget);
    expect(find.text('ENTER STRATAGEM CODE'), findsOneWidget);
  });
}
