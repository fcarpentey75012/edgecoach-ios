/**
 * Vue Performance - Métriques de haut niveau calculées en temps réel
 * Affiche VMA, FTP, CSS, Records personnels
 * Cards compactes avec vue détaillée au tap
 */

import SwiftUI

// MARK: - Metric Descriptions (Tooltips avec formules)

enum MetricDescription {

    // MARK: - Course à pied

    static let vma = """
    La VMA (Vitesse Maximale Aérobie) est la vitesse de course à laquelle votre consommation d'oxygène atteint son maximum.

    ━━━ FORMULES ━━━

    1. Extraction des efforts (test 6 min) :
       VMA_candidat = distance_6min / 100 (km/h)

    2. Qualité de chaque effort :
       • q_stab = max(0, 1 - cv_vitesse / 0.05)
       • q_hr = exp(-((FC% - 0.95)² / (2 × 0.03²)))
       • poids = q_stab × q_hr × q_env

    3. Pondération temporelle (decay) :
       w_temps = exp(-ln(2) × age_jours / demi_vie)
       (demi-vie = 30 jours par défaut)

    4. Calcul final :
       VMA = quantile_pondéré(efforts, 0.90) + Δ_FC
       Δ_FC = (0.95 - FC_moy) × 10, borné à ±0.3 km/h

    ━━━ PARAMÈTRES ━━━
    • Top 7 meilleurs efforts
    • Données < 120 jours
    • Quantile 90%

    Utilité : Base pour définir vos zones d'entraînement et allures d'intervalles.
    """

    static let bestDistances = """
    Vos meilleurs temps sur les distances de référence (1km, 5km, 10km, semi, marathon).

    ━━━ ALGORITHME ━━━

    Pour chaque distance cible :

    1. Via laps consécutifs :
       • Scanner tous les segments de laps
       • Tolérance : ±10% de la distance cible
       • Garder le meilleur temps

    2. Via données seconde par seconde :
       • Fenêtre glissante sur timestamps
       • Interpolation linéaire pour distance exacte
       • vitesse = distance / temps

    3. Via séance complète (fallback) :
       • Si séance ≈ distance cible (±10%)

    ━━━ CALCUL ALLURE ━━━
    pace = (temps_sec / (distance_m / 1000)) / 60
    Format : "M:SS /km"

    Les records sont mis à jour automatiquement à chaque nouvelle activité.
    """

    static let csDprime = """
    Modèle CS/D' pour prédire la durée de tenue à haute intensité en course à pied.

    ━━━ DÉFINITIONS ━━━

    • CS (Critical Speed) : Vitesse soutenable ~30-60 min
    • D' (D prime) : Réserve anaérobie au-dessus de CS (en mètres)

    C'est l'équivalent course à pied du modèle CP/W' en cyclisme.

    ━━━ MODÈLE MATHÉMATIQUE ━━━

    v(t) = CS + D' / t

    Équivalent : t = D' / (v - CS)

    ━━━ ALGORITHME DE CALCUL ━━━

    1. Collecte des MMP sur durées 60s à 3600s
    2. Triple pondération :
       • Récence : w = exp(-ln(2) × age / 42j)
       • Qualité HR : pénalité si FC trop basse
       • Bande durée : poids par plage temporelle

    3. Régression WLS (Weighted Least Squares) :
       β = (XᵀWX)⁻¹ XᵀWy
       où X = [1, 1/t] pour chaque point

    4. Contrainte D' ∈ [100, 6000] m si fit médiocre

    ━━━ QUALITÉ DU MODÈLE ━━━
    • R² > 0.90 : Excellent
    • R² > 0.80 : Bon
    • R² < 0.80 : Données insuffisantes
    • RMSE : Erreur en m/s

    Utilité : Prédire combien de temps tenir à une vitesse donnée.
    """

    // MARK: - Cyclisme

