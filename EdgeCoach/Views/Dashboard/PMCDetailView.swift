/**
 * PMCDetailView - Vue détaillée de l'état de forme (CTL/ATL/TSB)
 * Affiche des jauges visuelles avec zones colorées et explications
 * Permet de demander une analyse personnalisée du coach IA
 */

import SwiftUI

// MARK: - PMC Detail View

struct PMCDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PMCDetailViewModel

    let pmcStatus: PMCStatus

    init(pmcStatus: PMCStatus, userId: String) {
        self.pmcStatus = pmcStatus
        self._viewModel = StateObject(wrappedValue: PMCDetailViewModel(userId: userId))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    // Header avec statut principal
                    statusHeader

                    // Jauge TSB détaillée
                    tsbDetailSection

                    // Jauges CTL et ATL
                    fitnessAndFatigueSection

                    // Ramp Rate
                    rampRateSection

                    // Alertes actives
                    if !pmcStatus.alerts.isEmpty {
                        alertsSection
                    }

                    // Section Analyse Coach IA
                    coachAnalysisSection

                    // Légende éducative
                    educationalSection
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("État de forme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }

    // MARK: - Status Header

    private var statusHeader: some View {
        VStack(spacing: ECSpacing.sm) {
            // Icône et label
            HStack(spacing: ECSpacing.md) {
                Image(systemName: pmcStatus.formIcon)
                    .font(.system(size: 48))
                    .foregroundColor(pmcStatus.formColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pmcStatus.formLabel)
                        .font(.ecH2)
                        .foregroundColor(pmcStatus.formColor)

                    Text(formDescription)
                        .font(.ecBody)
                        .foregroundColor(themeManager.textSecondary)
                }
            }

            // TSB value
            HStack {
                Text("TSB")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textTertiary)
                Text(String(format: "%+.1f", pmcStatus.tsb))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(pmcStatus.tsbColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .fill(themeManager.cardColor)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }

    private var formDescription: String {
        switch pmcStatus.tsb {
        case ..<(-30): return "Fatigue critique - Repos obligatoire"
        case -30..<(-20): return "Très fatigué - Récupération nécessaire"
        case -20..<(-10): return "Fatigué - Phase de charge normale"
        case -10..<5: return "Équilibré - Zone optimale d'entraînement"
        case 5..<15: return "Frais - Prêt à performer"
        case 15..<25: return "Très frais - Fenêtre de compétition"
        default: return "Fraîcheur maximale - Idéal pour un objectif"
        }
    }

    // MARK: - TSB Detail Section

    private var tsbDetailSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader(title: "Forme (TSB)", icon: "waveform.path.ecg")

            // Jauge avec zones colorées
            VStack(spacing: ECSpacing.xs) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Zones colorées
                        HStack(spacing: 0) {
                            // Zone rouge (-30 et moins)
                            Rectangle()
                                .fill(Color.red.opacity(0.3))
                                .frame(width: geometry.size.width * 0.167)
                            // Zone orange (-20 à -30)
                            Rectangle()
                                .fill(Color.orange.opacity(0.3))
                                .frame(width: geometry.size.width * 0.167)
                            // Zone jaune (-10 à -20)
                            Rectangle()
                                .fill(Color.yellow.opacity(0.3))
                                .frame(width: geometry.size.width * 0.167)
                            // Zone verte (-10 à +10)
                            Rectangle()
                                .fill(Color.green.opacity(0.3))
                                .frame(width: geometry.size.width * 0.25)
                            // Zone bleue (+10 à +20)
                            Rectangle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: geometry.size.width * 0.167)
                            // Zone violette (+20 et plus)
                            Rectangle()
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: geometry.size.width * 0.082)
                        }
                        .frame(height: 24)
                        .cornerRadius(ECRadius.sm)

                        // Indicateur
                        let position = tsbPosition(pmcStatus.tsb, width: geometry.size.width)
                        VStack(spacing: 0) {
                            Triangle()
                                .fill(pmcStatus.tsbColor)
                                .frame(width: 12, height: 8)
                            Rectangle()
                                .fill(pmcStatus.tsbColor)
                                .frame(width: 3, height: 24)
                        }
                        .offset(x: position - 6, y: -8)
                    }
                }
                .frame(height: 32)

                // Labels des zones
                HStack {
                    Text("-30")
                    Spacer()
                    Text("-20")
                    Spacer()
                    Text("-10")
                    Spacer()
                    Text("0")
                    Spacer()
                    Text("+10")
                    Spacer()
                    Text("+20")
                    Spacer()
                    Text("+30")
                }
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(themeManager.textTertiary)

                // Légende rapide
                HStack {
                    zoneLegend(color: .red, label: "Surcharge")
                    zoneLegend(color: .yellow, label: "Charge")
                    zoneLegend(color: .green, label: "Optimal")
                    zoneLegend(color: .blue, label: "Frais")
                }
                .padding(.top, ECSpacing.xs)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .fill(themeManager.cardColor)
        )
    }

    private func tsbPosition(_ tsb: Double, width: CGFloat) -> CGFloat {
        let normalized = (tsb + 30) / 60
        let clamped = max(0, min(1, normalized))
        return clamped * width
    }

    private func zoneLegend(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color.opacity(0.5))
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(themeManager.textSecondary)
        }
    }

    // MARK: - Fitness and Fatigue Section

    private var fitnessAndFatigueSection: some View {
        HStack(spacing: ECSpacing.md) {
            // CTL (Fitness)
            metricGauge(
                title: "Fitness (CTL)",
                value: pmcStatus.ctl,
                maxValue: 100,
                color: .blue,
                icon: "chart.line.uptrend.xyaxis",
                interpretation: ctlInterpretation,
                zones: [
                    (0, 30, "Débutant", Color.gray),
                    (30, 50, "Intermédiaire", Color.blue.opacity(0.5)),
                    (50, 70, "Avancé", Color.blue),
                    (70, 100, "Élite", Color.purple)
                ]
            )

            // ATL (Fatigue)
            metricGauge(
                title: "Fatigue (ATL)",
                value: pmcStatus.atl,
                maxValue: 100,
                color: .orange,
                icon: "bolt.fill",
                interpretation: atlInterpretation,
                zones: [
                    (0, 30, "Reposé", Color.green),
                    (30, 50, "Normal", Color.yellow),
                    (50, 70, "Modéré", Color.orange),
                    (70, 100, "Élevé", Color.red)
                ]
            )
        }
    }

    private var ctlInterpretation: String {
        switch pmcStatus.ctl {
        case ..<30: return "Base en construction. Focus sur le volume."
        case 30..<50: return "Bonne condition. Continue la progression."
        case 50..<70: return "Très bonne forme. Tu peux intensifier."
        case 70..<90: return "Excellente condition physique."
        default: return "Niveau élite. Gère bien ta récupération."
        }
    }

    private var atlInterpretation: String {
        switch pmcStatus.atl {
        case ..<30: return "Bien reposé. Prêt pour un bloc de travail."
        case 30..<50: return "Fatigue normale d'entraînement."
        case 50..<70: return "Fatigue modérée. Surveille ton ressenti."
        case 70..<90: return "Fatigue élevée. Prévoir de la récup."
        default: return "Fatigue très élevée. Repos nécessaire."
        }
    }

    private func metricGauge(
        title: String,
        value: Double,
        maxValue: Double,
        color: Color,
        icon: String,
        interpretation: String,
        zones: [(Double, Double, String, Color)]
    ) -> some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Text(title)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            // Valeur
            Text(String(format: "%.0f", value))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)

            // Jauge avec zones
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Zones
                    HStack(spacing: 0) {
                        ForEach(zones, id: \.2) { zone in
                            let zoneWidth = (zone.1 - zone.0) / maxValue * geometry.size.width
                            Rectangle()
                                .fill(zone.3.opacity(0.3))
                                .frame(width: zoneWidth)
                        }
                    }
                    .frame(height: 12)
                    .cornerRadius(6)

                    // Indicateur
                    let position = min(value / maxValue, 1.0) * geometry.size.width
                    Circle()
                        .fill(color)
                        .frame(width: 16, height: 16)
                        .shadow(color: color.opacity(0.5), radius: 3)
                        .offset(x: position - 8)
                }
            }
            .frame(height: 16)

            // Zone actuelle
            if let currentZone = zones.first(where: { value >= $0.0 && value < $0.1 }) {
                Text("▲ \(currentZone.2)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(currentZone.3)
            }

            // Interprétation
            Text(interpretation)
                .font(.system(size: 11))
                .foregroundColor(themeManager.textSecondary)
                .lineLimit(2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: ECRadius.md)
                .fill(themeManager.cardColor)
        )
    }

    // MARK: - Ramp Rate Section

    private var rampRateSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader(title: "Progression (Ramp Rate)", icon: "arrow.up.right")

            let ramp = pmcStatus.rampRate ?? 0

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%+.1f", ramp))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(rampColor(ramp))

                    Text("CTL/semaine")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }

                Spacer()

                // Indicateur visuel
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: rampIcon(ramp))
                        .font(.system(size: 32))
                        .foregroundColor(rampColor(ramp))

                    Text(rampLabel(ramp))
                        .font(.ecCaptionBold)
                        .foregroundColor(rampColor(ramp))
                }
            }

            // Barre de progression
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Zones
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.blue.opacity(0.3))
                            .frame(width: geometry.size.width * 0.2) // < 0
                        Rectangle().fill(Color.green.opacity(0.3))
                            .frame(width: geometry.size.width * 0.3) // 0-5
                        Rectangle().fill(Color.orange.opacity(0.3))
                            .frame(width: geometry.size.width * 0.2) // 5-7
                        Rectangle().fill(Color.red.opacity(0.3))
                            .frame(width: geometry.size.width * 0.3) // > 7
                    }
                    .frame(height: 12)
                    .cornerRadius(6)

                    // Position
                    let normalizedRamp = (ramp + 5) / 15 // -5 à +10 mappé sur 0-1
                    let position = max(0, min(1, normalizedRamp)) * geometry.size.width
                    Circle()
                        .fill(rampColor(ramp))
                        .frame(width: 16, height: 16)
                        .shadow(color: rampColor(ramp).opacity(0.5), radius: 3)
                        .offset(x: position - 8)
                }
            }
            .frame(height: 16)

            // Labels
            HStack {
                Text("Récup")
                Spacer()
                Text("Idéal")
                Spacer()
                Text("Rapide")
                Spacer()
                Text("Danger")
            }
            .font(.system(size: 9))
            .foregroundColor(themeManager.textTertiary)

            // Explication
            Text(rampExplanation(ramp))
                .font(.ecCaption)
                .foregroundColor(themeManager.textSecondary)
                .padding(.top, ECSpacing.xs)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .fill(themeManager.cardColor)
        )
    }

    private func rampColor(_ ramp: Double) -> Color {
        switch ramp {
        case ..<0: return .blue
        case 0..<5: return .green
        case 5..<7: return .orange
        default: return .red
        }
    }

    private func rampIcon(_ ramp: Double) -> String {
        switch ramp {
        case ..<0: return "arrow.down.right.circle.fill"
        case 0..<3: return "arrow.right.circle.fill"
        case 3..<5: return "arrow.up.right.circle.fill"
        case 5..<7: return "exclamationmark.triangle.fill"
        default: return "xmark.octagon.fill"
        }
    }

    private func rampLabel(_ ramp: Double) -> String {
        switch ramp {
        case ..<0: return "Récupération"
        case 0..<3: return "Stable"
        case 3..<5: return "Idéal"
        case 5..<7: return "Rapide"
        default: return "Danger"
        }
    }

    private func rampExplanation(_ ramp: Double) -> String {
        switch ramp {
        case ..<0: return "Tu récupères. Ton CTL diminue, ce qui est normal après un bloc de charge ou une coupure."
        case 0..<3: return "Progression très douce. Tu maintiens ta forme sans trop de stress."
        case 3..<5: return "Progression idéale. Tu construis ta fitness de manière optimale et durable."
        case 5..<7: return "Progression rapide. Surveille les signes de fatigue et prévois une semaine allégée."
        default: return "⚠️ Progression trop rapide. Risque de blessure élevé. Réduis immédiatement la charge."
        }
    }

    // MARK: - Alerts Section

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader(title: "Alertes actives", icon: "exclamationmark.triangle.fill")

            ForEach(pmcStatus.alerts) { alert in
                HStack(spacing: ECSpacing.sm) {
                    Image(systemName: alert.severityIcon)
                        .font(.system(size: 16))
                        .foregroundColor(alert.severityColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(alert.type.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.ecCaptionBold)
                            .foregroundColor(themeManager.textPrimary)
                        Text(alert.message)
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    Spacer()
                }
                .padding()
                .background(alert.severityColor.opacity(0.1))
                .cornerRadius(ECRadius.md)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .fill(themeManager.cardColor)
        )
    }

    // MARK: - Coach Analysis Section

    private var coachAnalysisSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader(title: "Analyse Coach IA", icon: "brain.head.profile")

            if viewModel.isLoadingAnalysis {
                HStack {
                    Spacer()
                    VStack(spacing: ECSpacing.sm) {
                        ProgressView()
                        Text("Analyse en cours...")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, ECSpacing.lg)
            } else if let analysis = viewModel.coachAnalysis {
                // Affichage de l'analyse en Markdown
                VStack(alignment: .leading, spacing: ECSpacing.md) {
                    Text(markdownToAttributedString(analysis))
                        .font(.ecBody)
                        .foregroundColor(themeManager.textPrimary)
                        .lineSpacing(4)
                        .textSelection(.enabled)

                    // Actions recommandées
                    if !viewModel.actionItems.isEmpty {
                        VStack(alignment: .leading, spacing: ECSpacing.xs) {
                            Text("Actions recommandées")
                                .font(.ecCaptionBold)
                                .foregroundColor(themeManager.textSecondary)

                            ForEach(viewModel.actionItems, id: \.self) { action in
                                HStack(alignment: .top, spacing: ECSpacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                    Text(action)
                                        .font(.ecCaption)
                                        .foregroundColor(themeManager.textPrimary)
                                }
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(ECRadius.md)
                    }

                    // Bouton pour nouvelle analyse
                    Button {
                        viewModel.requestAnalysis()
                    } label: {
                        Label("Actualiser l'analyse", systemImage: "arrow.clockwise")
                            .font(.ecCaption)
                    }
                    .buttonStyle(.premium)
                }
            } else {
                // Bouton pour demander l'analyse
                VStack(spacing: ECSpacing.md) {
                    Text("Obtiens une analyse personnalisée de ton état de forme par notre coach IA.")
                        .font(.ecBody)
                        .foregroundColor(themeManager.textSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        viewModel.requestAnalysis()
                    } label: {
                        Label("Demander une analyse", systemImage: "sparkles")
                            .font(.ecBodyMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.accentColor.gradient)
                            .cornerRadius(ECRadius.md)
                    }
                    .buttonStyle(.premium)
                }
            }

            // Erreur
            if let error = viewModel.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(ECRadius.sm)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .fill(themeManager.cardColor)
        )
    }

    // MARK: - Educational Section

    private var educationalSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader(title: "Comprendre le PMC", icon: "book.fill")

            VStack(alignment: .leading, spacing: ECSpacing.md) {
                educationalItem(
                    term: "CTL (Chronic Training Load)",
                    definition: "Ta \"fitness\" accumulée sur ~42 jours. Plus elle est haute, plus tu es en forme pour les efforts d'endurance."
                )

                educationalItem(
                    term: "ATL (Acute Training Load)",
                    definition: "Ta \"fatigue\" des 7 derniers jours. Quand l'ATL dépasse le CTL, tu accumules de la fatigue."
                )

                educationalItem(
                    term: "TSB (Training Stress Balance)",
                    definition: "CTL - ATL = ta \"fraîcheur\". Positif = prêt à performer. Négatif = en phase de charge."
                )

                educationalItem(
                    term: "Ramp Rate",
                    definition: "Vitesse de progression du CTL par semaine. >7 = risque de blessure. 3-5 = idéal."
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .fill(themeManager.cardColor)
        )
    }

    private func educationalItem(term: String, definition: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(term)
                .font(.ecCaptionBold)
                .foregroundColor(themeManager.accentColor)
            Text(definition)
                .font(.ecCaption)
                .foregroundColor(themeManager.textSecondary)
        }
    }

    // MARK: - Helpers

    /// Convertit une chaîne Markdown en AttributedString
    private func markdownToAttributedString(_ markdown: String) -> AttributedString {
        do {
            var attributedString = try AttributedString(markdown: markdown, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
            return attributedString
        } catch {
            // Fallback si le parsing échoue
            return AttributedString(markdown)
        }
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: ECSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(themeManager.accentColor)
            Text(title)
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)
            Spacer()
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - PMC Detail ViewModel

@MainActor
class PMCDetailViewModel: ObservableObject {
    @Published var coachAnalysis: String?
    @Published var actionItems: [String] = []
    @Published var insights: [String] = []
    @Published var isLoadingAnalysis = false
    @Published var error: String?

    private let userId: String
    private let pmcService = PMCService.shared

    init(userId: String) {
        self.userId = userId
    }

    func requestAnalysis(type: PMCAnalysisType = .general) {
        isLoadingAnalysis = true
        error = nil

        Task {
            do {
                let result = try await pmcService.getAnalysis(userId: userId, type: type)
                self.coachAnalysis = result.response
                self.actionItems = result.actionItems
                self.insights = result.insights
                if let analysisError = result.error {
                    self.error = analysisError
                }
                self.isLoadingAnalysis = false
            } catch {
                self.error = "Impossible de charger l'analyse: \(error.localizedDescription)"
                self.isLoadingAnalysis = false
            }
        }
    }

    func askQuestion(_ question: String) {
        isLoadingAnalysis = true
        error = nil

        Task {
            do {
                let result = try await pmcService.askQuestion(userId: userId, question: question)
                self.coachAnalysis = result.response
                self.actionItems = result.actionItems
                self.insights = result.insights
                if let analysisError = result.error {
                    self.error = analysisError
                }
                self.isLoadingAnalysis = false
            } catch {
                self.error = "Impossible de charger la réponse: \(error.localizedDescription)"
                self.isLoadingAnalysis = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PMCDetailView(pmcStatus: .preview, userId: "preview_user")
        .environmentObject(ThemeManager.shared)
}

#Preview("Fatigued") {
    PMCDetailView(pmcStatus: .previewFatigued, userId: "preview_user")
        .environmentObject(ThemeManager.shared)
}
