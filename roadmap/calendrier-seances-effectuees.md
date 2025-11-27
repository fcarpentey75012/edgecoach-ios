# Roadmap - Calendrier & Séances Effectuées

> Améliorations proposées pour l'affichage des séances effectuées dans le calendrier EdgeCoach iOS

---

## Vue d'ensemble

Cette roadmap détaille les fonctionnalités proposées pour enrichir l'expérience utilisateur lors de la consultation des séances effectuées. Toutes les données nécessaires sont déjà disponibles via l'API backend existante.

---

## 1. Comparaison Prévu vs Réalisé ✅ IMPLÉMENTÉ

**Priorité : 🔴 Haute**
**Complexité : Moyenne**
**Impact UX : Très élevé**
**Statut : ✅ Implémenté le 27/11/2025**
**Fichier : `src/components/session/PlannedVsActualComparison.tsx`**

### Description
Afficher côte à côte les données planifiées et réalisées pour chaque séance, avec calcul automatique des écarts.

### Données à afficher

| Métrique | Prévu | Réalisé | Écart |
|----------|-------|---------|-------|
| Durée | 1h30 | 1h42 | +12min (+13%) |
| Distance | 40km | 43.2km | +3.2km (+8%) |
| Intensité | Zone 2 | Zone 2-3 | - |
| TSS estimé | 85 | 92 | +7 (+8%) |

### Fonctionnalités
- Score de conformité global (ex: "94% de respect du plan")
- Code couleur : vert (dans les clous), orange (écart modéré), rouge (écart important)
- Explication textuelle des écarts significatifs

### API utilisée
- `GET /api/activities/history` → données réalisées
- `GET /api/plans/last` → données planifiées
- Matching par date + sport

---

## 2. Graphiques de Zones Inline ✅ IMPLÉMENTÉ

**Priorité : 🔴 Haute**
**Complexité : Moyenne**
**Impact UX : Très élevé**
**Statut : ✅ Implémenté le 27/11/2025**
**Fichier : `src/components/session/ZonesChart.tsx`**

### Description
Intégrer des visualisations graphiques directement dans le détail de séance pour une compréhension immédiate de l'effort.

### Graphiques proposés
1. **Répartition temps en zones** - Barres horizontales empilées (Z1→Z7)
2. **Courbe de puissance/FC** - Graphique linéaire sur la durée
3. **Allure par kilomètre** - Bar chart pour la course
4. **Profil altimétrique** - Courbe simplifiée avec D+/D-

### Données disponibles
```javascript
activity.zones = [
  { zone: 1, time_seconds: 1200, percentage: 25 },
  { zone: 2, time_seconds: 1800, percentage: 37.5 },
  // ...
]
activity.file_datas.records = [...] // Points GPS temporels
```

### Librairie suggérée
- `react-native-chart-kit` ou `victory-native`

---

## 3. Vue Semaine avec Résumé Hebdomadaire ✅ IMPLÉMENTÉ

**Priorité : 🟠 Moyenne**
**Complexité : Moyenne**
**Impact UX : Élevé**
**Statut : ✅ Implémenté le 27/11/2025**
**Fichier : `src/components/calendar/WeekSummary.tsx`**

### Description
Nouvelle vue optionnelle (toggle semaine/mois) avec synthèse hebdomadaire des entraînements.

### Éléments affichés
- **Volume total** : heures et km par discipline
- **Charge totale** (TSS/ATL) avec graphique en barres
- **Répartition par zone** : camembert global de la semaine
- **Ratio prévu/réalisé** : pourcentage de respect du plan
- **Nombre de séances** par discipline avec icônes

### Maquette conceptuelle
```
┌─────────────────────────────────────────┐
│  Semaine 47 (18-24 Nov)     [< >]       │
├─────────────────────────────────────────┤
│  Volume: 8h45  │  TSS: 425  │  6 séances│
├─────────────────────────────────────────┤
│  🚴 4h30 (120km)  🏃 3h15 (35km)  🏊 1h │
├─────────────────────────────────────────┤
│  [========== Zones ===========]         │
│  Z1 ██░░░░ Z2 ████░░ Z3 ██░░ Z4+ █░    │
├─────────────────────────────────────────┤
│  Conformité plan: 87%  ●●●●●●●●○○      │
└─────────────────────────────────────────┘
```

