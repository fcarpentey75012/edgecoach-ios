/**
 * Écran de création de MacroPlan
 * Wizard 5 étapes : Sport & Niveau → Objectifs → Configuration → Contraintes → Récapitulatif
 */

import SwiftUI

// MARK: - MacroPlan Creator View

struct MacroPlanCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel

    @StateObject private var viewModel = MacroPlanCreatorViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Bar
                ProgressBar(current: viewModel.currentStep, total: viewModel.totalSteps)
                    .padding(.horizontal)
                    .padding(.top, ECSpacing.md)

                // Content - Utilise TabView pour pré-charger les vues
                TabView(selection: $viewModel.currentStep) {
                    // Step 1
                    ScrollView {
                        Step1SportLevel(
                            selectedSport: $viewModel.selectedSport,
                            selectedLevel: $viewModel.selectedLevel
                        )
                        .padding()
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .tag(1)

                    // Step 2
                    ScrollView {
                        Step2Objectives(
                            objectives: $viewModel.objectives,
                            selectedSport: viewModel.selectedSport,
                            errorMessage: viewModel.objectiveError,
                            onAdd: viewModel.addObjective,
                            onDelete: viewModel.removeObjective
                        )
                        .padding()
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .tag(2)

                    // Step 3
                    ScrollView {
                        Step3Configuration(
                            startDate: $viewModel.startDate,
                            weeklyHours: $viewModel.weeklyHours,
                            weeklyMinutes: $viewModel.weeklyMinutes,
                            maxSessionsPerWeek: $viewModel.maxSessionsPerWeek,
                            maxSessionsPerDay: $viewModel.maxSessionsPerDay,
                            minRestDays: $viewModel.minRestDays
                        )
                        .padding()
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .tag(3)

                    // Step 4
                    ScrollView {
                        Step4Constraints(
                            unavailableDays: $viewModel.unavailableDays,
                            preferredLongDays: $viewModel.preferredLongDays,
                            preferredEasyDays: $viewModel.preferredEasyDays,
                            avoidBackToBack: $viewModel.avoidBackToBack
                        )
                        .padding()
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .tag(4)

                    // Step 5
                    ScrollView {
                        Step5Summary(
                            sport: viewModel.selectedSport,
                            level: viewModel.selectedLevel,
                            objectives: viewModel.objectives,
                            startDate: viewModel.startDate,
                            weeklyHours: viewModel.weeklyHours,
                            weeklyMinutes: viewModel.weeklyMinutes,
                            maxSessionsPerWeek: viewModel.maxSessionsPerWeek,
                            unavailableDays: viewModel.unavailableDays
                        )
                        .padding()
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)

                // Navigation Buttons
                HStack(spacing: ECSpacing.md) {
                    if viewModel.currentStep > 1 {
                        Button {
                            viewModel.previousStep()
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Précédent")
                            }
                            .font(.ecBodyMedium)
                            .foregroundColor(themeManager.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ECSpacing.md)
                            .background(themeManager.cardColor)
                            .cornerRadius(ECRadius.lg)
                            .overlay(
                                RoundedRectangle(cornerRadius: ECRadius.lg)
                                    .stroke(themeManager.borderColor, lineWidth: 1)
                            )
                        }
                    }

                    Button {
                        if viewModel.currentStep < viewModel.totalSteps {
                            viewModel.nextStep()
                        } else {
                            viewModel.generatePlan(userId: authViewModel.user?.id) {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            if viewModel.isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text(viewModel.currentStep < viewModel.totalSteps ? "Suivant" : "Générer le plan")
                                if viewModel.currentStep < viewModel.totalSteps {
                                    Image(systemName: "chevron.right")
                                } else {
                                    Image(systemName: "sparkles")
                                }
                            }
                        }
                        .font(.ecBodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ECSpacing.md)
                        .background(viewModel.canProceed ? themeManager.accentColor : themeManager.textTertiary)
                        .cornerRadius(ECRadius.lg)
                    }
                    .disabled(!viewModel.canProceed || viewModel.isGenerating)
                }
                .padding()
                .background(themeManager.backgroundColor)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Créer un plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
            .alert("Erreur", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Une erreur est survenue")
            }
        }
    }
}

// MARK: - Progress Bar

private struct ProgressBar: View {
    @EnvironmentObject var themeManager: ThemeManager
    let current: Int
    let total: Int

    var body: some View {
        VStack(spacing: ECSpacing.xs) {
            HStack(spacing: ECSpacing.xs) {
                ForEach(1...total, id: \.self) { step in
                    Rectangle()
                        .fill(step <= current ? themeManager.accentColor : themeManager.borderColor)
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }

            HStack {
                Text(stepTitle)
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
                Spacer()
                Text("\(current)/\(total)")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textTertiary)
            }
        }
    }

    private var stepTitle: String {
        switch current {
        case 1: return "Sport & Niveau"
        case 2: return "Objectifs"
        case 3: return "Configuration"
        case 4: return "Contraintes"
        case 5: return "Récapitulatif"
        default: return ""
        }
    }
}

// MARK: - Step 1: Sport & Level

private struct Step1SportLevel: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedSport: MacroPlanSport
    @Binding var selectedLevel: AthleteLevel

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.xl) {
            // Sport Selection
            VStack(alignment: .leading, spacing: ECSpacing.md) {
                Text("Quel sport pratiquez-vous ?")
                    .font(.ecH3)
                    .foregroundColor(themeManager.textPrimary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ECSpacing.md) {
                    ForEach(MacroPlanSport.allCases) { sport in
                        MacroSportCard(
                            sport: sport,
                            isSelected: selectedSport == sport,
                            action: { selectedSport = sport }
                        )
                    }
                }
            }

            // Level Selection
            VStack(alignment: .leading, spacing: ECSpacing.md) {
                Text("Quel est votre niveau ?")
                    .font(.ecH3)
                    .foregroundColor(themeManager.textPrimary)

                VStack(spacing: ECSpacing.sm) {
                    ForEach(AthleteLevel.allCases) { level in
                        LevelCard(
                            level: level,
                            isSelected: selectedLevel == level,
                            action: { selectedLevel = level }
                        )
                    }
                }
            }
        }
    }
}

