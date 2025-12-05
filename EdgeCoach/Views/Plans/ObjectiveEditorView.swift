/**
 * ObjectiveEditorView - Éditeur d'objectif d'entraînement
 * Permet de créer ou modifier un TrainingObjective
 */

import SwiftUI

struct ObjectiveEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    @Binding var objective: TrainingObjective
    let isNew: Bool
    let defaultSport: ObjectiveSport
    let onSave: () -> Void
    let onDelete: (() -> Void)?

    @State private var showDeleteConfirmation = false

    init(
        objective: Binding<TrainingObjective>,
        isNew: Bool = false,
        defaultSport: ObjectiveSport = .running,
        onSave: @escaping () -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self._objective = objective
        self.isNew = isNew
        self.defaultSport = defaultSport
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    // Informations de base
                    basicInfoSection

                    // Type et priorité
                    typeAndPrioritySection

                    // Sport et format
                    sportAndFormatSection

                    // Distance personnalisée (si format custom)
                    if objective.raceFormat == .custom {
                        customDistanceSection
                    }

                    // Détails optionnels
                    optionalDetailsSection
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle(isNew ? "Nouvel objectif" : "Modifier l'objectif")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                    .disabled(objective.name.isEmpty)
                }
            }
            .confirmationDialog(
                "Supprimer cet objectif ?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Supprimer", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("Annuler", role: .cancel) {}
            }
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader("Informations", icon: "info.circle")

            // Nom
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Nom de l'objectif")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)

                TextField("Ex: Marathon de Paris", text: $objective.name)
                    .textFieldStyle(ECTextFieldStyle())
            }

            // Date cible
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Date cible")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)

                DatePicker("", selection: $objective.targetDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding()
                    .background(themeManager.cardColor)
                    .cornerRadius(ECRadius.md)

                // Indicateur semaines restantes
                if objective.weeksRemaining > 0 {
                    Text("\(objective.weeksRemaining) semaines jusqu'à l'objectif")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
    }

    // MARK: - Type and Priority Section

    private var typeAndPrioritySection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader("Type & Priorité", icon: "star")

            // Type d'objectif
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Type d'objectif")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)

                HStack(spacing: ECSpacing.sm) {
                    ForEach(TrainingObjectiveType.allCases) { type in
                        typeButton(type)
                    }
                }
            }

            // Priorité
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Importance")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)

                VStack(spacing: ECSpacing.sm) {
                    ForEach([TrainingObjectivePriority.A, .B, .C, .D], id: \.self) { priority in
                        priorityRow(priority)
                    }
                }
            }
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
    }

    private func typeButton(_ type: TrainingObjectiveType) -> some View {
        let isSelected = objective.objectiveType == type

        return Button {
            objective.objectiveType = type
        } label: {
            VStack(spacing: ECSpacing.xs) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                Text(type.label)
                    .font(.ecCaption)
            }
            .foregroundColor(isSelected ? themeManager.accentColor : themeManager.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ECSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ECRadius.md)
                    .fill(isSelected ? themeManager.accentColor.opacity(0.1) : themeManager.backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.md)
                    .stroke(isSelected ? themeManager.accentColor : themeManager.borderColor, lineWidth: 1)
            )
        }
    }

    private func priorityRow(_ priority: TrainingObjectivePriority) -> some View {
        let isSelected = objective.priority == priority

        return Button {
            objective.priority = priority
        } label: {
            HStack(spacing: ECSpacing.md) {
                Image(systemName: priority.icon)
                    .font(.system(size: 18))
                    .foregroundColor(priority.color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(priority.label)
                        .font(.ecBody)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(themeManager.textPrimary)

                    Text(priority.description)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: ECRadius.md)
                    .fill(isSelected ? themeManager.accentColor.opacity(0.05) : themeManager.backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.md)
                    .stroke(isSelected ? themeManager.accentColor : themeManager.borderColor, lineWidth: 1)
            )
        }
    }

    // MARK: - Sport and Format Section

    private var sportAndFormatSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader("Sport & Format", icon: "figure.run")

            // Sport (si objectif de type course)
            if objective.objectiveType == .race {
                VStack(alignment: .leading, spacing: ECSpacing.xs) {
                    Text("Sport")
                        .font(.ecLabel)
                        .foregroundColor(themeManager.textSecondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: ECSpacing.sm) {
                        ForEach(ObjectiveSport.allCases) { sport in
                            sportButton(sport)
                        }
                    }
                }

                // Format de course
                VStack(alignment: .leading, spacing: ECSpacing.xs) {
                    Text("Format")
                        .font(.ecLabel)
                        .foregroundColor(themeManager.textSecondary)

                    let formats = TrainingRaceFormat.formats(for: objective.sport)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ECSpacing.sm) {
                        ForEach(formats, id: \.self) { format in
                            formatButton(format)
                        }
                    }
                }
            }
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
    }

    private func sportButton(_ sport: ObjectiveSport) -> some View {
        let isSelected = objective.sport == sport

        return Button {
            objective.sport = sport
            // Reset format si incompatible
            if let format = objective.raceFormat,
               !format.compatibleSports.contains(sport) {
                objective.raceFormat = nil
            }
        } label: {
            VStack(spacing: ECSpacing.xs) {
                Image(systemName: sport.icon)
                    .font(.system(size: 20))
                Text(sport.label)
                    .font(.ecCaption)
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? sport.color : themeManager.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ECSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ECRadius.md)
                    .fill(isSelected ? sport.color.opacity(0.1) : themeManager.backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.md)
                    .stroke(isSelected ? sport.color : themeManager.borderColor, lineWidth: 1)
            )
        }
    }

    private func formatButton(_ format: TrainingRaceFormat) -> some View {
        let isSelected = objective.raceFormat == format

        return Button {
            objective.raceFormat = format
        } label: {
            Text(format.label)
                .font(.ecSmall)
                .foregroundColor(isSelected ? themeManager.accentColor : themeManager.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ECSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: ECRadius.md)
                        .fill(isSelected ? themeManager.accentColor.opacity(0.1) : themeManager.backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ECRadius.md)
                        .stroke(isSelected ? themeManager.accentColor : themeManager.borderColor, lineWidth: 1)
                )
        }
    }

    // MARK: - Custom Distance Section

    private var customDistanceSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader("Distance personnalisée", icon: "ruler")

            HStack(spacing: ECSpacing.md) {
                // Valeur
                VStack(alignment: .leading, spacing: ECSpacing.xs) {
                    Text("Distance")
                        .font(.ecLabel)
                        .foregroundColor(themeManager.textSecondary)

                    TextField("Ex: 42.195", value: $objective.distanceValue, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(ECTextFieldStyle())
                }

                // Unité
                VStack(alignment: .leading, spacing: ECSpacing.xs) {
                    Text("Unité")
                        .font(.ecLabel)
                        .foregroundColor(themeManager.textSecondary)

                    Picker("", selection: Binding(
                        get: { objective.distanceUnit ?? .km },
                        set: { objective.distanceUnit = $0 }
                    )) {
                        ForEach(DistanceUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(themeManager.cardColor)
                    .cornerRadius(ECRadius.md)
                }
            }
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
    }

    // MARK: - Optional Details Section

    private var optionalDetailsSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader("Détails (optionnel)", icon: "doc.text")

            // Lieu
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Lieu")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)

                TextField("Ex: Paris, France", text: Binding(
                    get: { objective.location ?? "" },
                    set: { objective.location = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(ECTextFieldStyle())
            }

            // Temps cible
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Temps cible")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)

                TextField("Ex: 3h30, 45min", text: Binding(
                    get: { objective.targetTime ?? "" },
                    set: { objective.targetTime = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(ECTextFieldStyle())
            }

            // Description
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Notes")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)

                TextField("Ajoutez des notes...", text: Binding(
                    get: { objective.description ?? "" },
                    set: { objective.description = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .lineLimit(3...5)
                .textFieldStyle(ECTextFieldStyle())
            }

            // Bouton supprimer (si édition)
            if !isNew, onDelete != nil {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Supprimer cet objectif")
                    }
                    .font(.ecBody)
                    .foregroundColor(themeManager.errorColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.errorColor.opacity(0.1))
                    .cornerRadius(ECRadius.md)
                }
                .padding(.top, ECSpacing.md)
            }
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: ECSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(themeManager.accentColor)
            Text(title)
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)
        }
    }
}

// MARK: - EC TextField Style

struct ECTextFieldStyle: TextFieldStyle {
    @EnvironmentObject var themeManager: ThemeManager

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(ThemeManager.shared.backgroundColor)
            .cornerRadius(ECRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.md)
                    .stroke(ThemeManager.shared.borderColor, lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview {
    ObjectiveEditorView(
        objective: .constant(TrainingObjective.preview),
        isNew: true,
        onSave: {}
    )
    .environmentObject(ThemeManager.shared)
}
