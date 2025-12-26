/**
 * PMCStatusWidget - Widget d'état de forme (CTL/ATL/TSB)
 * Affiche l'état de forme actuel avec jauge et recommandations
 */

import SwiftUI

// MARK: - PMC Status Widget

struct PMCStatusWidget: View {
    @EnvironmentObject var themeManager: ThemeManager
    let pmcStatus: PMCStatus?
    let isLoading: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: ECSpacing.md) {
                // Header
                headerView

                if isLoading {
                    loadingView
                } else if let pmc = pmcStatus {
                    contentView(pmc)
                } else {
                    emptyView
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .fill(themeManager.cardColor)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(.premium)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 16))
                .foregroundColor(themeManager.accentColor)

            Text("État de forme")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            Spacer()

            if let pmc = pmcStatus {
                Image(systemName: pmc.formIcon)
                    .font(.system(size: 16))
                    .foregroundColor(pmc.formColor)
            }
        }
    }

    // MARK: - Content View

    private func contentView(_ pmc: PMCStatus) -> some View {
        VStack(spacing: ECSpacing.md) {
            // SynergyRing + Jauge TSB
            HStack(spacing: ECSpacing.md) {
                // Synergy Ring pour visualiser le TSB
                SynergyRingView(
                    value: (pmc.tsb + 30) / 60, // Mapper TSB [-30, +30] sur [0, 1]
                    overrideColor: pmc.formColor,
                    size: 80,
                    lineWidth: 8
                )

                // Jauge TSB et label
                VStack(alignment: .leading, spacing: ECSpacing.xs) {
                    tsbGaugeView(pmc)
                }
            }

            // Métriques CTL/ATL
            metricsRow(pmc)

            // Alertes si présentes
            if !pmc.alerts.isEmpty {
                alertsView(pmc.alerts)
            }

            // Recommandation
            recommendationView(pmc)
        }
    }

    // MARK: - TSB Gauge

    private func tsbGaugeView(_ pmc: PMCStatus) -> some View {
        VStack(spacing: ECSpacing.xs) {
            // Label principal
            HStack(alignment: .firstTextBaseline, spacing: ECSpacing.xs) {
                Text(pmc.formLabel)
                    .font(.ecH3)
                    .foregroundColor(pmc.formColor)

                Text(pmc.rampTrend)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.textSecondary)
            }

            // Jauge horizontale
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(themeManager.backgroundColor)
                        .frame(height: 12)

                    // Gradient de couleur
                    LinearGradient(
                        colors: [.red, .orange, .yellow, .green, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 12)
                    .cornerRadius(6)
                    .opacity(0.3)

                    // Indicateur de position
                    let position = tsbPosition(pmc.tsb, width: geometry.size.width)
                    Circle()
                        .fill(pmc.tsbColor)
                        .frame(width: 16, height: 16)
                        .shadow(color: pmc.tsbColor.opacity(0.5), radius: 4)
                        .offset(x: position - 8)
                }
            }
            .frame(height: 16)

            // Labels de la jauge
            HStack {
                Text("Fatigué")
                    .font(.system(size: 9))
                    .foregroundColor(themeManager.textTertiary)
                Spacer()
                Text("TSB: \(String(format: "%.1f", pmc.tsb))")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(themeManager.textSecondary)
                Spacer()
                Text("Frais")
                    .font(.system(size: 9))
                    .foregroundColor(themeManager.textTertiary)
            }
        }
    }

    private func tsbPosition(_ tsb: Double, width: CGFloat) -> CGFloat {
        // TSB range: -30 à +30, on mappe sur la largeur
        let normalized = (tsb + 30) / 60 // 0 à 1
        let clamped = max(0, min(1, normalized))
        return clamped * width
    }

    // MARK: - Metrics Row

    private func metricsRow(_ pmc: PMCStatus) -> some View {
        let ramp = pmc.rampRate ?? 0

        return HStack(spacing: ECSpacing.md) {
            // CTL (Fitness)
            metricCard(
                title: "Fitness",
                subtitle: "CTL",
                value: String(format: "%.0f", pmc.ctl),
                icon: "chart.line.uptrend.xyaxis",
                color: .blue,
                interpretation: ctlInterpretation(pmc.ctl)
            )
            .staggeredAnimation(index: 0, totalCount: 3)

            // ATL (Fatigue)
            metricCard(
                title: "Fatigue",
                subtitle: "ATL",
                value: String(format: "%.0f", pmc.atl),
                icon: "bolt.fill",
                color: .orange,
                interpretation: atlInterpretation(pmc.atl)
            )
            .staggeredAnimation(index: 1, totalCount: 3)

            // Ramp Rate
            metricCard(
                title: "Ramp",
                subtitle: "TSS/sem",
                value: String(format: "%+.1f", ramp),
                icon: ramp >= 0 ? "arrow.up.right" : "arrow.down.right",
                color: ramp > 7 ? .red : (ramp > 5 ? .orange : (ramp < -2 ? .blue : .green)),
                interpretation: rampInterpretation(ramp)
            )
            .staggeredAnimation(index: 2, totalCount: 3)
        }
    }

    private func metricCard(title: String, subtitle: String, value: String, icon: String, color: Color, interpretation: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(themeManager.textSecondary)
            }

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.textPrimary)

            Text(interpretation)
                .font(.system(size: 8))
                .foregroundColor(color)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ECSpacing.xs)
        .background(color.opacity(0.1))
        .cornerRadius(ECRadius.sm)
    }

    // MARK: - Interpretations

    private func ctlInterpretation(_ ctl: Double) -> String {
        switch ctl {
        case ..<30: return "En construction"
        case 30..<50: return "Bonne base"
        case 50..<70: return "Très bonne"
        case 70..<90: return "Excellente"
        default: return "Niveau élite"
        }
    }

    private func atlInterpretation(_ atl: Double) -> String {
        switch atl {
        case ..<30: return "Bien reposé"
        case 30..<50: return "Fatigue normale"
        case 50..<70: return "Fatigue modérée"
        case 70..<90: return "Fatigue élevée"
        default: return "Repos nécessaire"
        }
    }

    private func rampInterpretation(_ ramp: Double) -> String {
        switch ramp {
        case ..<0: return "Récupération"
        case 0..<3: return "Progression douce"
        case 3..<5: return "Progression idéale"
        case 5..<7: return "Progression rapide"
        default: return "Attention ⚠️"
        }
    }

    // MARK: - Alerts View

    private func alertsView(_ alerts: [PMCAlert]) -> some View {
        VStack(spacing: ECSpacing.xs) {
            ForEach(alerts) { alert in
                HStack(spacing: ECSpacing.sm) {
                    Image(systemName: alert.severityIcon)
                        .font(.system(size: 12))
                        .foregroundColor(alert.severityColor)

                    Text(alert.message)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                        .lineLimit(2)

                    Spacer()
                }
                .padding(ECSpacing.sm)
                .background(alert.severityColor.opacity(0.1))
                .cornerRadius(ECRadius.sm)
            }
        }
    }

    // MARK: - Recommendation View

    @ViewBuilder
    private func recommendationView(_ pmc: PMCStatus) -> some View {
        if let recommendation = pmc.recommendation, !recommendation.isEmpty {
            HStack(spacing: ECSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.warningColor)

                Text(recommendation)
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
                    .lineLimit(2)

                Spacer()
            }
            .padding(ECSpacing.sm)
            .background(themeManager.warningColor.opacity(0.1))
            .cornerRadius(ECRadius.sm)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Spacer()
        }
        .frame(height: 100)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: ECSpacing.sm) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 24))
                .foregroundColor(themeManager.textTertiary)

            Text("Données insuffisantes")
                .font(.ecCaption)
                .foregroundColor(themeManager.textSecondary)

            Text("Enregistrez plus d'activités pour voir votre état de forme")
                .font(.system(size: 11))
                .foregroundColor(themeManager.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ECSpacing.md)
    }
}

