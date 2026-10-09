import 'package:flutter_test/flutter_test.dart';
import 'test_harness.dart';

void main() {
  group('Tier 3: Pairwise Combinatorial Tests (15 Scenarios)', () {
    late E2EAppHarness harness;

    setUp(() {
      harness = E2EAppHarness();
    });

    tearDown(() {
      harness.reset();
    });

    // -------------------------------------------------------------------------
    // Scenario 01: Cuisine, Diff 1 (5 moves), Never completed, Anon, Track Alpha
    // -------------------------------------------------------------------------
    test('T3_PAIR_01: Cuisine x Diff 1 (5 moves) x Never completed x Anon x Track Alpha', () async {
      await harness.signInAnonymous();
      final chore = E2EChore(
        id: 'p01',
        name: 'Vider évier',
        difficulty: 1,
        room: E2ERoomCategory.cuisine,
        periodicityDays: 1,
        lastCompletedAt: null,
      );
      await harness.repository.saveChores(harness.currentUserId!, [chore]);
      harness.currentChores = [chore];

      // Urgency check: never completed diff 1 = 1010.0
      final score = E2ETargetingEngine.calculateUrgencyScore(chore);
      expect(score, closeTo(1010.0, 0.001));

      // Start mission: generates 5 moves
      await harness.startMission(chore);
      expect(harness.targetSequence.length, equals(5));

      // Execute sequence
      for (final move in harness.targetSequence) {
        final ok = harness.submitSwipe(move);
        expect(ok, isTrue);
      }
      expect(harness.isStratagemUnlocked(), isTrue);
      expect(harness.audioService.isPlaying, isTrue);
      expect(harness.audioService.currentTrack, equals('tactical_ambiance_1.mp3'));

      // Complete mission
      harness.tickTimer(30);
      await harness.validateMission();

      expect(harness.audioService.isPlaying, isFalse);
      final logs = await harness.repository.getMissionLogs(harness.currentUserId!);
      expect(logs.length, equals(1));
      expect(logs.first.choreId, equals('p01'));
      expect(harness.currentProfile?.credits, equals(100)); // 100 * diff 1
    });

    // -------------------------------------------------------------------------
    // Scenario 02: Cuisine, Diff 3 (6 moves), Overdue 1.5x, Email, Track Bravo
    // -------------------------------------------------------------------------
    test('T3_PAIR_02: Cuisine x Diff 3 (6 moves) x Overdue 1.5x x Email x Track Bravo', () async {
      final uid = await harness.authService.signInWithEmailPassword('chef@logis.fr', 'pwd');
      harness.currentUserId = uid;
      harness.currentProfile = E2EUserProfile(
        userId: uid,
        preferredAudioTrack: 'tactical_ambiance_2.mp3',
        onboarded: true,
      );
      await harness.repository.saveUserProfile(harness.currentProfile!);

      final now = DateTime(2026, 10, 4, 12, 0);
      // Periodicity = 2 days, overdue by 1.5x = 3 days ago
      final chore = E2EChore(
        id: 'p02',
        name: 'Dégraissage four',
        difficulty: 3,
        room: E2ERoomCategory.cuisine,
        periodicityDays: 2,
        lastCompletedAt: now.subtract(const Duration(days: 3)),
      );
      await harness.repository.saveChores(uid, [chore]);
      harness.currentChores = [chore];

      // overdueRatio = 3/2 = 1.5. score = 1.5 * 100 + 3 * 5 = 165.0
      final score = E2ETargetingEngine.calculateUrgencyScore(chore, now: now);
      expect(score, closeTo(165.0, 0.001));

      await harness.startMission(chore);
      expect(harness.targetSequence.length, equals(6));

      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      expect(harness.isStratagemUnlocked(), isTrue);
      expect(harness.audioService.currentTrack, equals('tactical_ambiance_2.mp3'));

      await harness.validateMission(completionTime: now);
      expect(harness.currentProfile?.credits, equals(300));
    });

    // -------------------------------------------------------------------------
    // Scenario 03: Cuisine, Diff 5 (8 moves), Overdue 3.0x, Anon, Muted
    // -------------------------------------------------------------------------
    test('T3_PAIR_03: Cuisine x Diff 5 (8 moves) x Overdue 3.0x x Anon x Custom Moves', () async {
      await harness.signInAnonymous();
      final now = DateTime(2026, 10, 4, 12, 0);
      final chore = E2EChore(
        id: 'p03',
        name: 'Décapage sol extrême',
        difficulty: 5,
        room: E2ERoomCategory.cuisine,
        periodicityDays: 1,
        lastCompletedAt: now.subtract(const Duration(days: 3)),
      );
      await harness.repository.saveChores(harness.currentUserId!, [chore]);
      harness.currentChores = [chore];

      // overdueRatio = 3.0. Score = 300 + 25 = 325.0
      final score = E2ETargetingEngine.calculateUrgencyScore(chore, now: now);
      expect(score, closeTo(325.0, 0.001));

      await harness.startMission(chore);
      expect(harness.targetSequence.length, equals(8));

      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      expect(harness.isStratagemUnlocked(), isTrue);
      await harness.validateMission();
      expect(harness.currentProfile?.credits, equals(500));
    });

    // -------------------------------------------------------------------------
    // Scenario 04: SDB, Diff 1 (5 moves), Fresh 0.1x, Email, Track Bravo
    // -------------------------------------------------------------------------
    test('T3_PAIR_04: SDB x Diff 1 (5 moves) x Fresh 0.1x x Email x Track Bravo', () async {
      final uid = await harness.authService.signInWithEmailPassword('clean@sdb.fr', 'pwd');
      harness.currentUserId = uid;
      final now = DateTime(2026, 10, 4, 12, 0);
      final chore = E2EChore(
        id: 'p04',
        name: 'Rincer miroir',
        difficulty: 1,
        room: E2ERoomCategory.salleDeBain,
        periodicityDays: 10,
        lastCompletedAt: now.subtract(const Duration(days: 1)), // 1/10 = 0.1x
      );
      await harness.repository.saveChores(uid, [chore]);
      harness.currentChores = [chore];

      // overdueRatio = 0.1. Score = 10 + 5 = 15.0
      final score = E2ETargetingEngine.calculateUrgencyScore(chore, now: now);
      expect(score, closeTo(15.0, 0.001));

      await harness.startMission(chore);
      expect(harness.targetSequence.length, equals(5));
      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      await harness.validateMission();
      expect(harness.currentProfile?.credits, equals(100));
    });

    // -------------------------------------------------------------------------
    // Scenario 05: SDB, Diff 4 (7 moves), Overdue 3.0x, Anon, Track Alpha
    // -------------------------------------------------------------------------
    test('T3_PAIR_05: SDB x Diff 4 (7 moves) x Overdue 3.0x x Anon x Track Alpha', () async {
      await harness.signInAnonymous();
      final now = DateTime(2026, 10, 4, 12, 0);
      final chore = E2EChore(
        id: 'p05',
        name: 'Détartrage tuyauterie',
        difficulty: 4,
        room: E2ERoomCategory.salleDeBain,
        periodicityDays: 2,
        lastCompletedAt: now.subtract(const Duration(days: 6)), // 6/2 = 3.0x
      );
      await harness.repository.saveChores(harness.currentUserId!, [chore]);
      harness.currentChores = [chore];

      // overdueRatio = 3.0. Score = 300 + 20 = 320.0
      final score = E2ETargetingEngine.calculateUrgencyScore(chore, now: now);
      expect(score, closeTo(320.0, 0.001));

      await harness.startMission(chore);
      expect(harness.targetSequence.length, equals(7));
      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      await harness.validateMission();
      expect(harness.currentProfile?.credits, equals(400));
    });

    // -------------------------------------------------------------------------
    // Scenario 06: SDB, Diff 3 (6 moves), Never completed, Email, Track Alpha
    // -------------------------------------------------------------------------
    test('T3_PAIR_06: SDB x Diff 3 (6 moves) x Never completed x Email x Track Alpha', () async {
      final uid = await harness.authService.signInWithEmailPassword('wc@expert.com', 'pass');
      harness.currentUserId = uid;
      final chore = E2EChore(
        id: 'p06',
        name: 'Désinfecter toilettes',
        difficulty: 3,
        room: E2ERoomCategory.salleDeBain,
        periodicityDays: 3,
        lastCompletedAt: null,
      );
      await harness.repository.saveChores(uid, [chore]);
      harness.currentChores = [chore];

      // Score = 1000 + 30 = 1030.0
      expect(E2ETargetingEngine.calculateUrgencyScore(chore), closeTo(1030.0, 0.001));

      await harness.startMission(chore);
      expect(harness.targetSequence.length, equals(6));
      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      await harness.validateMission();
      expect(harness.currentProfile?.credits, equals(300));
    });

    // -------------------------------------------------------------------------
    // Scenario 07: Salon, Diff 1 (5 moves), Overdue 1.5x, Anon, Muted
    // -------------------------------------------------------------------------
    test('T3_PAIR_07: Salon x Diff 1 (5 moves) x Overdue 1.5x x Anon', () async {
      await harness.signInAnonymous();
      final now = DateTime(2026, 10, 4, 12, 0);
      final chore = E2EChore(
        id: 'p07',
        name: 'Ranger table basse',
        difficulty: 1,
        room: E2ERoomCategory.salon,
        periodicityDays: 2,
        lastCompletedAt: now.subtract(const Duration(days: 3)),
      );
      await harness.repository.saveChores(harness.currentUserId!, [chore]);
      harness.currentChores = [chore];

      // 1.5 * 100 + 5 = 155.0
      expect(E2ETargetingEngine.calculateUrgencyScore(chore, now: now), closeTo(155.0, 0.001));

      await harness.startMission(chore);
      expect(harness.targetSequence.length, equals(5));
      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      await harness.validateMission();
      expect(harness.currentProfile?.credits, equals(100));
    });

    // -------------------------------------------------------------------------
    // Scenario 08: Salon, Diff 2 (5 moves), Fresh 0.1x, Email, Track Alpha
    // -------------------------------------------------------------------------
    test('T3_PAIR_08: Salon x Diff 2 (5 moves) x Fresh 0.1x x Email x Track Alpha', () async {
      final uid = await harness.authService.signInWithEmailPassword('living@room.fr', 'pwd');
      harness.currentUserId = uid;
      final now = DateTime(2026, 10, 4, 12, 0);
      final chore = E2EChore(
        id: 'p08',
        name: 'Aspirer tapis salon',
        difficulty: 2,
        room: E2ERoomCategory.salon,
        periodicityDays: 10,
        lastCompletedAt: now.subtract(const Duration(days: 1)),
      );
      await harness.repository.saveChores(uid, [chore]);
      harness.currentChores = [chore];

      // 0.1 * 100 + 10 = 20.0
      expect(E2ETargetingEngine.calculateUrgencyScore(chore, now: now), closeTo(20.0, 0.001));

      await harness.startMission(chore);
      expect(harness.targetSequence.length, equals(5));
      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      await harness.validateMission();
      expect(harness.currentProfile?.credits, equals(200));
    });

    // -------------------------------------------------------------------------
    // Scenario 09: Salon, Diff 4 (7 moves), Overdue 3.0x, Anon, Track Bravo
    // -------------------------------------------------------------------------
    test('T3_PAIR_09: Salon x Diff 4 (7 moves) x Overdue 3.0x x Anon x Track Bravo', () async {
      await harness.signInAnonymous();
      final now = DateTime(2026, 10, 4, 12, 0);
      final chore = E2EChore(
        id: 'p09',
        name: 'Laver baies vitrées',
        difficulty: 4,
        room: E2ERoomCategory.salon,
        periodicityDays: 10,
        lastCompletedAt: now.subtract(const Duration(days: 30)),
      );
      await harness.repository.saveChores(harness.currentUserId!, [chore]);
      harness.currentChores = [chore];

      // 3.0 * 100 + 20 = 320.0
      expect(E2ETargetingEngine.calculateUrgencyScore(chore, now: now), closeTo(320.0, 0.001));

      await harness.startMission(chore);
      expect(harness.targetSequence.length, equals(7));
      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      await harness.validateMission();
      expect(harness.currentProfile?.credits, equals(400));
    });

    // -------------------------------------------------------------------------
    // Scenario 10: Chambre, Diff 1 (5 moves), Never completed, Email, Track Alpha
    // -------------------------------------------------------------------------
    test('T3_PAIR_10: Chambre x Diff 1 (5 moves) x Never completed x Email x Track Alpha', () async {
      final uid = await harness.authService.signInWithEmailPassword('bed@room.com', 'pwd');
      harness.currentUserId = uid;
      final chore = E2EChore(
        id: 'p10',
        name: 'Faire lit',
        difficulty: 1,
        room: E2ERoomCategory.chambre,
        periodicityDays: 1,
        lastCompletedAt: null,
      );
      await harness.repository.saveChores(uid, [chore]);
      harness.currentChores = [chore];

      expect(E2ETargetingEngine.calculateUrgencyScore(chore), closeTo(1010.0, 0.001));

      await harness.startMission(chore);
      expect(harness.targetSequence.length, equals(5));
      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      await harness.validateMission();
      expect(harness.currentProfile?.credits, equals(100));
    });

    // -------------------------------------------------------------------------
    // Scenario 11: Chambre, Diff 3 (6 moves), Overdue 1.5x, Anon, Track Bravo
    // -------------------------------------------------------------------------
    test('T3_PAIR_11: Chambre x Diff 3 (6 moves) x Overdue 1.5x x Anon x Track Bravo', () async {
      await harness.signInAnonymous();
      final now = DateTime(2026, 10, 4, 12, 0);
      final chore = E2EChore(
        id: 'p11',
        name: 'Changer draps',
        difficulty: 3,
        room: E2ERoomCategory.chambre,
        periodicityDays: 4,
        lastCompletedAt: now.subtract(const Duration(days: 6)),
      );
      await harness.repository.saveChores(harness.currentUserId!, [chore]);
      harness.currentChores = [chore];

      // 1.5 * 100 + 15 = 165.0
      expect(E2ETargetingEngine.calculateUrgencyScore(chore, now: now), closeTo(165.0, 0.001));

      await harness.startMission(chore);
      expect(harness.targetSequence.length, equals(6));
      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      await harness.validateMission();
      expect(harness.currentProfile?.credits, equals(300));
    });

    // -------------------------------------------------------------------------
    // Scenario 12: Chambre, Diff 2 (5 moves), Fresh 0.1x, Email, Muted
    // -------------------------------------------------------------------------
    test('T3_PAIR_12: Chambre x Diff 2 (5 moves) x Fresh 0.1x x Email', () async {
      final uid = await harness.authService.signInWithEmailPassword('suite@logis.fr', 'pwd');
      harness.currentUserId = uid;
      final now = DateTime(2026, 10, 4, 12, 0);
      final chore = E2EChore(
        id: 'p12',
        name: 'Ranger penderie',
        difficulty: 2,
        room: E2ERoomCategory.chambre,
        periodicityDays: 10,
        lastCompletedAt: now.subtract(const Duration(days: 1)),
      );
      await harness.repository.saveChores(uid, [chore]);
      harness.currentChores = [chore];

      // 0.1 * 100 + 10 = 20.0
      expect(E2ETargetingEngine.calculateUrgencyScore(chore, now: now), closeTo(20.0, 0.001));

      await harness.startMission(chore);
      expect(harness.targetSequence.length, equals(5));
      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      await harness.validateMission();
      expect(harness.currentProfile?.credits, equals(200));
    });

    // -------------------------------------------------------------------------
    // Scenario 13: Cuisine, Diff 4 (7 moves), Fresh 0.1x, Anon, Track Alpha
    // -------------------------------------------------------------------------
    test('T3_PAIR_13: Cuisine x Diff 4 (7 moves) x Fresh 0.1x x Anon x Track Alpha', () async {
      await harness.signInAnonymous();
      final now = DateTime(2026, 10, 4, 12, 0);
      final chore = E2EChore(
        id: 'p13',
        name: 'Dégraisser hottes',
        difficulty: 4,
        room: E2ERoomCategory.cuisine,
        periodicityDays: 10,
        lastCompletedAt: now.subtract(const Duration(days: 1)),
      );
      await harness.repository.saveChores(harness.currentUserId!, [chore]);
      harness.currentChores = [chore];

      // 0.1 * 100 + 20 = 30.0
      expect(E2ETargetingEngine.calculateUrgencyScore(chore, now: now), closeTo(30.0, 0.001));

      await harness.startMission(chore);
      expect(harness.targetSequence.length, equals(7));
      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      await harness.validateMission();
      expect(harness.currentProfile?.credits, equals(400));
    });

    // -------------------------------------------------------------------------
    // Scenario 14: SDB, Diff 2 (5 moves), Overdue 1.5x, Email, Track Bravo
    // -------------------------------------------------------------------------
    test('T3_PAIR_14: SDB x Diff 2 (5 moves) x Overdue 1.5x x Email x Track Bravo', () async {
      final uid = await harness.authService.signInWithEmailPassword('bath@pro.com', 'pwd');
      harness.currentUserId = uid;
      final now = DateTime(2026, 10, 4, 12, 0);
      final chore = E2EChore(
        id: 'p14',
        name: 'Nettoyer lavabo',
        difficulty: 2,
        room: E2ERoomCategory.salleDeBain,
        periodicityDays: 2,
        lastCompletedAt: now.subtract(const Duration(days: 3)),
      );
      await harness.repository.saveChores(uid, [chore]);
      harness.currentChores = [chore];

      // 1.5 * 100 + 10 = 160.0
      expect(E2ETargetingEngine.calculateUrgencyScore(chore, now: now), closeTo(160.0, 0.001));

      await harness.startMission(chore);
      expect(harness.targetSequence.length, equals(5));
      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      await harness.validateMission();
      expect(harness.currentProfile?.credits, equals(200));
    });

    // -------------------------------------------------------------------------
    // Scenario 15: Chambre, Diff 4 (7 moves), Overdue 3.0x, Anon, Track Alpha
    // -------------------------------------------------------------------------
    test('T3_PAIR_15: Chambre x Diff 4 (7 moves) x Overdue 3.0x x Anon x Track Alpha', () async {
      await harness.signInAnonymous();
      final now = DateTime(2026, 10, 4, 12, 0);
      final chore = E2EChore(
        id: 'p15',
        name: 'Aspirer recoins sous lit',
        difficulty: 4,
        room: E2ERoomCategory.chambre,
        periodicityDays: 2,
        lastCompletedAt: now.subtract(const Duration(days: 6)),
      );
      await harness.repository.saveChores(harness.currentUserId!, [chore]);
      harness.currentChores = [chore];

      // 3.0 * 100 + 20 = 320.0
      expect(E2ETargetingEngine.calculateUrgencyScore(chore, now: now), closeTo(320.0, 0.001));

      await harness.startMission(chore);
      expect(harness.targetSequence.length, equals(7));
      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      await harness.validateMission();
      expect(harness.currentProfile?.credits, equals(400));
    });
  });
}
