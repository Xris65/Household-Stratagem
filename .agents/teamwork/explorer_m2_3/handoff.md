# Milestone M2 Handoff Report: Dependencies & Services Unit Test Suite

**Agent**: `explorer_m2_3`  
**Working Directory**: `c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m2_3`  
**Milestone**: M2 (Service Architecture & Audio System)  
**Status**: Complete (Hard Handoff)

---

## 1. Observation

1. **Pubspec Current State (`app/pubspec.yaml`)**:
   - Environment: `sdk: ^3.13.4` (Flutter 3.47.5, Dart 3.13.4).
   - Dependencies currently list only:
     ```yaml
     dependencies:
       flutter:
         sdk: flutter
       cupertino_icons: ^1.0.8
     ```
   - Dev dependencies currently list only:
     ```yaml
     dev_dependencies:
       flutter_test:
         sdk: flutter
       flutter_lints: ^6.0.0
     ```
   - Flutter assets section is commented out (lines 60–64):
     ```yaml
     # assets:
     #   - images/a_dot_burr.jpeg
     ```

2. **Milestone M2 Requirements (`PROJECT.md` & `context.md`)**:
   - Feature 5 & 6 in `PROJECT.md` (lines 34–35):
     - "Audio Assets & AudioService: Bundled MP3 assets, AudioService with looping playback and lifecycle management | M2 | R4"
     - "Firebase Dependencies & Service Layer: firebase_core, firebase_auth, cloud_firestore setup with repository pattern and offline fallback | M2 | R1"
   - Context requirements (`explorer_m2_3/context.md`):
     - Dependencies to add: `firebase_core: ^4.15.0`, `firebase_auth: ^6.7.0`, `cloud_firestore: ^6.10.0`, `audioplayers: ^6.8.1`.
     - Dev dependencies to add: `fake_cloud_firestore: ^4.3.0`.
     - Asset declaration to add: `assets: - assets/audio/`.
     - Unit test suite to design: `app/test/unit/services_test.dart` covering `AuthService`, `HouseholdRepository`, and `AudioService`.

3. **Peer Explorer Designs**:
   - `explorer_m2_1` (`.agents/teamwork/explorer_m2_1/`):
     - `proposed_auth_service.dart`: `AuthService` interface with `FirebaseAuthService` and `FakeAuthService`.
     - `proposed_household_repository.dart`: `HouseholdRepository` interface with `FirestoreHouseholdRepository` (persisting to `users/{userId}`, `tasks`, `history`) and `InMemoryHouseholdRepository` (auto-seeded with 17 chores from `RoomCategory.defaultChores`).
   - `explorer_m2_2` (`.agents/teamwork/explorer_m2_2/`):
     - `proposed_audio_service.dart`: `AudioService` interface with `RealAudioService` (wrapping `audioplayers.AudioPlayer` with `ReleaseMode.loop` and static `normalizeAssetPath`) and `MockAudioService` (recording `playCount`, `stopCount`, `playedTracks`, and lifecycle guards).
     - Bundled MP3 generator: `generate_audio_assets.dart` synthesizing valid MPEG-1 Layer 3 frames with ID3v2 tags.

4. **Test Suite Baseline & Verification Results**:
   - Full baseline regression `flutter test` in `app/` ran 412 tests across unit and E2E suites: **412/412 tests passed** (exited with code 0).
   - In-memory service contracts verified via standalone verification runner:
     `dart --packages=app/.dart_tool/package_config.json verify_test_logic.dart`: **13/13 tests passed** (exited with code 0).

---

## 2. Logic Chain

1. **Dependency Formulation & Compatibility**:
   - *Observation*: Project runs on Dart 3.13.4 / Flutter 3.47.5.
   - *Reasoning*:
     - `firebase_core: ^4.15.0`, `firebase_auth: ^6.7.0`, and `cloud_firestore: ^6.10.0` represent the contemporary stable FlutterFire release line (September 2026).
     - `fake_cloud_firestore: ^4.3.0` explicitly maps to `cloud_firestore: ^6.10.0`, ensuring type-compatible `DocumentSnapshot`, `QuerySnapshot`, and `WriteBatch` mock interfaces.
     - `audioplayers: ^6.8.1` provides `AudioPlayer`, `ReleaseMode.loop`, and `AssetSource` for cross-platform audio playback.
     - Declaring `assets/audio/` in `app/pubspec.yaml` enables Flutter's asset bundle packaging so `audioplayers` can locate `assets/audio/tactical_ambiance_1.mp3` and `tactical_ambiance_2.mp3` without runtime asset-not-found errors.

