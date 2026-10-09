# Explorer M1-2 Context: Targeting & Stratagem Engine Implementation & Algorithms

- Project root: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper
- Original request: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\ORIGINAL_REQUEST.md
- Scope document: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\PROJECT.md
- Working directory: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m1_2

Milestone M1 Focus:
1. Examine `app/lib/targeting_engine.dart` and `app/lib/stratagem_screen.dart`.
2. Formulate the exact implementation of `TargetingEngine`:
   - `calculateUrgencyScore(Chore, {DateTime? now})`
   - `getTopTargets(List<Chore>, {int count = 3, DateTime? now})`
   - Handling ties, null completion dates, empty lists.
3. Formulate the exact implementation of `StratagemEngine`:
   - `generateSequenceForDifficulty(int difficulty, {Random? random})` returning 5 to 8 moves (`UP`, `DOWN`, `LEFT`, `RIGHT`).
   - `isMoveCorrect(List<String> targetSequence, int currentIndex, String move)`
4. Provide precise implementation and unit test plans for Worker.
