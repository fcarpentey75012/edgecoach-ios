/**
 * Vue Calendrier - Planning des entraînements
 * Utilise ThemeManager pour les couleurs dynamiques
 */

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = CalendarViewModel()

    // Navigation states
    @State private var selectedActivity: Activity?
    @State private var selectedPlannedSession: PlannedSession?
    @State private var selectedCycleSession: CycleSession?

    // Debounce pour les changements de mois
    @State private var monthChangeTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View Mode Picker (Mois / Semaine)
                Picker("Mode", selection: $viewModel.viewMode) {
                    ForEach(CalendarViewModel.CalendarViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, ECSpacing.md)
                .padding(.vertical, ECSpacing.sm)

                if viewModel.viewMode == .week {
                    // Vue Planifié (WeekPlanView)
                    weekView
                } else {
                    // Vue Réalisé (WeekActivitiesView)
                    activitiesView
                }
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Calendrier")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedActivity) { activity in
                NavigationStack {
                    SessionDetailView(activity: activity)
                        .environmentObject(themeManager)
                }
            }
            .sheet(item: $selectedPlannedSession) { session in
                PlannedSessionDetailView(session: session)
                    .environmentObject(themeManager)
            }
            .sheet(item: $selectedCycleSession) { session in
                CycleSessionDetailView(session: session)
                    .environmentObject(themeManager)
            }
        }
        .task {
            // Chargement initial non-bloquant
            if let userId = authViewModel.user?.id {
                await viewModel.loadData(userId: userId)
                // Charger aussi le cycle pour la vue semaine
                await viewModel.loadCyclePlan(userId: userId)
            }
        }
        .onChange(of: viewModel.currentDate) { newValue in
            // Debounce: annule la tâche précédente si l'utilisateur swipe rapidement
            monthChangeTask?.cancel()
            monthChangeTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                if let userId = authViewModel.user?.id {
                    await viewModel.loadData(userId: userId)
                }
            }
        }
        .onChange(of: viewModel.viewMode) { newMode in
            // Recharger le cycle quand on passe en mode semaine
            if newMode == .week, viewModel.cyclePlan == nil {
                Task {
                    if let userId = authViewModel.user?.id {
                        await viewModel.loadCyclePlan(userId: userId)
                    }
                }
            }
        }
    }

    // MARK: - Week View (Planifié)

    @ViewBuilder
    private var weekView: some View {
        if viewModel.cyclePlan != nil {
            WeekPlanView(
                viewModel: viewModel,
                onSessionTap: { session in
                    selectedCycleSession = session
                }
            )
        } else if viewModel.isLoading {
            VStack(spacing: ECSpacing.md) {
                ProgressView()
                Text("Chargement du cycle...")
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Pas de cycle disponible
            VStack(spacing: ECSpacing.lg) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 60))
                    .foregroundColor(themeManager.textTertiary)

                Text("Aucun cycle actif")
                    .font(.ecH4)
                    .foregroundColor(themeManager.textPrimary)

                Text("Crée un plan d'entraînement pour voir tes semaines planifiées")
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ECSpacing.xl)

                Button {
                    // TODO: Navigation vers création de plan
                } label: {
                    Text("Créer un plan")
                        .font(.ecLabelBold)
                        .foregroundColor(.white)
                        .padding(.horizontal, ECSpacing.xl)
                        .padding(.vertical, ECSpacing.md)
                        .background(themeManager.accentColor)
                        .cornerRadius(ECRadius.lg)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Activities View (Réalisé)

    @ViewBuilder
    private var activitiesView: some View {
        WeekActivitiesView(
            viewModel: viewModel,
            onActivityTap: { activity in
                selectedActivity = activity
            }
        )
    }
}

// MARK: - Calendar Header

struct CalendarHeader: View {
    @EnvironmentObject var themeManager: ThemeManager
    let currentMonth: Date
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void
    let onToday: () -> Void

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: currentMonth).capitalized
    }

    var body: some View {
        HStack {
            Button(action: onPreviousMonth) {
                Image(systemName: "chevron.left")
                    .font(.ecBody)
                    .foregroundColor(themeManager.accentColor)
            }

            Spacer()

            Button(action: onToday) {
                Text(monthYearString)
                    .font(.ecH4)
                    .foregroundColor(themeManager.textPrimary)
            }

            Spacer()

            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.ecBody)
                    .foregroundColor(themeManager.accentColor)
            }
        }
        .padding(.horizontal, ECSpacing.lg)
        .padding(.vertical, ECSpacing.md)
    }
}

// MARK: - Week Days Header

struct WeekDaysHeader: View {
    @EnvironmentObject var themeManager: ThemeManager
    private let weekDays = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                Text(day)
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, ECSpacing.sm)
        .padding(.bottom, ECSpacing.xs)
    }
}

// MARK: - Calendar Grid

