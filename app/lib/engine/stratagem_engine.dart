import 'dart:math';

/// Tactical engine responsible for generating and validating directional stratagem sequences.
class StratagemEngine {
  /// Allowed directional swipe inputs in the stratagem system.
  static const List<String> directions = ['UP', 'DOWN', 'LEFT', 'RIGHT'];

  /// Computes the sequence length for a given [difficulty].
  ///
  /// Bound specifications (clamped between 5 and 8 moves):
  /// - Difficulty <= 2: 5 moves
  /// - Difficulty 3: 6 moves
  /// - Difficulty 4: 7 moves
  /// - Difficulty >= 5: 8 moves
  static int sequenceLengthForDifficulty(int difficulty) {
    if (difficulty <= 2) return 5;
    if (difficulty == 3) return 6;
    if (difficulty == 4) return 7;
    return 8;
  }

  /// Generates a randomized directional sequence for the given [difficulty].
  ///
  /// The sequence length is clamped between 5 and 8 moves.
  /// Accepts an optional [random] generator for deterministic testing.
  static List<String> generateSequenceForDifficulty(
    int difficulty, {
    Random? random,
  }) {
    final rng = random ?? Random();
    final length = sequenceLengthForDifficulty(difficulty);
    return List.generate(
      length,
      (_) => directions[rng.nextInt(directions.length)],
    );
  }

  /// Validates whether the user's [move] matches the expected direction at [currentIndex].
  ///
  /// Rules:
  /// - Returns `false` if [currentIndex] is out of bounds (< 0 or >= targetSequence.length).
  /// - Normalizes [move] to uppercase and trims whitespace.
  /// - Returns `false` if [move] is not a valid directional command.
  /// - Returns `true` if and only if [targetSequence[currentIndex]] matches the normalized [move].
  static bool isMoveCorrect(
    List<String> targetSequence,
    int currentIndex,
    String move,
  ) {
    if (currentIndex < 0 || currentIndex >= targetSequence.length) {
      return false;
    }
    final normalizedMove = move.trim().toUpperCase();
    if (!directions.contains(normalizedMove)) {
      return false;
    }
    return targetSequence[currentIndex] == normalizedMove;
  }
}
