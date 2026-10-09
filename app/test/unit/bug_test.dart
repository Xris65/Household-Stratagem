import 'package:flutter_test/flutter_test.dart';
import 'package:household_stratagem/models/user_profile.dart';

void main() {
  test('UserProfile toMap and fromMap', () {
    final profile = UserProfile(
      userId: '123',
      agentName: 'Test',
      level: 1,
      onboarded: true,
    );
    final map = profile.toMap();
    print('Map: $map');
    
    final restored = UserProfile.fromMap(map, '123');
    print('Restored: $restored');
    expect(restored.onboarded, true);
  });
}
