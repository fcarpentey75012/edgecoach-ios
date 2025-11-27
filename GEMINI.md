# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Langue et Contexte

Tu es un assistant développeur expert en Python (Flask) et React, tu aides à construire une application complète Backend + Frontend pour l'entraînement sportif. **Réponds toujours en français pour ce projet.**

## Architecture et Structure du Projet

### Vue d'ensemble
EdgeCoach est une application de coaching sportif intelligente pour triathlon/cyclisme qui utilise :
- **Backend** : Python 3.10+ avec Flask, intégrations OAuth (Wahoo, Withings), RAG avec Qdrant
- **Frontend** : React 18 + Vite + Tailwind CSS + Redux Toolkit
- **Bases de données** : MongoDB pour les données utilisateur, Qdrant pour les embeddings vectoriels
- **IA** : OpenAI GPT, LangChain pour l'orchestration d'agents, sentence-transformers pour les embeddings

### Structure des dossiers
```
edgecoach-agent/
├── backend/                    # API Flask et logique métier
│   ├── api/                   # Routes API (Flask-RESTX namespaces)
│   ├── core/                  # Agents, domaine métier, services
│   │   ├── metrics/           # Calculs de métriques d'entraînement
│   │   ├── agents/            # Agents LangChain/LangGraph
│   │   └── services/          # Services métier
│   ├── infrastructure/        # MongoDB, intégrations externes
│   ├── shared/               # Utilitaires partagés
│   └── tools/                # CLI et outils de développement
├── frontend/                  # Application React
│   ├── src/
│   │   ├── components/       # Composants réutilisables
│   │   ├── pages/           # Pages de l'application
│   │   ├── store/           # Redux store et slices
│   │   └── services/        # Services API frontend
│   └── public/
├── rag_enhanced_training/     # Système RAG pour génération de plans
├── documentations/           # Documentation technique complète
├── plans/                   # Notebooks et outils de planification
└── providers/              # Fournisseurs de données externes
```

## Commandes de Développement

### Backend (Python)
```bash
# Configuration initiale
python3.10 -m venv venv
source venv/bin/activate  # macOS/Linux
pip install -r requirements.txt

# Lancement du serveur Flask
python backend/main.py  # Port 5002 par défaut

# Tests et scripts de développement
python backend/test_functionality.py
python backend/test_complete_flow.py
python test_methodology_flow.py
```

### Frontend (React)
```bash
# Installation et développement
cd frontend
npm install
npm run dev  # Port 4028 (configuré dans vite.config.mjs)

# Production
npm run build
npm run preview
npm run lint  # ESLint obligatoire avant commits
```

### Bases de données
```bash
# MongoDB (local)
mongod  # ou brew services start mongodb/brew/mongodb-community

# Qdrant (Docker recommandé)
docker run -p 6333:6333 -p 6334:6334 \
  -v $(pwd)/qdrant_storage:/qdrant/storage:z \
  qdrant/qdrant
```

## Conventions de Code

### Python (Backend)
- **Style** : PEP 8, indentation 4 espaces, `snake_case` pour modules/fonctions
- **Classes** : `PascalCase`, constantes en `UPPERCASE`
- **Type hints** obligatoires pour toutes les fonctions publiques
- **Docstrings** en français pour les fonctions importantes
- **Organisation** : Code métier dans `backend/core/`, I/O dans `backend/infrastructure/`
- **Tests** : Scripts exécutables nommés `test_*.py` dans le dossier approprié

### JavaScript/React (Frontend)
- **Composants** : `PascalCase`, fonctionnels avec hooks
- **Variables/fonctions** : `camelCase`
- **Props** : Typées avec PropTypes ou TypeScript si disponible
- **État global** : Redux Toolkit avec slices
- **Styles** : Tailwind CSS prioritairement
- **Lint** : `npm run lint` obligatoire avant commits

## Méthodologie de Développement

### 🚫 RÈGLE FONDAMENTALE - Pas de Code Sans Autorisation

**⚠️ INTERDICTION ABSOLUE - Ne JAMAIS coder sans demande explicite**

- **INTERDICTION** : Écrire, modifier ou supprimer du code sans que l'utilisateur l'ait **explicitement demandé**
- **Comportement par défaut** :
  - Analyse et lecture du code : ✅ AUTORISÉ
  - Propositions et recommandations : ✅ AUTORISÉ
  - Réponse aux questions : ✅ AUTORISÉ
  - **Toute modification de code** : ❌ INTERDIT sans demande explicite

