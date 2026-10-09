# Survey & Architecture Analysis Handoff Report

## 1. Observation

### 1.1 Environment & Toolchain
- **Command executed**: `flutter --version` (working directory: `c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\app`)
  - **Output verbatim**:
    ```
    Flutter 3.47.5 • channel stable • https://github.com/flutter/flutter.git
    Framework • revision 6a19cca564 (2 weeks ago) • 2026-09-17 14:13:22 -0400
    Engine • hash ab598368592da0064197e2bc15c7f5b0a2c6bb1f (revision af7e796e16) (17 days ago) • 2026-09-16 18:35:09.000Z
    Tools • Dart 3.13.4 • DevTools 2.60.0
    ```
- **Connected Devices**: Windows desktop (`windows-x64`), Chrome web (`web-javascript`), Android device connected wirelessly (`2407FPN8EG`, Android 16).
- **Git status**: `git status` returned `fatal: not a git repository (or any of the parent directories): .git`.

### 1.2 pubspec.yaml Analysis (`app/pubspec.yaml`)
- Package name: `household_stratagem` (line 1)
- SDK constraints: `sdk: ^3.13.4` (line 22)
- Dependencies declared (lines 30-37):
  - `flutter: sdk: flutter`
  - `cupertino_icons: ^1.0.8`
- Dev dependencies declared (lines 38-48):
  - `flutter_test: sdk: flutter`
  - `flutter_lints: ^6.0.0`
- Assets declared (lines 60-70): **None**. Commented out example lines only.
- Missing packages required for specifications:
  - Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`
  - Audio: `audioplayers` or `just_audio`
  - Testing Mocks: `fake_cloud_firestore`, `firebase_auth_mocks` (or clean abstraction)

### 1.3 Codebase File Map & Source Content
Total Dart files in `app/lib/`: **5 files** (~225 lines of Dart code total).

1. `app/lib/main.dart` (25 lines):
   - Sets up dark `ThemeData` (black background, cyanAccent body text).
   - `home: StratagemScreen()`.
   - Uses `StatelessWidget` without key constructor (triggers lint warning `use_key_in_widget_constructors`).
2. `app/lib/models.dart` (16 lines):
   - `Chore`: fields `id`, `name`, `difficulty`. Missing: `room` (Cuisine, Salle de bain, Salon, Chambre), `periodicityDays`, `lastCompletedAt`, `stratagemSequence` (5-8 directions), Firestore serialization methods (`toMap()`, `fromMap()`).
   - `MissionLog`: fields `choreId`, `completedAt`, `success`. Missing: `userId`, duration, Firestore serialization methods.
3. `app/lib/targeting_engine.dart` (12 lines):
   - Class `TargetingEngine` with single method `getAvailableTargets()`.
   - Returns 3 hardcoded `Chore` instances: `'1': Nettoyer la cuisine (diff 3)`, `'2': Sortir les poubelles (diff 1)`, `'3': Passer l'aspirateur (diff 2)`.
   - **Critical Observation**: `TargetingEngine` is never imported, called, or referenced anywhere in `lib/` or `test/`.
4. `app/lib/stratagem_screen.dart` (94 lines):
   - Tracks `List<String> _sequence = [];`.
   - `GestureDetector.onPanEnd` with threshold 100.0 detects `RIGHT`, `LEFT`, `DOWN`, `UP`.
   - Lines 15-21:
     ```dart
     if (_sequence.length >= 4) {
       Navigator.push(
         context,
         MaterialPageRoute(builder: (context) => TimerScreen()),
       );
       _sequence.clear();
     }
     ```
   - Checks only `_sequence.length >= 4`; ignores target sequence match, does not show Top 3 urgent tasks, does not use `TargetingEngine`.
5. `app/lib/timer_screen.dart` (84 lines):
   - Tracks `int _timeLeft = 600;` (10 minutes) with standard `Timer.periodic`.
   - Action: `GestureDetector.onLongPress` -> `_validateMission()`.
   - Zero audio playback logic. Zero audio package imports. Plain black screen with basic text and yellow box.
6. `app/test/widget_test.dart` (31 lines):
   - Default Flutter counter template:
     ```dart
     await tester.pumpWidget(const MyApp());
     ```

### 1.4 Test & Static Analysis Execution
- **Command executed**: `flutter test`
  - **Result**: Exit code 1 (FAILED).
  - **Output verbatim**:
    ```
    test/widget_test.dart:16:35: Error: Couldn't find constructor 'MyApp'.
        await tester.pumpWidget(const MyApp());
                                      ^^^^^
    00:00 +0 -1: loading C:/Users/krisd/.gemini/antigravity/scratch/MenageStratagemSweeper/app/test/widget_test.dart [E]
      Failed to load "C:/Users/krisd/.gemini/antigravity/scratch/MenageStratagemSweeper/app/test/widget_test.dart":
      Compilation failed for testPath=C:/Users/krisd/.gemini/antigravity/scratch/MenageStratagemSweeper/app/test/widget_test.dart: test/widget_test.dart:16:35: Error: Couldn't find constructor 'MyApp'.
          await tester.pumpWidget(const MyApp());
                                        ^^^^^
    00:00 +0 -1: Some tests failed.
    ```
