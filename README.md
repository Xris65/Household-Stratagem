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

### 🎵 Musique de Mission
- **Musique de mission : Cj Aist (Wikimedia Commons - CC BY 3.0)**
  - **Titre de l'œuvre** : *Epic battle*
  - **Auteur / Compositeur** : Cj Aist
  - **Source officielle** : [Wikimedia Commons — File:Cj_Aist_-_Epic_battle.mp3](https://commons.wikimedia.org/wiki/File:Cj_Aist_-_Epic_battle.mp3)
  - **Licence légale** : [Creative Commons Attribution 3.0 Unported (CC BY 3.0)](https://creativecommons.org/licenses/by/3.0/)
  - **Notice d'utilisation** : Piste audio intégrée en boucle d'accompagnement (`tactical_ambiance_1.mp3`, `tactical_ambiance_2.mp3`, `tactical_ambiance_3.mp3`) durant les opérations de nettoyage minutées.

### 🎧 Ambiance Audio & Passerelle de Commandement
- **Ambiance Command Bridge : Domaine Public / CC0**
  - **Désignation** : Atmosphère sonore tactique et bruitages d'arrière-plan du centre de commandement ménager.
  - **Licence légale** : [Creative Commons CC0 1.0 Universal — Public Domain Dedication](https://creativecommons.org/publicdomain/zero/1.0/)
  - **Statut légal** : Libre de droits, aucune restriction commerciale ou d'attribution requise.

### 🔊 SFX Tactiques
- **SFX Tactiques : Domaine Public / CC0**
  - **Catalogue d'effets sonores** :
    - `swipe.wav` : Signal acoustique de balayage directionnel de stratagème.
    - `deploy.wav` : Carillon d'activation et d'engagement de mission.
    - `victory.wav` : Fanfare d'accomplissement et de validation finale de tâche.
  - **Conception & Synthèse** : Génération procédurale d'ondes sinusoïdales à modulation d'enveloppe (`build_audio.py`).
  - **Licence légale** : [Creative Commons CC0 1.0 Universal (Domaine Public)](https://creativecommons.org/publicdomain/zero/1.0/)

---

## ⚖️ Licences Globales du Projet

- **Code Source & Composants UI** : Sous licence [MIT License](LICENSE) © 2026 Xris65.
- **Actifs Multimédia & Audio** : Conformes aux licences Creative Commons applicables ([CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) et [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)).
