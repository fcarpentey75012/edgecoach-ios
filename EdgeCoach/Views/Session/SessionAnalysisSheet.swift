/**
 * Modal de sélection d'analyse pour une séance
 * Permet de générer un message contextuel et naviguer vers le chat Coach
 */

import SwiftUI

// MARK: - Session Context

struct SessionContext {
    let sessionName: String
    let sessionDate: Date
    let discipline: Discipline
    let duration: TimeInterval?
    let distance: Double?
    let isCompleted: Bool

    /// Génère la description de la séance pour le message
    var sessionDescription: String {
        var parts: [String] = []

        if let duration = duration, duration > 0 {
            let hours = Int(duration) / 3600
            let minutes = (Int(duration) % 3600) / 60
            if hours > 0 {
                parts.append("\(hours)h\(String(format: "%02d", minutes))")
            } else {
                parts.append("\(minutes) min")
            }
        }

        if let distance = distance, distance > 0 {
            if distance >= 1000 {
                parts.append(String(format: "%.1f km", distance / 1000))
            } else {
                parts.append(String(format: "%.0f m", distance))
            }
        }

        return parts.isEmpty ? "" : "(\(parts.joined(separator: ", ")))"
    }

    /// Formate la date en français
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: sessionDate)
    }
}

// MARK: - Analysis Option

struct AnalysisOption: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Session Analysis Sheet

