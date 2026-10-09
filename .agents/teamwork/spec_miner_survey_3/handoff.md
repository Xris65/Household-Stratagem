# Handoff Report — Spec Miner Survey 3: UI/UX & Requirements Mining

**Author**: spec_miner_survey_3  
**Working Directory**: `c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\spec_miner_survey_3`  
**Target File**: `c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\spec_miner_survey_3\handoff.md`  
**Recipient**: orchestrator_lead (`275b51ec-7572-45ca-88b1-d6944bed4ad2`)  

---

## 1. Observation

### 1.1 Specification Files Located
1. **`ORIGINAL_REQUEST.md`** (located at `c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\ORIGINAL_REQUEST.md` and project root):
   - **R1. Base de données et Authentification (Firebase)**: Firebase Auth (email/mdp ou anonyme), Firestore pour profils, catalogue des tâches et historique.
   - **R2. Onboarding Initial et Configuration**: Flux affiché à la première connexion, tâches groupées par 4 pièces (`Cuisine`, `Salle de bain`, `Salon`, `Chambre`), périodicités par défaut ajustables, paramètres globaux, persistance Firebase.
   - **R3. Moteur de Cibles et Stratagèmes Complexes**: Affichage du Top 3 des tâches les plus urgentes sur l'écran principal, séquences de swipes de longueur dynamique (5 à 8 mouvements au lieu de 4 fixes).
   - **R4. Pression Audio Personnalisable**: Minuteur de 10 minutes avec lecture audio MP3 locale en boucle, choix de la piste sonore.
   - **R5. Refonte Visuelle (UI)**: Reconstruction visuelle calquée sur les maquettes de `ui_mockups.md`. Purge stricte du vocabulaire militaire ("escouades", "squads") au profit d'un vocabulaire purement orienté tâches ménagères et entretien.

2. **`ui_mockups.md`** (located at `c:\Users\krisd\.gemini\antigravity\brain\8594895e-dac0-45f7-be00-1e9594ff827f\ui_mockups.md` and `brain\3913ce5b-8afe-42cc-a5b9-7680c74d602f\ui_mockups.md`):
   - Quoting verbatim:
     > *"Voici les maquettes d'interface utilisateur pour la direction artistique de l'application, inspirées de l'esthétique Mil-Tech et sombre de Helldivers 2."*
     > *"## Écran Principal (Home Screen): Cet écran présente une interface tactique militaire avec des textes néons et des flèches directionnelles."*
     > *"## Écran de Mission (Timer Screen): Cet écran met en avant le chronomètre de mission avec un style néon imposant et une atmosphère sombre."*

3. **Mockup Images Directly Inspected via `view_file`**:
   - `C:\Users\krisd\.gemini\antigravity\brain\8594895e-dac0-45f7-be00-1e9594ff827f\home_screen_mockup_1791116804128.jpg` (Resolution: 1024x1792 high-detail mobile HUD).
   - `C:\Users\krisd\.gemini\antigravity\brain\8594895e-dac0-45f7-be00-1e9594ff827f\timer_screen_mockup_1791116815059.jpg` (Resolution: 1024x1792 high-detail mobile HUD).

### 1.2 Existing Codebase State
- **`app/pubspec.yaml`**: Flutter 3.x, currently only includes `cupertino_icons: ^1.0.8` and `flutter_lints: ^6.0.0`. Missing `firebase_core`, `firebase_auth`, `cloud_firestore`, and audio player package (`audioplayers`).
- **`app/lib/models.dart`**: Contains minimal `Chore(id, name, difficulty)` and `MissionLog(choreId, completedAt, success)`. Lacks `room`, `periodicityDays`, `lastCompletedAt`, `swipeSequence`.
- **`app/lib/targeting_engine.dart`**: Hardcoded 3 items (`Nettoyer la cuisine`, `Sortir les poubelles`, `Passer l'aspirateur`), no calculation of urgency, no date comparison.
- **`app/lib/stratagem_screen.dart`**: Hardcoded 4 swipes length check (`if (_sequence.length >= 4)`), ignores required target sequence matching.
- **`app/lib/timer_screen.dart`**: Basic 600s timer with standard `Scaffold`, missing audio integration, mission parameter panels, and styling from mockup.
- **`app/test/widget_test.dart`**: Broken template test failing with `Error: Couldn't find constructor 'MyApp'`.

