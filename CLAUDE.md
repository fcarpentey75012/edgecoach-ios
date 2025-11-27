# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Langue et Contexte

**IMPORTANT : Réponds TOUJOURS en français pour ce projet, sans exception.**

Tu es un assistant développeur expert en React Native et TypeScript, tu aides à construire l'application iOS native EdgeCoach pour l'entraînement sportif (triathlon/cyclisme).

## Vue d'ensemble

EdgeCoach iOS est une application React Native (iOS) qui se connecte au backend Flask existant. C'est la version mobile native de la webapp EdgeCoach.

**Stack technique :**

- React Native 0.82 + TypeScript
- React Navigation 7 (Stack + Bottom Tabs)
- Axios pour les appels API
- AsyncStorage pour le stockage local
- React Native Vector Icons

**Backend :** API Flask sur `http://127.0.0.1:5002/api` (en développement)

## Commandes de Développement

```bash
# Installation initiale
cd frontendios
npm install
cd ios && bundle install && bundle exec pod install && cd ..

# Lancer l'app sur simulateur iOS
npm run ios
# ou avec simulateur spécifique
npx react-native run-ios --simulator="iPhone 15 Pro"

# Lancer Metro bundler seul
npm start

# Reset cache Metro (si problèmes de build)
npx react-native start --reset-cache

# Linting
npm run lint

# Tests
npm test

# Réinstaller les pods après modification de dépendances
cd ios && bundle exec pod install && cd ..

# Ouvrir le projet dans Xcode
xed frontendios/ios/EdgeCoachIOS.xcworkspace
```

## Architecture du Projet

```text
frontendios/
├── App.tsx                    # Point d'entrée, providers (SafeAreaProvider, AuthProvider)
├── src/
│   ├── contexts/              # Context React (AuthContext)
│   ├── navigation/            # React Navigation configuration
│   │   ├── AppNavigator.tsx   # Navigation racine (Auth vs Main)
│   │   ├── AuthNavigator.tsx  # Stack login/register
│   │   ├── MainTabNavigator.tsx # Bottom tabs (Dashboard, Calendar, Coach, Stats, Profile)
│   │   └── types.ts           # Types de navigation TypeScript
│   ├── screens/               # Écrans de l'application
│   │   ├── auth/              # LoginScreen, RegisterScreen
│   │   ├── DashboardScreen.tsx
│   │   ├── CalendarScreen.tsx
│   │   ├── CoachChatScreen.tsx
│   │   ├── StatsScreen.tsx
│   │   ├── ProfileScreen.tsx
│   │   └── ...
│   ├── services/              # Services API (pattern identique au frontend web)
│   │   ├── api.ts             # Client Axios avec intercepteurs, retry, gestion erreurs
│   │   ├── userService.ts
│   │   ├── chatService.ts
│   │   ├── activitiesService.ts
│   │   └── ...
│   ├── components/            # Composants réutilisables (à développer)
│   │   ├── ui/
│   │   ├── charts/
│   │   └── common/
│   ├── theme/                 # Design tokens
│   │   ├── colors.ts          # Palette de couleurs EdgeCoach
│   │   ├── typography.ts      # Styles de texte
│   │   └── spacing.ts         # Espacements
│   ├── hooks/                 # Hooks personnalisés
│   ├── store/                 # Redux (prévu)
│   └── utils/                 # Utilitaires
├── ios/                       # Projet Xcode natif
└── android/                   # Projet Android (non prioritaire)
```

## Conventions de Code

### TypeScript/React Native

- **Composants** : `PascalCase`, fonctionnels avec hooks
- **Variables/fonctions** : `camelCase`
- **Types** : Interfaces TypeScript pour props et données
- **Styles** : `StyleSheet.create()` en fin de fichier
- **Navigation** : Types stricts via `RootStackParamList`

### Patterns importants