    static let ftp = """
    Le FTP (Functional Threshold Power) est la puissance maximale que vous pouvez maintenir ~1 heure.

    ━━━ FORMULES ━━━

    1. Puissance Normalisée (NP) :
       • Lissage 30s de la puissance
       • NP = ⁴√(moyenne(puissance_lissée⁴))

    2. FTP par effort (fenêtre 20 min) :
       FTP = NP × f_t × c_hr

       Où :
       • f_t = 1 - 0.05 × (30 / durée_min)
       • c_hr = 0.85 / (FC_moy / FC_max)

    3. Pondération temporelle :
       w_temps = exp(-ln(2) × age_jours / 45)
       (demi-vie = 45 jours)

    4. Pondération cardiaque :
       w_hr = exp(-((FC% - 0.85)² / (2 × 0.05²)))

    5. Agrégation finale :
       FTP_raw = quantile_pondéré(efforts, 0.90)
       FTP_final = FTP_raw × (1 + drift% / 100)

    ━━━ PARAMÈTRES ━━━
    • Fenêtre : 20 minutes
    • Top 7 efforts, données < 180 jours
    • Drift appliqué : +5%

    Utilité : Base pour définir vos zones de puissance.
    """

    static let cpWprime = """
    Modèle CP/W' pour prédire la durée de tenue à haute intensité.

    ━━━ DÉFINITIONS ━━━

    • CP (Critical Power) : Puissance soutenable ~30-60 min
    • W' (W prime) : Réserve anaérobie au-dessus de CP (kJ)

    ━━━ MODÈLE MATHÉMATIQUE ━━━

    P(t) = CP + W' / t

    Équivalent : t = W' / (P - CP)

    ━━━ ALGORITHME DE CALCUL ━━━

    1. Collecte des MMP sur durées 180s à 3600s
    2. Triple pondération :
       • Récence : w = exp(-ln(2) × age / 90j)
       • Qualité HR : pénalité si FC trop basse
       • Bande durée : poids par plage temporelle

    3. Sélection points (bandes 10-20s, 45-75s, 3-5min, 12-20min, 40-70min)

    4. Régression WLS (Weighted Least Squares) :
       β = (XᵀWX)⁻¹ XᵀWy
       où X = [1, 1/t] pour chaque point

    5. Reweighting Huber (outliers) :
       Seuil = 1.5 × MAD (Median Absolute Deviation)

    6. Contrainte W' ∈ [12, 40] kJ si fit médiocre

    ━━━ QUALITÉ DU MODÈLE ━━━
    • R² > 0.95 : Excellent
    • R² > 0.90 : Bon
    • R² < 0.90 : Données insuffisantes
    • RMSE : Erreur en Watts

    Utilité : Prédire combien de temps tenir à une puissance donnée.
    """

    static let ftpHybrid = """
    FTP Hybrid : Estimation FTP multi-fenêtres avec correction HR.

    ━━━ CONCEPT ━━━

    Moyenne pondérée des estimations FTP sur fenêtres 15-40 min,
    avec filtrage qualité et correction sous-maximalité.

    ━━━ FORMULE ━━━

    FTP_hybrid = Σ(FTP_est × poids) / Σ(poids)

    Pour chaque fenêtre (15, 20, 25, 30, 35, 40 min) :
    FTP_est = NP × facteur_durée × correction_HR

    ━━━ FACTEURS DE DURÉE ━━━
    • 15 min : ×0.97
    • 20 min : ×0.95
    • 25 min : ×0.94
    • 30 min : ×0.93
    • 35 min : ×0.92
    • 40 min : ×0.91

    ━━━ POIDS PAR DURÉE ━━━
    • 15 min : 0.8
    • 20 min : 1.0
    • 30 min : 1.5
    • 40 min : 3.0 (efforts longs privilégiés)

    ━━━ FILTRAGE QUALITÉ ━━━
    • Rejet si FC% < 80%
    • Rejet si dérive HR > 5%

    ━━━ CORRECTION SOUS-MAXIMALITÉ ━━━
    Si FC% < 90% :
    uplift = min(1.03, 90% / FC%)
    FTP_est × uplift (max +3%)

    Différence vs FTP standard : fenêtres multiples, filtrage strict, correction HR aggressive.
    """

    // MARK: - Natation

    static let css = """
    La CSS (Critical Swim Speed) est votre vitesse de nage au seuil lactique (~allure 1500m).

    ━━━ MÉTHODE 1 : Tests de temps ━━━

    CSS = (D₂ - D₁) / (T₂ - T₁)

    Où :
    • D₁, T₁ = distance/temps effort court (200-400m)
    • D₂, T₂ = distance/temps effort long (400-1500m)
    • CSS en m/s

    Confiance = (vitesse_min / vitesse_max) × 0.9

    ━━━ MÉTHODE 2 : Régression linéaire ━━━

    Distance = CSS × Temps + Distance_anaérobie

    • R² mesure la qualité du fit
    • Confiance = R² × 0.95

    ━━━ SÉLECTION DES EFFORTS ━━━
    • Court : 2-4 minutes
    • Long : 7-15 minutes
    • Repos > 30s = fin d'effort

    ━━━ CONVERSION ━━━
    pace_100m = 100 / CSS_m/s (en secondes)

    Utilité : Base pour définir vos zones de natation.
    """

