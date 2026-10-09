# TEST_INFRA — Test Infrastructure Specification

**Project**: HouseholdStratagem (Ménage Stratagem Sweeper)  
**Version**: 1.0.0  
**Status**: APPROVED & ACTIVE  
**Author**: E2E Test Writer (`e2e_test_writer`)  
**Scope**: Requirement-Driven Opaque-Box E2E Testing Track (Tiers 1–4)

---

## 1. Testing Methodology Overview

HouseholdStratagem utilizes a 4-Tier structured test architecture engineered to ensure complete opaque-box requirement coverage, strict mathematical correctness, edge-case resilience, and realistic end-to-end user workflows.

```
+-------------------------------------------------------------------------+
|                  TIER 4: REAL-WORLD APPLICATION SCENARIOS               |
|      Full multi-step user workflows (Onboarding -> Targeting ->         |
|      Stratagem Gestures -> Mission Timer & Audio -> Persistence)        |
+-------------------------------------------------------------------------+
                                    ^
+-------------------------------------------------------------------------+
|                   TIER 3: PAIRWISE COMBINATORIAL TESTING                |
|      Orthogonal 2-way interactions across state, difficulty, timing,    |
|      rooms, audio preferences, and network/persistence modes            |
+-------------------------------------------------------------------------+
                                    ^
+-------------------------------------------------------------------------+
|                TIER 2: BOUNDARY VALUE ANALYSIS (BVA) & CORNERS          |
|      Minimum/maximum limits, null handling, zero/negative durations,    |
|      gestures noise/ambiguity, tie-breakers, timeout clamping          |
+-------------------------------------------------------------------------+
                                    ^
+-------------------------------------------------------------------------+
|                 TIER 1: CATEGORY-PARTITION FEATURE TESTING              |
|      Equivalence partitioning across all 15 features in inventory.      |
|      Baseline functional contracts, nominal paths, explicit oracles    |
+-------------------------------------------------------------------------+
```

### 1.1 Tier 1: Category-Partition Feature Testing
- **Goal**: Validate nominal behavior, state transitions, and functional contracts for every feature in isolation and basic composition.
- **Methodology**: Equivalence partitioning derived directly from `PROJECT.md` interface contracts and `ORIGINAL_REQUEST.md` requirements.
- **Threshold**: **>= 5 test cases per feature** across all 15 features (Minimum **75 test cases**).

### 1.2 Tier 2: Boundary Value Analysis (BVA) & Corner Cases
- **Goal**: Stress input limits, mathematical asymptotic behavior, empty states, null defaults, invalid inputs, and timing boundaries.
- **Methodology**: Testing at $x_{\min}, x_{\min}^+, x_{\text{nominal}}, x_{\max}^-, x_{\max}$, null safety defaults, and exception/reset recovery.
- **Threshold**: **>= 5 boundary/corner test cases per feature** across all 15 features (Minimum **75 test cases**).

### 1.3 Tier 3: Pairwise Combinatorial Testing
- **Goal**: Uncover interaction defects between orthogonal features (e.g., room category $\times$ difficulty, urgency tie-breakers $\times$ completion state, swipe sequence lengths $\times$ gesture speed, audio state $\times$ mission lifecycle).
- **Methodology**: 2-way combinatorial test matrix ensuring all valid parameter interactions are exercised at least once.
- **Threshold**: **>= 15 distinct combinatorial scenarios** spanning all cross-cutting domain axes.

### 1.4 Tier 4: Real-World Application Scenarios
- **Goal**: Verify realistic user journeys from end to end using opaque-box simulation.
- **Methodology**: Multi-step stateful workflows replicating true user behavior:
  1. *First-Time Boot to First Mission Victory*: Clean state -> Auth anonymous -> 4-room Onboarding customization -> Firestore sync -> Top 3 targeting -> 5-swipe gesture unlock -> 10-minute timer with looping audio -> Long-press mission validation -> History log & level progress.
  2. *Returning Veteran Multi-Room Intervention*: Existing profile -> Daily reset -> Urgency recalculation with overdue tasks -> Multi-chore sequence -> Completion and credits accrual.
  3. *Aborted Intervention & Audio Cleanup*: Mission launch -> Audio loop start -> Premature user cancellation -> Audio stop verification -> Unmodified chore state -> Return to Home.
  4. *Exhaustive Room Rotation Cycle*: Rotating through all 4 rooms (Cuisine, Salle de bain, Salon, Chambre), validating room badges and sector floorplan highlights.
  5. *Offline / Fallback Resilience Journey*: Network disconnection simulation -> Local in-memory repository fallback -> Full mission cycle execution without data loss.
