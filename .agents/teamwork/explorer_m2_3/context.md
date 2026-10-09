# Explorer M2-3 Context: pubspec.yaml Dependencies & Services Unit Tests

- Project root: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper
- Original request: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\ORIGINAL_REQUEST.md
- Scope document: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\PROJECT.md
- Working directory: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m2_3

Milestone M2 Focus:
1. Specify changes to `app/pubspec.yaml`:
   - Dependencies: `firebase_core: ^4.15.0`, `firebase_auth: ^6.7.0`, `cloud_firestore: ^6.10.0`, `audioplayers: ^6.8.1`.
   - Assets declaration:
     ```yaml
     flutter:
       uses-material-design: true
       assets:
         - assets/audio/
     ```
   - Dev dependencies: `fake_cloud_firestore: ^4.3.0`.
2. Design unit test suite `app/test/unit/services_test.dart`:
   - Testing `AuthService` (anonymous, email, authStateChanges).
   - Testing `HouseholdRepository` (profile CRUD, chores saving & updating, mission history logging).
   - Testing `AudioService` (start loop, stop, track switching).
3. Deliver proposed test files and handoff report in your working directory. Do NOT modify source files directly.
