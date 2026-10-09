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
      expect(chore.room, equals('Cuisine'));
      expect(chore.lastCompletedAt, isNull);
      expect(chore.periodicityDays, equals(7));
      expect(chore.stratagemSequence, isEmpty);
      expect(chore.swipeSequence, isEmpty);
      expect(chore.isDefault, isFalse);
      expect(chore.enabled, isTrue);
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
        enabled: true,
      );

      expect(chore.id, equals('chore_full'));
      expect(chore.name, equals('Dégraisser la hotte'));
      expect(chore.room, equals('Cuisine'));
      expect(chore.difficulty, equals(4));
      expect(chore.periodicityDays, equals(14));
      expect(chore.lastCompletedAt, equals(completedTime));
      expect(chore.stratagemSequence, equals(['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP']));
      expect(chore.swipeSequence, equals(['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP']));
      expect(chore.isDefault, isTrue);
      expect(chore.enabled, isTrue);
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
        enabled: true,
      );

      final map = original.toMap();
      expect(map['id'], equals('chore_roundtrip'));
      expect(map['name'], equals('Nettoyer le miroir'));
      expect(map['room'], equals('Salle de bain'));
      expect(map['difficulty'], equals(2));
      expect(map['periodicityDays'], equals(7));
      expect(map['stratagemSequence'], equals(['LEFT', 'RIGHT', 'UP', 'DOWN', 'DOWN']));
      expect(map['swipeSequence'], equals(['LEFT', 'RIGHT', 'UP', 'DOWN', 'DOWN']));
      expect(map['isDefault'], isFalse);
      expect(map['enabled'], isTrue);

      final restored = Chore.fromMap(map, original.id);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.room, equals(original.room));
      expect(restored.difficulty, equals(original.difficulty));
      expect(restored.periodicityDays, equals(original.periodicityDays));
      expect(
        restored.lastCompletedAt?.millisecondsSinceEpoch,
        equals(original.lastCompletedAt?.millisecondsSinceEpoch),
      );
      expect(restored.stratagemSequence, equals(original.stratagemSequence));
      expect(restored.isDefault, equals(original.isDefault));
      expect(restored.enabled, equals(original.enabled));
      expect(restored, equals(original));
    });

    test('fromMap handles epoch milliseconds and id override', () {
      final map = {
        'name': 'Aspiration salon',
        'room': 'Salon',
        'difficulty': 2,
        'periodicityDays': 3,
        'lastCompletedAt': 1728043200000,
        'stratagemSequence': ['LEFT', 'RIGHT', 'UP'],
        'isDefault': false,
      };

      final chore = Chore.fromMap(map, 'override_id');
      expect(chore.id, equals('override_id'));
      expect(chore.name, equals('Aspiration salon'));
      expect(chore.lastCompletedAt, equals(DateTime.fromMillisecondsSinceEpoch(1728043200000)));
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

    test('copyWith updates specified fields while retaining others and clears completion date', () {
      final original = Chore(
        id: 'c1',
        name: 'Vider le lave-vaisselle',
        room: 'Cuisine',
        difficulty: 1,
        periodicityDays: 1,
        lastCompletedAt: DateTime(2026, 10, 3),
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

      final cleared = updated.copyWith(clearLastCompletedAt: true);
      expect(cleared.lastCompletedAt, isNull);
      expect(cleared.name, equals('Vider et recharger le lave-vaisselle'));
    });

    test('equality, hashCode, and toString work as expected', () {
      final c1 = Chore(id: 'c1', name: 'Task', difficulty: 2, stratagemSequence: ['UP', 'DOWN']);
      final c2 = Chore(id: 'c1', name: 'Task', difficulty: 2, stratagemSequence: ['UP', 'DOWN']);
      final c3 = Chore(id: 'c1', name: 'Task', difficulty: 2, stratagemSequence: ['UP', 'UP']);

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
      expect(c1.toString(), contains('Chore(id: c1'));
    });
  });

  group('MissionLog Model Tests', () {
    test('instantiates with required fields and defaults', () {
      final now = DateTime(2026, 10, 4, 12, 0);
      final log = MissionLog(
        choreId: 'chore_10',
        completedAt: now,
        success: true,
      );

      expect(log.choreId, equals('chore_10'));
      expect(log.completedAt, equals(now));
      expect(log.success, isTrue);
      expect(log.id, equals(''));
      expect(log.durationSeconds, equals(600));
    });

    test('roundtrip serialization via toMap and fromMap', () {
      final now = DateTime(2026, 10, 4, 13, 0);
      final log = MissionLog(
        id: 'log_abc',
        choreId: 'chore_10',
        choreName: 'Nettoyage sol',
        room: 'Salon',
        completedAt: now,
        durationSeconds: 450,
        success: false,
      );

      final map = log.toMap();
      final restored = MissionLog.fromMap(map);

      expect(restored.id, equals('log_abc'));
      expect(restored.choreId, equals(log.choreId));
      expect(restored.choreName, equals('Nettoyage sol'));
      expect(restored.room, equals('Salon'));
      expect(restored.success, isFalse);
      expect(restored.durationSeconds, equals(450));
      expect(
        restored.completedAt.millisecondsSinceEpoch,
        equals(log.completedAt.millisecondsSinceEpoch),
      );
      expect(restored, equals(log));
      expect(restored.hashCode, equals(log.hashCode));
    });

    test('copyWith updates fields', () {
      final log = MissionLog(
        choreId: 'c1',
        completedAt: DateTime.now(),
        success: false,
      );

      final successLog = log.copyWith(success: true, durationSeconds: 300);
      expect(successLog.success, isTrue);
      expect(successLog.durationSeconds, equals(300));
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
      expect(profile.agentName, equals('Nettoyeur-1'));
      expect(profile.level, equals(1));
      expect(profile.credits, equals(0));
      expect(profile.medals, equals(0));
      expect(profile.email, equals('nettoyeur@helldivers.fr'));
      expect(profile.isOnboarded, isFalse);
      expect(profile.onboarded, isFalse);
      expect(profile.selectedAudioTrack, equals('tactical_ambiance_1.mp3'));
      expect(profile.preferredAudioTrack, equals('tactical_ambiance_1.mp3'));
      expect(profile.createdAt, equals(created));
    });

    test('roundtrip serialization via toMap and fromMap', () {
      final created = DateTime(2026, 10, 1, 10, 0);
      final profile = UserProfile(
        userId: 'user_xyz',
        agentName: 'Nettoyeur-99',
        level: 12,
        credits: 5400,
        medals: 25,
        email: 'commander@cleaning.org',
        isOnboarded: true,
        selectedAudioTrack: 'tactical_ambiance_2.mp3',
        createdAt: created,
      );

      final map = profile.toMap();
      final restored = UserProfile.fromMap(map);

      expect(restored.userId, equals('user_xyz'));
      expect(restored.agentName, equals('Nettoyeur-99'));
      expect(restored.level, equals(12));
      expect(restored.credits, equals(5400));
      expect(restored.medals, equals(25));
      expect(restored.email, equals('commander@cleaning.org'));
      expect(restored.isOnboarded, isTrue);
      expect(restored.onboarded, isTrue);
      expect(restored.selectedAudioTrack, equals('tactical_ambiance_2.mp3'));
      expect(restored.preferredAudioTrack, equals('tactical_ambiance_2.mp3'));
      expect(
        restored.createdAt.millisecondsSinceEpoch,
        equals(profile.createdAt.millisecondsSinceEpoch),
      );
      expect(restored, equals(profile));
    });

    test('handles zero credits and zero medals cleanly in fromMap', () {
      final map = {
        'userId': 'u_zero',
        'credits': 0,
        'medals': 0,
        'level': 1,
      };

      final profile = UserProfile.fromMap(map);
      expect(profile.credits, equals(0));
      expect(profile.medals, equals(0));
    });

    test('copyWith updates onboarding state and audio track', () {
      final profile = UserProfile(
        userId: 'user_new',
        email: 'recruit@cleaning.org',
        isOnboarded: false,
        createdAt: DateTime.now(),
      );

      final updated = profile.copyWith(
        isOnboarded: true,
        selectedAudioTrack: 'tactical_ambiance_2.mp3',
        credits: 100,
      );
      expect(updated.isOnboarded, isTrue);
      expect(updated.onboarded, isTrue);
      expect(updated.selectedAudioTrack, equals('tactical_ambiance_2.mp3'));
      expect(updated.credits, equals(100));
      expect(updated.userId, equals('user_new'));
    });
  });

  group('RoomCategory Tests', () {
    test('contains the 4 required standard cleaning rooms', () {
      const expectedRooms = ['Cuisine', 'Salle de bain', 'Salon', 'Chambre'];
      expect(RoomCategory.all, containsAll(expectedRooms));
      expect(RoomCategory.all.length, equals(4));
      expect(RoomCategory.rooms, equals(RoomCategory.all));
      expect(RoomCategory.isValid('Cuisine'), isTrue);
      expect(RoomCategory.isValid('Salle de bain'), isTrue);
      expect(RoomCategory.isValid('Salon'), isTrue);
      expect(RoomCategory.isValid('Chambre'), isTrue);
      expect(RoomCategory.isValid('Garage'), isFalse);
    });

    test('metadata is defined for all 4 rooms', () {
      for (final room in RoomCategory.all) {
        final meta = RoomCategory.getMetadata(room);
        expect(meta, isNotNull);
        expect(meta!.name, equals(room));
        expect(meta.description.isNotEmpty, isTrue);
        expect(meta.iconKey.isNotEmpty, isTrue);
        expect(meta.defaultTaskCount, greaterThan(0));
      }
    });

    test('default chores catalogue contains 17 chores across the 4 rooms with 5-8 swipe sequences', () {
      final chores = RoomCategory.defaultChores;
      expect(chores.length, equals(17));

      for (final chore in chores) {
        expect(chore.id.isNotEmpty, isTrue);
        expect(chore.name.isNotEmpty, isTrue);
        expect(RoomCategory.isValid(chore.room), isTrue);
        expect(chore.difficulty, inInclusiveRange(1, 5));
        expect(chore.periodicityDays, greaterThanOrEqualTo(1));
        expect(chore.stratagemSequence.length, inInclusiveRange(5, 8));
        expect(chore.isDefault, isTrue);
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

      expect(cuisineChores.length, equals(5));
      expect(sdbChores.length, equals(4));
      expect(salonChores.length, equals(4));
      expect(chambreChores.length, equals(4));
    });
  });

  group('Backwards Compatibility with legacy models.dart', () {
    test('legacy Chore and MissionLog constructor signatures compile and behave', () {
      final legacyChore = Chore(id: '1', name: 'Nettoyer la cuisine', difficulty: 3);
      expect(legacyChore.id, equals('1'));
      expect(legacyChore.name, equals('Nettoyer la cuisine'));
      expect(legacyChore.difficulty, equals(3));

      final legacyLog = MissionLog(
        choreId: '1',
        completedAt: DateTime.now(),
        success: true,
      );
      expect(legacyLog.choreId, equals('1'));
      expect(legacyLog.success, isTrue);
    });
  });
}
