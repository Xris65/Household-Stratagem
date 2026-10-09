import 'package:flutter_test/flutter_test.dart';
import 'package:household_stratagem/models.dart';

void main() {
  group('Chore Model Tests', () {
    test('instantiates with required fields and verifies backward-compatible defaults', () {
      final chore = Chore(
        id: 'chore_1',
        name: 'Passer la serpillière',
        difficulty: 3,
      );

      expect(chore.id, equals('chore_1'));
      expect(chore.name, equals('Passer la serpillière'));
      expect(chore.difficulty, equals(3));
      expect(chore.lastCompletedAt, isNull);
      expect(chore.periodicityDays, isPositive);
    });

    test('instantiates with all fields populated', () {
      final completedTime = DateTime(2026, 10, 1, 14, 30);
      final chore = Chore(
        id: 'chore_full',
        name: 'Dégraisser la hotte',
        room: 'Cuisine',
        difficulty: 4,
        periodicityDays: 14,
        lastCompletedAt: completedTime,
        stratagemSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP'],
        isDefault: true,
      );

      expect(chore.id, equals('chore_full'));
      expect(chore.name, equals('Dégraisser la hotte'));
      expect(chore.room, equals('Cuisine'));
      expect(chore.difficulty, equals(4));
      expect(chore.periodicityDays, equals(14));
      expect(chore.lastCompletedAt, equals(completedTime));
      expect(chore.stratagemSequence, equals(['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP']));
      expect(chore.isDefault, isTrue);
    });

    test('serializes toMap and deserializes fromMap with fidelity (roundtrip)', () {
      final completedTime = DateTime(2026, 10, 2, 8, 15);
      final original = Chore(
        id: 'chore_roundtrip',
        name: 'Nettoyer le miroir',
        room: 'Salle de bain',
        difficulty: 2,
        periodicityDays: 7,
        lastCompletedAt: completedTime,
        stratagemSequence: ['LEFT', 'RIGHT', 'UP', 'DOWN', 'DOWN'],
        isDefault: false,
      );

      final map = original.toMap();
      expect(map['id'], equals('chore_roundtrip'));
      expect(map['name'], equals('Nettoyer le miroir'));
      expect(map['room'], equals('Salle de bain'));
      expect(map['difficulty'], equals(2));
      expect(map['periodicityDays'], equals(7));
      expect(map['stratagemSequence'], equals(['LEFT', 'RIGHT', 'UP', 'DOWN', 'DOWN']));
      expect(map['isDefault'], isFalse);

      final restored = Chore.fromMap(map, original.id);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.room, equals(original.room));
      expect(restored.difficulty, equals(original.difficulty));
      expect(restored.periodicityDays, equals(original.periodicityDays));
      expect(restored.lastCompletedAt?.millisecondsSinceEpoch,
          equals(original.lastCompletedAt?.millisecondsSinceEpoch));
      expect(restored.stratagemSequence, equals(original.stratagemSequence));
      expect(restored.isDefault, equals(original.isDefault));
    });

    test('serializes and deserializes null lastCompletedAt cleanly', () {
      final original = Chore(
        id: 'chore_never_done',
        name: 'Dépoussiérer les plinthes',
        room: 'Salon',
        difficulty: 1,
        periodicityDays: 30,
        lastCompletedAt: null,
      );

      final map = original.toMap();
      final restored = Chore.fromMap(map);

      expect(restored.lastCompletedAt, isNull);
      expect(restored.id, equals('chore_never_done'));
    });

    test('copyWith updates specified fields while retaining others', () {
      final original = Chore(
        id: 'c1',
        name: 'Vider le lave-vaisselle',
        room: 'Cuisine',
        difficulty: 1,
        periodicityDays: 1,
        lastCompletedAt: null,
        stratagemSequence: ['UP', 'UP', 'DOWN', 'DOWN', 'LEFT'],
        isDefault: true,
      );

      final newTime = DateTime(2026, 10, 4, 10, 0);
      final updated = original.copyWith(
        name: 'Vider et recharger le lave-vaisselle',
        lastCompletedAt: newTime,
        periodicityDays: 2,
      );

      expect(updated.id, equals('c1'));
      expect(updated.name, equals('Vider et recharger le lave-vaisselle'));
      expect(updated.room, equals('Cuisine'));
      expect(updated.difficulty, equals(1));
      expect(updated.periodicityDays, equals(2));
      expect(updated.lastCompletedAt, equals(newTime));
      expect(updated.stratagemSequence, equals(['UP', 'UP', 'DOWN', 'DOWN', 'LEFT']));
      expect(updated.isDefault, isTrue);
    });
  });

  group('MissionLog Model Tests', () {
    test('instantiates with required fields', () {
      final now = DateTime(2026, 10, 4, 12, 0);
      final log = MissionLog(
        choreId: 'chore_10',
        completedAt: now,
        success: true,
      );

      expect(log.choreId, equals('chore_10'));
      expect(log.completedAt, equals(now));
      expect(log.success, isTrue);
    });

    test('roundtrip serialization via toMap and fromMap', () {
      final now = DateTime(2026, 10, 4, 13, 0);
      final log = MissionLog(
        choreId: 'chore_10',
        completedAt: now,
        success: false,
      );

      final map = log.toMap();
      final restored = MissionLog.fromMap(map);

      expect(restored.choreId, equals(log.choreId));
      expect(restored.success, isFalse);
      expect(restored.completedAt.millisecondsSinceEpoch,
          equals(log.completedAt.millisecondsSinceEpoch));
    });
  });

  group('UserProfile Model Tests', () {
    test('instantiates and verifies default fields', () {
      final created = DateTime(2026, 10, 1, 10, 0);
      final profile = UserProfile(
        userId: 'user_abc_123',
        email: 'nettoyeur@helldivers.fr',
        createdAt: created,
      );

      expect(profile.userId, equals('user_abc_123'));
      expect(profile.email, equals('nettoyeur@helldivers.fr'));
      expect(profile.isOnboarded, isFalse);
      expect(profile.createdAt, equals(created));
    });

    test('roundtrip serialization via toMap and fromMap', () {
      final created = DateTime(2026, 10, 1, 10, 0);
      final profile = UserProfile(
        userId: 'user_xyz',
        email: 'commander@cleaning.org',
        isOnboarded: true,
        selectedAudioTrack: 'tactical_ambiance_2.mp3',
        createdAt: created,
      );

      final map = profile.toMap();
      final restored = UserProfile.fromMap(map);

      expect(restored.userId, equals('user_xyz'));
      expect(restored.email, equals('commander@cleaning.org'));
      expect(restored.isOnboarded, isTrue);
      expect(restored.selectedAudioTrack, equals('tactical_ambiance_2.mp3'));
      expect(restored.createdAt.millisecondsSinceEpoch,
          equals(profile.createdAt.millisecondsSinceEpoch));
    });

    test('copyWith updates onboarding state', () {
      final profile = UserProfile(
        userId: 'user_new',
        email: 'recruit@cleaning.org',
        isOnboarded: false,
        createdAt: DateTime.now(),
      );

      final updated = profile.copyWith(isOnboarded: true);
      expect(updated.isOnboarded, isTrue);
      expect(updated.userId, equals('user_new'));
    });
  });

  group('RoomCategory Tests', () {
    test('contains the 4 required standard cleaning rooms', () {
      const expectedRooms = ['Cuisine', 'Salle de bain', 'Salon', 'Chambre'];
      expect(RoomCategory.all, containsAll(expectedRooms));
      expect(RoomCategory.all.length, equals(4));
      expect(RoomCategory.rooms, equals(RoomCategory.all));
    });

    test('default chores catalogue contains 17 chores across the 4 rooms with 5-8 swipe sequences', () {
      final chores = RoomCategory.defaultChores;
      expect(chores.length, equals(17));

      for (final chore in chores) {
        expect(RoomCategory.isValid(chore.room), isTrue);
        expect(chore.stratagemSequence.length, inInclusiveRange(5, 8));
        expect(chore.isDefault, isTrue);
      }
    });
  });
}
