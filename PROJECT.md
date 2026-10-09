# Project: HouseholdStratagem (Ménage Stratagem Sweeper)

## Architecture
HouseholdStratagem is a Flutter application featuring a Helldivers 2 inspired Mil-Tech Dark Tactical HUD aesthetic, adapted to household cleaning productivity with strict non-military vocabulary.

### Architecture Layers
1. **Presentation Layer (`lib/screens/`, `lib/widgets/`, `lib/theme/`)**:
   - `MilTechTheme`: Dark metallic palette (`#0B0E14`), neon amber (`#FFA500`), cyan (`#00E5FF`), yellow (`#FFCC00`), green (`#00E676`), red (`#FF1744`), beveled panels, glowing borders.
   - `AuthGate`: Initial routing based on auth state and onboarding completion.
   - `OnboardingScreen`: 4-room configuration wizard (Cuisine, Salle de bain, Salon, Chambre), periodicity editor, initial persistence.
   - `HomeScreen`: Top 3 urgent tasks cards, tactical sector map, cleaning credentials HUD (Agent Nettoyeur, Credits, Medals), cleaning navigation.
   - `StratagemScreen`: Dynamic 5 to 8 directional swipe sequence detector (`onPanEnd`), visual progress indicators, error reset.
   - `TimerScreen`: 10-minute neon tactical countdown, looping audio player, mission objectives, long-press validation.
2. **Domain & Engine Layer (`lib/models/`, `lib/engine/`)**:
   - Models: `Chore`, `MissionLog`, `UserProfile`, `RoomCategory`.
   - `TargetingEngine`: Dynamic urgency scoring formula:
     $$\text{UrgencyScore} = (\text{overdueRatio} \times 100.0) + (\text{difficulty} \times 5.0)$$
     (or $1000 + \text{difficulty} \times 10$ if never completed), selecting Top 3 urgent chores.
   - `StratagemEngine`: Generates dynamic sequences of 5 to 8 moves based on difficulty and validates directional moves step-by-step.
3. **Service & Data Layer (`lib/services/`)**:
   - `AuthService`: Interface for authentication (Firebase Auth + in-memory fallback for offline/demo).
   - `HouseholdRepository`: Interface for Firestore persistence (UserProfile, Chores catalog, Mission history + mock fallback).
   - `AudioService`: Interface for looping tactical local MP3 audio playback (`assets/audio/`) during missions and stopping upon completion/abort.

---

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Test Suite Fix | Fix existing broken widget test and ensure `flutter test` and `flutter analyze` pass cleanly | M1 | Survey |
| 2 | Data Models & Serialization | `Chore`, `MissionLog`, `UserProfile`, `RoomCategory` with full Firestore serialization | M1 | R1, R2, Survey |
| 3 | Targeting Engine & Urgency | Urgency calculation formula and Top 3 urgent tasks selection | M1 | R3 |
| 4 | Stratagem Engine & Dynamic Swipes | Dynamic swipe sequence generation (5-8 moves) and step-by-step validation | M1 | R3 |
| 5 | Audio Assets & AudioService | Bundled MP3 assets, `AudioService` with looping playback and lifecycle management | M2 | R4 |
| 6 | Firebase Dependencies & Service Layer | `firebase_core`, `firebase_auth`, `cloud_firestore` setup with repository pattern and offline fallback | M2 | R1 |
| 7 | Onboarding Room Catalogue | 4 rooms (Cuisine, Salle de bain, Salon, Chambre) with 17 predefined chores and default periodicities | M3 | R2 |
| 8 | Onboarding Customizer & Persistence | Adjust periodicity, toggle chores, validate and persist to Firestore | M3 | R2 |
| 9 | Auth & Onboarding Routing | `AuthGate` routing new users to onboarding and returning users to Home | M3 | R1, R2 |
| 10 | Mil-Tech Dark Tactical Theme | Design tokens, glowing neon borders, beveled containers matching `ui_mockups.md` | M4 | R5 |
| 11 | Tactical Home Screen HUD | Header credentials, urgent room map highlight, Start Mission CTA, Top 3 tiles, cleaning nav | M4 | R3, R5 |
| 12 | Dynamic Gesture Screen UI | 5-8 arrow display, touch/swipe detection, visual success/error feedback | M4 | R3, R5 |
| 13 | Tactical Mission Timer Screen | 10-minute neon countdown clock, rotating radar, objectives panel, audio loop integration, long-press validation | M4 | R4, R5 |
| 14 | Vocabulary Purge | Strict domestic cleaning lexicon; complete removal of "squad", "escouade", and military terms | M4 | R5 |
| 15 | E2E Integration Suite & Hardening | Complete Tier 1-4 test coverage pass + Tier 5 adversarial coverage hardening | M5 | Acceptance Criteria |