    // MARK: - Général

    static let confidence = """
    Le niveau de confiance indique la fiabilité de l'estimation.

    ━━━ INTERPRÉTATION ━━━

    🟢 Vert (≥80%) : Donnée fiable
       → Suffisamment de sessions récentes
       → Faible variance entre les efforts

    🟠 Orange (60-79%) : Donnée indicative
       → À confirmer avec plus de données
       → Variance modérée

    🔴 Rouge (<60%) : Estimation approximative
       → Peu de données disponibles
       → Forte variance ou données anciennes

    ━━━ FACTEURS ━━━
    • Nombre d'efforts qualifiants
    • Fraîcheur des données (decay temporel)
    • Cohérence entre les efforts (écart-type)
    • Qualité des données FC

    Plus vous vous entraînez régulièrement, plus la confiance augmente.
    """
}

// MARK: - Performance View

struct PerformanceView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = PerformanceViewModel()
    @AppStorage("vma_display_pace") private var vmaDisplayAsPace = false

    var body: some View {
        ScrollView {
            VStack(spacing: ECSpacing.lg) {
                if viewModel.isLoading && viewModel.performanceReport == nil {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let error = viewModel.error {
                    ErrorCard(message: error) {
                        Task {
                            if let userId = authViewModel.user?.id {
                                await viewModel.loadData(userId: userId)
                            }
                        }
                    }
                } else if viewModel.performanceReport != nil {

                    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    // MARK: Course à pied
                    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    if viewModel.hasVMA || viewModel.hasBestDistances || viewModel.hasCSDprime {
                        PerformanceSectionHeader(title: "Course à pied", icon: "figure.run", sport: .course)

                        if viewModel.hasVMA {
                            VMACard(viewModel: viewModel, displayAsPace: $vmaDisplayAsPace)
                        }

                        if viewModel.hasCSDprime {
                            CSDprimeCard(viewModel: viewModel)
                        }

                        if viewModel.hasBestDistances {
                            BestDistancesCard(viewModel: viewModel)
                        }
                    }

                    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    // MARK: Cyclisme
                    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    if viewModel.hasFTP || viewModel.hasFTPHybrid || viewModel.hasCPWprime {
                        PerformanceSectionHeader(title: "Cyclisme", icon: "bicycle", sport: .cyclisme)

                        if viewModel.hasFTP {
                            FTPCard(viewModel: viewModel)
                        }

                        if viewModel.hasFTPHybrid {
                            FTPHybridCard(viewModel: viewModel)
                        }

                        if viewModel.hasCPWprime {
                            CPWprimeCard(viewModel: viewModel)
                        }
                    }

                    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    // MARK: Natation
                    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    if viewModel.hasCSS {
                        PerformanceSectionHeader(title: "Natation", icon: "figure.pool.swim", sport: .natation)

                        CSSCard(viewModel: viewModel)
                    }

                    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    // MARK: Technique
                    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    if viewModel.hasTechnique {
                        TechniqueSectionHeader()

                        if viewModel.hasRunningTechnique {
                            RunningTechniqueCard(viewModel: viewModel)
                        }

                        if viewModel.hasCyclingTechnique {
                            CyclingTechniqueCard(viewModel: viewModel)
                        }

                        if viewModel.hasSwimmingTechnique {
                            SwimmingTechniqueCard(viewModel: viewModel)
                        }
                    }

                    // Info dernière mise à jour
                    if let report = viewModel.performanceReport {
                        LastUpdateInfo(date: report.date)
                    }
                } else {
                    EmptyPerformanceView()
                }
            }
            .padding()
        }
        .background(themeManager.backgroundColor)
        .refreshable {
            if let userId = authViewModel.user?.id {
                await viewModel.refresh(userId: userId)
            }
        }
        .task {
            if let userId = authViewModel.user?.id {
                await viewModel.loadData(userId: userId)
            }
        }
    }
}

// MARK: - Performance Section Header

