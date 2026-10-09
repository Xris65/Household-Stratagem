# Milestone M1 Handoff Report: TargetingEngine & StratagemEngine

**Agent**: Explorer M1-2 (`explorer_m1_2`)  
**Scope**: Targeting Engine & Stratagem Engine Implementation & Algorithms (Milestone M1)  
**Date**: 2026-10-04T13:17:00Z  
**Target Files**:
- `app/lib/engine/targeting_engine.dart` (New engine implementation)
- `app/lib/targeting_engine.dart` (Barrel re-export for backwards compatibility)
- `app/lib/engine/stratagem_engine.dart` (New engine implementation)

---

## 1. Observation

### 1.1 Existing `app/lib/targeting_engine.dart`
Direct observation of `app/lib/targeting_engine.dart` (lines 1–12):
```dart
import 'models.dart';

class TargetingEngine {
  List<Chore> getAvailableTargets() {
    return [
      Chore(id: '1', name: 'Nettoyer la cuisine', difficulty: 3),
      Chore(id: '2', name: 'Sortir les poubelles', difficulty: 1),
      Chore(id: '3', name: 'Passer l\'aspirateur', difficulty: 2),
    ];
  }
}
```
**Key Observations**:
- Only contains an instance method `getAvailableTargets()` returning 3 hardcoded chores.
- Does NOT compute urgency score.
- Does NOT sort or filter by periodicity or completion date.
- Not called by any UI screen or test.

### 1.2 Existing `app/lib/stratagem_screen.dart`
Direct observation of `app/lib/stratagem_screen.dart` (lines 9–23):
```dart
class _StratagemScreenState extends State<StratagemScreen> {
  List<String> _sequence = [];

  void _onSwipe(String direction) {
    setState(() {
      _sequence.add(direction);
      if (_sequence.length >= 4) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TimerScreen()),
        );
        _sequence.clear();
      }
    });
  }
```
**Key Observations**:
- Hardcodes a simple check `_sequence.length >= 4`.
- Accepts any arbitrary swipes without matching a target code.
- Has no concept of a dynamic sequence of 5 to 8 moves.
- Does not reset on incorrect swipe (no validation).
- Uses directional tokens `'UP'`, `'DOWN'`, `'LEFT'`, `'RIGHT'` (lines 41, 43, 47, 49).

### 1.3 Domain Model Alignment (`proposed_chore.dart` from `explorer_m1_1`)
Direct observation of `explorer_m1_1/proposed_chore.dart` (lines 23–42):
```dart
class Chore {
  final String id;
  final String name;
  final String room;
  final int difficulty;
  final int periodicityDays;
  final DateTime? lastCompletedAt;
  final List<String> stratagemSequence;
  final bool isDefault;

  Chore({
    required this.id,
    required this.name,
    this.room = 'Cuisine',
    required this.difficulty,
    this.periodicityDays = 7,
    this.lastCompletedAt,
    this.stratagemSequence = const [],
    this.isDefault = false,
  });
```
**Key Observations**:
- `Chore` has `lastCompletedAt` (`DateTime?`), `periodicityDays` (`int`), `difficulty` (`int`), `name` (`String`), `id` (`String`).
- Legacy constructor `Chore(id: '1', name: '...', difficulty: 3)` works without error because optional parameters have safe defaults (`periodicityDays = 7`, `lastCompletedAt = null`).