---

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | M1: Core Domain, Engines & Test Baseline | Models (`Chore`, `MissionLog`, `UserProfile`), `TargetingEngine` (Top 3 urgency), `StratagemEngine` (5-8 swipes), fix broken widget test | none | DONE |
| 2 | M2: Service Architecture & Audio System | `pubspec.yaml` dependencies, `AuthService`, `HouseholdRepository` (Firestore & demo/offline fallback), local MP3 assets, `AudioService` loop | M1 | PLANNED |
| 3 | M3: Onboarding Flow & Data Persistence | `OnboardingScreen` (4 rooms, 17 chores, periodicity customization), `AuthGate`, Firestore persistence on first run | M1, M2 | PLANNED |
| 4 | M4: Mil-Tech UI Redesign, Top 3 HUD & Gesture / Timer Screens | Full theme overhaul (`ui_mockups.md`), `HomeScreen` (Top 3 HUD, sector map), `StratagemScreen` (5-8 swipes), `TimerScreen` (neon clock, audio loop), cleaning vocabulary purge | M1, M2, M3 | PLANNED |
| 5 | M5: E2E Test Suite Validation & Adversarial Hardening | Pass 100% of E2E tests (Tiers 1-4 from E2E Track) + Tier 5 adversarial coverage hardening | M1, M2, M3, M4 | PLANNED |

---

## Interface Contracts

### `TargetingEngine`
```dart
class TargetingEngine {
  static double calculateUrgencyScore(Chore chore, {DateTime? now});
  static List<Chore> getTopTargets(List<Chore> chores, {int count = 3, DateTime? now});
}
```

### `StratagemEngine`
```dart
class StratagemEngine {
  static const List<String> directions = ['UP', 'DOWN', 'LEFT', 'RIGHT'];
  static List<String> generateSequenceForDifficulty(int difficulty, {Random? random});
  static bool isMoveCorrect(List<String> targetSequence, int currentIndex, String move);
}
```

### `AuthService` & `HouseholdRepository`
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
```

### `AudioService`
```dart
abstract class AudioService {
  Future<void> playMissionLoop(String assetPath);
  Future<void> stop();
  void dispose();
}
```

---

## Code Layout
```
app/
├── assets/
│   └── audio/
│       ├── tactical_ambiance_1.mp3
│       └── tactical_ambiance_2.mp3
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── chore.dart
│   │   ├── mission_log.dart
│   │   ├── user_profile.dart
│   │   └── room_category.dart
│   ├── engine/
│   │   ├── targeting_engine.dart
│   │   └── stratagem_engine.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── household_repository.dart
│   │   ├── firebase_auth_service.dart
│   │   ├── firestore_household_repository.dart
│   │   ├── in_memory_household_repository.dart
│   │   └── audio_service.dart
│   ├── theme/
│   │   └── mil_tech_theme.dart
│   ├── screens/
│   │   ├── auth_gate.dart
│   │   ├── onboarding_screen.dart
│   │   ├── home_screen.dart
│   │   ├── stratagem_screen.dart
│   │   └── timer_screen.dart
│   └── widgets/
│       ├── tactical_card.dart
│       ├── tactical_button.dart
│       ├── chore_tile.dart
│       └── radar_spinner.dart
└── test/
    ├── e2e/
    │   ├── tier1_feature_test.dart
    │   ├── tier2_boundary_test.dart
    │   ├── tier3_combination_test.dart
    │   └── tier4_application_test.dart
    ├── unit/
    │   ├── targeting_engine_test.dart
    │   ├── stratagem_engine_test.dart
    │   ├── models_test.dart
    │   └── repository_test.dart
    └── widget/
        ├── onboarding_screen_test.dart
        ├── home_screen_test.dart
        └── timer_screen_test.dart
```