---

## 4. Analyse Rapide Intégrée

**Priorité : 🟠 Moyenne**
**Complexité : Faible** (API existante)
**Impact UX : Élevé**

### Description
Bouton "Analyser" sur chaque séance effectuée qui déclenche une analyse IA contextuelle.

### API existante
```javascript
POST /api/analysis/session
{
  session_id: "...",
  analysis_type: "quick_analysis", // ou "complete_analysis"
  user_id: "..."
}
```

### Types d'analyse disponibles
- **Analyse rapide** : Points clés en 30 secondes
- **Analyse complète** : Détails techniques approfondis
- **Analyse technique** : Focus sur la gestuelle/efficacité
- **Analyse comparative** : Comparaison avec séances similaires

### Affichage
- Section pliable/dépliable sous les métriques
- Formatage markdown du résultat
- Cache local pour éviter les appels répétés

---

## 5. Métriques Avancées par Sport ✅ IMPLÉMENTÉ

**Priorité : 🟠 Moyenne**
**Complexité : Faible**
**Impact UX : Élevé**
**Statut : ✅ Implémenté le 27/11/2025**
**Fichier : `src/components/session/AdvancedMetrics.tsx`**

### Description
Afficher des métriques spécialisées selon la discipline, calculées à partir des données existantes.

### Cyclisme
| Métrique | Description | Source |
|----------|-------------|--------|
| Puissance Normalisée (NP) | Moyenne pondérée de la puissance | `activity.np` |
| Intensity Factor (IF) | NP / FTP | `activity.file_datas.if_` |
| Variability Index (VI) | NP / Puissance moyenne | Calculé |
| Cadence moyenne | Tours de pédale/min | `activity.file_datas.cadence_avg` |
| Travail total | Énergie dépensée | `activity.kilojoules` |

### Course à pied
| Métrique | Description | Source |
|----------|-------------|--------|
| Allure moyenne | min/km | Calculé depuis distance/durée |
| Allure en mouvement | Sans les pauses | `activity.file_datas.avg_speed_moving_kmh` |
| GAP (Grade Adjusted Pace) | Allure corrigée dénivelé | À calculer |
| Cadence | Pas/min | `activity.file_datas.cadence_avg` |
| Longueur de foulée | Estimée | Calculé |

### Natation
| Métrique | Description | Source |
|----------|-------------|--------|
| Temps aux 100m | Allure de référence | Calculé |
| SWOLF | Efficacité de nage | À implémenter |
| Fréquence de bras | Coups/min | Si disponible |

---

## 6. Indicateurs Visuels Calendrier Enrichis ✅ IMPLÉMENTÉ