- **Command executed**: `flutter analyze`
  - **Result**: Exit code 1 (7 issues found).
  - **Output verbatim**:
    ```
    info - Constructors for public widgets should have a named 'key' parameter. Try adding a named parameter to the constructor - lib\main.dart:8:7 - use_key_in_widget_constructors
    info - Constructors for public widgets should have a named 'key' parameter. Try adding a named parameter to the constructor - lib\stratagem_screen.dart:4:7 - use_key_in_widget_constructors
    info - Invalid use of a private type in a public API. Try making the private type public, or making the API that uses the private type also be private - lib\stratagem_screen.dart:6:3 - library_private_types_in_public_api
    info - The private field _sequence could be 'final'. Try making the field 'final' - lib\stratagem_screen.dart:10:16 - prefer_final_fields
    info - Constructors for public widgets should have a named 'key' parameter. Try adding a named parameter to the constructor - lib\timer_screen.dart:4:7 - use_key_in_widget_constructors
    info - Invalid use of a private type in a public API. Try making the private type public, or making the API that uses the private type also be private - lib\timer_screen.dart:6:3 - library_private_types_in_public_api
    error - The name 'MyApp' isn't a class. Try correcting the name to match an existing class - test\widget_test.dart:16:35 - creation_with_non_type
    ```

### 1.5 UI Mockup Specifications Inspection
- Mockup files identified at:
  - `C:/Users/krisd/.gemini/antigravity/brain/8594895e-dac0-45f7-be00-1e9594ff827f/ui_mockups.md`
  - `home_screen_mockup_1791116804128.jpg` (Home Screen with Operator ID, credits/medals, Priority Alert banner, Operation overview, Start Mission CTA, Mission Tiles with threat levels, Bottom navigation).
  - `timer_screen_mockup_1791116815059.jpg` (Mission Screen with top agent status, Operation banner, massive glowing neon countdown clock `00:08:43`, rotating radar insert, Current Objectives Primary/Secondary/Bonus, Mission Parameters, Bottom buttons: Cancel Deployment & Start Mission).
- Strict vocabulary rule from `ORIGINAL_REQUEST.md`: "Le vocabulaire et les icônes doivent être adaptés au thème strict du 'ménage' et de l'entretien (sans les références à des 'escouades' ou 'squads')."

---

## 2. Logic Chain

1. **Test Suite Brokenness**: Because `test/widget_test.dart` was never updated when the sample project was converted to `HouseholdStratagemApp`, `flutter test` cannot compile. Any CI/CD or verification gate will fail immediately unless `widget_test.dart` is fixed to test the actual application widgets or domain classes.
2. **Targeting Engine Disconnection**: `TargetingEngine` exists in `lib/targeting_engine.dart` but is completely unreferenced. `StratagemScreen` directly accepts 4 raw swipes without selecting any target chore or computing urgency. Therefore, requirement R3 (displaying Top 3 most urgent chores and validating complex swipe sequences) requires both connecting `TargetingEngine` to the UI and adding an urgency ranking algorithm.
3. **Data Model Deficiencies**: `Chore` only possesses `id`, `name`, and `difficulty`. It lacks room category (`Cuisine`, `Salle de bain`, `Salon`, `Chambre`), periodicity in days, `lastCompletedAt`, and stratagem swipe sequences (5-8 movements). Without these fields, neither R2 (room grouping & periodicity adjustments in Onboarding), R3 (urgency sorting and variable swipe sequences), nor R1 (saving catalog and periodicity to Firestore) can function.
4. **Firebase & Architecture Absence**: There are zero Firebase plugins in `pubspec.yaml` and zero Auth/Firestore services. Because integrity mode is `demo`, a service abstraction pattern (`AuthService` and `FirestoreService` with production Firebase implementations and mockable test implementations) is required to ensure both full Firebase integration and seamless offline/unit-test execution.
5. **Audio Pipeline Absence**: There are no audio packages in `pubspec.yaml` and zero audio assets in the project. Meeting R4 requires adding an audio package (`audioplayers` or `just_audio`), bundling tactical ambiance MP3 files in `assets/audio/`, declaring them in `pubspec.yaml`, and managing playback lifecycle (start on timer start, loop, stop on validate or cancel).
6. **UI Theming Gap**: The current UI consists of default Flutter scaffolds with black backgrounds and unstyled text. Meeting R5 requires rebuilding the layout to match `ui_mockups.md` (tactical panels, neon colors `#00F0FF`, `#FFAA00`, `#FFE500`, mission objective cards, countdown typography) while systematically replacing military jargon ("squad", "automaton invasion", "orbital insertion") with domestic cleaning and maintenance terms.

---

## 3. Caveats

