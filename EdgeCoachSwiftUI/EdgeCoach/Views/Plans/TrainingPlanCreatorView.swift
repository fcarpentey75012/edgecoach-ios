/**
 * Écran de création de plan d'entraînement
 * Wizard 3 étapes : Sport & Niveau → Objectifs & Planning → Récapitulatif
 */

import SwiftUI

// MARK: - Data Models

struct PlanFormData {
    var sport: PlanSport = .triathlon
    var experience: ExperienceLevel = .intermediaire
    var objectives: Set<PlanObjective> = []
    var customObjective: String = ""
    var durationWeeks: Int = 8
    var startDate: Date = getNextMonday()
    var weeklyHours: Int = 6
    var constraints: String = ""
    var unavailableDays: Set<WeekDay> = []

    static func getNextMonday() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilMonday = weekday == 1 ? 1 : (9 - weekday)
        return calendar.date(byAdding: .day, value: daysUntilMonday, to: today) ?? today
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
        case .cycling: return "bicycle"
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
}

// Using ExperienceLevel from User.swift
extension ExperienceLevel: Identifiable {
    var id: String { rawValue }

    var planLabel: String { displayName }

    var planDescription: String {
        switch self {
        case .debutant: return "Moins de 1 an de pratique"
        case .intermediaire: return "1 à 3 ans de pratique"
        case .avance: return "3 à 5 ans de pratique"
        case .expert: return "Plus de 5 ans de pratique"
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

    @State private var currentStep = 0
    @State private var formData = PlanFormData()
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?

    private let durationPresets = [4, 8, 12, 16]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressIndicator
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
                            .foregroundColor(.ecSecondary)
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

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: ECSpacing.xs) {
            ForEach(0..<3) { step in
                HStack(spacing: ECSpacing.xs) {
                    Circle()
                        .fill(step <= currentStep ? Color.ecPrimary : Color.ecGray200)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("\(step + 1)")
                                .font(.ecLabel)
                                .fontWeight(.semibold)
                                .foregroundColor(step <= currentStep ? .white : .ecGray500)
                        )
                        .scaleEffect(step == currentStep ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: currentStep)

                    if step < 2 {
                        Rectangle()
                            .fill(step < currentStep ? Color.ecPrimary : Color.ecGray200)
                            .frame(width: 40, height: 2)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
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
        .background(Color.ecBackground)
    }

    // MARK: - Step 1: Sport & Level

    private var step1SportAndLevel: some View {
        VStack(alignment: .leading, spacing: ECSpacing.lg) {
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Sport & Niveau")
                    .font(.ecH2)
                    .foregroundColor(.ecSecondary)

                Text("Choisissez votre sport et indiquez votre niveau d'expérience")
                    .font(.ecBody)
                    .foregroundColor(.ecGray500)
            }

            // Sport Selection
            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                Text("Sport principal")
                    .font(.ecLabel)
                    .foregroundColor(.ecSecondary700)

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
                    .foregroundColor(.ecSecondary700)

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

        return Button {
            formData.sport = sport
        } label: {
            VStack(spacing: ECSpacing.sm) {
                Image(systemName: sport.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? sport.color : .ecGray400)

                Text(sport.label)
                    .font(.ecLabel)
                    .foregroundColor(isSelected ? sport.color : .ecGray600)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ECSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .fill(isSelected ? sport.color.opacity(0.1) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(isSelected ? sport.color : Color.ecGray200, lineWidth: 2)
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
                    .stroke(isSelected ? Color.ecPrimary : Color.ecGray300, lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .fill(isSelected ? Color.ecPrimary : Color.clear)
                            .frame(width: 12, height: 12)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.planLabel)
                        .font(.ecBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.ecSecondary800)

                    Text(level.planDescription)
                        .font(.ecCaption)
                        .foregroundColor(.ecGray500)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .fill(isSelected ? Color.ecPrimary.opacity(0.05) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(isSelected ? Color.ecPrimary : Color.ecGray200, lineWidth: 2)
            )
        }
    }

    // MARK: - Step 2: Objectives & Planning

    private var step2ObjectivesAndPlanning: some View {
        VStack(alignment: .leading, spacing: ECSpacing.lg) {
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Objectifs & Planning")
                    .font(.ecH2)
                    .foregroundColor(.ecSecondary)

                Text("Définissez vos objectifs et la durée de votre programme")
                    .font(.ecBody)
                    .foregroundColor(.ecGray500)
            }

            // Objectives
            objectivesSection

            // Custom Objective
            customObjectiveSection

            // Duration
            durationSection

            // Weekly Hours
            weeklyHoursSection

            // Start Date
            startDateSection
        }
    }

    private var objectivesSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Objectifs rapides (optionnel)")
                .font(.ecLabel)
                .foregroundColor(.ecSecondary700)

            VStack(spacing: ECSpacing.sm) {
                ForEach(PlanObjective.allCases) { objective in
                    objectiveCard(objective)
                }
            }
        }
    }

    private func objectiveCard(_ objective: PlanObjective) -> some View {
        let isSelected = formData.objectives.contains(objective)

        return Button {
            if isSelected {
                formData.objectives.remove(objective)
            } else {
                formData.objectives.insert(objective)
            }
        } label: {
            HStack(spacing: ECSpacing.md) {
                Image(systemName: objective.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .ecPrimary : .ecGray400)

                Text(objective.label)
                    .font(.ecBody)
                    .foregroundColor(isSelected ? .ecPrimary700 : .ecSecondary700)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.ecPrimary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .fill(isSelected ? Color.ecPrimary.opacity(0.05) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(isSelected ? Color.ecPrimary : Color.ecGray200, lineWidth: 2)
            )
        }
    }

    private var customObjectiveSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Mon objectif personnel")
                .font(.ecLabel)
                .foregroundColor(.ecSecondary700)

            TextField("Ex: Préparer le triathlon de Nice en juin...", text: $formData.customObjective, axis: .vertical)
                .lineLimit(3...5)
                .padding()
                .background(Color.white)
                .cornerRadius(ECRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: ECRadius.lg)
                        .stroke(Color.ecGray200, lineWidth: 1)
                )

            Text("Décrivez votre objectif en quelques mots")
                .font(.ecCaption)
                .foregroundColor(.ecGray400)
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Durée du programme")
                .font(.ecLabel)
                .foregroundColor(.ecSecondary700)

            // Presets
            HStack(spacing: ECSpacing.sm) {
                ForEach(durationPresets, id: \.self) { weeks in
                    Button {
                        formData.durationWeeks = weeks
                    } label: {
                        Text("\(weeks) sem.")
                            .font(.ecLabel)
                            .foregroundColor(formData.durationWeeks == weeks ? .ecPrimary600 : .ecGray600)
                            .padding(.vertical, ECSpacing.sm)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: ECRadius.lg)
                                    .fill(formData.durationWeeks == weeks ? Color.ecPrimary.opacity(0.1) : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: ECRadius.lg)
                                    .stroke(formData.durationWeeks == weeks ? Color.ecPrimary : Color.ecGray200, lineWidth: 2)
                            )
                    }
                }
            }