- **Threshold**: **>= 5 comprehensive multi-step application journeys**.

---

## 2. Feature Inventory Mapping (15 Features)

| Feature ID | Feature Name | Milestone | Scope Description | Primary Interface / Contract |
|---|---|---|---|---|
| **F01** | Test Suite Baseline & Health | M1 | Fix broken widget test baseline, ensure clean `flutter test` execution | `test/widget_test.dart`, `e2e_all_test.dart` |
| **F02** | Data Models & Serialization | M1 | `Chore`, `MissionLog`, `UserProfile`, `RoomCategory` serialization (`toMap`, `fromMap`, `copyWith`) | `Chore`, `MissionLog`, `UserProfile`, `RoomCategory` |
| **F03** | Targeting Engine & Urgency | M1 | Urgency formula $\text{Score} = (\text{overdueRatio} \times 100) + (\text{diff} \times 5)$ or $1000 + (\text{diff} \times 10)$, Top 3 sorting | `TargetingEngine.calculateUrgencyScore`, `getTopTargets` |
| **F04** | Stratagem Engine & Dynamic Swipes | M1 | Dynamic 5–8 move sequence generation, step-by-step validation, error buffer reset | `StratagemEngine.generateSequenceForDifficulty`, `isMoveCorrect` |
| **F05** | Audio Assets & AudioService | M2 | Looping MP3 playback, asset loading, play/stop lifecycle, resource disposal | `AudioService.playMissionLoop`, `stop`, `dispose` |
| **F06** | Firebase Dependencies & Service Layer | M2 | `AuthService` (anonymous/email) + `HouseholdRepository` (Firestore & in-memory fallback) | `AuthService`, `HouseholdRepository` |
| **F07** | Onboarding Room Catalogue | M3 | 4 mandatory rooms, 17 predefined chores, default periodicities (1–14 days) | Room catalogue definitions, room partitioning |
| **F08** | Onboarding Customizer & Persistence | M3 | Periodicity steppers, chore enable/disable, minimum room rules, initial save | Onboarding form state, repository commit |
| **F09** | Auth & Onboarding Routing | M3 | `AuthGate` branching: Unauthenticated -> Login/Anon -> Onboarded check -> Onboarding or Home | `AuthGate` routing state machine |
| **F10** | Mil-Tech Dark Tactical Theme | M4 | Black `#0B0E14`, Neon Amber `#FFA500`, Cyan `#00E5FF`, Yellow `#FFCC00`, Green `#00E676`, Red `#FF1744` | Design tokens, `MilTechTheme` |
| **F11** | Tactical Home Screen HUD | M4 | Agent credentials HUD (ID, level, credits, medals), Top 3 cards, urgent room highlight | `HomeScreen` presentation layer |
| **F12** | Dynamic Gesture Screen UI | M4 | 5–8 directional arrows, touch pan gestures, visual progress, error flash & reset | `StratagemScreen` gesture detection |
| **F13** | Tactical Mission Timer Screen | M4 | 10-minute (600s) neon countdown, radar spinner, objectives panel, audio loop, long-press validation | `TimerScreen` countdown and validation |
| **F14** | Vocabulary Purge | M4 | Strict cleaning/productivity lexicon; zero forbidden military terms ("squad", "automaton", "arsenal") | Lexicon scanner, UI string inspection |
| **F15** | E2E Integration & Hardening | M5 | Full lifecycle verification across all subsystems, hardening against edge conditions | Cross-feature E2E suites |

---

## 3. Detailed Test Specification by Tier

### 3.1 Tier 1: Category-Partition Feature Tests (F01–F15)

#### F01: Test Suite Baseline & Health
- `T1_F01_01`: Verify E2E master suite runs without unhandled exceptions.
- `T1_F01_02`: Verify test environment loads default mock services cleanly.
- `T1_F01_03`: Verify test runner handles asynchronous pump frames without timeouts.
- `T1_F01_04`: Verify test harness resets state between test cases to ensure isolation.
- `T1_F01_05`: Verify standard Flutter test bindings instantiate without headless platform crashes.

