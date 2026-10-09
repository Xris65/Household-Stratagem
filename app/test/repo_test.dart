import 'package:flutter_test/flutter_test.dart';
import 'package:household_stratagem/models/chore.dart';
import 'package:household_stratagem/services/household_repository.dart';

void main() {
  test('Test saveChores memory', () async {
    final repo = InMemoryHouseholdRepository();
    final chores = [
      Chore(id: 'c1', name: 'Nettoyer le plan de travail', room: 'Cuisine', difficulty: 1, periodicityDays: 1, enabled: true)
    ];
    await repo.saveChores('user1', chores);
    final fetched = await repo.getChores('user1');
    print('Fetched chores: ${fetched.length}');
  });
}