struct PerformanceSectionHeader: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let icon: String
    let sport: Discipline

    var body: some View {
        HStack(spacing: ECSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.sportColor(for: sport))

            Text(title)
                .font(.ecH4)
                .foregroundColor(themeManager.textPrimary)

            Spacer()
        }
        .padding(.top, ECSpacing.md)
        .padding(.bottom, ECSpacing.xs)
    }
}

// MARK: - Info Button (Tooltip Trigger)

struct InfoButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let description: String
    @State private var showInfo = false

    var body: some View {
        Button {
            showInfo = true
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 16))
                .foregroundColor(themeManager.textTertiary)
        }
        .sheet(isPresented: $showInfo) {
            InfoSheetView(title: title, description: description)
        }
    }
}

struct InfoSheetView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let title: String
    let description: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ECSpacing.lg) {
                    Text(description)
                        .font(.ecBody)
                        .foregroundColor(themeManager.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .environmentObject(themeManager)
    }
}

// MARK: - VMA Card

struct VMACard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: PerformanceViewModel
    @Binding var displayAsPace: Bool
    @State private var showDetail = false

    /// Convertit km/h en min/km
    private func kmhToPace(_ kmh: Double) -> String {
        guard kmh > 0 else { return "--:--" }
        let minPerKm = 60.0 / kmh
        let minutes = Int(minPerKm)
        let seconds = Int((minPerKm - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: ECSpacing.md) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(themeManager.sportColor(for: .course).opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "figure.run")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.sportColor(for: .course))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: ECSpacing.xs) {
                            Text("VMA")
                                .font(.ecLabelBold)
                                .foregroundColor(themeManager.textPrimary)
                            InfoButton(title: "VMA", description: MetricDescription.vma)
                        }
                        Text("Vitesse Maximale Aérobie")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    Spacer()

                    // Toggle km/h <-> min/km
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            displayAsPace.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 10))
                            Text(displayAsPace ? "km/h" : "min/km")
                                .font(.ecSmall)
                        }
                        .foregroundColor(themeManager.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeManager.accentColor.opacity(0.1))
                        .cornerRadius(ECRadius.sm)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.textTertiary)
                }

                // Value
                if let vma = viewModel.performanceReport?.metrics.vma {
                    HStack(alignment: .firstTextBaseline, spacing: ECSpacing.sm) {
                        if displayAsPace {
                            Text(kmhToPace(vma.value))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.textPrimary)

                            Text("min/km")
                                .font(.ecLabel)
                                .foregroundColor(themeManager.textSecondary)
                        } else {
                            Text(String(format: "%.1f", vma.value))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.textPrimary)

                            Text("km/h")
                                .font(.ecLabel)
                                .foregroundColor(themeManager.textSecondary)
                        }

                        Spacer()

                        ConfidenceBadge(confidence: vma.confidencePercent)
                    }

                    // Standard deviation + alternate display
                    HStack(spacing: ECSpacing.md) {
                        if let stdDev = vma.standardDeviation {
                            if displayAsPace {
                                // Afficher l'écart-type en min/km approximatif
                                let paceHigh = kmhToPace(vma.value - stdDev)
                                let paceLow = kmhToPace(vma.value + stdDev)
                                Text("\(paceLow) - \(paceHigh)")
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textTertiary)
                            } else {
                                Text("± \(String(format: "%.1f", stdDev)) km/h")
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textTertiary)
                            }
                        }

                        // Afficher l'autre unité en petit
                        if displayAsPace {
                            Text("(\(String(format: "%.1f", vma.value)) km/h)")
                                .font(.ecSmall)
                                .foregroundColor(themeManager.textTertiary)
                        } else {
                            Text("(\(kmhToPace(vma.value)) /km)")
                                .font(.ecSmall)
                                .foregroundColor(themeManager.textTertiary)
                        }
                    }

                    // Zones preview
                    if let zones = vma.trainingZones, !zones.isEmpty {
                        ZonesPreviewBar(zones: zones)
                    }
                }
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
            .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            VMADetailView(vma: viewModel.performanceReport?.metrics.vma)
        }
    }
}

// MARK: - CS/D' Card (Running - équivalent CP/W')