#### F02: Data Models & Serialization
- `T1_F02_01`: `Chore` model initialization with required fields (`id`, `name`, `difficulty`, `room`, `periodicityDays`).
- `T1_F02_02`: `Chore.toMap()` and `Chore.fromMap()` roundtrip serialization preserves all fields.
- `T1_F02_03`: `MissionLog` serialization roundtrip (`choreId`, `completedAt`, `success`, `durationSeconds`).
- `T1_F02_04`: `UserProfile` serialization roundtrip (`userId`, `agentName`, `level`, `credits`, `medals`, `onboarded`).
- `T1_F02_05`: `Chore.copyWith()` correctly updates specified fields while retaining others.

#### F03: Targeting Engine & Urgency
- `T1_F03_01`: Never-completed chore receives urgency score $= 1000.0 + (\text{difficulty} \times 10.0)$.
- `T1_F03_02`: Completed chore overdue by exactly 1 periodicity receives score $= 100.0 + (\text{difficulty} \times 5.0)$.
- `T1_F03_03`: Completed chore overdue by 2.0x periodicity receives score $= 200.0 + (\text{difficulty} \times 5.0)$.
- `T1_F03_04`: Completed chore with 0 elapsed time receives score $= 0.0 + (\text{difficulty} \times 5.0)$.
- `T1_F03_05`: `TargetingEngine.getTopTargets` returns exactly Top 3 highest scoring chores sorted descending.

#### F04: Stratagem Engine & Dynamic Swipes
- `T1_F04_01`: `generateSequenceForDifficulty(1)` generates a 5-directional sequence using valid directions.
- `T1_F04_02`: `generateSequenceForDifficulty(3)` generates a 6-directional sequence.
- `T1_F04_03`: `generateSequenceForDifficulty(5)` generates an 8-directional sequence.
- `T1_F04_04`: `isMoveCorrect` returns true when input matches `targetSequence[currentIndex]`.
- `T1_F04_05`: `isMoveCorrect` returns false when input differs from `targetSequence[currentIndex]`.

#### F05: Audio Assets & AudioService
- `T1_F05_01`: `AudioService.playMissionLoop` transitions service state to playing.
- `T1_F05_02`: `AudioService.playMissionLoop` registers the designated asset path.
- `T1_F05_03`: `AudioService.stop` stops playback and marks service as stopped.
- `T1_F05_04`: Calling `stop()` when already stopped does not throw an error.
- `T1_F05_05`: Calling `dispose()` releases audio resources safely.

#### F06: Firebase Dependencies & Service Layer
- `T1_F06_01`: `AuthService.signInAnonymously` yields valid user ID and emits auth state change.
- `T1_F06_02`: `AuthService.signOut` clears `currentUserId` and emits null.
- `T1_F06_03`: `HouseholdRepository.saveUserProfile` and `getUserProfile` persist and retrieve user profile.
- `T1_F06_04`: `HouseholdRepository.saveChores` and `getChores` persist and retrieve chore list.
- `T1_F06_05`: `HouseholdRepository.logMission` appends mission logs retrievable via `getMissionLogs`.

#### F07: Onboarding Room Catalogue
- `T1_F07_01`: Onboarding catalogue contains all 4 mandatory rooms (`Cuisine`, `Salle de bain`, `Salon`, `Chambre`).
- `T1_F07_02`: Onboarding catalogue contains exactly 17 predefined default chores.
- `T1_F07_03`: Kitchen (`Cuisine`) contains exactly 5 chores with valid default periodicities.
- `T1_F07_04`: Bathroom (`Salle de bain`) contains exactly 4 chores.
- `T1_F07_05`: Living room (`Salon`) and Bedroom (`Chambre`) each contain exactly 4 chores.

#### F08: Onboarding Customizer & Persistence
- `T1_F08_01`: Periodicity customization modifies chore periodicity within valid day bounds.
- `T1_F08_02`: Disabling a chore excludes it from active configuration.
- `T1_F08_03`: Minimum room rule validates that each of the 4 rooms has at least 1 enabled chore.
- `T1_F08_04`: Customizer commits all configured chores to repository.
- `T1_F08_05`: Customizer updates `UserProfile.onboarded` to `true` upon completion.

