# Explorer M2-2 Context: Audio Assets & AudioService Design

- Project root: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper
- Original request: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\ORIGINAL_REQUEST.md
- Scope document: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\PROJECT.md
- Working directory: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m2_2

Milestone M2 Focus:
1. Formulate exact code for `AudioService` (`app/lib/services/audio_service.dart`):
   - Methods: `playMissionLoop(String assetPath)`, `stop()`, `dispose()`, getters for `isPlaying`, `currentTrack`.
   - Provide `RealAudioService` (using `audioplayers: ^6.1.0` with `ReleaseMode.loop`) and `MockAudioService` (for headless tests and testing without native audio channel).
2. Specify local audio files to create in `app/assets/audio/`:
   - `tactical_ambiance_1.mp3`, `tactical_ambiance_2.mp3`.
   - Provide script / generator to generate valid minimal MP3 audio binary assets if not present.
3. Deliver proposed files and handoff report in your working directory. Do NOT modify source files directly.