struct CSDprimeCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: PerformanceViewModel
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: ECSpacing.md) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(themeManager.sportColor(for: .course).opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.sportColor(for: .course))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: ECSpacing.xs) {
                            Text("CS / D'")
                                .font(.ecLabelBold)
                                .foregroundColor(themeManager.textPrimary)
                            InfoButton(title: "CS / D'", description: MetricDescription.csDprime)
                        }
                        Text("Critical Speed & D' Balance")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.textTertiary)
                }

                // Values
                if let csDprime = viewModel.performanceReport?.metrics.csDprime {
                    HStack(spacing: ECSpacing.xl) {
                        // CS
                        if let cs = csDprime.cs {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CS")
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textSecondary)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(cs.paceMinKm)
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.textPrimary)
                                    Text("/km")
                                        .font(.ecSmall)
                                        .foregroundColor(themeManager.textSecondary)
                                }
                                Text(String(format: "%.1f km/h", cs.valueKmh))
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textTertiary)
                            }
                        }

                        // D'
                        if let dPrime = csDprime.dPrime {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("D'")
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textSecondary)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(String(format: "%.0f", dPrime.value))
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.textPrimary)
                                    Text("m")
                                        .font(.ecSmall)
                                        .foregroundColor(themeManager.textSecondary)
                                }
                            }
                        }

                        Spacer()

                        // R2 indicator
                        if let fitStats = csDprime.fitStats, let r2 = fitStats.r2 {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("R²")
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textSecondary)
                                Text(String(format: "%.2f", r2))
                                    .font(.ecLabelBold)
                                    .foregroundColor(r2 > 0.85 ? themeManager.successColor : themeManager.warningColor)
                            }
                        }
                    }
                }
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
            .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            CSDprimeDetailView(
                csDprime: viewModel.performanceReport?.metrics.csDprime,
                csZones: viewModel.performanceReport?.metrics.csZones,
                csZonesPace: viewModel.performanceReport?.metrics.csZonesPace
            )
        }
    }
}

// MARK: - FTP Card

struct FTPCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: PerformanceViewModel
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: ECSpacing.md) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(themeManager.sportColor(for: .cyclisme).opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "bicycle")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.sportColor(for: .cyclisme))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: ECSpacing.xs) {
                            Text("FTP")
                                .font(.ecLabelBold)
                                .foregroundColor(themeManager.textPrimary)
                            InfoButton(title: "FTP", description: MetricDescription.ftp)
                        }
                        Text("Functional Threshold Power")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.textTertiary)
                }

                // Value
                if let ftp = viewModel.performanceReport?.metrics.ftp {
                    HStack(alignment: .firstTextBaseline, spacing: ECSpacing.sm) {
                        Text(String(format: "%.0f", ftp.value))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.textPrimary)

                        Text("W")
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textSecondary)

                        Spacer()

                        ConfidenceBadge(confidence: ftp.confidencePercent)
                    }

                    // Standard deviation + drift info
                    HStack(spacing: ECSpacing.md) {
                        if let stdDev = ftp.standardDeviation {
                            Text("± \(String(format: "%.0f", stdDev)) W")
                                .font(.ecSmall)
                                .foregroundColor(themeManager.textTertiary)
                        }
                        if let metadata = ftp.metadata, metadata.driftApplied == true {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10))
                                Text("Drift +\(String(format: "%.0f", metadata.driftPercent ?? 0))%")
                                    .font(.ecSmall)
                            }
                            .foregroundColor(themeManager.successColor)
                        }
                    }

                    // Zones preview
                    if let zones = ftp.trainingZones, !zones.isEmpty {
                        ZonesPreviewBar(zones: zones)
                    }
                }
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
            .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            FTPDetailView(ftp: viewModel.performanceReport?.metrics.ftp)
        }
    }
}

// MARK: - FTP Hybrid Card

