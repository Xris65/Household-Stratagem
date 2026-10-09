import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:household_stratagem/services/household_repository.dart';
import 'package:household_stratagem/models/user_profile.dart';
import 'package:household_stratagem/models/chore.dart';

void main() {
  test('FirestoreHouseholdRepository correctly saves and loads onboarded status', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    final repo = FirestoreHouseholdRepository(firestore: fakeFirestore);
    
    // 1. Initial State: no user
    var profile = await repo.getUserProfile('test_user');
    expect(profile, isNull, reason: 'Profile should be null initially');
    
    // 2. User created with onboarded: false (like Guest Login)
    var initialProfile = UserProfile(
      userId: 'test_user',
      agentName: 'Test',
      level: 1,
      onboarded: false,
    );
    await repo.saveUserProfile(initialProfile);
    
    // Read back
    profile = await repo.getUserProfile('test_user');
    expect(profile, isNotNull);
    expect(profile!.onboarded, isFalse, reason: 'Profile should not be onboarded');
    
    // 3. User completes Onboarding (like _completeOnboarding in OnboardingScreen)
    final updatedProfile = profile.copyWith(onboarded: true);
    await repo.saveUserProfile(updatedProfile);
    
    // Add some chores so it doesn't fail chores.isNotEmpty check
    await repo.saveChores('test_user', [
      Chore(id: 'c1', name: 'Test Chore', difficulty: 1)
    ]);
    
    // 4. Read back after onboarding
    profile = await repo.getUserProfile('test_user');
    print('Raw Firestore Document: ${(await fakeFirestore.collection('users').doc('test_user').get()).data()}');
    expect(profile, isNotNull);
    expect(profile!.onboarded, isTrue, reason: 'Profile MUST be onboarded now');
    
    // 5. Test AuthGate logic simulation
    final chores = await repo.getChores('test_user');
    final hasCompletedOnboarding = profile.onboarded || chores.isNotEmpty;
    print('hasCompletedOnboarding (logic): $hasCompletedOnboarding');
    expect(hasCompletedOnboarding, isTrue, reason: 'AuthGate logic should allow returning user');
  });
}
