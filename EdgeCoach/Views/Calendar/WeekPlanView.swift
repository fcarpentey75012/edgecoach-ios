/**
 * Vue Semaine pour le mode Planifié
 * Affiche les séances du cycle sur 2 semaines
 */

import SwiftUI

// MARK: - Week Plan View

struct WeekPlanView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: CalendarViewModel
    let onSessionTap: (CycleSession) -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Barre d'info du cycle (phase, semaine x/y, durée)
                WeekPlanInfoBar(viewModel: viewModel)

                // Grille des jours de la semaine
                WeekDaysGrid(viewModel: viewModel, onDateSelected: { date in
                    viewModel.selectDate(date)
                })

                Divider()
                    .background(themeManager.borderColor)
                    .padding(.vertical, ECSpacing.sm)

                // Liste des sessions du jour sélectionné
                WeekPlanSessionsList(
                    viewModel: viewModel,
                    onSessionTap: onSessionTap
                )
            }

            // Toast de résultat de déplacement
            if viewModel.showMoveResult {
                VStack {
                    SessionMoveResultView(
                        warnings: viewModel.lastMoveWarnings,
                        onDismiss: { viewModel.dismissMoveResult() }
                    )
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.3), value: viewModel.showMoveResult)
                .onAppear {
                    // Auto-dismiss après 4 secondes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        viewModel.dismissMoveResult()
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showMoveConfirmation) {
            SessionMoveConfirmationSheet(
                viewModel: viewModel,
                userId: authViewModel.user?.id ?? ""
            )
            .environmentObject(themeManager)
        }
        .onAppear {
            // S'assurer qu'on affiche la semaine courante à chaque apparition
            viewModel.selectCurrentWeek()
        }
    }
}

// MARK: - Week Plan Info Bar (infos du cycle sans navigation)

struct WeekPlanInfoBar: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: CalendarViewModel

    var body: some View {
        if let plan = viewModel.cyclePlan {
            HStack {
                // Badge phase
                Text(plan.phaseDisplayName.uppercased())
                    .font(.ecSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, ECSpacing.sm)
                    .padding(.vertical, 4)
                    .background(phaseColor(for: plan.phase))
                    .cornerRadius(ECRadius.sm)

                // Semaine x/y
                Text("Semaine \(viewModel.selectedWeekIndex + 1)/\(plan.weeks.count)")
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textSecondary)

                Spacer()

                // Durée totale de la semaine
                if let week = viewModel.currentWeek {
                    Label(week.formattedTotalDuration, systemImage: "clock")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }
            }
            .padding(.horizontal, ECSpacing.lg)
            .padding(.vertical, ECSpacing.sm)
        }
    }

    private func phaseColor(for phase: String) -> Color {
        switch phase.uppercased() {
        case "BASE": return themeManager.infoColor
        case "BUILD": return themeManager.warningColor
        case "PEAK": return themeManager.errorColor
        case "RACE": return themeManager.successColor
        case "RECOVERY", "TRANSITION": return themeManager.textSecondary
        default: return themeManager.accentColor
        }
    }
}

// MARK: - Week Days Grid

struct WeekDaysGrid: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: CalendarViewModel
    let onDateSelected: (Date) -> Void

    private let weekDays = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]

    var body: some View {
        VStack(spacing: ECSpacing.xs) {
            // Noms des jours
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, ECSpacing.sm)

            // Cellules des jours
            HStack(spacing: ECSpacing.xs) {
                ForEach(viewModel.daysInCurrentWeek, id: \.self) { date in
                    WeekDayCell(
                        date: date,
                        isSelected: viewModel.isSelected(date),
                        isToday: viewModel.isToday(date),
                        sessions: viewModel.cycleSessionsForDate(date),
                        isInMoveMode: viewModel.isInMoveMode,
                        isValidTarget: viewModel.isInMoveMode && viewModel.isValidMoveTarget(date: date),
                        isSourceDate: viewModel.moveState.sourceDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false,
                        onTap: {
                            if viewModel.isInMoveMode {
                                // En mode déplacement, tap = sélectionner comme cible
                                viewModel.setMoveTarget(date: date)
                                viewModel.prepareMoveConfirmation()
                            } else {
                                onDateSelected(date)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, ECSpacing.sm)
        }
    }
}

// MARK: - Week Day Cell

struct WeekDayCell: View {
    @EnvironmentObject var themeManager: ThemeManager
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let sessions: [CycleSession]
    var isInMoveMode: Bool = false
    var isValidTarget: Bool = false
    var isSourceDate: Bool = false
    let onTap: () -> Void

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Numéro du jour
                ZStack {
                    if isSourceDate {
                        // Date source = orange
                        Circle()
                            .fill(themeManager.warningColor)
                            .frame(width: 32, height: 32)
                    } else if isSelected && !isInMoveMode {
                        Circle()
                            .fill(themeManager.accentColor)
                            .frame(width: 32, height: 32)
                    } else if isToday {
                        Circle()
                            .stroke(themeManager.accentColor, lineWidth: 2)
                            .frame(width: 32, height: 32)
                    }

                    Text(dayNumber)
                        .font(.ecBodyMedium)
                        .foregroundColor(
                            isSourceDate ? .white :
                            (isSelected && !isInMoveMode ? .white :
                             (isToday ? themeManager.accentColor : themeManager.textPrimary))
                        )
                }

                // Indicateurs de sessions (icônes sport)
                if !sessions.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(sessions.prefix(3)) { session in
                            DisciplineIconView(discipline: session.discipline, size: 10, useCustomImage: true)
                        }
                        if sessions.count > 3 {
                            Text("+\(sessions.count - 3)")
                                .font(.system(size: 8))
                                .foregroundColor(themeManager.textTertiary)
                        }
                    }
                    .frame(height: 14)
                } else {
                    // En mode move, montrer une icône de cible
                    if isInMoveMode && isValidTarget && !isSourceDate {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.successColor.opacity(0.7))
                            .frame(height: 14)
                    } else {
                        Spacer()
                            .frame(height: 14)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: ECRadius.sm)
                    .fill(cellBackgroundColor)
            )
            .overlay(
                // Bordure spéciale en mode déplacement
                RoundedRectangle(cornerRadius: ECRadius.sm)
                    .stroke(
                        isInMoveMode && isValidTarget && !isSourceDate ? themeManager.successColor : Color.clear,
                        lineWidth: 2
                    )
                    .animation(.easeInOut(duration: 0.2), value: isInMoveMode)
            )
        }
        .buttonStyle(.premium)
        .animation(.easeInOut(duration: 0.2), value: isInMoveMode)
    }

    private var cellBackgroundColor: Color {
        if isSourceDate {
            return themeManager.warningColor.opacity(0.2)
        } else if isInMoveMode && isValidTarget && !isSourceDate {
            return themeManager.successColor.opacity(0.1)
        } else if !sessions.isEmpty {
            return themeManager.cardColor.opacity(0.5)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Week Plan Sessions List

struct WeekPlanSessionsList: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: CalendarViewModel
    let onSessionTap: (CycleSession) -> Void

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: viewModel.selectedDate).capitalized
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ECSpacing.md) {
                // Bannière mode déplacement
                if viewModel.isInMoveMode {
                    SessionMoveBanner(
                        session: viewModel.moveState.sourceSession,
                        onCancel: { viewModel.cancelSessionMove() }
                    )
                }

                Text(dateString)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                    .padding(.horizontal, ECSpacing.md)

                let sessions = viewModel.selectedDateCycleSessions

                if sessions.isEmpty {
                    EmptyWeekDayView()
                } else {
                    ForEach(sessions) { session in
                        CycleSessionCard(
                            session: session,
                            isBeingMoved: viewModel.moveState.sourceSession?.id == session.id,
                            onTap: {
                                if !viewModel.isInMoveMode {
                                    onSessionTap(session)
                                }
                            },
                            onLongPress: {
                                // Initier le déplacement
                                viewModel.startSessionMove(session: session, from: viewModel.selectedDate)
                            }
                        )
                    }
                }
            }
            .padding(.vertical, ECSpacing.sm)
        }
    }
}