---

## 2. Logic Chain

1. **Aesthetic & Visual Identity (R5)**:
   - The mockups demonstrate a high-contrast **Mil-Tech Dark Tactical HUD** aesthetic inspired by Helldivers 2.
   - However, `ORIGINAL_REQUEST.md` mandates that all military-combat terminology (such as "escouade", "squad", "automaton invasion", "arsenal") must be purged in favor of a domestic cleaning/productivity theme while preserving the intense, humorous Mil-Tech visual styling (neon colors, chamfered frames, hazard stripes, tactical scanlines).
2. **Screen Architecture**:
   - The application requires 4 core screen states:
     - **Onboarding / Setup Screen** (`OnboardingScreen`): Initial room-based task configuration (R2).
     - **Home / Command Screen** (`HomeScreen` / `StratagemHomeScreen`): Displays Top 3 urgent tasks on tactical map and mission tiles, user level, and navigation (R3, R5).
     - **Stratagem Unlock Screen** (`StratagemScreen`): Variable 5 to 8 directional swipe sequence input (R3).
     - **Mission Timer Screen** (`TimerScreen`): 10-minute tactical countdown with audio track playback in loop, objectives breakdown, and validation action (R4, R5).
3. **Urgency Engine (R3)**:
   - To identify the Top 3 tasks dynamically, the engine must compute an urgency metric:
     $$\text{UrgencyRatio} = \frac{\text{Now} - \text{lastCompletedAt}}{\text{periodicityDays}}$$
     $$\text{PriorityScore} = \text{UrgencyRatio} \times (1.0 + \text{difficulty} \times 0.2)$$
   - When a task is overdue ($\text{UrgencyRatio} > 1.0$) or has never been completed, its urgency is maximized.
4. **Data Persistence & Testing Isolation (R1, R2)**:
   - Data must be structured to persist cleanly to Firestore (`users/{uid}/tasks/{taskId}`).
   - For automated CI/unit tests (`flutter test`), dependencies on Firebase should be abstractable through an injectable repository/service interface to enable deterministic in-memory tests without live Firebase credentials.

---

## 3. Features Discovered

