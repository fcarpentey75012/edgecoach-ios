# Roadmap UI Premium - Phase 2

## Statut actuel

### Phase 1 & 2 (Terminées)
- [x] HapticManager singleton
- [x] PremiumButtonStyle avec scale + haptic
- [x] StoryContainerView (Instagram-like)
- [x] SessionBriefingView

### Phase 3 & 4 (Terminées)
- [x] `.buttonStyle(.premium)` généralisé (30+ fichiers)
- [x] `.staggeredAnimation()` sur les listes principales
- [x] `SynergyRingView` dans PMCStatusWidget
- [x] Compilation validée

---

## Phase 5 : Composants Premium Avancés

### 5.1 SynergyRingView - Extension d'usage

| Fichier | Emplacement | Valeur mappée |
|---------|-------------|---------------|
| `MacroPlanDetailView.swift` | Header (remplacer `CircularProgress`) | Progression du plan (semaine actuelle / total) |
| `PerformanceView.swift` | Cards VMA/FTP/CSS | Niveau de confiance (0-100%) |
| `SessionDetailView.swift` | Header séance | % objectif atteint vs plan |
| `ComplianceBanner.swift` | Indicateur compliance | Taux de respect du plan |

**Priorité :** Haute
**Effort :** Moyen

---

### 5.2 LiquidFillView - Intégration

| Fichier | Usage | Animation |
|---------|-------|-----------|
| `SessionDetailView.swift` | Barre de complétion de séance | Fill progressif au scroll |
| `WeekPlanView.swift` | Volume hebdo réalisé vs prévu | Fill horizontal |
| `ZonesDistributionCard.swift` | Remplacer les barres statiques | Fill animé par zone |
| `PMCStatusWidget.swift` | Jauge TSB alternative | Fill vertical avec couleur dynamique |

**Priorité :** Haute
**Effort :** Moyen

---

### 5.3 CompletionCelebrationView - Moments clés

| Déclencheur | Fichier | Condition |
|-------------|---------|-----------|
| Fin de séance réussie | `SessionDetailView.swift` | `session.completionRate >= 0.9` |
| Plan semaine complété | `WeekPlanView.swift` | Toutes sessions validées |
| Nouveau record personnel | `PerformanceView.swift` | Détection nouveau PR |
| Objectif A atteint | `MacroPlanDetailView.swift` | Date objectif = aujourd'hui |

**Priorité :** Moyenne
**Effort :** Faible

---

## Phase 6 : Cohérence des CTA

### 6.1 ECActionButton - Remplacement systématique

| Fichier | Bouton actuel | Style ECActionButton |
|---------|---------------|----------------------|
| `LoginView.swift` | "Se connecter" | `.primary` |
| `RegisterView.swift` | "S'inscrire" | `.primary` |
| `MacroPlanCreatorView.swift` | "Générer le plan" | `.primary` + sparkles |
| `ProfileView.swift` | "Déconnexion" | `.destructive` |
| `TrainingPlanCreatorView.swift` | "Créer le plan" | `.primary` |
| `ObjectiveEditorView.swift` | "Enregistrer" | `.primary` |

**Priorité :** Moyenne
**Effort :** Faible

---

### 6.2 ECCardButton - Cards cliquables

Remplacer les `Button { } label: { Card() }` par `ECCardButton` dans :
- `DashboardView.swift` (SportCard, MacroPlanCard)
- `CalendarView.swift` (CalendarSessionCard, CalendarActivityCard)
- `PerformanceView.swift` (VMACard, FTPCard, CSSCard, etc.)

**Priorité :** Basse
**Effort :** Moyen

---

## Phase 7 : États de chargement

### 7.1 SkeletonView - Généralisation

| Vue | Composant skeleton à créer |
|-----|----------------------------|
| `DashboardView` | `DashboardSkeletons.swift` (existe déjà) - Vérifier usage |
| `CalendarView` | `CalendarSkeleton` - Cards sessions placeholder |
| `PerformanceView` | `PerformanceCardSkeleton` - Métriques placeholder |
| `CoachChatView` | `MessageSkeleton` - Bulles de chat placeholder |
| `StatsView` | `ChartSkeleton` - Graphiques placeholder |

**Pattern recommandé :**
```swift
if isLoading {
    SkeletonView()
        .shimmer()
} else {
    ActualContent()
        .staggeredAnimation(index: index, totalCount: count)
}
```

**Priorité :** Moyenne
**Effort :** Moyen

---

### 7.2 Pull-to-Refresh Premium

Créer `PremiumRefreshControl` avec :
- Animation Lottie ou custom SwiftUI
- Haptic feedback au seuil de déclenchement
- Transition fluide vers le contenu

**Fichiers concernés :**
- `DashboardView.swift`
- `CalendarView.swift`
- `StatsView.swift`
- `PerformanceView.swift`

**Priorité :** Basse
**Effort :** Élevé

---

## Phase 8 : Transitions & Navigation

### 8.1 MatchedGeometryEffect