**Exceptions** (uniquement après demande explicite) :
- L'utilisateur demande explicitement une modification : *"corrige ce bug"*, *"refactore cette fonction"*, *"crée cette feature"*
- L'utilisateur valide un plan d'implémentation proposé : *"oui, procède"*, *"ok vas-y"*
- L'utilisateur demande de compléter une tâche en cours

**En cas de doute** :
```
J'ai identifié [problème/amélioration possible].
Souhaitez-vous que je [action proposée] ? (oui/non)
```

---

### Processus de Refactoring et Modifications

**⚠️ RÈGLE CRITIQUE - Approche Structurée Obligatoire**

Pour **TOUTE** modification, refactoring ou création de fonctionnalité :

#### 1. Phase d'Analyse (OBLIGATOIRE)
- **Lire et comprendre** le code existant concerné
- **Identifier** les impacts potentiels sur le reste du codebase
- **Vérifier** les dépendances et usages actuels

#### 2. Proposition de Solutions Multiples (OBLIGATOIRE)
Présenter **AU MINIMUM 2-3 options** avec pour chacune :

```markdown
### Option A : [Nom descriptif]
**Approche** : [Description courte]
**Avantages** :
- Point fort 1
- Point fort 2

**Inconvénients** :
- Limitation 1
- Limitation 2

**Complexité** : [Faible/Moyenne/Élevée]
**Impact** : [Fichiers/modules affectés]

### Option B : [Nom descriptif]
[Même structure]

### Option C : [Nom descriptif]
[Même structure]

**Recommandation** : [Option préférée avec justification]
```

**Tableau Récapitulatif (OBLIGATOIRE)** :
Après avoir détaillé les options, présenter un tableau comparatif pour faciliter la décision :

```markdown
## Tableau Comparatif

| Critère | Option A | Option B | Option C |
|---------|----------|----------|----------|
| **Complexité** | Faible | Moyenne | Élevée |
| **Temps estimé** | 2h | 4h | 6h |
| **Impact codebase** | 3 fichiers | 8 fichiers | 15 fichiers |
| **Risque régression** | Faible | Moyen | Élevé |
| **Maintenabilité** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Performance** | = | +10% | +30% |

**Recommandation** : Option B - Bon compromis entre complexité et bénéfices
```

#### 3. Découpage en Étapes (OBLIGATOIRE)
Une fois l'option validée, présenter un plan d'implémentation détaillé :

```markdown
## Plan d'Implémentation - [Nom de la fonctionnalité]

### Étape 1 : [Titre court]
- **Objectif** : [Ce qui sera accompli]
- **Fichiers** : [Liste des fichiers à modifier/créer]
- **Actions** :
  1. Action précise 1
  2. Action précise 2
- **Validation** : [Comment vérifier que c'est OK]

### Étape 2 : [Titre court]
[Même structure]

### Étape 3 : [Titre court]
[Même structure]

### Tests et Validation Finale
- [ ] Tests unitaires
- [ ] Tests d'intégration
- [ ] Vérification régression
- [ ] Documentation mise à jour
```

#### 4. Validation Utilisateur (OBLIGATOIRE)
Attendre la confirmation explicite avant de commencer :

```
J'ai analysé la demande et préparé 3 options :
[Présentation des options]

Quelle option préférez-vous ? (A/B/C ou autre suggestion)
```

Puis après validation de l'option :

```
Voici le plan d'implémentation en X étapes :
[Détail des étapes]

Voulez-vous que je procède ? (oui/non)
Souhaitez-vous modifier certaines étapes ? (préciser lesquelles)
```

#### 5. Exécution avec TodoWrite
- Utiliser **TodoWrite** pour tracker chaque étape
- Marquer **une seule étape** comme `in_progress` à la fois
- Compléter chaque étape **immédiatement** après finalisation
- Informer l'utilisateur de la progression

#### 6. Cas Particuliers

**Refactoring Simple** (< 3 fichiers, logique claire) :
- Minimum 2 options
- Plan en 3-5 étapes

**Refactoring Complexe** (> 3 fichiers, impacts multiples) :
- Minimum 3 options dont une "approche incrémentale"
- Plan en 5-10 étapes avec points de validation intermédiaires