// MARK: - Session Move Banner

struct SessionMoveBanner: View {
    @EnvironmentObject var themeManager: ThemeManager
    let session: CycleSession?
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: ECSpacing.sm) {
            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                .font(.system(size: 16))
                .foregroundColor(themeManager.warningColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Mode déplacement")
                    .font(.ecSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textPrimary)

                if let session = session {
                    Text("Touchez une date pour déplacer \"\(session.displayTitle)\"")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(themeManager.textTertiary)
            }
            .buttonStyle(.premium)
        }
        .padding(ECSpacing.sm)
        .background(themeManager.warningColor.opacity(0.15))
        .cornerRadius(ECRadius.md)
        .padding(.horizontal, ECSpacing.md)
    }
}

// MARK: - Empty Week Day View

struct EmptyWeekDayView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: ECSpacing.sm) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 40))
                .foregroundColor(themeManager.textTertiary)

            Text("Jour de repos")
                .font(.ecBody)
                .foregroundColor(themeManager.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ECSpacing.xl)
    }
}

// MARK: - Cycle Session Card

struct CycleSessionCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let session: CycleSession
    var isBeingMoved: Bool = false
    var onTap: (() -> Void)? = nil
    var onLongPress: (() -> Void)? = nil

    @State private var isPressed: Bool = false

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Barre colorée sport
            Rectangle()
                .fill(themeManager.sportColor(for: session.discipline))
                .frame(width: 4)
                .cornerRadius(2)

            // Icône sport
            ZStack {
                Circle()
                    .fill(themeManager.sportColor(for: session.discipline).opacity(0.15))
                    .frame(width: 40, height: 40)

                DisciplineIconView(discipline: session.discipline, size: 16, useCustomImage: true)
            }

            // Infos session
            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayTitle)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                    .lineLimit(1)

                HStack(spacing: ECSpacing.sm) {
                    // Durée
                    Label(session.formattedDuration, systemImage: "clock")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)

                    // Distance (si disponible)
                    if let distance = session.formattedDistance {
                        Label(distance, systemImage: "arrow.left.and.right")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    // Zone/Intensité
                    if let intensity = session.intensity {
                        Text(intensity)
                            .font(.ecSmall)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(intensityColor(intensity))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            // TSS estimé ou icône de déplacement
            if isBeingMoved {
                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.warningColor)
            } else {
                if let tss = session.formattedTss {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(tss)
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)
                        Text("TSS")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textTertiary)
            }
        }
        .padding(ECSpacing.md)
        .background(isBeingMoved ? themeManager.warningColor.opacity(0.1) : themeManager.cardColor)
        .cornerRadius(ECRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.md)
                .stroke(isBeingMoved ? themeManager.warningColor : themeManager.borderColor, lineWidth: isBeingMoved ? 2 : 1)
        )
        .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
        .padding(.horizontal, ECSpacing.md)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isBeingMoved)
        .onTapGesture {
            onTap?()
        }
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            isPressed = pressing
        }, perform: {
            // Feedback haptique
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onLongPress?()
        })
    }

    private func intensityColor(_ intensity: String) -> Color {
        switch intensity.uppercased() {
        case "Z1": return .blue.opacity(0.7)
        case "Z2": return .green
        case "Z3": return .yellow.opacity(0.8)
        case "Z4": return .orange
        case "Z5": return .red
        default: return themeManager.textSecondary
        }
    }
}

// MARK: - Cycle Session Detail View

