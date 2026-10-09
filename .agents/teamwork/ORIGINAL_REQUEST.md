# Original User Request

## 2026-10-04T12:55:14Z

Le projet consiste à terminer le développement de l'application Flutter "HouseholdStratagem". L'équipe doit implémenter les jalons finaux : une refonte UI basée sur des maquettes, un système d'onboarding complet avec Firebase Auth/Firestore, des séquences de tâches dynamiques, et des retours audio (musique/sons).

Working directory: c:\Users\krisd\.gemini\antigravity\scratch\MenageStratagemSweeper
Integrity mode: demo

## Requirements

### R1. Base de données et Authentification (Firebase)
Le système doit utiliser Firebase Authentication pour l'identification utilisateur, et Firestore pour sauvegarder le profil, le catalogue des tâches (périodicité) et l'historique des missions.

### R2. Onboarding Initial et Configuration
Lors de la première connexion d'un compte, un flux d'onboarding doit s'afficher. Il doit présenter des tâches pré-définies groupées par section/pièce (Cuisine, Salle de bain, Salon, Chambre) avec leurs périodicités par défaut. L'utilisateur doit pouvoir ajuster ces périodicités et d'autres paramètres globaux. Une fois validé, tout est sauvegardé sur Firebase avant de démarrer l'aventure.

### R3. Moteur de Cibles et Stratagèmes Complexes
L'écran principal ne doit plus afficher qu'une seule tâche, mais le Top 3 des tâches les plus urgentes. De plus, la séquence de "swipes" (Haut, Bas, etc.) pour déverrouiller un stratagème n'est plus limitée à 4 ; elle peut être de longueur variable (ex: 5 à 8 mouvements).

### R4. Pression Audio Personnalisable
Le Timer de 10 minutes (ou la mission) doit déclencher la lecture de fichiers audio locaux (MP3). L'utilisateur peut choisir sa piste sonore (ambiance tactique) pour s'accompagner.

### R5. Refonte Visuelle (UI)
L'interface utilisateur doit être reconstruite pour correspondre visuellement aux maquettes du fichier `ui_mockups.md`. Le vocabulaire et les icônes doivent être adaptés au thème strict du "ménage" et de l'entretien (sans les références à des "escouades" ou "squads").

## Acceptance Criteria

### R1 & R2. Firebase et Onboarding
- [ ] Firebase Auth (email/mdp ou anonyme) et Firestore sont intégrés.
- [ ] Le flux d'onboarding catégorise les tâches par pièce et permet leur modification avant l'enregistrement initial.
- [ ] Après l'onboarding, les données sont persistées sur Firestore et rechargées aux lancements suivants.

### R3. Affichage et Gameplay
- [ ] L'écran principal affiche les 3 tâches les plus urgentes identifiées par le moteur.
- [ ] Le lecteur de `GestureDetector` accepte et valide des séquences de swipes supérieures à 4 mouvements.

### R4. Audio
- [ ] Un package audio joue une piste sonore en boucle pendant la mission, et s'arrête à la fin.

### R5. Refonte Visuelle
- [ ] L'interface respecte le layout et les couleurs de `ui_mockups.md`.
- [ ] Le lexique est purement orienté tâches ménagères (productivité).
