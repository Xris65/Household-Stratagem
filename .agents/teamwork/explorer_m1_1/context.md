# Explorer M1-1 Context: Domain Models & Firestore Serialization Design

- Project root: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper
- Original request: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\ORIGINAL_REQUEST.md
- Scope document: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\PROJECT.md
- Working directory: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\explorer_m1_1

Milestone M1 Focus:
1. Examine existing `app/lib/models.dart`.
2. Detail the exact design of `Chore`, `MissionLog`, `UserProfile`, and `RoomCategory` models.
3. Define Firestore serialization (`toMap()`, `fromMap()`, `copyWith()`).
4. Ensure backward compatibility with existing `models.dart` imports so no existing code breaks.
5. Provide precise implementation instructions for Worker.