struct CycleSessionDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appState: AppState
    let session: CycleSession
    var cycleNotes: String? = nil
    var onNavigateToChat: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSegment: WorkoutSegment?
    @State private var showFullCoachDescription = false
    @State private var showFullRationale = false
    @State private var showFullNotes = false
    @State private var showingAnalysisSheet = false
    @State private var buttonPosition: CGPoint = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
            ZStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    // Header
                    sessionHeader

                    // Stats rapides
                    quickStats

                    // Objectif (extrait du coach_description)
                    if let objective = extractObjective(from: session.coachDescription) {
                        objectiveSection(objective)
                    }

                    // Structure de l'entraînement (cliquable)
                    if let structure = session.workoutStructure, !structure.isEmpty {
                        workoutStructureSection(structure)
                    }

                    // Rationale (pourquoi cette séance)
                    if let rationale = session.rationale, !rationale.isEmpty {
                        rationaleSection(rationale)
                    }

                    // Conseil du coach (tronqué avec voir plus)
                    if let coachDesc = session.coachDescription, !coachDesc.isEmpty {
                        coachDescriptionSection(coachDesc)
                    }

                    // Notes du cycle
                    if let notes = cycleNotes, !notes.isEmpty {
                        notesSection(notes)
                    }

                    Spacer(minLength: ECSpacing.xl)
                }
                .padding()
                .padding(.bottom, 80)
            }

            // Bouton flottant Coach IA
            coachFloatingButton(in: geometry)
            }
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Séance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
            .sheet(isPresented: $showingAnalysisSheet) {
                PlannedSessionAnalysisSheet(
                    session: session,
                    onNavigateToChat: {
                        dismiss()
                        onNavigateToChat?()
                    }
                )
                .environmentObject(appState)
                .environmentObject(themeManager)
            }
            .sheet(item: $selectedSegment) { segment in
                SegmentDetailSheet(segment: segment, sport: session.sport)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showFullCoachDescription) {
                FullTextSheet(title: "Conseil du coach", text: session.coachDescription ?? "", icon: "person.fill", iconColor: themeManager.warningColor)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showFullRationale) {
                FullTextSheet(title: "Pourquoi cette séance", text: session.rationale ?? "", icon: "lightbulb", iconColor: themeManager.infoColor)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showFullNotes) {
                FullTextSheet(title: "Notes du cycle", text: cycleNotes ?? "", icon: "note.text", iconColor: themeManager.successColor)
                    .environmentObject(themeManager)
            }
        }
    }

    /// Extrait l'objectif du coach_description (ligne commençant par 🎯)
    private func extractObjective(from text: String?) -> String? {
        guard let text = text else { return nil }
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            if line.contains("OBJECTIF") || line.contains("🎯") {
                // Nettoyer la ligne
                var cleaned = line
                    .replacingOccurrences(of: "🎯", with: "")
                    .replacingOccurrences(of: "**OBJECTIF**", with: "")
                    .replacingOccurrences(of: "**", with: "")
                    .replacingOccurrences(of: ":", with: "")
                    .trimmingCharacters(in: .whitespaces)
                return cleaned.isEmpty ? nil : cleaned
            }
        }
        return nil
    }

    // MARK: - Header

    private var sessionHeader: some View {
        VStack(spacing: ECSpacing.md) {
            ZStack {
                Circle()
                    .fill(themeManager.sportColor(for: session.discipline).opacity(0.15))
                    .frame(width: 80, height: 80)

                DisciplineIconView(discipline: session.discipline, size: 36, useCustomImage: true)
            }

            Text(session.displayTitle)
                .font(.ecH3)
                .foregroundColor(themeManager.textPrimary)
                .multilineTextAlignment(.center)

            if let dateValue = session.dateValue {
                Text(formatDate(dateValue))
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
            }

            // Type badge
            if let type = session.type {
                Text(type)
                    .font(.ecSmall)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.accentColor)
                    .padding(.horizontal, ECSpacing.sm)
                    .padding(.vertical, 4)
                    .background(themeManager.accentColor.opacity(0.1))
                    .cornerRadius(ECRadius.sm)
            }
        }
        .padding(.top, ECSpacing.lg)
    }

    // MARK: - Quick Stats

    private var quickStats: some View {
        HStack(spacing: 0) {
            StatItem(icon: "clock", value: session.formattedDuration, label: "Durée")

            if let distance = session.formattedDistance {
                StatItem(icon: "arrow.left.and.right", value: distance, label: "Distance")
            }

            if let intensity = session.intensity {
                StatItem(icon: "flame", value: intensity, label: "Zone")
            }

            if let tss = session.formattedTss {
                StatItem(icon: "bolt", value: tss, label: "TSS")
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }

    // MARK: - Objective Section

    private func objectiveSection(_ objective: String) -> some View {
        HStack(spacing: ECSpacing.sm) {
            Image(systemName: "target")
                .font(.system(size: 20))
                .foregroundColor(themeManager.accentColor)

            Text(objective)
                .font(.ecBodyMedium)
                .foregroundColor(themeManager.textPrimary)
                .lineLimit(3)

            Spacer()
        }
        .padding(ECSpacing.md)
        .background(themeManager.accentColor.opacity(0.1))
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.accentColor.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Workout Structure

    @ViewBuilder
    private func workoutStructureSection(_ structure: [WorkoutSegment]) -> some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(themeManager.accentColor)
                Text("Structure")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()

                // Durée totale
                Text(totalDurationFormatted(structure))
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(themeManager.accentColor)
            }

            // Graphique d'intervalles style 2peak (interactif)
            WorkoutIntervalsChart(
                segments: structure,
                zoneColorProvider: zoneColor,
                selectedSegment: $selectedSegment
            )

            // Label synthétique des intervalles (si pas de segment sélectionné)
            if selectedSegment == nil, let summary = intervalsSummary(structure) {
                Text(summary)
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Divider()
                .background(themeManager.borderColor)

            // Liste détaillée des segments (cliquables, synchronisée avec le graphique)
            VStack(spacing: ECSpacing.xs) {
                ForEach(Array(structure.enumerated()), id: \.element.id) { index, segment in
                    let isSelected = selectedSegment?.id == segment.id

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedSegment?.id == segment.id {
                                selectedSegment = nil
                            } else {
                                selectedSegment = segment
                            }
                        }
                    } label: {
                        WorkoutSegmentListRow(
                            segment: segment,
                            zoneColor: zoneColor(segment.intensityTarget),
                            isSelected: isSelected
                        )
                    }
                    .buttonStyle(.premium)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }

    /// Durée totale formatée
    private func totalDurationFormatted(_ segments: [WorkoutSegment]) -> String {
        let totalSeconds = segments.compactMap { $0.durationValue }.reduce(0, +)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d'%02d", hours, minutes, seconds)
        }
        return String(format: "%02d'%02d", minutes, seconds)
    }

    /// Résumé des intervalles (ex: "Z5 (4 x 03'00'')")
    private func intervalsSummary(_ segments: [WorkoutSegment]) -> String? {
        // Trouver les segments de travail (pas warmup/cooldown/recovery)
        let workSegments = segments.filter { segment in
            let type = segment.segmentType?.lowercased() ?? ""
            return type == "work" || type == "interval" || type == "steady"
        }

        guard !workSegments.isEmpty else { return nil }

        // Grouper par zone et durée
        var zoneCounts: [String: (count: Int, duration: Int)] = [:]
        for segment in workSegments {
            let zone = segment.intensityTarget ?? "Work"
            let duration = segment.durationValue ?? 0
            let key = "\(zone)_\(duration)"
            if let existing = zoneCounts[key] {
                zoneCounts[key] = (existing.count + 1, duration)
            } else {
                zoneCounts[key] = (1, duration)
            }
        }

        // Construire le résumé
        let summaries = zoneCounts.map { (key, value) in
            let zone = key.components(separatedBy: "_").first ?? "Work"
            let minutes = value.duration / 60
            let seconds = value.duration % 60
            if value.count > 1 {
                return "\(zone) (\(value.count) x \(String(format: "%02d'%02d''", minutes, seconds)))"
            } else {
                return "\(zone) \(String(format: "%02d'%02d''", minutes, seconds))"
            }
        }

        return summaries.joined(separator: " + ")
    }

    /// Couleur par zone d'entraînement (standard)
    private func zoneColor(_ zone: String?) -> Color {
        guard let zone = zone?.uppercased() else { return Color.gray.opacity(0.5) }

        switch zone {
        case "Z1", "RECOVERY":
            return Color(red: 0.6, green: 0.6, blue: 0.6) // Gris - Récup
        case "Z2", "ENDURANCE":
            return Color(red: 0.0, green: 0.6, blue: 0.9) // Bleu - Endurance
        case "Z3", "TEMPO":
            return Color(red: 0.2, green: 0.8, blue: 0.2) // Vert - Tempo
        case "Z4", "THRESHOLD", "FTP":
            return Color(red: 1.0, green: 0.8, blue: 0.0) // Jaune/Or - Seuil
        case "Z5", "VO2MAX", "VO2":
            return Color(red: 1.0, green: 0.4, blue: 0.0) // Orange - VO2max
        case "Z6", "ANAEROBIC":
            return Color(red: 0.9, green: 0.1, blue: 0.1) // Rouge - Anaérobie
        case "Z7", "SPRINT", "NEUROMUSCULAR":
            return Color(red: 0.6, green: 0.0, blue: 0.6) // Violet - Sprint
        default:
            // Essayer d'extraire le numéro de zone
            if zone.contains("1") { return zoneColor("Z1") }
            if zone.contains("2") { return zoneColor("Z2") }
            if zone.contains("3") { return zoneColor("Z3") }
            if zone.contains("4") { return zoneColor("Z4") }
            if zone.contains("5") { return zoneColor("Z5") }
            return Color.gray.opacity(0.5)
        }
    }
}

// MARK: - Workout Segment Row (Timeline Style)

struct WorkoutSegmentRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let segment: WorkoutSegment
    let isFirst: Bool
    let isLast: Bool
    let zoneColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: ECSpacing.md) {
            // Colonne de gauche : barre verticale colorée + connecteur
            VStack(spacing: 0) {
                // Connecteur haut (invisible si premier)
                Rectangle()
                    .fill(isFirst ? Color.clear : themeManager.borderColor)
                    .frame(width: 2, height: 8)

                // Barre de zone colorée (hauteur proportionnelle ou fixe)
                RoundedRectangle(cornerRadius: 3)
                    .fill(zoneColor)
                    .frame(width: 6, height: segmentHeight)

                // Connecteur bas (invisible si dernier)
                Rectangle()
                    .fill(isLast ? Color.clear : themeManager.borderColor)
                    .frame(width: 2, height: 8)
            }
            .frame(width: 20)

            // Contenu du segment
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Badge zone
                    if let target = segment.intensityTarget {
                        Text(target)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(zoneColor)
                            .cornerRadius(6)
                    }

                    // Type de segment
                    Text(segment.displayType)
                        .font(.ecBodyMedium)
                        .foregroundColor(themeManager.textPrimary)

                    Spacer()

                    // Durée
                    Text(segment.formattedDuration)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(themeManager.textPrimary)
                }

                // Description
                if let desc = segment.description, !desc.isEmpty {
                    Text(desc)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 8)
        }
    }

    /// Hauteur de la barre basée sur la durée (min 30, max 80)
    private var segmentHeight: CGFloat {
        let minutes = CGFloat(segment.durationValue ?? 0) / 60.0
        let height = max(30, min(80, minutes * 1.5))
        return height
    }
}