private struct MacroSportCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let sport: MacroPlanSport
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: ECSpacing.sm) {
                Image(systemName: sport.icon)
                .font(.system(size: 32))                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.textSecondary)

                Text(sport.displayName)
                    .font(.ecBodyMedium)
                    .foregroundColor(isSelected ? themeManager.textPrimary : themeManager.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ECSpacing.lg)
            .background(isSelected ? themeManager.accentColor.opacity(0.1) : themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(isSelected ? themeManager.accentColor : themeManager.borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

private struct LevelCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let level: AthleteLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(.ecBodyMedium)
                        .foregroundColor(themeManager.textPrimary)

                    Text(level.description)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.accentColor)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? themeManager.accentColor.opacity(0.1) : themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(isSelected ? themeManager.accentColor : themeManager.borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - Step 2: Objectives

private struct Step2Objectives: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var objectives: [RaceObjective]
    let selectedSport: MacroPlanSport
    let errorMessage: String?
    let onAdd: (RaceObjective) -> Void
    let onDelete: (String) -> Void

    @State private var showingAddObjective = false

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.lg) {
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Vos objectifs de saison")
                    .font(.ecH3)
                    .foregroundColor(themeManager.textPrimary)

                Text("Ajoutez vos courses et objectifs principaux")
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
            }
            
            // Inline Error Message
            if let error = errorMessage {
                HStack(spacing: ECSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .font(.ecCaption)
                .foregroundColor(themeManager.errorColor)
                .padding(.vertical, ECSpacing.xs)
                .transition(.opacity)
            }

            // Objectives List
            if objectives.isEmpty {
                EmptyObjectivesCard(action: { showingAddObjective = true })
            } else {
                VStack(spacing: ECSpacing.sm) {
                    ForEach(objectives) { objective in
                        ObjectiveRow(
                            objective: objective,
                            onEdit: { /* TODO */ },
                            onDelete: { onDelete(objective.id) }
                        )
                    }
                }

                Button {
                    showingAddObjective = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Ajouter un objectif")
                    }
                    .font(.ecBodyMedium)
                    .foregroundColor(themeManager.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ECSpacing.md)
                    .background(themeManager.accentColor.opacity(0.1))
                    .cornerRadius(ECRadius.lg)
                }
            }

            // Info Box
            InfoBox(
                icon: "lightbulb",
                text: "Définissez un objectif A (principal), puis des objectifs B et C pour structurer votre préparation."
            )
        }
        .sheet(isPresented: $showingAddObjective) {
            MacroObjectiveEditorSheet(
                sport: selectedSport,
                onSave: { objective in
                    onAdd(objective)
                }
            )
        }
    }
}

