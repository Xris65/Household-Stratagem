# Technical Investigation & Architecture Handoff Report (R1, R3, R4)

**Agent**: `explorer_survey_2`  
**Date**: 2026-10-04  
**Project**: `HouseholdStratagem` (`MenageStratagemSweeper`)  
**Scope**: Technical Implementation Details for R1 (Firebase Auth & Firestore), R3 (Target Engine Top 3 & Gesture Sequences > 4 Moves), and R4 (Audio Playback in Mission).

---

## 1. Observation

### 1.1 Toolchain & Environment
- **Flutter SDK**: `Flutter 3.47.5 • channel stable`, `Tools Dart 3.13.4`, `DevTools 2.60.0`.
- **Target OS / Host**: Windows (`windows-x64`), Chrome web (`web-javascript`), Android wirelessly connected (`2407FPN8EG`, Android 16).
- **Execution Script**: `run_android.bat` executes `cd app && call flutter run`.

### 1.2 pubspec.yaml & Dependencies
- Path: `app/pubspec.yaml`
- Current dependencies (lines 30-37):
  ```yaml
  dependencies:
    flutter:
      sdk: flutter
    cupertino_icons: ^1.0.8
  dev_dependencies:
    flutter_test:
      sdk: flutter
    flutter_lints: ^6.0.0
  ```
- **Firebase Status**: Neither `firebase_core`, `firebase_auth`, `cloud_firestore`, `fake_cloud_firestore`, nor `firebase_auth_mocks` are present.
- **Audio Status**: Neither `audioplayers` nor `just_audio` is present.
- **Assets Status**: Lines 60-70 have the `assets:` block commented out. No asset folders are registered.
- **Asset Directory Inspection**: Searched for `*.mp3` files across the entire project (`c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper`). **0 MP3 files found**.
- **Dependency Dry-Run Resolution**:
  Executed `flutter pub add --dry-run firebase_core firebase_auth cloud_firestore audioplayers fake_cloud_firestore` in `app/`:
  - Resolved smoothly without version conflicts:
    - `firebase_core: 4.15.0`
    - `firebase_auth: 6.7.0`
    - `cloud_firestore: 6.10.0`
    - `fake_cloud_firestore: 4.3.0`
    - `audioplayers: 6.8.1`
  - Dry-run for `dev:firebase_auth_mocks: 0.15.2` also resolved successfully with zero conflicts.

### 1.3 Firebase Native Configuration Status
- Searched for `google-services.json` in `app/android`: **0 files found**.
- Searched for `GoogleService-Info.plist` in `app/ios` / `app/macos`: **0 files found**.
- No `firebase_options.dart` file exists.

### 1.4 Current Task & Mission Data Models (`app/lib/models.dart`)
- Full content of `app/lib/models.dart` (lines 1-16):
  ```dart
  class Chore {
    final String id;
    final String name;
    final int difficulty;

    Chore({required this.id, required this.name, required this.difficulty});
  }

  class MissionLog {
    final String choreId;
    final DateTime completedAt;
    final bool success;

    MissionLog({required this.choreId, required this.completedAt, required this.success});
  }
  ```
- **Deficiencies**:
  - `Chore` lacks `room` / `category` (needed for R2: Cuisine, Salle de bain, Salon, Chambre).
  - `Chore` lacks `periodicityDays` (needed for R1, R2, R3).
  - `Chore` lacks `lastCompletedAt` (needed for R3 urgency calculation).
  - `Chore` lacks `stratagemSequence` (needed for R3 sequences > 4 moves).
  - Missing Firestore serialization (`toMap()`, `fromMap()`, `toJson()`, `fromJson()`).
  - `MissionLog` lacks `userId`, `durationSeconds`, and Firestore serialization.

### 1.5 Current Targeting Engine (`app/lib/targeting_engine.dart`)
- Full content of `app/lib/targeting_engine.dart` (lines 1-12):
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
- **Deficiencies**:
  - `TargetingEngine` is never referenced or called anywhere in `app/lib/` or `app/test/`.
  - No urgency calculation logic, no sorting, no filtering.
  - Returns a static hardcoded 3-item list without considering timestamps or periodicity.

