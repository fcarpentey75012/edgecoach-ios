/**
 * SessionBriefingView - Briefing IA immersif pour les séances
 * Phase 2.1 : Composants Story
 * Phase 2.3 : Connexion aux données réelles du Coach
 */

import SwiftUI

/// Vue spécifique pour le briefing d'une séance
/// Connectée aux données réelles de PlannedSession
struct SessionBriefingView: View {
    @EnvironmentObject var themeManager: ThemeManager

    /// Séance planifiée (données réelles)
    let session: PlannedSession
    /// Statut PMC pour le contexte de récupération (optionnel)
    var pmcStatus: PMCStatus?
    /// Callback de fermeture
    let onClose: () -> Void

    /// Génère les slides dynamiquement à partir des données réelles
    private var slides: [BriefingSlide] {
        var result: [BriefingSlide] = []

        // Slide 1: Intro - L'objectif du jour
        let recoveryText = generateRecoveryText()
        result.append(BriefingSlide(
            type: .intro,
            title: "Objectif du jour",
            subtitle: session.intensity ?? session.zone ?? "Entraînement",
            content: recoveryText,
            accentColor: themeManager.sportColor(for: session.discipline)
        ))

        // Slide 2: Structure - Le menu de la séance
        let structureText = generateStructureText()
        result.append(BriefingSlide(
            type: .structure,
            title: "Au menu",
            subtitle: session.formattedDuration ?? "\(session.dureeMinutes) min",
            content: structureText,
            accentColor: .orange,
            structureData: generateStructureData()
        ))

        // Slide 3: Focus - Conseil technique
        let focusText = generateFocusText()
        result.append(BriefingSlide(
            type: .focus,
            title: "Focus Technique",
            subtitle: session.focus ?? "Exécution",
            content: focusText,
            accentColor: .green,
            educatifs: session.educatifs
        ))

        return result
    }

    var body: some View {
        StoryContainerView(count: slides.count, onComplete: onClose) { index in
            SlideView(slide: slides[index], sessionTitle: session.displayTitle, discipline: session.discipline)
        }
    }

    // MARK: - Text Generation

    private func generateRecoveryText() -> String {
        var text = ""

        // Ajouter le contexte PMC si disponible
        if let pmc = pmcStatus {
            let formPercentage = Int((1 - abs(pmc.tsb) / 50) * 100)
            if pmc.tsb > 10 {
                text = "Ta récupération est excellente (\(formPercentage)%). "
            } else if pmc.tsb > 0 {
                text = "Tu es bien reposé (\(formPercentage)%). "
            } else if pmc.tsb > -15 {
                text = "Ta charge est équilibrée. "
            } else {
                text = "Attention à la fatigue accumulée. "
            }
        }

        // Ajouter le contexte de la séance
        if let intensity = session.intensity {
            switch intensity.lowercased() {
            case "endurance", "récupération", "z1", "z2":
                text += "Cette séance vise à développer ton endurance fondamentale sans surcharger ton organisme."
            case "seuil", "tempo", "z3", "z4":
                text += "L'objectif est de travailler au seuil pour améliorer ta capacité à maintenir un effort intense."
            case "intervalle", "pma", "vo2max", "z5", "z6":
                text += "Séance de haute intensité pour repousser tes limites cardiovasculaires."
            case "force", "musculation":
                text += "Focus sur le renforcement musculaire et la puissance."
            default:
                text += "Séance conçue pour améliorer tes capacités dans cette discipline."
            }
        } else if let description = session.description {
            text += description
        } else {
            text += "Cette séance est adaptée à ton niveau actuel et à tes objectifs."
        }

        return text
    }

    private func generateStructureText() -> String {
        var parts: [String] = []

        if session.dureeMinutes > 60 {
            parts.append("Séance de \(session.formattedDuration ?? "\(session.dureeMinutes) min") avec échauffement progressif")
        } else {
            parts.append("Séance courte et efficace de \(session.formattedDuration ?? "\(session.dureeMinutes) min")")
        }

        if let distance = session.formattedDistance {
            parts.append("pour parcourir \(distance)")
        }

        if let zone = session.zone {
            parts.append("en zone \(zone)")
        }

        var result = parts.joined(separator: " ")

        if let coachInstructions = session.coachInstructions, !coachInstructions.isEmpty {
            result += ". " + coachInstructions
        } else {
            result += ". Garde de l'énergie pour la fin !"
        }

        return result
    }

    private func generateFocusText() -> String {
        if let focus = session.focus, !focus.isEmpty {
            return focus
        }

        // Générer un focus basé sur la discipline
        switch session.discipline {
        case .cyclisme:
            if let zone = session.zone?.uppercased() {
                if zone.contains("5") || zone.contains("6") {
                    return "Maintiens une cadence élevée (90-100 rpm) sur les intervalles intenses pour réduire la charge musculaire."
                }
            }
            return "Travaille ta position aérodynamique et garde une cadence fluide autour de 85-95 rpm."

        case .course:
            return "Concentre-toi sur une foulée légère et régulière. Évite de partir trop vite, monte en puissance progressivement."

        case .natation:
            return "Pense à l'allongement de ta coulée et à une respiration régulière tous les 3 mouvements."

        case .autre:
            return "Reste concentré sur la qualité de tes mouvements plutôt que sur l'intensité."
        }
    }

