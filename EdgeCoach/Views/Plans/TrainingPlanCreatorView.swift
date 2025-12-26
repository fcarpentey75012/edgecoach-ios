/**
 * Écran de création de plan d'entraînement
 * Wizard 3 étapes : Sport & Niveau → Objectifs & Planning → Récapitulatif
 */

import SwiftUI

// MARK: - Data Models

struct PlanFormData {
    var sport: PlanSport = .triathlon
    var experience: ExperienceLevel = .amateur
    // Nouveau système d'objectifs structurés
    // TODO: Supprimer devExamples après le développement
    var trainingObjectives: [TrainingObjective] = TrainingObjective.devExamples
    // Legacy - gardé pour compatibilité
    var objectives: Set<PlanObjective> = []
    var customObjective: String = ""
    var durationWeeks: Int = 8
    var startDate: Date = getNextMonday()
    var weeklyHours: Int = 6
    var constraints: String = ""
    var unavailableDays: Set<WeekDay> = []

    // Soft constraints (contraintes souples)
    var softConstraints: String = ""

    // Séances par sport (pour triathlon/duathlon)
    var swimmingSessions: Int = 3
    var cyclingSessions: Int = 3
    var runningSessions: Int = 3

    static func getNextMonday() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilMonday = weekday == 1 ? 1 : (9 - weekday)
        return calendar.date(byAdding: .day, value: daysUntilMonday, to: today) ?? today
    }

    /// Calcule automatiquement la durée et date de début basées sur les objectifs
    mutating func calculateDatesFromObjectives() {
        guard let primaryObjective = trainingObjectives.first(where: { $0.priority == .A }) else { return }

        // Date de fin = date de l'objectif principal
        let endDate = primaryObjective.targetDate

        // Date de début = aujourd'hui ou lundi prochain
        let proposedStart = Self.getNextMonday()

        // Calculer la durée en semaines
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: proposedStart, to: endDate).weekOfYear ?? 8

        if weeks > 0 {
            self.durationWeeks = min(max(weeks, 4), 52) // Entre 4 et 52 semaines
            self.startDate = proposedStart
        }
    }
}

enum PlanSport: String, CaseIterable, Identifiable {
    case triathlon, running, cycling, swimming

    var id: String { rawValue }

    var label: String {
        switch self {
        case .triathlon: return "Triathlon"
        case .running: return "Course à pied"
        case .cycling: return "Cyclisme"
        case .swimming: return "Natation"
        }
    }

    var icon: String {
        switch self {
        case .triathlon: return "trophy"
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        }
    }

    var color: Color {
        switch self {
        case .triathlon: return .ecTriathlon
        case .running: return .ecRunning
        case .cycling: return .ecCycling
        case .swimming: return .ecSwimming
        }
    }

    var discipline: Discipline {
        switch self {
        case .triathlon: return .autre  // Triathlon utilise "autre" comme fallback
        case .running: return .course
        case .cycling: return .cyclisme
        case .swimming: return .natation
        }
    }
}

// Using ExperienceLevel from User.swift
extension ExperienceLevel: Identifiable {
    var id: String { rawValue }

    var planLabel: String { displayName }

    var planDescription: String {
        switch self {
        case .discovery: return "Moins de 1 an de pratique"
        case .amateur: return "1 à 3 ans de pratique régulière"
        case .competitor: return "Plus de 3 ans, compétitions régulières"
        case .expert: return "Plus de 5 ans, haut niveau"
        }
    }
}

enum PlanObjective: String, CaseIterable, Identifiable {
    case endurance, speed, strength, technique, competition, weightLoss

    var id: String { rawValue }

    var label: String {
        switch self {
        case .endurance: return "Améliorer l'endurance"
        case .speed: return "Gagner en vitesse"
        case .strength: return "Renforcer la puissance"
        case .technique: return "Améliorer la technique"
        case .competition: return "Préparer une compétition"
        case .weightLoss: return "Perdre du poids"
        }
    }

    var icon: String {
        switch self {
        case .endurance: return "heart"
        case .speed: return "bolt"
        case .strength: return "dumbbell"
        case .technique: return "figure.walk"
        case .competition: return "trophy"
        case .weightLoss: return "scalemass"
        }
    }
}

enum WeekDay: String, CaseIterable, Identifiable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .monday: return "Lun"
        case .tuesday: return "Mar"
        case .wednesday: return "Mer"
        case .thursday: return "Jeu"
        case .friday: return "Ven"
        case .saturday: return "Sam"
        case .sunday: return "Dim"
        }
    }
}