| # | Category | Feature | Description | Inputs | Outputs | Error Behavior | Discovered Via |
|---|----------|---------|-------------|--------|---------|----------------|----------------|
| 1 | UI / Theming | Mil-Tech Dark Tactical Theme | Deep space black background (`#0B0E14`), glowing neon accents (Amber `#FFA500`, Cyan `#00E5FF`, Green `#00E676`, Crimson `#FF1744`), beveled frames and hazard stripes. | Theme tokens, color constants | Custom `ThemeData` & decoration widgets | Fallback to dark grey if style undefined | `ui_mockups.md`, mockup images |
| 2 | R5 UI | Tactical Home Screen HUD | Header displaying Agent ID, Level, Rank (Commandeur du Foyer), Cleaning Credits, Products count, and Medals. | User profile data | Formatted HUD header | Defaults to Niv. 1, 0 credits if fresh | `home_screen_mockup` |
| 3 | R3 UI | Top 3 Urgent Targets Map & Tiles | Shows tactical sector floorplan highlighting highest urgency room + carousel of 3 most urgent tasks. | `TargetingEngine.getTopUrgentTasks()` | Interactive tiles + tactical map display | Empty state: "Toutes les zones sont propres !" | `ORIGINAL_REQUEST.md` R3, `home_screen_mockup` |
| 4 | R2 Flow | Room-based Onboarding Wizard | 4 mandatory rooms (`Cuisine`, `Salle de bain`, `Salon`, `Chambre`) with predefined task catalogues and default periodicities. | First login event / uninitialized user | Onboarding interactive catalogue | Prevents validation if 0 tasks enabled | `ORIGINAL_REQUEST.md` R2 |
| 5 | R2 Config | Periodicity & Task Customizer | Controls to adjust task frequency in days (1, 2, 3, 7, 14, 30j), toggle tasks on/off, adjust difficulty. | User touch inputs (steppers/chips) | Updated task configuration in local state | Clamps periodicity to valid range (1-365 days) | `ORIGINAL_REQUEST.md` R2 |
| 6 | R1 & R2 | Firestore Initial State Persistence | Persists user profile and all configured chores to Firestore under `users/{uid}/tasks` and marks `onboarded: true`. | Configured tasks list, user ID | Written Firestore documents | Shows retry snackbar on network failure | `ORIGINAL_REQUEST.md` R1, R2 |
| 7 | R3 Input | Dynamic Swipe Detector (5-8 moves) | `GestureDetector` validating directional pan gestures (`UP`, `DOWN`, `LEFT`, `RIGHT`) against a required sequence of 5 to 8 movements. | Pan drag velocity & direction | Progress index, visual arrow highlights, navigation on match | Input mismatch shakes UI, flashes red, resets input buffer | `ORIGINAL_REQUEST.md` R3, `stratagem_screen.dart` |
| 8 | R4 Audio | Tactical Audio Pressure Player | Plays selected local MP3 audio track on loop during 10-minute timer; stops upon completion or abort. | Local MP3 asset path, start/stop events | Continuous audio playback loop | Graceful fallback if audio asset missing | `ORIGINAL_REQUEST.md` R4 |
| 9 | R4 Config | Audio Track Selector | Allows user to select preferred tactical background music (e.g., Piste Alpha, Piste Bravo). | User selection from settings/onboarding | Persisted audio preference string | Defaults to default asset track | `ORIGINAL_REQUEST.md` R4 |
| 10 | R5 UI | Tactical Countdown HUD | Large neon digital display (`MM:SS` or `HH:MM:SS`), rotating radar spinner, objectives breakdown. | Timer tick (1 sec periodic) | Reactive text update, warning color shift below 2 min | Timer stops at 00:00 without negative values | `timer_screen_mockup` |
| 11 | R5 UI | Mission Validation (Long Press / Hold) | Tactile validation button requiring deliberate action (long press / confirm) to validate mission success. | Long press gesture | Log saved to `MissionLog`, SnackBar, return to Home | Accidental short tap ignored | `timer_screen.dart`, `timer_screen_mockup` |
| 12 | R5 Lexicon | Domestic Cleaning Lexicon Purge | Enforced terminology: replaces military units ("squads", "escouades", "artillery") with cleaning equivalents ("Planning", "Équipement", "Détartrage"). | All UI text strings and tooltips | Clean, theme-compliant user interface | Flagged by tests if forbidden strings exist | `ORIGINAL_REQUEST.md` R5 |

---

## 4. Edge Cases