    /// Génère les données pour le graphique de structure
    private func generateStructureData() -> [StructureBar] {
        var bars: [StructureBar] = []

        // Échauffement (20% du temps)
        let warmupDuration = Int(Double(session.dureeMinutes) * 0.2)
        bars.append(StructureBar(duration: warmupDuration, intensity: .low, label: "Échauff."))

        // Corps de séance basé sur l'intensité
        if let intensity = session.intensity?.lowercased() {
            if intensity.contains("intervalle") || intensity.contains("pma") || intensity.contains("vo2") {
                // Intervalles
                let intervalDuration = Int(Double(session.dureeMinutes) * 0.15)
                for i in 0..<4 {
                    bars.append(StructureBar(duration: intervalDuration, intensity: .high, label: "Int. \(i+1)"))
                    if i < 3 {
                        bars.append(StructureBar(duration: intervalDuration / 2, intensity: .low, label: "Récup"))
                    }
                }
            } else if intensity.contains("seuil") || intensity.contains("tempo") {
                // Bloc au seuil
                let thresholdDuration = Int(Double(session.dureeMinutes) * 0.6)
                bars.append(StructureBar(duration: thresholdDuration, intensity: .medium, label: "Seuil"))
            } else {
                // Endurance continue
                let mainDuration = Int(Double(session.dureeMinutes) * 0.6)
                bars.append(StructureBar(duration: mainDuration, intensity: .medium, label: "Corps"))
            }
        } else {
            // Par défaut, bloc principal
            let mainDuration = Int(Double(session.dureeMinutes) * 0.6)
            bars.append(StructureBar(duration: mainDuration, intensity: .medium, label: "Corps"))
        }

        // Retour au calme (20% du temps)
        let cooldownDuration = Int(Double(session.dureeMinutes) * 0.2)
        bars.append(StructureBar(duration: cooldownDuration, intensity: .low, label: "Retour"))

        return bars
    }
}

// MARK: - Legacy Init (compatibilité)

extension SessionBriefingView {
    /// Init legacy pour compatibilité avec l'ancien code
    init(sessionTitle: String, sessionDuration: String, onClose: @escaping () -> Void) {
        // Créer une session fictive pour la compatibilité
        self.session = PlannedSession(
            id: UUID().uuidString,
            userId: "",
            date: ISO8601DateFormatter().string(from: Date()),
            discipline: .autre,
            name: sessionTitle,
            dureeMinutes: Self.parseDuration(sessionDuration)
        )
        self.pmcStatus = nil
        self.onClose = onClose
    }

    private static func parseDuration(_ duration: String) -> Int {
        // Parse "1:30" ou "45min" vers minutes
        if duration.contains(":") {
            let parts = duration.split(separator: ":")
            if parts.count == 2, let hours = Int(parts[0]), let mins = Int(parts[1]) {
                return hours * 60 + mins
            }
        } else if duration.lowercased().contains("min") {
            let cleaned = duration.lowercased().replacingOccurrences(of: "min", with: "").trimmingCharacters(in: .whitespaces)
            return Int(cleaned) ?? 60
        }
        return 60
    }
}

// MARK: - Models & Subviews

enum SlideType {
    case intro, structure, focus

    var icon: String {
        switch self {
        case .intro: return "brain.head.profile"
        case .structure: return "chart.bar.fill"
        case .focus: return "scope"
        }
    }
}

struct BriefingSlide {
    let type: SlideType
    let title: String
    let subtitle: String
    let content: String
    let accentColor: Color
    var structureData: [StructureBar]?
    var educatifs: [String]?

    init(type: SlideType, title: String, subtitle: String, content: String, accentColor: Color, structureData: [StructureBar]? = nil, educatifs: [String]? = nil) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.accentColor = accentColor
        self.structureData = structureData
        self.educatifs = educatifs
    }
}

struct StructureBar: Identifiable {
    let id = UUID()
    let duration: Int
    let intensity: Intensity
    let label: String

    enum Intensity {
        case low, medium, high

        var heightRatio: CGFloat {
            switch self {
            case .low: return 0.3
            case .medium: return 0.6
            case .high: return 1.0
            }
        }
    }
}