// MARK: - Main View

struct TrainingPlanCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager

    @State private var currentStep = 0
    @State private var formData = PlanFormData()
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                content
                footerButtons
            }
            .navigationTitle("Nouveau plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(themeManager.textSecondary)
                    }
                }
            }
            .alert("Plan créé !", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Votre plan d'entraînement a été généré avec succès. Retrouvez-le dans votre calendrier.")
            }
            .alert("Erreur", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(spacing: ECSpacing.lg) {
                switch currentStep {
                case 0:
                    step1SportAndLevel
                case 1:
                    step2ObjectivesAndPlanning
                case 2:
                    step3Summary
                default:
                    EmptyView()
                }
            }
            .padding()
        }
        .background(themeManager.backgroundColor)
    }

    // MARK: - Step 1: Sport & Level

    private var step1SportAndLevel: some View {
        VStack(alignment: .leading, spacing: ECSpacing.lg) {
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Sport & Niveau")
                    .font(.ecH2)
                    .foregroundColor(themeManager.textPrimary)

                Text("Choisissez votre sport et indiquez votre niveau d'expérience")
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
            }

            // Sport Selection
            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                Text("Sport principal")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textPrimary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ECSpacing.sm) {
                    ForEach(PlanSport.allCases) { sport in
                        sportCard(sport)
                    }
                }
            }

            // Experience Level
            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                Text("Niveau d'expérience")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textPrimary)

                VStack(spacing: ECSpacing.sm) {
                    ForEach(ExperienceLevel.allCases) { level in
                        experienceLevelCard(level)
                    }
                }
            }
        }
    }

    private func sportCard(_ sport: PlanSport) -> some View {
        let isSelected = formData.sport == sport
        let sportColor = themeManager.sportColor(for: sport.discipline)

        return Button {
            formData.sport = sport
        } label: {
            VStack(spacing: ECSpacing.sm) {
                Image(systemName: sport.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? sportColor : themeManager.textTertiary)

                Text(sport.label)
                    .font(.ecLabel)
                    .foregroundColor(isSelected ? sportColor : themeManager.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ECSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .fill(isSelected ? sportColor.opacity(0.1) : themeManager.cardColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(isSelected ? sportColor : themeManager.borderColor, lineWidth: 2)
            )
        }
    }

    private func experienceLevelCard(_ level: ExperienceLevel) -> some View {
        let isSelected = formData.experience == level

        return Button {
            formData.experience = level
        } label: {
            HStack(spacing: ECSpacing.md) {
                Circle()
                    .stroke(isSelected ? themeManager.accentColor : themeManager.textTertiary, lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .fill(isSelected ? themeManager.accentColor : Color.clear)
                            .frame(width: 12, height: 12)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.planLabel)
                        .font(.ecBody)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textPrimary)

                    Text(level.planDescription)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .fill(isSelected ? themeManager.accentColor.opacity(0.05) : themeManager.cardColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(isSelected ? themeManager.accentColor : themeManager.borderColor, lineWidth: 2)
            )
        }
    }

    // MARK: - Step 2: Objectives & Planning

    private var step2ObjectivesAndPlanning: some View {
        VStack(alignment: .leading, spacing: ECSpacing.lg) {
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Objectifs & Planning")
                    .font(.ecH2)
                    .foregroundColor(themeManager.textPrimary)

                Text("Définissez vos courses et objectifs de la saison")
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
            }

            // Nouveau système d'objectifs structurés
            trainingObjectivesSection

            // Séparateur
            if !formData.trainingObjectives.isEmpty {
                planningInfoCard
            }

            // Duration
            durationSection

            // Weekly Hours
            weeklyHoursSection

            // Per Sport Sessions (pour triathlon)
            if formData.sport == .triathlon {
                perSportSessionsSection
            }

            // Start Date
            startDateSection

            // Soft Constraints
            softConstraintsSection
        }
    }

    // MARK: - Training Objectives Section (Nouveau)

    private var trainingObjectivesSection: some View {
        ObjectivesListView(
            objectives: $formData.trainingObjectives,
            defaultSport: ObjectiveSport(from: formData.sport)
        )
        .onChange(of: formData.trainingObjectives) { newValue in
            // Recalculer les dates si un objectif A est défini
            if newValue.contains(where: { $0.priority == .A }) {
                formData.calculateDatesFromObjectives()
            }
        }
    }

    private var planningInfoCard: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            if let primaryObj = formData.trainingObjectives.first(where: { $0.priority == .A }) {
                HStack(spacing: ECSpacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(themeManager.warningColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Planning suggéré")
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)

                        Text("Basé sur votre objectif \"\(primaryObj.name)\" le \(primaryObj.targetDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }
                .padding()
                .background(themeManager.warningColor.opacity(0.1))
                .cornerRadius(ECRadius.md)
            }
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            HStack {
                Text("Durée du programme")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textPrimary)

                Spacer()

                if formData.trainingObjectives.isEmpty {
                    Text("Ajoutez un objectif")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }

            // Affichage en lecture seule
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(formData.durationWeeks) semaines")
                        .font(.ecH4)
                        .foregroundColor(themeManager.textPrimary)

                    if let lastObjective = formData.trainingObjectives.max(by: { $0.targetDate < $1.targetDate }) {
                        Text("Jusqu'au \(lastObjective.targetDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    } else {
                        Text("Calculé à partir de vos objectifs")
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
    }

    private var weeklyHoursSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Volume horaire hebdomadaire")
                .font(.ecLabel)
                .foregroundColor(themeManager.textPrimary)

            HStack {
                Button {
                    if formData.weeklyHours > 2 {
                        formData.weeklyHours -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.accentColor)
                        .frame(width: 44, height: 44)
                        .background(themeManager.accentColor.opacity(0.1))
                        .clipShape(Circle())
                }

                Spacer()

                VStack {
                    Text("\(formData.weeklyHours)")
                        .font(.ecH1)
                        .foregroundColor(themeManager.accentColor)

                    Text("heures/semaine")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }

                Spacer()

                Button {
                    if formData.weeklyHours < 20 {
                        formData.weeklyHours += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.accentColor)
                        .frame(width: 44, height: 44)
                        .background(themeManager.accentColor.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
        }
    }

    private var startDateSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Date de début")
                .font(.ecLabel)
                .foregroundColor(themeManager.textPrimary)

            DatePicker("", selection: $formData.startDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding()
                .background(themeManager.cardColor)
                .cornerRadius(ECRadius.lg)

            HStack(spacing: ECSpacing.sm) {
                Button {
                    formData.startDate = PlanFormData.getNextMonday()
                } label: {
                    Text("Lundi prochain")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.accentColor)
                        .padding(.horizontal, ECSpacing.md)
                        .padding(.vertical, ECSpacing.xs)
                        .background(themeManager.accentColor.opacity(0.1))
                        .cornerRadius(ECRadius.full)
                }

                Button {
                    if let date = Calendar.current.date(byAdding: .day, value: 7, to: PlanFormData.getNextMonday()) {
                        formData.startDate = date
                    }
                } label: {
                    Text("Dans 2 semaines")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.accentColor)
                        .padding(.horizontal, ECSpacing.md)
                        .padding(.vertical, ECSpacing.xs)
                        .background(themeManager.accentColor.opacity(0.1))
                        .cornerRadius(ECRadius.full)
                }
            }
        }
    }

    private var perSportSessionsSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Séances par sport")
                .font(.ecLabel)
                .foregroundColor(themeManager.textPrimary)

            Text("Nombre de séances hebdomadaires par discipline")
                .font(.ecCaption)
                .foregroundColor(themeManager.textSecondary)

            VStack(spacing: ECSpacing.sm) {
                // Natation
                sportSessionRow(
                    sport: "Natation",
                    icon: "figure.pool.swim",
                    color: .ecSwimming,
                    value: $formData.swimmingSessions
                )

                // Cyclisme
                sportSessionRow(
                    sport: "Cyclisme",
                    icon: "figure.outdoor.cycle",
                    color: .ecCycling,
                    value: $formData.cyclingSessions
                )

                // Course à pied
                sportSessionRow(
                    sport: "Course à pied",
                    icon: "figure.run",
                    color: .ecRunning,
                    value: $formData.runningSessions
                )
            }
            .padding()
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
        }
    }

    private func sportSessionRow(sport: String, icon: String, color: Color, value: Binding<Int>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 30)

            Text(sport)
                .font(.ecBody)
                .foregroundColor(themeManager.textPrimary)

            Spacer()

            HStack(spacing: ECSpacing.md) {
                Button {
                    if value.wrappedValue > 1 {
                        value.wrappedValue -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value.wrappedValue > 1 ? themeManager.accentColor : themeManager.textTertiary)
                }
                .disabled(value.wrappedValue <= 1)

                Text("\(value.wrappedValue)")
                    .font(.ecH4)
                    .foregroundColor(themeManager.textPrimary)
                    .frame(width: 30)

                Button {
                    if value.wrappedValue < 7 {
                        value.wrappedValue += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value.wrappedValue < 7 ? themeManager.accentColor : themeManager.textTertiary)
                }
                .disabled(value.wrappedValue >= 7)
            }
        }
    }

    private var softConstraintsSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Contraintes & Préférences")
                .font(.ecLabel)
                .foregroundColor(themeManager.textPrimary)

            Text("Indiquez vos contraintes ou préférences d'entraînement (optionnel)")
                .font(.ecCaption)
                .foregroundColor(themeManager.textSecondary)

            TextEditor(text: $formData.softConstraints)
                .frame(minHeight: 80)
                .padding(ECSpacing.sm)
                .background(themeManager.cardColor)
                .cornerRadius(ECRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: ECRadius.lg)
                        .stroke(themeManager.borderColor, lineWidth: 1)
                )

            // Suggestions rapides
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ECSpacing.sm) {
                    ForEach(softConstraintSuggestions, id: \.self) { suggestion in
                        Button {
                            if formData.softConstraints.isEmpty {
                                formData.softConstraints = suggestion
                            } else {
                                formData.softConstraints += "\n" + suggestion
                            }
                        } label: {
                            Text(suggestion)
                                .font(.ecCaption)
                                .foregroundColor(themeManager.accentColor)
                                .padding(.horizontal, ECSpacing.sm)
                                .padding(.vertical, ECSpacing.xs)
                                .background(themeManager.accentColor.opacity(0.1))
                                .cornerRadius(ECRadius.full)
                        }
                    }
                }
            }
        }
    }

    private var softConstraintSuggestions: [String] {
        [
            "Pas de séance le matin",
            "Longue sortie le week-end uniquement",
            "Séances courtes en semaine",
            "Privilégier le home trainer",
            "Piscine disponible 3x/semaine"
        ]
    }

    // MARK: - Step 3: Summary

    private var step3Summary: some View {
        VStack(alignment: .leading, spacing: ECSpacing.lg) {
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Récapitulatif")
                    .font(.ecH2)
                    .foregroundColor(themeManager.textPrimary)

                Text("Vérifiez vos choix avant de générer votre plan")
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
            }

            // Summary Card
            summaryCard

            // Constraints
            constraintsSection

            // Unavailable Days
            unavailableDaysSection
        }
    }

    private var summaryCard: some View {
        let sportColor = themeManager.sportColor(for: formData.sport.discipline)

        return VStack(spacing: 0) {
            summaryRow(label: "Sport", value: formData.sport.label, icon: formData.sport.icon, iconColor: sportColor)
            Divider().padding(.horizontal)

            summaryRow(label: "Niveau", value: formData.experience.planLabel)
            Divider().padding(.horizontal)

            // Nouveaux objectifs structurés
            if !formData.trainingObjectives.isEmpty {
                VStack(alignment: .leading, spacing: ECSpacing.sm) {
                    Text("Objectifs (\(formData.trainingObjectives.count))")
                        .font(.ecLabel)
                        .foregroundColor(themeManager.textSecondary)

                    VStack(spacing: ECSpacing.xs) {
                        ForEach(formData.trainingObjectives.sorted(by: { $0.targetDate < $1.targetDate })) { obj in
                            ObjectiveSummaryCard(objective: obj)
                        }
                    }
                }
                .padding()

                Divider().padding(.horizontal)
            }

            summaryRow(label: "Durée", value: "\(formData.durationWeeks) semaines")
            Divider().padding(.horizontal)

            summaryRow(label: "Volume", value: "\(formData.weeklyHours)h / semaine")
            Divider().padding(.horizontal)

            summaryRow(label: "Début", value: formData.startDate.formatted(date: .long, time: .omitted))
        }
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
    }

    private func summaryRow(label: String, value: String, icon: String? = nil, iconColor: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.ecLabel)
                .foregroundColor(themeManager.textSecondary)

            Spacer()

            HStack(spacing: ECSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(iconColor ?? themeManager.accentColor)
                }
                Text(value)
                    .font(.ecBody)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textPrimary)
            }
        }
        .padding()
    }

    private var constraintsSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Contraintes ou précisions (optionnel)")
                .font(.ecLabel)
                .foregroundColor(themeManager.textPrimary)

            TextField("Ex: Je ne peux pas nager le mardi...", text: $formData.constraints, axis: .vertical)
                .lineLimit(3...5)
                .padding()
                .background(themeManager.cardColor)
                .cornerRadius(ECRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: ECRadius.lg)
                        .stroke(themeManager.borderColor, lineWidth: 1)
                )
        }
    }

    private var unavailableDaysSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Jours indisponibles (optionnel)")
                .font(.ecLabel)
                .foregroundColor(themeManager.textPrimary)

            HStack(spacing: ECSpacing.xs) {
                ForEach(WeekDay.allCases) { day in
                    let isUnavailable = formData.unavailableDays.contains(day)

                    Button {
                        if isUnavailable {
                            formData.unavailableDays.remove(day)
                        } else {
                            formData.unavailableDays.insert(day)
                        }
                    } label: {
                        Text(day.shortLabel)
                            .font(.ecCaption)
                            .fontWeight(.medium)
                            .foregroundColor(isUnavailable ? themeManager.errorColor : themeManager.textPrimary)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(isUnavailable ? themeManager.errorColor.opacity(0.1) : themeManager.cardColor)
                            )
                            .overlay(
                                Circle()
                                    .stroke(isUnavailable ? themeManager.errorColor : themeManager.borderColor, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Footer Buttons

    private var footerButtons: some View {
        HStack(spacing: ECSpacing.sm) {
            if currentStep > 0 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    Text("Retour")
                        .font(.ecButton)
                        .foregroundColor(themeManager.textPrimary)
                        .padding(.vertical, ECSpacing.md)
                        .padding(.horizontal, ECSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: ECRadius.lg)
                                .stroke(themeManager.borderColor, lineWidth: 1)
                        )
                }
            }

            Button {
                if currentStep < 2 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    submitPlan()
                }
            } label: {
                HStack(spacing: ECSpacing.sm) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(currentStep < 2 ? "Continuer" : "Générer mon plan")
                            .font(.ecButton)

                        if currentStep < 2 {
                            Image(systemName: "arrow.right")
                        }
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ECSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: ECRadius.lg)
                        .fill(canProceed() ? themeManager.accentColor : themeManager.textTertiary)
                )
            }
            .disabled(!canProceed() || isSubmitting)
        }
        .padding()
        .background(themeManager.cardColor)
    }

    // MARK: - Helpers

    private func canProceed() -> Bool {
        switch currentStep {
        case 0:
            return true // Sport and experience have defaults
        case 1:
            // Au moins un objectif structuré requis
            return !formData.trainingObjectives.isEmpty &&
                   formData.trainingObjectives.allSatisfy { !$0.name.isEmpty }
        case 2:
            return true
        default:
            return false
        }
    }

    private func submitPlan() {
        guard let userId = authViewModel.user?.id else {
            errorMessage = "Vous devez être connecté pour créer un plan."
            return
        }

        isSubmitting = true

        Task {
            do {
                // Convertir les objectifs structurés en dictionnaires pour l'API
                let objectivesData = formData.trainingObjectives.map { $0.toDictionary() }

                // Construire per_sport_sessions pour triathlon
                var perSportSessions: [String: Int]? = nil
                if formData.sport == .triathlon {
                    perSportSessions = [
                        "swimming": formData.swimmingSessions,
                        "cycling": formData.cyclingSessions,
                        "running": formData.runningSessions
                    ]
                }

                _ = try await PlansService.shared.generatePlanWithObjectives(
                    userId: userId,
                    sport: formData.sport.rawValue,
                    experienceLevel: formData.experience.rawValue,
                    objectives: objectivesData,
                    durationWeeks: formData.durationWeeks,
                    startDate: formData.startDate,
                    weeklyHours: formData.weeklyHours,
                    constraints: formData.constraints.isEmpty ? nil : formData.constraints,
                    unavailableDays: formData.unavailableDays.isEmpty ? nil : formData.unavailableDays.map { $0.rawValue },
                    softConstraintsText: formData.softConstraints.isEmpty ? nil : formData.softConstraints,
                    perSportSessions: perSportSessions
                )

                showSuccessAlert = true
            } catch {
                errorMessage = error.localizedDescription
            }

            isSubmitting = false
        }
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + lineHeight)
        }
    }
}

#Preview {
    TrainingPlanCreatorView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager.shared)
}