// MARK: - Mini PMC Widget (pour intégration compacte)

struct PMCStatusMiniWidget: View {
    @EnvironmentObject var themeManager: ThemeManager
    let pmcStatus: PMCStatus

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Emoji et label
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: ECSpacing.xs) {
                    Image(systemName: pmcStatus.formIcon)
                        .font(.system(size: 18))
                        .foregroundColor(pmcStatus.formColor)

                    Text(pmcStatus.formLabel)
                        .font(.ecBodyMedium)
                        .foregroundColor(pmcStatus.formColor)
                }

                Text("TSB: \(String(format: "%.1f", pmcStatus.tsb))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(themeManager.textSecondary)
            }

            Spacer()

            // Mini métriques
            HStack(spacing: ECSpacing.md) {
                miniMetric(label: "CTL", value: pmcStatus.ctl)
                miniMetric(label: "ATL", value: pmcStatus.atl)
            }
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.md)
    }

    private func miniMetric(label: String, value: Double) -> some View {
        VStack(spacing: 0) {
            Text(String(format: "%.0f", value))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.textPrimary)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(themeManager.textTertiary)
        }
    }
}

// MARK: - PMC Alerts Banner

/// Banner d'alertes PMC affiché en haut du Dashboard
struct PMCAlertsBanner: View {
    @EnvironmentObject var themeManager: ThemeManager
    let alerts: [PMCAlert]
    @State private var isDismissed = false
    @State private var currentAlertIndex = 0

