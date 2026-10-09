## 2026-10-04T13:19:04Z
You are Worker M1 (worker_m1).
Your working directory is: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\worker_m1
The project root is: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper
Read ORIGINAL_REQUEST.md at: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\ORIGINAL_REQUEST.md
Read PROJECT.md at: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\PROJECT.md
Read your context at: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\worker_m1\context.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Exclusive file ownership:
- `app/lib/models/**`
- `app/lib/models.dart`
- `app/lib/engine/**`
- `app/lib/targeting_engine.dart`
- `app/test/unit/**`
- `app/test/widget_test.dart`
Do NOT edit any other files.

Mission:
Implement Milestone M1:
1. Copy/implement the production model files from explorer_m1_1:
   - `app/lib/models/chore.dart`
   - `app/lib/models/mission_log.dart`
   - `app/lib/models/user_profile.dart`
   - `app/lib/models/room_category.dart`
   - `app/lib/models.dart` (barrel export maintaining backwards compatibility)
2. Copy/implement the engine files from explorer_m1_2:
   - `app/lib/engine/targeting_engine.dart`
   - `app/lib/engine/stratagem_engine.dart`
   - `app/lib/targeting_engine.dart` (barrel export)
3. Fix `app/test/widget_test.dart` per explorer_m1_3 so it passes cleanly without missing class errors.
4. Implement the unit test suites from explorer_m1_3:
   - `app/test/unit/models_test.dart`
   - `app/test/unit/targeting_engine_test.dart`
   - `app/test/unit/stratagem_engine_test.dart`
5. Run verification commands in `app/`:
   - `flutter test test/unit/`
   - `flutter test test/widget_test.dart`
   - `flutter analyze`
6. Write your handoff report to `c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\worker_m1\handoff.md` and send a message when done with path and full test results.
