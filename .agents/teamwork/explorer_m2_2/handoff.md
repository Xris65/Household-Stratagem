# Milestone M2 Handoff Report: Audio System & Local Assets Design

**Agent**: `explorer_m2_2`  
**Working Directory**: `c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m2_2`  
**Milestone**: M2 (Service Architecture & Audio System)  
**Status**: Complete (Hard Handoff)

---

## 1. Observation

### Codebase and Specification State
1. **Interface Contract in `PROJECT.md`** (lines 100-106):
   ```dart
   abstract class AudioService {
     Future<void> playMissionLoop(String assetPath);
     Future<void> stop();
     void dispose();
   }
   ```
2. **Feature Inventory in `PROJECT.md`** (lines 34, Feature 5):
   - "Audio Assets & AudioService: Bundled MP3 assets, AudioService with looping playback and lifecycle management | M2 | R4"
   - Expected code layout (lines 113-116):
     ```
     app/
     ├── assets/
     │   └── audio/
     │       ├── tactical_ambiance_1.mp3
     │       └── tactical_ambiance_2.mp3
     ```
     and `app/lib/services/audio_service.dart` (line 133).
3. **User Request R4 & Acceptance Criteria in `ORIGINAL_REQUEST.md`** (lines 21-23, 38-40):
   - "R4. Pression Audio Personnalisable: Le Timer de 10 minutes (ou la mission) doit déclencher la lecture de fichiers audio locaux (MP3). L'utilisateur peut choisir sa piste sonore (ambiance tactique) pour s'accompagner."
   - Acceptance Criteria: "Un package audio joue une piste sonore en boucle pendant la mission, et s'arrête à la fin."
4. **Existing E2E Test Harness Reference in `app/test/e2e/test_harness.dart`** (lines 436-478):
   - `E2EAudioService` interface specifies:
     - `bool get isPlaying;`
     - `String? get currentTrack;`
     - `Future<void> playMissionLoop(String assetPath);`
     - `Future<void> stop();`
     - `void dispose();`
   - `E2EUserProfile` sets `preferredAudioTrack: 'tactical_ambiance_1.mp3'` (line 173).
   - `E2EAppHarness.submitSwipe` triggers `audioService.playMissionLoop(...)` upon sequence completion (lines 782-786).
5. **Flutter & Pubspec Status in `app/pubspec.yaml`**:
   - Flutter version: 3.47.5 (Dart 3.13.4).
   - Currently, `audioplayers` is not yet listed in `dependencies`, and `assets: - assets/audio/` is not yet declared. Milestones M2-3 explorer context specifies `audioplayers: ^6.8.1`.
   - Current test baseline: 412/412 tests pass cleanly (`flutter test`).

---

## 2. Logic Chain

1. **Unified Interface Harmonization**:
   - *Observation Reference*: `PROJECT.md:100` vs `test_harness.dart:436` vs `context.md:10`.
   - *Reasoning*: The `AudioService` abstract class must expose `isPlaying` and `currentTrack` getters in addition to `playMissionLoop`, `stop`, and `dispose`. This satisfies both the architectural spec in `PROJECT.md` and the existing assertions in the test suite.
2. **Defensive Path Normalization for `audioplayers`**:
   - *Observation Reference*: `audioplayers` package documentation and `test_harness.dart:173`.
   - *Reasoning*: In `audioplayers`, `AssetSource(path)` prepends the default cache prefix `'assets/'`. Callers in the codebase supply track names in differing formats:
     - Profile model supplies `"tactical_ambiance_1.mp3"`.
     - File tree spec in `PROJECT.md` describes `"assets/audio/tactical_ambiance_1.mp3"`.
     - Some UI screens might pass `"audio/tactical_ambiance_1.mp3"`.
     If `"assets/audio/..."` were passed directly to `AssetSource`, `audioplayers` would search for `"assets/assets/audio/..."` and fail.
     Hence, `RealAudioService.normalizeAssetPath(path)` is implemented to:
     - Strip leading `/` and `assets/`.
     - Ensure filename without directory separator is mapped to `audio/<filename>`.
     - Output is consistently `audio/<filename>` which maps cleanly to `assets/audio/<filename>`.
3. **Decoupling MockAudioService for Test Automation**:
   - *Observation Reference*: `test_harness.dart:444` and `flutter test` headless CI constraints.
   - *Reasoning*: Running widget and unit tests with `RealAudioService` would trigger `MissingPluginException` in headless flutter test environments lacking platform channels. Providing `MockAudioService` alongside `RealAudioService` ensures instant zero-dependency testing, while exposing test-inspection fields (`playCount`, `stopCount`, `playedTracks`, `reset()`).