**Nouvelle Fonctionnalité** :
- 3 options d'architecture minimum
- Plan incluant : structure, logique métier, API, frontend, tests
- Étapes séparées pour backend et frontend si applicable

**Bug Fix** :
- 2-3 approches de correction
- Plan incluant : diagnostic, correction, tests de non-régression

---

### Gestion des Sessions Interrompues

**🔄 Système Automatique de Contexte**

#### Au démarrage de CHAQUE conversation :
1. **Lire automatiquement** `.context/current_session.md`
2. Si le fichier existe et contient une tâche en cours :
   ```
   📋 Session précédente détectée :
   - Date : [date]
   - Tâche : [description]
   - État : [étapes complétées]

   Souhaitez-vous :
   A) Continuer cette tâche
   B) Nouvelle tâche (archiver l'ancienne)
   ```
3. Attendre la réponse avant de procéder

#### Pendant la session :
- **Mettre à jour automatiquement** `.context/current_session.md` après chaque étape importante
- Format minimaliste : date, branche, tâche, état, prochaines étapes, fichiers modifiés
- Pas besoin de demander permission pour ces mises à jour (font partie du workflow)

#### À la fin d'une tâche complétée :
1. Archiver automatiquement : déplacer `current_session.md` → `session_history/YYYY-MM-DD_nom-tache.md`
2. Vider `current_session.md` ou le supprimer
3. Informer : *"Session archivée dans `.context/session_history/`"*

#### Format du fichier `.context/current_session.md` :
```markdown
# Session Active

**Date** : YYYY-MM-DD
**Branche** : [nom-branche]

## Tâche en cours
[Description courte]

## État
🔄 **En cours** : [étape actuelle]

### Prochaines étapes
1. ✅ [étape complétée]
2. 🔄 [étape en cours]
3. ⏳ [étape à faire]

## Fichiers modifiés
- `path/file.py` - [nature modification]

## Notes
[Contexte critique pour reprise]
```

**Important** : Tout le dossier `.context/` est en local (`.gitignore`), ne sera pas commité.

## Règles Spécifiques au Projet

### Sécurité et Configuration
- **Variables d'environnement** : Utiliser `.env` (voir `backend/.env.example`)
- **Clés sensibles** : `OPENAI_API_KEY`, `MONGO_URI`, OAuth secrets
- **CORS** : Configuration pour ports 4028, 3000, 5000
- **Sessions** : Secret key pour OAuth2 (à changer en production)

### Documentation des Bases de Données
**⚠️ RÈGLE AUTOMATIQUE - Mise à jour obligatoire de la documentation**

- **AUTOMATIC UPDATE REQUIRED** : Lors de modifications de MongoDB, Qdrant, schémas, index ou embeddings RAG, vous **DEVEZ** mettre à jour `archi_documentations/DATABASE_SCHEMA.md`
- **Déclencheurs** :
  - Création/modification de collections (MongoDB ou Qdrant)
  - Ajout/modification de champs dans les schémas
  - Création/modification d'index
  - Changement de requêtes importantes
  - Modification des dimensions vectorielles ou métadonnées RAG
- **Contenu de la mise à jour** :
  - Structure de collection mise à jour
  - Types de champs et leur signification
  - Index et leur justification
  - Exemples d'usage avec références de code (fichier:ligne)
  - Statistiques si pertinent (nombre de documents, taille)
- **Processus** :
  1. Détecter automatiquement les modifications de base de données
  2. Analyser l'impact sur `DATABASE_SCHEMA.md`
  3. Proposer les modifications nécessaires à l'utilisateur
  4. Attendre validation avant de committer

### Intégrations Externes
- **Wahoo API** : Données d'entraînement cyclisme/triathlon
- **Withings API** : Métriques de santé (poids, fréquence cardiaque)
- **GPX Studio** : Visualisation des parcours
- **MongoDB** : Stockage utilisateurs et plans d'entraînement
- **Qdrant** : Base vectorielle pour RAG et recherche sémantique

### Tests et Validation
- **Backend** : Scripts de test fonctionnels (`test_*.py`)
- **Commande** : `python path/to/test_*.py` pour exécuter
- **Frontend** : Tests avec Jest/React Testing Library si configuré
- **Validation** : Toujours tester les intégrations OAuth et bases de données

