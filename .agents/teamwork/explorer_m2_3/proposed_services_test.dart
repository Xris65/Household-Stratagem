import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:household_stratagem/models/chore.dart';
import 'package:household_stratagem/models/mission_log.dart';
import 'package:household_stratagem/models/room_category.dart';
import 'package:household_stratagem/models/user_profile.dart';
import 'package:household_stratagem/services/auth_service.dart';
import 'package:household_stratagem/services/household_repository.dart';
import 'package:household_stratagem/services/audio_service.dart';

void main() {
  group('1. AuthService - FakeAuthService Lifecycle & Authentication', () {
    late FakeAuthService auth;

    setUp(() {
      auth = FakeAuthService();
    });

    tearDown(() {
      auth.dispose();
    });

    test('initial state has null currentUserId and no active user', () {
      expect(auth.currentUserId, isNull);
    });

    test('signInAnonymously returns unique anon_ UID and updates currentUserId', () async {
      final uid = await auth.signInAnonymously();

      expect(uid, isNotEmpty);
      expect(uid.startsWith('anon_'), isTrue);
      expect(auth.currentUserId, equals(uid));
    });

    test('signInAnonymously emits new UID to authStateChanges stream', () async {
      final expectation = expectLater(
        auth.authStateChanges,
        emits(predicate<String?>((val) => val != null && val.startsWith('anon_'))),
      );

      await auth.signInAnonymously();
      await expectation;
    });

    test('signInWithEmailPassword sanitizes email and returns deterministic user_ UID', () async {
      final uid = await auth.signInWithEmailPassword('cleaner@orbit.net', 'TacticalPass123!');

      expect(uid, equals('user_cleaner_orbit_net'));
      expect(auth.currentUserId, equals('user_cleaner_orbit_net'));
    });

    test('signInWithEmailPassword emits new UID to authStateChanges stream', () async {
      final expectation = expectLater(
        auth.authStateChanges,
        emits('user_soldier_cleaning_org'),
      );

      await auth.signInWithEmailPassword('soldier@cleaning.org', 'SecurePassword99');
      await expectation;
    });

    test('signInWithEmailPassword throws ArgumentError for empty or whitespace credentials', () async {
      expect(
        () => auth.signInWithEmailPassword('', 'secret'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => auth.signInWithEmailPassword('   ', 'secret'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => auth.signInWithEmailPassword('valid@domain.com', ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => auth.signInWithEmailPassword('valid@domain.com', '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('signOut sets currentUserId to null and emits null on authStateChanges', () async {
      await auth.signInAnonymously();
      expect(auth.currentUserId, isNotNull);

      final expectation = expectLater(auth.authStateChanges, emits(isNull));

      await auth.signOut();
      expect(auth.currentUserId, isNull);
      await expectation;
    });

    test('signOut when already unauthenticated is safe and idempotent', () async {
      expect(auth.currentUserId, isNull);
      await auth.signOut();
      expect(auth.currentUserId, isNull);
    });

    test('authStateChanges stream records chronological authentication transitions', () async {
      final events = <String?>[];
      final subscription = auth.authStateChanges.listen((uid) => events.add(uid));

      await auth.signInAnonymously();
      final anonUid = auth.currentUserId;
      await auth.signOut();
      await auth.signInWithEmailPassword('agent@clean.com', 'pwd');
      await auth.signOut();

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events, equals([
        anonUid,
        null,
        'user_agent_clean_com',
        null,
      ]));

      await subscription.cancel();
    });

    test('simulateAuthChange updates currentUserId and pushes to stream', () async {
      final expectation = expectLater(auth.authStateChanges, emits('custom_test_uid'));

      auth.simulateAuthChange('custom_test_uid');
      expect(auth.currentUserId, equals('custom_test_uid'));
      await expectation;
    });
  });

  group('2. HouseholdRepository - InMemoryHouseholdRepository Persistence', () {
    late InMemoryHouseholdRepository repository;

    setUp(() {
      repository = InMemoryHouseholdRepository(autoSeed: false);
    });

    test('getUserProfile returns null for non-existent userId', () async {
      final profile = await repository.getUserProfile('unknown_user_999');
      expect(profile, isNull);
    });

    test('saveUserProfile stores profile and getUserProfile retrieves identical record', () async {
      final original = UserProfile(
        userId: 'agent_001',
        agentName: 'Aspirateur-Elite',
        level: 5,
        credits: 1500,
        medals: 42,
        onboarded: true,
        selectedAudioTrack: 'tactical_ambiance_2.mp3',
        createdAt: DateTime(2026, 10, 4, 12, 0),
      );

      await repository.saveUserProfile(original);
      final retrieved = await repository.getUserProfile('agent_001');

      expect(retrieved, isNotNull);
      expect(retrieved!.userId, equals('agent_001'));
      expect(retrieved.agentName, equals('Aspirateur-Elite'));
      expect(retrieved.level, equals(5));
      expect(retrieved.credits, equals(1500));
      expect(retrieved.medals, equals(42));
      expect(retrieved.onboarded, isTrue);
      expect(retrieved.selectedAudioTrack, equals('tactical_ambiance_2.mp3'));
      expect(retrieved.createdAt, equals(DateTime(2026, 10, 4, 12, 0)));
    });

    test('saveUserProfile overwrites existing profile without state leakage', () async {
      final profileV1 = UserProfile(userId: 'agent_002', agentName: 'Novice', level: 1);
      await repository.saveUserProfile(profileV1);

      final profileV2 = profileV1.copyWith(agentName: 'Maître Nettoyeur', level: 10, medals: 50);
      await repository.saveUserProfile(profileV2);

      final retrieved = await repository.getUserProfile('agent_002');
      expect(retrieved!.agentName, equals('Maître Nettoyeur'));
      expect(retrieved.level, equals(10));
      expect(retrieved.medals, equals(50));
    });

    test('getChores returns empty list for new user when autoSeed is false', () async {
      final chores = await repository.getChores('user_empty');
      expect(chores, isEmpty);
    });

    test('getChores auto-populates 17 default chores when autoSeed is true', () async {
      final autoSeedRepo = InMemoryHouseholdRepository(autoSeed: true);
      final chores = await autoSeedRepo.getChores('user_seeded');

      expect(chores.length, equals(17));
      expect(chores.any((c) => c.room == 'Cuisine'), isTrue);
      expect(chores.any((c) => c.room == 'Salle de bain'), isTrue);
      expect(chores.any((c) => c.room == 'Salon'), isTrue);
      expect(chores.any((c) => c.room == 'Chambre'), isTrue);
    });

    test('seedDefaultsForUser manually seeds standard chores for user', () async {
      repository.seedDefaultsForUser('user_manual_seed');
      final chores = await repository.getChores('user_manual_seed');

      expect(chores.length, equals(17));
    });

    test('saveChores persists custom chore list and getChores retrieves them', () async {
      final customChores = [
        Chore(
          id: 'chore_c1',
          name: 'Nettoyer plan de travail',
          room: 'Cuisine',
          difficulty: 2,
          periodicityDays: 1,
          stratagemSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP'],
        ),
        Chore(
          id: 'chore_s1',
          name: 'Passer l\'aspirateur',
          room: 'Salon',
          difficulty: 3,
          periodicityDays: 3,
          stratagemSequence: ['DOWN', 'UP', 'DOWN', 'LEFT', 'RIGHT', 'UP'],
        ),
      ];

      await repository.saveChores('user_custom', customChores);
      final retrieved = await repository.getChores('user_custom');

      expect(retrieved.length, equals(2));
      expect(retrieved[0].id, equals('chore_c1'));
      expect(retrieved[0].name, equals('Nettoyer plan de travail'));
      expect(retrieved[0].stratagemSequence, equals(['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP']));
      expect(retrieved[1].id, equals('chore_s1'));
      expect(retrieved[1].difficulty, equals(3));
    });

    test('updateChore modifies existing chore in repository', () async {
      final initialChore = Chore(
        id: 'chore_update_1',
        name: 'Laver le miroir',
        room: 'Salle de bain',
        difficulty: 1,
        periodicityDays: 7,
      );
      await repository.saveChores('user_upd', [initialChore]);

      final completedDate = DateTime(2026, 10, 4, 13, 0);
      final updatedChore = Chore(
        id: 'chore_update_1',
        name: 'Laver le miroir (Brillant)',
        room: 'Salle de bain',
        difficulty: 2,
        periodicityDays: 4,
        lastCompletedAt: completedDate,
        stratagemSequence: ['UP', 'RIGHT', 'DOWN', 'LEFT', 'UP'],
      );

      await repository.updateChore('user_upd', updatedChore);
      final chores = await repository.getChores('user_upd');

      expect(chores.length, equals(1));
      expect(chores[0].name, equals('Laver le miroir (Brillant)'));
      expect(chores[0].difficulty, equals(2));
      expect(chores[0].periodicityDays, equals(4));
      expect(chores[0].lastCompletedAt, equals(completedDate));
    });

    test('updateChore inserts chore if chore id was not previously present', () async {
      final newChore = Chore(
        id: 'brand_new_chore',
        name: 'Détartrer bouilloire',
        room: 'Cuisine',
        difficulty: 2,
        periodicityDays: 14,
      );

      await repository.updateChore('user_upsert', newChore);
      final chores = await repository.getChores('user_upsert');

      expect(chores.length, equals(1));
      expect(chores.first.id, equals('brand_new_chore'));
    });

    test('defensive copying ensures repository internal chores cannot be mutated from outside', () async {
      final originalList = [
        Chore(id: 'task_1', name: 'Task 1', difficulty: 1),
      ];
      await repository.saveChores('user_copy', originalList);

      final fetchedList = await repository.getChores('user_copy');
      fetchedList.clear();

      final reFetched = await repository.getChores('user_copy');
      expect(reFetched.length, equals(1));
    });

    test('logMission persists execution log and getMissionLogs returns in order', () async {
      final log1 = MissionLog(
        id: 'log_01',
        choreId: 'c1',
        choreName: 'Nettoyer plaques',
        room: 'Cuisine',
        completedAt: DateTime(2026, 10, 3, 10, 0),
        durationSeconds: 300,
        success: true,
      );
      final log2 = MissionLog(
        id: 'log_02',
        choreId: 's1',
        choreName: 'Aspirateur salon',
        room: 'Salon',
        completedAt: DateTime(2026, 10, 4, 11, 30),
        durationSeconds: 450,
        success: true,
      );

      await repository.logMission('user_logs', log1);
      await repository.logMission('user_logs', log2);

      final logs = await repository.getMissionLogs('user_logs');
      expect(logs.length, equals(2));
      expect(logs[0].id, equals('log_01'));
      expect(logs[0].choreName, equals('Nettoyer plaques'));
      expect(logs[1].id, equals('log_02'));
      expect(logs[1].durationSeconds, equals(450));
    });

    test('data is strictly isolated between distinct user IDs', () async {
      await repository.saveUserProfile(UserProfile(userId: 'user_alpha', agentName: 'Alpha'));
      await repository.saveUserProfile(UserProfile(userId: 'user_beta', agentName: 'Beta'));

      await repository.saveChores('user_alpha', [Chore(id: 't_alpha', name: 'Task Alpha', difficulty: 1)]);
      await repository.saveChores('user_beta', [Chore(id: 't_beta', name: 'Task Beta', difficulty: 2)]);

      final profileA = await repository.getUserProfile('user_alpha');
      final profileB = await repository.getUserProfile('user_beta');
      expect(profileA!.agentName, equals('Alpha'));
      expect(profileB!.agentName, equals('Beta'));

      final choresA = await repository.getChores('user_alpha');
      final choresB = await repository.getChores('user_beta');
      expect(choresA.map((c) => c.id), equals(['t_alpha']));
      expect(choresB.map((c) => c.id), equals(['t_beta']));
    });

    test('reset clears all profiles, chores, and mission logs', () async {
      await repository.saveUserProfile(UserProfile(userId: 'wipe_user'));
      await repository.saveChores('wipe_user', [Chore(id: 'wipe_chore', name: 'Test', difficulty: 1)]);
      await repository.logMission('wipe_user', MissionLog(choreId: 'wipe_chore', completedAt: DateTime.now()));

      repository.reset();

      expect(await repository.getUserProfile('wipe_user'), isNull);
      expect(await repository.getChores('wipe_user'), isEmpty);
      expect(await repository.getMissionLogs('wipe_user'), isEmpty);
    });
  });

  group('3. HouseholdRepository - FirestoreHouseholdRepository (FakeFirebaseFirestore)', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreHouseholdRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestoreHouseholdRepository(firestore: fakeFirestore);
    });

    test('getUserProfile returns null for non-existent document or empty userId', () async {
      final notFound = await repository.getUserProfile('non_existent_uid');
      expect(notFound, isNull);

      final emptyId = await repository.getUserProfile('');
      expect(emptyId, isNull);
    });

    test('saveUserProfile writes to users/{userId} and getUserProfile retrieves it', () async {
      final profile = UserProfile(
        userId: 'firestore_user_1',
        agentName: 'Spectre Nettoyeur',
        level: 4,
        credits: 900,
        medals: 15,
        onboarded: true,
        selectedAudioTrack: 'tactical_ambiance_1.mp3',
        createdAt: DateTime(2026, 10, 4, 10, 0),
      );

      await repository.saveUserProfile(profile);

      // Verify Firestore raw document
      final docSnap = await fakeFirestore.collection('users').doc('firestore_user_1').get();
      expect(docSnap.exists, isTrue);
      expect(docSnap.data()!['agentName'], equals('Spectre Nettoyeur'));
      expect(docSnap.data()!['level'], equals(4));

      // Verify repository retrieval
      final retrieved = await repository.getUserProfile('firestore_user_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.userId, equals('firestore_user_1'));
      expect(retrieved.agentName, equals('Spectre Nettoyeur'));
      expect(retrieved.credits, equals(900));
      expect(retrieved.onboarded, isTrue);
    });

    test('saveUserProfile throws ArgumentError for empty userId', () async {
      final invalid = UserProfile(userId: '   ');
      expect(() => repository.saveUserProfile(invalid), throwsA(isA<ArgumentError>()));
    });

    test('saveChores batch-writes chores and getChores retrieves them from users/{userId}/tasks', () async {
      final chores = [
        Chore(
          id: 'fs_task_1',
          name: 'Dégraisser la hotte',
          room: 'Cuisine',
          difficulty: 4,
          periodicityDays: 14,
          stratagemSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP'],
        ),
        Chore(
          id: 'fs_task_2',
          name: 'Désinfecter les sanitaires',
          room: 'Salle de bain',
          difficulty: 3,
          periodicityDays: 3,
          stratagemSequence: ['DOWN', 'DOWN', 'UP', 'RIGHT', 'LEFT', 'UP'],
        ),
      ];

      await repository.saveChores('fs_user_2', chores);

      // Check subcollection in Firestore
      final snapshot = await fakeFirestore
          .collection('users')
          .doc('fs_user_2')
          .collection('tasks')
          .get();
      expect(snapshot.docs.length, equals(2));

      // Retrieve via repository
      final retrieved = await repository.getChores('fs_user_2');
      expect(retrieved.length, equals(2));
      final names = retrieved.map((c) => c.name).toSet();
      expect(names, contains('Dégraisser la hotte'));
      expect(names, contains('Désinfecter les sanitaires'));
    });

    test('saveChores throws ArgumentError on empty userId', () async {
      expect(
        () => repository.saveChores('', [Chore(id: 'c', name: 'Task', difficulty: 1)]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updateChore modifies single chore document in subcollection', () async {
      final original = Chore(
        id: 'fs_update_chore',
        name: 'Vider le lave-vaisselle',
        room: 'Cuisine',
        difficulty: 1,
        periodicityDays: 1,
      );
      await repository.saveChores('fs_user_3', [original]);

      final updated = Chore(
        id: 'fs_update_chore',
        name: 'Vider et recharger le lave-vaisselle',
        room: 'Cuisine',
        difficulty: 2,
        periodicityDays: 2,
        lastCompletedAt: DateTime(2026, 10, 4, 14, 0),
      );

      await repository.updateChore('fs_user_3', updated);

      final retrieved = await repository.getChores('fs_user_3');
      expect(retrieved.length, equals(1));
      expect(retrieved.first.name, equals('Vider et recharger le lave-vaisselle'));
      expect(retrieved.first.difficulty, equals(2));
      expect(retrieved.first.periodicityDays, equals(2));
      expect(retrieved.first.lastCompletedAt, equals(DateTime(2026, 10, 4, 14, 0)));
    });

    test('logMission stores mission log and getMissionLogs returns in chronological order', () async {
      final earlierLog = MissionLog(
        id: 'm_log_1',
        choreId: 'task_a',
        choreName: 'Tâche A',
        room: 'Salon',
        completedAt: DateTime(2026, 10, 2, 8, 0),
        durationSeconds: 500,
        success: true,
      );
      final laterLog = MissionLog(
        id: 'm_log_2',
        choreId: 'task_b',
        choreName: 'Tâche B',
        room: 'Chambre',
        completedAt: DateTime(2026, 10, 3, 9, 30),
        durationSeconds: 600,
        success: false,
      );

      // Log in reverse chronological order
      await repository.logMission('fs_user_4', laterLog);
      await repository.logMission('fs_user_4', earlierLog);

      final logs = await repository.getMissionLogs('fs_user_4');
      expect(logs.length, equals(2));
      expect(logs[0].id, equals('m_log_1')); // Sorted earlier first
      expect(logs[1].id, equals('m_log_2'));
    });

    test('logMission auto-generates document ID when log id is empty', () async {
      final logWithoutId = MissionLog(
        choreId: 'task_c',
        completedAt: DateTime.now(),
      );

      await repository.logMission('fs_user_5', logWithoutId);
      final logs = await repository.getMissionLogs('fs_user_5');

      expect(logs.length, equals(1));
      expect(logs.first.id, isNotEmpty);
    });
  });

  group('4. AudioService - MockAudioService Playback & State', () {
    late MockAudioService audio;

    setUp(() {
      audio = MockAudioService();
    });

    tearDown(() {
      audio.dispose();
    });

    test('initial state is stopped and not playing', () {
      expect(audio.isPlaying, isFalse);
      expect(audio.currentTrack, isNull);
      expect(audio.isDisposed, isFalse);
      expect(audio.playCount, equals(0));
      expect(audio.stopCount, equals(0));
      expect(audio.playedTracks, isEmpty);
    });

    test('playMissionLoop transitions isPlaying to true and tracks filename', () async {
      await audio.playMissionLoop('tactical_ambiance_1.mp3');

      expect(audio.isPlaying, isTrue);
      expect(audio.currentTrack, equals('tactical_ambiance_1.mp3'));
      expect(audio.playCount, equals(1));
      expect(audio.playedTracks, equals(['tactical_ambiance_1.mp3']));
    });

    test('playMissionLoop switching tracks updates currentTrack and increments counter', () async {
      await audio.playMissionLoop('tactical_ambiance_1.mp3');
      await audio.playMissionLoop('tactical_ambiance_2.mp3');

      expect(audio.isPlaying, isTrue);
      expect(audio.currentTrack, equals('tactical_ambiance_2.mp3'));
      expect(audio.playCount, equals(2));
      expect(audio.playedTracks, equals(['tactical_ambiance_1.mp3', 'tactical_ambiance_2.mp3']));
    });

    test('playMissionLoop throws ArgumentError for empty or whitespace asset paths', () async {
      expect(() => audio.playMissionLoop(''), throwsA(isA<ArgumentError>()));
      expect(() => audio.playMissionLoop('   '), throwsA(isA<ArgumentError>()));
    });

    test('stop clears playing status and increments stopCount', () async {
      await audio.playMissionLoop('tactical_ambiance_1.mp3');
      expect(audio.isPlaying, isTrue);

      await audio.stop();

      expect(audio.isPlaying, isFalse);
      expect(audio.currentTrack, isNull);
      expect(audio.stopCount, equals(1));
    });

    test('redundant stop calls are safe and idempotent', () async {
      await audio.stop();
      await audio.stop();

      expect(audio.isPlaying, isFalse);
      expect(audio.currentTrack, isNull);
      expect(audio.stopCount, equals(2));
    });

    test('dispose marks service as disposed and prevents subsequent play calls', () async {
      await audio.playMissionLoop('tactical_ambiance_1.mp3');
      audio.dispose();

      expect(audio.isDisposed, isTrue);
      expect(audio.isPlaying, isFalse);
      expect(audio.currentTrack, isNull);

      expect(() => audio.playMissionLoop('tactical_ambiance_1.mp3'), throwsA(isA<StateError>()));
    });

    test('reset clears mock statistics and restores initial state', () async {
      await audio.playMissionLoop('tactical_ambiance_1.mp3');
      await audio.stop();

      audio.reset();

      expect(audio.isPlaying, isFalse);
      expect(audio.currentTrack, isNull);
      expect(audio.isDisposed, isFalse);
      expect(audio.playCount, equals(0));
      expect(audio.stopCount, equals(0));
      expect(audio.playedTracks, isEmpty);
    });
  });

  group('5. RealAudioService - Path Normalization Logic', () {
    test('normalizes assets/audio/ prefix to audio/', () {
      final normalized = RealAudioService.normalizeAssetPath('assets/audio/tactical_ambiance_1.mp3');
      expect(normalized, equals('audio/tactical_ambiance_1.mp3'));
    });

    test('preserves audio/ prefix as audio/', () {
      final normalized = RealAudioService.normalizeAssetPath('audio/tactical_ambiance_1.mp3');
      expect(normalized, equals('audio/tactical_ambiance_1.mp3'));
    });

    test('prepends audio/ when given bare filename', () {
      final normalized = RealAudioService.normalizeAssetPath('tactical_ambiance_1.mp3');
      expect(normalized, equals('audio/tactical_ambiance_1.mp3'));
    });

    test('strips leading slash from /assets/audio/ path', () {
      final normalized = RealAudioService.normalizeAssetPath('/assets/audio/tactical_ambiance_2.mp3');
      expect(normalized, equals('audio/tactical_ambiance_2.mp3'));
    });

    test('trims surrounding whitespace from path', () {
      final normalized = RealAudioService.normalizeAssetPath('   tactical_ambiance_2.mp3   ');
      expect(normalized, equals('audio/tactical_ambiance_2.mp3'));
    });

    test('throws ArgumentError for empty or whitespace path', () {
      expect(() => RealAudioService.normalizeAssetPath(''), throwsA(isA<ArgumentError>()));
      expect(() => RealAudioService.normalizeAssetPath('   '), throwsA(isA<ArgumentError>()));
    });
  });
}