// MARK: - Workout Intervals Chart (Style 2peak - Interactive)

struct WorkoutIntervalsChart: View {
    @EnvironmentObject var themeManager: ThemeManager
    let segments: [WorkoutSegment]
    let zoneColorProvider: (String?) -> Color
    @Binding var selectedSegment: WorkoutSegment?

    /// Durée totale en secondes
    private var totalDuration: Int {
        segments.compactMap { $0.durationValue }.reduce(0, +)
    }

    /// Hauteur maximale du graphique
    private let maxBarHeight: CGFloat = 100

    /// Hauteur de base (Z1)
    private let baseHeight: CGFloat = 25

    var body: some View {
        VStack(spacing: ECSpacing.xs) {
            // Graphique des barres
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: 1) {
                    ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                        let barWidth = widthForSegment(segment, totalWidth: geometry.size.width)
                        let barHeight = heightForZone(segment.intensityTarget)
                        let color = zoneColorProvider(segment.intensityTarget)
                        let isSelected = selectedSegment?.id == segment.id

                        // Barre cliquable
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedSegment?.id == segment.id {
                                    selectedSegment = nil
                                } else {
                                    selectedSegment = segment
                                }
                            }
                        } label: {
                            ZStack(alignment: .bottom) {
                                // Barre principale
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                color.opacity(0.9),
                                                color
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: max(barWidth - 1, 6), height: barHeight)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(
                                                isSelected ? Color.white : color.opacity(0.5),
                                                lineWidth: isSelected ? 2 : 0.5
                                            )
                                    )
                                    .shadow(
                                        color: isSelected ? color.opacity(0.6) : Color.clear,
                                        radius: isSelected ? 6 : 0,
                                        x: 0,
                                        y: 2
                                    )
                                    .scaleEffect(isSelected ? 1.05 : 1.0)
                            }
                            .frame(width: barWidth, height: maxBarHeight, alignment: .bottom)
                        }
                        .buttonStyle(.premium)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: maxBarHeight)

            // Info du segment sélectionné
            if let segment = selectedSegment {
                selectedSegmentInfo(segment)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(ECSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: ECRadius.md)
                .fill(themeManager.backgroundColor.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: ECRadius.md)
                        .stroke(themeManager.borderColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    /// Info du segment sélectionné
    @ViewBuilder
    private func selectedSegmentInfo(_ segment: WorkoutSegment) -> some View {
        let color = zoneColorProvider(segment.intensityTarget)

        HStack(spacing: ECSpacing.md) {
            // Barre de couleur
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                // Type et zone
                HStack(spacing: ECSpacing.sm) {
                    Text(segment.displayType)
                        .font(.ecBodyMedium)
                        .foregroundColor(themeManager.textPrimary)

                    if let target = segment.intensityTarget {
                        Text(target)
                            .font(.ecCaptionBold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(color)
                            .cornerRadius(ECRadius.sm)
                    }
                }

                // Description si disponible
                if let desc = segment.description, !desc.isEmpty {
                    Text(desc)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Durée
            VStack(alignment: .trailing, spacing: 2) {
                Text(segment.formattedDuration)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(color)

                if let durationValue = segment.durationValue {
                    let minutes = durationValue / 60
                    let seconds = durationValue % 60
                    Text(seconds > 0 ? "\(minutes)'\(String(format: "%02d", seconds))''" : "\(minutes) min")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }
        }
        .padding(ECSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: ECRadius.sm)
                .fill(color.opacity(0.1))
        )
    }

    /// Largeur proportionnelle à la durée
    private func widthForSegment(_ segment: WorkoutSegment, totalWidth: CGFloat) -> CGFloat {
        guard totalDuration > 0, let duration = segment.durationValue else { return 20 }
        let ratio = CGFloat(duration) / CGFloat(totalDuration)
        return max(totalWidth * ratio, 12) // Minimum 12pt pour pouvoir cliquer
    }

    /// Hauteur basée sur la zone d'intensité - échelle améliorée
    private func heightForZone(_ zone: String?) -> CGFloat {
        guard let zone = zone?.uppercased() else { return baseHeight * 1.5 }

        switch zone {
        case "Z1", "RECOVERY":
            return baseHeight  // 25pt
        case "Z2", "ENDURANCE":
            return baseHeight * 1.8  // 45pt
        case "Z3", "TEMPO":
            return baseHeight * 2.4  // 60pt
        case "Z4", "THRESHOLD", "FTP":
            return baseHeight * 3.0  // 75pt
        case "Z5", "VO2MAX", "VO2":
            return baseHeight * 3.4  // 85pt
        case "Z6", "ANAEROBIC":
            return baseHeight * 3.7  // 92pt
        case "Z7", "SPRINT", "NEUROMUSCULAR":
            return maxBarHeight  // 100pt
        default:
            // Essayer d'extraire le numéro de zone
            if zone.contains("1") { return heightForZone("Z1") }
            if zone.contains("2") { return heightForZone("Z2") }
            if zone.contains("3") { return heightForZone("Z3") }
            if zone.contains("4") { return heightForZone("Z4") }
            if zone.contains("5") { return heightForZone("Z5") }
            if zone.contains("6") { return heightForZone("Z6") }
            if zone.contains("7") { return heightForZone("Z7") }
            return baseHeight * 1.5
        }
    }
}

// MARK: - Workout Segment List Row (Compact Style)

struct WorkoutSegmentListRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let segment: WorkoutSegment
    let zoneColor: Color
    var isSelected: Bool = false

    /// Durée formatée courte (ex: "15'" ou "3'")
    private var shortDuration: String {
        guard let value = segment.durationValue else { return "-" }
        let minutes = value / 60
        let seconds = value % 60
        if seconds > 0 {
            return "\(minutes)'\(String(format: "%02d", seconds))"
        }
        return "\(minutes)'"
    }

    /// Nom de zone formaté
    private var zoneName: String {
        guard let target = segment.intensityTarget else {
            return segment.displayType
        }

        let zone = target.uppercased()
        switch zone {
        case "Z1", "RECOVERY": return "Zone 1"
        case "Z2", "ENDURANCE": return "Zone 2"
        case "Z3", "TEMPO": return "Zone 3"
        case "Z4", "THRESHOLD", "FTP": return "Zone 4"
        case "Z5", "VO2MAX", "VO2": return "Zone 5"
        case "Z6", "ANAEROBIC": return "Zone 6"
        case "Z7", "SPRINT", "NEUROMUSCULAR": return "Zone 7"
        default:
            if zone.hasPrefix("Z") { return "Zone \(zone.dropFirst())" }
            return target
        }
    }

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Durée
            Text(shortDuration)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(zoneColor)
                .frame(width: 44, alignment: .leading)

            // Barre verticale de couleur
            RoundedRectangle(cornerRadius: 2)
                .fill(zoneColor)
                .frame(width: isSelected ? 6 : 4, height: isSelected ? 28 : nil)

            // Nom de zone
            Text(zoneName)
                .font(isSelected ? .ecBodyMedium : .ecBody)
                .foregroundColor(themeManager.textPrimary)

            Spacer()

            // Chevron ou checkmark si sélectionné
            Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                .font(isSelected ? .body : .ecCaption)
                .foregroundColor(isSelected ? zoneColor : themeManager.textTertiary)
        }
        .frame(height: 40)
        .padding(.horizontal, ECSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: ECRadius.sm)
                .fill(isSelected ? zoneColor.opacity(0.15) : themeManager.backgroundColor.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.sm)
                .stroke(isSelected ? zoneColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Cycle Session Detail View Helpers

extension CycleSessionDetailView {

    // MARK: - Coach Floating Button

    func coachFloatingButton(in geometry: GeometryProxy) -> some View {
        let buttonSize: CGFloat = 44
        let padding: CGFloat = ECSpacing.lg

        // Position par défaut (bas droite)
        let defaultPosition = CGPoint(
            x: geometry.size.width - buttonSize - padding,
            y: geometry.size.height - buttonSize - padding - geometry.safeAreaInsets.bottom
        )

        // Initialiser la position si nécessaire
        let currentPosition = buttonPosition == .zero ? defaultPosition : buttonPosition

        return Image(systemName: "bubble.left.and.text.bubble.right.fill")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: buttonSize, height: buttonSize)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: themeManager.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
            )
            .position(currentPosition)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Limiter aux bords de l'écran
                        let newX = min(max(buttonSize/2 + padding, value.location.x), geometry.size.width - buttonSize/2 - padding)
                        let newY = min(max(buttonSize/2 + padding, value.location.y), geometry.size.height - buttonSize/2 - padding - geometry.safeAreaInsets.bottom)
                        buttonPosition = CGPoint(x: newX, y: newY)
                    }
            )
            .onTapGesture {
                showingAnalysisSheet = true
            }
    }

    // MARK: - Coach Description (tronqué avec voir plus)

    func coachDescriptionSection(_ description: String) -> some View {
        let maxLength = 150
        let isTruncated = description.count > maxLength

        return Button {
            showFullCoachDescription = true
        } label: {
            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(themeManager.warningColor)
                    Text("Conseil du coach")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                    Spacer()
                    if isTruncated {
                        Text("Voir plus")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.accentColor)
                        Image(systemName: "chevron.right")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.accentColor)
                    }
                }

                Text(isTruncated ? String(description.prefix(maxLength)) + "..." : description)
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.premium)
    }

    // MARK: - Rationale (tronqué avec voir plus)

    private func rationaleSection(_ rationale: String) -> some View {
        let maxLength = 120
        let isTruncated = rationale.count > maxLength

        return Button {
            showFullRationale = true
        } label: {
            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(themeManager.infoColor)
                    Text("Pourquoi cette séance")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                    Spacer()
                    if isTruncated {
                        Text("Voir plus")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.accentColor)
                        Image(systemName: "chevron.right")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.accentColor)
                    }
                }

                Text(isTruncated ? String(rationale.prefix(maxLength)) + "..." : rationale)
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.premium)
    }

    // MARK: - Notes Section (tronqué avec voir plus)

    private func notesSection(_ notes: String) -> some View {
        let maxLength = 100
        let isTruncated = notes.count > maxLength

        return Button {
            showFullNotes = true
        } label: {
            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(themeManager.successColor)
                    Text("Notes du cycle")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                    Spacer()
                    if isTruncated {
                        Text("Voir plus")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.accentColor)
                        Image(systemName: "chevron.right")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.accentColor)
                    }
                }

                Text(isTruncated ? String(notes.prefix(maxLength)) + "..." : notes)
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.premium)
    }

    // MARK: - Markdown Helper

    private func markdownToAttributedString(_ markdown: String) -> AttributedString {
        do {
            return try AttributedString(markdown: markdown, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            return AttributedString(markdown)
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date).capitalized
    }

    private func segmentIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "warmup": return "flame"
        case "work": return "bolt.fill"
        case "steady": return "arrow.right"
        case "cooldown": return "snow"
        case "recovery": return "heart"
        case "interval": return "waveform.path"
        default: return "circle"
        }
    }

    private func segmentColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "warmup": return .orange
        case "work": return themeManager.accentColor
        case "steady": return .green
        case "cooldown": return .blue
        case "recovery": return .mint
        case "interval": return .red
        default: return themeManager.textSecondary
        }
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textTertiary)
                Text(value)
                    .font(.ecBodyMedium)
                    .foregroundColor(themeManager.textPrimary)
            }
            Text(label)
                .font(.ecSmall)
                .foregroundColor(themeManager.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Full Text Sheet

struct FullTextSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let title: String
    let text: String
    let icon: String
    let iconColor: Color

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ECSpacing.lg) {
                    // Header
                    HStack(spacing: ECSpacing.sm) {
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(iconColor)

                        Text(title)
                            .font(.ecH3)
                            .foregroundColor(themeManager.textPrimary)

                        Spacer()
                    }
                    .padding(.top, ECSpacing.md)

                    // Contenu avec rendu markdown
                    Text(markdownToAttributedString(text))
                        .font(.ecBody)
                        .foregroundColor(themeManager.textSecondary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: ECSpacing.xl)
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
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

    private func markdownToAttributedString(_ markdown: String) -> AttributedString {
        do {
            return try AttributedString(markdown: markdown, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            return AttributedString(markdown)
        }
    }
}

// MARK: - Segment Detail Sheet

struct SegmentDetailSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let segment: WorkoutSegment
    let sport: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    // Header avec zone
                    VStack(spacing: ECSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(zoneColor.opacity(0.15))
                                .frame(width: 80, height: 80)

                            VStack(spacing: 2) {
                                if let target = segment.intensityTarget {
                                    Text(target)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(zoneColor)
                                }
                                Image(systemName: segmentIcon)
                                    .font(.system(size: 20))
                                    .foregroundColor(zoneColor)
                            }
                        }

                        Text(segment.displayType)
                            .font(.ecH3)
                            .foregroundColor(themeManager.textPrimary)

                        Text(segment.formattedDuration)
                            .font(.ecH4)
                            .foregroundColor(themeManager.textSecondary)
                    }
                    .padding(.top, ECSpacing.lg)

                    // Détails de la zone
                    if let target = segment.intensityTarget {
                        zoneInfoCard(target)
                    }

                    // Description du segment
                    if let desc = segment.description, !desc.isEmpty {
                        descriptionCard(desc)
                    }

                    // Conseils selon le type de segment
                    tipsCard

                    Spacer(minLength: ECSpacing.xl)
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Détail du bloc")
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
        .presentationDetents([.medium, .large])
    }

    private var zoneColor: Color {
        guard let zone = segment.intensityTarget?.uppercased() else { return .gray }
        switch zone {
        case "Z1", "RECOVERY": return Color(red: 0.6, green: 0.6, blue: 0.6)
        case "Z2", "ENDURANCE": return Color(red: 0.0, green: 0.6, blue: 0.9)
        case "Z3", "TEMPO": return Color(red: 0.2, green: 0.8, blue: 0.2)
        case "Z4", "THRESHOLD", "FTP": return Color(red: 1.0, green: 0.8, blue: 0.0)
        case "Z5", "VO2MAX", "VO2": return Color(red: 1.0, green: 0.4, blue: 0.0)
        case "Z6", "ANAEROBIC": return Color(red: 0.9, green: 0.1, blue: 0.1)
        case "Z7", "SPRINT": return Color(red: 0.6, green: 0.0, blue: 0.6)
        default: return .gray
        }
    }

    private var segmentIcon: String {
        switch segment.segmentType?.lowercased() ?? "" {
        case "warmup": return "flame"
        case "work", "main": return "bolt.fill"
        case "steady": return "arrow.right"
        case "cooldown": return "snowflake"
        case "recovery": return "heart"
        case "interval": return "waveform.path"
        default: return "circle.fill"
        }
    }

    private func zoneInfoCard(_ zone: String) -> some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            HStack {
                Image(systemName: "gauge.with.needle")
                    .foregroundColor(zoneColor)
                Text("Zone d'intensité")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Zone:")
                        .font(.ecBody)
                        .foregroundColor(themeManager.textSecondary)
                    Text(zone)
                        .font(.ecBodyMedium)
                        .foregroundColor(zoneColor)
                }

                Text(zoneDescription(zone))
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
                    .lineSpacing(4)

                // Effort perçu
                HStack {
                    Text("Effort perçu:")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                    Text(rpeDescription(zone))
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textPrimary)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }

    private func descriptionCard(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(themeManager.infoColor)
                Text("Instructions")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
            }

            Text(description)
                .font(.ecBody)
                .foregroundColor(themeManager.textSecondary)
                .lineSpacing(4)
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(themeManager.warningColor)
                Text("Conseils")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(tipsForSegment, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.successColor)
                            .padding(.top, 2)
                        Text(tip)
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }

    private var tipsForSegment: [String] {
        switch segment.segmentType?.lowercased() ?? "" {
        case "warmup":
            return [
                "Commence doucement, laisse ton corps se préparer",
                "Augmente progressivement l'intensité",
                "Concentre-toi sur ta respiration"
            ]
        case "work", "main", "steady":
            return [
                "Maintiens un effort régulier et contrôlé",
                "Surveille ta fréquence cardiaque",
                "Reste dans la zone ciblée"
            ]
        case "cooldown":
            return [
                "Réduis progressivement l'intensité",
                "Laisse ta fréquence cardiaque redescendre",
                "Profite de ce moment pour récupérer"
            ]
        case "interval":
            return [
                "Donne le maximum pendant l'effort",
                "Récupère activement entre les répétitions",
                "Maintiens une bonne technique"
            ]
        default:
            return [
                "Reste concentré sur l'objectif de ce bloc",
                "Écoute ton corps et adapte si nécessaire"
            ]
        }
    }

    private func zoneDescription(_ zone: String) -> String {
        switch zone.uppercased() {
        case "Z1", "RECOVERY":
            return "Zone de récupération active. Effort très léger, conversation facile. Idéal pour la récupération."
        case "Z2", "ENDURANCE":
            return "Zone d'endurance fondamentale. Effort modéré, respiration contrôlée. Développe l'aérobie de base."
        case "Z3", "TEMPO":
            return "Zone tempo. Effort soutenu mais gérable. Améliore l'endurance musculaire."
        case "Z4", "THRESHOLD", "FTP":
            return "Zone seuil. Effort intense, respiration difficile. Améliore la puissance au seuil."
        case "Z5", "VO2MAX", "VO2":
            return "Zone VO2max. Effort très intense, respiration maximale. Développe la capacité aérobie maximale."
        case "Z6", "ANAEROBIC":
            return "Zone anaérobie. Effort maximal de courte durée. Améliore la puissance explosive."
        case "Z7", "SPRINT":
            return "Zone sprint neuromusculaire. Effort maximal très bref. Développe la vitesse pure."
        default:
            return "Zone d'entraînement ciblée pour cette partie de la séance."
        }
    }

    private func rpeDescription(_ zone: String) -> String {
        switch zone.uppercased() {
        case "Z1", "RECOVERY": return "1-2/10 - Très facile"
        case "Z2", "ENDURANCE": return "3-4/10 - Facile à modéré"
        case "Z3", "TEMPO": return "5-6/10 - Modéré"
        case "Z4", "THRESHOLD", "FTP": return "7-8/10 - Difficile"
        case "Z5", "VO2MAX", "VO2": return "8-9/10 - Très difficile"
        case "Z6", "ANAEROBIC": return "9-10/10 - Maximal"
        case "Z7", "SPRINT": return "10/10 - Sprint maximal"
        default: return "Adapté au bloc"
        }
    }
}

