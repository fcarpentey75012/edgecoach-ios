# Plan de Migration React Native - EdgeCoach iOS

> **Projet** : EdgeCoach
> **Date de création** : 2025-11-26
> **Objectif** : Créer une application iOS native à partir de la webapp React existante
> **Stratégie** : Nouveau dossier `frontendios/` avec son propre repo Git

---

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Phase 1 : Préparation de l'environnement](#phase-1--préparation-de-lenvironnement)
3. [Phase 2 : Architecture et dépendances](#phase-2--architecture-et-dépendances)
4. [Phase 3 : Code partagé et services API](#phase-3--code-partagé-et-services-api)
5. [Phase 4 : Conversion des écrans](#phase-4--conversion-des-écrans)
6. [Phase 5 : Intégrations natives iOS](#phase-5--intégrations-natives-ios)
7. [Phase 6 : Tests et publication](#phase-6--tests-et-publication)
8. [Ressources et références](#ressources-et-références)

---

## Vue d'ensemble

### Pourquoi React Native ?

| Avantage | Description |
|----------|-------------|
| **Performance native** | Composants natifs iOS réels, pas une WebView |
| **Expérience utilisateur** | Look & feel natif Apple |
| **Accès complet aux APIs** | HealthKit, notifications push, OAuth natif |
| **Écosystème mature** | Large communauté, nombreuses librairies |

### Planning estimé

| Phase | Durée | Statut |
|-------|-------|--------|
| Phase 1 : Environnement | 1-2h | ✅ Fait |
| Phase 2 : Architecture | 2-3h | ⬜ À faire |
| Phase 3 : Code partagé | 1-2h | ⬜ À faire |
| Phase 4 : Écrans | 1-2 semaines | ⬜ À faire |
| Phase 5 : Intégrations | 3-5 jours | ⬜ À faire |
| Phase 6 : Publication | 3-5 jours | ⬜ À faire |

**Durée totale estimée : 3-4 semaines**

---

## Phase 1 : Préparation de l'environnement

### 1.1 Prérequis système

#### Vérifications initiales

```bash
# Vérifier Node.js (>= 18 requis)
node -v

# Vérifier npm (>= 9 requis)
npm -v

# Vérifier que Xcode est installé
xcode-select -p
```

#### Installations nécessaires

```bash
# 1. Installer les outils CLI Xcode
xcode-select --install

# 2. Installer CocoaPods (gestionnaire de dépendances iOS)
sudo gem install cocoapods

# 3. Installer Watchman (surveillance des fichiers, recommandé par Meta)
brew install watchman

# 4. Accepter la licence Xcode
sudo xcodebuild -license accept
```

#### Checklist prérequis

- [x] Node.js >= 18 installé
- [x] npm >= 9 installé
- [ ] Xcode >= 15.0 installé (via App Store)
- [ ] Xcode CLI tools installés
- [ ] CocoaPods installé
- [ ] Watchman installé
- [ ] Compte Apple Developer (pour publication)

### 1.2 Initialisation du projet ✅

Le projet a été initialisé avec :

```bash
npx @react-native-community/cli init EdgeCoachIOS --directory frontendios --skip-git-init
```

### 1.3 Première exécution

```bash
cd frontendios

# Installer les dépendances npm
npm install

# Installer les pods iOS
cd ios && bundle install && bundle exec pod install && cd ..

# Lancer sur simulateur iPhone
npx react-native run-ios

# Ou spécifier un simulateur
npx react-native run-ios --simulator="iPhone 15 Pro"
```

#### Résultat attendu
- ✅ Simulateur iPhone qui s'ouvre
- ✅ Application "EdgeCoachIOS" affichée
- ✅ Écran de bienvenue React Native

---

## Phase 2 : Architecture et dépendances

### 2.1 Dépendances à installer

#### Navigation

```bash
# React Navigation (équivalent React Router)
npm install @react-navigation/native @react-navigation/stack @react-navigation/bottom-tabs

# Dépendances peer
npm install react-native-screens react-native-safe-area-context react-native-gesture-handler

# Configuration iOS
cd ios && pod install && cd ..
```

#### État global (Redux)

```bash
# Vous utilisez déjà Redux Toolkit - même syntaxe !
npm install @reduxjs/toolkit react-redux
```

#### Requêtes API

```bash
# Axios (identique à la webapp)
npm install axios
```

#### Stockage local

```bash
# Équivalent localStorage
npm install @react-native-async-storage/async-storage
cd ios && pod install && cd ..
```

#### Styles (Tailwind pour React Native)

```bash
# NativeWind = Tailwind CSS pour React Native
npm install nativewind tailwindcss
npx tailwindcss init
```

#### Graphiques

```bash
# Victory Native (équivalent Recharts)
npm install react-native-svg victory-native
cd ios && pod install && cd ..
```

#### Cartes

```bash
# Pour afficher les parcours GPX
npm install react-native-maps
cd ios && pod install && cd ..
```

#### Icônes

```bash
npm install react-native-vector-icons
cd ios && pod install && cd ..
```

#### Variables d'environnement

```bash
npm install react-native-config
cd ios && pod install && cd ..
```

### 2.2 Configuration NativeWind (Tailwind)

Créer/modifier `tailwind.config.js` :

```javascript
// tailwind.config.js
module.exports = {
  content: [
    "./App.{js,jsx,ts,tsx}",
    "./src/**/*.{js,jsx,ts,tsx}"
  ],
  theme: {
    extend: {
      colors: {
        // Couleurs EdgeCoach (reprendre de frontend/)
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
        },
        secondary: {
          500: '#10b981',
          600: '#059669',
        },
      },
    },
  },
  plugins: [],
}
```

Modifier `babel.config.js` :

```javascript
// babel.config.js
module.exports = {
  presets: ['module:metro-react-native-babel-preset'],
  plugins: ["nativewind/babel"],
};
```

### 2.3 Structure des dossiers

```
frontendios/
├── ios/                          # Projet Xcode (généré automatiquement)
├── android/                      # Projet Android (peut être supprimé si iOS uniquement)
├── src/
│   ├── components/               # Composants réutilisables
│   │   ├── ui/                   # Boutons, inputs, cards, modals
│   │   ├── charts/               # Graphiques d'entraînement
│   │   └── common/               # Header, Footer, Loading
│   │
│   ├── screens/                  # Écrans (= pages/ dans webapp)
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── training-calendar/
│   │   ├── ai-coach-chat/
│   │   └── training-plan-creator/
│   │
│   ├── navigation/               # Configuration navigation
│   │   ├── AppNavigator.tsx
│   │   ├── AuthNavigator.tsx
│   │   └── MainNavigator.tsx
│   │
│   ├── store/                    # Redux (structure identique à frontend/)
│   │   ├── index.ts
│   │   └── slices/
│   │
│   ├── services/                 # Services API
│   │   ├── api.ts
│   │   ├── authService.ts
│   │   ├── trainingService.ts
│   │   └── conversationService.ts
│   │
│   ├── hooks/                    # Hooks personnalisés
│   │   ├── useAuth.ts
│   │   ├── useTraining.ts
│   │   └── useHealthKit.ts
│   │
│   ├── utils/                    # Utilitaires
│   │   ├── formatters.ts
│   │   ├── validators.ts
│   │   └── constants.ts
│   │
│   └── theme/                    # Thème et styles globaux
│       ├── colors.ts
│       ├── typography.ts
│       └── spacing.ts
│
├── __tests__/                    # Tests
├── App.tsx                       # Point d'entrée
├── app.json                      # Configuration app
├── babel.config.js
├── metro.config.js
├── package.json
├── tailwind.config.js
├── tsconfig.json
└── PLAN_MIGRATION_IOS.md         # Ce fichier
```

---

## Phase 3 : Code partagé et services API

### 3.1 Configuration du client API

Créer `src/services/api.ts` :

```typescript
// src/services/api.ts
import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';

// URL selon l'environnement
const API_URL = __DEV__
  ? 'http://localhost:5002/api'      // Développement
  : 'https://api.edgecoach.app/api'; // Production

export const apiClient = axios.create({
  baseURL: API_URL,
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Intercepteur pour ajouter le token d'authentification
apiClient.interceptors.request.use(
  async (config) => {
    const token = await AsyncStorage.getItem('authToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Intercepteur pour gérer les erreurs
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      await AsyncStorage.removeItem('authToken');
    }
    return Promise.reject(error);
  }
);

export default apiClient;
```

### 3.2 Services réutilisables

```typescript
// src/services/trainingService.ts
import apiClient from './api';

export const trainingService = {
  getSessions: async (startDate: string, endDate: string) => {
    const response = await apiClient.get('/training/sessions', {
      params: { start_date: startDate, end_date: endDate }
    });
    return response.data;
  },

  getPlan: async (planId: string) => {
    const response = await apiClient.get(`/training/plans/${planId}`);
    return response.data;
  },

  createPlan: async (planData: any) => {
    const response = await apiClient.post('/training/plans', planData);
    return response.data;
  },
};
```

### 3.3 Configuration Redux Store

```typescript
// src/store/index.ts
import { configureStore } from '@reduxjs/toolkit';
import authReducer from './slices/authSlice';
import userReducer from './slices/userSlice';
import trainingReducer from './slices/trainingSlice';

export const store = configureStore({
  reducer: {
    auth: authReducer,
    user: userReducer,
    training: trainingReducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: false,
    }),
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
```

---

## Phase 4 : Conversion des écrans

### 4.1 Guide de conversion Web → Native

| Web (React) | Native (React Native) | Notes |
|-------------|----------------------|-------|
| `<div>` | `<View>` | Container de base |
| `<span>`, `<p>` | `<Text>` | **Obligatoire** pour tout texte |
| `<img src="...">` | `<Image source={{uri: ...}}>` | Syntaxe différente |
| `<button>` | `<TouchableOpacity>` | ou `<Pressable>` |
| `<input>` | `<TextInput>` | Props différentes |
| `<ul>`, `<li>` | `<FlatList>` | Optimisé pour listes |
| `onClick` | `onPress` | Événement tactile |
| `className="..."` | `className="..."` | Avec NativeWind |

### 4.2 Ordre de migration recommandé

#### Priorité 1 : Infrastructure (Jour 1-2)
- [ ] Navigation principale (Tab + Stack)
- [ ] Écran de login/authentification
- [ ] Layout de base (Header, etc.)

#### Priorité 2 : Écrans principaux (Jour 3-7)
- [ ] Dashboard (métriques, résumé)
- [ ] Calendrier d'entraînement
- [ ] Détail d'une séance

#### Priorité 3 : Fonctionnalités avancées (Semaine 2)
- [ ] Chat IA Coach
- [ ] Créateur de plan d'entraînement
- [ ] Visualisation des parcours (carte)

#### Priorité 4 : Polish (Semaine 2-3)
- [ ] Animations et transitions
- [ ] Gestion offline
- [ ] Optimisations performance

### 4.3 Exemple : Écran de Chat

```tsx
// src/screens/ai-coach-chat/ChatScreen.tsx
import React, { useState } from 'react';
import { View, Text, TextInput, FlatList, TouchableOpacity, KeyboardAvoidingView, Platform } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

interface Message {
  id: string;
  content: string;
  isUser: boolean;
  timestamp: Date;
}

const ChatScreen: React.FC = () => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState('');

  const sendMessage = () => {
    if (!inputText.trim()) return;

    const newMessage: Message = {
      id: Date.now().toString(),
      content: inputText,
      isUser: true,
      timestamp: new Date(),
    };

    setMessages([...messages, newMessage]);
    setInputText('');
    // TODO: Appeler l'API du coach IA
  };

  const renderMessage = ({ item }: { item: Message }) => (
    <View className={`flex ${item.isUser ? 'items-end' : 'items-start'} mb-3 px-4`}>
      <View className={`max-w-[80%] p-3 rounded-2xl ${
        item.isUser ? 'bg-blue-500' : 'bg-gray-200'
      }`}>
        <Text className={item.isUser ? 'text-white' : 'text-gray-800'}>
          {item.content}
        </Text>
      </View>
    </View>
  );

  return (
    <SafeAreaView className="flex-1 bg-white">
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        className="flex-1"
      >
        <View className="px-4 py-3 border-b border-gray-200">
          <Text className="text-xl font-bold text-center">Coach IA</Text>
        </View>

        <FlatList
          data={messages}
          renderItem={renderMessage}
          keyExtractor={(item) => item.id}
          className="flex-1"
          contentContainerStyle={{ paddingVertical: 16 }}
        />

        <View className="flex-row items-center px-4 py-2 border-t border-gray-200">
          <TextInput
            className="flex-1 bg-gray-100 rounded-full px-4 py-2 mr-2"
            placeholder="Posez votre question..."
            value={inputText}
            onChangeText={setInputText}
            onSubmitEditing={sendMessage}
          />
          <TouchableOpacity onPress={sendMessage} className="bg-blue-500 rounded-full p-3">
            <Text className="text-white font-semibold">Envoyer</Text>
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
};

export default ChatScreen;
```

---

## Phase 5 : Intégrations natives iOS

### 5.1 HealthKit (Données Apple Santé)

#### Installation

```bash
npm install react-native-health
cd ios && pod install && cd ..
```

#### Configuration Xcode

1. Ouvrir `ios/EdgeCoachIOS.xcworkspace`
2. Signing & Capabilities → "+ Capability" → "HealthKit"

#### Info.plist

```xml
<key>NSHealthShareUsageDescription</key>
<string>EdgeCoach a besoin d'accéder à vos données de santé pour suivre vos entraînements.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>EdgeCoach peut enregistrer vos séances dans Apple Santé.</string>
```

#### Code

```typescript
// src/services/healthKit.ts
import AppleHealthKit from 'react-native-health';

const permissions = {
  permissions: {
    read: [
      AppleHealthKit.Constants.Permissions.HeartRate,
      AppleHealthKit.Constants.Permissions.DistanceCycling,
      AppleHealthKit.Constants.Permissions.DistanceSwimming,
      AppleHealthKit.Constants.Permissions.DistanceWalkingRunning,
      AppleHealthKit.Constants.Permissions.Workout,
    ],
    write: [AppleHealthKit.Constants.Permissions.Workout],
  },
};

export const initHealthKit = (): Promise<boolean> => {
  return new Promise((resolve, reject) => {
    AppleHealthKit.initHealthKit(permissions, (error) => {
      if (error) reject(error);
      else resolve(true);
    });
  });
};

export const getWorkouts = (startDate: Date, endDate: Date): Promise<any[]> => {
  return new Promise((resolve, reject) => {
    AppleHealthKit.getSamples({
      type: 'Workout',
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString(),
    }, (err, results) => {
      if (err) reject(err);
      else resolve(results);
    });
  });
};
```

### 5.2 Notifications Push

```bash
npm install @react-native-firebase/app @react-native-firebase/messaging
cd ios && pod install && cd ..
```

### 5.3 OAuth Natif (Wahoo, Withings)

```bash
npm install react-native-app-auth
cd ios && pod install && cd ..
```

```typescript
// src/services/oauth.ts
import { authorize } from 'react-native-app-auth';

const wahooConfig = {
  clientId: 'VOTRE_WAHOO_CLIENT_ID',
  redirectUrl: 'edgecoach://oauth/wahoo/callback',
  scopes: ['user_read', 'workouts_read'],
  serviceConfiguration: {
    authorizationEndpoint: 'https://api.wahooligan.com/oauth/authorize',
    tokenEndpoint: 'https://api.wahooligan.com/oauth/token',
  },
};

export const loginWithWahoo = async () => {
  const result = await authorize(wahooConfig);
  return result.accessToken;
};
```

---

## Phase 6 : Tests et publication

### 6.1 Tests

```bash
# Simulateur
npx react-native run-ios

# Appareil réel
npx react-native run-ios --device

# Build release
npx react-native run-ios --configuration Release
```

### 6.2 Publication App Store

1. Créer compte Apple Developer (99€/an)
2. Configurer signing dans Xcode
3. Créer l'app sur App Store Connect
4. Archive et upload via Xcode

### 6.3 Checklist pré-soumission

- [ ] Tests sur plusieurs appareils
- [ ] Tests d'accessibilité (VoiceOver)
- [ ] Vérification des permissions
- [ ] Test du flux OAuth complet
- [ ] Icônes et screenshots prêts

---

## Ressources et références

- [React Native Docs](https://reactnative.dev/docs/getting-started)
- [React Navigation](https://reactnavigation.org/)
- [NativeWind](https://www.nativewind.dev/)
- [Apple HealthKit](https://developer.apple.com/documentation/healthkit)
- [App Store Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

## Commandes utiles

```bash
# Lancer l'app iOS
npx react-native run-ios

# Lancer Metro bundler seul
npx react-native start

# Reset cache Metro
npx react-native start --reset-cache

# Installer pods
cd ios && bundle exec pod install && cd ..

# Ouvrir dans Xcode
xed ios/EdgeCoachIOS.xcworkspace

# Lister les simulateurs
xcrun simctl list devices
```

---

> **Dernière mise à jour** : 2025-11-26
