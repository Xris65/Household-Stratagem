import '../models/chore.dart';

/// Helper entry class for sorting chores by precomputed urgency scores.
class _ScoredChore {
  final Chore chore;
  final double score;

  const _ScoredChore({
    required this.chore,
    required this.score,
  });
}

/// Tactical targeting engine responsible for ranking domestic chores by urgency.
class TargetingEngine {
  /// Computes the dynamic urgency score for a given [chore] at [now] (defaults to current time).
  ///
  /// Formula specifications:
  /// - If [chore.lastCompletedAt] is null (never completed), returns maximum priority:
  ///   `1000.0 + (chore.difficulty * 10.0)`
  /// - If [chore.lastCompletedAt] is in the future (clock drift), elapsed time is clamped to 0.0:
  ///   `0.0 + (chore.difficulty * 5.0)`
  /// - Otherwise:
  ///   `overdueRatio = elapsedDays / effectivePeriodicity`
  ///   `score = (overdueRatio * 100.0) + (chore.difficulty * 5.0)`
  static double calculateUrgencyScore(Chore chore, {DateTime? now}) {
    final effectiveNow = now ?? DateTime.now();

    if (chore.lastCompletedAt == null) {
      return 1000.0 + (chore.difficulty * 10.0);
    }

    final elapsedMs = effectiveNow.difference(chore.lastCompletedAt!).inMilliseconds;
    final elapsedDays = elapsedMs / (1000.0 * 60.0 * 60.0 * 24.0);

    // Clamp to 0.0 if completed in future (T2_F03_05)
    final clampedElapsedDays = elapsedDays < 0.0 ? 0.0 : elapsedDays;

    final effectivePeriodicity = chore.periodicityDays > 0 ? chore.periodicityDays.toDouble() : 1.0;
    final overdueRatio = clampedElapsedDays / effectivePeriodicity;

    return (overdueRatio * 100.0) + (chore.difficulty * 5.0);
  }

  /// Returns the top [count] urgent chores sorted descending by urgency score.
  ///
  /// - If [chores] is empty or [count] <= 0, returns an empty list `[]`.
  /// - If [chores.length] < [count], returns all available chores sorted.
  /// - Deterministic tie-breaking order:
  ///   1. Urgency score descending
  ///   2. Difficulty descending (T2_F03_03)
  ///   3. Chore name ascending (T2_F03_03)
  ///   4. Chore ID ascending
  static List<Chore> getTopTargets(
    List<Chore> chores, {
    int count = 3,
    DateTime? now,
  }) {
    if (chores.isEmpty || count <= 0) {
      return <Chore>[];
    }

    final effectiveNow = now ?? DateTime.now();

    final scoredList = chores.map((chore) {
      final score = calculateUrgencyScore(chore, now: effectiveNow);
      return _ScoredChore(chore: chore, score: score);
    }).toList();

    scoredList.sort((a, b) {
      // 1. Urgency score descending
      final scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) return scoreComparison;

      // 2. Difficulty descending
      final diffComparison = b.chore.difficulty.compareTo(a.chore.difficulty);
      if (diffComparison != 0) return diffComparison;

      // 3. Chore name ascending
      final nameComparison = a.chore.name.compareTo(b.chore.name);
      if (nameComparison != 0) return nameComparison;

      // 4. Chore ID ascending
      return a.chore.id.compareTo(b.chore.id);
    });

    return scoredList.take(count).map((item) => item.chore).toList();
  }

  /// Legacy helper for backwards compatibility with the initial scaffold.
  List<Chore> getAvailableTargets() {
    return [
      Chore(id: '1', name: 'Nettoyer la cuisine', difficulty: 3),
      Chore(id: '2', name: 'Sortir les poubelles', difficulty: 1),
      Chore(id: '3', name: 'Passer l\'aspirateur', difficulty: 2),
    ];
  }
}