            // Custom duration stepper
            HStack {
                Button {
                    if formData.durationWeeks > 1 {
                        formData.durationWeeks -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 20))
                        .foregroundColor(.ecPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.ecPrimary.opacity(0.1))
                        .clipShape(Circle())
                }

                Spacer()

                VStack {
                    Text("\(formData.durationWeeks)")
                        .font(.ecH1)
                        .foregroundColor(.ecPrimary)

                    Text("semaines")
                        .font(.ecCaption)
                        .foregroundColor(.ecGray500)
                }

                Spacer()

                Button {
                    if formData.durationWeeks < 52 {
                        formData.durationWeeks += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(.ecPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.ecPrimary.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(ECRadius.lg)
        }
    }

    private var weeklyHoursSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Volume horaire hebdomadaire")
                .font(.ecLabel)
                .foregroundColor(.ecSecondary700)

            HStack {
                Button {
                    if formData.weeklyHours > 2 {
                        formData.weeklyHours -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 20))
                        .foregroundColor(.ecPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.ecPrimary.opacity(0.1))
                        .clipShape(Circle())
                }

                Spacer()

                VStack {
                    Text("\(formData.weeklyHours)")
                        .font(.ecH1)
                        .foregroundColor(.ecPrimary)

                    Text("heures/semaine")
                        .font(.ecCaption)
                        .foregroundColor(.ecGray500)
                }

                Spacer()

                Button {
                    if formData.weeklyHours < 20 {
                        formData.weeklyHours += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(.ecPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.ecPrimary.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(ECRadius.lg)
        }
    }

    private var startDateSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Date de début")
                .font(.ecLabel)
                .foregroundColor(.ecSecondary700)

            DatePicker("", selection: $formData.startDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding()
                .background(Color.white)
                .cornerRadius(ECRadius.lg)

            HStack(spacing: ECSpacing.sm) {
                Button {
                    formData.startDate = PlanFormData.getNextMonday()
                } label: {
                    Text("Lundi prochain")
                        .font(.ecCaption)
                        .foregroundColor(.ecPrimary600)
                        .padding(.horizontal, ECSpacing.md)
                        .padding(.vertical, ECSpacing.xs)
                        .background(Color.ecPrimary.opacity(0.1))
                        .cornerRadius(ECRadius.full)
                }

                Button {
                    if let date = Calendar.current.date(byAdding: .day, value: 7, to: PlanFormData.getNextMonday()) {
                        formData.startDate = date
                    }
                } label: {
                    Text("Dans 2 semaines")
                        .font(.ecCaption)
                        .foregroundColor(.ecPrimary600)
                        .padding(.horizontal, ECSpacing.md)
                        .padding(.vertical, ECSpacing.xs)
                        .background(Color.ecPrimary.opacity(0.1))
                        .cornerRadius(ECRadius.full)
                }
            }
        }
    }

    // MARK: - Step 3: Summary

    private var step3Summary: some View {
        VStack(alignment: .leading, spacing: ECSpacing.lg) {
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Récapitulatif")
                    .font(.ecH2)
                    .foregroundColor(.ecSecondary)

                Text("Vérifiez vos choix avant de générer votre plan")
                    .font(.ecBody)
                    .foregroundColor(.ecGray500)
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
        VStack(spacing: 0) {
            summaryRow(label: "Sport", value: formData.sport.label, icon: formData.sport.icon, iconColor: formData.sport.color)
            Divider().padding(.horizontal)

            summaryRow(label: "Niveau", value: formData.experience.planLabel)
            Divider().padding(.horizontal)

            if !formData.objectives.isEmpty {
                VStack(alignment: .leading, spacing: ECSpacing.sm) {
                    Text("Objectifs")
                        .font(.ecLabel)
                        .foregroundColor(.ecGray500)

                    FlowLayout(spacing: ECSpacing.xs) {
                        ForEach(Array(formData.objectives)) { obj in
                            Text(obj.label)
                                .font(.ecCaption)
                                .foregroundColor(.ecPrimary600)
                                .padding(.horizontal, ECSpacing.sm)
                                .padding(.vertical, 4)
                                .background(Color.ecPrimary.opacity(0.1))
                                .cornerRadius(ECRadius.full)
                        }
                    }
                }
                .padding()

                Divider().padding(.horizontal)
            }

            if !formData.customObjective.isEmpty {
                VStack(alignment: .leading, spacing: ECSpacing.xs) {
                    Text("Objectif personnel")
                        .font(.ecLabel)
                        .foregroundColor(.ecGray500)

                    Text("\"\(formData.customObjective)\"")
                        .font(.ecBody)
                        .foregroundColor(.ecSecondary700)
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                Divider().padding(.horizontal)
            }

            summaryRow(label: "Durée", value: "\(formData.durationWeeks) semaines")
            Divider().padding(.horizontal)

            summaryRow(label: "Volume", value: "\(formData.weeklyHours)h / semaine")
            Divider().padding(.horizontal)

            summaryRow(label: "Début", value: formData.startDate.formatted(date: .long, time: .omitted))
        }
        .background(Color.white)
        .cornerRadius(ECRadius.lg)
    }

    private func summaryRow(label: String, value: String, icon: String? = nil, iconColor: Color = .ecPrimary) -> some View {
        HStack {
            Text(label)
                .font(.ecLabel)
                .foregroundColor(.ecGray500)

            Spacer()

            HStack(spacing: ECSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                }
                Text(value)
                    .font(.ecBody)
                    .fontWeight(.medium)
                    .foregroundColor(.ecSecondary800)
            }
        }
        .padding()
    }

    private var constraintsSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Contraintes ou précisions (optionnel)")
                .font(.ecLabel)
                .foregroundColor(.ecSecondary700)

            TextField("Ex: Je ne peux pas nager le mardi...", text: $formData.constraints, axis: .vertical)
                .lineLimit(3...5)
                .padding()
                .background(Color.white)
                .cornerRadius(ECRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: ECRadius.lg)
                        .stroke(Color.ecGray200, lineWidth: 1)
                )
        }
    }

    private var unavailableDaysSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Jours indisponibles (optionnel)")
                .font(.ecLabel)
                .foregroundColor(.ecSecondary700)

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
                            .foregroundColor(isUnavailable ? .ecError : .ecSecondary700)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(isUnavailable ? Color.ecError.opacity(0.1) : Color.white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(isUnavailable ? Color.ecError : Color.ecGray200, lineWidth: 1)
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
                        .foregroundColor(.ecSecondary700)
                        .padding(.vertical, ECSpacing.md)
                        .padding(.horizontal, ECSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: ECRadius.lg)
                                .stroke(Color.ecGray300, lineWidth: 1)
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
                        .fill(canProceed() ? Color.ecPrimary : Color.ecGray300)
                )
            }
            .disabled(!canProceed() || isSubmitting)
        }
        .padding()
        .background(Color.white)
    }

    // MARK: - Helpers

    private func canProceed() -> Bool {
        switch currentStep {
        case 0:
            return true // Sport and experience have defaults
        case 1:
            return !formData.objectives.isEmpty || !formData.customObjective.isEmpty
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
                var allObjectives = formData.objectives.map { $0.rawValue }
                if !formData.customObjective.isEmpty {
                    allObjectives.append("custom:\(formData.customObjective)")
                }

                _ = try await PlansService.shared.generatePlan(
                    userId: userId,
                    sport: formData.sport.rawValue,
                    experienceLevel: formData.experience.rawValue,
                    objectives: allObjectives,
                    customObjective: formData.customObjective.isEmpty ? nil : formData.customObjective,
                    durationWeeks: formData.durationWeeks,
                    startDate: formData.startDate,
                    weeklyHours: formData.weeklyHours,
                    constraints: formData.constraints.isEmpty ? nil : formData.constraints,
                    unavailableDays: formData.unavailableDays.isEmpty ? nil : formData.unavailableDays.map { $0.rawValue }
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
}