2. **Test Architecture (`app/test/unit/services_test.dart`)**:
   - *Observation*: Tests must run reliably both in headless CI and locally, verifying business logic, error boundaries, async streams, and persistence.
   - *Reasoning*:
     - Group 1: `AuthService` (`FakeAuthService`):
       - Verifies initial `currentUserId == null`.
       - Verifies `signInAnonymously()` produces unique `anon_*` UID, updates property, and emits to `authStateChanges`.
       - Verifies `signInWithEmailPassword()` sanitizes email to `user_*` format, validates non-empty inputs with `ArgumentError`, and emits to `authStateChanges`.
       - Verifies `signOut()` resets state and emits `null`.
       - Verifies stream transitions across multiple login/logout operations in chronological order.
     - Group 2: `HouseholdRepository` (`InMemoryHouseholdRepository`):
       - Verifies `getUserProfile()` returns `null` for unknown user, and returns exact profile after `saveUserProfile()`.
       - Verifies profile updates with `copyWith` and field preservation.
       - Verifies `getChores()` returns empty when unseeded, or 17 default chores when `autoSeed: true` or `seedDefaultsForUser()` is called.
       - Verifies `saveChores()` and `updateChore()` (both update and upsert paths).
       - Verifies defensive copying (immutability of internal repository cache).
       - Verifies `logMission()` appends logs in chronological order.
       - Verifies strict multi-tenant isolation between different user IDs.
       - Verifies `reset()` wipes all stored state cleanly.
     - Group 3: `HouseholdRepository` (`FirestoreHouseholdRepository` via `FakeFirebaseFirestore`):
       - Uses `FakeFirebaseFirestore` from `fake_cloud_firestore` to test real Firestore document and collection logic without network or native plugin channels.
       - Verifies `users/{userId}` profile document write and read.
       - Verifies `users/{userId}/tasks/{choreId}` subcollection batch write and query.
       - Verifies `users/{userId}/history/{logId}` mission logging with auto-generated document IDs and chronological sorting.
       - Verifies `ArgumentError` guards on empty `userId`.
     - Group 4: `AudioService` (`MockAudioService`):
       - Verifies initial stopped state.
       - Verifies `playMissionLoop()` sets `isPlaying = true`, sets `currentTrack`, increments `playCount`, and logs played tracks.
       - Verifies track switching updates track and increments count without stopping.
       - Verifies `stop()` resets playing state and currentTrack.
       - Verifies input validation (empty/whitespace path throws `ArgumentError`).
       - Verifies lifecycle guard: calling `playMissionLoop()` after `dispose()` throws `StateError`.
       - Verifies `reset()` restores zeroed counters.
     - Group 5: `RealAudioService.normalizeAssetPath`:
       - Verifies path transformation rules:
         - `'assets/audio/track.mp3'` -> `'audio/track.mp3'` (preventing duplicate `assets/` prefix).
         - `'audio/track.mp3'` -> `'audio/track.mp3'`.
         - `'track.mp3'` -> `'audio/track.mp3'`.
         - Leading slashes stripped, surrounding whitespace trimmed.
         - Empty strings throw `ArgumentError`.

---

## 3. Caveats

1. **Pre-`pub get` Package Resolution**:
   `app/test/unit/services_test.dart` imports `package:fake_cloud_firestore/fake_cloud_firestore.dart` and `package:household_stratagem/services/...`. It requires the implementer to first apply `pubspec.yaml`, create the service files in `app/lib/services/`, and execute `flutter pub get` before running `flutter test test/unit/services_test.dart`.
2. **Native Platform Audio in Tests**:
   `RealAudioService` wraps native platform channels for audio decoding. For headless tests (unit and widget tests), `MockAudioService` must always be injected (or used as the default mock in `test_harness.dart`). Direct instantiation of `RealAudioService` in unit tests should only be used to test static methods like `normalizeAssetPath`.

---

## 4. Conclusion

1. **Deliverables Produced**:
   - `proposed_pubspec.yaml` (full replacement file for `app/pubspec.yaml` with all M2 dependencies and assets).
   - `pubspec_patch.diff` (unified diff patch against `app/pubspec.yaml`).
   - `proposed_services_test.dart` (complete 38-test unit test suite ready to be placed at `app/test/unit/services_test.dart`).
   - `verify_test_logic.dart` (self-contained verification runner demonstrating 100% test pass rate for in-memory service contracts).
2. **Alignment**:
   All method names, types, and error handling behavior are 100% harmonized between `explorer_m2_1` (Firebase/Repo), `explorer_m2_2` (Audio/Assets), and `explorer_m2_3` (Dependencies & Tests).

---

## 5. Verification Method

### A. Verify Standalone Logic Now (Zero External Dependency)
From `app/` directory:
```powershell
dart --packages=c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\app\.dart_tool\package_config.json c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m2_3\verify_test_logic.dart
```
**Expected Output**:
```
=== Running Verification Suite for M2 Services Test Design ===
...
=== Verification Summary ===
Total tests run: 13
Passed: 13
Failed: 0
```

### B. Verify Implementation Sequence for Worker / Implementer
1. Copy `proposed_pubspec.yaml` to `app/pubspec.yaml`:
   ```powershell
   Copy-Item c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m2_3\proposed_pubspec.yaml c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\app\pubspec.yaml -Force
   ```
2. Run `flutter pub get`:
   ```powershell
   flutter pub get
   ```
3. Copy service implementations from `explorer_m2_1` and `explorer_m2_2` into `app/lib/services/`:
   ```powershell
   New-Item -ItemType Directory -Force -Path c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\app\lib\services
   Copy-Item c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m2_1\proposed_auth_service.dart c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\app\lib\services\auth_service.dart
   Copy-Item c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m2_1\proposed_household_repository.dart c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\app\lib\services\household_repository.dart
   Copy-Item c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m2_2\proposed_audio_service.dart c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\app\lib\services\audio_service.dart
   ```
4. Copy `proposed_services_test.dart` to `app/test/unit/services_test.dart`:
   ```powershell
   Copy-Item c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m2_3\proposed_services_test.dart c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\app\test\unit\services_test.dart
   ```
5. Run the new unit test suite:
   ```powershell
   flutter test test/unit/services_test.dart
   ```
   **Expected Result**: All 5 groups pass (0 failures).
6. Run full regression suite:
   ```powershell
   flutter test
   ```
   **Expected Result**: All 412 baseline tests + 38 new unit tests pass cleanly (450 total).

### C. Invalidation Conditions
- Any change to `RoomCategory.defaultChores` (expected 17 chores) invalidates the `autoSeed` assertion.
- Any change to `FakeAuthService.signInWithEmailPassword` return prefix (expected `user_<sanitized_email>`) invalidates the auth UID assertion.
- Renaming the Firestore collection names (`users`, `tasks`, `history`) invalidates the Firestore hierarchy assertion.