#### F09: Auth & Onboarding Routing
- `T1_F09_01`: Unauthenticated user is directed to Authentication prompt.
- `T1_F09_02`: Authenticated user with `onboarded == false` is routed to `OnboardingScreen`.
- `T1_F09_03`: Authenticated user with `onboarded == true` is routed to `HomeScreen`.
- `T1_F09_04`: Signing out routes active session back to Authentication screen.
- `T1_F09_05`: Completing onboarding triggers state update transitioning view to `HomeScreen`.

#### F10: Mil-Tech Dark Tactical Theme
- `T1_F10_01`: Background color matches `#0B0E14` (Deep space black).
- `T1_F10_02`: Accent colors match `#FFA500` (Amber), `#00E5FF` (Cyan), `#FFCC00` (Yellow).
- `T1_F10_03`: Alert colors match `#FF1744` (Crimson) and `#00E676` (Green).
- `T1_F10_04`: Tactical typography specifies uppercase display for headers and buttons.
- `T1_F10_05`: Beveled/chamfered frame border radius tokens are non-zero.

#### F11: Tactical Home Screen HUD
- `T1_F11_01`: Header HUD displays Agent ID and Level from profile.
- `T1_F11_02`: Header HUD displays Cleaning Credits and Medals counters.
- `T1_F11_03`: Tactical Sector Map highlights the room containing the highest urgency chore.
- `T1_F11_04`: Carousel displays Top 3 urgent tasks cards with urgency badges.
- `T1_F11_05`: Primary CTA button initiates mission for the topmost urgent task.

#### F12: Dynamic Gesture Screen UI
- `T1_F12_01`: Screen renders sequence of directional arrow icons matching chore code length (5–8).
- `T1_F12_02`: Valid swipe gesture advances step index and highlights validated arrow in cyan/amber.
- `T1_F12_03`: Invalid swipe gesture triggers error reset, resetting input index to 0.
- `T1_F12_04`: Completing the final swipe in sequence initiates navigation to `TimerScreen`.
- `T1_F12_05`: Screen displays chore name, room sector, and difficulty rating.

#### F13: Tactical Mission Timer Screen
- `T1_F13_01`: Countdown initializes at 10 minutes (600 seconds, formatted `10:00`).
- `T1_F13_02`: Timer ticks down synchronously on periodic tick events.
- `T1_F13_03`: Objectives panel lists primary objective matching current chore name.
- `T1_F13_04`: Long-press on validation button triggers mission completion.
- `T1_F13_05`: Tapping abandon button confirms cancellation and halts timer.

#### F14: Vocabulary Purge
- `T1_F14_01`: Lexicon scanner verifies absence of string "squad" (case-insensitive) in UI strings.
- `T1_F14_02`: Lexicon scanner verifies absence of string "escouade" in UI strings.
- `T1_F14_03`: Lexicon scanner verifies absence of string "automaton" and "arsenal" in UI strings.
- `T1_F14_04`: Navigation labels use domestic terms: `[QG/ACCUEIL]`, `[PLANNING]`, `[MATÉRIEL]`, `[BOUTIQUE]`.
- `T1_F14_05`: User role displayed as "Nettoyeur" / "Commandeur du Foyer" rather than military ranks.

#### F15: E2E Integration & Hardening
- `T1_F15_01`: Mission completion flow updates chore's `lastCompletedAt` timestamp to current time.
- `T1_F15_02`: Mission completion flow logs a successful entry in `MissionLog`.
- `T1_F15_03`: Completing top urgent chore drops its urgency score on subsequent targeting refresh.
- `T1_F15_04`: User profile credits increment upon mission completion.
- `T1_F15_05`: Mission cancellation leaves chore `lastCompletedAt` unchanged.

---

### 3.2 Tier 2: Boundary Value Analysis (BVA) & Corner Cases (F01–F15)

#### F01: Test Suite Baseline & Health
- `T2_F01_01`: Harness handles zero registered chores without null reference exceptions.
- `T2_F01_02`: Harness handles 1000 chores without memory exhaustion or stack overflow.
- `T2_F01_03`: Test runner recovers gracefully if mock repository throws simulated network error.
- `T2_F01_04`: Rapid repeated initialization and teardown cycles execute without resource leaks.
- `T2_F01_05`: Headless canvas rendering handles zero display dimensions without crash.