// MARK: - Planned Session Analysis Sheet

struct PlannedSessionAnalysisSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager

    let session: CycleSession
    var onNavigateToChat: (() -> Void)?

    @State private var customQuestion: String = ""
    @FocusState private var isCustomQuestionFocused: Bool

    // Options d'analyse spécifiques aux séances planifiées
    private var analysisOptions: [PlannedAnalysisOption] {
        [
            PlannedAnalysisOption(
                icon: "figure.run",
                title: "Comment me préparer ?",
                description: "Conseils de préparation pour cette séance"
            ),
            PlannedAnalysisOption(
                icon: "slider.horizontal.3",
                title: "Adapter cette séance",
                description: "Modifier l'intensité ou la durée selon ma forme"
            ),
            PlannedAnalysisOption(
                icon: "fork.knife",
                title: "Nutrition recommandée",
                description: "Quoi manger avant et pendant la séance"
            ),
            PlannedAnalysisOption(
                icon: "questionmark.circle",
                title: "Expliquer les zones",
                description: "Comprendre les zones d'entraînement visées"
            )
        ]
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
            .navigationTitle("Questions sur la séance")
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
                    .fill(themeManager.sportColor(for: session.discipline).opacity(0.15))
                    .frame(width: 56, height: 56)

                DisciplineIconView(discipline: session.discipline, size: 24, useCustomImage: true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayTitle)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                    .lineLimit(1)

                Text("\(session.discipline.displayName) • \(formattedDate)")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)

                HStack(spacing: ECSpacing.sm) {
                    Text(session.formattedDuration)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)

                    if let distance = session.formattedDistance {
                        Text("•")
                            .foregroundColor(themeManager.textTertiary)
                        Text(distance)
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textTertiary)
                    }
                }
            }

            Spacer()

            // Badge "Planifiée"
            Text("Planifiée")
                .font(.ecSmall)
                .fontWeight(.medium)
                .foregroundColor(themeManager.infoColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(themeManager.infoColor.opacity(0.15))
                .cornerRadius(ECRadius.sm)
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
    }

    private var formattedDate: String {
        guard let date = session.dateValue else { return session.date }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Analysis Options Section

    private var analysisOptionsSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Comment puis-je t'aider ?")
                .font(.ecLabel)
                .foregroundColor(themeManager.textPrimary)

            VStack(spacing: ECSpacing.sm) {
                ForEach(analysisOptions) { option in
                    PlannedAnalysisOptionCard(
                        option: option,
                        sportColor: themeManager.sportColor(for: session.discipline)
                    ) {
                        sendAnalysisRequest(option.title)
                    }
                }
            }
        }
    }

    // MARK: - Custom Question Section

    private var customQuestionSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Ou pose ta propre question")
                .font(.ecLabel)
                .foregroundColor(themeManager.textPrimary)

            HStack(spacing: ECSpacing.sm) {
                TextField("Ex: Est-ce que je peux faire cette séance en soirée ?", text: $customQuestion, axis: .vertical)
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
                .buttonStyle(.premium)
                .disabled(customQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: - Actions

    private func sendAnalysisRequest(_ analysisType: String) {
        let message = generateMessage(question: analysisType)
        navigateToChat(with: message)
    }

    private func sendCustomQuestion() {
        let question = customQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }

        let message = generateMessage(question: question)
        navigateToChat(with: message)
    }

    private func generateMessage(question: String) -> String {
        var message = "Pour ma séance planifiée de \(session.discipline.displayName) \"\(session.displayTitle)\" prévue le \(formattedDate)"

        message += " (\(session.formattedDuration)"
        if let distance = session.formattedDistance {
            message += ", \(distance)"
        }
        if let intensity = session.intensity {
            message += ", zone \(intensity)"
        }
        message += ")"

        message += ", \(question)"

        return message
    }

    private func navigateToChat(with message: String) {
        // Définir le message pré-rempli
        appState.prefilledChatMessage = message

        // Fermer la sheet
        dismiss()

        // Appeler le callback pour fermer la vue et changer d'onglet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onNavigateToChat?()
            appState.selectedTab = .coach
        }
    }
}

