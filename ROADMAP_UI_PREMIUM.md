# Roadmap EdgeCoach : Expérience UI Premium

Cette roadmap définit les étapes pour transformer EdgeCoach en une application de sport "Premium", rivalisant avec Strava ou Runna par son attention aux détails, ses micro-interactions et sa pédagogie par l'IA.

---

## ✅ Phase 1 : La Fondation Sensorielle ("Le Toucher") - TERMINÉE
*Objectif : Donner du poids et de la texture à l'application.*

- [x] **1.1. Architecture Haptique (`HapticManager`)**
    - Singleton centralisé : `.tap`, `.lock`, `.pulse`, `.error`, `.success`.
- [x] **1.2. Intégration dans l'existant**
    - Feedback au changement d'onglet (`TabView`).
    - Feedback sur les actions de Login et la sidebar du Coach.
- [x] **1.3. Refonte "Card Design"**
    - Suppression des bordures strictes au profit d'ombres douces (KPI, Training Load, PMC).
    - Ajout de `PremiumButtonStyle` avec effet de pression (scale effect).

## ✅ Phase 2 : L'Intelligence Tangible ("Smart Briefing") - TERMINÉE
*Objectif : Remplacer le contenu statique par une narration immersive.*

- [x] **2.1. Composants "Story" (SwiftUI)**
    - `StoryContainerView` : Navigation par tap, barres de progression automatiques, pause au long press.
- [x] **2.2. Templates de Briefing**
    - `SessionBriefingView` : Intro IA (Pourquoi), Structure (Le Menu), Focus (Le Conseil).
- [x] **2.3. Intégration Dashboard**
    - Bouton "Briefing IA" dynamique sur le Dashboard avec dégradé Premium.
    - Transition plein écran (`fullScreenCover`) pour l'immersion.

## ⏳ Phase 3 : La Synergie Visuelle ("Gamification Organique") - À VENIR
*Objectif : Visualiser l'état de forme et la discipline de façon élégante.*

- [ ] **3.1. Le "Synergy Ring" (Header Dashboard)**
    - Indicateur circulaire "vivant" (animation de respiration).
    - Couleurs dynamiques selon la fraîcheur/charge.
- [ ] **3.2. Animation de Complétion "Liquid Fill"**
    - Animation de remplissage fluide de la séance complétée.
    - Effet de fusion avec l'anneau de synergie.
- [ ] **3.3. Jauges de Progrès Stylisées**
    - Remplacement des barres de progression classiques par des jauges minimalistes et animées.

## ⏳ Phase 4 : Polish & Fluidité ("Le Finissage") - À VENIR
*Objectif : Atteindre un niveau de finition "App Store Featured".*

- [ ] **4.1. Micro-interactions**
    - Animations de pression (scale down) généralisées.
    - Entrées en cascade (staggered animations) pour le contenu des listes.
- [ ] **4.2. Physique des Listes**
    - Effets ressort (spring) sur le Drag & Drop.
- [ ] **4.3. Dark Mode Excellence**
    - Optimisation des contrastes et des dégradés profonds.

---

## Philosophie de Design
- **Organique :** L'interface réagit physiquement.
- **Pédagogique :** L'IA explique ses choix via les Stories.
- **Subtile :** Le design s'efface devant l'action.
