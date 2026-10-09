import 'package:flutter_test/flutter_test.dart';
import 'package:household_stratagem/screens/auth_gate.dart';
import 'package:household_stratagem/services/auth_service.dart';
import 'package:household_stratagem/services/household_repository.dart';
import 'package:household_stratagem/models/user_profile.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Returning users skip onboarding', (tester) async {
    final auth = FakeAuthService(initialUserId: 'user1');
    final repo = InMemoryHouseholdRepository(initialProfiles: {
      'user1': UserProfile(userId: 'user1', onboarded: true),
    });

    await tester.pumpWidget(MaterialApp(
      home: AuthGate(authService: auth, householdRepo: repo),
    ));

    await tester.pumpAndSettle();

    expect(find.text('CONFIGURATION'), findsNothing); // or something from onboarding
    // check if it's on HomeScreen
  });
}
