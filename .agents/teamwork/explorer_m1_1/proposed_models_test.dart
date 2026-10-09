import 'package:flutter_test/flutter_test.dart';
import 'package:household_stratagem/models.dart';

void main() {
  group('Chore Model', () {
    test('instantiates with defaults', () {
      final chore = Chore(id: 'c1', name: 'Test Chore', difficulty: 2);
      expect(chore.id, 'c1');
      expect(chore.name, 'Test Chore');
      expect(chore.difficulty, 2);
      expect(chore.room, 'Cuisine');
      expect(chore.periodicityDays, 7);
      expect(chore.lastCompletedAt, isNull);
      expect(chore.stratagemSequence, isEmpty);
      expect(chore.isDefault, isFalse);
    });

    test('instantiates with all custom fields', () {
      final now = DateTime.utc(2026, 10, 4, 12, 0, 0);
      final chore = Chore(
        id: 'c2',
        name: 'Dégraissage',
        room: RoomCategory.cuisine,
        difficulty: 3,
        periodicityDays: 5,
        lastCompletedAt: now,
        stratagemSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP'],
        isDefault: true,
      );

      expect(chore.id, 'c2');
      expect(chore.name, 'Dégraissage');
      expect(chore.room, 'Cuisine');
      expect(chore.difficulty, 3);
      expect(chore.periodicityDays, 5);
      expect(chore.lastCompletedAt, now);
      expect(chore.stratagemSequence, ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP']);
      expect(chore.isDefault, isTrue);
    });

    test('toMap and fromMap serialization round-trip', () {
      final now = DateTime.utc(2026, 10, 4, 12, 0, 0);
      final original = Chore(
        id: 'c3',
        name: 'Détartrage douche',
        room: RoomCategory.salleDeBain,
        difficulty: 4,
        periodicityDays: 14,
        lastCompletedAt: now,
        stratagemSequence: ['DOWN', 'UP', 'LEFT', 'RIGHT', 'DOWN', 'UP'],
        isDefault: true,
      );

      final map = original.toMap();
      expect(map['id'], 'c3');
      expect(map['name'], 'Détartrage douche');
      expect(map['room'], 'Salle de bain');
      expect(map['difficulty'], 4);
      expect(map['periodicityDays'], 14);
      expect(map['lastCompletedAt'], now.toIso8601String());
      expect(map['stratagemSequence'], ['DOWN', 'UP', 'LEFT', 'RIGHT', 'DOWN', 'UP']);
      expect(map['isDefault'], isTrue);

      final restored = Chore.fromMap(map);
      expect(restored, equals(original));
    });

    test('fromMap handles doc id override and timestamp variations', () {
      final map = {
        'name': 'Aspiration',
        'room': 'Salon',
        'difficulty': 2,
        'periodicityDays': 3,
        'lastCompletedAt': 1728043200000, // Epoch milliseconds
        'stratagemSequence': ['LEFT', 'RIGHT', 'UP', 'DOWN', 'UP'],
        'isDefault': false,
      };

      final chore = Chore.fromMap(map, 'doc_123');
      expect(chore.id, 'doc_123');
      expect(chore.name, 'Aspiration');
      expect(chore.lastCompletedAt, DateTime.fromMillisecondsSinceEpoch(1728043200000));
    });

    test('copyWith updates fields correctly and clearLastCompletedAt resets date', () {
      final chore = Chore(
        id: 'c4',
        name: 'Initial',
        difficulty: 1,
        lastCompletedAt: DateTime.now(),
      );

      final updated = chore.copyWith(name: 'Updated', difficulty: 3);
      expect(updated.id, 'c4');
      expect(updated.name, 'Updated');
      expect(updated.difficulty, 3);
      expect(updated.lastCompletedAt, chore.lastCompletedAt);

      final cleared = updated.copyWith(clearLastCompletedAt: true);
      expect(cleared.lastCompletedAt, isNull);
    });

    test('equality and hashCode work as expected', () {
      final c1 = Chore(id: 'c1', name: 'Task', difficulty: 2, stratagemSequence: ['UP', 'DOWN']);
      final c2 = Chore(id: 'c1', name: 'Task', difficulty: 2, stratagemSequence: ['UP', 'DOWN']);
      final c3 = Chore(id: 'c1', name: 'Task', difficulty: 2, stratagemSequence: ['UP', 'UP']);

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });
  });

  group('MissionLog Model', () {
    test('instantiates with defaults and custom values', () {
      final now = DateTime.utc(2026, 10, 4, 14, 0, 0);
      final log = MissionLog(
        id: 'log1',
        choreId: 'c1',
        choreName: 'Nettoyer la cuisine',
        room: 'Cuisine',
        completedAt: now,
        durationSeconds: 450,
        success: true,
      );

      expect(log.id, 'log1');
      expect(log.choreId, 'c1');
      expect(log.choreName, 'Nettoyer la cuisine');
      expect(log.room, 'Cuisine');
      expect(log.completedAt, now);
      expect(log.durationSeconds, 450);
      expect(log.success, isTrue);
    });

    test('toMap and fromMap serialization round-trip', () {
      final now = DateTime.utc(2026, 10, 4, 14, 0, 0);
      final original = MissionLog(
        id: 'log2',
        choreId: 'c2',
        choreName: 'Dépoussiérage',
        room: 'Salon',
        completedAt: now,
        durationSeconds: 300,
        success: true,
      );

      final map = original.toMap();
      final restored = MissionLog.fromMap(map);
      expect(restored, equals(original));
    });

    test('copyWith updates fields', () {
      final log = MissionLog(
        choreId: 'c1',
        completedAt: DateTime.now(),
        success: false,
      );

      final successLog = log.copyWith(success: true, durationSeconds: 600);
      expect(successLog.success, isTrue);
      expect(successLog.durationSeconds, 600);
    });
  });

  group('UserProfile Model', () {
    test('instantiates with defaults and anonymous support', () {
      final profile = UserProfile(userId: 'anon_user_1');
      expect(profile.userId, 'anon_user_1');
      expect(profile.email, isNull);
      expect(profile.isOnboarded, isFalse);
      expect(profile.selectedAudioTrack, 'tactical_ambiance_1.mp3');
      expect(profile.createdAt, isNotNull);
    });

    test('toMap and fromMap serialization round-trip', () {
      final now = DateTime.utc(2026, 10, 4, 10, 0, 0);
      final original = UserProfile(
        userId: 'u123',
        email: 'nettoyeur@foyer.mil',
        isOnboarded: true,
        selectedAudioTrack: 'tactical_ambiance_2.mp3',
        createdAt: now,
      );

      final map = original.toMap();
      final restored = UserProfile.fromMap(map);
      expect(restored, equals(original));
    });

    test('copyWith updates fields', () {
      final profile = UserProfile(userId: 'u1');
      final onboarded = profile.copyWith(
        isOnboarded: true,
        selectedAudioTrack: 'tactical_ambiance_2.mp3',
      );
      expect(onboarded.isOnboarded, isTrue);
      expect(onboarded.selectedAudioTrack, 'tactical_ambiance_2.mp3');
    });
  });

  group('RoomCategory & Predefined Catalogue', () {
    test('has exactly 4 core rooms', () {
      expect(RoomCategory.all, ['Cuisine', 'Salle de bain', 'Salon', 'Chambre']);
      expect(RoomCategory.rooms, equals(RoomCategory.all));
      expect(RoomCategory.isValid('Cuisine'), isTrue);
      expect(RoomCategory.isValid('Garage'), isFalse);
    });

    test('metadata is present for each room', () {
      for (final room in RoomCategory.all) {
        final meta = RoomCategory.getMetadata(room);
        expect(meta, isNotNull);
        expect(meta!.name, room);
        expect(meta.description.isNotEmpty, isTrue);
        expect(meta.iconKey.isNotEmpty, isTrue);
      }
    });

    test('defaultChores contains exactly 17 predefined chores with valid specs', () {
      final chores = RoomCategory.defaultChores;
      expect(chores.length, 17);

      for (final chore in chores) {
        expect(chore.id.isNotEmpty, isTrue);
        expect(chore.name.isNotEmpty, isTrue);
        expect(RoomCategory.isValid(chore.room), isTrue);
        expect(chore.difficulty, inInclusiveRange(1, 5));
        expect(chore.periodicityDays, greaterThanOrEqualTo(1));
        expect(chore.isDefault, isTrue);
        expect(chore.stratagemSequence.length, inInclusiveRange(5, 8));
        for (final move in chore.stratagemSequence) {
          expect(['UP', 'DOWN', 'LEFT', 'RIGHT'].contains(move), isTrue);
        }
      }
    });

    test('room-specific chore distribution matches requirements', () {
      final cuisineChores = RoomCategory.defaultChoresForRoom(RoomCategory.cuisine);
      final sdbChores = RoomCategory.defaultChoresForRoom(RoomCategory.salleDeBain);
      final salonChores = RoomCategory.defaultChoresForRoom(RoomCategory.salon);
      final chambreChores = RoomCategory.defaultChoresForRoom(RoomCategory.chambre);

      expect(cuisineChores.length, 5);
      expect(sdbChores.length, 4);
      expect(salonChores.length, 4);
      expect(chambreChores.length, 4);
    });
  });

  group('Backwards Compatibility with legacy models.dart', () {
    test('legacy Chore and MissionLog constructor signatures compile and behave', () {
      final legacyChore = Chore(id: '1', name: 'Nettoyer la cuisine', difficulty: 3);
      expect(legacyChore.id, '1');
      expect(legacyChore.name, 'Nettoyer la cuisine');
      expect(legacyChore.difficulty, 3);

      final legacyLog = MissionLog(
        choreId: '1',
        completedAt: DateTime.now(),
        success: true,
      );
      expect(legacyLog.choreId, '1');
      expect(legacyLog.success, isTrue);
    });
  });
}