// MARK: - Planned Analysis Option

struct PlannedAnalysisOption: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Planned Analysis Option Card

struct PlannedAnalysisOptionCard: View {
    @EnvironmentObject var themeManager: ThemeManager

    let option: PlannedAnalysisOption
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
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.premium)
    }
}

// MARK: - Session Move Confirmation Sheet

struct SessionMoveConfirmationSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CalendarViewModel
    let userId: String

    private var sourceDateString: String {
        guard let date = viewModel.moveState.sourceDate else { return "-" }
        return formatDate(date)
    }

    private var targetDateString: String {
        guard let date = viewModel.moveState.targetDate else { return "-" }
        return formatDate(date)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: ECSpacing.lg) {
                // Header avec icône
                VStack(spacing: ECSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(themeManager.warningColor.opacity(0.15))
                            .frame(width: 64, height: 64)

                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(.system(size: 28))
                            .foregroundColor(themeManager.warningColor)
                    }

                    Text("Déplacer la séance ?")
                        .font(.ecH3)
                        .foregroundColor(themeManager.textPrimary)
                }
                .padding(.top, ECSpacing.lg)

                // Info session
                if let session = viewModel.moveState.sourceSession {
                    VStack(spacing: ECSpacing.sm) {
                        Text(session.displayTitle)
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)

                        HStack(spacing: ECSpacing.md) {
                            // Date source
                            VStack(spacing: 4) {
                                Text("De")
                                    .font(.ecCaption)
                                    .foregroundColor(themeManager.textSecondary)
                                Text(sourceDateString)
                                    .font(.ecBodyMedium)
                                    .foregroundColor(themeManager.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(ECSpacing.md)
                            .background(themeManager.cardColor)
                            .cornerRadius(ECRadius.md)

                            Image(systemName: "arrow.right")
                                .foregroundColor(themeManager.accentColor)

                            // Date cible
                            VStack(spacing: 4) {
                                Text("Vers")
                                    .font(.ecCaption)
                                    .foregroundColor(themeManager.textSecondary)
                                Text(targetDateString)
                                    .font(.ecBodyMedium)
                                    .foregroundColor(themeManager.successColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(ECSpacing.md)
                            .background(themeManager.successColor.opacity(0.1))
                            .cornerRadius(ECRadius.md)
                        }
                    }
                    .padding(.horizontal, ECSpacing.lg)
                }

                // Warnings (si présents après exécution)
                if !viewModel.lastMoveWarnings.isEmpty {
                    warningsSection
                }

                Spacer()

                // Boutons d'action
                VStack(spacing: ECSpacing.sm) {
                    // Bouton confirmer
                    Button {
                        Task {
                            await viewModel.executeSessionMove(userId: userId)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            if viewModel.moveState.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark")
                                Text("Confirmer le déplacement")
                            }
                        }
                        .font(.ecLabelBold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.accentColor)
                        .cornerRadius(ECRadius.lg)
                    }
                    .buttonStyle(.premium)
                    .disabled(viewModel.moveState.isLoading)

                    // Bouton annuler
                    Button {
                        viewModel.cancelSessionMove()
                        dismiss()
                    } label: {
                        Text("Annuler")
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.premium)
                    .disabled(viewModel.moveState.isLoading)
                }
                .padding(.horizontal, ECSpacing.lg)
                .padding(.bottom, ECSpacing.lg)
            }
            .background(themeManager.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        viewModel.cancelSessionMove()
                        dismiss()
                    }
                    .foregroundColor(themeManager.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var warningsSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Avertissements")
                .font(.ecLabel)
                .foregroundColor(themeManager.textPrimary)

            ForEach(viewModel.lastMoveWarnings) { warning in
                HStack(spacing: ECSpacing.sm) {
                    Image(systemName: warning.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(warningColor(for: warning.severityLevel))

                    Text(warning.message)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)

                    Spacer()
                }
                .padding(ECSpacing.sm)
                .background(warningColor(for: warning.severityLevel).opacity(0.1))
                .cornerRadius(ECRadius.sm)
            }
        }
        .padding(.horizontal, ECSpacing.lg)
    }

    private func warningColor(for severity: WarningSeverity) -> Color {
        switch severity {
        case .low: return themeManager.successColor
        case .medium: return themeManager.warningColor
        case .high: return themeManager.errorColor
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date).capitalized
    }
}

