# BRIEFING — 2026-10-04T13:43:00Z

## Mission
Explore and design the Firebase Auth and Firestore architecture for Milestone M2 (AuthService and HouseholdRepository interfaces, implementations, and offline/mock counterparts).

## 🔒 My Identity
- Archetype: Teamwork explorer
- Roles: Read-only investigation, architecture design, synthesis
- Working directory: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m2_1
- Original parent: 275b51ec-7572-45ca-88b1-d6944bed4ad2
- Milestone: M2 - Service Architecture & Audio System

## 🔒 Key Constraints
- Read-only investigation — do NOT implement directly into source files (app/lib/...)
- Produce complete, ready-to-use proposed Dart code files in working directory
- Deliver handoff report with 5 components (Observation, Logic Chain, Caveats, Conclusion, Verification Method)

## Current Parent
- Conversation ID: 275b51ec-7572-45ca-88b1-d6944bed4ad2
- Updated: not yet

## Investigation State
- **Explored paths**:
  - `PROJECT.md` & `ORIGINAL_REQUEST.md`: Milestone M2 requirements and interfaces.
  - `app/lib/models/` (`chore.dart`, `mission_log.dart`, `user_profile.dart`, `room_category.dart`): Data structures, Firestore serialization (`fromMap`/`toMap`), and 17 default chores catalogue in `RoomCategory.defaultChores`.
  - `app/test/e2e/test_harness.dart` & `tier1` to `tier4` tests: Existing contracts, error boundaries (e.g. whitespace credential handling), and persistence flows.
  - `.agents/teamwork/explorer_m2_2/context.md` & `explorer_m2_3/context.md`: Boundaries with sibling agents (M2-2 handles AudioService, M2-3 handles pubspec dependencies & services unit tests).
- **Key findings**:
  - `AuthService` interface: `authStateChanges`, `currentUserId`, `signInAnonymously()`, `signInWithEmailPassword(email, pwd)`, `signOut()`.
  - `FirebaseAuthService`: Backed by `FirebaseAuth.instance`, supports optional injected `FirebaseAuth` for tests, handles UID extraction and whitespace rejection.
  - `FakeAuthService`: Backed by broadcast `StreamController<String?>`, supports offline/demo mode, rejects whitespace credentials, provides test simulation helpers.
  - `HouseholdRepository` interface: `getUserProfile`, `saveUserProfile`, `getChores`, `saveChores`, `updateChore`, `logMission`, `getMissionLogs`.
  - `FirestoreHouseholdRepository`: Structured under `users/{uid}` (profile document), `users/{uid}/tasks/{choreId}` (chores collection), and `users/{uid}/history/{logId}` (mission history collection). Chunks batch writes to 400 items. Supports injected `FirebaseFirestore` (e.g. `FakeFirebaseFirestore`).
  - `InMemoryHouseholdRepository`: Seeded with 17 default chores from `RoomCategory.defaultChores`, provides defensive copying, `autoSeed` option, and manual seeding.
- **Unexplored areas**: None within the M2-1 problem boundary.

## Key Decisions Made
- Provided both unified all-in-one files (`proposed_auth_service.dart`, `proposed_household_repository.dart`) and modular breakdown files (`proposed_firebase_auth_service.dart`, `proposed_fake_auth_service.dart`, etc.) to give the implementer full flexibility.
- Implemented and passed all 16 self-verification tests in `proposed_services_test.dart` with 100% pass rate.
- Preserved existing project baseline (all 412 test cases pass cleanly).

## Artifact Index
- `DISPATCH.md` — Incoming task dispatches
- `BRIEFING.md` — Persistent working memory and state
- `progress.md` — Liveness heartbeat
- `proposed_auth_service.dart` — All-in-one AuthService file
- `proposed_household_repository.dart` — All-in-one HouseholdRepository file
- `proposed_firebase_auth_service.dart` — Modular FirebaseAuthService
- `proposed_fake_auth_service.dart` — Modular FakeAuthService
- `proposed_firestore_household_repository.dart` — Modular FirestoreHouseholdRepository
- `proposed_in_memory_household_repository.dart` — Modular InMemoryHouseholdRepository
- `proposed_modular_auth_service.dart` — Barrel AuthService
- `proposed_modular_household_repository.dart` — Barrel HouseholdRepository
- `proposed_services_test.dart` — Verification test suite (16 tests, all green)
- `handoff.md` — Final 5-component handoff report