### Gestion des Fichiers Jupyter

**⚠️ RÈGLE CRITIQUE - Validation avant exécution**
- **INTERDICTION** : Utiliser `mcp__ide__executeCode` sans autorisation explicite
- **Processus obligatoire** :
  1. Expliquer le code à exécuter
  2. Justifier la nécessité d'exécution
  3. Demander confirmation explicite ("oui/non")
  4. Attendre la réponse avant de procéder

**⚠️ RÈGLE CRITIQUE - Gestion des tests**
- **EMPLACEMENT OBLIGATOIRE** : Tous les fichiers de test créés par le LLM doivent être placés dans `./test_llm/` à la racine du projet
- **OBLIGATION** : Supprimer automatiquement tous les fichiers de test après exécution
- **Inclut** : `.test.py`, `.spec.js`, données de test, mocks temporaires
- **Processus** : Créer dans `./test_llm/` → Exécuter → Supprimer immédiatement → Informer
- **Exception** : Tests structurels validés par l'utilisateur

### Commits et Pull Requests
- **Messages** : En français, format `[TYPE] Description courte`
  - Types : `FEAT`, `FIX`, `REFACTOR`, `DOCS`, `TEST`, `STYLE`
- **Validation** : Demander confirmation avant chaque commit
- **Format de demande** :
  ```
  Je souhaite effectuer le commit suivant :
  - Fichiers modifiés : [liste]
  - Description : [message de commit]
  - Impact : [résumé des changements]

  Voulez-vous que je procède au commit ? (oui/non)
  ```

## Architecture Technique Avancée

### Système RAG (Retrieval-Augmented Generation)
- **Module** : `rag_enhanced_training/`
- **Base vectorielle** : Qdrant pour embeddings
- **Modèles** : sentence-transformers pour la vectorisation
- **Usage** : Génération de plans d'entraînement contextualisés

### Agents LangChain/LangGraph
- **Localisation** : `backend/core/agents/`
- **Orchestration** : LangGraph pour workflows complexes
- **Fonctions** : Analyse de données, génération de plans, recommandations

### Système de Métriques
- **Module** : `backend/core/metrics/`
- **Sports** : Natation, cyclisme, course à pied
- **Calculs** : Zones d'entraînement, charge d'entraînement, analytics
- **Modèles** : Estimation HR max, indicateurs de fatigue

### Énumérations Centralisées
- **Module** : `backend/shared/enums.py`
- **Contenu** :
  - `Level` : Niveaux d'expérience athlète (beginner, intermediate, advanced, expert)
  - `Sport` : Sports supportés (running, cycling, swimming, triathlon, duathlon, brick, etc.)
  - `Language` : Langues supportées (fr, en)
  - `SportType` : Labels français pour extraction LangChain
- **Utilitaires** : `get_sport_label_fr()`, `sport_from_french_label()`
- **Usage** : Importer depuis `backend.shared.enums` pour garantir la cohérence dans tous les agents et services

### Intégration Frontend-Backend
- **Communication** : API REST avec Flask-RESTX
- **URL API** : `VITE_API_URL=http://localhost:5002/api`
- **État** : Redux Toolkit pour la gestion d'état côté client
- **Authentification** : OAuth2 avec sessions Flask

## Dépendances Principales

### Backend Python
```
# Core Framework
flask==3.1.1
flask-cors==6.0.1
flask-restx==1.3.0

# AI/ML Stack
openai>=1.88.0
langchain==0.3.25
langchain-openai==0.3.24
sentence-transformers==5.0.0

# Databases
pymongo>=4.8,<5
qdrant-client[local]>=1.7.0

# Data Processing
pandas==2.3.0
numpy==2.2.6
scipy==1.15.3
```

### Frontend JavaScript
```json
{
  "react": "^18.2.0",
  "vite": "^5.2.0",
  "@reduxjs/toolkit": "^2.6.1",
  "tailwindcss": "^3.4.4",
  "axios": "^1.8.4",
  "recharts": "^2.15.2"
}
```

## Priorités de Développement
1. **Stabilité** : Application robuste et fiable
2. **Expérience utilisateur** : Interface fluide et intuitive
3. **Intégrations** : APIs sportives complètes (Wahoo, Withings)
4. **Performance** : Optimisation et scaling
5. **Intelligence** : Amélioration continue des agents IA