// MARK: - Session Move Result Toast

struct SessionMoveResultView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let warnings: [MoveWarning]
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: ECSpacing.md) {
            // Succès header
            HStack(spacing: ECSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.successColor)

                Text("Séance déplacée !")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(themeManager.textTertiary)
                }
                .buttonStyle(.premium)
            }

            // Afficher les warnings s'il y en a
            if !warnings.isEmpty {
                VStack(alignment: .leading, spacing: ECSpacing.xs) {
                    ForEach(warnings.prefix(2)) { warning in
                        HStack(spacing: ECSpacing.xs) {
                            Image(systemName: warning.iconName)
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.warningColor)

                            Text(warning.message)
                                .font(.ecCaption)
                                .foregroundColor(themeManager.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .shadow(color: themeManager.cardShadow, radius: 8, x: 0, y: 4)
        .padding(.horizontal, ECSpacing.lg)
    }
}

// MARK: - Week History View (Mode Réalisé)

struct WeekHistoryView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: CalendarViewModel
    let onActivityTap: (Activity) -> Void
    let onPlannedSessionTap: (PlannedSession) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Grille des jours (pas de header car géré par CalendarScaleHeader)
            WeekHistoryDaysGrid(
                viewModel: viewModel,
                onDateSelected: { date in
                    viewModel.selectDate(date)
                }
            )

            Divider()
                .background(themeManager.borderColor)
                .padding(.vertical, ECSpacing.sm)

            // Contenu du jour sélectionné
            WeekHistorySessionsList(
                viewModel: viewModel,
                onActivityTap: onActivityTap,
                onPlannedSessionTap: onPlannedSessionTap
            )
        }
    }
}

// MARK: - Week History Days Grid

