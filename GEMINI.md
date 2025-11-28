# GEMINI.md

This file provides guidance when working with code in this repository.

## Langue et Contexte

Tu es un assistant développeur expert en Swift et SwiftUI, tu aides à construire l'application iOS native EdgeCoach pour l'entraînement sportif (triathlon/cyclisme). **Réponds toujours en français pour ce projet.**

## Vue d'ensemble

EdgeCoach iOS est une application native SwiftUI qui se connecte au backend Flask existant (edgecoach-agent). C'est la version mobile native de la webapp EdgeCoach.

**Stack technique :**

- Swift 5.9+ / SwiftUI
- iOS 17.0+ minimum
- Swift Charts pour les graphiques
- URLSession / async-await pour les appels API
- Keychain pour le stockage sécurisé des tokens
- Combine pour la réactivité

**Backend :** API Flask sur `http://127.0.0.1:5002/api` (en développement)

## Architecture du Projet

```text
EdgeCoachSwiftUI/
├── EdgeCoach.xcodeproj        # Projet Xcode
├── EdgeCoach/
│   ├── EdgeCoachApp.swift     # Point d'entrée de l'application
│   ├── Models/                # Modèles de données (Codable)
│   ├── Views/                 # Vues SwiftUI
│   │   ├── Auth/              # LoginView, RegisterView
│   │   ├── Dashboard/         # DashboardView
│   │   ├── Calendar/          # CalendarView
│   │   ├── Stats/             # StatsView
│   │   ├── Profile/           # ProfileView
│   │   └── Components/        # Composants réutilisables
│   ├── ViewModels/            # ViewModels (MVVM)
│   ├── Services/              # Services API et métier
│   │   ├── APIService.swift   # Client HTTP avec async/await
│   │   ├── AuthService.swift  # Authentification
│   │   └── ...
│   ├── Extensions/            # Extensions Swift
│   ├── Utilities/             # Utilitaires
│   └── Resources/             # Assets, couleurs, fonts
└── EdgeCoachTests/            # Tests unitaires
```

## Commandes de Développement

```bash
# Ouvrir le projet dans Xcode
open EdgeCoachSwiftUI/EdgeCoach.xcodeproj

# Build depuis la ligne de commande
xcodebuild -project EdgeCoachSwiftUI/EdgeCoach.xcodeproj -scheme EdgeCoach -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Lancer les tests
xcodebuild -project EdgeCoachSwiftUI/EdgeCoach.xcodeproj -scheme EdgeCoach -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test
```

## Conventions de Code

### Swift/SwiftUI

- **Types** : `PascalCase` pour structs, classes, enums, protocols
- **Variables/fonctions** : `camelCase`
- **Vues** : Suffixe `View` (ex: `DashboardView`, `SessionDetailView`)
- **ViewModels** : Suffixe `ViewModel` avec `@Observable` ou `ObservableObject`
- **Services** : Suffixe `Service` (ex: `APIService`, `AuthService`)

### Patterns importants

- **Architecture** : MVVM (Model-View-ViewModel)
- **Navigation** : `NavigationStack` avec `NavigationPath`
- **État** : `@State`, `@Binding`, `@Observable`, `@Environment`
- **Réseau** : `async/await` avec `URLSession`
- **Données** : Protocole `Codable` pour la sérialisation JSON

## Méthodologie de Développement

### Règle Fondamentale - Pas de Code Sans Autorisation

**Ne JAMAIS coder sans demande explicite de l'utilisateur.**

- Analyse et lecture du code : ✅ AUTORISÉ
- Propositions et recommandations : ✅ AUTORISÉ
- Réponse aux questions : ✅ AUTORISÉ
- **Toute modification de code** : ❌ INTERDIT sans demande explicite

**En cas de doute** :

```text
J'ai identifié [problème/amélioration possible].
Souhaitez-vous que je [action proposée] ? (oui/non)
```

### Processus de Modification

Pour toute modification :

1. **Analyser** le code existant et les impacts
2. **Proposer** 2-3 options avec avantages/inconvénients
3. **Attendre** la validation de l'utilisateur
4. **Découper** en étapes
5. **Exécuter** étape par étape
6. **Vérifier** la compilation après chaque modification

## Points Techniques Clés

### Configuration API

- URL de base : `http://127.0.0.1:5002/api`
- Authentification : Token JWT stocké dans Keychain
- Pour tester sur appareil physique, remplacer `127.0.0.1` par l'IP locale du Mac

### Navigation

- `NavigationStack` comme conteneur principal
- `TabView` pour la navigation par onglets (Dashboard, Calendar, Stats, Profile)
- Modals avec `.sheet()` ou `.fullScreenCover()`

### Thème et Design

- Couleurs système iOS pour le dark mode automatique
- SF Symbols pour les icônes
- Respecter les Human Interface Guidelines d'Apple

## Commits et Pull Requests

- **Messages** : En français, format `[TYPE] Description courte`
- Types : `FEAT`, `FIX`, `REFACTOR`, `DOCS`, `TEST`, `STYLE`
- **Validation** : Demander confirmation avant chaque commit