| # | Feature | Input | Observed Behavior |
|---|---------|-------|-------------------|
| 1 | Dynamic Swipes (R3) | User swipes in wrong direction at step 4 of a 7-swipe code | Input buffer resets to index 0, visual error shake / red flash, audio error tone. |
| 2 | Dynamic Swipes (R3) | Diagonal swipe with ambiguous dx and dy ($\|dx\| \approx \|dy\|$) | `GestureDetector` evaluates dominant axis: `dx.abs() > dy.abs()`; if difference is below noise threshold (<15%), swipe is discarded to prevent false triggers. |
| 3 | Dynamic Swipes (R3) | Sequence length < 5 or > 8 | Generator clamps chore code length to $[5, 8]$ range strictly per R3 spec. |
| 4 | Targeting Engine (R3) | Task has never been completed (`lastCompletedAt == null`) | Treated as maximum urgency ($\text{UrgencyRatio} = 999.0$), guaranteeing inclusion in the Top 3 urgent tasks. |
| 5 | Targeting Engine (R3) | Fewer than 3 tasks exist in database (e.g., user disabled all but 2) | Engine returns all available tasks without index out of bounds; UI gracefully handles 1 or 2 tiles. |
| 6 | Targeting Engine (R3) | Multiple tasks have identical urgency scores | Secondary sorting by `difficulty` descending, then by alphabetical `name`. |
| 7 | Onboarding (R2) | User disables every task in a room | Validation button displays warning: "Au moins 1 tâche doit être configurée par pièce" (or minimum active chores threshold). |
| 8 | Onboarding (R2) | Periodicity set to 0 or negative days | Form validation clamps periodicity to $\ge 1$ day. |
| 9 | Audio Feedback (R4) | Mission paused, app sent to background, or user cancels mission | Audio player immediately calls `stop()` and releases audio focus. |
| 10 | Mission Timer (R4, R5) | Countdown timer reaches 00:00 without user validation | Timer halts at 00:00, red flashing alert: "TEMPS ÉCOULÉ - MISSION EXPIRÉE", audio track stops, option to extend or abort. |
| 11 | Firebase Offline (R1) | No internet connection on initial launch | Firebase Auth runs in anonymous mode; Firestore cache persists data locally via offline persistence; mock service fallback ensures app remains 100% playable. |

---

## 5. Detailed UI/UX Specifications (from `ui_mockups.md` & Mockups)

### 5.1 Design Tokens & Color Palette

```dart
class MilTechColors {
  // Backgrounds
  static const Color backgroundBlack = Color(0xFF0B0E14);
  static const Color panelDark = Color(0xFF141922);
  static const Color panelBorder = Color(0xFF263040);
  static const Color panelBevel = Color(0xFF333E50);

  // Neon Tactical Accents
  static const Color neonAmber = Color(0xFFFFA500);       // Primary CTA, alerts, active borders
  static const Color neonYellow = Color(0xFFFFCC00);      // Operation titles, high threat
  static const Color neonCyan = Color(0xFF00E5FF);        // Secondary info, HUD headers, timer hours
  static const Color neonGreen = Color(0xFF00E676);       // Success, active status, deploy CTA
  static const Color neonRed = Color(0xFFFF1744);         // Critical threat, alerts, cancellation

  // Text & Neutrals
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF90A4AE);
  static const Color textMuted = Color(0xFF546E7A);
}
```

### 5.2 Typography & Styling Tokens
- **Font Family**: Monospace or bold geometric sans-serif (e.g. `Roboto Mono`, `Share Tech Mono`, uppercase System Sans).
- **Text Case**: `toUpperCase()` for all headings, badges, action buttons, and HUD labels.
- **Letter Spacing**: `letterSpacing: 1.5` to `2.2` for tactical HUD readability.
- **Neon Glow Filter**:
  ```dart
  BoxShadow(
    color: MilTechColors.neonAmber.withOpacity(0.4),
    blurRadius: 10,
    spreadRadius: 1,
  )
  ```
- **Hazard Stripes**: Top-right corner diagonal orange/black warning stripes (`45°` repeating gradients) on primary cards.

---

### 5.3 Detailed Screen Layouts

#### Screen 1: Écran Principal (Tactical Home Screen)
1. **Status Bar / Top HUD**:
   - Connection & Battery indicator (`WIFI | BATT 84% | 19:42`).
   - Agent Profile Card:
     - Avatar box with cleaning shield / crossed mops insignia.
     - `AGENT ID: NETTOYEUR-7`
     - Level & Progress: `NIV. 42` with neon cyan progress bar.
     - Title: `COMMANDEUR DU FOYER` / `RESPONSABLE HYGIÈNE`.
     - Counters:
       - `CRÉDITS MÉNAGE: 124,500` (Cyan coin icon)
       - `PRODUITS: 64/98` (Orange spray bottle icon)
       - `MÉDAILLES: 15` (Yellow star/ribbon icon)
2. **Alert Banner**:
   - Warning triangle with exclamation mark.
   - Text: `ALERTE PRIORITAIRE: ENCRASSAGE DÉTECTÉ DANS LA CUISINE !`