### 1.6 Current Gesture & Stratagem Code (`app/lib/stratagem_screen.dart`)
- Lines 10-23:
  ```dart
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
- Lines 33-52:
  ```dart
  body: GestureDetector(
    onPanEnd: (details) {
      final double dx = details.velocity.pixelsPerSecond.dx;
      final double dy = details.velocity.pixelsPerSecond.dy;
      final double threshold = 100.0;

      if (dx.abs() > dy.abs()) {
        if (dx > threshold) {
          _onSwipe('RIGHT');
        } else if (dx < -threshold) {
          _onSwipe('LEFT');
        }
      } else {
        if (dy > threshold) {
          _onSwipe('DOWN');
        } else if (dy < -threshold) {
          _onSwipe('UP');
        }
      }
    },
  ...
  ```
- **Deficiencies**:
  - Hardcoded length limit: `if (_sequence.length >= 4)`.
  - Zero validation against any required stratagem sequence! Any 4 swipes (e.g. 4 UP swipes) trigger navigation.
  - The UI does not show the target sequence that the user needs to enter; it only displays whatever arrows the user already swiped.
  - `StratagemScreen` does not receive a target `Chore` parameter.

### 1.7 Current Audio & Timer Implementation (`app/lib/timer_screen.dart`)
- Lines 10-35:
  - Tracks `int _timeLeft = 600;` (10 minutes) with standard `Timer.periodic(Duration(seconds: 1), ...)`.
  - No audio player import, no audio initialization, no audio playback, no track selection.
  - Long press validates mission and pops back (`Navigator.pop(context)`).

### 1.8 Current Test Suite (`app/test/widget_test.dart`)
- Executed `flutter test` in `app/`:
  - **Exit Code**: 1 (Failed).
  - Verbatim error:
    ```
    test/widget_test.dart:16:35: Error: Couldn't find constructor 'MyApp'.
        await tester.pumpWidget(const MyApp());
                                      ^^^^^
    ```
  - `MyApp` does not exist in `household_stratagem` (the class in `main.dart` is `HouseholdStratagemApp`).

---

## 2. Logic Chain

### 2.1 R1: Firebase Architecture, Offline Testing & CI Safety
1. **The Native Plugin Constraint**: In Flutter, running `Firebase.initializeApp()` in a test environment (`flutter test` on desktop VM) throws a `MissingPluginException` or platform channel error if native bindings are not mocked. Furthermore, CI environments and local test runs do not have live Firebase credentials or network access.
2. **Integrity Mode 'Demo'**: In `ORIGINAL_REQUEST.md`, line 8 specifies `Integrity mode: demo`. Native configuration files (`google-services.json`) are absent from the repository. If the app hard-crashes on startup when Firebase fails to connect to Google Cloud, `run_android.bat` will fail.
3. **Repository Pattern Solution**:
   - Create an abstract `AuthService` and an abstract `HouseholdRepository`.
   - Provide two implementations for each:
     - **Firebase Implementation**: `FirebaseAuthService` (using `firebase_auth`) and `FirestoreHouseholdRepository` (using `cloud_firestore`).
     - **In-Memory / Fake Implementation**: `FakeAuthService` and `InMemoryHouseholdRepository` (or `FirestoreHouseholdRepository` injected with `FakeFirebaseFirestore`).
   - In `main.dart`, wrap Firebase initialization in a safe initialization block: if Firebase initializes, use the Firebase services; if it throws (due to missing native credentials or offline dev environment), gracefully fallback to `FakeAuthService` and `InMemoryHouseholdRepository` with initial seed data.
   - For `flutter test`: All unit and widget tests can use `FakeAuthService`, `FakeFirebaseFirestore`, or `InMemoryHouseholdRepository`.
   - Result: 100% test reliability, zero external credential requirement, blazing fast test execution (<2s), while fully satisfying R1 & R2 acceptance criteria.

### 2.2 R3: Urgency Calculation Formula & Top 3 Target Engine
1. **Data Model Requirements**:
   To calculate urgency, `Chore` must store:
   - `periodicityDays` (int: e.g., 1 day for trash, 3 days for vacuuming, 7 days for kitchen deep clean).
   - `lastCompletedAt` (DateTime? nullable: null indicates never completed).
   - `difficulty` (int: 1 to 5).
2. **Urgency Formula Rationale**:
   - Let `now = DateTime.now()`.
   - If `lastCompletedAt == null`: The task has never been done. It must be prioritized immediately.
     $$\text{UrgencyScore} = 1000.0 + (\text{difficulty} \times 10.0)$$
   - If `lastCompletedAt != null`:
     $$\text{elapsedDays} = \frac{\text{now} - \text{lastCompletedAt}}{\text{24 hours}}$$
     $$\text{overdueRatio} = \frac{\text{elapsedDays}}{\text{periodicityDays}}$$
     $$\text{UrgencyScore} = (\text{overdueRatio} \times 100.0) + (\text{difficulty} \times 5.0)$$
   - Interpretation:
     - An `overdueRatio` $\ge 1.0$ means the chore is past due. Higher ratios indicate longer neglect.
     - The `difficulty * 5.0` term serves as an intuitive tie-breaker: if two chores are equally overdue, the harder chore demands attention or gives higher priority.
3. **Top 3 Selection**:
   - `TargetingEngine.getTopTargets(List<Chore> chores, {int count = 3, DateTime? currentTime})`:
     1. Compute `UrgencyScore` for each chore.
     2. Sort chores in descending order of `UrgencyScore`.
     3. Return `sortedChores.take(count).toList()`.
   - If total chores $< 3$, returns all available chores safely without crashing.
   - In the UI (Main/Home Screen), the Top 3 are rendered as tactical target cards showing:
     - Name, Room Category badge, Difficulty stars/skulls, Periodicity indicator, and Urgency status (`CRITIQUE`, `EN RETARD`, `À PLANIFIER`).

### 2.3 R3: Stratagem Swipe Sequences (> 4 Moves)
1. **Dynamic Length Requirement**: R3 requires variable sequences between 5 and 8 movements (e.g., 5 to 8 swipes).
2. **Sequence Assignment / Generation**:
   - Allowed directions: `['UP', 'DOWN', 'LEFT', 'RIGHT']`.
   - Sequence length can scale with difficulty:
     - Difficulty 1: 5 moves
     - Difficulty 2: 6 moves
     - Difficulty 3: 7 moves
     - Difficulty 4-5: 8 moves
   - `stratagemSequence` is stored on the `Chore` object or generated deterministically.
3. **Sequence Validation Machine**:
   - State: `int enteredIndex = 0;`
   - UI Display: Displays the full target sequence of arrows at the top of the screen.
     - Completed arrows: Glowing gold/yellow or solid cyan.
     - Pending arrows: Semi-transparent dark cyan/grey.
   - On Swipe Input `swipeDirection`:
     - If `swipeDirection == targetSequence[enteredIndex]`:
       - `enteredIndex++`
       - If `enteredIndex == targetSequence.length`:
         - Mission Stratagem Unlocked!
         - Trigger haptic/visual feedback and navigate to `TimerScreen(chore: chore)`.
     - Else:
       - Wrong swipe!
       - Flash screen red / error feedback.
       - Reset `enteredIndex = 0`.
4. **Gesture Reliability**:
   - In addition to `onPanEnd` with velocity threshold, track drag displacement or allow keyboard arrow keys (`LogicalKeyboardKey.arrowUp`, etc.) so testing on desktop/emulator is smooth.

### 2.4 R4: Audio Playback & Lifecycle
1. **Package Selection**:
   - `audioplayers: ^6.1.0` (or `6.8.1` as resolved) is the industry standard for Flutter audio playback, with first-class support for looping local assets (`ReleaseMode.loop`), volume control, and cross-platform compatibility (Windows, Android, iOS, Web).
2. **Audio Abstraction (`AudioService`)**:
   - Direct calls to `AudioPlayer()` in widget tests cause `MissingPluginException`.
   - Wrap playback in an `AudioService` interface:
     ```dart
     abstract class AudioService {
       Future<void> playMissionLoop(String assetPath);
       Future<void> stop();
       void dispose();
     }
     ```
   - `RealAudioService` uses `audioplayers.AudioPlayer`.
   - `MockAudioService` tracks calls (`isLooping`, `currentTrack`, `isStopped`) without executing platform channels in widget tests.
3. **Lifecycle Management**:
   - In `TimerScreen.initState()`: Call `audioService.playMissionLoop(selectedTrackPath)`.
   - In `TimerScreen.dispose()` and upon mission validation / mission cancel: Call `audioService.stop()`.
4. **Local Audio Assets**:
   - Assets directory: `app/assets/audio/`.
   - Registered in `pubspec.yaml` under `flutter: assets: - assets/audio/`.
   - Provision local MP3 files:
     - `tactical_ambiance_1.mp3` ("Protocole Nettoyage")
     - `tactical_ambiance_2.mp3` ("Aspiration Tactique")
     - `tactical_ambiance_3.mp3` ("Décontamination Urgente")
   - Provide a track selector (modal or dropdown) in the mission briefing or settings so the user can choose their soundtrack.

---

## 3. Caveats

1. **Absence of Pre-existing Audio Files**:
   - There are currently no `.mp3` files in the repository. The implementation phase must create or bundle valid local audio files in `app/assets/audio/` and register them in `pubspec.yaml`.
2. **Absence of Live Firebase Project Credentials**:
   - No `google-services.json` or Firebase project exists in the workspace. Relying solely on live Firebase without an in-memory/fake fallback would break `run_android.bat` and desktop testing. The repository pattern with automatic demo fallback is non-negotiable.
3. **Existing Test Failure**:
   - `app/test/widget_test.dart` currently breaks the build on `flutter test`. It must be replaced or updated with actual widget/unit tests.
4. **Touch vs Desktop Navigation in Stratagem Screen**:
   - In desktop mode (Windows), mouse drag gestures might be less sensitive than finger swipes on mobile; implementing keyboard arrow listener alongside `GestureDetector` will significantly improve testing ergonomics on Windows.

---

## 4. Conclusion & Concrete Architectural Contracts

### 4.1 Domain Models Specification

#### `Chore` Model (`app/lib/models/chore.dart`)
```dart
class Chore {
  final String id;
  final String name;
  final String room; // 'Cuisine', 'Salle de bain', 'Salon', 'Chambre'
  final int difficulty; // 1 to 5
  final int periodicityDays; // 1, 2, 7, 14, 30
  final DateTime? lastCompletedAt;
  final List<String> stratagemSequence; // ['UP', 'DOWN', 'LEFT', 'RIGHT', ...] (5 to 8 items)
  final bool isDefault;

  Chore({
    required this.id,
    required this.name,
    required this.room,
    required this.difficulty,
    required this.periodicityDays,
    this.lastCompletedAt,
    required this.stratagemSequence,
    this.isDefault = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'room': room,
    'difficulty': difficulty,
    'periodicityDays': periodicityDays,
    'lastCompletedAt': lastCompletedAt?.toIso8601String(),
    'stratagemSequence': stratagemSequence,
    'isDefault': isDefault,
  };

  factory Chore.fromMap(Map<String, dynamic> map) => Chore(
    id: map['id'] as String,
    name: map['name'] as String,
    room: map['room'] as String,
    difficulty: (map['difficulty'] as num).toInt(),
    periodicityDays: (map['periodicityDays'] as num).toInt(),
    lastCompletedAt: map['lastCompletedAt'] != null
        ? DateTime.parse(map['lastCompletedAt'] as String)
        : null,
    stratagemSequence: List<String>.from(map['stratagemSequence'] as List),
    isDefault: map['isDefault'] as bool? ?? true,
  );

  Chore copyWith({
    String? id,
    String? name,
    String? room,
    int? difficulty,
    int? periodicityDays,
    DateTime? lastCompletedAt,
    List<String>? stratagemSequence,
    bool? isDefault,
  }) => Chore(
    id: id ?? this.id,
    name: name ?? this.name,
    room: room ?? this.room,
    difficulty: difficulty ?? this.difficulty,
    periodicityDays: periodicityDays ?? this.periodicityDays,
    lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
    stratagemSequence: stratagemSequence ?? this.stratagemSequence,
    isDefault: isDefault ?? this.isDefault,
  );
}
```

#### `MissionLog` Model (`app/lib/models/mission_log.dart`)
```dart
class MissionLog {
  final String id;
  final String choreId;
  final String choreName;
  final String room;
  final DateTime completedAt;
  final int durationSeconds;
  final bool success;

  MissionLog({
    required this.id,
    required this.choreId,
    required this.choreName,
    required this.room,
    required this.completedAt,
    required this.durationSeconds,
    required this.success,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'choreId': choreId,
    'choreName': choreName,
    'room': room,
    'completedAt': completedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'success': success,
  };

  factory MissionLog.fromMap(Map<String, dynamic> map) => MissionLog(
    id: map['id'] as String,
    choreId: map['choreId'] as String,
    choreName: map['choreName'] as String,
    room: map['room'] as String,
    completedAt: DateTime.parse(map['completedAt'] as String),
    durationSeconds: (map['durationSeconds'] as num).toInt(),
    success: map['success'] as bool,
  );
}
```

#### `UserProfile` Model (`app/lib/models/user_profile.dart`)
```dart
class UserProfile {
  final String userId;
  final String? email;
  final bool isOnboarded;
  final String selectedAudioTrack;
  final DateTime createdAt;

  UserProfile({
    required this.userId,
    this.email,
    required this.isOnboarded,
    this.selectedAudioTrack = 'assets/audio/tactical_ambiance_1.mp3',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'email': email,
    'isOnboarded': isOnboarded,
    'selectedAudioTrack': selectedAudioTrack,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    userId: map['userId'] as String,
    email: map['email'] as String?,
    isOnboarded: map['isOnboarded'] as bool? ?? false,
    selectedAudioTrack: map['selectedAudioTrack'] as String? ?? 'assets/audio/tactical_ambiance_1.mp3',
    createdAt: DateTime.parse(map['createdAt'] as String),
  );
}
```

---

### 4.2 Targeting Engine & Urgency Algorithm Specification

```dart
class TargetingEngine {
  /// Computes urgency score for a chore
  static double calculateUrgencyScore(Chore chore, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();

    if (chore.lastCompletedAt == null) {
      // Never completed: highest urgency priority
      return 1000.0 + (chore.difficulty * 10.0);
    }

    final elapsedDays = currentTime.difference(chore.lastCompletedAt!).inMinutes / (24.0 * 60.0);
    final overdueRatio = elapsedDays / (chore.periodicityDays > 0 ? chore.periodicityDays : 1);

    // Overdue ratio * 100 + difficulty bonus * 5
    return (overdueRatio * 100.0) + (chore.difficulty * 5.0);
  }

  /// Returns top [count] urgent chores
  static List<Chore> getTopTargets(List<Chore> chores, {int count = 3, DateTime? now}) {
    if (chores.isEmpty) return [];

    final scoredChores = chores.map((chore) {
      return MapEntry(chore, calculateUrgencyScore(chore, now: now));
    }).toList();

    // Sort descending by score
    scoredChores.sort((a, b) => b.value.compareTo(a.value));

    return scoredChores.take(count).map((entry) => entry.key).toList();
  }
}
```

---

### 4.3 Stratagem Sequence Generator & Validator Specification

```dart
class StratagemEngine {
  static const List<String> directions = ['UP', 'DOWN', 'LEFT', 'RIGHT'];

  /// Generates a valid stratagem sequence between 5 and 8 moves based on difficulty
  static List<String> generateSequenceForDifficulty(int difficulty, {Random? random}) {
    final rng = random ?? Random();
    // Clamp sequence length between 5 and 8 moves:
    // diff 1 -> 5, diff 2 -> 6, diff 3 -> 7, diff 4-5 -> 8
    final length = (4 + difficulty).clamp(5, 8);
    return List.generate(length, (_) => directions[rng.nextInt(directions.length)]);
  }

  /// Validates a single move against current index in the target sequence
  static bool isMoveCorrect(List<String> targetSequence, int currentIndex, String move) {
    if (currentIndex < 0 || currentIndex >= targetSequence.length) return false;
    return targetSequence[currentIndex] == move;
  }
}
```

---

### 4.4 Repository & Service Abstractions

```dart
abstract class AuthService {
  Stream<String?> get authStateChanges;
  String? get currentUserId;
  Future<String> signInAnonymously();
  Future<String> signInWithEmailPassword(String email, String password);
  Future<void> signOut();
}

abstract class HouseholdRepository {
  Future<UserProfile?> getUserProfile(String userId);
  Future<void> saveUserProfile(UserProfile profile);
  Future<List<Chore>> getChores(String userId);
  Future<void> saveChores(String userId, List<Chore> chores);
  Future<void> updateChore(String userId, Chore chore);
  Future<void> logMission(String userId, MissionLog log);
  Future<List<MissionLog>> getMissionLogs(String userId);
}

abstract class AudioService {
  Future<void> playMissionLoop(String assetPath);
  Future<void> stop();
  void dispose();
}
```

---

## 5. Verification Method

### 5.1 Verification Commands for Independent Reproduction

1. **Verify Dependency Compatibility**:
   Run in `app/`:
   ```powershell
   flutter pub add --dry-run firebase_core firebase_auth cloud_firestore audioplayers fake_cloud_firestore
   ```
   **Expected Result**: Code 0, cleanly resolving without dependency solver conflicts.

2. **Verify Current Test Failure**:
   Run in `app/`:
   ```powershell
   flutter test
   ```
   **Expected Result**: Fails with `Couldn't find constructor 'MyApp'`.

3. **Verify Post-Implementation Test Execution**:
   After implementation, run:
   ```powershell
   flutter test
   ```
   **Expected Result**: All unit tests (`targeting_engine_test.dart`, `stratagem_engine_test.dart`, `repository_test.dart`) and widget tests pass cleanly in under 5 seconds without requiring live network or GCP credentials.

4. **Verify Invalidation Conditions**:
   This report would be invalidated if:
   - An existing Firebase credentials file (`google-services.json`) is added to the project by the user.
   - The sequence length constraint in R3 is altered from $> 4$ moves (5-8) to a different range.