struct CalendarGrid: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: CalendarViewModel
    let onDateSelected: (Date) -> Void

    var body: some View {
        let days = viewModel.daysInMonth
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        LazyVGrid(columns: columns, spacing: ECSpacing.xs) {
            ForEach(days, id: \.self) { date in
                CalendarDayCell(
                    date: date,
                    isCurrentMonth: viewModel.isCurrentMonth(date),
                    isSelected: viewModel.isSelected(date),
                    isToday: viewModel.isToday(date),
                    hasActivity: viewModel.hasActivity(on: date),
                    hasPlannedSession: viewModel.hasPlannedSession(on: date),
                    onTap: { onDateSelected(date) }
                )
            }
        }
        .padding(.horizontal, ECSpacing.sm)
    }
}

struct CalendarDayCell: View {
    @EnvironmentObject var themeManager: ThemeManager
    let date: Date
    let isCurrentMonth: Bool
    let isSelected: Bool
    let isToday: Bool
    let hasActivity: Bool
    let hasPlannedSession: Bool
    let onTap: () -> Void

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Fond coloré pour activité/séance planifiée
                if hasActivity && hasPlannedSession {
                    // Dégradé si les deux
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeManager.successColor.opacity(0.2),
                                    themeManager.accentColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                } else if hasActivity {
                    Circle()
                        .fill(themeManager.successColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                } else if hasPlannedSession {
                    Circle()
                        .fill(themeManager.accentColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                }

                // Cercle de sélection ou aujourd'hui
                if isSelected {
                    Circle()
                        .fill(themeManager.accentColor)
                        .frame(width: 36, height: 36)
                } else if isToday {
                    Circle()
                        .stroke(themeManager.accentColor, lineWidth: 2)
                        .frame(width: 36, height: 36)
                }

                Text(dayNumber)
                    .font(.ecBody)
                    .foregroundColor(textColor)
            }
        }
        .frame(height: 50)
        .opacity(isCurrentMonth ? 1 : 0.3)
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return themeManager.accentColor
        } else if !isCurrentMonth {
            return themeManager.textTertiary
        } else {
            return themeManager.textPrimary
        }
    }
}

// MARK: - Selected Date Content

struct SelectedDateContent: View {
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
                Text(dateString)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                    .padding(.horizontal, ECSpacing.md)

                let activities = viewModel.activitiesForSelectedDate
                let sessions = viewModel.plannedSessionsForSelectedDate

                if activities.isEmpty && sessions.isEmpty {
                    EmptyDayView()
                } else {
                    // Planned Sessions
                    if !sessions.isEmpty {
                        VStack(alignment: .leading, spacing: ECSpacing.sm) {
                            Text("Séances planifiées")
                                .font(.ecCaption)
                                .foregroundColor(themeManager.textSecondary)
                                .padding(.horizontal, ECSpacing.md)

                            ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                                Button {
                                    onPlannedSessionTap(session)
                                } label: {
                                    CalendarSessionCard(session: session)
                                }
                                .buttonStyle(.premium)
                                .staggeredAnimation(index: index, totalCount: sessions.count)
                            }
                        }
                    }

                    // Activities
                    if !activities.isEmpty {
                        VStack(alignment: .leading, spacing: ECSpacing.sm) {
                            Text("Activités réalisées")
                                .font(.ecCaption)
                                .foregroundColor(themeManager.textSecondary)
                                .padding(.horizontal, ECSpacing.md)

                            ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                                Button {
                                    onActivityTap(activity)
                                } label: {
                                    CalendarActivityCard(activity: activity)
                                }
                                .buttonStyle(.premium)
                                .staggeredAnimation(index: index, totalCount: activities.count)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, ECSpacing.sm)
        }
    }
}

struct EmptyDayView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
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
    }
}

struct CalendarSessionCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let session: PlannedSession

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Barre colorée sport
            Rectangle()
                .fill(themeManager.sportColor(for: session.discipline))
                .frame(width: 4)
                .cornerRadius(2)

            // Icône sport dans un cercle
            ZStack {
                Circle()
                    .fill(themeManager.sportColor(for: session.discipline).opacity(0.15))
                    .frame(width: 40, height: 40)

                DisciplineIconView(discipline: session.discipline, size: 16)
            }

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

                    // Zone/Intensité (si disponible)
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

struct CalendarActivityCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let activity: Activity

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Barre colorée sport (alignée avec CalendarSessionCard)
            Rectangle()
                .fill(themeManager.sportColor(for: activity.discipline))
                .frame(width: 4)
                .cornerRadius(2)

            // Icône sport dans un cercle
            ZStack {
                Circle()
                    .fill(themeManager.sportColor(for: activity.discipline).opacity(0.15))
                    .frame(width: 40, height: 40)

                DisciplineIconView(discipline: activity.discipline, size: 16)
            }

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

                    // TSS affiché comme badge (aligné avec le badge intensité de CalendarSessionCard)
                    if let tss = activity.tss {
                        Text("\(tss) TSS")
                            .font(.ecSmall)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(tssColor(tss))
                            .cornerRadius(4)
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

    private func tssColor(_ tss: Int) -> Color {
        switch tss {
        case 0..<50: return .blue.opacity(0.7)
        case 50..<100: return .green
        case 100..<150: return .yellow.opacity(0.8)
        case 150..<200: return .orange
        default: return .red
        }
    }
}