3. **Tactical Intervention Map (Urgent Sector Blueprint)**:
   - Header: `OPÉRATION: ÉRADICATION SALETÉ` in neon yellow.
   - Vector Floorplan Blueprint: Graphic map showing Cuisine, Salon, SDB, Chambre.
   - Highlight: Neon yellow polygon around the most critical room.
   - Threat Level: `Urgence: MAXIMALE` in glowing red.
4. **Primary CTA Button**:
   - Heavy beveled frame with neon orange outer glow.
   - Text: `DÉMARRER LA MISSION`
   - Subtitle: `SECTEUR 1 - CUISINE ->`
   - On Tap: Opens the Stratagem Code Unlock Screen for the top urgent chore.
5. **Top 3 Urgent Tasks Carousel (Mission Tiles)**:
   - Header: `MISSIONS D'ENTRETIEN PRIORITAIRES`
   - **Tile 1 (Sélectionnée - Urgence Max)**:
     - Border: Glowing neon amber (`#FFA500`).
     - Icon: Flame / Degreaser spray (`Icons.cleaning_services` or `Icons.local_fire_department`).
     - Title: `DÉGRAISSAGE FOUR & PLAQUES`
     - Subtitle: `Cuisine • Diff. 3`
     - Badge: `Urgence Maximale` (Red).
   - **Tile 2**:
     - Border: Neon cyan (`#00E5FF`).
     - Icon: Shower / anti-limescale (`Icons.shower`).
     - Title: `DÉTARTRAGE DOUCHE`
     - Subtitle: `Salle de bain • Diff. 4`
     - Badge: `Urgence Moyenne` (Yellow).
   - **Tile 3**:
     - Border: Neon cyan (`#00E5FF`).
     - Icon: Vacuum (`Icons.cleaning_services`).
     - Title: `ASPIRATION SALON`
     - Subtitle: `Salon • Diff. 2`
     - Badge: `Basse Urgence` (Green).
6. **Bottom Navigation Bar**:
   - Metallic grooved panel with active orange top-border glow.
   - 4 Tabs:
     - `[QG/ACCUEIL]` (Active - Home icon)
     - `[PLANNING]` (Replaces `[SQUAD]` - Calendar/Tasks icon)
     - `[MATÉRIEL]` (Replaces `[ARSENAL]` - Cleaning tools icon)
     - `[BOUTIQUE]` (Replaces `[STORE]` - Eco-store/Supplies icon)

---

#### Screen 2: Écran de Saisie du Stratagème (Dynamic Swipe Input Screen)
1. **Header HUD**:
   - Title: `DÉVERROUILLAGE DU STRATAGÈME` (Neon yellow).
   - Task Details: `MISSION: DÉGRAISSAGE FOUR | CUISINE`.
2. **Dynamic Target Code Display (5 to 8 Arrows)**:
   - Row of 5 to 8 directional arrow indicators corresponding to the chore's code.
   - Visual States:
     - Inactive/Pending: Slate grey outline (`#374151`).
     - Completed / Validated: Glowing neon cyan/amber (`#00E5FF`).
     - Current Active Input: Pulsing neon yellow.
3. **Gesture Detector Area**:
   - Listens to pan gestures (`onPanEnd`) across full screen.
   - Velocity threshold: 100 px/sec.
   - Matching Logic: Compares direction to `targetSequence[currentStep]`.
   - On Success: Advances step; upon completing all steps, navigates to `TimerScreen`.
   - On Failure: Screen shakes, arrows flash red, buffer resets to 0.

---

#### Screen 3: Écran de Mission / Minuteur (Tactical Timer Screen)
1. **Header HUD**:
   - Insignia: Cleaning emblem.
   - Text: `AGENT: NETTOYEUR-7 | RANG: MAÎTRE DU LOGIS | INDICATIF: PROPRE-1`
2. **Operation Status Banner**:
   - `OPÉRATION: ÉRADICATION GRAISSE | STATUT: EN INTERVENTION`