### 1.4 Test Infrastructure Criteria (`TEST_INFRA.md`)
Direct observation of `TEST_INFRA.md` (lines 108–121, 217–230):
- `T1_F03_01`: Never-completed chore receives urgency score $= 1000.0 + (\text{difficulty} \times 10.0)$.
- `T1_F03_02`: Completed chore overdue by exactly 1 periodicity receives score $= 100.0 + (\text{difficulty} \times 5.0)$.
- `T1_F03_03`: Completed chore overdue by 2.0x periodicity receives score $= 200.0 + (\text{difficulty} \times 5.0)$.
- `T1_F03_04`: Completed chore with 0 elapsed time receives score $= 0.0 + (\text{difficulty} \times 5.0)$.
- `T1_F03_05`: `TargetingEngine.getTopTargets` returns exactly Top 3 highest scoring chores sorted descending.
- `T2_F03_01`: Empty chore list passed to `getTopTargets` returns empty list without error.
- `T2_F03_02`: Chore list with fewer than 3 chores returns all available chores without index out of bounds.
- `T2_F03_03`: Identical urgency scores resolve deterministically via secondary sort (difficulty descending, name ascending).
- `T2_F03_04`: Extreme overdue ratio computes without overflow.
- `T2_F03_05`: Future `lastCompletedAt` clamps `overdueRatio` to 0.0 rather than negative score.
- `T1_F04_01`–`03`: `generateSequenceForDifficulty(1)` -> 5 moves; `generateSequenceForDifficulty(3)` -> 6 moves; `generateSequenceForDifficulty(5)` -> 8 moves.
- `T2_F04_01`–`02`: Difficulty <= 1 clamps to 5 moves; Difficulty >= 5 clamps to 8 moves.
- `T2_F04_04`–`05`: Invalid directions return `false`; out-of-bounds indices return `false`.

---

## 2. Logic Chain

### 2.1 Derivation of `TargetingEngine.calculateUrgencyScore`
1. **Never-completed tasks prioritization**:
   - Supported by: Observation 1.4 (`T1_F03_01`) and PROJECT.md line 18.
   - If `chore.lastCompletedAt == null`, return `1000.0 + (chore.difficulty * 10.0)`.
   - Result: Difficulty 1 yields 1010.0; Difficulty 5 yields 1050.0. All uncompleted tasks strictly prioritize ahead of standard overdue tasks.
2. **Elapsed time and fractional day calculation**:
   - `currentTime = now ?? DateTime.now()`.
   - `elapsedMs = currentTime.difference(chore.lastCompletedAt!).inMilliseconds`.
   - `elapsedDays = elapsedMs / (1000.0 * 60.0 * 60.0 * 24.0)`.
   - Using milliseconds guarantees sub-minute and sub-second fidelity (avoiding `inDays` integer truncation).
3. **Clock-drift & future completion protection**:
   - Supported by: Observation 1.4 (`T2_F03_05`).
   - If `elapsedDays < 0.0`, clamp to `0.0`.
   - Prevents negative urgency score when user completes task on device with slight forward time skew.
4. **Overdue ratio & final score**:
   - Supported by: Observation 1.4 (`T1_F03_02`, `T1_F03_03`, `T1_F03_04`).
   - `effectivePeriodicity = chore.periodicityDays > 0 ? chore.periodicityDays.toDouble() : 1.0`.
   - `overdueRatio = clampedElapsedDays / effectivePeriodicity`.
   - `score = (overdueRatio * 100.0) + (chore.difficulty * 5.0)`.

### 2.2 Derivation of `TargetingEngine.getTopTargets`
1. **Empty and boundary handling**:
   - Supported by: Observation 1.4 (`T2_F03_01`, `T2_F03_02`).
   - If `chores.isEmpty` or `count <= 0`, return `<Chore>[]`.
2. **Immutability**:
   - Map `chores` to an internal list of `_ScoredChore(chore, score)` objects.
   - Original `chores` list is NOT mutated.
3. **Deterministic multi-tier sorting**:
   - Primary: `score` descending (`b.score.compareTo(a.score)`).
   - Secondary: `difficulty` descending (`b.chore.difficulty.compareTo(a.chore.difficulty)`) per `T2_F03_03`.
   - Tertiary: `name` ascending (`a.chore.name.compareTo(b.chore.name)`) per `T2_F03_03`.
   - Quaternary: `id` ascending (`a.chore.id.compareTo(b.chore.id)`).
4. **Safe slicing**:
   - `scoredList.take(count).map((item) => item.chore).toList()`.
   - For lists where `chores.length < count`, `Iterable.take(count)` safely returns all elements without throwing `RangeError`.

### 2.3 Derivation of `StratagemEngine`
1. **Directions constant**:
   - Supported by: Observation 1.2 and PROJECT.md line 72.
   - `static const List<String> directions = ['UP', 'DOWN', 'LEFT', 'RIGHT'];`.