private struct EmptyObjectivesCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: ECSpacing.md) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 40))
                    .foregroundColor(themeManager.textTertiary)

                Text("Aucun objectif défini")
                    .font(.ecBodyMedium)
                    .foregroundColor(themeManager.textSecondary)

                Text("Appuyez pour ajouter votre première course")
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ECSpacing.xl)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
        }
    }
}

private struct ObjectiveRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let objective: RaceObjective
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Priority Badge
            Text(objective.priority.shortName)
                .font(.ecCaptionBold)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(priorityColor)
                .cornerRadius(ECRadius.sm)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(objective.name)
                    .font(.ecBodyMedium)
                    .foregroundColor(themeManager.textPrimary)

                HStack(spacing: ECSpacing.sm) {
                    if !objective.targetDate.isEmpty {
                        Text(formattedDate)
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    if let format = objective.raceFormat {
                        Text("• \(format.displayName)")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textTertiary)
                    }
                }
            }

            Spacer()

            // Actions
            Menu {
                Button("Modifier", action: onEdit)
                Button("Supprimer", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(themeManager.textSecondary)
                    .padding(ECSpacing.sm)
            }
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }

    private var priorityColor: Color {
        switch objective.priority {
        case .principal: return themeManager.warningColor
        case .secondary: return themeManager.infoColor
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: objective.targetDate) else {
            return objective.targetDate
        }
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

// MARK: - Macro Objective Editor Sheet (Rich UI)

private struct MacroObjectiveEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    let sport: MacroPlanSport
    let onSave: (RaceObjective) -> Void

    // State
    @State private var name = ""
    @State private var targetDate = Date()
    @State private var priority: ObjectivePriority = .principal
    @State private var objectiveType: ObjectiveType = .race
    @State private var raceFormat: RaceFormat = .olympic
    @State private var location = ""
    @State private var targetTime = ""
    
    // Custom distance
    @State private var customDistanceValue: Double?
    @State private var customDistanceUnit: String = "km"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    // 1. Basic Info Section (Card)
                    basicInfoSection

                    // 2. Type & Priority Section (Card)
                    typeAndPrioritySection

                    // 3. Sport & Format Section (Card)
                    // Only show if it's a race
                    if objectiveType == .race {
                        sportAndFormatSection
                    }
                    
                    // 4. Details Section (Card)
                    detailsSection
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Nouvel objectif")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") { dismiss() }
                        .foregroundColor(themeManager.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ajouter") {
                        saveObjective()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader("Informations", icon: "info.circle")

            // Name Field
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Nom de l'objectif")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)
                
                TextField("Ex: Marathon de Paris", text: $name)
                    .padding()
                    .background(themeManager.backgroundColor)
                    .cornerRadius(ECRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: ECRadius.md)
                            .stroke(themeManager.borderColor, lineWidth: 1)
                    )
            }

            // Date Picker
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Date cible")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)
                
                DatePicker("", selection: $targetDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding()
                    .background(themeManager.backgroundColor)
                    .cornerRadius(ECRadius.md)
            }
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
    }

    private var typeAndPrioritySection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader("Type & Priorité", icon: "star")

            // Objective Type
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Type d'objectif")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)
                
                HStack(spacing: ECSpacing.sm) {
                    ForEach(ObjectiveType.allCases) { type in
                        SelectionCard(
                            title: type.displayName,
                            icon: type.iconName,
                            isSelected: objectiveType == type,
                            action: { objectiveType = type }
                        )
                    }
                }
            }
            
            // Priority
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Importance")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)
                
                VStack(spacing: ECSpacing.sm) {
                    ForEach(ObjectivePriority.allCases) { p in
                        PrioritySelectionRow(
                            priority: p,
                            isSelected: priority == p,
                            action: { priority = p }
                        )
                    }
                }
            }
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
    }

    private var sportAndFormatSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader("Format de course", icon: "figure.run")

            // Sport is fixed to the plan sport for now, or adaptable? 
            // The MacroPlanRequest structure allows per-objective sport.
            // But usually for a plan, we focus on the plan's sport.
            // For Triathlon plan, it's always triathlon races mostly, but could be single sport.
            // Let's stick to the plan's sport or allow variation if it's Triathlon.
            
            if sport == .triathlon {
                 VStack(alignment: .leading, spacing: ECSpacing.xs) {
                    Text("Discipline")
                        .font(.ecLabel)
                        .foregroundColor(themeManager.textSecondary)
                     
                     // We can't easily change the 'sport' let, but we can have a local state if needed.
                     // The requirement is to match user friendliness.
                     // Let's assume for now we keep the passed sport regarding the UI logic 
                     // unless user specifically wants to add a "Run" race in a Triathlon plan.
                     // The previous AddObjectiveSheet allowed filtering formats based on sport.
                 }
            }

            // Sub-formats
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Format")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)
                
                let formats = RaceFormat.allCases.filter { format in
                    // Filter formats relevant to the sport
                    if sport == .triathlon {
                        return [.sprint, .olympic, .halfIronman, .ironman].contains(format)
                    } else if sport == .courseAPied {
                        return [.tenK, .other].contains(format) // Add more if needed
                    }
                    return true
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ECSpacing.sm) {
                    ForEach(formats) { format in
                        SelectionCard(
                            title: format.displayName,
                            subtitle: format.distances,
                            isSelected: raceFormat == format,
                            action: { raceFormat = format }
                        )
                    }
                }
            }
            
            // Custom Distance (if needed, simplified for now)
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader("Détails (Optionnel)", icon: "doc.text")

            // Location
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Lieu")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)
                
                TextField("Ex: Nice, France", text: $location)
                    .padding()
                    .background(themeManager.backgroundColor)
                    .cornerRadius(ECRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: ECRadius.md)
                            .stroke(themeManager.borderColor, lineWidth: 1)
                    )
            }
            
            // Time
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Temps visé")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)
                
                TextField("Ex: 1h45", text: $targetTime)
                    .padding()
                    .background(themeManager.backgroundColor)
                    .cornerRadius(ECRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: ECRadius.md)
                            .stroke(themeManager.borderColor, lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
    }

    // MARK: - Helpers & Components

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: ECSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(themeManager.accentColor)
            Text(title)
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)
        }
    }
    
    private func saveObjective() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var distanceValue: Double? = nil
        var distanceUnit: String? = nil

        if objectiveType == .race {
            // Use standard distance for format
            distanceValue = raceFormat.totalDistanceKm
            distanceUnit = "km"
        }

        let newObj = RaceObjective(
            name: name,
            targetDate: formatter.string(from: targetDate),
            priority: priority,
            objectiveType: objectiveType,
            sport: sport,
            raceFormat: objectiveType == .race ? raceFormat : nil,
            distanceValue: distanceValue,
            distanceUnit: distanceUnit,
            targetTime: targetTime.isEmpty ? nil : targetTime,
            location: location.isEmpty ? nil : location
        )
        onSave(newObj)
        dismiss()
    }
}

