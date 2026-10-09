# ⚡ HouseholdStratagem — Ménage Stratagem Sweeper 🧹

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Audio License: CC BY 3.0](https://img.shields.io/badge/Audio%20License-CC%20BY%203.0-orange.svg)](https://creativecommons.org/licenses/by/3.0/)
[![SFX License: CC0](https://img.shields.io/badge/SFX-CC0%20%2F%20Public%20Domain-brightgreen.svg)](https://creativecommons.org/publicdomain/zero/1.0/)

> **ORDRE DE MISSION PRIORITAIRE** : L'entretien ménager élevé au rang de protocole tactique d'élite.  
> Inspiré de l'esthétique Mil-Tech Dark Tactical HUD (Helldivers 2), **HouseholdStratagem** transforme la corvée domestique en déploiements de stratagèmes chronométrés et rythmés sous haute pression audio.

---

## 🛰️ Présentation du Projet

**HouseholdStratagem** est une application mobile Flutter conçue pour gamifier la gestion ménagère quotidienne :
- **HUD Tactique Mil-Tech** : Palette sombre métallique (`#0B0E14`), néon ambre (`#FFA500`), cyan tactique (`#00E5FF`) et indicateurs d'urgence.
- **Moteur de Ciblage Dynamique (`TargetingEngine`)** : Calcul en temps réel du score d'urgence de chaque tâche ménagère selon la formule :
  $$\text{UrgencyScore} = (\text{overdueRatio} \times 100.0) + (\text{difficulty} \times 5.0)$$
- **Déverrouillage par Stratagèmes Gestuels (`StratagemEngine`)** : Combinaisons dynamiques de balayages tactiques (5 à 8 mouvements directionnels : Haut, Bas, Gauche, Droite) pour autoriser l'intervention.
- **Chronomètre de Mission & Ambiance Sous Pression (`TimerScreen`)** : Compte à rebours de 10 minutes avec radar rotatif, objectifs interactifs et immersion sonore continue.
- **Lexique Domestique Strict** : Terminologie 100% orientée nettoyage, maintenance et propreté (zéro terme militaire superflu).

---

## 🛠️ Architecture & Modules

```
app/
├── assets/
│   ├── audio/              # Banques sonores & musiques de mission
│   └── logo.jpg            # Emblème tactique du projet
├── lib/
│   ├── engine/             # Moteurs de ciblage et séquences de stratagèmes
│   ├── models/             # Modèles Chore, MissionLog, UserProfile, RoomCategory
│   ├── screens/            # Écrans AuthGate, Onboarding, Home, Stratagem, Timer, Settings
│   ├── services/           # Abstraction AudioService, AuthService, HouseholdRepository
│   ├── theme/              # Thème MilTechTheme (Dark HUD, néon, biseaux)
│   └── widgets/            # Cartes d'intervention, boutons tactiques, radar scanner
└── test/
    └── e2e/                # Suite E2E opaque-box exhaustive (170 tests, 100% pass)
```

---

## 🚀 Déploiement & Exécution

### Prérequis
- Flutter SDK (≥ 3.19.0)
- Dart SDK (≥ 3.3.0)

### Lancement de l'application
```bash
# Se placer dans le répertoire de l'application Flutter
cd app

# Récupération des dépendances
flutter pub get

# Lancement en mode debug
flutter run
```

### Exécution de la suite de tests
```bash
# Exécution complète de la suite E2E opaque-box (170 tests validés)
flutter test test/e2e/e2e_all_test.dart
```

---

## Crédits & Licences Audio

> ### 📢 REGISTRE OFFICIEL DES ATTRIBUTIONS AUDIO & LICENCES
> Tous les actifs sonores et musicaux intégrés dans **HouseholdStratagem** respectent scrupuleusement les conditions de diffusion de **Wikimedia Commons** et des licences **Creative Commons**.

### 🎵 Musiques de Mission Tactique (6 Pistes Distinctes)

- **Piste 1 (Alpha) — `tactical_ambiance_1.mp3`**
  - **Titre de l'œuvre** : *Epic battle*
  - **Auteur / Compositeur** : Cj Aist
  - **Source officielle** : [Wikimedia Commons — File:Cj_Aist_-_Epic_battle.mp3](https://commons.wikimedia.org/wiki/File:Cj_Aist_-_Epic_battle.mp3)
  - **Licence légale** : [Creative Commons Attribution 3.0 Unported (CC BY 3.0)](https://creativecommons.org/licenses/by/3.0/)
  - **Notice d'utilisation** : Rythme martial et percussions d'assaut tactique durant les opérations minutées.

- **Piste 2 (Bravo) — `tactical_ambiance_2.mp3`**
  - **Titre de l'œuvre** : *Epic Questionmark*
  - **Auteur / Compositeur** : Antti Luode
  - **Source officielle** : [Wikimedia Commons — File:Epic Questionmark (Antti Luode).mp3](https://commons.wikimedia.org/wiki/File:Epic_Questionmark_(Antti_Luode).mp3)
  - **Licence légale** : [Creative Commons Attribution 3.0 Unported (CC BY 3.0)](https://creativecommons.org/licenses/by/3.0/)
  - **Notice d'utilisation** : Tension opérationnelle héroïque, cordes dramatiques et marche sous pression.

- **Piste 3 (Charlie) — `tactical_ambiance_3.mp3`**
  - **Titre de l'œuvre** : *Not So Epic* (Heavy Recon)
  - **Auteur / Compositeur** : Antti Luode
  - **Source officielle** : [Wikimedia Commons — File:Not So Epic (Antti Luode).mp3](https://commons.wikimedia.org/wiki/File:Not_So_Epic_(Antti_Luode).mp3)
  - **Licence légale** : [Creative Commons Attribution 3.0 Unported (CC BY 3.0)](https://creativecommons.org/licenses/by/3.0/)
  - **Notice d'utilisation** : Infiltration lourde, basse industrielle et suspense d'intervention tactique.

- **Piste 4 (Delta) — `tactical_ambiance_4.mp3`**
  - **Titre de l'œuvre** : *Dark Synth*
  - **Auteur / Compositeur** : Antti Luode
  - **Source officielle** : [Wikimedia Commons — File:Dark Synth (Antti Luode).mp3](https://commons.wikimedia.org/wiki/File:Dark_Synth_(Antti_Luode).mp3)
  - **Licence légale** : [Creative Commons Attribution 3.0 Unported (CC BY 3.0)](https://creativecommons.org/licenses/by/3.0/)
  - **Notice d'utilisation** : Ondes synthétiques sombres, battements électroniques cybernétiques et dynamique d'assaut.

- **Piste 5 (Echo) — `tactical_ambiance_5.mp3`**
  - **Titre de l'œuvre** : *Future City*
  - **Auteur / Compositeur** : Antti Luode
  - **Source officielle** : [Wikimedia Commons — File:Future City (Antti Luode).mp3](https://commons.wikimedia.org/wiki/File:Future_City_(Antti_Luode).mp3)
  - **Licence légale** : [Creative Commons Attribution 3.0 Unported (CC BY 3.0)](https://creativecommons.org/licenses/by/3.0/)
  - **Notice d'utilisation** : Électro futuriste haute cadence, ambiance urbaine sci-fi d'intervention d'urgence.

- **Piste 6 (Foxtrot) — `tactical_ambiance_6.mp3`**
  - **Titre de l'œuvre** : *Space Dominator Squadron*
  - **Auteur / Compositeur** : Antti Luode
  - **Source officielle** : [Wikimedia Commons — File:Space Dominator Squadron (Antti Luode).mp3](https://commons.wikimedia.org/wiki/File:Space_Dominator_Squadron_(Antti_Luode).mp3)
  - **Licence légale** : [Creative Commons Attribution 3.0 Unported (CC BY 3.0)](https://creativecommons.org/licenses/by/3.0/)
  - **Notice d'utilisation** : Marche d'escadron spatial, percussions électroniques intenses et assaut critique.

### 🎧 Ambiance Passerelle de Commandement (Bridge Deck)

- **Ambiance Command Bridge — `bridge_ambiance.mp3`**
  - **Titre de l'œuvre** : *The Bridge*
  - **Auteur / Compositeur** : Antti Luode
  - **Source officielle** : [Wikimedia Commons — File:The Bridge (Antti Luode).mp3](https://commons.wikimedia.org/wiki/File:The_Bridge_(Antti_Luode).mp3)
  - **Licence légale** : [Creative Commons Attribution 3.0 Unported (CC BY 3.0)](https://creativecommons.org/licenses/by/3.0/)
  - **Notice d'utilisation** : Boucle d'ambiance sonore globale pour le centre d'opérations et la passerelle de commandement.

### 🔊 SFX Tactiques

- **SFX Tactiques procéduraux : Domaine Public / CC0**
  - **Catalogue d'effets sonores** :
    - `swipe.wav` : Signal acoustique de balayage directionnel de stratagème.
    - `deploy.wav` : Carillon d'activation et d'engagement de mission.
    - `victory.wav` : Fanfare d'accomplissement et de validation finale de tâche.
  - **Conception & Synthèse** : Génération procédurale d'ondes sinusoïdales à modulation d'enveloppe (`build_audio.py` / Mil-Tech Audio Core).
  - **Licence légale** : [Creative Commons CC0 1.0 Universal (Domaine Public)](https://creativecommons.org/publicdomain/zero/1.0/)

---

## ⚖️ Licences Globales du Projet

- **Code Source & Composants UI** : Sous licence [MIT License](LICENSE) © 2026 Xris65.
- **Actifs Multimédia & Audio** : Conformes aux licences Creative Commons applicables ([CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) et [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)).