struct FTPHybridCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: PerformanceViewModel
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: ECSpacing.md) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(themeManager.sportColor(for: .cyclisme).opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.sportColor(for: .cyclisme))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: ECSpacing.xs) {
                            Text("FTP Hybrid")
                                .font(.ecLabelBold)
                                .foregroundColor(themeManager.textPrimary)
                            InfoButton(title: "FTP Hybrid", description: MetricDescription.ftpHybrid)
                        }
                        Text("Multi-fenêtres avec correction HR")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.textTertiary)
                }

                // Values
                if let ftpHybrid = viewModel.performanceReport?.metrics.ftpHybrid {
                    HStack(spacing: ECSpacing.xl) {
                        // FTP Value
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(String(format: "%.0f", ftpHybrid.value))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(themeManager.textPrimary)
                                Text("W")
                                    .font(.ecLabel)
                                    .foregroundColor(themeManager.textSecondary)
                            }
                        }

                        // W/kg
                        if let wPerKg = ftpHybrid.wPerKg {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Ratio")
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textSecondary)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(String(format: "%.2f", wPerKg.value))
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.textPrimary)
                                    Text("W/kg")
                                        .font(.ecSmall)
                                        .foregroundColor(themeManager.textSecondary)
                                }
                            }
                        }

                        Spacer()
                    }

                    // Windows preview
                    if let details = ftpHybrid.details, !details.isEmpty {
                        HStack(spacing: ECSpacing.sm) {
                            ForEach(details.prefix(4)) { detail in
                                VStack(spacing: 2) {
                                    Text("\(Int(detail.durationMin ?? 0))'")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(themeManager.textTertiary)
                                    Text(String(format: "%.0f", detail.ftpEst ?? 0))
                                        .font(.ecSmall)
                                        .foregroundColor(themeManager.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, ECSpacing.sm)
                        .padding(.vertical, ECSpacing.xs)
                        .background(themeManager.backgroundColor.opacity(0.5))
                        .cornerRadius(ECRadius.sm)
                    }
                }
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
            .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            FTPHybridDetailView(ftpHybrid: viewModel.performanceReport?.metrics.ftpHybrid)
        }
    }
}

// MARK: - CSS Card (Natation)

struct CSSCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: PerformanceViewModel
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: ECSpacing.md) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(themeManager.sportColor(for: .natation).opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "figure.pool.swim")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.sportColor(for: .natation))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: ECSpacing.xs) {
                            Text("CSS")
                                .font(.ecLabelBold)
                                .foregroundColor(themeManager.textPrimary)
                            InfoButton(title: "CSS", description: MetricDescription.css)
                        }
                        Text("Critical Swim Speed")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.textTertiary)
                }

                // Value
                if let css = viewModel.performanceReport?.metrics.css {
                    HStack(alignment: .firstTextBaseline, spacing: ECSpacing.sm) {
                        Text(css.formattedPace)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.textPrimary)

                        Text("/100m")
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textSecondary)

                        Spacer()

                        ConfidenceBadge(confidence: css.confidencePercent)
                    }

                    // Speed in m/s
                    if let metadata = css.metadata, let speedMs = metadata.cssMs {
                        Text(String(format: "%.2f m/s", speedMs))
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textTertiary)
                    }

                    // Zones preview
                    if let zones = css.trainingZones, !zones.isEmpty {
                        ZonesPreviewBar(zones: zones)
                    }
                }
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
            .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            CSSDetailView(css: viewModel.performanceReport?.metrics.css)
        }
    }
}

// MARK: - Best Distances Card

struct BestDistancesCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: PerformanceViewModel
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: ECSpacing.md) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(themeManager.warningColor.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "trophy")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.warningColor)
                    }

                    HStack(spacing: ECSpacing.xs) {
                        Text("Records Personnels")
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)
                        InfoButton(title: "Records", description: MetricDescription.bestDistances)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.textTertiary)
                }

                // Records preview (top 3)
                VStack(spacing: ECSpacing.sm) {
                    ForEach(viewModel.sortedBestDistances.prefix(3), id: \.key) { key, record in
                        HStack {
                            Text(key.uppercased())
                                .font(.ecCaptionBold)
                                .foregroundColor(themeManager.textSecondary)
                                .frame(width: 50, alignment: .leading)

                            Text(record.formattedTime)
                                .font(.ecLabelBold)
                                .foregroundColor(themeManager.textPrimary)

                            if let pace = record.pace {
                                Text("(\(pace) /km)")
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textSecondary)
                            }

                            Spacer()

                            if let date = record.date {
                                Text(formatRecordDate(date))
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textTertiary)
                            }
                        }
                    }
                }
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
            .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            BestDistancesDetailView(records: viewModel.sortedBestDistances)
        }
    }

    private func formatRecordDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: date)
    }
}

// MARK: - CP/W' Card