#### F02: Data Models & Serialization
- `T2_F02_01`: `Chore.fromMap` with missing optional fields (`swipeSequence`, `lastCompletedAt`) applies safe defaults.
- `T2_F02_02`: `Chore` handles extreme periodicity values (min 1 day, max 365 days).
- `T2_F02_03`: `UserProfile.fromMap` with zero credits and zero medals deserializes without error.
- `T2_F02_04`: `MissionLog` with 0-second duration serializes and deserializes correctly.
- `T2_F02_05`: Empty strings in chore name or room throw `ArgumentError` or clamp safely.

#### F03: Targeting Engine & Urgency
- `T2_F03_01`: Empty chore list passed to `getTopTargets` returns empty list without error.
- `T2_F03_02`: Chore list with fewer than 3 chores (e.g., exactly 1 or 2) returns all available chores without index out of bounds.
- `T2_F03_03`: Identical urgency scores resolve deterministically via secondary sort (difficulty descending, name ascending).
- `T2_F03_04`: Extreme overdue ratio (e.g., 1000 days overdue) computes without floating-point overflow.
- `T2_F03_05`: Future `lastCompletedAt` (clock drift / time skew) clamps `overdueRatio` to 0.0 rather than negative score.

#### F04: Stratagem Engine & Dynamic Swipes
- `T2_F04_01`: Difficulty <= 1 clamps sequence length to minimum 5 moves.
- `T2_F04_02`: Difficulty >= 5 clamps sequence length to maximum 8 moves.
- `T2_F04_03`: Sequence generation with seeded `Random` produces 100% deterministic sequence.
- `T2_F04_04`: Invalid direction string passed to `isMoveCorrect` returns `false` without throwing exception.
- `T2_F04_05`: Index out of bounds in `isMoveCorrect` (negative index or index >= length) returns `false` safely.

#### F05: Audio Assets & AudioService
- `T2_F05_01`: Playing non-existent audio asset path handles file not found gracefully without unhandled crash.
- `T2_F05_02`: Rapid consecutive calls to `playMissionLoop` without stopping pre-empts previous audio cleanly.
- `T2_F05_03`: Rapid interleaved `play` and `stop` calls maintain consistent boolean `isPlaying` flag.
- `T2_F05_04`: Calling `dispose()` while playback is active halts audio first.
- `T2_F05_05`: Empty string passed as asset path raises descriptive error or falls back to default track.

#### F06: Firebase Dependencies & Service Layer
- `T2_F06_01`: Repository retrieval of non-existent user profile returns `null` rather than throwing.
- `T2_F06_02`: Repository updates chore that does not exist in store handles gracefully (upsert or error).
- `T2_F06_03`: User with 0 mission logs returns empty list `[]` from `getMissionLogs`.
- `T2_F06_04`: Auth service sign-in with whitespace-only credentials rejects authentication.
- `T2_F06_05`: Offline repository persists data in-memory across calls within the session.

#### F07: Onboarding Room Catalogue
- `T2_F07_01`: Catalogue contains no duplicate chore IDs across all rooms.
- `T2_F07_02`: Every predefined chore has difficulty strictly in range $[1, 5]$.
- `T2_F07_03`: Every predefined chore has periodicity strictly in range $[1, 30]$ days.
- `T2_F07_04`: Room category string normalization (case-insensitive lookup) returns correct room.
- `T2_F07_05`: Unknown room lookup returns empty list without exception.

#### F08: Onboarding Customizer & Persistence
- `T2_F08_01`: Stepper decrement at lower bound (1 day) does not decrease periodicity below 1.
- `T2_F08_02`: Stepper increment at upper bound (e.g. 30 days) caps at upper limit.
- `T2_F08_03`: Attempting to disable ALL chores in a room blocks onboarding validation.
- `T2_F08_04`: Submitting customization with exactly 1 chore enabled per room succeeds.
- `T2_F08_05`: Submitting customization with all 17 chores enabled succeeds.

#### F09: Auth & Onboarding Routing
- `T2_F09_01`: Rapid auth state toggling does not cause multiple competing navigations.
- `T2_F09_02`: Null user ID in auth state stream maintains Unauthenticated screen.
- `T2_F09_03`: Profile with corrupt data (`onboarded` field null) defaults safely to `onboarded = false`.
- `T2_F09_04`: Routing evaluates correctly when network disconnect occurs during transition.
- `T2_F09_05`: Session resumption with cached valid profile routes immediately to `HomeScreen` without flashing Onboarding.

