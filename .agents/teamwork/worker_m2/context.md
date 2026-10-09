# Worker M2 Context: Implement Services Architecture & Audio Subsystem

- Project root: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper
- Original request: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\ORIGINAL_REQUEST.md
- Scope document: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\PROJECT.md
- Working directory: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\worker_m2

Scope:
Milestone M2:
1. Update `app/pubspec.yaml` to include:
   - Dependencies: `firebase_core`, `firebase_auth`, `cloud_firestore`, `audioplayers`
   - Dev dependencies: `fake_cloud_firestore`
   - Assets: `assets/audio/`
   Run `flutter pub get`.
2. Generate local binary MP3 assets in `app/assets/audio/`:
   - Run `dart .agents/teamwork/explorer_m2_2/generate_audio_assets.dart app/assets/audio`
   - Verify `tactical_ambiance_1.mp3` and `tactical_ambiance_2.mp3` exist and have valid MP3 headers.
3. Implement `app/lib/services/`:
   - `auth_service.dart`: `AuthService`, `FirebaseAuthService`, `FakeAuthService`.
   - `household_repository.dart`: `HouseholdRepository`, `FirestoreHouseholdRepository`, `InMemoryHouseholdRepository`.
   - `audio_service.dart`: `AudioService`, `RealAudioService`, `MockAudioService`.
4. Implement `app/test/unit/services_test.dart` from `explorer_m2_3/proposed_services_test.dart`.
5. Run verification commands:
   - `flutter test test/unit/`
   - `flutter analyze lib/services test/unit/services_test.dart`
   - `flutter test`

Exclusive file ownership:
- `app/pubspec.yaml`
- `app/assets/audio/**`
- `app/lib/services/**`
- `app/test/unit/services_test.dart`
DO NOT touch `app/lib/models/**`, `app/lib/engine/**`, `app/test/e2e/**`.
