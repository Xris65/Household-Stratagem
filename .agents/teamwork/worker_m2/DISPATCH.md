## 2026-10-04T13:48:47Z
You are Worker M2 (worker_m2).
Your working directory is: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\worker_m2
The project root is: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper
Read ORIGINAL_REQUEST.md at: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\ORIGINAL_REQUEST.md
Read PROJECT.md at: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\PROJECT.md
Read your context at: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\worker_m2\context.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Exclusive file ownership:
- `app/pubspec.yaml`
- `app/assets/audio/**`
- `app/lib/services/**`
- `app/test/unit/services_test.dart`
Do NOT edit other files.

Mission:
Implement Milestone M2:
1. Update `app/pubspec.yaml` using `explorer_m2_3/proposed_pubspec.yaml` (or run `flutter pub add firebase_core firebase_auth cloud_firestore audioplayers && flutter pub add --dev fake_cloud_firestore`) and declare `assets: - assets/audio/`. Run `flutter pub get`.
2. Generate local binary MP3 assets in `app/assets/audio/`:
   Run `dart .agents/teamwork/explorer_m2_2/generate_audio_assets.dart app/assets/audio`
   Verify that `tactical_ambiance_1.mp3` and `tactical_ambiance_2.mp3` exist.
3. Implement services in `app/lib/services/`:
   - `auth_service.dart`: `AuthService`, `FirebaseAuthService`, `FakeAuthService` (from `explorer_m2_1/proposed_auth_service.dart`).
   - `household_repository.dart`: `HouseholdRepository`, `FirestoreHouseholdRepository`, `InMemoryHouseholdRepository` (from `explorer_m2_1/proposed_household_repository.dart`).
   - `audio_service.dart`: `AudioService`, `RealAudioService`, `MockAudioService` (from `explorer_m2_2/proposed_audio_service.dart`).
4. Implement `app/test/unit/services_test.dart` using `explorer_m2_3/proposed_services_test.dart`.
5. Run verification commands in `app/`:
   - `flutter test test/unit/`
   - `flutter analyze lib/services test/unit/services_test.dart`
   - `flutter test`
6. Write your handoff report to `c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\worker_m2\handoff.md` and send a message when done with path and full test results.