// MARK: - Planned Session Detail View

struct PlannedSessionDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let session: PlannedSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    // Header
                    VStack(spacing: ECSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(themeManager.sportColor(for: session.discipline).opacity(0.15))
                                .frame(width: 80, height: 80)

                            Image(systemName: session.discipline.icon)
                                .font(.system(size: 36))
                                .foregroundColor(themeManager.sportColor(for: session.discipline))
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
                    }
                    .padding(.top, ECSpacing.lg)

                    // Stats
                    HStack(spacing: 0) {
                        if let duration = session.estimatedDuration {
                            PlannedSessionStatItem(icon: "clock", value: duration, label: "Durée")
                        }

                        if let distance = session.estimatedDistance {
                            PlannedSessionStatItem(icon: "arrow.left.and.right", value: distance, label: "Distance")
                        }

                        if let intensity = session.intensity {
                            PlannedSessionStatItem(icon: "flame", value: intensity, label: "Type")
                        }
                    }
                    .padding(ECSpacing.md)
                    .background(themeManager.cardColor)
                    .cornerRadius(ECRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: ECRadius.lg)
                            .stroke(themeManager.borderColor, lineWidth: 1)
                    )
                    .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)

                    // Zone & Intensity
                    if session.targetPace != nil || session.zone != nil {
                        VStack(alignment: .leading, spacing: ECSpacing.md) {
                            HStack {
                                Image(systemName: "gauge.with.needle")
                                    .foregroundColor(themeManager.accentColor)
                                Text("Intensité")
                                    .font(.ecLabelBold)
                                    .foregroundColor(themeManager.textPrimary)
                                Spacer()
                            }

                            HStack(spacing: ECSpacing.lg) {
                                if let zone = session.zone {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Zone")
                                            .font(.ecSmall)
                                            .foregroundColor(themeManager.textSecondary)
                                        Text(zone)
                                            .font(.ecBodyMedium)
                                            .foregroundColor(themeManager.textPrimary)
                                    }
                                }

                                if let pace = session.targetPace {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Cible")
                                            .font(.ecSmall)
                                            .foregroundColor(themeManager.textSecondary)
                                        Text(pace)
                                            .font(.ecBodyMedium)
                                            .foregroundColor(themeManager.textPrimary)
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
                        .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
                    }

                    // Description
                    if let description = session.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: ECSpacing.sm) {
                            HStack {
                                Image(systemName: "text.alignleft")
                                    .foregroundColor(themeManager.warningColor)
                                Text("Description")
                                    .font(.ecLabelBold)
                                    .foregroundColor(themeManager.textPrimary)
                                Spacer()
                            }

                            Text(description)
                                .font(.ecBody)
                                .foregroundColor(themeManager.textSecondary)
                        }
                        .padding(ECSpacing.md)
                        .background(themeManager.cardColor)
                        .cornerRadius(ECRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: ECRadius.lg)
                                .stroke(themeManager.borderColor, lineWidth: 1)
                        )
                        .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
                    }

                    // Focus
                    if let focus = session.focus, !focus.isEmpty {
                        VStack(alignment: .leading, spacing: ECSpacing.sm) {
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(themeManager.successColor)
                                Text("Focus")
                                    .font(.ecLabelBold)
                                    .foregroundColor(themeManager.textPrimary)
                                Spacer()
                            }

                            Text(focus)
                                .font(.ecBody)
                                .foregroundColor(themeManager.textSecondary)
                        }
                        .padding(ECSpacing.md)
                        .background(themeManager.cardColor)
                        .cornerRadius(ECRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: ECRadius.lg)
                                .stroke(themeManager.borderColor, lineWidth: 1)
                        )
                        .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
                    }

                    // Educatifs
                    if !session.educatifs.isEmpty {
                        VStack(alignment: .leading, spacing: ECSpacing.sm) {
                            HStack {
                                Image(systemName: "lightbulb")
                                    .foregroundColor(themeManager.infoColor)
                                Text("Éducatifs")
                                    .font(.ecLabelBold)
                                    .foregroundColor(themeManager.textPrimary)
                                Spacer()
                            }

                            ForEach(session.educatifs, id: \.self) { educatif in
                                HStack(alignment: .top, spacing: ECSpacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(themeManager.successColor)
                                    Text(educatif)
                                        .font(.ecBody)
                                        .foregroundColor(themeManager.textSecondary)
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
                        .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
                    }

                    Spacer(minLength: ECSpacing.xl)
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Séance planifiée")
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date).capitalized
    }
}

struct PlannedSessionStatItem: View {
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

#Preview {
    CalendarView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager.shared)
        .environmentObject(AppState())
}