#### F10: Mil-Tech Dark Tactical Theme
- `T2_F10_01`: Contrast ratio between text primary (`#FFFFFF`) and background (`#0B0E14`) exceeds WCAG AAA (15:1).
- `T2_F10_02`: Contrast ratio between neon amber (`#FFA500`) and background exceeds WCAG AA (4.5:1).
- `T2_F10_03`: Contrast ratio between neon cyan (`#00E5FF`) and background exceeds WCAG AA.
- `T2_F10_04`: Hazard stripe gradient angles remain strictly bounded (45 degrees).
- `T2_F10_05`: Theme fallback on unsupported brightness modes remains dark tactical.

#### F11: Tactical Home Screen HUD
- `T2_F11_01`: User with 0 credits and 0 medals renders "0" without formatting error.
- `T2_F11_02`: User with 999,999 credits formats with thousand separators ("999,999").
- `T2_F11_03`: All chores completed today (urgency 0) displays "Toutes les zones sont propres !".
- `T2_F11_04`: When multiple rooms have equal maximum urgency, sector map highlights deterministically.
- `T2_F11_05`: Tapping secondary or tertiary task card selects it as the target for mission start.

#### F12: Dynamic Gesture Screen UI
- `T2_F12_01`: Ambiguous diagonal swipe ($\|dx\| \approx \|dy\|$, diff < 15%) is rejected as noise.
- `T2_F12_02`: Swipe with velocity below threshold (< 100 px/s) is ignored.
- `T2_F12_03`: Error on penultimate swipe (step $N-1$ of $N$) resets progress completely back to step 0.
- `T2_F12_04`: Rapid double swipes in quick succession do not skip steps or overflow sequence.
- `T2_F12_05`: Swiping after final move does not double-trigger navigation.

#### F13: Tactical Mission Timer Screen
- `T2_F13_01`: Timer reaching 00:00 does not decrement into negative numbers.
- `T2_F13_02`: Timer reaching 00:00 triggers mission expired state and halts audio.
- `T2_F13_03`: Short tap on validation button does NOT validate mission (requires long-press hold).
- `T2_F13_04`: Long press released prematurely (< 500ms threshold) cancels validation progress.
- `T2_F13_05`: Navigating back via system back button cleans up active timer periodic subscription.

#### F14: Vocabulary Purge
- `T2_F14_01`: Lexicon scanner flags substrings embedded inside compound words (e.g. "squad-leader").
- `T2_F14_02`: Lexicon scanner checks accented variants ("escouade", "escouades").
- `T2_F14_03`: Lexicon scanner inspects button tooltips and accessibility semantics labels.
- `T2_F14_04`: Lexicon scanner inspects mission objective text and parameters panel strings.
- `T2_F14_05`: Lexicon scanner inspects mock data and default chore names for military jargon.

#### F15: E2E Integration & Hardening
- `T2_F15_01`: Completing mission with 0 seconds elapsed (immediate completion) records duration 0 safely.
- `T2_F15_02`: Completing mission at exactly 600 seconds records full duration without timeout abort.
- `T2_F15_03`: Concurrently logging two missions for different chores updates history independently.
- `T2_F15_04`: App lifecycle pause/resume during mission timer preserves remaining time correctly.
- `T2_F15_05`: Audio stops cleanly when mission screen is popped unexpectedly.

---

### 3.3 Tier 3: Pairwise Combinatorial Scenarios

Pairwise test matrix covering orthogonal configuration axes:
- **Axis 1 (Room)**: Cuisine, Salle de bain, Salon, Chambre
- **Axis 2 (Difficulty / Sequence Length)**: Diff 1 (5 moves), Diff 3 (6 moves), Diff 4 (7 moves), Diff 5 (8 moves)
- **Axis 3 (Urgency Status)**: Never completed (null date), Moderately overdue (1.5x), Critically overdue (3.0x), Fresh (0.1x)
- **Axis 4 (Auth & Persistence)**: Anonymous auth, Email/Password auth, In-Memory mock, Firestore repository
- **Axis 5 (Audio Ambience)**: Track Alpha (`tactical_ambiance_1.mp3`), Track Bravo (`tactical_ambiance_2.mp3`), Muted