struct SlideView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let slide: BriefingSlide
    let sessionTitle: String
    let discipline: Discipline

    @State private var appear = false

    var body: some View {
        ZStack {
            // Fond dégradé subtil
            LinearGradient(
                colors: [Color.black, Color(hex: "1C1C1E")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                // Header commun
                HStack {
                    Image(systemName: slide.type.icon)
                        .font(.title2)
                        .foregroundColor(slide.accentColor)

                    Text(sessionTitle.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)

                    Spacer()

                    // Badge discipline
                    HStack(spacing: 4) {
                        DisciplineIconView(discipline: discipline, size: 12)
                        Text(discipline.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(themeManager.sportColor(for: discipline))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.sportColor(for: discipline).opacity(0.2))
                    .cornerRadius(ECRadius.sm)
                }
                .padding(.top, 100)

                // Contenu spécifique animé
                VStack(alignment: .leading, spacing: 16) {
                    Text(slide.title)
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .offset(y: appear ? 0 : 20)
                        .opacity(appear ? 1 : 0)

                    Text(slide.subtitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(slide.accentColor)
                        .offset(y: appear ? 0 : 20)
                        .opacity(appear ? 1 : 0)

                    Rectangle()
                        .fill(slide.accentColor.opacity(0.3))
                        .frame(height: 1)
                        .padding(.vertical, 8)
                        .scaleEffect(x: appear ? 1 : 0, anchor: .leading)

                    Text(slide.content)
                        .font(.body)
                        .lineSpacing(6)
                        .foregroundColor(Color(hex: "E5E5EA"))
                        .offset(y: appear ? 0 : 20)
                        .opacity(appear ? 1 : 0)

                    // Graphique de structure (slide structure)
                    if slide.type == .structure, let bars = slide.structureData {
                        StructureChartView(bars: bars, accentColor: slide.accentColor, appear: appear)
                            .padding(.top, 20)
                    }

                    // Liste des éducatifs (slide focus)
                    if slide.type == .focus, let educatifs = slide.educatifs, !educatifs.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Points clés")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .padding(.top, 16)

                            ForEach(Array(educatifs.enumerated()), id: \.offset) { index, educatif in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(slide.accentColor)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 6)

                                    Text(educatif)
                                        .font(.subheadline)
                                        .foregroundColor(Color(hex: "E5E5EA"))
                                }
                                .opacity(appear ? 1 : 0)
                                .offset(y: appear ? 0 : 10)
                                .animation(.spring(response: 0.4).delay(Double(index) * 0.1), value: appear)
                            }
                        }
                    }
                }

                Spacer()

                // Indication sur la dernière slide
                if slide.type == .focus {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "hand.tap.fill")
                                .font(.title3)
                                .foregroundColor(.gray)
                            Text("Toucher pour fermer")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 40)
                    .opacity(appear ? 1 : 0)
                }
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                appear = true
            }
        }
        .onDisappear {
            appear = false
        }
    }
}

/// Vue graphique pour la structure de la séance
struct StructureChartView: View {
    let bars: [StructureBar]
    let accentColor: Color
    let appear: Bool

    private let maxHeight: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(bars.enumerated()), id: \.element.id) { index, bar in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorForIntensity(bar.intensity))
                            .frame(height: appear ? maxHeight * bar.intensity.heightRatio : 0)
                            .animation(.spring(response: 0.5).delay(Double(index) * 0.08), value: appear)

                        Text(bar.label)
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: maxHeight + 20)
        }
        .scaleEffect(appear ? 1 : 0.8)
        .opacity(appear ? 1 : 0)
    }

    private func colorForIntensity(_ intensity: StructureBar.Intensity) -> Color {
        switch intensity {
        case .low: return Color.gray.opacity(0.4)
        case .medium: return accentColor.opacity(0.7)
        case .high: return accentColor
        }
    }
}

// MARK: - Discipline Icon View

/// Vue d'icône pour une discipline sportive
struct DisciplineIconView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let discipline: Discipline
    let size: CGFloat
    var useCustomImage: Bool = false

    var body: some View {
        if useCustomImage, let customIcon = customIconName {
            // Utiliser l'icône custom si disponible
            Image(customIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            // Utiliser l'icône SF Symbols par défaut
            Image(systemName: discipline.icon)
                .font(.system(size: size))
                .foregroundColor(themeManager.sportColor(for: discipline))
        }
    }

    /// Nom de l'icône custom pour la discipline
    private var customIconName: String? {
        switch discipline {
        case .cyclisme:
            return "cycling"
        case .course:
            return "running"
        case .natation:
            return "swimming"
        case .autre:
            return nil // Pas d'icône custom pour cette discipline
        }
    }
}

// MARK: - Preview

#Preview {
    let mockSession = PlannedSession(
        id: "preview-1",
        userId: "user-1",
        date: "2024-12-26",
        discipline: .cyclisme,
        name: "Intervalles PMA",
        dureeMinutes: 90,
        volumeMeters: 45000,
        intensity: "Intervalle",
        description: "4x5min à PMA avec 3min récup",
        educatifs: ["Cadence haute 90-100 rpm", "Respiration régulière", "Relâchement des épaules"]
    )

    SessionBriefingView(session: mockSession, pmcStatus: nil) {
        print("Closed")
    }
    .environmentObject(ThemeManager.shared)
}