struct CPWprimeCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: PerformanceViewModel
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: ECSpacing.md) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(themeManager.sportColor(for: .cyclisme).opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.sportColor(for: .cyclisme))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: ECSpacing.xs) {
                            Text("CP / W'")
                                .font(.ecLabelBold)
                                .foregroundColor(themeManager.textPrimary)
                            InfoButton(title: "CP / W'", description: MetricDescription.cpWprime)
                        }
                        Text("Critical Power & W' Balance")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.textTertiary)
                }

                // Values
                if let cpWprime = viewModel.performanceReport?.metrics.cpWprime {
                    HStack(spacing: ECSpacing.xl) {
                        // CP
                        if let cp = cpWprime.cp {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CP")
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textSecondary)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(String(format: "%.0f", cp.value))
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.textPrimary)
                                    Text("W")
                                        .font(.ecSmall)
                                        .foregroundColor(themeManager.textSecondary)
                                }
                            }
                        }

                        // W'
                        if let wPrime = cpWprime.wPrime {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("W'")
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textSecondary)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(String(format: "%.1f", wPrime.value))
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.textPrimary)
                                    Text("kJ")
                                        .font(.ecSmall)
                                        .foregroundColor(themeManager.textSecondary)
                                }
                            }
                        }

                        Spacer()

                        // R2 indicator
                        if let fitStats = cpWprime.fitStats, let r2 = fitStats.r2 {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("R²")
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textSecondary)
                                Text(String(format: "%.2f", r2))
                                    .font(.ecLabelBold)
                                    .foregroundColor(r2 > 0.9 ? themeManager.successColor : themeManager.warningColor)
                            }
                        }
                    }
                }
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
            .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            CPWprimeDetailView(cpWprime: viewModel.performanceReport?.metrics.cpWprime)
        }
    }
}

// MARK: - Supporting Views

struct ConfidenceBadge: View {
    @EnvironmentObject var themeManager: ThemeManager
    let confidence: Int
    @State private var showInfo = false

    var color: Color {
        if confidence >= 80 {
            return themeManager.successColor
        } else if confidence >= 60 {
            return themeManager.warningColor
        } else {
            return themeManager.errorColor
        }
    }

    var body: some View {
        Button {
            showInfo = true
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text("\(confidence)%")
                    .font(.ecSmall)
                    .foregroundColor(color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(ECRadius.sm)
        }
        .sheet(isPresented: $showInfo) {
            InfoSheetView(title: "Niveau de confiance", description: MetricDescription.confidence)
        }
    }
}

struct ZonesPreviewBar: View {
    @EnvironmentObject var themeManager: ThemeManager
    let zones: [TrainingZone]

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(Array(zones.enumerated()), id: \.offset) { index, _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(themeManager.zoneColor(for: index + 1))
                        .frame(height: 6)
                }
            }
        }
        .frame(height: 6)
    }
}

struct LastUpdateInfo: View {
    @EnvironmentObject var themeManager: ThemeManager
    let date: String

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let parsedDate = formatter.date(from: date) else {
            // Essayer sans fractions
            formatter.formatOptions = [.withInternetDateTime]
            guard let parsedDate = formatter.date(from: date) else {
                return date
            }
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "dd/MM/yyyy HH:mm"
            return displayFormatter.string(from: parsedDate)
        }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        return displayFormatter.string(from: parsedDate)
    }

    var body: some View {
        HStack {
            Image(systemName: "clock")
                .font(.ecSmall)
                .foregroundColor(themeManager.textTertiary)
            Text("Mis à jour le \(formattedDate)")
                .font(.ecSmall)
                .foregroundColor(themeManager.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, ECSpacing.md)
    }
}

struct EmptyPerformanceView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: ECSpacing.lg) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(themeManager.textTertiary)

            Text("Pas encore de données")
                .font(.ecH4)
                .foregroundColor(themeManager.textPrimary)

            Text("Effectuez des entraînements pour calculer vos métriques de performance.")
                .font(.ecBody)
                .foregroundColor(themeManager.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

struct ErrorCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: ECSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(themeManager.errorColor)

            Text("Erreur de chargement")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            Text(message)
                .font(.ecSmall)
                .foregroundColor(themeManager.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: retry) {
                Text("Réessayer")
                    .font(.ecLabelBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, ECSpacing.lg)
                    .padding(.vertical, ECSpacing.sm)
                    .background(themeManager.accentColor)
                    .cornerRadius(ECRadius.md)
            }
        }
        .padding(ECSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
    }
}

// MARK: - Technique Section Header

struct TechniqueSectionHeader: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: ECSpacing.sm) {
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.accentColor)

            Text("Technique")
                .font(.ecH4)
                .foregroundColor(themeManager.textPrimary)

            Spacer()
        }
        .padding(.top, ECSpacing.lg)
        .padding(.bottom, ECSpacing.xs)
    }
}

// MARK: - Running Technique Card