3. **Giant Countdown Timer HUD Card**:
   - Corner rivets and green status LED dot.
   - Subtitle: `TEMPS RESTANT D'INTERVENTION:` (Neon cyan).
   - Massive Display: `00:08:43` (Split neon: Cyan minutes `08`, Amber seconds `43`).
   - Radar circle spinner animation rotating in cyan.
   - Subtext: `NETTOYAGE TACTIQUE EN COURS...`
4. **Current Objectives Panel (`OBJECTIFS DE MISSION`)**:
   - `PRINCIPAL: Dégraisser les plaques de cuisson (EN COURS)` (Cyan/Amber).
   - `SECONDAIRE: Vider et nettoyer l'évier (0/1)` (Cyan/White).
   - `BONUS: Passer un coup de chiffon sur le plan de travail` (Yellow).
5. **Cleaning Parameters Panel (`PARAMÈTRES D'INTERVENTION`)**:
   - `ZONE: Secteur Cuisine | Plan de travail`.
   - `FLÉAUX: GRAISSE INCRUSTÉE, CALCAIRE HOSTILE`.
   - `ÉQUIPEMENT: Éponge grattante, Spray dégraissant microfibre`.
6. **Tactical Audio Control Bar (R4)**:
   - Displays currently playing loop: `Piste: Ambiance Tactique Alpha (En boucle)`.
   - Mute / Track toggle button.
7. **Action Buttons**:
   - Left Button: `ABANDONNER LA MISSION` (Orange neon outline, confirms exit and stops audio).
   - Right Button: `VALIDER LA MISSION` (Neon green glowing button, long-press hold to validate).

---

## 6. Exhaustive R2 Onboarding Specifications

### 6.1 The 4 Mandatory Rooms and Predefined Chores Catalogue

| Room (Pièce) | Chore Name (Tâche) | Default Periodicity | Difficulty | Swipe Length | Generated Code Example |
|--------------|-------------------|---------------------|------------|--------------|------------------------|
| **Cuisine** | Nettoyer les plaques & plan de travail | 1 jour (Quotidien) | 2 | 5 | `['UP', 'RIGHT', 'DOWN', 'DOWN', 'RIGHT']` |
| **Cuisine** | Vider et nettoyer l'évier | 1 jour (Quotidien) | 1 | 5 | `['DOWN', 'DOWN', 'UP', 'RIGHT', 'LEFT']` |
| **Cuisine** | Sortir les poubelles & tri sélectif | 2 jours | 1 | 5 | `['LEFT', 'DOWN', 'RIGHT', 'UP', 'UP']` |
| **Cuisine** | Nettoyer le micro-ondes & four | 7 jours (Hebdo) | 3 | 6 | `['UP', 'UP', 'RIGHT', 'DOWN', 'LEFT', 'UP']` |
| **Cuisine** | Lessiver le sol de la cuisine | 4 jours | 3 | 6 | `['DOWN', 'LEFT', 'DOWN', 'RIGHT', 'UP', 'DOWN']` |
| **Salle de bain** | Nettoyer le lavabo et le miroir | 3 jours | 2 | 5 | `['UP', 'LEFT', 'DOWN', 'RIGHT', 'UP']` |
| **Salle de bain** | Détartrer la douche / baignoire | 7 jours (Hebdo) | 4 | 7 | `['UP', 'RIGHT', 'DOWN', 'LEFT', 'UP', 'RIGHT', 'DOWN']` |
| **Salle de bain** | Désinfecter les toilettes (WC) | 3 jours | 3 | 6 | `['DOWN', 'DOWN', 'LEFT', 'RIGHT', 'UP', 'DOWN']` |
| **Salle de bain** | Laver le carrelage et tapis de bain | 7 jours (Hebdo) | 3 | 6 | `['LEFT', 'RIGHT', 'DOWN', 'DOWN', 'UP', 'UP']` |
| **Salon** | Passer l'aspirateur | 3 jours | 2 | 5 | `['UP', 'DOWN', 'UP', 'DOWN', 'RIGHT']` |
| **Salon** | Dépoussiérer les meubles et TV | 7 jours (Hebdo) | 2 | 6 | `['RIGHT', 'LEFT', 'UP', 'UP', 'DOWN', 'RIGHT']` |
| **Salon** | Nettoyer et ranger la table basse | 2 jours | 1 | 5 | `['DOWN', 'RIGHT', 'UP', 'LEFT', 'DOWN']` |
| **Salon** | Nettoyer les baies vitrées / fenêtres | 14 jours (Bi-mensuel) | 4 | 7 | `['UP', 'UP', 'LEFT', 'DOWN', 'RIGHT', 'UP', 'RIGHT']` |
| **Chambre** | Changer les draps et taies | 7 jours (Hebdo) | 3 | 6 | `['UP', 'DOWN', 'LEFT', 'RIGHT', 'UP', 'UP']` |
| **Chambre** | Aérer et faire le lit | 1 jour (Quotidien) | 1 | 5 | `['UP', 'UP', 'RIGHT', 'LEFT', 'DOWN']` |
| **Chambre** | Aspirer sous le lit et recoins | 7 jours (Hebdo) | 2 | 6 | `['DOWN', 'LEFT', 'RIGHT', 'DOWN', 'UP', 'UP']` |
| **Chambre** | Trier le linge et ranger penderie | 3 jours | 2 | 5 | `['LEFT', 'DOWN', 'LEFT', 'RIGHT', 'UP', 'DOWN']` |