// MARK: - UI Components for Sheet

private struct SelectionCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: ECSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .padding(.bottom, 2)
                }
                
                Text(title)
                    .font(.ecCaption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .multilineTextAlignment(.center)
                
                if let sub = subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 9))
                        .foregroundColor(isSelected ? themeManager.accentColor.opacity(0.8) : themeManager.textTertiary)
                }
            }
            .foregroundColor(isSelected ? themeManager.accentColor : themeManager.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ECSpacing.md)
            .padding(.horizontal, ECSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: ECRadius.md)
                    .fill(isSelected ? themeManager.accentColor.opacity(0.1) : themeManager.backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.md)
                    .stroke(isSelected ? themeManager.accentColor : themeManager.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PrioritySelectionRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let priority: ObjectivePriority
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ECSpacing.md) {
                // Icon/Badge
                ZStack {
                    Circle()
                        .fill(priorityColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Text(priority.shortName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(priorityColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(priority.displayName)
                        .font(.ecBody)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(themeManager.textPrimary)
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
        .buttonStyle(.plain)
    }
    
    var priorityColor: Color {
        switch priority {
        case .principal: return themeManager.warningColor
        case .secondary: return themeManager.infoColor
        }
    }
}

// MARK: - UI Extensions

private extension ObjectiveType {
    var iconName: String {
        switch self {
        case .race: return "flag.checkered"
        case .focus: return "target"
        }
    }
}

// MARK: - Step 3: Configuration

private struct Step3Configuration: View {
    @EnvironmentObject var themeManager: ThemeManager

    @Binding var startDate: Date
    @Binding var weeklyHours: Int
    @Binding var weeklyMinutes: Int
    @Binding var maxSessionsPerWeek: Int
    @Binding var maxSessionsPerDay: Int
    @Binding var minRestDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.xl) {
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Configuration du plan")
                    .font(.ecH3)
                    .foregroundColor(themeManager.textPrimary)

                Text("Définissez votre disponibilité hebdomadaire")
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
            }

            // Start Date
            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                Text("Date de début")
                    .font(.ecCaptionBold)
                    .foregroundColor(themeManager.textSecondary)

                DatePicker(
                    "",
                    selection: $startDate,
                    in: Date()..., // Prevent picking past dates
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .background(themeManager.cardColor)
                .cornerRadius(ECRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: ECRadius.lg)
                        .stroke(themeManager.borderColor, lineWidth: 1)
                )
            }
            
            // Weekly Hours Slider
            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                HStack {
                    Text("Volume hebdo cible")
                        .font(.ecBodyMedium)
                        .foregroundColor(themeManager.textPrimary)
                    Spacer()
                    Text("\(weeklyHours)h \(weeklyMinutes > 0 ? "\(weeklyMinutes)" : "")")
                        .font(.ecH3)
                        .foregroundColor(themeManager.accentColor)
                }
                
                Slider(value: Binding(
                    get: { Double(weeklyHours) },
                    set: { weeklyHours = Int($0) }
                ), in: 3...20, step: 1)
                .tint(themeManager.accentColor)
                
                Text("Heures par semaine")
                    .font(.caption)
                    .foregroundColor(themeManager.textSecondary)
            }
            .padding()
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            
            // Max Sessions Per Day
             VStack(alignment: .leading, spacing: ECSpacing.sm) {
                 Text("Max séances par jour")
                     .font(.ecBodyMedium)
                     .foregroundColor(themeManager.textPrimary)
                 
                 Picker("Max séances", selection: $maxSessionsPerDay) {
                     Text("1 séance").tag(1)
                     Text("2 séances").tag(2)
                     Text("Illimité").tag(3)
                 }
                 .pickerStyle(.segmented)
             }
             
             // Min Rest Days
             Stepper("Jours de repos min: \(minRestDays)", value: $minRestDays, in: 0...3)
                 .font(.ecBodyMedium)
                 .foregroundColor(themeManager.textPrimary)
                 .padding()
                 .background(themeManager.cardColor)
                 .cornerRadius(ECRadius.lg)

        }
    }
}

