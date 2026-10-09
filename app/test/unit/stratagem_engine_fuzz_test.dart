// ignore_for_file: avoid_print
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_stratagem/engine/stratagem_engine.dart';

void main() {
  group('Adversarial Fuzzing - 10,000 Sequence Generation Iterations', () {
    test('10,000 randomized iterations verify lengths strictly in [5, 8] and directions in standard set', () {
      final rng = Random(1337);
      const int iterations = 10000;

      final lengthDistribution = <int, int>{5: 0, 6: 0, 7: 0, 8: 0};
      final directionDistribution = <String, int>{'UP': 0, 'DOWN': 0, 'LEFT': 0, 'RIGHT': 0};
      int totalMovesGenerated = 0;

      for (int i = 0; i < iterations; i++) {
        // Fuzz difficulty across negatives, zeros, nominal 1..5, and extreme positives
        final difficulty = rng.nextInt(2001) - 1000; // [-1000, 1000]
        final sequence = StratagemEngine.generateSequenceForDifficulty(difficulty, random: rng);

        // Invariant 1: Sequence length strictly in [5, 8]
        expect(
          sequence.length,
          inInclusiveRange(5, 8),
          reason: 'Iteration $i: sequence length ${sequence.length} outside [5, 8] for difficulty $difficulty',
        );

        // Invariant 2: Correct mapping per difficulty
        if (difficulty <= 2) {
          expect(sequence.length, equals(5));
        } else if (difficulty == 3) {
          expect(sequence.length, equals(6));
        } else if (difficulty == 4) {
          expect(sequence.length, equals(7));
        } else {
          expect(sequence.length, equals(8));
        }

        lengthDistribution[sequence.length] = (lengthDistribution[sequence.length] ?? 0) + 1;

        // Invariant 3: All directions in ['UP', 'DOWN', 'LEFT', 'RIGHT']
        for (final move in sequence) {
          expect(
            StratagemEngine.directions.contains(move),
            isTrue,
            reason: 'Iteration $i: Invalid direction token "$move"',
          );
          directionDistribution[move] = (directionDistribution[move] ?? 0) + 1;
          totalMovesGenerated++;
        }
      }

      // Empirical logging & statistics verification
      print('=== 10,000 Iterations Fuzzing Results ===');
      print('Total moves generated: $totalMovesGenerated');
      print('Length distribution: $lengthDistribution');
      print('Direction distribution: $directionDistribution');

      // Verify every allowed length was generated
      for (int len = 5; len <= 8; len++) {
        expect(lengthDistribution[len]! > 0, isTrue);
      }

      // Verify uniform statistical spread across all 4 directions (each ~25% +/- 2%)
      for (final dir in StratagemEngine.directions) {
        final ratio = directionDistribution[dir]! / totalMovesGenerated;
        expect(ratio, inInclusiveRange(0.23, 0.27), reason: 'Direction $dir distribution skewed ($ratio)');
      }
    });

    test('10,000 unseeded generations (system Random) adhere to invariants', () {
      const int iterations = 10000;
      for (int i = 0; i < iterations; i++) {
        final difficulty = (i % 7) - 1; // -1, 0, 1, 2, 3, 4, 5
        final sequence = StratagemEngine.generateSequenceForDifficulty(difficulty);

        expect(sequence.length >= 5 && sequence.length <= 8, isTrue);
        for (final move in sequence) {
          expect(StratagemEngine.directions.contains(move), isTrue);
        }
      }
    });
  });

  group('Adversarial Fuzzing - Input Validator Extremes & Malformed Data', () {
    final validSequence = ['UP', 'RIGHT', 'DOWN', 'LEFT', 'UP', 'DOWN', 'RIGHT', 'LEFT'];

    test('fuzzing invalid move strings never returns true', () {
      final invalidTokens = <String>[
        '',
        ' ',
        '   ',
        '\t',
        '\n',
        '\r\n',
        'DIAGONAL',
        'FORWARD',
        'BACKWARD',
        'NORTH',
        'SOUTH',
        'EAST',
        'WEST',
        'null',
        'NULL',
        'nil',
        'undefined',
        '0',
        '1',
        '-1',
        '999999',
        'UPP',
        'U_P',
        'D OWN',
        'L-EFT',
        'RIGHT!',
        '⬆️',
        '⬇️',
        '⬅️',
        '➡️',
        'UP\u0000',
        'DOWN\u0000',
        'UP; DROP TABLE chores;',
        'UP -- comment',
        '<script>alert("UP")</script>',
        'A' * 1000,
      ];

      for (int idx = 0; idx < validSequence.length; idx++) {
        for (final token in invalidTokens) {
          final result = StratagemEngine.isMoveCorrect(validSequence, idx, token);
          expect(
            result,
            isFalse,
            reason: 'Token "$token" at index $idx should never validate as true',
          );
        }
      }
    });

    test('whitespace trimming and case insensitivity fuzzing', () {
      final variations = {
        'UP': ['up', 'UP', 'Up', 'uP', '  UP', 'UP  ', '  UP  ', '\tUP\t', '\nUP\n', '  up  '],
        'DOWN': ['down', 'DOWN', 'Down', 'dOwN', '  DOWN', 'DOWN  ', '  DOWN  ', '\tdown\t'],
        'LEFT': ['left', 'LEFT', 'Left', 'lEfT', '  LEFT', 'LEFT  ', '  LEFT  ', '\tleft\t'],
        'RIGHT': ['right', 'RIGHT', 'Right', 'rIgHt', '  RIGHT', 'RIGHT  ', '  RIGHT  ', '\tright\t'],
      };

      for (final entry in variations.entries) {
        final expectedDirection = entry.key;
        final singleSeq = [expectedDirection];

        for (final variation in entry.value) {
          expect(
            StratagemEngine.isMoveCorrect(singleSeq, 0, variation),
            isTrue,
            reason: 'Variation "$variation" should normalize to "$expectedDirection"',
          );
        }
      }
    });

    test('index boundary fuzzing with extreme integers', () {
      final extremeIndices = [
        -1,
        -2,
        -5,
        -100,
        -999999,
        -2147483648,
        validSequence.length,
        validSequence.length + 1,
        validSequence.length + 5,
        100,
        999999,
        2147483647,
      ];

      for (final idx in extremeIndices) {
        for (final dir in StratagemEngine.directions) {
          expect(
            StratagemEngine.isMoveCorrect(validSequence, idx, dir),
            isFalse,
            reason: 'Index $idx should be out-of-bounds for sequence of length ${validSequence.length}',
          );
        }
      }
    });

    test('empty target sequence boundary fuzzing', () {
      final emptySequence = <String>[];
      final indicesToTest = [-10, -1, 0, 1, 10];

      for (final idx in indicesToTest) {
        for (final dir in StratagemEngine.directions) {
          expect(
            StratagemEngine.isMoveCorrect(emptySequence, idx, dir),
            isFalse,
            reason: 'Empty sequence must return false for index $idx and move $dir',
          );
        }
      }
    });
  });

  group('Adversarial Fuzzing - Combinatorial Matrix & State Machine Resets', () {
    test('4x4 full combinatorial truth matrix', () {
      for (final target in StratagemEngine.directions) {
        final seq = [target];
        for (final input in StratagemEngine.directions) {
          final isMatch = StratagemEngine.isMoveCorrect(seq, 0, input);
          if (target == input) {
            expect(isMatch, isTrue, reason: '$target == $input must be true');
          } else {
            expect(isMatch, isFalse, reason: '$target == $input must be false');
          }
        }
      }
    });

    test('1,000 multi-step interactive gameplay simulations with random error resets', () {
      final rng = Random(98765);
      const int simulations = 1000;
      int totalResets = 0;
      int completedSequences = 0;

      for (int sim = 0; sim < simulations; sim++) {
        final diff = rng.nextInt(5) + 1; // 1 to 5
        final targetSeq = StratagemEngine.generateSequenceForDifficulty(diff, random: rng);
        int currentIndex = 0;
        int stepBudget = 200; // Safeguard against infinite loops

        while (currentIndex < targetSeq.length && stepBudget > 0) {
          stepBudget--;
          // 80% chance to submit correct move, 20% chance to submit wrong move or garbage
          final willMakeError = rng.nextDouble() < 0.20;

          if (!willMakeError) {
            final correctMove = targetSeq[currentIndex];
            final isValid = StratagemEngine.isMoveCorrect(targetSeq, currentIndex, correctMove);
            expect(isValid, isTrue);
            currentIndex++;
          } else {
            // Adversarial wrong move: wrong direction or random garbage
            final wrongMove = rng.nextBool()
                ? StratagemEngine.directions[(StratagemEngine.directions.indexOf(targetSeq[currentIndex]) + 1) % 4]
                : 'MALFORMED_${rng.nextInt(100)}';

            final isValid = StratagemEngine.isMoveCorrect(targetSeq, currentIndex, wrongMove);
            expect(isValid, isFalse);

            // Error reset behavior as implemented in StratagemScreen
            currentIndex = 0;
            totalResets++;
          }
        }

        if (currentIndex == targetSeq.length) {
          completedSequences++;
        }
      }

      print('=== 1,000 Interactive Simulations Summary ===');
      print('Completed sequences: $completedSequences / $simulations');
      print('Total error resets triggered: $totalResets');
      expect(completedSequences > 0, isTrue);
      expect(totalResets > 0, isTrue);
    });
  });
}