| Test ID | Room | Difficulty / Moves | Urgency Status | Auth / Persistence | Audio Track | Objective |
|---|---|---|---|---|---|---|
| `T3_PAIR_01` | Cuisine | Diff 1 (5 moves) | Never completed | Anonymous / In-Memory | Track Alpha | Baseline happy path for new user kitchen chore |
| `T3_PAIR_02` | Cuisine | Diff 3 (6 moves) | Overdue 1.5x | Email / Firestore | Track Bravo | Medium difficulty kitchen chore with custom audio |
| `T3_PAIR_03` | Cuisine | Diff 5 (8 moves) | Overdue 3.0x | Anonymous / In-Memory | Muted | Maximum difficulty 8-move kitchen deep clean without audio |
| `T3_PAIR_04` | SDB | Diff 1 (5 moves) | Fresh 0.1x | Email / In-Memory | Track Bravo | Low urgency bathroom task verification |
| `T3_PAIR_05` | SDB | Diff 4 (7 moves) | Overdue 3.0x | Anonymous / Firestore | Track Alpha | High difficulty 7-move bathroom limescale mission |
| `T3_PAIR_06` | SDB | Diff 3 (6 moves) | Never completed | Email / Firestore | Track Alpha | Uncompleted WC disinfection with audio loop |
| `T3_PAIR_07` | Salon | Diff 1 (5 moves) | Overdue 1.5x | Anonymous / Firestore | Muted | Living room coffee table quick tidy |
| `T3_PAIR_08` | Salon | Diff 2 (5 moves) | Fresh 0.1x | Email / In-Memory | Track Alpha | Vacuuming living room when recently done |
| `T3_PAIR_09` | Salon | Diff 4 (7 moves) | Overdue 3.0x | Anonymous / In-Memory | Track Bravo | 7-move window washing with critical priority |
| `T3_PAIR_10` | Chambre | Diff 1 (5 moves) | Never completed | Email / Firestore | Track Alpha | Bedroom bed making first execution |
| `T3_PAIR_11` | Chambre | Diff 3 (6 moves) | Overdue 1.5x | Anonymous / In-Memory | Track Bravo | Bed sheet replacement 6-move sequence |
| `T3_PAIR_12` | Chambre | Diff 2 (6 moves) | Fresh 0.1x | Email / Firestore | Muted | Under-bed vacuuming low urgency |
| `T3_PAIR_13` | Cuisine | Diff 4 (7 moves) | Fresh 0.1x | Anonymous / Firestore | Track Alpha | High difficulty chore recently completed |
| `T3_PAIR_14` | SDB | Diff 2 (5 moves) | Overdue 1.5x | Email / In-Memory | Track Bravo | Sink and mirror medium urgency |
| `T3_PAIR_15` | Chambre | Diff 4 (7 moves) | Overdue 3.0x | Anonymous / In-Memory | Track Alpha | Closet sorting max urgency 7-move sequence |

---

### 3.4 Tier 4: Real-World Application Scenarios

#### Scenario 1: `T4_APP_01_FIRST_TIME_ONBOARDING_TO_VICTORY`
1. Initialize clean state (user not logged in, no existing database).
2. Sign in anonymously via `AuthService.signInAnonymously()`.
3. `AuthGate` detects uninitialized user -> displays `OnboardingScreen`.
4. Inspect 4 rooms (`Cuisine`, `Salle de bain`, `Salon`, `Chambre`) and 17 chores.
5. Customize Kitchen "Sortir les poubelles" periodicity from 2 days to 1 day.
6. Submit Onboarding -> verifies user profile saved (`onboarded = true`) and 17 chores committed.
7. System transitions to `HomeScreen` -> Top 3 urgent tasks computed.
8. Verify Top 1 task is Kitchen, tap "DÉMARRER LA MISSION".
9. Transition to `StratagemScreen`: chore code has 5 directional moves.
10. Swipe correctly through 5 moves: `['UP', 'RIGHT', 'DOWN', 'DOWN', 'RIGHT']`.
11. Navigate to `TimerScreen`: 10-minute timer starts, audio loop commences.
12. Simulate timer running 60 seconds.
13. Long-press "VALIDER LA MISSION" button.
14. Verify audio stops, `MissionLog` recorded, chore `lastCompletedAt` updated, credits awarded.
15. Return to `HomeScreen` -> verify Top 3 targets refreshed with new urgency ranking.

