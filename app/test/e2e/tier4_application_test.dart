import 'package:flutter_test/flutter_test.dart';
import 'test_harness.dart';

void main() {
  group('Tier 4: Real-World Application Scenarios (5 Comprehensive Workflows)', () {
    late E2EAppHarness harness;

    setUp(() {
      harness = E2EAppHarness();
    });

    tearDown(() {
      harness.reset();
    });

    // =========================================================================
    // Scenario 1: First-Time Onboarding to Mission Victory
    // =========================================================================
    test('T4_APP_01: First-Time Onboarding to First Mission Victory', () async {
      // 1. Initial State: App starts unauthenticated
      expect(harness.currentUserId, isNull);
      expect(harness.currentProfile, isNull);

      // 2. Auth: User signs in anonymously
      await harness.signInAnonymous();
      expect(harness.currentUserId, isNotNull);
      expect(harness.currentProfile?.onboarded, isFalse);

      // 3. Routing: App detects onboarded == false -> presents Onboarding
      final catalogue = E2EPredefinedCatalogue.getDefault17Chores();
      expect(catalogue.length, equals(17));

      // 4. Customization: User adjusts Kitchen trash periodicity from 2j to 1j
      final customized = catalogue.map((c) {
        if (c.id == 'c3') {
          return c.copyWith(periodicityDays: 1);
        }
        return c;
      }).toList();
      final trashChore = customized.firstWhere((c) => c.id == 'c3');
      expect(trashChore.periodicityDays, equals(1));

      // 5. Submit Onboarding: Persists to repository and updates onboarded flag
      await harness.submitOnboarding(customized);
      expect(harness.currentProfile?.onboarded, isTrue);

      final persistedChores = await harness.repository.getChores(harness.currentUserId!);
      expect(persistedChores.length, equals(17));

      // 6. Home Screen Transition: Targeting engine identifies Top 3 urgent tasks
      final topTargets = harness.getTopUrgentTargets();
      expect(topTargets.length, equals(3));
      final selectedChore = topTargets.first;
      expect(selectedChore.lastCompletedAt, isNull);

      // 7. Start Mission: Launches Stratagem sequence
      await harness.startMission(selectedChore);
      expect(harness.isMissionActive, isTrue);
      expect(harness.targetSequence.length, inInclusiveRange(5, 8));

      // 8. Swipe Gestures: User completes directional code step-by-step
      for (final move in harness.targetSequence) {
        final success = harness.submitSwipe(move);
        expect(success, isTrue);
      }
      expect(harness.isStratagemUnlocked(), isTrue);

      // 9. Mission Timer Screen: Countdown initialized at 600s, audio begins looping
      expect(harness.timerSecondsRemaining, equals(600));
      expect(harness.audioService.isPlaying, isTrue);
      expect(harness.audioService.currentTrack, equals('tactical_ambiance_1.mp3'));

      // 10. Elapsed Time: 60 seconds of cleaning intervention pass
      harness.tickTimer(60);
      expect(harness.timerSecondsRemaining, equals(540));

      // 11. Long-Press Mission Validation
      final finishTime = DateTime(2026, 10, 4, 14, 0);
      await harness.validateMission(completionTime: finishTime);

      // 12. Verification: Audio halted, log stored, chore timestamp updated, credits accrued
      expect(harness.audioService.isPlaying, isFalse);
      expect(harness.isMissionActive, isFalse);

      final missionLogs = await harness.repository.getMissionLogs(harness.currentUserId!);
      expect(missionLogs.length, equals(1));
      expect(missionLogs.first.choreId, equals(selectedChore.id));
      expect(missionLogs.first.durationSeconds, equals(60));
      expect(missionLogs.first.success, isTrue);

      final updatedChores = await harness.repository.getChores(harness.currentUserId!);
      final finishedChore = updatedChores.firstWhere((c) => c.id == selectedChore.id);
      expect(finishedChore.lastCompletedAt, equals(finishTime));

      expect(harness.currentProfile?.credits, greaterThan(0));
      expect(harness.currentProfile?.medals, equals(1));

      // 13. Refresh: Chore is no longer top priority
      final newTopTargets = harness.getTopUrgentTargets(now: finishTime);
      expect(newTopTargets.first.id, isNot(equals(selectedChore.id)));
    });

    // =========================================================================
    // Scenario 2: Returning User Daily Triage
    // =========================================================================
    test('T4_APP_02: Returning User Daily Triage and Sequential Interventions', () async {
      // 1. Setup returning profile
      final uid = 'veteran_user';
      final existingProfile = E2EUserProfile(
        userId: uid,
        agentName: 'Nettoyeur-7',
        level: 5,
        credits: 2400,
        medals: 8,
        onboarded: true,
      );
      await harness.repository.saveUserProfile(existingProfile);

      // 2. Setup catalogue with varying overdue states
      final now = DateTime(2026, 10, 4, 12, 0);
      final choreKitchen = E2EChore(
        id: 'c_kitch',
        name: 'Dégraissage Cuisine',
        difficulty: 3,
        room: E2ERoomCategory.cuisine,
        periodicityDays: 1,
        lastCompletedAt: now.subtract(const Duration(days: 3)), // 3 days overdue (score 315)
      );
      final choreBath = E2EChore(
        id: 'c_bath',
        name: 'Détartrage Baignoire',
        difficulty: 4,
        room: E2ERoomCategory.salleDeBain,
        periodicityDays: 1,
        lastCompletedAt: now.subtract(const Duration(days: 5)), // 5 days overdue (score 520)
      );
      final choreSalon = E2EChore(
        id: 'c_salon',
        name: 'Aspirer Salon',
        difficulty: 2,
        room: E2ERoomCategory.salon,
        periodicityDays: 2,
        lastCompletedAt: now.subtract(const Duration(days: 1)), // 0.5x overdue (score 60)
      );
      final choreChambre = E2EChore(
        id: 'c_bed',
        name: 'Faire le lit',
        difficulty: 1,
        room: E2ERoomCategory.chambre,
        periodicityDays: 1,
        lastCompletedAt: now, // 0 overdue (score 5)
      );

      await harness.repository.saveChores(uid, [choreKitchen, choreBath, choreSalon, choreChambre]);

      // 3. Authenticate returning session
      harness.currentUserId = uid;
      harness.currentProfile = await harness.repository.getUserProfile(uid);
      harness.currentChores = await harness.repository.getChores(uid);
      expect(harness.currentProfile?.onboarded, isTrue);

      // 4. Triage: Verify Top 3 ranking
      final top3 = harness.getTopUrgentTargets(now: now);
      expect(top3.length, equals(3));
      expect(top3[0].id, equals('c_bath'));   // Highest urgency (score 520)
      expect(top3[1].id, equals('c_kitch'));  // Second (score 315)
      expect(top3[2].id, equals('c_salon'));  // Third (score 60)

      // 5. Intervene on #1 (Bathroom)
      await harness.startMission(top3[0]);
      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      expect(harness.isStratagemUnlocked(), isTrue);
      harness.tickTimer(180);
      await harness.validateMission(completionTime: now);

      // 6. Verify bathroom chore timestamp and profile credits updated
      final logsAfter1 = await harness.repository.getMissionLogs(uid);
      expect(logsAfter1.length, equals(1));
      expect(harness.currentProfile?.credits, equals(2800)); // 2400 + 400 (diff 4)
      expect(harness.currentProfile?.medals, equals(9));

      // 7. Intervene on new #1 (Kitchen)
      final topAfter1 = harness.getTopUrgentTargets(now: now);
      expect(topAfter1[0].id, equals('c_kitch'));

      await harness.startMission(topAfter1[0]);
      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      harness.tickTimer(90);
      await harness.validateMission(completionTime: now);

      // 8. Verify cumulative rewards
      final logsAfter2 = await harness.repository.getMissionLogs(uid);
      expect(logsAfter2.length, equals(2));
      expect(harness.currentProfile?.credits, equals(3100)); // 2800 + 300 (diff 3)
      expect(harness.currentProfile?.medals, equals(10));
      expect(harness.currentProfile?.level, equals(7)); // 1 + 3100~/500 = 7
    });

    // =========================================================================
    // Scenario 3: Aborted Mission & Retry Resilience
    // =========================================================================
    test('T4_APP_03: Aborted Mission and Retry Resilience', () async {
      await harness.signInAnonymous();
      final chore = E2EChore(
        id: 'c_abort_flow',
        name: 'Dégraissage Four',
        difficulty: 3,
        room: E2ERoomCategory.cuisine,
        periodicityDays: 1,
        swipeSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP', 'DOWN'],
        lastCompletedAt: null,
      );
      await harness.repository.saveChores(harness.currentUserId!, [chore]);
      harness.currentChores = [chore];

      // 1. Launch Mission
      await harness.startMission(chore);
      expect(harness.isMissionActive, isTrue);

      // 2. Mistake at Step 3
      harness.submitSwipe('UP');
      harness.submitSwipe('DOWN');
      expect(harness.currentSwipeIndex, equals(2));

      final wrongMove = harness.submitSwipe('UP'); // Expected LEFT
      expect(wrongMove, isFalse);
      expect(harness.currentSwipeIndex, equals(0)); // Reset!

      // 3. Retry input correctly
      for (final dir in chore.swipeSequence!) {
        harness.submitSwipe(dir);
      }
      expect(harness.isStratagemUnlocked(), isTrue);
      expect(harness.audioService.isPlaying, isTrue);

      // 4. Timer running
      harness.tickTimer(45);
      expect(harness.timerSecondsRemaining, equals(555));

      // 5. User aborts mission
      await harness.abortMission();
      expect(harness.isMissionActive, isFalse);
      expect(harness.audioService.isPlaying, isFalse);

      // 6. Verify chore status unchanged
      final choresAfterAbort = await harness.repository.getChores(harness.currentUserId!);
      expect(choresAfterAbort.first.lastCompletedAt, isNull);

      final logsAfterAbort = await harness.repository.getMissionLogs(harness.currentUserId!);
      expect(logsAfterAbort, isEmpty);

      // 7. Relaunch and successfully complete this time
      await harness.startMission(chore);
      for (final dir in chore.swipeSequence!) {
        harness.submitSwipe(dir);
      }
      harness.tickTimer(60);
      final now = DateTime.now();
      await harness.validateMission(completionTime: now);

      final logsFinal = await harness.repository.getMissionLogs(harness.currentUserId!);
      expect(logsFinal.length, equals(1));
      expect(logsFinal.first.success, isTrue);
    });

    // =========================================================================
    // Scenario 4: Four-Room Rotation Campaign
    // =========================================================================
    test('T4_APP_04: Four-Room Rotation Campaign', () async {
      await harness.signInAnonymous();
      final chores = [
        E2EChore(id: 'r_cuisine', name: 'Plan cuisine', difficulty: 2, room: E2ERoomCategory.cuisine, periodicityDays: 1),
        E2EChore(id: 'r_sdb', name: 'Douche SDB', difficulty: 3, room: E2ERoomCategory.salleDeBain, periodicityDays: 1),
        E2EChore(id: 'r_salon', name: 'Sol salon', difficulty: 2, room: E2ERoomCategory.salon, periodicityDays: 1),
        E2EChore(id: 'r_chambre', name: 'Lit chambre', difficulty: 3, room: E2ERoomCategory.chambre, periodicityDays: 1),
      ];
      await harness.repository.saveChores(harness.currentUserId!, chores);
      harness.currentChores = chores;

      final testStartTime = DateTime(2026, 10, 4, 8, 0);

      // Round 1: Cuisine
      await harness.startMission(chores[0]);
      for (final move in harness.targetSequence) { harness.submitSwipe(move); }
      await harness.validateMission(completionTime: testStartTime.add(const Duration(minutes: 15)));

      // Round 2: Salle de bain
      await harness.startMission(chores[1]);
      for (final move in harness.targetSequence) { harness.submitSwipe(move); }
      await harness.validateMission(completionTime: testStartTime.add(const Duration(minutes: 30)));

      // Round 3: Salon
      await harness.startMission(chores[2]);
      for (final move in harness.targetSequence) { harness.submitSwipe(move); }
      await harness.validateMission(completionTime: testStartTime.add(const Duration(minutes: 45)));

      // Round 4: Chambre
      await harness.startMission(chores[3]);
      for (final move in harness.targetSequence) { harness.submitSwipe(move); }
      await harness.validateMission(completionTime: testStartTime.add(const Duration(minutes: 60)));

      // Verification: 4 logs recorded across all 4 rooms
      final allLogs = await harness.repository.getMissionLogs(harness.currentUserId!);
      expect(allLogs.length, equals(4));

      final updatedChores = await harness.repository.getChores(harness.currentUserId!);
      for (final chore in updatedChores) {
        expect(chore.lastCompletedAt, isNotNull);
      }

      // Total credits: (200 + 300 + 200 + 300) = 1000 credits
      expect(harness.currentProfile?.credits, equals(1000));
      expect(harness.currentProfile?.medals, equals(4));
      expect(harness.currentProfile?.level, equals(3)); // 1 + 1000~/500 = 3
    });

    // =========================================================================
    // Scenario 5: Offline Resilience and In-Memory Fallback
    // =========================================================================
    test('T4_APP_05: Offline Resilience and In-Memory Fallback Operation', () async {
      // 1. Operates entirely without live network/Firebase
      await harness.signInAnonymous();
      expect(harness.currentUserId, isNotNull);

      // 2. Complete full onboarding cycle
      final defaultCatalogue = E2EPredefinedCatalogue.getDefault17Chores();
      await harness.submitOnboarding(defaultCatalogue);
      expect(harness.currentProfile?.onboarded, isTrue);

      // 3. Verify data persistence in in-memory repository
      final cachedChores = await harness.repository.getChores(harness.currentUserId!);
      expect(cachedChores.length, equals(17));

      // 4. Execute rapid mission
      final top1 = harness.getTopUrgentTargets().first;
      await harness.startMission(top1);
      for (final move in harness.targetSequence) {
        harness.submitSwipe(move);
      }
      expect(harness.isStratagemUnlocked(), isTrue);

      await harness.validateMission();
      final logs = await harness.repository.getMissionLogs(harness.currentUserId!);
      expect(logs.length, equals(1));
      expect(logs.first.success, isTrue);

      // 5. Verify no unhandled socket or network exceptions thrown
      expect(harness.isMissionActive, isFalse);
    });
  });
}
