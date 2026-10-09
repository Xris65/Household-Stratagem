import 'package:flutter_test/flutter_test.dart';
import 'package:household_stratagem/models/chore.dart';
import 'package:household_stratagem/models/mission_log.dart';
import 'package:household_stratagem/models/room_category.dart';
import 'package:household_stratagem/models/user_profile.dart';

import 'proposed_fake_auth_service.dart';
import 'proposed_in_memory_household_repository.dart';

void main() {
  group('FakeAuthService Verification Tests', () {
    late FakeAuthService authService;

    setUp(() {
      authService = FakeAuthService();
    });

    tearDown(() {
      authService.dispose();
    });

    test('initializes unauthenticated with null currentUserId', () {
      expect(authService.currentUserId, isNull);
    });

    test('signInAnonymously generates unique anonymous UID and updates state', () async {
      final emitted = <String?>[];
      final sub = authService.authStateChanges.listen(emitted.add);

      final uid = await authService.signInAnonymously();
      expect(uid, startsWith('anon_'));
      expect(authService.currentUserId, equals(uid));

      await Future<void>.delayed(Duration.zero);
      expect(emitted, contains(uid));
      await sub.cancel();
    });

    test('signInWithEmailPassword rejects empty or whitespace email and password', () async {
      expect(() => authService.signInWithEmailPassword('', 'secret'), throwsArgumentError);
      expect(() => authService.signInWithEmailPassword('   ', 'secret'), throwsArgumentError);
      expect(() => authService.signInWithEmailPassword('user@domain.com', ''), throwsArgumentError);
      expect(() => authService.signInWithEmailPassword('user@domain.com', '   '), throwsArgumentError);
    });

    test('signInWithEmailPassword sanitizes email into UID and updates state', () async {
      final uid = await authService.signInWithEmailPassword('agent.clean@hud.com', 'tactical_pass');
      expect(uid, equals('user_agent_clean_hud_com'));
      expect(authService.currentUserId, equals(uid));
    });

    test('signOut resets user ID and notifies authStateChanges listeners', () async {
      await authService.signInAnonymously();
      expect(authService.currentUserId, isNotNull);

      final emitted = <String?>[];
      final sub = authService.authStateChanges.listen(emitted.add);

      await authService.signOut();
      expect(authService.currentUserId, isNull);

      await Future<void>.delayed(Duration.zero);
      expect(emitted, contains(null));
      await sub.cancel();
    });

    test('simulateAuthChange allows arbitrary test injection', () async {
      authService.simulateAuthChange('mock_override_uid');
      expect(authService.currentUserId, equals('mock_override_uid'));
    });
  });

  group('InMemoryHouseholdRepository Verification Tests', () {
    late InMemoryHouseholdRepository repository;

    setUp(() {
      repository = InMemoryHouseholdRepository();
    });

    tearDown(() {
      repository.reset();
    });

    test('getUserProfile returns null for unknown user', () async {
      final profile = await repository.getUserProfile('non_existent_uid');
      expect(profile, isNull);
    });

    test('saveUserProfile and getUserProfile persist and retrieve profile data', () async {
      final profile = UserProfile(
        userId: 'u_101',
        agentName: 'Agent Nettoyeur Alpha',
        level: 3,
        credits: 1200,
        medals: 7,
        onboarded: true,
        selectedAudioTrack: 'tactical_ambiance_2.mp3',
      );

      await repository.saveUserProfile(profile);
      final retrieved = await repository.getUserProfile('u_101');

      expect(retrieved, isNotNull);
      expect(retrieved?.userId, equals('u_101'));
      expect(retrieved?.agentName, equals('Agent Nettoyeur Alpha'));
      expect(retrieved?.level, equals(3));
      expect(retrieved?.credits, equals(1200));
      expect(retrieved?.medals, equals(7));
      expect(retrieved?.isOnboarded, isTrue);
      expect(retrieved?.selectedAudioTrack, equals('tactical_ambiance_2.mp3'));
    });

    test('getChores returns empty list when user has not saved chores and autoSeed is false', () async {
      final chores = await repository.getChores('fresh_user');
      expect(chores, isEmpty);
    });

    test('getChores with autoSeed: true automatically provides 17 default chores on first read', () async {
      final autoSeedRepo = InMemoryHouseholdRepository(autoSeed: true);
      final chores = await autoSeedRepo.getChores('demo_agent');

      expect(chores.length, equals(17));
      expect(chores.map((c) => c.room).toSet(), containsAll(RoomCategory.all));
    });

    test('seedDefaultsForUser populates 17 default chores on demand', () async {
      expect(await repository.getChores('user_manual'), isEmpty);

      repository.seedDefaultsForUser('user_manual');
      final chores = await repository.getChores('user_manual');
      expect(chores.length, equals(17));
    });

    test('saveChores and getChores maintain full chore list', () async {
      final sampleChores = [
        Chore(
          id: 'test_c1',
          name: 'Dégraisser les plaques',
          room: RoomCategory.cuisine,
          difficulty: 2,
          periodicityDays: 3,
          stratagemSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP'],
        ),
        Chore(
          id: 'test_c2',
          name: 'Détartrer la robinetterie',
          room: RoomCategory.salleDeBain,
          difficulty: 3,
          periodicityDays: 7,
          stratagemSequence: ['DOWN', 'UP', 'DOWN', 'UP', 'LEFT', 'RIGHT'],
        ),
      ];

      await repository.saveChores('u_test_chores', sampleChores);
      final fetched = await repository.getChores('u_test_chores');

      expect(fetched.length, equals(2));
      expect(fetched[0].id, equals('test_c1'));
      expect(fetched[1].id, equals('test_c2'));
    });

    test('updateChore modifies existing chore in place', () async {
      final chore = Chore(
        id: 'c_update',
        name: 'Aspirer salon',
        room: RoomCategory.salon,
        difficulty: 2,
        periodicityDays: 3,
      );

      await repository.saveChores('u_update', [chore]);

      final completionTime = DateTime(2026, 10, 4, 18, 0);
      final updated = chore.copyWith(lastCompletedAt: completionTime, periodicityDays: 5);

      await repository.updateChore('u_update', updated);
      final fetched = await repository.getChores('u_update');

      expect(fetched.length, equals(1));
      expect(fetched.first.periodicityDays, equals(5));
      expect(fetched.first.lastCompletedAt, equals(completionTime));
    });

    test('updateChore upserts safely if chore does not exist yet', () async {
      final newChore = Chore(
        id: 'c_upsert',
        name: 'Changer draps',
        room: RoomCategory.chambre,
        difficulty: 1,
        periodicityDays: 7,
      );

      await repository.updateChore('u_upsert', newChore);
      final fetched = await repository.getChores('u_upsert');

      expect(fetched.length, equals(1));
      expect(fetched.first.id, equals('c_upsert'));
    });

    test('logMission and getMissionLogs record and retrieve mission history chronologically', () async {
      expect(await repository.getMissionLogs('u_logs'), isEmpty);

      final log1 = MissionLog(
        id: 'log_1',
        choreId: 'c1',
        choreName: 'Nettoyer plaques',
        room: RoomCategory.cuisine,
        completedAt: DateTime(2026, 10, 4, 10, 0),
        durationSeconds: 240,
        success: true,
      );
      final log2 = MissionLog(
        id: 'log_2',
        choreId: 'c2',
        choreName: 'Aspirateur salon',
        room: RoomCategory.salon,
        completedAt: DateTime(2026, 10, 4, 11, 30),
        durationSeconds: 310,
        success: true,
      );

      await repository.logMission('u_logs', log1);
      await repository.logMission('u_logs', log2);

      final fetchedLogs = await repository.getMissionLogs('u_logs');
      expect(fetchedLogs.length, equals(2));
      expect(fetchedLogs[0].id, equals('log_1'));
      expect(fetchedLogs[1].id, equals('log_2'));
      expect(fetchedLogs[0].durationSeconds, equals(240));
      expect(fetchedLogs[1].durationSeconds, equals(310));
    });

    test('reset clears all profiles, chores, and mission logs', () async {
      await repository.saveUserProfile(UserProfile(userId: 'u1'));
      await repository.saveChores('u1', [Chore(id: 'c1', name: 'Task', difficulty: 1)]);
      await repository.logMission('u1', MissionLog(choreId: 'c1', completedAt: DateTime.now()));

      expect(repository.profiles.length, equals(1));
      expect(repository.allChores.length, equals(1));
      expect(repository.allLogs.length, equals(1));

      repository.reset();

      expect(repository.profiles, isEmpty);
      expect(repository.allChores, isEmpty);
      expect(repository.allLogs, isEmpty);
    });
  });
}