4. **Valid Binary MP3 Generation vs Empty Files**:
   - *Observation Reference*: `ORIGINAL_REQUEST.md:21` and mobile/desktop platform audio decoders.
   - *Reasoning*: Empty (0-byte) or dummy text files cause platform audio decoders (Android MediaPlayer/ExoPlayer, iOS AVPlayer, Windows Media Foundation) to throw native decoding failures. Valid MPEG-1 Layer 3 frames (128 kbps, 44.1 kHz, mono: 417 bytes with syncword `0xFF 0xFB 0x90 0xC4`) with ID3v2.3 tags are synthesized to ensure 100% compliant, seamless audio looping.
5. **Self-Contained Artifacts**:
   - Both a Dart generator (`generate_audio_assets.dart`) and a PowerShell generator (`generate_audio_assets.ps1`) are provided so the implementer can generate the required binary files on any machine without installing ffmpeg or external tools.

---

## 3. Caveats

1. **Pubspec Dependency Requirement**:
   `app/lib/services/audio_service.dart` relies on `package:audioplayers/audioplayers.dart`. The implementer must add `audioplayers: ^6.8.1` (or `^6.1.0`) to `app/pubspec.yaml` and run `flutter pub get` before placing the file into `app/lib/services/`.
2. **Flutter Asset Registration**:
   The implementer must register `- assets/audio/` under `flutter: assets:` in `app/pubspec.yaml` for Flutter to bundle the MP3 files into the application asset bundle.
3. **Headless Unit vs Device Execution**:
   In widget and unit tests, `MockAudioService` should always be injected into `TimerScreen` and application controllers. `RealAudioService` is intended for actual device / desktop application runs.

---

## 4. Conclusion

The complete audio subsystem for Milestone M2 is fully designed, tested, and ready for deployment:

1. **Proposed Source Code**:
   - `.agents/teamwork/explorer_m2_2/proposed_audio_service.dart`:
     - `AudioService` (abstract class)
     - `RealAudioService` (audioplayers integration, `ReleaseMode.loop`, path normalization, lifecycle safety)
     - `MockAudioService` (in-memory mock with counters and reset helper)
     - Destination path for implementer: `app/lib/services/audio_service.dart`
2. **Audio Asset Specifications**:
   - Target files:
     - `app/assets/audio/tactical_ambiance_1.mp3` (Title: "Tactical Ambiance 1: Dark Synth Pulse", 128 kbps, 44.1 kHz, ID3v2.3)
     - `app/assets/audio/tactical_ambiance_2.mp3` (Title: "Tactical Ambiance 2: Heavy Cyber Bass Drone", 128 kbps, 44.1 kHz, ID3v2.3)
3. **Deterministic Asset Generators**:
   - `.agents/teamwork/explorer_m2_2/generate_audio_assets.dart`
   - `.agents/teamwork/explorer_m2_2/generate_audio_assets.ps1`
   - Pre-generated verified sample files are ready at `.agents/teamwork/explorer_m2_2/sample_assets/`.
4. **Unit Test Suite**:
   - `.agents/teamwork/explorer_m2_2/proposed_audio_service_test.dart` (7 tests, 100% pass rate).

---

## 5. Verification Method

To independently verify all findings and artifacts:

1. **Verify Audio Tests**:
   Run the proposed test suite using Dart:
   ```powershell
   dart run c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m2_2\proposed_audio_service_test.dart
   ```
   *Expected Output*: `=== ALL 7 AUDIO TESTS PASSED SUCCESSFULLY ===`

2. **Verify MP3 Binary Generation**:
   Run the Dart asset generator:
   ```powershell
   dart run c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m2_2\generate_audio_assets.dart c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m2_2\sample_assets
   ```
   Inspect generated MP3 file headers:
   - Header magic: `ID3` (0x49 0x44 0x33)
   - MP3 Syncword: `0xFF 0xFB` at the end of the ID3 tag block.
   - File size: ~62.7 KB (150 valid MPEG-1 Layer 3 frames).

3. **Verify Baseline Project Health**:
   ```powershell
   cd c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\app
   flutter test
   ```
   *Expected Output*: All 412 existing tests pass cleanly without errors.

4. **Invalidation Conditions**:
   - If `AudioService` signatures change to remove `isPlaying` or `currentTrack`, failing `test_harness.dart`.
   - If `audioplayers` 6.x breaking API changes alter `setReleaseMode` or `AssetSource`.