| Transition | Source | Destination |
|------------|--------|-------------|
| Session card → Détail | `CalendarSessionCard` | `SessionDetailView` |
| Activity card → Détail | `ActivityRowCompact` | `SessionDetailView` |
| Plan card → Détail | `MacroPlanCard` | `MacroPlanDetailView` |
| Performance card → Détail | `VMACard` etc. | Detail sheets |

**Implémentation :**
```swift
@Namespace private var animation

// Source
.matchedGeometryEffect(id: session.id, in: animation)

// Destination
.matchedGeometryEffect(id: session.id, in: animation)
```

**Priorité :** Basse
**Effort :** Élevé

---

### 8.2 Tab Transitions

Custom transition entre les tabs du `MainTabView` :
- Slide horizontal avec parallax
- Fade + scale subtil
- Haptic léger au changement

**Priorité :** Basse
**Effort :** Moyen

---

## Phase 9 : Micro-interactions

### 9.1 Haptics étendus

| Action | Type haptic | Fichier |
|--------|-------------|---------|
| Toggle switch | `.light` | Tous les `Toggle` |
| Picker selection | `.selection` | Tous les `Picker` |
| Swipe action | `.medium` | Lists avec swipe |
| Long press menu | `.heavy` | Context menus |
| Error shake | `.error` (pattern custom) | Validation forms |

**Priorité :** Moyenne
**Effort :** Faible

---

### 9.2 Animations de feedback

| Événement | Animation |
|-----------|-----------|
| Erreur de validation | Shake horizontal (3x) |
| Succès sauvegarde | Scale pulse + checkmark |
| Ajout à liste | Insert avec bounce |
| Suppression | Fade out + collapse |

**Priorité :** Moyenne
**Effort :** Moyen

---

## Phase 10 : Performance & Accessibilité

### 10.1 Optimisation animations

```swift
// Pattern anti-re-render
struct AnimatedList: View {
    @State private var hasAppeared = false

    var body: some View {
        ForEach(items.enumerated(), id: \.element.id) { index, item in
            ItemView(item: item)
                .staggeredAnimation(
                    index: hasAppeared ? 0 : index,
                    totalCount: hasAppeared ? 1 : items.count
                )
        }
        .onAppear { hasAppeared = true }
    }
}
```

**Fichiers à optimiser :**
- Toutes les vues avec `.staggeredAnimation()` dans des `ScrollView`

**Priorité :** Haute
**Effort :** Faible

---

### 10.2 Reduce Motion

```swift
// Dans PremiumAnimations.swift
extension View {
    func premiumAnimation() -> some View {
        self.modifier(PremiumAnimationModifier())
    }
}

struct PremiumAnimationModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content // Pas d'animation
        } else {
            content.staggeredAnimation(...)
        }
    }
}
```

**Priorité :** Haute
**Effort :** Faible

---

### 10.3 Dark Mode Audit

Vérifier dans chaque fichier modifié :
- [ ] Aucune couleur hardcodée (`.blue`, `.white`, etc.)
- [ ] Utilisation de `themeManager.accentColor`
- [ ] Shadows adaptées au mode (plus subtiles en dark)
- [ ] Contraste suffisant (ratio 4.5:1 minimum)

**Priorité :** Haute
**Effort :** Moyen

---

## Ordre d'exécution recommandé

| Phase | Priorité | Effort | Impact UX |
|-------|----------|--------|-----------|
| 10.1 Optimisation re-render | Haute | Faible | Performance |
| 10.2 Reduce Motion | Haute | Faible | Accessibilité |
| 5.2 LiquidFillView | Haute | Moyen | Wow effect |
| 5.1 SynergyRingView extension | Haute | Moyen | Cohérence |
| 5.3 CompletionCelebration | Moyenne | Faible | Engagement |
| 6.1 ECActionButton | Moyenne | Faible | Cohérence |
| 7.1 Skeletons | Moyenne | Moyen | Polish |
| 9.1 Haptics étendus | Moyenne | Faible | Tactile |
| 10.3 Dark Mode audit | Haute | Moyen | Qualité |
| 8.1 MatchedGeometry | Basse | Élevé | Premium feel |

---

## Métriques de succès

- [ ] Temps de réponse perçu < 100ms sur toutes les interactions
- [ ] Animations à 60 FPS constant
- [ ] 0 couleur hardcodée dans les vues
- [ ] 100% des CTA utilisent ECActionButton
- [ ] Reduce Motion respecté partout
- [ ] Skeletons sur tous les états de chargement

---

## Fichiers critiques

```
EdgeCoach/Views/Components/PremiumAnimations.swift  # Composants source
EdgeCoach/Theme/Styles.swift                         # Styles source
EdgeCoach/Views/Components/SkeletonView.swift        # Skeletons
EdgeCoach/Utilities/HapticManager.swift              # Haptics
EdgeCoach/Theme/ThemeManager.swift                   # Couleurs
```

---

*Dernière mise à jour : 26 décembre 2024*
