import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_stratagem/engine/stratagem_engine.dart';

void main() {
  group('StratagemEngine - Directions Constants', () {
    test('contains exact 4 standard cardinal swipe directions', () {
      expect(StratagemEngine.directions, equals(['UP', 'DOWN', 'LEFT', 'RIGHT']));
      expect(StratagemEngine.directions.length, equals(4));
    });
  });

  group('StratagemEngine - generateSequenceForDifficulty', () {
    test('generates sequences strictly within [5, 8] moves for valid difficulties 1 to 5', () {
      final random = Random(42);

      for (int diff = 1; diff <= 5; diff++) {
        for (int i = 0; i < 20; i++) {
          final sequence = StratagemEngine.generateSequenceForDifficulty(diff, random: random);
          expect(
            sequence.length,
            inInclusiveRange(5, 8),
            reason: 'Sequence length for difficulty $diff must be between 5 and 8',
          );
        }
      }
    });

    test('clamps boundary and extreme difficulties to [5, 8] moves', () {
      final random = Random(123);

      final negativeSeq = StratagemEngine.generateSequenceForDifficulty(-5, random: random);
      expect(negativeSeq.length, equals(5));

      final zeroSeq = StratagemEngine.generateSequenceForDifficulty(0, random: random);
      expect(zeroSeq.length, equals(5));

      final highSeq = StratagemEngine.generateSequenceForDifficulty(99, random: random);
      expect(highSeq.length, equals(8));
    });

    test('all generated items are valid directions', () {
      final random = Random(999);
      for (int i = 0; i < 50; i++) {
        final sequence = StratagemEngine.generateSequenceForDifficulty(3, random: random);
        for (final move in sequence) {
          expect(StratagemEngine.directions.contains(move), isTrue,
              reason: 'Generated move $move must be in directions list');
        }
      }
    });

    test('reproducible generation when seeded Random is provided', () {
      final seq1 = StratagemEngine.generateSequenceForDifficulty(3, random: Random(777));
      final seq2 = StratagemEngine.generateSequenceForDifficulty(3, random: Random(777));
      expect(seq1, equals(seq2));
    });

    test('produces variety of directions across generations', () {
      final random = Random(2026);
      final observedDirections = <String>{};

      for (int i = 0; i < 30; i++) {
        final seq = StratagemEngine.generateSequenceForDifficulty(4, random: random);
        observedDirections.addAll(seq);
      }

      expect(observedDirections, containsAll(StratagemEngine.directions));
    });
  });

  group('StratagemEngine - isMoveCorrect', () {
    final target = ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP', 'DOWN'];

    test('returns true when move matches the current index', () {
      expect(StratagemEngine.isMoveCorrect(target, 0, 'UP'), isTrue);
      expect(StratagemEngine.isMoveCorrect(target, 1, 'DOWN'), isTrue);
      expect(StratagemEngine.isMoveCorrect(target, 2, 'LEFT'), isTrue);
      expect(StratagemEngine.isMoveCorrect(target, 3, 'RIGHT'), isTrue);
      expect(StratagemEngine.isMoveCorrect(target, 4, 'UP'), isTrue);
      expect(StratagemEngine.isMoveCorrect(target, 5, 'DOWN'), isTrue);
    });

    test('returns false when move differs from current index', () {
      expect(StratagemEngine.isMoveCorrect(target, 0, 'DOWN'), isFalse);
      expect(StratagemEngine.isMoveCorrect(target, 1, 'UP'), isFalse);
      expect(StratagemEngine.isMoveCorrect(target, 2, 'RIGHT'), isFalse);
      expect(StratagemEngine.isMoveCorrect(target, 3, 'LEFT'), isFalse);
    });

    test('returns false for out-of-bounds indices', () {
      expect(StratagemEngine.isMoveCorrect(target, -1, 'UP'), isFalse);
      expect(StratagemEngine.isMoveCorrect(target, 6, 'UP'), isFalse);
      expect(StratagemEngine.isMoveCorrect(target, 100, 'UP'), isFalse);
    });

    test('returns false for empty target sequence', () {
      expect(StratagemEngine.isMoveCorrect([], 0, 'UP'), isFalse);
    });

    test('returns false for unrecognized move tokens', () {
      expect(StratagemEngine.isMoveCorrect(target, 0, 'INVALID'), isFalse);
      expect(StratagemEngine.isMoveCorrect(target, 0, 'FORWARD'), isFalse);
      expect(StratagemEngine.isMoveCorrect(target, 0, ''), isFalse);
    });

    test('handles whitespace and lowercase move tokens via normalization', () {
      expect(StratagemEngine.isMoveCorrect(target, 0, 'UP'), isTrue);
      expect(StratagemEngine.isMoveCorrect(target, 0, ' up '), isTrue);
    });
  });

  group('StratagemEngine - Interactive State Progression and Reset Simulation', () {
    test('simulates step-by-step advance and resets to 0 upon incorrect move', () {
      final target = ['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP'];
      int currentIndex = 0;

      // 1. First move correct ('UP')
      expect(StratagemEngine.isMoveCorrect(target, currentIndex, 'UP'), isTrue);
      currentIndex++;
      expect(currentIndex, equals(1));

      // 2. Second move correct ('DOWN')
      expect(StratagemEngine.isMoveCorrect(target, currentIndex, 'DOWN'), isTrue);
      currentIndex++;
      expect(currentIndex, equals(2));

      // 3. Third move WRONG ('UP' instead of 'LEFT') -> error reset
      final isCorrect = StratagemEngine.isMoveCorrect(target, currentIndex, 'UP');
      expect(isCorrect, isFalse);
      if (!isCorrect) {
        currentIndex = 0; // Reset behavior
      }
      expect(currentIndex, equals(0));

      // 4. Restart sequence after reset
      for (final move in target) {
        expect(StratagemEngine.isMoveCorrect(target, currentIndex, move), isTrue);
        currentIndex++;
      }

      // 5. Sequence completed
      expect(currentIndex, equals(target.length));
    });
  });
}