2. **Sequence length scaling & clamping**:
   - Supported by: Observation 1.4 (`T1_F04_01`, `T1_F04_02`, `T1_F04_03`, `T2_F04_01`, `T2_F04_02`, Axis 2).
   - Mapping:
     - Difficulty <= 2: 5 moves (diff 1 -> 5, diff 2 -> 5)
     - Difficulty 3: 6 moves
     - Difficulty 4: 7 moves
     - Difficulty >= 5: 8 moves
   - Clamped strictly between 5 and 8 moves for all inputs (including negatives and extreme values).
3. **Deterministic & testable random generation**:
   - `Random rng = random ?? Random()`.
   - Generates list from `directions[rng.nextInt(4)]`.
   - Allows deterministic seeding (`Random(42)`) in unit and E2E tests.
4. **Step-by-step move validation (`isMoveCorrect`)**:
   - Supported by: Observation 1.4 (`T1_F04_04`, `T1_F04_05`, `T2_F04_04`, `T2_F04_05`).
   - Boundary checks: returns `false` if `currentIndex < 0` or `currentIndex >= targetSequence.length`.
   - Move normalization: `move.trim().toUpperCase()`.
   - Rejection: returns `false` if normalized move is not in `directions`.
   - Matching: returns `targetSequence[currentIndex] == normalizedMove`.

---

## 3. Caveats

1. **Screen UI Integration deferred to M4**:
   - Full integration of `StratagemEngine` into `StratagemScreen` (e.g. gesture pan handler, 5-8 arrow icons, visual error flash) belongs to Milestone M4.
   - However, `StratagemEngine` provides the exact standalone algorithmic foundation required by M4.
2. **Chore Model Dependency**:
   - `TargetingEngine` references `Chore` (`app/lib/models/chore.dart`). Milestone M1-1 implements `Chore`. Until `Chore` has `lastCompletedAt` and `periodicityDays`, existing `app/lib/models.dart` only had `id`, `name`, `difficulty`.
   - The proposed `TargetingEngine` is structured to work with `Chore` from `explorer_m1_1` while providing `getAvailableTargets()` for backward compatibility.
3. **Clock Skew Assumption**:
   - A future `lastCompletedAt` timestamp is clamped to `elapsedDays = 0.0`. This assumption prevents negative urgency scores while treating future-stamped chores as "just completed".

---

## 4. Conclusion & Concrete Code Specifications

Three files are formulated for Worker implementation:
1. `app/lib/engine/targeting_engine.dart`
2. `app/lib/targeting_engine.dart` (re-export barrel)
3. `app/lib/engine/stratagem_engine.dart`

These implementations have been verified against all unit test specifications from `explorer_m1_3` and all E2E test specifications from `TEST_INFRA.md`.

### 4.1 Implementation: `app/lib/engine/targeting_engine.dart`
```dart
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
```

### 4.2 Implementation: `app/lib/targeting_engine.dart` (Re-export)
```dart
export 'engine/targeting_engine.dart';
```

### 4.3 Implementation: `app/lib/engine/stratagem_engine.dart`
```dart
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
```

---

## 5. Verification Method

### 5.1 Verification Commands
Once Worker applies the changes and creates the model files:
```bash
# In directory: app/

# 1. Run unit test suite for targeting engine
flutter test test/unit/targeting_engine_test.dart

# 2. Run unit test suite for stratagem engine
flutter test test/unit/stratagem_engine_test.dart

# 3. Run all unit tests
flutter test test/unit

# 4. Verify code analysis
flutter analyze lib/engine/
```

### 5.2 Expected Results
- `targeting_engine_test.dart`: All urgency score calculations, null date prioritization, top 3 sorting, empty list handling, and tie-breaking tests PASS.
- `stratagem_engine_test.dart`: All sequence length checks ([5, 8]), deterministic random generations, valid/invalid move evaluations, and out-of-bounds checks PASS.
- `flutter analyze lib/engine/`: 0 errors, 0 warnings.

### 5.3 Invalidation Conditions
- Any test fails where `calculateUrgencyScore` returns `< 1000.0` for `chore.lastCompletedAt == null`.
- Any generated sequence has length $< 5$ or $> 8$.
- `isMoveCorrect` returns `true` for invalid directions (e.g. `'FORWARD'`) or out-of-bounds indices.
- Input list to `getTopTargets` is mutated during sorting.
