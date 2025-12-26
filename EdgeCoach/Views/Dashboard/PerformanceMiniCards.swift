/**
 * Mini-Cards de Performance pour le Dashboard
 * Affiche un résumé compact des métriques CS/D', CP/W', CSS avec jauge de positionnement
 * et interprétation du profil athlète
 */

import SwiftUI

// MARK: - Running Performance Mini Card (CS/D')

struct RunningPerformanceMiniCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let csDprime: CSDprimeMetric
    let onTap: () -> Void

    // Reference values for CS (in m/s)
    private let csReferences: [(level: String, minMs: Double, maxMs: Double)] = [
        ("Débutant", 2.5, 3.2),
        ("Intermédiaire", 3.2, 3.8),
        ("Avancé", 3.8, 4.3),
        ("Elite", 4.3, 5.0),
        ("Pro", 5.0, 6.5)
    ]

    private var csPositionPercent: Double {
        guard let cs = csDprime.cs else { return 0 }
        let minVal = csReferences.first?.minMs ?? 2.5
        let maxVal = csReferences.last?.maxMs ?? 6.5
        return min(1.0, max(0.0, (cs.value - minVal) / (maxVal - minVal)))
    }

    private var currentLevel: String {
        guard let cs = csDprime.cs else { return "N/A" }
        for ref in csReferences {
            if cs.value >= ref.minMs && cs.value < ref.maxMs {
                return ref.level
            }
        }
        if cs.value >= csReferences.last?.minMs ?? 0 {
            return csReferences.last?.level ?? ""
        }
        return csReferences.first?.level ?? ""
    }

    /// Analyse du profil athlète basée sur CS et D'
    private var profileAnalysis: (title: String, icon: String, tip: String) {
        guard let cs = csDprime.cs, let dPrime = csDprime.dPrime else {
            return ("--", "questionmark.circle", "Données insuffisantes")
        }

        let csKmh = cs.valueKmh
        let dPrimeM = dPrime.value

        if csKmh >= 15 && dPrimeM >= 280 {
            return ("Complet", "star.circle.fill", "Polyvalent du 5K au semi")
        } else if csKmh >= 15 && dPrimeM < 280 {
            return ("Endurant", "figure.run.circle.fill", "Idéal semi/marathon")
        } else if csKmh < 15 && dPrimeM >= 280 {
            return ("Puissant", "bolt.circle.fill", "Fort sur demi-fond court")
        } else if csKmh >= 13 && dPrimeM >= 180 {
            return ("Équilibré", "chart.bar.fill", "Bon potentiel global")
        } else {
            return ("En progression", "arrow.up.circle.fill", "Base aérobie à développer")
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                // Header
                HStack {
                    Image(systemName: "figure.run")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.sportColor(for: .course))
                    Text("Course")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(themeManager.textTertiary)
                }

                // Main value
                if let cs = csDprime.cs {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(cs.paceMinKm)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.sportColor(for: .course))
                        Text("/km")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.textSecondary)

                        Spacer()

                        // D' compact
                        if let dPrime = csDprime.dPrime {
                            VStack(alignment: .trailing, spacing: 0) {
                                Text("\(Int(dPrime.value))m")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(themeManager.warningColor)
                                Text("D'")
                                    .font(.system(size: 9))
                                    .foregroundColor(themeManager.textTertiary)
                            }
                        }
                    }
                }

                // Mini gauge
                MiniPositionGauge(
                    position: csPositionPercent,
                    color: themeManager.sportColor(for: .course)
                )

                // Level badge
                HStack(spacing: 4) {
                    Text(currentLevel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(themeManager.sportColor(for: .course))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(themeManager.sportColor(for: .course).opacity(0.15))
                        .cornerRadius(4)

                    Spacer()
                }

                Divider()
                    .padding(.vertical, 2)

                // Profile interpretation
                HStack(spacing: 6) {
                    Image(systemName: profileAnalysis.icon)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.accentColor)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(profileAnalysis.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(themeManager.textPrimary)
                        Text(profileAnalysis.tip)
                            .font(.system(size: 9))
                            .foregroundColor(themeManager.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: themeManager.cardBorderWidth)
            )
            .shadow(color: themeManager.cardShadow, radius: themeManager.cardShadowRadius, x: 0, y: 2)
        }
        .buttonStyle(.premium)
    }
}

// MARK: - Cycling Performance Mini Card (CP/W')

struct CyclingPerformanceMiniCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let cpWprime: CPWprimeMetric
    let onTap: () -> Void

    // Reference values for CP (in Watts)
    private let cpReferences: [(level: String, minW: Double, maxW: Double)] = [
        ("Débutant", 100, 180),
        ("Intermédiaire", 180, 250),
        ("Avancé", 250, 320),
        ("Elite", 320, 400),
        ("Pro", 400, 550)
    ]

    private var cpPositionPercent: Double {
        guard let cp = cpWprime.cp else { return 0 }
        let minVal = cpReferences.first?.minW ?? 100
        let maxVal = cpReferences.last?.maxW ?? 550
        return min(1.0, max(0.0, (cp.value - minVal) / (maxVal - minVal)))
    }

    private var currentLevel: String {
        guard let cp = cpWprime.cp else { return "N/A" }
        for ref in cpReferences {
            if cp.value >= ref.minW && cp.value < ref.maxW {
                return ref.level
            }
        }
        if cp.value >= cpReferences.last?.minW ?? 0 {
            return cpReferences.last?.level ?? ""
        }
        return cpReferences.first?.level ?? ""
    }

    /// Analyse du profil athlète basée sur CP et W'
    private var profileAnalysis: (title: String, icon: String, tip: String) {
        guard let cp = cpWprime.cp, let wPrime = cpWprime.wPrime else {
            return ("--", "questionmark.circle", "Données insuffisantes")
        }

        let cpW = cp.value
        let wPrimeKJ = wPrime.value

        if cpW >= 300 && wPrimeKJ >= 25 {
            return ("Complet", "star.circle.fill", "CLM et grimpeur-puncheur")
        } else if cpW >= 300 && wPrimeKJ < 25 {
            return ("Rouleur", "figure.outdoor.cycle", "Idéal CLM et cols")
        } else if cpW < 300 && wPrimeKJ >= 25 {
            return ("Puncheur", "bolt.circle.fill", "Fort en critériums")
        } else if cpW >= 220 && wPrimeKJ >= 18 {
            return ("Équilibré", "chart.bar.fill", "Bon potentiel global")
        } else {
            return ("En progression", "arrow.up.circle.fill", "Sweet spot à développer")
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                // Header
                HStack {
                    Image(systemName: "figure.outdoor.cycle")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.sportColor(for: .cyclisme))
                    Text("Cyclisme")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(themeManager.textTertiary)
                }

                // Main value
                if let cp = cpWprime.cp {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(cp.value))")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.sportColor(for: .cyclisme))
                        Text("W")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.textSecondary)

                        Spacer()

                        // W' compact
                        if let wPrime = cpWprime.wPrime {
                            VStack(alignment: .trailing, spacing: 0) {
                                Text(String(format: "%.1f", wPrime.value))
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(themeManager.warningColor)
                                Text("kJ")
                                    .font(.system(size: 9))
                                    .foregroundColor(themeManager.textTertiary)
                            }
                        }
                    }
                }

                // Mini gauge
                MiniPositionGauge(
                    position: cpPositionPercent,
                    color: themeManager.sportColor(for: .cyclisme)
                )

                // Level badge
                HStack(spacing: 4) {
                    Text(currentLevel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(themeManager.sportColor(for: .cyclisme))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(themeManager.sportColor(for: .cyclisme).opacity(0.15))
                        .cornerRadius(4)

                    Spacer()
                }

                Divider()
                    .padding(.vertical, 2)

                // Profile interpretation
                HStack(spacing: 6) {
                    Image(systemName: profileAnalysis.icon)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.accentColor)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(profileAnalysis.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(themeManager.textPrimary)
                        Text(profileAnalysis.tip)
                            .font(.system(size: 9))
                            .foregroundColor(themeManager.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: themeManager.cardBorderWidth)
            )
            .shadow(color: themeManager.cardShadow, radius: themeManager.cardShadowRadius, x: 0, y: 2)
        }
        .buttonStyle(.premium)
    }
}

// MARK: - Swimming Performance Mini Card (CSS)

struct SwimmingPerformanceMiniCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let css: CSSMetric
    let onTap: () -> Void

    // Reference values for CSS (in seconds per 100m) - lower is better
    private let cssReferences: [(level: String, maxSec: Double, minSec: Double)] = [
        ("Débutant", 180, 130),
        ("Intermédiaire", 130, 105),
        ("Avancé", 105, 85),
        ("Elite", 85, 70),
        ("Pro", 70, 55)
    ]

    // For CSS, lower is better, so we invert the position
    private var cssPositionPercent: Double {
        let maxVal = cssReferences.first?.maxSec ?? 180
        let minVal = cssReferences.last?.minSec ?? 55
        return min(1.0, max(0.0, (maxVal - css.value) / (maxVal - minVal)))
    }

    private var currentLevel: String {
        let value = css.value
        for ref in cssReferences {
            if value <= ref.maxSec && value > ref.minSec {
                return ref.level
            }
        }
        if value <= cssReferences.last?.minSec ?? 55 {
            return cssReferences.last?.level ?? ""
        }
        return cssReferences.first?.level ?? ""
    }

    /// Analyse du profil nageur basée sur CSS et confiance
    private var profileAnalysis: (title: String, icon: String, tip: String) {
        let cssPer100m = css.value
        let confidence = css.confidence ?? 0

        if cssPer100m <= 85 && confidence >= 0.7 {
            return ("Confirmé", "star.circle.fill", "Technique efficace")
        } else if cssPer100m <= 105 && confidence >= 0.6 {
            return ("Bon niveau", "figure.pool.swim", "Base solide en natation")
        } else if cssPer100m <= 130 {
            return ("En progression", "arrow.up.circle.fill", "Travaillez la technique")
        } else {
            return ("Débutant", "chart.bar.fill", "Priorité à la régularité")
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                // Header
                HStack {
                    Image(systemName: "figure.pool.swim")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.sportColor(for: .natation))
                    Text("Natation")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(themeManager.textTertiary)
                }

                // Main value
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(css.formattedValue)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.sportColor(for: .natation))

                    Spacer()

                    // Confidence compact
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(css.confidencePercent)%")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor((css.confidence ?? 0) >= 0.7 ? themeManager.successColor : themeManager.warningColor)
                        Text("confiance")
                            .font(.system(size: 8))
                            .foregroundColor(themeManager.textTertiary)
                    }
                }

                // Mini gauge
                MiniPositionGauge(
                    position: cssPositionPercent,
                    color: themeManager.sportColor(for: .natation)
                )

                // Level badge
                HStack(spacing: 4) {
                    Text(currentLevel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(themeManager.sportColor(for: .natation))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(themeManager.sportColor(for: .natation).opacity(0.15))
                        .cornerRadius(4)

                    Spacer()
                }

                Divider()
                    .padding(.vertical, 2)

                // Profile interpretation
                HStack(spacing: 6) {
                    Image(systemName: profileAnalysis.icon)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.accentColor)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(profileAnalysis.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(themeManager.textPrimary)
                        Text(profileAnalysis.tip)
                            .font(.system(size: 9))
                            .foregroundColor(themeManager.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: themeManager.cardBorderWidth)
            )
            .shadow(color: themeManager.cardShadow, radius: themeManager.cardShadowRadius, x: 0, y: 2)
        }
        .buttonStyle(.premium)
    }
}

// MARK: - Mini Position Gauge

struct MiniPositionGauge: View {
    @EnvironmentObject var themeManager: ThemeManager
    let position: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.red.opacity(0.3),
                        Color.orange.opacity(0.3),
                        Color.yellow.opacity(0.3),
                        Color.green.opacity(0.3),
                        Color.blue.opacity(0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 6)
                .cornerRadius(3)

                // Position indicator
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    .shadow(color: color.opacity(0.5), radius: 2)
                    .offset(x: (geometry.size.width - 10) * position)
            }
        }
        .frame(height: 10)
    }
}

// MARK: - Performance Cards Section

struct PerformanceCardsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let viewModel: DashboardViewModel
    let config: PerformanceWidgetConfig
    let onNavigateToPerformance: () -> Void

    var body: some View {
        let hasAnyPerformanceCard = (config.showRunning && viewModel.hasRunningPerformance) ||
                                    (config.showCycling && viewModel.hasCyclingPerformance) ||
                                    (config.showSwimming && viewModel.hasSwimmingPerformance)

        if hasAnyPerformanceCard {
            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                HStack {
                    Text("Performance")
                        .font(.ecH4)
                        .foregroundColor(themeManager.textPrimary)
                    Spacer()
                    Button(action: onNavigateToPerformance) {
                        Text("Voir tout")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.accentColor)
                    }
                }

                // Cards grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: ECSpacing.sm),
                    GridItem(.flexible(), spacing: ECSpacing.sm)
                ], spacing: ECSpacing.sm) {
                    // Running card
                    if config.showRunning, let csDprime = viewModel.csDprime {
                        RunningPerformanceMiniCard(csDprime: csDprime, onTap: onNavigateToPerformance)
                    }

                    // Cycling card
                    if config.showCycling, let cpWprime = viewModel.cpWprime {
                        CyclingPerformanceMiniCard(cpWprime: cpWprime, onTap: onNavigateToPerformance)
                    }

                    // Swimming card
                    if config.showSwimming, let css = viewModel.css {
                        SwimmingPerformanceMiniCard(css: css, onTap: onNavigateToPerformance)
                    }
                }
            }
        }
    }
}
