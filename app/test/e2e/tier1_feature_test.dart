import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_harness.dart';

void main() {
  group('Tier 1: Category-Partition Feature Tests (F01–F15)', () {
    late E2EAppHarness harness;

    setUp(() {
      harness = E2EAppHarness();
    });

    tearDown(() {
      harness.reset();
    });

    // =========================================================================
    // F01: Test Suite Baseline & Health
    // =========================================================================
    group('F01: Test Suite Baseline & Health', () {
      test('T1_F01_01: E2E harness instantiates in clean uninitialized state', () {
        expect(harness.currentUserId, isNull);
        expect(harness.currentProfile, isNull);
        expect(harness.currentChores, isEmpty);
        expect(harness.isMissionActive, isFalse);
      });

      test('T1_F01_02: Mock authentication service connects and emits state cleanly', () async {
        final futureUid = harness.authService.signInAnonymously();
        expect(await futureUid, isNotEmpty);
        expect(harness.authService.currentUserId, isNotEmpty);
      });

      test('T1_F01_03: In-memory repository handles read/write cycles without exception', () async {
        final profile = E2EUserProfile(userId: 'test_user_01');
        await harness.repository.saveUserProfile(profile);
        final fetched = await harness.repository.getUserProfile('test_user_01');
        expect(fetched?.userId, equals('test_user_01'));
      });

      test('T1_F01_04: Audio mock service transitions between stopped and playing states', () async {
        expect(harness.audioService.isPlaying, isFalse);
        await harness.audioService.playMissionLoop('tactical_ambiance_1.mp3');
        expect(harness.audioService.isPlaying, isTrue);
        await harness.audioService.stop();
        expect(harness.audioService.isPlaying, isFalse);
      });

      test('T1_F01_05: Flutter test environment supports async state ticks', () async {
        harness.isMissionActive = true;
        harness.timerSecondsRemaining = 600;
        harness.tickTimer(10);
        expect(harness.timerSecondsRemaining, equals(590));
      });
    });

    // =========================================================================
    // F02: Data Models & Serialization
    // =========================================================================
    group('F02: Data Models & Serialization', () {
      test('T1_F02_01: Chore model instantiates with all attributes intact', () {
        final chore = E2EChore(
          id: 'test_c1',
          name: 'Dégraisser les plaques',
          difficulty: 3,
          room: E2ERoomCategory.cuisine,
          periodicityDays: 2,
          swipeSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP', 'DOWN'],
        );
        expect(chore.id, equals('test_c1'));
        expect(chore.name, equals('Dégraisser les plaques'));
        expect(chore.difficulty, equals(3));
        expect(chore.room, equals(E2ERoomCategory.cuisine));
        expect(chore.periodicityDays, equals(2));
        expect(chore.swipeSequence?.length, equals(6));
      });

      test('T1_F02_02: Chore toMap and fromMap serialization roundtrip is loss-free', () {
        final original = E2EChore(
          id: 'c_roundtrip',
          name: 'Détartrer la douche',
          difficulty: 4,
          room: E2ERoomCategory.salleDeBain,
          periodicityDays: 7,
          lastCompletedAt: DateTime(2026, 10, 1, 10, 0),
          swipeSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP', 'UP', 'DOWN'],
          enabled: true,
        );
        final map = original.toMap();
        final reconstituted = E2EChore.fromMap(map);
        expect(reconstituted, equals(original));
      });

      test('T1_F02_03: MissionLog serialization preserves choreId, completion time, and success', () {
        final log = E2EMissionLog(
          choreId: 'c_log_test',
          completedAt: DateTime(2026, 10, 4, 12, 30),
          success: true,
          durationSeconds: 450,
        );
        final map = log.toMap();
        final restored = E2EMissionLog.fromMap(map);
        expect(restored.choreId, equals('c_log_test'));
        expect(restored.completedAt, equals(DateTime(2026, 10, 4, 12, 30)));
        expect(restored.success, isTrue);
        expect(restored.durationSeconds, equals(450));
      });

      test('T1_F02_04: UserProfile serialization maintains agent level, credits, and medals', () {
        final profile = E2EUserProfile(
          userId: 'u_test',
          agentName: 'Nettoyeur-7',
          level: 42,
          credits: 124500,
          medals: 15,
          onboarded: true,
          preferredAudioTrack: 'tactical_ambiance_2.mp3',
        );
        final map = profile.toMap();
        final restored = E2EUserProfile.fromMap(map);
        expect(restored.agentName, equals('Nettoyeur-7'));
        expect(restored.level, equals(42));
        expect(restored.credits, equals(124500));
        expect(restored.medals, equals(15));
        expect(restored.onboarded, isTrue);
        expect(restored.preferredAudioTrack, equals('tactical_ambiance_2.mp3'));
      });

      test('T1_F02_05: Chore copyWith updates targeted fields while preserving others', () {
        final base = E2EChore(
          id: 'c_base',
          name: 'Aspirer salon',
          difficulty: 2,
          room: E2ERoomCategory.salon,
          periodicityDays: 3,
        );
        final updated = base.copyWith(
          lastCompletedAt: DateTime(2026, 10, 4),
          periodicityDays: 5,
        );
        expect(updated.id, equals('c_base'));
        expect(updated.name, equals('Aspirer salon'));
        expect(updated.periodicityDays, equals(5));
        expect(updated.lastCompletedAt, equals(DateTime(2026, 10, 4)));
        expect(updated.room, equals(E2ERoomCategory.salon));
      });
    });

    // =========================================================================
    // F03: Targeting Engine & Urgency
    // =========================================================================
    group('F03: Targeting Engine & Urgency', () {
      test('T1_F03_01: Never-completed chore yields formula score 1000 + (difficulty * 10)', () {
        final choreDiff1 = E2EChore(id: '1', name: 'T1', difficulty: 1, room: 'Cuisine', periodicityDays: 1);
        final choreDiff3 = E2EChore(id: '2', name: 'T2', difficulty: 3, room: 'Cuisine', periodicityDays: 7);
        final choreDiff5 = E2EChore(id: '3', name: 'T3', difficulty: 5, room: 'Cuisine', periodicityDays: 14);

        expect(E2ETargetingEngine.calculateUrgencyScore(choreDiff1), closeTo(1010.0, 0.001));
        expect(E2ETargetingEngine.calculateUrgencyScore(choreDiff3), closeTo(1030.0, 0.001));
        expect(E2ETargetingEngine.calculateUrgencyScore(choreDiff5), closeTo(1050.0, 0.001));
      });

      test('T1_F03_02: Chore overdue by exactly 1.0 periodicity yields score (100.0) + (difficulty * 5)', () {
        final now = DateTime(2026, 10, 4, 12, 0);
        final completed2DaysAgo = now.subtract(const Duration(days: 2));
        final chore = E2EChore(
          id: '1',
          name: 'T1',
          difficulty: 2,
          room: 'Salon',
          periodicityDays: 2,
          lastCompletedAt: completed2DaysAgo,
        );
        // overdueRatio = 2/2 = 1.0. Score = 1.0 * 100 + 2 * 5 = 110.0
        expect(E2ETargetingEngine.calculateUrgencyScore(chore, now: now), closeTo(110.0, 0.001));
      });

      test('T1_F03_03: Chore overdue by 2.0x periodicity scales urgency score proportionally', () {
        final now = DateTime(2026, 10, 4, 12, 0);
        final completed4DaysAgo = now.subtract(const Duration(days: 4));
        final chore = E2EChore(
          id: '1',
          name: 'T1',
          difficulty: 4,
          room: 'Salon',
          periodicityDays: 2,
          lastCompletedAt: completed4DaysAgo,
        );
        // overdueRatio = 4/2 = 2.0. Score = 2.0 * 100 + 4 * 5 = 220.0
        expect(E2ETargetingEngine.calculateUrgencyScore(chore, now: now), closeTo(220.0, 0.001));
      });

      test('T1_F03_04: Freshly completed chore (0 elapsed time) yields baseline difficulty score', () {
        final now = DateTime(2026, 10, 4, 12, 0);
        final chore = E2EChore(
          id: '1',
          name: 'T1',
          difficulty: 3,
          room: 'Salon',
          periodicityDays: 7,
          lastCompletedAt: now,
        );
        // overdueRatio = 0. Score = 0 + 3 * 5 = 15.0
        expect(E2ETargetingEngine.calculateUrgencyScore(chore, now: now), closeTo(15.0, 0.001));
      });

      test('T1_F03_05: getTopTargets returns top 3 highest urgency chores in strict descending order', () {
        final now = DateTime(2026, 10, 4, 12, 0);
        final chores = [
          E2EChore(id: 'c_fresh', name: 'Fresh', difficulty: 1, room: 'Cuisine', periodicityDays: 1, lastCompletedAt: now),
          E2EChore(id: 'c_undone', name: 'Never Done', difficulty: 2, room: 'Cuisine', periodicityDays: 1, lastCompletedAt: null), // score 1020
          E2EChore(id: 'c_overdue2', name: 'Overdue 2x', difficulty: 3, room: 'Cuisine', periodicityDays: 1, lastCompletedAt: now.subtract(const Duration(days: 2))), // score 215
          E2EChore(id: 'c_overdue3', name: 'Overdue 3x', difficulty: 1, room: 'Cuisine', periodicityDays: 1, lastCompletedAt: now.subtract(const Duration(days: 3))), // score 305
        ];

        final topTargets = E2ETargetingEngine.getTopTargets(chores, count: 3, now: now);
        expect(topTargets.length, equals(3));
        expect(topTargets[0].id, equals('c_undone')); // score 1020
        expect(topTargets[1].id, equals('c_overdue3')); // score 305
        expect(topTargets[2].id, equals('c_overdue2')); // score 215
      });
    });

    // =========================================================================
    // F04: Stratagem Engine & Dynamic Swipes
    // =========================================================================
    group('F04: Stratagem Engine & Dynamic Swipes', () {
      test('T1_F04_01: Difficulty 1 generates sequence of exactly 5 moves', () {
        final seq = E2EStratagemEngine.generateSequenceForDifficulty(1);
        expect(seq.length, equals(5));
        for (final move in seq) {
          expect(E2EStratagemEngine.directions.contains(move), isTrue);
        }
      });

      test('T1_F04_02: Difficulty 3 generates sequence of exactly 6 moves', () {
        final seq = E2EStratagemEngine.generateSequenceForDifficulty(3);
        expect(seq.length, equals(6));
      });

      test('T1_F04_03: Difficulty 4 and 5 generate sequences of 7 and 8 moves respectively', () {
        final seq4 = E2EStratagemEngine.generateSequenceForDifficulty(4);
        final seq5 = E2EStratagemEngine.generateSequenceForDifficulty(5);
        expect(seq4.length, equals(7));
        expect(seq5.length, equals(8));
      });

      test('T1_F04_04: isMoveCorrect returns true when matching current target index', () {
        final target = ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP'];
        expect(E2EStratagemEngine.isMoveCorrect(target, 0, 'UP'), isTrue);
        expect(E2EStratagemEngine.isMoveCorrect(target, 2, 'LEFT'), isTrue);
        expect(E2EStratagemEngine.isMoveCorrect(target, 4, 'UP'), isTrue);
      });

      test('T1_F04_05: isMoveCorrect returns false on wrong directional input', () {
        final target = ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP'];
        expect(E2EStratagemEngine.isMoveCorrect(target, 0, 'DOWN'), isFalse);
        expect(E2EStratagemEngine.isMoveCorrect(target, 1, 'UP'), isFalse);
        expect(E2EStratagemEngine.isMoveCorrect(target, 3, 'LEFT'), isFalse);
      });
    });

    // =========================================================================
    // F05: Audio Assets & AudioService
    // =========================================================================
    group('F05: Audio Assets & AudioService', () {
      test('T1_F05_01: playMissionLoop marks audio service active with designated track', () async {
        await harness.audioService.playMissionLoop('tactical_ambiance_1.mp3');
        expect(harness.audioService.isPlaying, isTrue);
        expect(harness.audioService.currentTrack, equals('tactical_ambiance_1.mp3'));
      });

      test('T1_F05_02: stop halts playback and resets currentTrack to null', () async {
        await harness.audioService.playMissionLoop('tactical_ambiance_2.mp3');
        await harness.audioService.stop();
        expect(harness.audioService.isPlaying, isFalse);
        expect(harness.audioService.currentTrack, isNull);
      });

      test('T1_F05_03: Calling stop when already stopped is a benign no-op', () async {
        expect(() async => await harness.audioService.stop(), returnsNormally);
      });

      test('T1_F05_04: Audio service plays alternative tactical track Bravo', () async {
        await harness.audioService.playMissionLoop('tactical_ambiance_2.mp3');
        expect(harness.audioService.currentTrack, equals('tactical_ambiance_2.mp3'));
      });

      test('T1_F05_05: dispose cleanly halts playback and releases state', () {
        harness.audioService.dispose();
        expect(harness.audioService.isPlaying, isFalse);
        expect(harness.audioService.currentTrack, isNull);
      });
    });

    // =========================================================================
    // F06: Firebase Dependencies & Service Layer
    // =========================================================================
    group('F06: Firebase Dependencies & Service Layer', () {
      test('T1_F06_01: Anonymous authentication generates unique user id', () async {
        final uid = await harness.authService.signInAnonymously();
        expect(uid, startsWith('anon_'));
        expect(harness.authService.currentUserId, equals(uid));
      });

      test('T1_F06_02: Email/password authentication logs in and emits state change', () async {
        final uid = await harness.authService.signInWithEmailPassword('cleaner@tactical.hud', 'secret123');
        expect(uid, contains('cleaner'));
        expect(harness.authService.currentUserId, equals(uid));
      });

      test('T1_F06_03: Repository saves and loads user profile accurately', () async {
        final profile = E2EUserProfile(userId: 'u_123', agentName: 'Nettoyeur-Prime', credits: 500);
        await harness.repository.saveUserProfile(profile);
        final loaded = await harness.repository.getUserProfile('u_123');
        expect(loaded?.agentName, equals('Nettoyeur-Prime'));
        expect(loaded?.credits, equals(500));
      });

      test('T1_F06_04: Repository saves and updates chores for a specific user', () async {
        final chores = [
          E2EChore(id: 'ch1', name: 'Vaisselle', difficulty: 1, room: 'Cuisine', periodicityDays: 1),
        ];
        await harness.repository.saveChores('u_123', chores);
        final fetched = await harness.repository.getChores('u_123');
        expect(fetched.length, equals(1));
        expect(fetched.first.name, equals('Vaisselle'));
      });

      test('T1_F06_05: Repository appends and retrieves mission logs chronologically', () async {
        final log = E2EMissionLog(
          choreId: 'ch1',
          completedAt: DateTime(2026, 10, 4, 15, 0),
          success: true,
          durationSeconds: 300,
        );
        await harness.repository.logMission('u_123', log);
        final logs = await harness.repository.getMissionLogs('u_123');
        expect(logs.length, equals(1));
        expect(logs.first.choreId, equals('ch1'));
        expect(logs.first.durationSeconds, equals(300));
      });
    });

    // =========================================================================
    // F07: Onboarding Room Catalogue
    // =========================================================================
    group('F07: Onboarding Room Catalogue', () {
      test('T1_F07_01: Catalogue contains all 4 mandatory rooms', () {
        final catalogue = E2EPredefinedCatalogue.getDefault17Chores();
        final rooms = catalogue.map((c) => c.room).toSet();
        expect(rooms.contains(E2ERoomCategory.cuisine), isTrue);
        expect(rooms.contains(E2ERoomCategory.salleDeBain), isTrue);
        expect(rooms.contains(E2ERoomCategory.salon), isTrue);
        expect(rooms.contains(E2ERoomCategory.chambre), isTrue);
      });

      test('T1_F07_02: Catalogue contains exactly 17 predefined chores', () {
        final catalogue = E2EPredefinedCatalogue.getDefault17Chores();
        expect(catalogue.length, equals(17));
      });

      test('T1_F07_03: Cuisine room contains exactly 5 chores with valid periodicities', () {
        final catalogue = E2EPredefinedCatalogue.getDefault17Chores();
        final kitchenChores = catalogue.where((c) => c.room == E2ERoomCategory.cuisine).toList();
        expect(kitchenChores.length, equals(5));
        for (final c in kitchenChores) {
          expect(c.periodicityDays, inInclusiveRange(1, 7));
        }
      });

      test('T1_F07_04: Salle de bain room contains exactly 4 chores', () {
        final catalogue = E2EPredefinedCatalogue.getDefault17Chores();
        final sdbChores = catalogue.where((c) => c.room == E2ERoomCategory.salleDeBain).toList();
        expect(sdbChores.length, equals(4));
      });

      test('T1_F07_05: Salon and Chambre each contain exactly 4 chores', () {
        final catalogue = E2EPredefinedCatalogue.getDefault17Chores();
        final salonChores = catalogue.where((c) => c.room == E2ERoomCategory.salon).toList();
        final chambreChores = catalogue.where((c) => c.room == E2ERoomCategory.chambre).toList();
        expect(salonChores.length, equals(4));
        expect(chambreChores.length, equals(4));
      });
    });

    // =========================================================================
    // F08: Onboarding Customizer & Persistence
    // =========================================================================
    group('F08: Onboarding Customizer & Persistence', () {
      test('T1_F08_01: Customizer allows updating chore periodicity', () {
        final base = E2EPredefinedCatalogue.getDefault17Chores();
        final modified = base.map((c) {
          if (c.id == 'c1') return c.copyWith(periodicityDays: 3);
          return c;
        }).toList();

        final c1 = modified.firstWhere((c) => c.id == 'c1');
        expect(c1.periodicityDays, equals(3));
      });

      test('T1_F08_02: Customizer allows toggling chores on and off', () {
        final base = E2EPredefinedCatalogue.getDefault17Chores();
        final toggled = base.map((c) {
          if (c.id == 'c3') return c.copyWith(enabled: false);
          return c;
        }).toList();

        final c3 = toggled.firstWhere((c) => c.id == 'c3');
        expect(c3.enabled, isFalse);
      });

      test('T1_F08_03: Submitting valid customized catalogue persists all chores', () async {
        await harness.signInAnonymous();
        final catalogue = E2EPredefinedCatalogue.getDefault17Chores();
        await harness.submitOnboarding(catalogue);

        final stored = await harness.repository.getChores(harness.currentUserId!);
        expect(stored.length, equals(17));
      });

      test('T1_F08_04: Submitting onboarding updates user profile onboarded flag to true', () async {
        await harness.signInAnonymous();
        expect(harness.currentProfile?.onboarded, isFalse);

        final catalogue = E2EPredefinedCatalogue.getDefault17Chores();
        await harness.submitOnboarding(catalogue);

        expect(harness.currentProfile?.onboarded, isTrue);
        final persisted = await harness.repository.getUserProfile(harness.currentUserId!);
        expect(persisted?.onboarded, isTrue);
      });

      test('T1_F08_05: Onboarding enforces at least 1 active chore per mandatory room', () async {
        await harness.signInAnonymous();
        final catalogue = E2EPredefinedCatalogue.getDefault17Chores().map((c) {
          if (c.room == E2ERoomCategory.cuisine) return c.copyWith(enabled: false);
          return c;
        }).toList();

        expect(
          harness.submitOnboarding(catalogue),
          throwsArgumentError,
        );
      });
    });

    // =========================================================================
    // F09: Auth & Onboarding Routing
    // =========================================================================
    group('F09: Auth & Onboarding Routing', () {
      test('T1_F09_01: Unauthenticated session starts with null user id', () {
        expect(harness.authService.currentUserId, isNull);
      });

      test('T1_F09_02: Fresh authenticated user defaults to onboarded == false', () async {
        await harness.signInAnonymous();
        expect(harness.currentProfile?.onboarded, isFalse);
      });

      test('T1_F09_03: Completed onboarding sets onboarded == true routing to home', () async {
        await harness.signInAnonymous();
        await harness.submitOnboarding(E2EPredefinedCatalogue.getDefault17Chores());
        expect(harness.currentProfile?.onboarded, isTrue);
      });

      test('T1_F09_04: Sign out resets active session to unauthenticated state', () async {
        await harness.signInAnonymous();
        expect(harness.currentUserId, isNotNull);
        await harness.authService.signOut();
        expect(harness.authService.currentUserId, isNull);
      });

      test('T1_F09_05: Returning authenticated user with onboarded true preserves state', () async {
        final profile = E2EUserProfile(userId: 'u_returning', onboarded: true);
        await harness.repository.saveUserProfile(profile);
        final fetched = await harness.repository.getUserProfile('u_returning');
        expect(fetched?.onboarded, isTrue);
      });
    });

    // =========================================================================
    // F10: Mil-Tech Dark Tactical Theme
    // =========================================================================
    group('F10: Mil-Tech Dark Tactical Theme', () {
      test('T1_F10_01: Background black matches specification #0B0E14', () {
        expect(E2EMilTechColors.backgroundBlack, equals(const Color(0xFF0B0E14)));
      });

      test('T1_F10_02: Neon accent colors match specification values', () {
        expect(E2EMilTechColors.neonAmber, equals(const Color(0xFFFFA500)));
        expect(E2EMilTechColors.neonYellow, equals(const Color(0xFFFFCC00)));
        expect(E2EMilTechColors.neonCyan, equals(const Color(0xFF00E5FF)));
      });

      test('T1_F10_03: Alert and status colors match Green #00E676 and Red #FF1744', () {
        expect(E2EMilTechColors.neonGreen, equals(const Color(0xFF00E676)));
        expect(E2EMilTechColors.neonRed, equals(const Color(0xFFFF1744)));
      });

      test('T1_F10_04: Panel shades provide dark tactical depth', () {
        expect(E2EMilTechColors.panelDark, equals(const Color(0xFF141922)));
        expect(E2EMilTechColors.panelBorder, equals(const Color(0xFF263040)));
        expect(E2EMilTechColors.panelBevel, equals(const Color(0xFF333E50)));
      });

      test('T1_F10_05: Neutral text colors provide high contrast', () {
        expect(E2EMilTechColors.textPrimary, equals(const Color(0xFFFFFFFF)));
        expect(E2EMilTechColors.textSecondary, equals(const Color(0xFF90A4AE)));
        expect(E2EMilTechColors.textMuted, equals(const Color(0xFF546E7A)));
      });
    });

    // =========================================================================
    // F11: Tactical Home Screen HUD
    // =========================================================================
    group('F11: Tactical Home Screen HUD', () {
      test('T1_F11_01: HUD displays Agent ID and Level from profile', () async {
        await harness.signInAnonymous();
        expect(harness.currentProfile?.agentName, equals('Nettoyeur-1'));
        expect(harness.currentProfile?.level, equals(1));
      });

      test('T1_F11_02: HUD displays Cleaning Credits and Medals counters', () async {
        await harness.signInAnonymous();
        expect(harness.currentProfile?.credits, equals(0));
        expect(harness.currentProfile?.medals, equals(0));
      });

      test('T1_F11_03: Tactical sector map detects room of highest urgency chore', () async {
        final now = DateTime(2026, 10, 4, 12, 0);
        final chores = [
          E2EChore(id: '1', name: 'Salon Chore', difficulty: 1, room: E2ERoomCategory.salon, periodicityDays: 1, lastCompletedAt: now),
          E2EChore(id: '2', name: 'Kitchen Chore', difficulty: 4, room: E2ERoomCategory.cuisine, periodicityDays: 1, lastCompletedAt: null),
        ];
        final top = E2ETargetingEngine.getTopTargets(chores, count: 1, now: now);
        expect(top.first.room, equals(E2ERoomCategory.cuisine));
      });

      test('T1_F11_04: Home screen carousel provides top 3 urgent chores', () async {
        await harness.signInAnonymous();
        await harness.submitOnboarding(E2EPredefinedCatalogue.getDefault17Chores());
        final top3 = harness.getTopUrgentTargets();
        expect(top3.length, equals(3));
      });

      test('T1_F11_05: Starting mission sets active chore on harness', () async {
        await harness.signInAnonymous();
        await harness.submitOnboarding(E2EPredefinedCatalogue.getDefault17Chores());
        final top1 = harness.getTopUrgentTargets().first;
        await harness.startMission(top1);
        expect(harness.isMissionActive, isTrue);
        expect(harness.activeChore?.id, equals(top1.id));
      });
    });

    // =========================================================================
    // F12: Dynamic Gesture Screen UI
    // =========================================================================
    group('F12: Dynamic Gesture Screen UI', () {
      test('T1_F12_01: Target swipe sequence has length between 5 and 8 moves', () async {
        final chore = E2EChore(id: 'c', name: 'Test', difficulty: 3, room: 'Cuisine', periodicityDays: 1);
        await harness.startMission(chore);
        expect(harness.targetSequence.length, inInclusiveRange(5, 8));
      });

      test('T1_F12_02: Submitting correct swipe advances sequence index', () async {
        final chore = E2EChore(
          id: 'c',
          name: 'Test',
          difficulty: 1,
          room: 'Cuisine',
          periodicityDays: 1,
          swipeSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP'],
        );
        await harness.startMission(chore);
        expect(harness.currentSwipeIndex, equals(0));

        final result = harness.submitSwipe('UP');
        expect(result, isTrue);
        expect(harness.currentSwipeIndex, equals(1));
      });

      test('T1_F12_03: Submitting wrong swipe resets sequence index back to 0', () async {
        final chore = E2EChore(
          id: 'c',
          name: 'Test',
          difficulty: 1,
          room: 'Cuisine',
          periodicityDays: 1,
          swipeSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP'],
        );
        await harness.startMission(chore);
        harness.submitSwipe('UP'); // step 1 ok
        expect(harness.currentSwipeIndex, equals(1));

        final failResult = harness.submitSwipe('LEFT'); // wrong move
        expect(failResult, isFalse);
        expect(harness.currentSwipeIndex, equals(0));
      });

      test('T1_F12_04: Completing full swipe sequence unlocks stratagem', () async {
        final chore = E2EChore(
          id: 'c',
          name: 'Test',
          difficulty: 1,
          room: 'Cuisine',
          periodicityDays: 1,
          swipeSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP'],
        );
        await harness.startMission(chore);
        harness.submitSwipe('UP');
        harness.submitSwipe('DOWN');
        harness.submitSwipe('LEFT');
        harness.submitSwipe('RIGHT');
        harness.submitSwipe('UP');

        expect(harness.isStratagemUnlocked(), isTrue);
      });

      test('T1_F12_05: Completing swipe sequence triggers audio pressure player', () async {
        final chore = E2EChore(
          id: 'c',
          name: 'Test',
          difficulty: 1,
          room: 'Cuisine',
          periodicityDays: 1,
          swipeSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP'],
        );
        await harness.startMission(chore);
        for (final dir in chore.swipeSequence!) {
          harness.submitSwipe(dir);
        }
        expect(harness.audioService.isPlaying, isTrue);
      });
    });

    // =========================================================================
    // F13: Tactical Mission Timer Screen
    // =========================================================================
    group('F13: Tactical Mission Timer Screen', () {
      test('T1_F13_01: Timer initializes at 10 minutes (600 seconds)', () async {
        final chore = E2EChore(id: 'c', name: 'Test', difficulty: 1, room: 'Cuisine', periodicityDays: 1);
        await harness.startMission(chore);
        expect(harness.timerSecondsRemaining, equals(600));
      });

      test('T1_F13_02: Timer decrements accurately on ticks', () async {
        final chore = E2EChore(id: 'c', name: 'Test', difficulty: 1, room: 'Cuisine', periodicityDays: 1);
        await harness.startMission(chore);
        harness.tickTimer(30);
        expect(harness.timerSecondsRemaining, equals(570));
      });

      test('T1_F13_03: Validating mission stops audio player', () async {
        final chore = E2EChore(
          id: 'c',
          name: 'Test',
          difficulty: 1,
          room: 'Cuisine',
          periodicityDays: 1,
          swipeSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP'],
        );
        await harness.startMission(chore);
        for (final dir in chore.swipeSequence!) {
          harness.submitSwipe(dir);
        }
        expect(harness.audioService.isPlaying, isTrue);

        await harness.validateMission();
        expect(harness.audioService.isPlaying, isFalse);
      });

      test('T1_F13_04: Aborting mission stops audio player and cancels active mission', () async {
        final chore = E2EChore(id: 'c', name: 'Test', difficulty: 1, room: 'Cuisine', periodicityDays: 1);
        await harness.startMission(chore);
        await harness.audioService.playMissionLoop('tactical_ambiance_1.mp3');

        await harness.abortMission();
        expect(harness.isMissionActive, isFalse);
        expect(harness.audioService.isPlaying, isFalse);
      });

      test('T1_F13_05: Mission validation records accurate duration in mission log', () async {
        await harness.signInAnonymous();
        final chore = E2EChore(id: 'c_dur', name: 'Timer Dur', difficulty: 2, room: 'Cuisine', periodicityDays: 1);
        await harness.repository.saveChores(harness.currentUserId!, [chore]);
        await harness.startMission(chore);
        harness.tickTimer(120); // 120 seconds elapsed

        await harness.validateMission();
        final logs = await harness.repository.getMissionLogs(harness.currentUserId!);
        expect(logs.first.durationSeconds, equals(120));
      });
    });

    // =========================================================================
    // F14: Vocabulary Purge
    // =========================================================================
    group('F14: Vocabulary Purge', () {
      test('T1_F14_01: Lexicon validator detects forbidden term squad', () {
        expect(E2ELexiconValidator.containsForbiddenTerms('JOIN SQUAD MISSION'), isTrue);
        expect(E2ELexiconValidator.findViolations('squad status'), contains('squad'));
      });

      test('T1_F14_02: Lexicon validator detects forbidden term escouade', () {
        expect(E2ELexiconValidator.containsForbiddenTerms('Intervention d\'escouade'), isTrue);
      });

      test('T1_F14_03: Lexicon validator detects forbidden terms automaton and arsenal', () {
        expect(E2ELexiconValidator.containsForbiddenTerms('Automaton attack'), isTrue);
        expect(E2ELexiconValidator.containsForbiddenTerms('ARSENAL SECTOR'), isTrue);
      });

      test('T1_F14_04: Domestic cleaning terms pass lexicon validation cleanly', () {
        final approvedStrings = [
          'DÉGRAISSAGE PLAQUES DE CUISSON',
          'DÉTARTRAGE DOUCHE & LAVABO',
          'COMMANDEMENT DU FOYER',
          'PLANNING DES TÂCHES MÉNAGÈRES',
          'MATÉRIEL & PRODUITS D\'ENTRETIEN',
          'AGENT NETTOYEUR-1',
          'BOUTIQUE ÉCO DU LOGIS',
        ];
        for (final str in approvedStrings) {
          expect(E2ELexiconValidator.containsForbiddenTerms(str), isFalse,
              reason: 'String "$str" should not trigger violations');
        }
      });

      test('T1_F14_05: Default 17 chores catalogue has zero forbidden terms', () {
        final catalogue = E2EPredefinedCatalogue.getDefault17Chores();
        for (final chore in catalogue) {
          expect(E2ELexiconValidator.containsForbiddenTerms(chore.name), isFalse);
          expect(E2ELexiconValidator.containsForbiddenTerms(chore.room), isFalse);
        }
      });
    });

    // =========================================================================
    // F15: E2E Integration & Hardening
    // =========================================================================
    group('F15: E2E Integration & Hardening', () {
      test('T1_F15_01: Validating mission updates chore lastCompletedAt timestamp', () async {
        await harness.signInAnonymous();
        final chore = E2EChore(id: 'c15', name: 'Nettoyage 15', difficulty: 2, room: 'Salon', periodicityDays: 2);
        await harness.repository.saveChores(harness.currentUserId!, [chore]);
        await harness.startMission(chore);

        final testTime = DateTime(2026, 10, 4, 16, 45);
        await harness.validateMission(completionTime: testTime);

        final updated = (await harness.repository.getChores(harness.currentUserId!)).first;
        expect(updated.lastCompletedAt, equals(testTime));
      });

      test('T1_F15_02: Validating mission awards credits based on chore difficulty', () async {
        await harness.signInAnonymous();
        final chore = E2EChore(id: 'c15_diff3', name: 'Diff 3 Chore', difficulty: 3, room: 'Salon', periodicityDays: 2);
        await harness.repository.saveChores(harness.currentUserId!, [chore]);
        await harness.startMission(chore);

        final initialCredits = harness.currentProfile?.credits ?? 0;
        await harness.validateMission();

        // 100 * difficulty = 300 credits
        expect(harness.currentProfile?.credits, equals(initialCredits + 300));
        expect(harness.currentProfile?.medals, equals(1));
      });

      test('T1_F15_03: Completed chore urgency score drops drastically', () async {
        final now = DateTime(2026, 10, 4, 12, 0);
        final chore = E2EChore(id: 'c_urgent', name: 'Urgent', difficulty: 2, room: 'Cuisine', periodicityDays: 2, lastCompletedAt: null);
        final uncompletedScore = E2ETargetingEngine.calculateUrgencyScore(chore, now: now);
        expect(uncompletedScore, closeTo(1020.0, 0.001));

        final completedChore = chore.copyWith(lastCompletedAt: now);
        final completedScore = E2ETargetingEngine.calculateUrgencyScore(completedChore, now: now);
        expect(completedScore, closeTo(10.0, 0.001)); // drops from 1020 to 10
      });

      test('T1_F15_04: Aborting mission does not update chore timestamp', () async {
        await harness.signInAnonymous();
        final chore = E2EChore(id: 'c_abort', name: 'Abort Me', difficulty: 1, room: 'Cuisine', periodicityDays: 1, lastCompletedAt: null);
        await harness.repository.saveChores(harness.currentUserId!, [chore]);
        await harness.startMission(chore);

        await harness.abortMission();
        final stored = (await harness.repository.getChores(harness.currentUserId!)).first;
        expect(stored.lastCompletedAt, isNull);
      });

      test('T1_F15_05: Consecutively completing missions accumulates level and credits', () async {
        await harness.signInAnonymous();
        final chore1 = E2EChore(id: 'c_seq1', name: 'Step 1', difficulty: 2, room: 'Salon', periodicityDays: 1);
        final chore2 = E2EChore(id: 'c_seq2', name: 'Step 2', difficulty: 3, room: 'Salon', periodicityDays: 1);
        await harness.repository.saveChores(harness.currentUserId!, [chore1, chore2]);

        await harness.startMission(chore1);
        await harness.validateMission();

        await harness.startMission(chore2);
        await harness.validateMission();

        // diff 2 (200) + diff 3 (300) = 500 credits -> Level 2
        expect(harness.currentProfile?.credits, equals(500));
        expect(harness.currentProfile?.medals, equals(2));
        expect(harness.currentProfile?.level, equals(2));
      });
    });
  });
}
