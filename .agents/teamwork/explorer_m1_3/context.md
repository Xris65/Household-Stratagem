# Explorer M1-3 Context: Test Infrastructure & Test Suite Baseline Fix

- Project root: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper
- Original request: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\ORIGINAL_REQUEST.md
- Scope document: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\PROJECT.md
- Working directory: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m1_3

Milestone M1 Focus:
1. Fix broken `app/test/widget_test.dart` where `MyApp` is missing (update it to test `HouseholdStratagemApp` or replace with unit/widget tests).
2. Plan directory layout under `app/test/`: `test/unit/` (models, targeting_engine, stratagem_engine), `test/widget/`.
3. Design complete unit test coverage for M1 features:
   - Urgency sorting order and null-date priority.
   - Sequence generation bounds (min 5, max 8 moves).
   - Validation correctness and reset behavior.
   - Model serialization/deserialization fidelity.
4. Provide precise test commands and verification plan for Worker.