    var body: some View {
        if !isDismissed && !alerts.isEmpty {
            VStack(spacing: 0) {
                // Alerte principale (la plus critique)
                let sortedAlerts = alerts.sorted { severity($0) > severity($1) }
                let currentAlert = sortedAlerts[currentAlertIndex % sortedAlerts.count]

                HStack(spacing: ECSpacing.sm) {
                    // Icône contextuelle
                    Image(systemName: alertIcon(currentAlert))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 24)

                    // Message
                    VStack(alignment: .leading, spacing: 2) {
                        Text(alertTitle(currentAlert))
                            .font(.ecCaptionBold)
                            .foregroundColor(.white)

                        Text(currentAlert.message)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }

                    Spacer()

                    // Indicateur de nombre d'alertes + navigation
                    if sortedAlerts.count > 1 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentAlertIndex = (currentAlertIndex + 1) % sortedAlerts.count
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("\(currentAlertIndex + 1)/\(sortedAlerts.count)")
                                    .font(.system(size: 10, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    // Bouton fermer
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isDismissed = true
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(4)
                    }
                }
                .padding(ECSpacing.sm)
                .background(currentAlert.severityColor.gradient)
                .cornerRadius(ECRadius.md)
            }
        }
    }

    private func severity(_ alert: PMCAlert) -> Int {
        switch alert.severity.lowercased() {
        case "critical": return 3
        case "warning": return 2
        case "info": return 1
        default: return 0
        }
    }

    private func alertIcon(_ alert: PMCAlert) -> String {
        switch alert.type.lowercased() {
        case "overtraining", "high_fatigue":
            return "flame.fill"
        case "ramp_too_fast":
            return "arrow.up.right.circle.fill"
        case "detraining", "low_fitness":
            return "arrow.down.right.circle.fill"
        case "injury_risk":
            return "exclamationmark.shield.fill"
        case "recovery_needed":
            return "bed.double.fill"
        case "optimal_form":
            return "star.fill"
        default:
            return "info.circle.fill"
        }
    }

    private func alertTitle(_ alert: PMCAlert) -> String {
        switch alert.type.lowercased() {
        case "overtraining", "high_fatigue":
            return "Attention surcharge"
        case "ramp_too_fast":
            return "Progression rapide"
        case "detraining", "low_fitness":
            return "Perte de forme"
        case "injury_risk":
            return "Risque de blessure"
        case "recovery_needed":
            return "Récupération conseillée"
        case "optimal_form":
            return "Forme optimale"
        default:
            return "Information"
        }
    }
}

// MARK: - PMC Alert Notification Helper

/// Helper pour déclencher des alertes locales basées sur le PMC
struct PMCAlertNotificationHelper {
    static func checkAndNotify(pmc: PMCStatus) {
        guard pmc.hasCriticalAlert else { return }
        // Les alertes critiques pourraient déclencher une notification locale
        // TODO: Implémenter les notifications locales
    }
}

// MARK: - Preview

#Preview("PMC Widget - Normal") {
    PMCStatusWidget(
        pmcStatus: .preview,
        isLoading: false,
        onTap: {}
    )
    .padding()
    .background(Color.gray.opacity(0.1))
    .environmentObject(ThemeManager.shared)
}

#Preview("PMC Widget - Fatigued") {
    PMCStatusWidget(
        pmcStatus: .previewFatigued,
        isLoading: false,
        onTap: {}
    )
    .padding()
    .background(Color.gray.opacity(0.1))
    .environmentObject(ThemeManager.shared)
}

#Preview("PMC Widget - Fresh") {
    PMCStatusWidget(
        pmcStatus: .previewFresh,
        isLoading: false,
        onTap: {}
    )
    .padding()
    .background(Color.gray.opacity(0.1))
    .environmentObject(ThemeManager.shared)
}

#Preview("PMC Mini Widget") {
    PMCStatusMiniWidget(pmcStatus: .preview)
        .padding()
        .background(Color.gray.opacity(0.1))
        .environmentObject(ThemeManager.shared)
}

#Preview("PMC Alerts Banner") {
    VStack(spacing: 16) {
        PMCAlertsBanner(alerts: [
            PMCAlert(type: "overtraining", severity: "critical", message: "Risque de surmenage détecté. Réduisez l'intensité."),
            PMCAlert(type: "ramp_too_fast", severity: "warning", message: "Progression rapide (+3.5 TSS/sem)")
        ])

        PMCAlertsBanner(alerts: [
            PMCAlert(type: "recovery_needed", severity: "warning", message: "Une journée de récupération est recommandée")
        ])

        PMCAlertsBanner(alerts: [
            PMCAlert(type: "optimal_form", severity: "info", message: "Forme optimale pour une compétition")
        ])
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .environmentObject(ThemeManager.shared)
}