// MARK: - Step 4: Constraints

private struct Step4Constraints: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    @Binding var unavailableDays: Set<Int>
    @Binding var preferredLongDays: Set<Int>
    @Binding var preferredEasyDays: Set<Int>
    @Binding var avoidBackToBack: Bool
    
    let days = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.xl) {
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Vos disponibilités")
                    .font(.ecH3)
                    .foregroundColor(themeManager.textPrimary)
                
                Text("Quels jours préférez-vous vous entraîner ?")
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
            }
            
            // Unavailable Days
            DaySelector(
                title: "Jours indisponibles",
                subtitle: "Jours où vous ne pouvez PAS vous entraîner",
                days: days,
                selectedIndices: $unavailableDays,
                color: themeManager.errorColor
            )
            
            // Long Days
            DaySelector(
                title: "Sorties longues",
                subtitle: "Jours préférés pour les séances longues",
                days: days,
                selectedIndices: $preferredLongDays,
                color: themeManager.successColor
            )
            
            // Easy Days
            DaySelector(
                title: "Séances légères",
                subtitle: "Jours préférés pour repos ou récup",
                days: days,
                selectedIndices: $preferredEasyDays,
                color: themeManager.infoColor
            )
            
            Toggle("Éviter les jours difficiles consécutifs", isOn: $avoidBackToBack)
                .font(.ecBodyMedium)
                .foregroundColor(themeManager.textPrimary)
                .tint(themeManager.accentColor)
                .padding()
                .background(themeManager.cardColor)
                .cornerRadius(ECRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: ECRadius.lg)
                        .stroke(themeManager.borderColor, lineWidth: 1)
                )
        }
    }
}