### 6.2 Customization UI Flow
1. **Room Stepper / Tabs**: 4 tabs (`CUISINE`, `SALLE DE BAIN`, `SALON`, `CHAMBRE`).
2. **Card Controls**:
   - Checkbox / Toggle: Activer/Désactiver la tâche.
   - Stepper (`-` / `+`) & Frequency presets (`1j`, `3j`, `7j`, `14j`, `30j`).
   - Difficulty rating display (1 to 5 stars).
3. **Global Parameters Panel**:
   - Indicatif / Nom de l'agent: default `"Nettoyeur-1"`.
   - Durée du Timer: default `10 minutes` (600s), adjustable (5, 10, 15 min).
   - Ambiance sonore par défaut: dropdown/radio selection (`Piste Tactique Alpha`, `Piste Tactique Bravo`).
4. **Validation & Persistence Protocol**:
   - Button: `VALIDER ET COMMENCER L'AVENTURE` (Neon amber CTA).
   - Validates that user has configured at least 1 task per room.
   - Persists user document to Firestore (`users/{uid}`) with `onboarded: true`.
   - Persists all enabled tasks to Firestore (`users/{uid}/tasks/{taskId}`).
   - Sets local preference flag `onboarded = true`.
   - Transitions navigation directly to `StratagemHomeScreen`.

---

## 7. Vocabulary Constraints & Replacement Dictionary

