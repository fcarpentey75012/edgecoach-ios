/**
 * ObjectivesListView - Liste des objectifs d'entraînement
 * Permet de gérer plusieurs objectifs avec drag & drop pour réorganiser
 */

import SwiftUI

struct ObjectivesListView: View {
    @EnvironmentObject var themeManager: ThemeManager

    @Binding var objectives: [TrainingObjective]
    let defaultSport: ObjectiveSport

    @State private var editingState: EditingState?

    enum EditingState: Identifiable {
        case new(TrainingObjective)
        case existing(TrainingObjective)

        var id: String {
            switch self {
            case .new(let obj): return "new-\(obj.id)"
            case .existing(let obj): return "existing-\(obj.id)"
            }
        }

        var objective: TrainingObjective {
            switch self {
            case .new(let obj), .existing(let obj): return obj
            }
        }

        var isNew: Bool {
            switch self {
            case .new: return true
            case .existing: return false
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            // Header
            headerView

            // Liste des objectifs ou état vide
            if objectives.isEmpty {
                emptyState
            } else {
                objectivesList
            }

            // Bouton ajouter
            addButton
        }
        .sheet(item: $editingState) { state in
            ObjectiveEditorSheet(
                objective: state.objective,
                isNew: state.isNew,
                defaultSport: defaultSport,
                objectives: $objectives,
                onDismiss: { editingState = nil }
            )
            .environmentObject(themeManager)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: ECSpacing.xs) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(themeManager.accentColor)
                Text("Mes objectifs")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)

                Spacer()

                if !objectives.isEmpty {
                    Text("\(objectives.count) objectif\(objectives.count > 1 ? "s" : "")")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }

            Text("Définissez vos courses et objectifs de la saison. L'objectif A est votre cible principale.")
                .font(.ecCaption)
                .foregroundColor(themeManager.textSecondary)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: ECSpacing.md) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 40))
                .foregroundColor(themeManager.textTertiary)

            Text("Aucun objectif défini")
                .font(.ecBody)
                .foregroundColor(themeManager.textSecondary)

            Text("Ajoutez votre premier objectif pour que votre plan soit adapté à vos courses.")
                .font(.ecCaption)
                .foregroundColor(themeManager.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ECSpacing.xl)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
    }

    // MARK: - Objectives List

    private var objectivesList: some View {
        VStack(spacing: ECSpacing.sm) {
            ForEach(objectives.sorted(by: { $0.targetDate < $1.targetDate })) { objective in
                objectiveCard(objective)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteObjective(objective)
                        } label: {
                            Label("Supprimer", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            editingState = .existing(objective)
                        } label: {
                            Label("Modifier", systemImage: "pencil")
                        }
                        .tint(themeManager.accentColor)
                    }
            }
        }
    }

    private func deleteObjective(_ objective: TrainingObjective) {
        if let index = objectives.firstIndex(where: { $0.id == objective.id }) {
            objectives.remove(at: index)
        }
    }

    private func objectiveCard(_ objective: TrainingObjective) -> some View {
        HStack(spacing: ECSpacing.md) {
            // Indicateur priorité
            VStack(spacing: 4) {
                Image(systemName: objective.priority.icon)
                    .font(.system(size: 16))
                    .foregroundColor(objective.priority.color)

                Text(objective.priority.label.components(separatedBy: " ").last ?? "")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(objective.priority.color)
                    .lineLimit(1)
            }
            .frame(width: 40)

            // Infos principales
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: ECSpacing.xs) {
                    Text(objective.name.isEmpty ? "Sans nom" : objective.name)
                        .font(.ecBody)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textPrimary)
                        .lineLimit(1)

                    if objective.isRace {
                        Image(systemName: objective.sport.icon)
                            .font(.system(size: 12))
                            .foregroundColor(objective.sport.color)
                    }
                }

                HStack(spacing: ECSpacing.sm) {
                    // Date
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(objective.targetDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.ecCaption)
                    }
                    .foregroundColor(themeManager.textSecondary)

                    // Distance/Format
                    if objective.isRace {
                        Text("•")
                            .foregroundColor(themeManager.textTertiary)

                        Text(objective.displayDistance)
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    // Temps cible
                    if let time = objective.targetTime, !time.isEmpty {
                        Text("•")
                            .foregroundColor(themeManager.textTertiary)

                        HStack(spacing: 2) {
                            Image(systemName: "timer")
                                .font(.system(size: 10))
                            Text(time)
                                .font(.ecCaption)
                        }
                        .foregroundColor(themeManager.accentColor)
                    }
                }
            }

            Spacer()

            // Semaines restantes
            VStack(alignment: .trailing, spacing: 2) {
                if objective.weeksRemaining > 0 {
                    Text("J-\(objective.daysRemaining)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(objective.daysRemaining < 30 ? themeManager.warningColor : themeManager.textSecondary)

                    Text("\(objective.weeksRemaining) sem.")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                } else {
                    Text("Passé")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(
                    objective.isPrimary ? objective.priority.color.opacity(0.3) : themeManager.borderColor,
                    lineWidth: objective.isPrimary ? 2 : 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            editingState = .existing(objective)
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            // Créer un nouvel objectif avec le sport par défaut
            var newObjective = TrainingObjective()
            newObjective.sport = defaultSport

            // Assigner la priorité automatiquement
            if objectives.isEmpty {
                newObjective.priority = .A
            } else if !objectives.contains(where: { $0.priority == .A }) {
                newObjective.priority = .A
            } else if !objectives.contains(where: { $0.priority == .B }) {
                newObjective.priority = .B
            } else {
                newObjective.priority = .C
            }

            editingState = .new(newObjective)
        } label: {
            HStack(spacing: ECSpacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Ajouter un objectif")
                    .font(.ecBody)
            }
            .foregroundColor(themeManager.accentColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.accentColor, style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
        .buttonStyle(.premium)
    }
}

// MARK: - Objective Summary Card (pour le récapitulatif)

struct ObjectiveSummaryCard: View {
    @EnvironmentObject var themeManager: ThemeManager

    let objective: TrainingObjective

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Badge priorité
            ZStack {
                Circle()
                    .fill(objective.priority.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Text(objective.priority == .A ? "A" : objective.priority == .B ? "B" : objective.priority == .C ? "C" : "D")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(objective.priority.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(objective.name)
                    .font(.ecBody)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textPrimary)

                HStack(spacing: ECSpacing.sm) {
                    if objective.isRace {
                        HStack(spacing: 4) {
                            Image(systemName: objective.sport.icon)
                                .font(.system(size: 10))
                            Text(objective.displayDistance)
                                .font(.ecCaption)
                        }
                        .foregroundColor(objective.sport.color)
                    }

                    Text(objective.targetDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)

                    if let time = objective.targetTime, !time.isEmpty {
                        Text("→ \(time)")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.md)
    }
}

// MARK: - Objective Editor Sheet Wrapper

/// Wrapper pour gérer l'édition d'un objectif dans un sheet
struct ObjectiveEditorSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    let objective: TrainingObjective
    let isNew: Bool
    let defaultSport: ObjectiveSport
    @Binding var objectives: [TrainingObjective]
    let onDismiss: () -> Void

    @State private var editedObjective: TrainingObjective

    init(objective: TrainingObjective, isNew: Bool, defaultSport: ObjectiveSport, objectives: Binding<[TrainingObjective]>, onDismiss: @escaping () -> Void) {
        self.objective = objective
        self.isNew = isNew
        self.defaultSport = defaultSport
        self._objectives = objectives
        self.onDismiss = onDismiss
        self._editedObjective = State(initialValue: objective)
    }

    var body: some View {
        ObjectiveEditorView(
            objective: $editedObjective,
            isNew: isNew,
            defaultSport: defaultSport,
            onSave: {
                if isNew {
                    objectives.append(editedObjective)
                } else if let index = objectives.firstIndex(where: { $0.id == objective.id }) {
                    objectives[index] = editedObjective
                }
                onDismiss()
            },
            onDelete: isNew ? nil : {
                if let index = objectives.firstIndex(where: { $0.id == objective.id }) {
                    objectives.remove(at: index)
                }
                onDismiss()
            }
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack {
            ObjectivesListView(
                objectives: .constant(TrainingObjective.previewList),
                defaultSport: .running
            )
            .padding()
        }
    }
    .background(Color.gray.opacity(0.1))
    .environmentObject(ThemeManager.shared)
}