- **Network / Firebase Credentials**: In `demo` integrity mode, live Google Cloud / Firebase console credentials (`google-services.json` or FirebaseOptions) are not yet provided in the repository. Implementing an abstract service layer with fake/mock backends for testing and live Firebase configuration capabilities is critical.
- **Audio Asset Availability**: The repository contains no existing MP3 assets. Local royalty-free/synth MP3 files or synthesized placeholder audio assets must be provisioned and bundled in `assets/audio/`.
- **Targeting Engine Urgency Formula**: `ORIGINAL_REQUEST.md` specifies "Top 3 des tâches les plus urgentes" based on periodicity and history, but does not dictate a rigid mathematical formula. Urgency should logically be calculated as `(daysSinceLastCompleted / periodicityDays)` or `daysOverdue`.

---

## 4. Conclusion

The current application is a barebones Flutter starter app (~225 LOC) containing 5 basic files in `lib/`. It has:
- **0% implementation of R1** (Firebase Auth & Firestore)
- **0% implementation of R2** (Onboarding flow & room-based configuration)
- **~10% implementation of R3** (rudimentary swipe listener hardcoded to 4 moves, disconnected targeting engine)
- **0% implementation of R4** (audio playback and track selection)
- **~15% implementation of R5** (basic dark colors, but lacking Mil-Tech layout and vocabulary adaptation)
- **Failing test suite** (`flutter test` fails on compilation error in `widget_test.dart`)

### Gap Analysis & Implementation Roadmap

| Requirement | Current Status | Key Missing Components |
|---|---|---|
| **R1. Firebase & Auth** | Missing (0%) | `firebase_core`, `firebase_auth`, `cloud_firestore` in `pubspec.yaml`; `AuthService`; `FirestoreService`; model serialization (`toMap`/`fromMap`). |
| **R2. Onboarding Flow** | Missing (0%) | `OnboardingScreen`; room categorization (Cuisine, Salle de bain, Salon, Chambre); default periodicity editor; persistence to Firestore before main navigation. |
| **R3. Urgency Engine & Complex Swipes** | Incomplete (~10%) | Dynamic urgency algorithm; `List<String> stratagemSequence` (5-8 moves); Top 3 urgent chore cards on main screen; swipe validation against expected code. |
| **R4. Audio System** | Missing (0%) | `audioplayers` dependency; MP3 files in `assets/audio/`; `AudioService` (looping during mission, stop on exit); sound track selection. |
| **R5. UI Refactor & Mil-Tech Theme** | Incomplete (~15%) | Mil-Tech styling matching `ui_mockups.md` (neon cyan, orange, yellow, tactical panels); massive countdown display; objective cards; strict cleaning vocabulary (removal of "squad"). |
| **Test Suite** | Broken (0% pass) | Fix `widget_test.dart`; create unit tests for `TargetingEngine`, `StratagemValidator`, and models; create widget tests for screens. |

### Recommended File Organization:
```
app/
├── assets/
│   └── audio/                  # tactical_track_1.mp3, tactical_track_2.mp3
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── chore.dart          # with room, periodicity, urgency, stratagemSequence, toMap/fromMap
│   │   ├── mission_log.dart    # with completedAt, duration, success, toMap/fromMap
│   │   ├── user_profile.dart   # with id, email, onboardingCompleted, selectedTrack
│   │   └── room_category.dart  # Cuisine, Salle de bain, Salon, Chambre
│   ├── services/
│   │   ├── auth_service.dart   # Firebase Auth + Mock fallback
│   │   ├── firestore_service.dart # Firestore + Mock fallback
│   │   └── audio_service.dart  # Audioplayers manager
│   ├── engine/
│   │   └── targeting_engine.dart # Urgency computation & top 3 selection
│   ├── theme/
│   │   └── tactical_theme.dart # Neon colors, sci-fi borders, dark metal palette
│   ├── screens/
│   │   ├── auth_gate.dart      # Routes to Onboarding or Main
│   │   ├── onboarding_screen.dart # Room tabs, periodicity sliders, save
│   │   ├── home_screen.dart    # Top 3 tiles, tactical map, swipe entry
│   │   └── timer_screen.dart   # Neon clock, audio loop, objective checks
│   └── widgets/
│       ├── tactical_panel.dart
│       ├── chore_tile.dart
│       └── stratagem_input_display.dart
└── test/
    ├── targeting_engine_test.dart
    ├── stratagem_validator_test.dart
    ├── chore_model_test.dart
    └── app_smoke_test.dart
```

---

## 5. Verification Method

1. **Verify Flutter Environment**:
   Run in `app/`:
   ```powershell
   flutter --version
   flutter devices
   ```
   Expect Flutter 3.47.5 and Dart 3.13.4.

2. **Verify Current Test Failure**:
   Run in `app/`:
   ```powershell
   flutter test
   ```
   Observe compilation error on `MyApp` in `test/widget_test.dart`.

3. **Verify Static Analysis**:
   Run in `app/`:
   ```powershell
   flutter analyze
   ```
   Observe 1 error (`MyApp` missing) and 6 info diagnostics.

4. **Invalidation Conditions**:
   This report would be invalidated if:
   - A different branch or project directory exists containing existing Firebase, audio, or onboarding code.
   - Additional Dart files outside `app/lib/` or `app/test/` are discovered.
   (Both checked and confirmed negative).
