# Explorer M2-1 Context: Firebase Services & Offline Repository Design

- Project root: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper
- Original request: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\ORIGINAL_REQUEST.md
- Scope document: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\PROJECT.md
- Working directory: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m2_1

Milestone M2 Focus:
1. Formulate exact code for `AuthService` (`app/lib/services/auth_service.dart`):
   - Anonymous sign-in, email/password sign-in, sign out, `authStateChanges`, `currentUserId`.
   - Provide `FirebaseAuthService` and `FakeAuthService` (for offline demo mode & tests).
2. Formulate exact code for `HouseholdRepository` (`app/lib/services/household_repository.dart`):
   - Methods: `getUserProfile`, `saveUserProfile`, `getChores`, `saveChores`, `updateChore`, `logMission`, `getMissionLogs`.
   - Provide `FirestoreHouseholdRepository` (with Firestore collections `users`, `tasks`, `history`) and `InMemoryHouseholdRepository` (injected with seed default chores).
3. Deliver proposed files and handoff report in your working directory. Do NOT modify source files directly.