- **Services API** : Utilisent `apiService.get/post/put/delete` avec retry automatique
- **Authentification** : `AuthContext` gère l'état auth via AsyncStorage
- **Navigation conditionnelle** : `AppNavigator` affiche Auth ou Main selon `isAuthenticated`

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

### Vérification Obligatoire après Modification Frontend

**RÈGLE CRITIQUE : Après TOUTE modification de l'interface frontend (screens, components, navigation, styles), tu DOIS :**

1. Vérifier que le code compile sans erreurs TypeScript
2. Relancer l'application avec la commande :

```bash
npx react-native run-ios
```

3. Confirmer à l'utilisateur que l'app a été relancée et fonctionne

**Ne jamais considérer une modification frontend comme terminée sans avoir relancé l'app.**

### Processus de Modification

Pour toute modification :

1. **Analyser** le code existant et les impacts
2. **Proposer** 2-3 options avec avantages/inconvénients
3. **Attendre** la validation de l'utilisateur
4. **Découper** en étapes avec TodoWrite
5. **Exécuter** étape par étape
6. **Relancer** l'app iOS après chaque modification frontend

### Gestion des Sessions

Au démarrage de chaque conversation, lire `.context/current_session.md` si présent pour reprendre le contexte précédent.

## Points Techniques Clés

### Configuration API (src/services/api.ts)

- URL de base : `http://127.0.0.1:5002/api`
- Retry automatique avec exponential backoff (3 tentatives)
- Token JWT via `AsyncStorage.getItem('authToken')`
- Intercepteurs pour logging en `__DEV__`

### Navigation (src/navigation/)

- **AppNavigator** : Conteneur principal, switch Auth/Main
- **AuthNavigator** : Stack Navigator (Login → Register)
- **MainTabNavigator** : Bottom Tabs avec 5 onglets
- Écrans modaux : SessionDetail, Zones, Equipment

### Thème (src/theme/)

- Couleurs : `colors.primary`, `colors.sport.*`, `colors.neutral.*`
- Typography : fontSizes, fontWeights, lineHeights
- Spacing : scale de 0 à 80

### Connexion au backend

Pour tester sur appareil physique, remplacer `127.0.0.1` par l'IP locale du Mac dans `src/services/api.ts`.

## Tests

### Règle Obligatoire - Tests Unitaires

**RÈGLE CRITIQUE : Lors de la création ou modification de code, tu DOIS ajouter/mettre à jour les tests unitaires correspondants (sauf si la partie est déjà couverte par des tests existants).**

- **Nouveau service/hook/utilitaire** : Créer le fichier de test associé
- **Modification de logique existante** : Mettre à jour les tests SI la logique testée change
- **Nouveau composant** : Ajouter des tests si logique complexe
- **Code déjà testé** : Vérifier que les tests existants passent toujours

**Emplacement des tests :**

- Services : `src/services/__tests__/`
- Hooks : `src/hooks/__tests__/`
- Composants : `src/components/__tests__/` ou co-localisés
- Tests E2E : `e2e/flows/` (scénarios Maestro YAML)

**Commandes :**

```bash
# Lancer tous les tests unitaires
npm test

# Lancer tests E2E Maestro
maestro test e2e/flows/
```

### Tests E2E avec Maestro

Les scénarios E2E sont écrits en YAML dans `e2e/flows/`. Utiliser des `testID` sur les composants pour les identifier :

```tsx
<TouchableOpacity testID="login-button" onPress={handleLogin}>
```

## Commits et Pull Requests

- **Messages** : En français, format `[TYPE] Description courte`
- Types : `FEAT`, `FIX`, `REFACTOR`, `DOCS`, `TEST`, `STYLE`
- **Validation** : Demander confirmation avant chaque commit

## Migration depuis la Webapp

Voir `PLAN_MIGRATION_IOS.md` pour :

- Guide de conversion Web → Native (div→View, span→Text, etc.)
- Ordre de priorité des écrans à migrer
- Intégrations natives prévues (HealthKit, notifications push, OAuth natif)