struct RunningTechniqueCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: PerformanceViewModel
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: ECSpacing.md) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(themeManager.sportColor(for: .course).opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "figure.run")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.sportColor(for: .course))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Technique Course")
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)
                        Text("Efficacité & biomécanique")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.textTertiary)
                }

                // Key metrics
                if let running = viewModel.performanceReport?.meta?.technique?.running {
                    HStack(spacing: ECSpacing.lg) {
                        if let cadence = running.cadenceSpm {
                            TechniqueMetricView(
                                label: "Cadence",
                                value: String(format: "%.0f", cadence),
                                unit: "spm"
                            )
                        }

                        if let efficiency = running.efficiencyIndex {
                            TechniqueMetricView(
                                label: "Efficacité",
                                value: String(format: "%.2f", efficiency),
                                unit: ""
                            )
                        }

                        if let paHr = running.paHrMedianPct {
                            TechniqueMetricView(
                                label: "Pa:Hr",
                                value: String(format: "%.1f", paHr),
                                unit: "%"
                            )
                        }

                        Spacer()
                    }
                }
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
            .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            RunningTechniqueDetailView(
                technique: viewModel.performanceReport?.meta?.technique?.running,
                vmaZones: viewModel.performanceReport?.metrics.vmaZones,
                paceZones: viewModel.performanceReport?.metrics.paceZones,
                hrZones: viewModel.performanceReport?.metrics.hrZones
            )
        }
    }
}

// MARK: - Cycling Technique Card

struct CyclingTechniqueCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: PerformanceViewModel
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: ECSpacing.md) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(themeManager.sportColor(for: .cyclisme).opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "bicycle")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.sportColor(for: .cyclisme))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Technique Vélo")
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)
                        Text("Puissance & pédalage")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.textTertiary)
                }

                // Key metrics
                if let cycling = viewModel.performanceReport?.meta?.technique?.cycling {
                    HStack(spacing: ECSpacing.lg) {
                        if let cadence = cycling.cadenceRpm {
                            TechniqueMetricView(
                                label: "Cadence",
                                value: String(format: "%.0f", cadence),
                                unit: "rpm"
                            )
                        }

                        if let vi = cycling.variabilityIndex {
                            TechniqueMetricView(
                                label: "VI",
                                value: String(format: "%.2f", vi),
                                unit: ""
                            )
                        }

                        if let ef = cycling.efficiencyFactor {
                            TechniqueMetricView(
                                label: "EF",
                                value: String(format: "%.2f", ef),
                                unit: ""
                            )
                        }

                        Spacer()
                    }
                }
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
            .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            CyclingTechniqueDetailView(
                technique: viewModel.performanceReport?.meta?.technique?.cycling,
                ftpZones: viewModel.performanceReport?.metrics.ftpZones
            )
        }
    }
}

// MARK: - Swimming Technique Card

struct SwimmingTechniqueCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: PerformanceViewModel
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: ECSpacing.md) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(themeManager.sportColor(for: .natation).opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "figure.pool.swim")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.sportColor(for: .natation))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Technique Natation")
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)
                        Text("SWOLF & efficacité")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.textTertiary)
                }

                // Key metrics
                if let swimming = viewModel.performanceReport?.meta?.technique?.swimming {
                    HStack(spacing: ECSpacing.lg) {
                        if let swolf = swimming.swolf {
                            TechniqueMetricView(
                                label: "SWOLF",
                                value: String(format: "%.0f", swolf),
                                unit: ""
                            )
                        }

                        if let strokeRate = swimming.strokeRateCpm {
                            TechniqueMetricView(
                                label: "Fréquence",
                                value: String(format: "%.0f", strokeRate),
                                unit: "c/min"
                            )
                        }

                        if let efficiency = swimming.efficiencyIndex {
                            TechniqueMetricView(
                                label: "Efficacité",
                                value: String(format: "%.2f", efficiency),
                                unit: ""
                            )
                        }

                        Spacer()
                    }
                }
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
            .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            SwimmingTechniqueDetailView(
                technique: viewModel.performanceReport?.meta?.technique?.swimming,
                cssZones: viewModel.performanceReport?.metrics.cssZonesFormatted
            )
        }
    }
}

// MARK: - Technique Metric View (réutilisable)

struct TechniqueMetricView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.ecSmall)
                .foregroundColor(themeManager.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.textPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PerformanceView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager.shared)
}