#### Scenario 2: `T4_APP_02_RETURNING_USER_DAILY_TRIAGE`
1. Load existing user profile (Level 5, 2,400 credits, 8 medals, `onboarded = true`).
2. Load catalogue where 2 chores are 5 days overdue, 1 chore is 1 day overdue, others fresh.
3. Authenticate -> `AuthGate` routes directly to `HomeScreen`.
4. Validate Top 3 urgent tasks match the 3 overdue chores sorted by score.
5. Verify Tactical Sector Map highlights the room of the #1 overdue chore.
6. Launch mission for #1 chore -> complete 6-swipe stratagem.
7. Validate mission on `TimerScreen` -> verify chore drops out of Top 3.
8. Launch mission for new #1 chore -> complete 5-swipe stratagem.
9. Validate mission -> verify user level and credits increment again.

#### Scenario 3: `T4_APP_03_ABORTED_MISSION_AND_RETRY`
1. Start mission on #1 urgent task.
2. Enter `StratagemScreen` -> perform 2 correct swipes, then 1 wrong swipe.
3. Verify progress resets to 0 (error recovery).
4. Complete full swipe sequence correctly -> enter `TimerScreen`.
5. Verify audio loop starts playing.
6. User taps "ABANDONNER LA MISSION".
7. Verify confirmation dialog / prompt.
8. Confirm abort -> verify audio player immediately stops.
9. Return to `HomeScreen` -> verify chore `lastCompletedAt` is UNMODIFIED, task remains #1 urgent.
10. Relaunch mission -> successfully complete this time.

#### Scenario 4: `T4_APP_04_FOUR_ROOM_ROTATION_CAMPAIGN`
1. Complete a sequential cleaning tour across all 4 rooms in order:
   - Round 1: Cuisine chore (Diff 2, 5 moves).
   - Round 2: Salle de bain chore (Diff 3, 6 moves).
   - Round 3: Salon chore (Diff 2, 5 moves).
   - Round 4: Chambre chore (Diff 3, 6 moves).
2. After each round, verify:
   - Sector map updates active room indicator.
   - Corresponding room chore timestamp is saved.
   - 4 consecutive mission logs recorded in history.
   - Cumulative credits increase after each completed room.

#### Scenario 5: `T4_APP_05_OFFLINE_RESILIENCE_AND_RECOVERY`
1. Simulate offline state / disconnected Firestore.
2. Initialize app with in-memory repository fallback.
3. Perform anonymous sign-in, onboarding configuration, and mission execution.
4. Verify all operations function identically without crashing or throwing unhandled socket errors.
5. Verify data integrity within local session: chore status, logs, profile state.

---

## 4. Test Thresholds & Quantitative Summary

| Tier | Focus | Test Count Minimum | Actual Planned Tests | Status |
|---|---|---|---|---|
| **Tier 1** | Category-Partition Feature Tests (F01–F15) | $\ge 75$ ($15 \times 5$) | **75** | DEFINED |
| **Tier 2** | Boundary Value Analysis & Edge Cases (F01–F15) | $\ge 75$ ($15 \times 5$) | **75** | DEFINED |
| **Tier 3** | Pairwise Combinatorial Scenarios | $\ge 15$ | **15** | DEFINED |
| **Tier 4** | Real-World Application Workflows | $\ge 5$ | **5** | DEFINED |
| **Total** | **All Tiers Combined** | $\ge \mathbf{170}$ | **170** | **ACTIVE** |

---

## 5. Execution Strategy & Tooling

### 5.1 Test Execution Commands
```bash
# Run all E2E test suites together
flutter test test/e2e/e2e_all_test.dart

# Run individual tiers
flutter test test/e2e/tier1_feature_test.dart
flutter test test/e2e/tier2_boundary_test.dart
flutter test test/e2e/tier3_combination_test.dart
flutter test test/e2e/tier4_application_test.dart
```

### 5.2 Test Isolation & Opaque Interface Design
All E2E tests interact exclusively via opaque interfaces:
- `E2EAppHarness`: Encapsulates application state, in-memory repositories, simulated time, gesture dispatchers, and audio lifecycle listeners.
- No direct coupling to unstable external network dependencies (live Firestore, live Google Auth).
- Standard Flutter testing primitives (`test`, `testWidgets`, `expect`, `find`, `WidgetTester`) ensuring 100% deterministic CI execution.