struct SessionAnalysisSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager

    let context: SessionContext
    var onNavigateToChat: (() -> Void)?

    @State private var customQuestion: String = ""
    @State private var selectedOption: AnalysisOption?
    @FocusState private var isCustomQuestionFocused: Bool

    // Options d'analyse par discipline
    private var analysisOptions: [AnalysisOption] {
        switch context.discipline {
        case .cyclisme:
            return [
                AnalysisOption(icon: "bolt.fill", title: "Analyse de puissance", description: "FTP, zones de puissance, distribution"),
                AnalysisOption(icon: "heart.fill", title: "Zones cardiaques", description: "Temps dans les zones, efficacité"),
                AnalysisOption(icon: "arrow.triangle.2.circlepath", title: "Efficacité pédalage", description: "Cadence, équilibre gauche/droite"),
                AnalysisOption(icon: "chart.line.uptrend.xyaxis", title: "Performance globale", description: "Points forts, axes d'amélioration")
            ]
        case .course:
            return [
                AnalysisOption(icon: "speedometer", title: "Analyse des allures", description: "Vitesse, régularité, split times"),
                AnalysisOption(icon: "heart.fill", title: "Fréquence cardiaque", description: "Zones, dérive cardiaque"),
                AnalysisOption(icon: "figure.run", title: "Cadence de course", description: "Foulée, efficacité biomécanique"),
                AnalysisOption(icon: "mountain.2.fill", title: "Gestion du dénivelé", description: "Performance montée/descente")
            ]
        case .natation:
            return [
                AnalysisOption(icon: "figure.pool.swim", title: "Technique de nage", description: "Efficacité, points à améliorer"),
                AnalysisOption(icon: "timer", title: "Allures au 100m", description: "Temps de passage, régularité"),
                AnalysisOption(icon: "waveform.path.ecg", title: "Index SWOLF", description: "Efficacité de nage"),
                AnalysisOption(icon: "arrow.up.right", title: "Progression", description: "Comparaison avec séances précédentes")
            ]
        case .autre:
            return [
                AnalysisOption(icon: "chart.line.uptrend.xyaxis", title: "Performance globale", description: "Analyse complète de la séance"),
                AnalysisOption(icon: "heart.fill", title: "Effort cardiaque", description: "Zones, récupération"),
                AnalysisOption(icon: "flame.fill", title: "Dépense énergétique", description: "Calories, intensité"),
                AnalysisOption(icon: "lightbulb.fill", title: "Conseils personnalisés", description: "Recommandations d'amélioration")
            ]
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    // En-tête avec infos séance
                    sessionHeader

                    // Options d'analyse prédéfinies
                    analysisOptionsSection

                    // Question personnalisée
                    customQuestionSection
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Analyser la séance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.textSecondary)
                }
            }
        }
    }

    // MARK: - Session Header

    private var sessionHeader: some View {
        HStack(spacing: ECSpacing.md) {
            // Icône discipline
            ZStack {
                Circle()
                    .fill(themeManager.sportColor(for: context.discipline).opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: context.discipline.icon)
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.sportColor(for: context.discipline))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(context.sessionName)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                    .lineLimit(1)

                Text("\(context.discipline.displayName) • \(context.formattedDate)")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)

                if !context.sessionDescription.isEmpty {
                    Text(context.sessionDescription)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }

            Spacer()
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
    }

    // MARK: - Analysis Options Section

    private var analysisOptionsSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Que souhaitez-vous analyser ?")
                .font(.ecLabel)
                .foregroundColor(themeManager.textPrimary)

            VStack(spacing: ECSpacing.sm) {
                ForEach(analysisOptions) { option in
                    AnalysisOptionCard(
                        option: option,
                        isSelected: selectedOption?.id == option.id,
                        sportColor: themeManager.sportColor(for: context.discipline)
                    ) {
                        selectedOption = option
                        sendAnalysisRequest(option.title)
                    }
                }
            }
        }
    }

    // MARK: - Custom Question Section

    private var customQuestionSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Ou posez votre propre question")
                .font(.ecLabel)
                .foregroundColor(themeManager.textPrimary)

            HStack(spacing: ECSpacing.sm) {
                TextField("Ex: Comment améliorer mon endurance ?", text: $customQuestion, axis: .vertical)
                    .font(.ecBody)
                    .padding()
                    .background(themeManager.cardColor)
                    .cornerRadius(ECRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: ECRadius.lg)
                            .stroke(themeManager.borderColor, lineWidth: 1)
                    )
                    .lineLimit(1...3)
                    .focused($isCustomQuestionFocused)

                Button {
                    sendCustomQuestion()
                } label: {
                    ZStack {
                        Circle()
                            .fill(customQuestion.isEmpty ? themeManager.textTertiary : themeManager.accentColor)
                            .frame(width: 44, height: 44)

                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(customQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: - Actions

    private func sendAnalysisRequest(_ analysisType: String) {
        let message = generateMessage(analysisType: analysisType)
        navigateToChat(with: message)
    }

    private func sendCustomQuestion() {
        let question = customQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }

        let message = generateMessage(analysisType: question)
        navigateToChat(with: message)
    }

    private func generateMessage(analysisType: String) -> String {
        var message = "Pour ma séance de \(context.discipline.displayName) \"\(context.sessionName)\" du \(context.formattedDate)"

        if !context.sessionDescription.isEmpty {
            message += " \(context.sessionDescription)"
        }

        message += ", peux-tu m'aider avec : \(analysisType)"

        return message
    }

    private func navigateToChat(with message: String) {
        // Définir le message pré-rempli
        appState.prefilledChatMessage = message

        // Fermer la sheet
        dismiss()

        // Appeler le callback pour fermer SessionDetailView et changer d'onglet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onNavigateToChat?()
            appState.selectedTab = .coach
        }
    }
}

// MARK: - Analysis Option Card

struct AnalysisOptionCard: View {
    @EnvironmentObject var themeManager: ThemeManager

    let option: AnalysisOption
    let isSelected: Bool
    let sportColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ECSpacing.md) {
                // Icône
                ZStack {
                    Circle()
                        .fill(sportColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: option.icon)
                        .font(.system(size: 18))
                        .foregroundColor(sportColor)
                }

                // Texte
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .font(.ecLabel)
                        .foregroundColor(themeManager.textPrimary)

                    Text(option.description)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }

                Spacer()

                // Flèche
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.textTertiary)
            }
            .padding()
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(isSelected ? sportColor : themeManager.borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SessionAnalysisSheet(
        context: SessionContext(
            sessionName: "Sortie endurance",
            sessionDate: Date(),
            discipline: .cyclisme,
            duration: 7200,
            distance: 65000,
            isCompleted: true
        )
    )
    .environmentObject(AppState())
    .environmentObject(ThemeManager.shared)
}