private struct DaySelector: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let subtitle: String
    let days: [String]
    @Binding var selectedIndices: Set<Int>
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.ecBodyMedium)
                    .foregroundColor(themeManager.textPrimary)
                
                Text(subtitle)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textSecondary)
            }
            
            HStack(spacing: 0) {
                ForEach(0..<7) { index in
                    DayCircle(
                        text: days[index],
                        isSelected: selectedIndices.contains(index),
                        color: color,
                        action: { toggle(index) }
                    )
                }
            }
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
    
    private func toggle(_ index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }
}

private struct DayCircle: View {
    @EnvironmentObject var themeManager: ThemeManager
    let text: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text.prefix(1))
                .font(.ecCaptionBold)
                .foregroundColor(isSelected ? .white : themeManager.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isSelected ? color : Color.clear)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? color : themeManager.borderColor, lineWidth: 1)
                )
        }
    }
}

// MARK: - Step 5: Summary

private struct Step5Summary: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let sport: MacroPlanSport
    let level: AthleteLevel
    let objectives: [RaceObjective]
    let startDate: Date
    let weeklyHours: Int
    let weeklyMinutes: Int
    let maxSessionsPerWeek: Int
    let unavailableDays: Set<Int>
    
    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.xl) {
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Récapitulatif")
                    .font(.ecH3)
                    .foregroundColor(themeManager.textPrimary)
                
                Text("Vérifiez vos informations avant de générer le plan")
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
            }
            
            // Profile Summary
            SummarySection(title: "Profil") {
                SummaryRow(label: "Sport", value: sport.displayName)
                SummaryRow(label: "Niveau", value: level.displayName)
            }
            
            // Objectives Summary
            SummarySection(title: "Objectifs") {
                if let mainObj = objectives.first(where: { $0.priority == .principal }) {
                    SummaryRow(label: "Principal", value: "\(mainObj.name) (\(mainObj.targetDate))")
                }
                SummaryRow(label: "Total", value: "\(objectives.count) course(s)")
            }
            
            // Config Summary
            SummarySection(title: "Paramètres") {
                SummaryRow(label: "Début", value: formattedDate(startDate))
                SummaryRow(label: "Volume", value: "\(weeklyHours)h / semaine")
                SummaryRow(label: "Fréquence", value: "Max \(maxSessionsPerWeek) séances / semaine")
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

private struct SummarySection<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text(title)
                .font(.ecH4)
                .foregroundColor(themeManager.textPrimary)
            
            VStack(spacing: ECSpacing.sm) {
                content()
            }
            .padding()
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
        }
    }
}

private struct SummaryRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.ecBody)
                .foregroundColor(themeManager.textSecondary)
            Spacer()
            Text(value)
                .font(.ecBodyMedium)
                .foregroundColor(themeManager.textPrimary)
        }
    }
}

// MARK: - Info Box

private struct InfoBox: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: ECSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(themeManager.accentColor)
                .font(.title3)
            
            Text(text)
                .font(.ecSmall)
                .foregroundColor(themeManager.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding()
        .background(themeManager.accentColor.opacity(0.1))
        .cornerRadius(ECRadius.md)
    }
}

// MARK: - ViewModel

@MainActor
class MacroPlanCreatorViewModel: ObservableObject {
    // MARK: - State properties
    
    @Published var currentStep = 1
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var showError = false // Gardé pour l'instant pour les erreurs API globales
    
    // Form Data
    @Published var selectedSport: MacroPlanSport = .triathlon
    @Published var selectedLevel: AthleteLevel = .advanced
    @Published var objectives: [RaceObjective] = [
        RaceObjective(
            name: "10k Paris",
            targetDate: "2026-02-01",
            priority: .secondary,
            objectiveType: .race,
            sport: .courseAPied,
            raceFormat: .tenK,
            distanceValue: 10.0,
            distanceUnit: "km",
            targetTime: "42:00"
        ),
        RaceObjective(
            name: "Ironman 70.3 Carcans",
            targetDate: "2026-05-16",
            priority: .principal,
            objectiveType: .race,
            sport: .triathlon,
            raceFormat: .halfIronman,
            distanceValue: 113.0,
            distanceUnit: "km",
            targetTime: "5:30:00"
        )
    ]
    @Published var startDate: Date = MacroPlanCreatorViewModel.getNextMonday()
    @Published var weeklyHours: Int = 12
    @Published var weeklyMinutes: Int = 0
    @Published var maxSessionsPerWeek: Int = 8
    @Published var maxSessionsPerDay: Int = 2
    @Published var minRestDays: Int = 1
    @Published var unavailableDays: Set<Int> = [0] // Lun
    @Published var preferredLongDays: Set<Int> = [5, 6] // Sam, Dim
    @Published var preferredEasyDays: Set<Int> = [1, 4] // Mar, Ven
    @Published var avoidBackToBack: Bool = false
    
