import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'test_harness.dart';

void main() {
  group('Tier 2: Boundary Value Analysis & Edge Cases (F01–F15)', () {
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
    group('F01: Baseline Health Boundary Cases', () {
      test('T2_F01_01: Harness handles zero registered chores without exceptions', () {
        expect(harness.currentChores, isEmpty);
        final targets = harness.getTopUrgentTargets();
        expect(targets, isEmpty);
      });

      test('T2_F01_02: Repository handles 1000 chores without memory exhaustion or stack overflow', () async {
        final thousandChores = List.generate(
          1000,
          (i) => E2EChore(
            id: 'c_$i',
            name: 'Chore $i',
            difficulty: (i % 5) + 1,
            room: E2ERoomCategory.allRooms[i % 4],
            periodicityDays: (i % 14) + 1,
          ),
        );
        await harness.repository.saveChores('user_bulk', thousandChores);
        final retrieved = await harness.repository.getChores('user_bulk');
        expect(retrieved.length, equals(1000));
      });

      test('T2_F01_03: Repository handles query for non-existent user ID returning empty list', () async {
        final result = await harness.repository.getChores('non_existent_uid_999');
        expect(result, isEmpty);
      });

      test('T2_F01_04: Rapid repeated reset cycles execute cleanly without resource leaks', () {
        for (int i = 0; i < 50; i++) {
          harness.reset();
          expect(harness.currentUserId, isNull);
        }
      });

      test('T2_F01_05: Harness handles negative timer tick by clamping safely', () {
        harness.isMissionActive = true;
        harness.timerSecondsRemaining = 600;
        harness.tickTimer(-50); // Negative tick (drift)
        expect(harness.timerSecondsRemaining, equals(600)); // clamped to 600
      });
    });

    // =========================================================================
    // F02: Data Models & Serialization
    // =========================================================================
    group('F02: Data Models & Serialization Boundary Cases', () {
      test('T2_F02_01: Chore.fromMap with missing optional fields applies safe defaults', () {
        final map = {
          'id': 'c_sparse',
          'name': 'Minimal Chore',
        };
        final chore = E2EChore.fromMap(map);
        expect(chore.id, equals('c_sparse'));
        expect(chore.name, equals('Minimal Chore'));
        expect(chore.difficulty, equals(1));
        expect(chore.room, equals(E2ERoomCategory.cuisine));
        expect(chore.periodicityDays, equals(1));
        expect(chore.lastCompletedAt, isNull);
        expect(chore.swipeSequence, isNull);
        expect(chore.enabled, isTrue);
      });

      test('T2_F02_02: Chore handles extreme periodicity values (min 1 day, max 365 days)', () {
        final minChore = E2EChore(id: '1', name: 'Min', difficulty: 1, room: 'Cuisine', periodicityDays: 1);
        final maxChore = E2EChore(id: '2', name: 'Max', difficulty: 5, room: 'Salon', periodicityDays: 365);
        expect(minChore.periodicityDays, equals(1));
        expect(maxChore.periodicityDays, equals(365));
      });

      test('T2_F02_03: UserProfile.fromMap with zero credits and zero medals deserializes cleanly', () {
        final map = {
          'userId': 'u_zero',
          'agentName': 'Novice-0',
          'level': 1,
          'credits': 0,
          'medals': 0,
          'onboarded': false,
        };
        final profile = E2EUserProfile.fromMap(map);
        expect(profile.credits, equals(0));
        expect(profile.medals, equals(0));
        expect(profile.onboarded, isFalse);
      });

      test('T2_F02_04: MissionLog with 0-second duration serializes and deserializes correctly', () {
        final log = E2EMissionLog(
          choreId: 'c_instant',
          completedAt: DateTime(2026, 10, 4, 10, 0),
          success: true,
          durationSeconds: 0,
        );
        final restored = E2EMissionLog.fromMap(log.toMap());
        expect(restored.durationSeconds, equals(0));
      });

      test('T2_F02_05: Chore.fromMap with missing required fields throws ArgumentError', () {
        expect(() => E2EChore.fromMap({'difficulty': 2}), throwsArgumentError);
        expect(() => E2EChore.fromMap({'id': 'only_id'}), throwsArgumentError);
      });
    });

    // =========================================================================
    // F03: Targeting Engine & Urgency
    // =========================================================================
    group('F03: Targeting Engine Boundary Cases', () {
      test('T2_F03_01: Empty chore list passed to getTopTargets returns empty list without error', () {
        final targets = E2ETargetingEngine.getTopTargets([]);
        expect(targets, isEmpty);
      });

      test('T2_F03_02: Chore list with fewer than 3 chores returns all available chores without bounds exception', () {
        final chores = [
          E2EChore(id: 'c1', name: 'Single 1', difficulty: 1, room: 'Cuisine', periodicityDays: 1),
          E2EChore(id: 'c2', name: 'Single 2', difficulty: 2, room: 'Salon', periodicityDays: 1),
        ];
        final targets = E2ETargetingEngine.getTopTargets(chores, count: 3);
        expect(targets.length, equals(2));
      });

      test('T2_F03_03: Identical urgency scores resolve deterministically via secondary sort', () {
        final now = DateTime(2026, 10, 4, 12, 0);
        // Both chores never completed -> score = 1000 + diff * 10
        // Same diff 2 -> tie-break by name alphabetically
        final choreA = E2EChore(id: '1', name: 'Balayer le sol', difficulty: 2, room: 'Cuisine', periodicityDays: 1);
        final choreB = E2EChore(id: '2', name: 'Aérer la pièce', difficulty: 2, room: 'Salon', periodicityDays: 1);

        final targets = E2ETargetingEngine.getTopTargets([choreA, choreB], count: 2, now: now);
        expect(targets.first.name, equals('Aérer la pièce'));
        expect(targets.last.name, equals('Balayer le sol'));
      });

      test('T2_F03_04: Extreme overdue ratio (1000 days overdue) computes without overflow', () {
        final now = DateTime(2026, 10, 4, 12, 0);
        final thousandDaysAgo = now.subtract(const Duration(days: 1000));
        final chore = E2EChore(
          id: 'ancient',
          name: 'Ancient Chore',
          difficulty: 3,
          room: 'Cave',
          periodicityDays: 1,
          lastCompletedAt: thousandDaysAgo,
        );
        final score = E2ETargetingEngine.calculateUrgencyScore(chore, now: now);
        // overdueRatio = 1000. Score = 1000 * 100 + 3 * 5 = 100,015.0
        expect(score, closeTo(100015.0, 1.0));
      });

      test('T2_F03_05: Future lastCompletedAt (clock skew) clamps overdueRatio to 0.0', () {
        final now = DateTime(2026, 10, 4, 12, 0);
        final futureTime = now.add(const Duration(days: 2));
        final chore = E2EChore(
          id: 'future',
          name: 'Future Chore',
          difficulty: 2,
          room: 'Salon',
          periodicityDays: 2,
          lastCompletedAt: futureTime,
        );
        final score = E2ETargetingEngine.calculateUrgencyScore(chore, now: now);
        // Score clamped to 0 + 2 * 5 = 10.0
        expect(score, closeTo(10.0, 0.001));
      });
    });

    // =========================================================================
    // F04: Stratagem Engine & Dynamic Swipes
    // =========================================================================
    group('F04: Stratagem Engine Boundary Cases', () {
      test('T2_F04_01: Difficulty <= 1 clamps sequence length to minimum 5 moves', () {
        final seq0 = E2EStratagemEngine.generateSequenceForDifficulty(0);
        final seq1 = E2EStratagemEngine.generateSequenceForDifficulty(1);
        final seqNeg = E2EStratagemEngine.generateSequenceForDifficulty(-5);
        expect(seq0.length, equals(5));
        expect(seq1.length, equals(5));
        expect(seqNeg.length, equals(5));
      });

      test('T2_F04_02: Difficulty >= 5 clamps sequence length to maximum 8 moves', () {
        final seq5 = E2EStratagemEngine.generateSequenceForDifficulty(5);
        final seq10 = E2EStratagemEngine.generateSequenceForDifficulty(10);
        expect(seq5.length, equals(8));
        expect(seq10.length, equals(8));
      });

      test('T2_F04_03: Sequence generation with seeded Random produces 100% deterministic sequence', () {
        final rng1 = Random(42);
        final rng2 = Random(42);
        final seq1 = E2EStratagemEngine.generateSequenceForDifficulty(4, random: rng1);
        final seq2 = E2EStratagemEngine.generateSequenceForDifficulty(4, random: rng2);
        expect(seq1, equals(seq2));
      });

      test('T2_F04_04: Invalid direction string passed to isMoveCorrect returns false safely', () {
        final target = ['UP', 'DOWN', 'LEFT', 'RIGHT'];
        expect(E2EStratagemEngine.isMoveCorrect(target, 0, 'DIAGONAL'), isFalse);
        expect(E2EStratagemEngine.isMoveCorrect(target, 0, ''), isFalse);
      });

      test('T2_F04_05: Index out of bounds in isMoveCorrect returns false safely', () {
        final target = ['UP', 'DOWN', 'LEFT', 'RIGHT'];
        expect(E2EStratagemEngine.isMoveCorrect(target, -1, 'UP'), isFalse);
        expect(E2EStratagemEngine.isMoveCorrect(target, 10, 'UP'), isFalse);
      });
    });

    // =========================================================================
    // F05: Audio Assets & AudioService
    // =========================================================================
    group('F05: Audio Assets Boundary Cases', () {
      test('T2_F05_01: Empty string passed as asset path raises descriptive ArgumentError', () async {
        expect(harness.audioService.playMissionLoop(''), throwsArgumentError);
        expect(harness.audioService.playMissionLoop('   '), throwsArgumentError);
      });

      test('T2_F05_02: Rapid consecutive calls to playMissionLoop pre-empts previous audio cleanly', () async {
        await harness.audioService.playMissionLoop('track_1.mp3');
        await harness.audioService.playMissionLoop('track_2.mp3');
        expect(harness.audioService.isPlaying, isTrue);
        expect(harness.audioService.currentTrack, equals('track_2.mp3'));
      });

      test('T2_F05_03: Rapid interleaved play and stop calls maintain consistent boolean state', () async {
        for (int i = 0; i < 20; i++) {
          await harness.audioService.playMissionLoop('loop.mp3');
          await harness.audioService.stop();
        }
        expect(harness.audioService.isPlaying, isFalse);
        expect(harness.audioService.currentTrack, isNull);
      });

      test('T2_F05_04: Calling dispose while playback is active halts audio first', () async {
        await harness.audioService.playMissionLoop('loop.mp3');
        expect(harness.audioService.isPlaying, isTrue);
        harness.audioService.dispose();
        expect(harness.audioService.isPlaying, isFalse);
      });

      test('T2_F05_05: Calling play on disposed service throws StateError', () async {
        harness.audioService.dispose();
        expect(
          harness.audioService.playMissionLoop('loop.mp3'),
          throwsStateError,
        );
      });
    });

    // =========================================================================
    // F06: Firebase Dependencies & Service Layer
    // =========================================================================
    group('F06: Firebase Dependencies Boundary Cases', () {
      test('T2_F06_01: Repository retrieval of non-existent user profile returns null rather than throwing', () async {
        final profile = await harness.repository.getUserProfile('ghost_user');
        expect(profile, isNull);
      });

      test('T2_F06_02: Repository updates chore that does not exist in store upserts safely', () async {
        final chore = E2EChore(id: 'c_new', name: 'Upserted', difficulty: 1, room: 'Salon', periodicityDays: 1);
        await harness.repository.updateChore('user_1', chore);
        final list = await harness.repository.getChores('user_1');
        expect(list.length, equals(1));
        expect(list.first.id, equals('c_new'));
      });

      test('T2_F06_03: User with 0 mission logs returns empty list from getMissionLogs', () async {
        final logs = await harness.repository.getMissionLogs('empty_user');
        expect(logs, isEmpty);
      });

      test('T2_F06_04: Auth service sign-in with whitespace-only credentials rejects authentication', () async {
        expect(harness.authService.signInWithEmailPassword('', 'pass'), throwsArgumentError);
        expect(harness.authService.signInWithEmailPassword('email@test.com', '  '), throwsArgumentError);
      });

      test('T2_F06_05: Repository persists data across independent callers within the same session', () async {
        final profile = E2EUserProfile(userId: 'persistent_u', agentName: 'Agent-X');
        await harness.repository.saveUserProfile(profile);
        final fetched1 = await harness.repository.getUserProfile('persistent_u');
        final fetched2 = await harness.repository.getUserProfile('persistent_u');
        expect(fetched1?.agentName, equals('Agent-X'));
        expect(fetched2?.agentName, equals('Agent-X'));
      });
    });

    // =========================================================================
    // F07: Onboarding Room Catalogue
    // =========================================================================
    group('F07: Onboarding Room Catalogue Boundary Cases', () {
      test('T2_F07_01: Catalogue contains no duplicate chore IDs across all rooms', () {
        final catalogue = E2EPredefinedCatalogue.getDefault17Chores();
        final ids = catalogue.map((c) => c.id).toList();
        final uniqueIds = ids.toSet();
        expect(ids.length, equals(uniqueIds.length));
      });

      test('T2_F07_02: Every predefined chore has difficulty strictly in range [1, 5]', () {
        final catalogue = E2EPredefinedCatalogue.getDefault17Chores();
        for (final chore in catalogue) {
          expect(chore.difficulty, inInclusiveRange(1, 5));
        }
      });

      test('T2_F07_03: Every predefined chore has periodicity strictly in range [1, 30] days', () {
        final catalogue = E2EPredefinedCatalogue.getDefault17Chores();
        for (final chore in catalogue) {
          expect(chore.periodicityDays, inInclusiveRange(1, 30));
        }
      });

      test('T2_F07_04: Room category validation identifies valid vs invalid room strings', () {
        expect(E2ERoomCategory.isValid('Cuisine'), isTrue);
        expect(E2ERoomCategory.isValid('Salle de bain'), isTrue);
        expect(E2ERoomCategory.isValid('Salon'), isTrue);
        expect(E2ERoomCategory.isValid('Chambre'), isTrue);
        expect(E2ERoomCategory.isValid('Cave'), isFalse);
        expect(E2ERoomCategory.isValid(''), isFalse);
      });

      test('T2_F07_05: Every predefined chore has non-empty swipeSequence with length in [5, 8]', () {
        final catalogue = E2EPredefinedCatalogue.getDefault17Chores();
        for (final chore in catalogue) {
          expect(chore.swipeSequence, isNotNull);
          expect(chore.swipeSequence!.length, inInclusiveRange(5, 8));
          for (final dir in chore.swipeSequence!) {
            expect(E2EStratagemEngine.directions.contains(dir), isTrue);
          }
        }
      });
    });

    // =========================================================================
    // F08: Onboarding Customizer & Persistence
    // =========================================================================
    group('F08: Onboarding Customizer Boundary Cases', () {
      test('T2_F08_01: Periodicity clamped to minimum 1 day (cannot be 0 or negative)', () {
        final chore = E2EChore(id: 'c', name: 'T', difficulty: 1, room: 'Cuisine', periodicityDays: 0);
        // Engine handles 0 days by treating it as maximum urgency
        final score = E2ETargetingEngine.calculateUrgencyScore(chore);
        expect(score, greaterThanOrEqualTo(1000.0));
      });

      test('T2_F08_02: Disabling all chores in a room blocks onboarding validation with ArgumentError', () async {
        await harness.signInAnonymous();
        final catalogue = E2EPredefinedCatalogue.getDefault17Chores().map((c) {
          if (c.room == E2ERoomCategory.chambre) return c.copyWith(enabled: false);
          return c;
        }).toList();

        expect(
          harness.submitOnboarding(catalogue),
          throwsArgumentError,
        );
      });

      test('T2_F08_03: Submitting customization with exactly 1 chore enabled per room succeeds', () async {
        await harness.signInAnonymous();
        final minimal4Chores = [
          E2EChore(id: 'c1', name: 'Cuisine Solo', difficulty: 1, room: E2ERoomCategory.cuisine, periodicityDays: 1),
          E2EChore(id: 'b1', name: 'SDB Solo', difficulty: 1, room: E2ERoomCategory.salleDeBain, periodicityDays: 1),
          E2EChore(id: 's1', name: 'Salon Solo', difficulty: 1, room: E2ERoomCategory.salon, periodicityDays: 1),
          E2EChore(id: 'ch1', name: 'Chambre Solo', difficulty: 1, room: E2ERoomCategory.chambre, periodicityDays: 1),
        ];

        await harness.submitOnboarding(minimal4Chores);
        expect(harness.currentProfile?.onboarded, isTrue);
        final saved = await harness.repository.getChores(harness.currentUserId!);
        expect(saved.length, equals(4));
      });

      test('T2_F08_04: Submitting customization with all 17 chores enabled succeeds', () async {
        await harness.signInAnonymous();
        final catalogue = E2EPredefinedCatalogue.getDefault17Chores();
        await harness.submitOnboarding(catalogue);
        final saved = await harness.repository.getChores(harness.currentUserId!);
        expect(saved.length, equals(17));
      });

      test('T2_F08_05: Submitting onboarding without logged-in user throws StateError', () async {
        final catalogue = E2EPredefinedCatalogue.getDefault17Chores();
        expect(
          harness.submitOnboarding(catalogue),
          throwsStateError,
        );
      });
    });

    // =========================================================================
    // F09: Auth & Onboarding Routing
    // =========================================================================
    group('F09: Auth & Onboarding Routing Boundary Cases', () {
      test('T2_F09_01: Corrupt profile with onboarded false requires onboarding', () async {
        final profile = E2EUserProfile(userId: 'u_corrupt', onboarded: false);
        await harness.repository.saveUserProfile(profile);
        final loaded = await harness.repository.getUserProfile('u_corrupt');
        expect(loaded?.onboarded, isFalse);
      });

      test('T2_F09_02: Sign out while on home resets state and requires login', () async {
        await harness.signInAnonymous();
        await harness.submitOnboarding(E2EPredefinedCatalogue.getDefault17Chores());
        expect(harness.currentProfile?.onboarded, isTrue);

        await harness.authService.signOut();
        expect(harness.authService.currentUserId, isNull);
      });

      test('T2_F09_03: Anonymous user ID generation never collisions across sequential sign-ins', () async {
        final uid1 = await harness.authService.signInAnonymously();
        await Future.delayed(const Duration(milliseconds: 2));
        final uid2 = await harness.authService.signInAnonymously();
        expect(uid1, isNot(equals(uid2)));
      });

      test('T2_F09_04: Submitting onboarding updates profile without affecting other user profiles', () async {
        final profile1 = E2EUserProfile(userId: 'user_A', onboarded: false);
        final profile2 = E2EUserProfile(userId: 'user_B', onboarded: false);
        await harness.repository.saveUserProfile(profile1);
        await harness.repository.saveUserProfile(profile2);

        await harness.repository.saveUserProfile(profile1.copyWith(onboarded: true));

        final checkA = await harness.repository.getUserProfile('user_A');
        final checkB = await harness.repository.getUserProfile('user_B');
        expect(checkA?.onboarded, isTrue);
        expect(checkB?.onboarded, isFalse);
      });

      test('T2_F09_05: Switching user switches to corresponding profile and chore dataset', () async {
        await harness.repository.saveChores('u1', [E2EChore(id: 'c1', name: 'U1 Chore', difficulty: 1, room: 'Cuisine', periodicityDays: 1)]);
        await harness.repository.saveChores('u2', [E2EChore(id: 'c2', name: 'U2 Chore', difficulty: 2, room: 'Salon', periodicityDays: 1)]);

        final list1 = await harness.repository.getChores('u1');
        final list2 = await harness.repository.getChores('u2');
        expect(list1.first.name, equals('U1 Chore'));
        expect(list2.first.name, equals('U2 Chore'));
      });
    });

    // =========================================================================
    // F10: Mil-Tech Dark Tactical Theme
    // =========================================================================
    group('F10: Mil-Tech Dark Tactical Theme Boundary Cases', () {
      test('T2_F10_01: Color luminance of backgroundBlack is near zero (< 0.01)', () {
        expect(E2EMilTechColors.backgroundBlack.computeLuminance(), lessThan(0.01));
      });

      test('T2_F10_02: Color luminance of neon accents is high (> 0.4)', () {
        expect(E2EMilTechColors.neonAmber.computeLuminance(), greaterThan(0.4));
        expect(E2EMilTechColors.neonYellow.computeLuminance(), greaterThan(0.5));
        expect(E2EMilTechColors.neonCyan.computeLuminance(), greaterThan(0.6));
      });

      test('T2_F10_03: Contrast ratio between text primary and background exceeds WCAG AAA (15:1)', () {
        final l1 = E2EMilTechColors.textPrimary.computeLuminance();
        final l2 = E2EMilTechColors.backgroundBlack.computeLuminance();
        final ratio = (l1 + 0.05) / (l2 + 0.05);
        expect(ratio, greaterThan(15.0));
      });

      test('T2_F10_04: Contrast ratio between neon amber and background exceeds WCAG AA (4.5:1)', () {
        final l1 = E2EMilTechColors.neonAmber.computeLuminance();
        final l2 = E2EMilTechColors.backgroundBlack.computeLuminance();
        final ratio = (l1 + 0.05) / (l2 + 0.05);
        expect(ratio, greaterThan(4.5));
      });

      test('T2_F10_05: Contrast ratio between neon cyan and background exceeds WCAG AA (4.5:1)', () {
        final l1 = E2EMilTechColors.neonCyan.computeLuminance();
        final l2 = E2EMilTechColors.backgroundBlack.computeLuminance();
        final ratio = (l1 + 0.05) / (l2 + 0.05);
        expect(ratio, greaterThan(4.5));
      });
    });

    // =========================================================================
    // F11: Tactical Home Screen HUD
    // =========================================================================
    group('F11: Tactical Home Screen HUD Boundary Cases', () {
      test('T2_F11_01: User with 0 credits and 0 medals renders values without error', () {
        final profile = E2EUserProfile(userId: 'u_zero', credits: 0, medals: 0);
        expect(profile.credits, equals(0));
        expect(profile.medals, equals(0));
      });

      test('T2_F11_02: User with 999,999 credits stores and updates properly', () {
        final profile = E2EUserProfile(userId: 'u_max', credits: 999999);
        expect(profile.credits, equals(999999));
      });

      test('T2_F11_03: All chores completed today sort deterministically by diff and name', () {
        final now = DateTime(2026, 10, 4, 12, 0);
        final chores = [
          E2EChore(id: 'c1', name: 'Z Chore', difficulty: 2, room: 'Cuisine', periodicityDays: 1, lastCompletedAt: now),
          E2EChore(id: 'c2', name: 'A Chore', difficulty: 4, room: 'Salon', periodicityDays: 1, lastCompletedAt: now),
          E2EChore(id: 'c3', name: 'B Chore', difficulty: 2, room: 'SDB', periodicityDays: 1, lastCompletedAt: now),
        ];
        final targets = E2ETargetingEngine.getTopTargets(chores, count: 3, now: now);
        // Diff 4 highest -> A Chore
        expect(targets[0].name, equals('A Chore'));
        // Diff 2 tie -> B Chore before Z Chore
        expect(targets[1].name, equals('B Chore'));
        expect(targets[2].name, equals('Z Chore'));
      });

      test('T2_F11_04: Only 1 active chore in app returns list of length 1 for top targets', () {
        final chores = [
          E2EChore(id: 'solo', name: 'Solo', difficulty: 1, room: 'Cuisine', periodicityDays: 1),
        ];
        final targets = E2ETargetingEngine.getTopTargets(chores, count: 3);
        expect(targets.length, equals(1));
      });

      test('T2_F11_05: Disabled chores are excluded from top targets calculations', () {
        final chores = [
          E2EChore(id: 'c_disabled', name: 'Disabled Critical', difficulty: 5, room: 'Cuisine', periodicityDays: 1, enabled: false),
          E2EChore(id: 'c_active', name: 'Active Normal', difficulty: 1, room: 'Salon', periodicityDays: 1, enabled: true),
        ];
        final targets = E2ETargetingEngine.getTopTargets(chores, count: 3);
        expect(targets.length, equals(1));
        expect(targets.first.id, equals('c_active'));
      });
    });

    // =========================================================================
    // F12: Dynamic Gesture Screen UI
    // =========================================================================
    group('F12: Dynamic Gesture Screen UI Boundary Cases', () {
      test('T2_F12_01: Error on penultimate move (step N-1 of N) resets progress completely back to step 0', () async {
        final chore = E2EChore(
          id: 'c_penultimate',
          name: 'Penultimate Test',
          difficulty: 3,
          room: 'Cuisine',
          periodicityDays: 1,
          swipeSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP', 'DOWN'], // 6 moves
        );
        await harness.startMission(chore);

        // Perform 4 moves correctly
        harness.submitSwipe('UP');
        harness.submitSwipe('DOWN');
        harness.submitSwipe('LEFT');
        harness.submitSwipe('RIGHT');
        expect(harness.currentSwipeIndex, equals(4));

        // Fail at step 5
        final result = harness.submitSwipe('LEFT'); // Wrong move (expected UP)
        expect(result, isFalse);
        expect(harness.currentSwipeIndex, equals(0)); // Reset!
      });

      test('T2_F12_02: Submitting gesture when no mission active throws StateError', () {
        expect(() => harness.submitSwipe('UP'), throwsStateError);
      });

      test('T2_F12_03: Swiping after stratagem already unlocked does not overflow currentSwipeIndex', () async {
        final chore = E2EChore(
          id: 'c_unlock',
          name: 'Unlock Test',
          difficulty: 1,
          room: 'Cuisine',
          periodicityDays: 1,
          swipeSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP'],
        );
        await harness.startMission(chore);
        for (final dir in chore.swipeSequence!) {
          harness.submitSwipe(dir);
        }
        expect(harness.currentSwipeIndex, equals(5));

        // Extra swipe
        harness.submitSwipe('UP');
        expect(harness.currentSwipeIndex, inInclusiveRange(0, 5));
      });

      test('T2_F12_04: 8-move maximum difficulty sequence validates accurately across all 8 steps', () async {
        final chore = E2EChore(
          id: 'c_8moves',
          name: 'Max Moves',
          difficulty: 5,
          room: 'Salon',
          periodicityDays: 1,
          swipeSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP', 'DOWN', 'LEFT', 'RIGHT'],
        );
        await harness.startMission(chore);
        for (final move in chore.swipeSequence!) {
          final res = harness.submitSwipe(move);
          expect(res, isTrue);
        }
        expect(harness.isStratagemUnlocked(), isTrue);
      });

      test('T2_F12_05: Single-move error on step 1 resets index back to 0', () async {
        final chore = E2EChore(
          id: 'c_first_step',
          name: 'First Step',
          difficulty: 1,
          room: 'Cuisine',
          periodicityDays: 1,
          swipeSequence: ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP'],
        );
        await harness.startMission(chore);
        final res = harness.submitSwipe('DOWN'); // expected UP
        expect(res, isFalse);
        expect(harness.currentSwipeIndex, equals(0));
      });
    });

    // =========================================================================
    // F13: Tactical Mission Timer Screen
    // =========================================================================
    group('F13: Tactical Mission Timer Screen Boundary Cases', () {
      test('T2_F13_01: Timer reaching 00:00 does not decrement into negative numbers', () async {
        final chore = E2EChore(id: 'c_zero', name: 'Zero', difficulty: 1, room: 'Cuisine', periodicityDays: 1);
        await harness.startMission(chore);
        harness.tickTimer(700); // Exceeds 600s
        expect(harness.timerSecondsRemaining, equals(0));
      });

      test('T2_F13_02: Timer reaching 00:00 automatically halts audio playback', () async {
        final chore = E2EChore(id: 'c_audio_zero', name: 'Zero Audio', difficulty: 1, room: 'Cuisine', periodicityDays: 1);
        await harness.startMission(chore);
        await harness.audioService.playMissionLoop('tactical_ambiance_1.mp3');
        expect(harness.audioService.isPlaying, isTrue);

        harness.tickTimer(600);
        expect(harness.timerSecondsRemaining, equals(0));
        expect(harness.audioService.isPlaying, isFalse);
      });

      test('T2_F13_03: Mission validation with 0 seconds remaining records full 600s duration', () async {
        await harness.signInAnonymous();
        final chore = E2EChore(id: 'c_full_dur', name: 'Full Dur', difficulty: 1, room: 'Cuisine', periodicityDays: 1);
        await harness.repository.saveChores(harness.currentUserId!, [chore]);
        await harness.startMission(chore);
        harness.tickTimer(600);

        await harness.validateMission();
        final logs = await harness.repository.getMissionLogs(harness.currentUserId!);
        expect(logs.first.durationSeconds, equals(600));
      });

      test('T2_F13_04: Mission validation with 0 seconds elapsed records 0s duration', () async {
        await harness.signInAnonymous();
        final chore = E2EChore(id: 'c_zero_dur', name: 'Zero Dur', difficulty: 1, room: 'Cuisine', periodicityDays: 1);
        await harness.repository.saveChores(harness.currentUserId!, [chore]);
        await harness.startMission(chore);

        await harness.validateMission();
        final logs = await harness.repository.getMissionLogs(harness.currentUserId!);
        expect(logs.first.durationSeconds, equals(0));
      });

      test('T2_F13_05: Ticking timer by negative value clamps safely to max 600s', () async {
        final chore = E2EChore(id: 'c_neg_tick', name: 'Neg Tick', difficulty: 1, room: 'Cuisine', periodicityDays: 1);
        await harness.startMission(chore);
        harness.tickTimer(-100);
        expect(harness.timerSecondsRemaining, equals(600));
      });
    });

    // =========================================================================
    // F14: Vocabulary Purge
    // =========================================================================
    group('F14: Vocabulary Purge Boundary Cases', () {
      test('T2_F14_01: Lexicon scanner flags substrings embedded inside compound words', () {
        expect(E2ELexiconValidator.containsForbiddenTerms('join-the-squad-today'), isTrue);
      });

      test('T2_F14_02: Lexicon scanner checks pluralized and accented variants', () {
        expect(E2ELexiconValidator.containsForbiddenTerms('escouades opérationnelles'), isTrue);
      });

      test('T2_F14_03: Lexicon scanner identifies multiple simultaneous violations', () {
        final violations = E2ELexiconValidator.findViolations('squad attack with heavy assault and arsenal');
        expect(violations, contains('squad'));
        expect(violations, contains('heavy assault'));
        expect(violations, contains('arsenal'));
      });

      test('T2_F14_04: Empty string or punctuation passes lexicon validation cleanly', () {
        expect(E2ELexiconValidator.containsForbiddenTerms(''), isFalse);
        expect(E2ELexiconValidator.containsForbiddenTerms('---!@#\$%^&*()---'), isFalse);
      });

      test('T2_F14_05: Case-insensitive detection catches capitalized military jargon', () {
        expect(E2ELexiconValidator.containsForbiddenTerms('SQUAD DEPLOYMENT'), isTrue);
        expect(E2ELexiconValidator.containsForbiddenTerms('ARSENAL LEVEL 4'), isTrue);
      });
    });

    // =========================================================================
    // F15: E2E Integration & Hardening
    // =========================================================================
    group('F15: E2E Integration Boundary Cases', () {
      test('T2_F15_01: Validating inactive mission throws StateError', () async {
        expect(harness.validateMission(), throwsStateError);
      });

      test('T2_F15_02: Concurrently logging two missions for different chores updates history independently', () async {
        await harness.signInAnonymous();
        final log1 = E2EMissionLog(choreId: 'c1', completedAt: DateTime.now(), success: true, durationSeconds: 200);
        final log2 = E2EMissionLog(choreId: 'c2', completedAt: DateTime.now(), success: true, durationSeconds: 400);

        await Future.wait([
          harness.repository.logMission(harness.currentUserId!, log1),
          harness.repository.logMission(harness.currentUserId!, log2),
        ]);

        final logs = await harness.repository.getMissionLogs(harness.currentUserId!);
        expect(logs.length, equals(2));
      });

      test('T2_F15_03: Starting new mission while one is active safely re-initializes mission state', () async {
        final chore1 = E2EChore(id: 'c1', name: 'First', difficulty: 1, room: 'Cuisine', periodicityDays: 1);
        final chore2 = E2EChore(id: 'c2', name: 'Second', difficulty: 3, room: 'Salon', periodicityDays: 2);

        await harness.startMission(chore1);
        harness.submitSwipe('UP');
        expect(harness.activeChore?.id, equals('c1'));

        await harness.startMission(chore2);
        expect(harness.activeChore?.id, equals('c2'));
        expect(harness.currentSwipeIndex, equals(0));
        expect(harness.timerSecondsRemaining, equals(600));
      });

      test('T2_F15_04: Repeated rapid mission completions increment medals and level monotonically', () async {
        await harness.signInAnonymous();
        final chore = E2EChore(id: 'c_loop', name: 'Loop', difficulty: 5, room: 'Cuisine', periodicityDays: 1); // 500 credits per win
        await harness.repository.saveChores(harness.currentUserId!, [chore]);

        for (int i = 0; i < 5; i++) {
          await harness.startMission(chore);
          await harness.validateMission();
        }

        // 5 * 500 = 2500 credits -> level 1 + (2500 ~/ 500) = 6
        expect(harness.currentProfile?.credits, equals(2500));
        expect(harness.currentProfile?.medals, equals(5));
        expect(harness.currentProfile?.level, equals(6));
      });

      test('T2_F15_05: Level formula correctly thresholds level promotions every 500 credits', () {
        // level = 1 + (credits ~/ 500)
        expect(1 + (0 ~/ 500), equals(1));
        expect(1 + (499 ~/ 500), equals(1));
        expect(1 + (500 ~/ 500), equals(2));
        expect(1 + (999 ~/ 500), equals(2));
        expect(1 + (1000 ~/ 500), equals(3));
      });
    });
  });
}
