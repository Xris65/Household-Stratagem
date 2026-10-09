import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_stratagem/main.dart';
import 'package:household_stratagem/services/auth_service.dart';
import 'package:household_stratagem/services/household_repository.dart';
import 'package:household_stratagem/theme/theme_manager.dart';

void main() {
  testWidgets('HouseholdStratagemApp smoke test mounts cleanly',
      (WidgetTester tester) async {
    // Build root app widget and trigger a frame.
    await tester.pumpWidget(HouseholdStratagemApp(
      authService: FakeAuthService(),
      householdRepo: InMemoryHouseholdRepository(),
      themeManager: ThemeManager(),
    ));

    // Verify MaterialApp mounts properly
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify initial screen content is rendered
    expect(find.text('HOUSEHOLD STRATAGEM'), findsOneWidget);
    expect(find.text('INITIALISATION DU SYSTÈME...'), findsOneWidget);
  });
}