**Priorité : 🟡 Basse**
**Complexité : Faible**
**Impact UX : Moyen**
**Statut : ✅ Implémenté le 27/11/2025**
**Fichier : `src/screens/CalendarScreen.tsx` (indicateurs avec anneau d'intensité)**

### Description
Améliorer les indicateurs visuels sur la grille du calendrier pour une lecture rapide.

### Améliorations proposées

#### Intensité par couleur
```
TSS < 50  → Vert clair (récupération)
TSS 50-100 → Vert (endurance)
TSS 100-150 → Orange (tempo/seuil)
TSS > 150 → Rouge (haute intensité)
```

#### Indicateur de conformité
- ✓ Vert : Séance conforme au plan (écart < 15%)
- ⚠️ Orange : Écart modéré (15-30%)
- ✗ Rouge : Écart important (> 30%) ou séance manquée

#### Mini-barre de volume
```
Jour avec 2h d'entraînement:
┌───┐
│ ● │  ← Point sport
│▓▓▓│  ← Barre proportionnelle
└───┘
```

#### Badge streak
- Afficher le nombre de jours consécutifs d'entraînement
- Animation spéciale à 7 jours, 30 jours, etc.

---

## 7. Comparaison Historique Intelligente

**Priorité : 🟡 Basse**
**Complexité : Moyenne**
**Impact UX : Moyen**

### Description
Permettre la comparaison d'une séance avec des séances similaires passées.

### API existante
```javascript
GET /api/sessions/retrieve?user_id=...&query=séances vélo depuis 3 mois minimum 40km
```

### Fonctionnalités
- Recherche automatique de séances comparables (même sport, distance ±20%)
- Affichage de l'évolution : "Allure améliorée de 5% sur distance similaire"
- Détection et affichage des records personnels battus
- Graphique de progression sur N séances similaires

### Interface
- Bouton "Comparer" dans le détail séance
- Modal avec liste des séances comparables
- Tableau comparatif sélectionnable

---

## 8. Vue Liste Alternative

**Priorité : 🟡 Basse**
**Complexité : Moyenne**
**Impact UX : Moyen**

### Description
Ajouter une vue tableau/liste en alternative à la vue calendrier.

### Fonctionnalités
- Toggle "Calendrier / Liste" en haut d'écran
- Colonnes : Date, Sport, Titre, Durée, Distance, TSS
- Tri par n'importe quelle colonne
- Filtres rapides par discipline
- Recherche textuelle dans titres/descriptions
- Sélection multiple pour comparaison

### Maquette
```
┌────────────────────────────────────────────────┐
│  [Calendrier] [Liste●]     🔍 Rechercher...    │
├────────────────────────────────────────────────┤
│  📅 Date  │ 🏃 │ Titre          │ Durée │ Dist │
├───────────┼────┼────────────────┼───────┼──────┤
│  24/11    │ 🚴 │ Sortie longue  │ 3h12  │ 85km │
│  23/11    │ 🏃 │ Fractionné     │ 1h05  │ 12km │
│  22/11    │ 🏊 │ Technique      │ 1h00  │ 2.5km│
│  ...      │    │                │       │      │
└────────────────────────────────────────────────┘
```

---

## 9. Données Contextuelles Environnementales

**Priorité : 🟡 Basse**
**Complexité : Faible**
**Impact UX : Moyen**

### Description
Afficher les informations environnementales de la séance.

### Données à afficher
- **Météo** : Température, conditions (☀️ 🌧️ 💨)
- **Horaire** : Heure de début, durée, créneau (matin/midi/soir)
- **Dénivelé** : D+ et D- avec gradient moyen
- **Équipement** : Vélo utilisé, chaussures, etc.

### Sources
```javascript
activity.file_datas.start_time // Horaire
activity.elevation_gain / activity.elevation_loss // Dénivelé
logbook.weather // Météo saisie
logbook.equipment // Équipement
```

---

## 10. Score de Récupération & Recommandation

**Priorité : 🟡 Basse**
**Complexité : Moyenne**
**Impact UX : Moyen**

### Description
Afficher une estimation du temps de récupération et des recommandations.

### Calculs proposés
```
Temps de récupération ≈ TSS × facteur (1-2h par 100 TSS)

Form = CTL - ATL (Chronic Training Load - Acute Training Load)
- Form > 10 : Forme optimale
- Form 0-10 : Bien entraîné
- Form < 0 : Fatigue accumulée
```

### Affichage
- Jauge de fraîcheur visuelle
- Temps de récupération estimé (24h, 48h, 72h)
- Recommandation pour le lendemain :
  - 🟢 "Prêt pour une séance intense"
  - 🟡 "Privilégier endurance légère"
  - 🔴 "Repos recommandé"

---

## 11. Carnet de Bord Enrichi

**Priorité : 🟡 Basse**
**Complexité : Moyenne**
**Impact UX : Moyen**

### Description
Enrichir l'onglet carnet de bord existant avec des champs supplémentaires.

### Nouveaux champs
- **Qualité de sommeil** (veille) : 😴 1-5 étoiles
- **Fatigue pré-séance** : 💪 1-5 étoiles
- **Objectif de la séance** : Dropdown (récupération, endurance, seuil, VO2max, force, technique)
- **Tags personnalisés** : #fractionné, #sortie-longue, #compétition, #test
- **Photos** : Galerie de photos de la séance

### API à étendre
Ajouter ces champs au modèle Logbook existant.

---

## 12. Widget Résumé Multi-Séances ✅ IMPLÉMENTÉ

**Priorité : 🟡 Basse**
**Complexité : Faible**
**Impact UX : Moyen**
**Statut : ✅ Implémenté le 27/11/2025**
**Fichier : `src/components/calendar/MultiSessionSummary.tsx`**

### Description
Afficher un résumé agrégé quand un jour contient plusieurs séances.

### Cas d'usage
- Double séance (matin + soir)
- Brick triathlon (vélo → course)
- Journée compétition

### Affichage
```
┌─────────────────────────────────────────┐
│  📅 Samedi 23 Novembre - 2 séances      │
├─────────────────────────────────────────┤
│  Volume total: 4h15  │  TSS: 245        │
│  Enchaînement: 🚴 3h → 🏃 1h15 (brick)  │
│  Récupération entre séances: 15min      │
├─────────────────────────────────────────┤
│  ► Séance 1: Vélo - Sortie longue       │
│  ► Séance 2: Course - Transition brick  │
└─────────────────────────────────────────┘
```

---

## Récapitulatif & Priorisation

### Phase 1 - Fonctionnalités Essentielles
| # | Fonctionnalité | Priorité | Effort | Statut |
|---|----------------|----------|--------|--------|
| 1 | Comparaison Prévu vs Réalisé | 🔴 Haute | 3-4j | ✅ Fait |
| 2 | Graphiques de Zones Inline | 🔴 Haute | 3-4j | ✅ Fait |

### Phase 2 - Améliorations Significatives
| # | Fonctionnalité | Priorité | Effort | Statut |
|---|----------------|----------|--------|--------|
| 3 | Vue Semaine avec Résumé | 🟠 Moyenne | 2-3j | ✅ Fait |
| 4 | Analyse Rapide Intégrée | 🟠 Moyenne | 1-2j | ⏳ À faire |
| 5 | Métriques Avancées par Sport | 🟠 Moyenne | 1-2j | ✅ Fait |

### Phase 3 - Nice to Have
| # | Fonctionnalité | Priorité | Effort | Statut |
|---|----------------|----------|--------|--------|
| 6 | Indicateurs Visuels Calendrier | 🟡 Basse | 1-2j | ✅ Fait |
| 7 | Comparaison Historique | 🟡 Basse | 2-3j | ⏳ À faire |
| 8 | Vue Liste Alternative | 🟡 Basse | 2-3j | ⏳ À faire |
| 9 | Données Environnementales | 🟡 Basse | 1j | ⏳ À faire |
| 10 | Score de Récupération | 🟡 Basse | 2j | ⏳ À faire |
| 11 | Carnet de Bord Enrichi | 🟡 Basse | 2j | ⏳ À faire |
| 12 | Widget Multi-Séances | 🟡 Basse | 1j | ✅ Fait |

---

## Notes Techniques

### APIs Backend Existantes
Toutes les données sont disponibles via :
- `GET /api/activities/history` - Séances effectuées avec métriques
- `GET /api/plans/last` - Plan d'entraînement prévu
- `POST /api/analysis/session` - Analyse IA de séance
- `GET /api/sessions/retrieve` - Recherche intelligente de séances
- `GET /api/logbook` - Carnet de bord

### Librairies Suggérées
- Graphiques : `react-native-chart-kit` ou `victory-native`
- Animations : `react-native-reanimated`
- Calendrier enrichi : Extension de `react-native-calendars`

### Points d'Attention
- Performance : Limiter les appels API, utiliser le cache
- Offline : Stocker les données localement avec AsyncStorage
- UX : Animations fluides, feedback visuel immédiat
- Accessibilité : Contrastes suffisants, labels descriptifs

---

*Document créé le 27 novembre 2025*
*Dernière mise à jour : 27 novembre 2025*

---

## Historique des implémentations

| Date | Fonctionnalités implémentées |
|------|------------------------------|
| 27/11/2025 | #1 Comparaison Prévu vs Réalisé, #2 Graphiques de Zones, #3 Vue Semaine, #5 Métriques Avancées, #6 Indicateurs Visuels, #12 Widget Multi-Séances |
