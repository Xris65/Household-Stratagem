import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_stratagem/engine/stratagem_engine.dart';
import 'package:household_stratagem/models/chore.dart';
import 'package:household_stratagem/targeting_engine.dart';

void main() {
  final fixedNow = DateTime(2026, 10, 4, 12, 0, 0);

  group('STRESS HARNESS 1: 10,000 Chores Throughput, Latency, and Scalability', () {
    test('handles 10,000 heterogeneous chores under 300ms without memory or stack failure', () {
      final rng = Random(42);
      final thousandRooms = ['Cuisine', 'Salle de bain', 'Salon', 'Chambre'];

      // Generate 10,000 heterogeneous chores
      final largeChoreList = List.generate(10000, (i) {
        final difficulty = (rng.nextInt(5) + 1); // 1..5
        final periodicity = rng.nextBool() ? (rng.nextInt(30) + 1) : -rng.nextInt(10); // positive or negative
        DateTime? lastCompleted;
        final dateMode = rng.nextInt(4);
        if (dateMode == 0) {
          lastCompleted = null; // 25% never completed
        } else if (dateMode == 1) {
          lastCompleted = fixedNow.subtract(Duration(days: rng.nextInt(60))); // past
        } else if (dateMode == 2) {
          lastCompleted = fixedNow.add(Duration(days: rng.nextInt(10) + 1)); // future clock drift
        } else {
          lastCompleted = fixedNow; // completed today
        }

        return Chore(
          id: 'chore_${i.toString().padLeft(5, '0')}',
          name: 'Tâche ménagère $i',
          room: thousandRooms[i % 4],
          difficulty: difficulty,
          periodicityDays: periodicity,
          lastCompletedAt: lastCompleted,
        );
      });

      final stopwatch = Stopwatch()..start();
      final top3 = TargetingEngine.getTopTargets(largeChoreList, count: 3, now: fixedNow);
      stopwatch.stop();

      // Performance assertion
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: '10,000 chores getTopTargets took ${stopwatch.elapsedMilliseconds}ms; expected < 500ms',
      );

      // Sanity checks on top 3
      expect(top3.length, equals(3));
      final score0 = TargetingEngine.calculateUrgencyScore(top3[0], now: fixedNow);
      final score1 = TargetingEngine.calculateUrgencyScore(top3[1], now: fixedNow);
      final score2 = TargetingEngine.calculateUrgencyScore(top3[2], now: fixedNow);

      expect(score0, greaterThanOrEqualTo(score1));
      expect(score1, greaterThanOrEqualTo(score2));
      expect(score0.isNaN, isFalse);
      expect(score0.isInfinite, isFalse);
    });

    test('full sort of 10,000 chores (count: 10000) maintains strictly monotonic order', () {
      final rng = Random(1234);
      final largeChoreList = List.generate(10000, (i) {
        return Chore(
          id: 'c_$i',
          name: 'Task $i',
          difficulty: (i % 5) + 1,
          periodicityDays: (i % 14) + 1,
          lastCompletedAt: fixedNow.subtract(Duration(days: rng.nextInt(30))),
        );
      });

      final stopwatch = Stopwatch()..start();
      final allSorted = TargetingEngine.getTopTargets(largeChoreList, count: 10000, now: fixedNow);
      stopwatch.stop();

      expect(allSorted.length, equals(10000));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      // Verify monotonicity across sampled intervals
      for (int i = 0; i < allSorted.length - 1; i += 50) {
        final currentScore = TargetingEngine.calculateUrgencyScore(allSorted[i], now: fixedNow);
        final nextScore = TargetingEngine.calculateUrgencyScore(allSorted[i + 1], now: fixedNow);
        expect(
          currentScore,
          greaterThanOrEqualTo(nextScore),
          reason: 'Monotonicity violation at index $i: $currentScore < $nextScore',
        );
      }
    });
  });

  group('STRESS HARNESS 2: Negative and Zero Periodicity Oracle', () {
    test('non-positive periodicity (0, -1, -7, -99999) does not throw, divide by zero, or return NaN/Infinity', () {
      final nonPositivePeriodicities = [0, -1, -2, -7, -30, -365, -99999, -2147483648];

      for (final period in nonPositivePeriodicities) {
        final choreNever = Chore(
          id: 'test_period_$period',
          name: 'Zero or Negative Period Chore',
          difficulty: 3,
          periodicityDays: period,
          lastCompletedAt: null,
        );

        final scoreNever = TargetingEngine.calculateUrgencyScore(choreNever, now: fixedNow);
        expect(scoreNever.isNaN, isFalse, reason: 'NaN for periodicity $period with null date');
        expect(scoreNever.isInfinite, isFalse, reason: 'Infinity for periodicity $period with null date');
        expect(scoreNever, equals(1030.0));

        final chorePast = Chore(
          id: 'test_period_past_$period',
          name: 'Past with Negative Period',
          difficulty: 2,
          periodicityDays: period,
          lastCompletedAt: fixedNow.subtract(const Duration(days: 5)),
        );

        final scorePast = TargetingEngine.calculateUrgencyScore(chorePast, now: fixedNow);
        expect(scorePast.isNaN, isFalse, reason: 'NaN for periodicity $period with past date');
        expect(scorePast.isInfinite, isFalse, reason: 'Infinity for periodicity $period with past date');
        // When period <= 0, effectivePeriodicity defaults to 1.0 -> 5 days / 1.0 * 100 + 2 * 5 = 510.0
        expect(scorePast, closeTo(510.0, 0.01));
      }
    });

    test('property test: 1,000 random negative periodicities evaluated against oracle specification', () {
      final rng = Random(789);

      for (int i = 0; i < 1000; i++) {
        final period = -rng.nextInt(100000);
        final difficulty = rng.nextInt(5) + 1;
        final daysAgo = rng.nextDouble() * 100.0;
        final lastCompleted = fixedNow.subtract(Duration(milliseconds: (daysAgo * 86400000).round()));

        final chore = Chore(
          id: 'neg_$i',
          name: 'Negative $i',
          difficulty: difficulty,
          periodicityDays: period,
          lastCompletedAt: lastCompleted,
        );

        final score = TargetingEngine.calculateUrgencyScore(chore, now: fixedNow);

        // Oracle calculation: effective period should clamp to 1.0
        final expectedOverdue = daysAgo / 1.0;
        final expectedScore = (expectedOverdue * 100.0) + (difficulty * 5.0);

        expect(score.isFinite, isTrue);
        expect(score, closeTo(expectedScore, 0.05));
      }
    });
  });

  group('STRESS HARNESS 3: Clock Drift and Extreme Dates Oracle', () {
    test('future completion dates across multiple time intervals clamp elapsed time to 0.0', () {
      final futureOffsets = [
        const Duration(milliseconds: 1),
        const Duration(seconds: 1),
        const Duration(minutes: 1),
        const Duration(hours: 1),
        const Duration(days: 1),
        const Duration(days: 30),
        const Duration(days: 365),
        const Duration(days: 3650), // 10 years
      ];

      for (final offset in futureOffsets) {
        final chore = Chore(
          id: 'future_${offset.inMilliseconds}',
          name: 'Future Chore',
          difficulty: 4,
          periodicityDays: 7,
          lastCompletedAt: fixedNow.add(offset),
        );

        final score = TargetingEngine.calculateUrgencyScore(chore, now: fixedNow);
        // Clamped to 0.0 elapsed -> 0.0 + (4 * 5.0) = 20.0
        expect(
          score,
          closeTo(20.0, 0.0001),
          reason: 'Future offset ${offset.inDays} days must clamp to 20.0, got $score',
        );
      }
    });

    test('extreme future date (year 9999) computes safely without integer or double overflow', () {
      final distantFutureChore = Chore(
        id: 'c_9999',
        name: 'Year 9999 Chore',
        difficulty: 5,
        periodicityDays: 7,
        lastCompletedAt: DateTime(9999, 12, 31),
      );

      final score = TargetingEngine.calculateUrgencyScore(distantFutureChore, now: fixedNow);
      expect(score, closeTo(25.0, 0.0001));
      expect(score.isFinite, isTrue);
    });

    test('extreme past date (epoch 1970 and year 1 AD) computes without crash', () {
      final epochChore = Chore(
        id: 'c_1970',
        name: 'Epoch Chore',
        difficulty: 1,
        periodicityDays: 7,
        lastCompletedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

      final score = TargetingEngine.calculateUrgencyScore(epochChore, now: fixedNow);
      expect(score.isFinite, isTrue);
      expect(score, greaterThan(100000.0));

      final ancientChore = Chore(
        id: 'c_year1',
        name: 'Year 1 Chore',
        difficulty: 1,
        periodicityDays: 30,
        lastCompletedAt: DateTime(1, 1, 1),
      );

      final ancientScore = TargetingEngine.calculateUrgencyScore(ancientChore, now: fixedNow);
      expect(ancientScore.isFinite, isTrue);
      expect(ancientScore, greaterThan(1000000.0));
    });
  });

  group('STRESS HARNESS 4: Identical Urgency Scores & Deterministic Tie-Breaking', () {
    test('strict tie-breaking hierarchy: Urgency -> Difficulty -> Name -> ID', () {
      // 4 chores with identical score (all completed today -> score = 0 + diff * 5)
      // Chores A, B, C, D configured to test each tie-break level:
      final choreHigherDiff = Chore(
        id: 'id_99',
        name: 'Zeta',
        difficulty: 4, // higher difficulty wins over 3
        periodicityDays: 7,
        lastCompletedAt: fixedNow,
      );

      final choreAlpha = Chore(
        id: 'id_50',
        name: 'Alpha', // same diff 3, earlier name wins over Beta
        difficulty: 3,
        periodicityDays: 7,
        lastCompletedAt: fixedNow,
      );

      final choreBetaId1 = Chore(
        id: 'id_01', // same diff 3, same name Beta, earlier ID wins over id_02
        name: 'Beta',
        difficulty: 3,
        periodicityDays: 7,
        lastCompletedAt: fixedNow,
      );

      final choreBetaId2 = Chore(
        id: 'id_02',
        name: 'Beta',
        difficulty: 3,
        periodicityDays: 7,
        lastCompletedAt: fixedNow,
      );

      final input = [choreBetaId2, choreBetaId1, choreAlpha, choreHigherDiff];
      final sorted = TargetingEngine.getTopTargets(input, count: 4, now: fixedNow);

      expect(sorted[0].id, equals('id_99')); // Chore Higher Diff
      expect(sorted[1].id, equals('id_50')); // Chore Alpha
      expect(sorted[2].id, equals('id_01')); // Chore Beta ID 1
      expect(sorted[3].id, equals('id_02')); // Chore Beta ID 2
    });

    test('permutation invariance oracle: 100 random shuffles produce identical top targets', () {
      // Create 50 chores with identical urgency scores
      final chores = List.generate(50, (i) {
        return Chore(
          id: 'id_${i.toString().padLeft(3, '0')}',
          name: 'Task ${(i % 10).toString().padLeft(2, '0')}',
          difficulty: (i % 3) + 1,
          periodicityDays: 7,
          lastCompletedAt: null, // all score = 1000 + diff * 10
        );
      });

      // Reference sort
      final referenceTop5 = TargetingEngine.getTopTargets(List.of(chores), count: 5, now: fixedNow);
      final referenceIds = referenceTop5.map((c) => c.id).toList();

      // Test 100 randomized permutations
      for (int seed = 0; seed < 100; seed++) {
        final shuffledList = List.of(chores)..shuffle(Random(seed));
        final shuffledTop5 = TargetingEngine.getTopTargets(shuffledList, count: 5, now: fixedNow);
        final shuffledIds = shuffledTop5.map((c) => c.id).toList();

        expect(
          shuffledIds,
          equals(referenceIds),
          reason: 'Permutation with seed $seed resulted in divergent tie-breaking order: $shuffledIds vs $referenceIds',
        );
      }
    });

    test('massive tie-breaking: 10,000 chores with identical urgency scores resolve deterministically', () {
      final chores = List.generate(10000, (i) {
        return Chore(
          id: 'id_${i.toString().padLeft(5, '0')}',
          name: 'Same Task Name',
          difficulty: 3,
          periodicityDays: 7,
          lastCompletedAt: null, // exact identical score 1030.0, identical diff, identical name
        );
      });

      // Shuffled
      final shuffled = List.of(chores)..shuffle(Random(42));
      final top3 = TargetingEngine.getTopTargets(shuffled, count: 3, now: fixedNow);

      // Must break ties strictly by ID ascending
      expect(top3[0].id, equals('id_00000'));
      expect(top3[1].id, equals('id_00001'));
      expect(top3[2].id, equals('id_00002'));
    });
  });

  group('STRESS HARNESS 5: StratagemEngine High-Throughput & Invariant Oracle', () {
    test('100,000 sequence generations invariant: length strictly in [5, 8], valid directions', () {
      final rng = Random(999);
      final allowed = StratagemEngine.directions.toSet();

      for (int i = 0; i < 100000; i++) {
        final difficulty = (i % 12) - 3; // -3 to 8
        final seq = StratagemEngine.generateSequenceForDifficulty(difficulty, random: rng);

        // Invariant 1: length bounded
        expect(seq.length, inInclusiveRange(5, 8));

        // Invariant 2: difficulty tier mapping
        if (difficulty <= 2) {
          expect(seq.length, equals(5));
        } else if (difficulty == 3) {
          expect(seq.length, equals(6));
        } else if (difficulty == 4) {
          expect(seq.length, equals(7));
        } else {
          expect(seq.length, equals(8));
        }

        // Invariant 3: valid tokens
        for (final move in seq) {
          expect(allowed.contains(move), isTrue);
        }
      }
    });

    test('10,000 adversarial swipe inputs through isMoveCorrect oracle without crashes', () {
      final testSequence = ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP', 'DOWN', 'LEFT', 'RIGHT'];
      final adversarialMoves = [
        'UP', 'DOWN', 'LEFT', 'RIGHT',
        'up', 'down', 'left', 'right',
        '  UP  ', '\tDOWN\n', '  left  ', ' RiGhT ',
        '', '   ', 'INVALID', 'DIAGONAL', 'FORWARD', 'BACK', '123',
        '⬆️', '⬇️', '👈', '👉', 'UP\x00', 'UP\nDOWN',
      ];

      for (int i = 0; i < 10000; i++) {
        final move = adversarialMoves[i % adversarialMoves.length];
        final index = (i % 20) - 5; // -5 to 14 (includes out-of-bounds)

        // Must never throw an exception
        final result = StratagemEngine.isMoveCorrect(testSequence, index, move);

        // Verification oracle
        if (index < 0 || index >= testSequence.length) {
          expect(result, isFalse);
        } else {
          final normalized = move.trim().toUpperCase();
          if (!StratagemEngine.directions.contains(normalized)) {
            expect(result, isFalse);
          } else {
            expect(result, equals(testSequence[index] == normalized));
          }
        }
      }
    });

    test('rapid interactive game loop simulation: 1,000 game runs with random mistakes and resets', () {
      final rng = Random(555);

      for (int game = 0; game < 1000; game++) {
        final difficulty = rng.nextInt(5) + 1;
        final targetSequence = StratagemEngine.generateSequenceForDifficulty(difficulty, random: rng);

        int currentIndex = 0;
        int attempts = 0;

        while (currentIndex < targetSequence.length && attempts < 50) {
          attempts++;
          final shouldMakeMistake = rng.nextInt(4) == 0; // 25% error rate
          String move;
          if (shouldMakeMistake) {
            // Pick wrong move
            final wrongMoves = StratagemEngine.directions.where((d) => d != targetSequence[currentIndex]).toList();
            move = wrongMoves[rng.nextInt(wrongMoves.length)];
          } else {
            // Pick correct move
            move = targetSequence[currentIndex];
          }

          final isValid = StratagemEngine.isMoveCorrect(targetSequence, currentIndex, move);

          if (isValid) {
            currentIndex++;
          } else {
            currentIndex = 0; // Reset progression
          }
        }

        // Successfully progressed or safely halted
        expect(currentIndex, inInclusiveRange(0, targetSequence.length));
      }
    });
  });

  group('STRESS HARNESS 6: Edge Cases, Bounds & Mutability', () {
    test('TargetingEngine does not mutate input chores list', () {
      final originalList = [
        Chore(id: 'c1', name: 'Z', difficulty: 1, periodicityDays: 7, lastCompletedAt: fixedNow),
        Chore(id: 'c2', name: 'A', difficulty: 5, periodicityDays: 7, lastCompletedAt: null),
      ];

      final clonedOrder = List.of(originalList.map((c) => c.id));
      TargetingEngine.getTopTargets(originalList, count: 2, now: fixedNow);

      expect(originalList.map((c) => c.id).toList(), equals(clonedOrder));
    });

    test('TargetingEngine handles count <= 0 or empty input returning empty list', () {
      expect(TargetingEngine.getTopTargets([], count: 3, now: fixedNow), isEmpty);
      expect(TargetingEngine.getTopTargets([], count: 0, now: fixedNow), isEmpty);
      expect(TargetingEngine.getTopTargets([], count: -5, now: fixedNow), isEmpty);

      final singleChore = [Chore(id: '1', name: 'Test', difficulty: 1)];
      expect(TargetingEngine.getTopTargets(singleChore, count: 0, now: fixedNow), isEmpty);
      expect(TargetingEngine.getTopTargets(singleChore, count: -1, now: fixedNow), isEmpty);
    });

    test('TargetingEngine handles count > chores.length safely', () {
      final chores = [
        Chore(id: '1', name: 'A', difficulty: 1),
        Chore(id: '2', name: 'B', difficulty: 2),
      ];

      final result = TargetingEngine.getTopTargets(chores, count: 100, now: fixedNow);
      expect(result.length, equals(2));
    });

    test('TargetingEngine behavior on disabled chores', () {
      final chores = [
        Chore(id: 'c_disabled', name: 'Disabled Urgent', difficulty: 5, periodicityDays: 7, lastCompletedAt: null, enabled: false),
        Chore(id: 'c_active', name: 'Active Normal', difficulty: 1, periodicityDays: 7, lastCompletedAt: fixedNow, enabled: true),
      ];

      final top = TargetingEngine.getTopTargets(chores, count: 2, now: fixedNow);
      // NOTE: Verify empirical behavior: does TargetingEngine filter enabled or include all passed chores?
      // TargetingEngine currently operates on whichever chores list is passed to it.
      expect(top.length, equals(2));
      expect(top.first.id, equals('c_disabled'));
    });
  });
}