| # | Forbidden / Removed Military Term | Where It Appears in Mockups / Old Code | Exact Mandated Replacement (Cleaning/Productivity Theme) |
|---|-----------------------------------|---------------------------------------|----------------------------------------------------------|
| 1 | **Squad / Escouade** | Bottom Nav `[SQUAD]`, Tile `SQUAD DEFENSE`, Status `SQUAD STATUS` | **Planning / Répartition / Tâches** |
| 2 | **Squad Defense** | Mockup Tile 2 | **Barrière Anti-Calcaire / Protection Hygiène** |
| 3 | **Squad Status** | Mockup Timer Screen | **Statut d'Intervention / État d'Avancement** |
| 4 | **Helldiver / Helldivers** | Mockup Header, Art Direction description | **Nettoyeur / Agent d'Entretien / Maître du Logis** |
| 5 | **Orbital Commander / Marshal** | Mockup Header Rank | **Commandeur du Foyer / Expert Entretien** |
| 6 | **Arsenal** | Bottom Nav `[ARSENAL]` | **Matériel / Produits d'Entretien / Équipement** |
| 7 | **Store** | Bottom Nav `[STORE]` | **Boutique Éco / Réserve / Inventaire** |
| 8 | **Automaton Invasion** | Mockup Alert Banner | **Encrassage Critique / Foyer de Saleté Détecté** |
| 9 | **Automaton Fabricator** | Mockup Secondary Objective | **Résidu Incrusté / Dépôt Calcaire Tenace** |
| 10 | **Enemies** | Mockup Parameters Panel | **Fléaux Ménagers (Graisse, Calcaire, Poussière, Désordre)** |
| 11 | **Hazards** | Mockup Parameters Panel | **Surfaces Fragiles / Contraintes d'Intervention** |
| 12 | **Heavy Artillery** | Mockup Hazards | **Graisse Cuite / Taches Anciennes** |
| 13 | **Planet X / Sector 74G** | Mockup Subtitle & Location | **Secteur Cuisine / Zone d'Habitation / Maison** |
| 14 | **Orbital Strike** | Mockup Tile 1 | **Dégraissage Express / Frappe Décapante** |
| 15 | **Supply Raid** | Mockup Tile 3 | **Rangement Éclair / Réassort Produits** |
| 16 | **Heavy Assault / Hvy Assault** | Mockup Tile 4 | **Grand Nettoyage / Décapage Intensif** |
| 17 | **Readying Orbital Insertion** | Mockup Spinner Subtext | **Préparation de l'Intervention / Déploiement des Éponges** |
| 18 | **Time until Deployment** | Mockup Timer Header | **Temps Restant d'Intervention / Chrono Mission** |
| 19 | **Evacuate Research Personnel** | Mockup Bonus Objective | **Aérer la pièce / Vider les poubelles** |
| 20 | **Cancel Deployment** | Mockup Cancel Button | **Abandonner la Mission / Annuler l'Intervention** |

---

## 8. Caveats

1. **Firebase Testing Isolation**: Running `flutter test` in automated environments without configured Google Cloud credentials will fail if Firebase plugins attempt real network handshakes. Therefore, the architecture must decouple Firebase via an abstract repository/service interface (`AuthService`, `ChoreRepository`) backed by mock implementations for tests.
2. **Audio Package Headless Support**: The `audioplayers` package requires platform channels. In headless widget tests (`flutter_test`), audio calls must be safely wrapped or mocked so that audio playback does not crash unit tests.
3. **Local Audio Files**: MP3 files should be placed under `app/assets/audio/` and registered in `pubspec.yaml`. Dummy/short MP3 files or silent audio buffers can be provided for testing and demonstration.

---

## 9. Conclusion

The specification mining phase is **100% complete**:
- Authoritative mockups from `ui_mockups.md` have been fully visually analyzed, and all color codes, font treatments, and layout widgets have been specified.
- The R2 Onboarding catalogue has been established with 4 rooms, 17 balanced tasks, default periodicities (1 to 14 days), difficulties (1-4), and dynamic swipe lengths (5 to 8).
- The strict cleaning vocabulary replacement dictionary has been defined, completely replacing all military/squad terminology.
- The urgency formula for R3 and the audio lifecycle for R4 are fully defined and ready for the implementation team.

---

## 10. Verification Method

To verify these findings:
1. **Inspect Mockup Visuals**:
   - `view_file` on `C:\Users\krisd\.gemini\antigravity\brain\8594895e-dac0-45f7-be00-1e9594ff827f\home_screen_mockup_1791116804128.jpg`
   - `view_file` on `C:\Users\krisd\.gemini\antigravity\brain\8594895e-dac0-45f7-be00-1e9594ff827f\timer_screen_mockup_1791116815059.jpg`
2. **Inspect Spec Documents**:
   - `view_file` on `c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\.agents\teamwork\ORIGINAL_REQUEST.md`
   - `view_file` on `C:\Users\krisd\.gemini\antigravity\brain\8594895e-dac0-45f7-be00-1e9594ff827f\ui_mockups.md`
3. **Verify Environment**:
   - `run_command`: `flutter --version` in `c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper\app` (verifies Flutter 3.47.5 / Dart 3.13.4).