    // MARK: - Validation State
    
    @Published var objectiveError: String? = nil
    
    var totalSteps = 5
    
    // MARK: - Computed Properties
    
    var canProceed: Bool {
        switch currentStep {
        case 2:
            return !objectives.isEmpty && objectives.contains { $0.priority == .principal }
        default:
            return true
        }
    }
    
    // MARK: - Actions
    
    func nextStep() {
        if validateCurrentStep() {
            withAnimation {
                if currentStep < totalSteps {
                    currentStep += 1
                }
            }
        }
    }
    
    func previousStep() {
        withAnimation {
            if currentStep > 1 {
                currentStep -= 1
            }
        }
    }
    
    func validateCurrentStep() -> Bool {
        objectiveError = nil
        
        switch currentStep {
        case 2:
            if objectives.isEmpty {
                objectiveError = "Ajoutez au moins un objectif"
                return false
            }
            if !objectives.contains(where: { $0.priority == .principal }) {
                objectiveError = "Définissez au moins un objectif principal (A)"
                return false
            }
            for obj in objectives {
                if obj.name.trimmingCharacters(in: .whitespaces).isEmpty {
                    objectiveError = "Tous les objectifs doivent avoir un nom"
                    return false
                }
            }
        default:
            break
        }
        return true
    }
    
    // MARK: - API Calls
    
    func generatePlan(userId: String?, onSuccess: @escaping () -> Void) {
        guard let userId = userId else {
            errorMessage = "Utilisateur non connecté"
            showError = true
            return
        }
        
        isGenerating = true
        
        // Formatter et prépa des données
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // Construire la string de contraintes
        var constraintsDescription: String? = nil
        if maxSessionsPerDay > 0 || minRestDays > 0 {
            var parts: [String] = []
            if maxSessionsPerDay == 1 {
                parts.append("pas de biquotidien")
            }
            if minRestDays > 0 {
                parts.append("minimum \(minRestDays) jour(s) de repos")
            }
            constraintsDescription = parts.isEmpty ? nil : parts.joined(separator: ", ")
        }
        
        let planConfig = PlanConfig(
            startDate: formatter.string(from: startDate),
            weeklyTimeAvailable: weeklyHours, // en heures
            constraints: constraintsDescription,
            perSportSessions: selectedSport == .triathlon ? .defaultTriathlon : nil
        )
        
        let softConstraints = SoftConstraints(
            unavailableDays: daysToApiNames(unavailableDays),
            preferredEasyDays: daysToApiNames(preferredEasyDays),
            preferredLongWorkoutDays: daysToApiNames(preferredLongDays),
            maxSessionsPerWeek: maxSessionsPerWeek,
            noDoubles: maxSessionsPerDay == 1
        )
        
        let athleteProfile = AthleteProfile(
            sport: selectedSport,
            level: selectedLevel,
            planConfig: planConfig,
            softConstraints: softConstraints
        )
        
        let request = MacroPlanRequest(
            userId: userId,
            athleteProfile: athleteProfile,
            objectives: objectives,
            options: .default
        )
        
        Task {
            do {
                let _ = try await MacroPlanService.shared.createMacroPlan(request: request)
                await MainActor.run {
                    self.isGenerating = false
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    self.isGenerating = false
                    self.errorMessage = "Erreur lors de la génération : \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }
    
    // MARK: - Data Manipulation
    
    func addObjective(_ objective: RaceObjective) {
        objectives.append(objective)
        objectiveError = nil // Clear error on action
    }
    
    func removeObjective(withId id: String) {
        objectives.removeAll { $0.id == id }
    }
    
    // MARK: - Helpers
    
    /// Convertit un Set d'index de jours en tableau de noms API
    private func daysToApiNames(_ days: Set<Int>) -> [String] {
        days.compactMap { DayOfWeek(rawValue: $0)?.apiName }
    }
    
    static func getNextMonday() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilMonday = weekday == 1 ? 1 : (9 - weekday)
        return calendar.date(byAdding: .day, value: daysUntilMonday, to: today) ?? today
    }
}