struct WeekHistoryDaysGrid: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: CalendarViewModel
    let onDateSelected: (Date) -> Void

    private let weekDays = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]

    var body: some View {
        VStack(spacing: ECSpacing.xs) {
            // Noms des jours
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, ECSpacing.sm)

            // Cellules des jours
            HStack(spacing: ECSpacing.xs) {
                ForEach(viewModel.daysInCurrentWeek, id: \.self) { date in
                    WeekHistoryDayCell(
                        date: date,
                        isSelected: viewModel.isSelected(date),
                        isToday: viewModel.isToday(date),
                        activities: viewModel.activitiesForDate(date),
                        plannedSessions: viewModel.plannedSessionsForDate(date),
                        onTap: {
                            onDateSelected(date)
                        }
                    )
                }
            }
            .padding(.horizontal, ECSpacing.sm)
        }
    }
}

// MARK: - Week History Day Cell

struct WeekHistoryDayCell: View {
    @EnvironmentObject var themeManager: ThemeManager
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let activities: [Activity]
    let plannedSessions: [PlannedSession]
    let onTap: () -> Void

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var hasData: Bool {
        !activities.isEmpty || !plannedSessions.isEmpty
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Numéro du jour
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(themeManager.accentColor)
                            .frame(width: 32, height: 32)
                    } else if isToday {
                        Circle()
                            .stroke(themeManager.accentColor, lineWidth: 2)
                            .frame(width: 32, height: 32)
                    }

                    Text(dayNumber)
                        .font(.ecBodyMedium)
                        .foregroundColor(
                            isSelected ? .white :
                            (isToday ? themeManager.accentColor : themeManager.textPrimary)
                        )
                }

                // Indicateurs de données (icônes sport comme en mode Planifié)
                if hasData {
                    HStack(spacing: 2) {
                        // Icônes des activités réalisées
                        if !activities.isEmpty {
                            ForEach(activities.prefix(3)) { activity in
                                DisciplineIconView(discipline: activity.discipline, size: 10, useCustomImage: true)
                            }
                            if activities.count > 3 {
                                Text("+\(activities.count - 3)")
                                    .font(.system(size: 8))
                                    .foregroundColor(themeManager.textTertiary)
                            }
                        }

                        // Icônes des séances planifiées (si pas d'activités)
                        if !plannedSessions.isEmpty && activities.isEmpty {
                            ForEach(plannedSessions.prefix(3)) { session in
                                DisciplineIconView(discipline: session.discipline, size: 10, useCustomImage: true)
                                    .opacity(0.5)
                            }
                            if plannedSessions.count > 3 {
                                Text("+\(plannedSessions.count - 3)")
                                    .font(.system(size: 8))
                                    .foregroundColor(themeManager.textTertiary)
                            }
                        }
                    }
                    .frame(height: 14)
                } else {
                    Spacer()
                        .frame(height: 14)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: ECRadius.sm)
                    .fill(cellBackgroundColor)
            )
        }
        .buttonStyle(.premium)
    }

    private var cellBackgroundColor: Color {
        if !activities.isEmpty {
            return themeManager.successColor.opacity(0.1)
        } else if !plannedSessions.isEmpty {
            return themeManager.accentColor.opacity(0.05)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Week History Sessions List

struct WeekHistorySessionsList: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: CalendarViewModel
    let onActivityTap: (Activity) -> Void
    let onPlannedSessionTap: (PlannedSession) -> Void

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: viewModel.selectedDate).capitalized
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ECSpacing.md) {
                // Date sélectionnée
                Text(dateString)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                    .padding(.horizontal, ECSpacing.md)

                let activities = viewModel.activitiesForDate(viewModel.selectedDate)
                let sessions = viewModel.plannedSessionsForDate(viewModel.selectedDate)

                if activities.isEmpty && sessions.isEmpty {
                    // Aucune donnée
                    VStack(spacing: ECSpacing.sm) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(themeManager.textTertiary)

                        Text("Aucune activité ce jour")
                            .font(.ecBody)
                            .foregroundColor(themeManager.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ECSpacing.xl)
                } else {
                    // Activités réalisées
                    if !activities.isEmpty {
                        VStack(alignment: .leading, spacing: ECSpacing.sm) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(themeManager.successColor)
                                Text("Réalisé")
                                    .font(.ecCaption)
                                    .foregroundColor(themeManager.textSecondary)
                            }
                            .padding(.horizontal, ECSpacing.md)

                            ForEach(activities) { activity in
                                Button {
                                    onActivityTap(activity)
                                } label: {
                                    HistoryActivityCard(activity: activity)
                                }
                                .buttonStyle(.premium)
                            }
                        }
                    }

                    // Séances planifiées (non réalisées)
                    if !sessions.isEmpty {
                        VStack(alignment: .leading, spacing: ECSpacing.sm) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(themeManager.accentColor)
                                Text("Planifié")
                                    .font(.ecCaption)
                                    .foregroundColor(themeManager.textSecondary)
                            }
                            .padding(.horizontal, ECSpacing.md)

                            ForEach(sessions) { session in
                                Button {
                                    onPlannedSessionTap(session)
                                } label: {
                                    HistoryPlannedSessionCard(session: session)
                                }
                                .buttonStyle(.premium)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, ECSpacing.sm)
        }
    }
}

// MARK: - History Activity Card

struct HistoryActivityCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let activity: Activity

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Indicateur vert (réalisé)
            Rectangle()
                .fill(themeManager.successColor)
                .frame(width: 4)
                .cornerRadius(2)

            // Icône sport
            ZStack {
                Circle()
                    .fill(themeManager.sportColor(for: activity.discipline).opacity(0.15))
                    .frame(width: 40, height: 40)

                DisciplineIconView(discipline: activity.discipline, size: 16, useCustomImage: true)
            }

            // Infos
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.displayTitle)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                    .lineLimit(1)

                HStack(spacing: ECSpacing.sm) {
                    if let duration = activity.formattedDuration {
                        Label(duration, systemImage: "clock")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    if let distance = activity.formattedDistance {
                        Label(distance, systemImage: "arrow.left.and.right")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }
            }

            Spacer()

            // TSS
            if let tss = activity.tss {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(tss)")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                    Text("TSS")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.ecCaption)
                .foregroundColor(themeManager.textTertiary)
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.md)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
        .padding(.horizontal, ECSpacing.md)
    }
}

// MARK: - History Planned Session Card

struct HistoryPlannedSessionCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let session: PlannedSession

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Indicateur bleu (planifié)
            Rectangle()
                .fill(themeManager.accentColor.opacity(0.5))
                .frame(width: 4)
                .cornerRadius(2)

            // Icône sport
            ZStack {
                Circle()
                    .fill(themeManager.sportColor(for: session.discipline).opacity(0.15))
                    .frame(width: 40, height: 40)

                DisciplineIconView(discipline: session.discipline, size: 16, useCustomImage: true)
            }

            // Infos
            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayTitle)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                    .lineLimit(1)

                HStack(spacing: ECSpacing.sm) {
                    if let duration = session.estimatedDuration {
                        Label(duration, systemImage: "clock")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    if let distance = session.estimatedDistance {
                        Label(distance, systemImage: "arrow.left.and.right")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.ecCaption)
                .foregroundColor(themeManager.textTertiary)
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.md)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
        .padding(.horizontal, ECSpacing.md)
    }
}

// MARK: - Preview

#Preview {
    WeekPlanView(
        viewModel: CalendarViewModel(),
        onSessionTap: { _ in }
    )
    .environmentObject(ThemeManager.shared)
    .environmentObject(AppState())
}
