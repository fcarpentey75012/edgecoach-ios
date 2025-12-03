/**
 * Vue Dashboard - Écran d'accueil
 * Utilise ThemeManager pour les couleurs dynamiques
 */

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedDiscipline: Discipline?
    @State private var showingPlanCreator = false
    @State private var showingSettings = false
    @State private var selectedPlannedSession: PlannedSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.md) {
                    // Time Scope Picker (Granularité)
                    Picker("Période", selection: $viewModel.preferences.timeScope) {
                        ForEach(DashboardTimeScope.allCases) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Dynamic KPIs Grid
                    if let summary = viewModel.summary {
                        KpiGrid(
                            metrics: viewModel.preferences.selectedMetrics,
                            summary: summary,
                            themeManager: themeManager
                        )
                        .padding(.horizontal)
                    }
                    
                    // Training Load Card (TODO: Implement TrainingLoadCard and TrainingLoad model)
                    // if let trainingLoad = viewModel.trainingLoad {
                    //     TrainingLoadCard(load: trainingLoad)
                    // }

                    // Week Progress
                    if let progress = viewModel.weekProgress, progress.targetDuration > 0 {
                        WeekProgressCard(progress: progress)
                            .padding(.horizontal)
                    }

                    // Sports Breakdown
                    if viewModel.hasAnySport, let byDiscipline = viewModel.byDiscipline {
                        SportsBreakdownSection(
                            byDiscipline: byDiscipline,
                            viewModel: viewModel,
                            weekStart: viewModel.weekStartDate,
                            selectedDiscipline: $selectedDiscipline
                        )
                        .padding(.horizontal)
                    }

                    // Planned Sessions (from plan)
                    PlannedSessionsSection(
                        sessions: viewModel.plannedSessions,
                        hasPlan: viewModel.hasPlan,
                        onCreatePlan: { showingPlanCreator = true },
                        onSessionTap: { session in
                            selectedPlannedSession = session
                        }
                    )
                    .padding(.horizontal)

                    // Upcoming Sessions (from API)
                    if !viewModel.upcomingSessions.isEmpty {
                        UpcomingSessionsSection(sessions: viewModel.upcomingSessions)
                            .padding(.horizontal)
                    }

                    // Recent Activities
                    if !viewModel.recentActivities.isEmpty {
                        RecentActivitiesSection(activities: viewModel.recentActivities)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.body)
                            .foregroundColor(themeManager.textPrimary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingPlanCreator = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            .refreshable {
                if let userId = authViewModel.user?.id {
                    await viewModel.refresh(userId: userId)
                }
            }
            .overlay {
                if viewModel.isLoading && viewModel.weeklySummaryData == nil {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .sheet(item: $selectedDiscipline) { discipline in
                DisciplineSessionsView(
                    discipline: discipline,
                    weekStart: viewModel.weekStartDate ?? Date()
                )
                .environmentObject(authViewModel)
                .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingPlanCreator) {
                TrainingPlanCreatorView()
                    .environmentObject(authViewModel)
                    .environmentObject(themeManager)
                    .onDisappear {
                        // Refresh data after creating a plan
                        Task {
                            if let userId = authViewModel.user?.id {
                                await viewModel.refresh(userId: userId)
                            }
                        }
                    }
            }
            .sheet(isPresented: $showingSettings) {
                DashboardSettingsView(preferences: $viewModel.preferences)
                    .environmentObject(themeManager)
            }
            .sheet(item: $selectedPlannedSession) { session in
                PlannedSessionDetailSheet(session: session)
                    .environmentObject(themeManager)
            }
        }
        .task {
            if let userId = authViewModel.user?.id {
                await viewModel.loadData(userId: userId)
            }
        }
    }
}

// MARK: - KPI Grid

struct KpiGrid: View {
    let metrics: [DashboardMetric]
    let summary: WeeklySummary
    let themeManager: ThemeManager
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: ECSpacing.sm) {
            ForEach(metrics) { metric in
                KpiCard(metric: metric, value: value(for: metric), themeManager: themeManager)
            }
        }
    }
    
    private func value(for metric: DashboardMetric) -> String {
        switch metric {
        case .volume:
            return summary.formattedDuration
        case .distance:
            return summary.formattedDistance
        case .sessions:
            return "\(summary.sessionsCount)"
        case .elevation:
            return "\(summary.totalElevation) m"
        case .calories:
            return "\(summary.totalCalories)"
        }
    }
}

struct KpiCard: View {
    let metric: DashboardMetric
    let value: String
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: metric.icon)
                    .foregroundColor(themeManager.accentColor)
                Spacer()
                Text(metric.unit)
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textTertiary)
            }
            
            Text(value)
                .font(.ecH3)
                .foregroundColor(themeManager.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(metric.rawValue)
                .font(.ecCaption)
                .foregroundColor(themeManager.textSecondary)
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: themeManager.cardBorderWidth)
        )
        .shadow(color: themeManager.cardShadow, radius: themeManager.cardShadowRadius, x: 0, y: 2)
    }
}


// MARK: - Week Progress Card

struct WeekProgressCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let progress: WeekProgress

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(themeManager.successColor)
                Text("Progression de la semaine")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
                Text("\(Int(progress.percentage))%")
                    .font(.ecH4)
                    .foregroundColor(themeManager.successColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.elevatedColor)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.successColor)
                        .frame(width: geometry.size.width * min(1, progress.percentage / 100), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(DashboardService.shared.formatDuration(progress.achievedDuration))")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
                Spacer()
                Text("Objectif: \(DashboardService.shared.formatDuration(progress.targetDuration))")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textTertiary)
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: themeManager.cardBorderWidth)
        )
        .shadow(color: themeManager.cardShadow, radius: themeManager.cardShadowRadius, x: 0, y: 2)
    }
}

// MARK: - Sports Breakdown Section

struct SportsBreakdownSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let byDiscipline: ByDiscipline
    @ObservedObject var viewModel: DashboardViewModel
    let weekStart: Date?
    @Binding var selectedDiscipline: Discipline?

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Par sport")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)
                .padding(.horizontal, ECSpacing.sm)

            VStack(spacing: ECSpacing.sm) {
                if viewModel.hasCyclisme {
                    SportCard(discipline: .cyclisme, stats: byDiscipline.cyclisme) {
                        selectedDiscipline = .cyclisme
                    }
                }

                if viewModel.hasCourse {
                    SportCard(discipline: .course, stats: byDiscipline.course) {
                        selectedDiscipline = .course
                    }
                }

                if viewModel.hasNatation {
                    SportCard(discipline: .natation, stats: byDiscipline.natation) {
                        selectedDiscipline = .natation
                    }
                }

                if viewModel.hasAutre {
                    SportCard(discipline: .autre, stats: byDiscipline.autre) {
                        selectedDiscipline = .autre
                    }
                }
            }
        }
    }
}

struct SportCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let discipline: Discipline
    let stats: DisciplineStat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ECSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(themeManager.sportColorLight(for: discipline))
                        .frame(width: 44, height: 44)

                    Image(systemName: discipline.icon)
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.sportColor(for: discipline))
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(discipline.displayName)
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)

                    Text("\(stats.count) séance\(stats.count > 1 ? "s" : "")")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }

                Spacer()

                // Duration + Chevron
                HStack(spacing: ECSpacing.sm) {
                    Text(stats.formattedDuration)
                        .font(.ecBodyMedium)
                        .foregroundColor(themeManager.textPrimary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.textTertiary)
                }
            }
            .padding(ECSpacing.md)
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: themeManager.cardBorderWidth)
            )
            .shadow(color: themeManager.cardShadow, radius: themeManager.cardShadowRadius, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Upcoming Sessions Section

struct UpcomingSessionsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let sessions: [UpcomingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Prochaines séances")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)
                .padding(.horizontal, ECSpacing.sm)

            ForEach(sessions) { session in
                UpcomingSessionCard(session: session)
            }
        }
    }
}

struct UpcomingSessionCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let session: UpcomingSession

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Date
            VStack(spacing: 2) {
                Text(dayOfWeek)
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
                Text(dayNumber)
                    .font(.ecH4)
                    .foregroundColor(themeManager.textPrimary)
            }
            .frame(width: 44)

            // Discipline indicator
            Rectangle()
                .fill(themeManager.sportColor(for: session.discipline))
                .frame(width: 4)
                .cornerRadius(2)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                    .lineLimit(1)

                HStack(spacing: ECSpacing.sm) {
                    Label(session.formattedDuration, systemImage: "clock")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)

                    if let distance = session.formattedDistance {
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
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: themeManager.cardBorderWidth)
        )
        .shadow(color: themeManager.cardShadow, radius: themeManager.cardShadowRadius, x: 0, y: 2)
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: session.parsedDate).uppercased()
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: session.parsedDate)
    }
}

// MARK: - Planned Sessions Section

struct PlannedSessionsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let sessions: [PlannedSession]
    let hasPlan: Bool
    let onCreatePlan: () -> Void
    let onSessionTap: (PlannedSession) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            HStack {
                Text("Séances prévues")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
                if !hasPlan {
                    Button(action: onCreatePlan) {
                        Text("Créer un plan")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            .padding(.horizontal, ECSpacing.sm)

            if sessions.isEmpty {
                VStack(spacing: ECSpacing.sm) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 30))
                        .foregroundColor(themeManager.textTertiary)
                    Text(hasPlan ? "Aucune séance prévue cette semaine" : "Créez un plan d'entraînement")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ECSpacing.lg)
                .background(themeManager.cardColor)
                .cornerRadius(ECRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: ECRadius.lg)
                        .stroke(themeManager.borderColor, lineWidth: themeManager.cardBorderWidth)
                )
            } else {
                ForEach(sessions) { session in
                    Button {
                        onSessionTap(session)
                    } label: {
                        PlannedSessionRow(session: session)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct PlannedSessionRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let session: PlannedSession

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Discipline indicator
            Rectangle()
                .fill(themeManager.sportColor(for: session.discipline))
                .frame(width: 4)
                .cornerRadius(2)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                    .lineLimit(1)

                HStack(spacing: ECSpacing.sm) {
                    if let duration = session.formattedDuration {
                        Label(duration, systemImage: "clock")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }
            }

            Spacer()

            // Badge "Prévu"
            Text("Prévu")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(themeManager.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(themeManager.accentColorLight)
                .cornerRadius(ECRadius.sm)

            Image(systemName: "chevron.right")
                .font(.ecCaption)
                .foregroundColor(themeManager.textTertiary)
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: themeManager.cardBorderWidth)
        )
        .shadow(color: themeManager.cardShadow, radius: themeManager.cardShadowRadius, x: 0, y: 2)
    }
}

struct PlannedSessionDetailSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    let session: PlannedSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ECSpacing.md) {
                    // Header
                    VStack(alignment: .leading, spacing: ECSpacing.sm) {
                        HStack {
                            Circle()
                                .fill(themeManager.sportColorLight(for: session.discipline))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: session.discipline.icon)
                                        .font(.title2)
                                        .foregroundColor(themeManager.sportColor(for: session.discipline))
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title)
                                    .font(.ecH4)
                                    .foregroundColor(themeManager.textPrimary)

                                Text(session.formattedDate ?? session.date)
                                    .font(.ecCaption)
                                    .foregroundColor(themeManager.textSecondary)
                            }
                        }
                    }
                    .padding(ECSpacing.md)
                    .background(themeManager.cardColor)
                    .cornerRadius(ECRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: ECRadius.lg)
                            .stroke(themeManager.borderColor, lineWidth: themeManager.cardBorderWidth)
                    )

                    // Stats
                    HStack(spacing: ECSpacing.md) {
                        if let duration = session.formattedDuration {
                            PlannedStatItem(icon: "clock", value: duration, label: "Durée")
                        }
                        if let distance = session.formattedDistance {
                            PlannedStatItem(icon: "arrow.left.and.right", value: distance, label: "Distance")
                        }
                    }
                    .padding(ECSpacing.md)
                    .background(themeManager.cardColor)
                    .cornerRadius(ECRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: ECRadius.lg)
                            .stroke(themeManager.borderColor, lineWidth: themeManager.cardBorderWidth)
                    )

                    // Description
                    if let description = session.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: ECSpacing.sm) {
                            Text("Description")
                                .font(.ecLabelBold)
                                .foregroundColor(themeManager.textPrimary)
                            Text(description)
                                .font(.ecBody)
                                .foregroundColor(themeManager.textSecondary)
                        }
                        .padding(ECSpacing.md)
                        .background(themeManager.cardColor)
                        .cornerRadius(ECRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: ECRadius.lg)
                                .stroke(themeManager.borderColor, lineWidth: themeManager.cardBorderWidth)
                        )
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Séance prévue")
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
}

struct PlannedStatItem: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.accentColor)
                Text(value)
                    .font(.ecBodyMedium)
                    .foregroundColor(themeManager.textPrimary)
            }
            Text(label)
                .font(.ecCaption)
                .foregroundColor(themeManager.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recent Activities Section

struct RecentActivitiesSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let activities: [Activity]

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Activités récentes")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)
                .padding(.horizontal, ECSpacing.sm)

            ForEach(activities) { activity in
                ActivityCard(activity: activity)
            }
        }
    }
}

struct ActivityCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let activity: Activity

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(themeManager.sportColorLight(for: activity.discipline))
                    .frame(width: 44, height: 44)

                Image(systemName: activity.discipline.icon)
                    .font(.system(size: 18))
                    .foregroundColor(themeManager.sportColor(for: activity.discipline))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.displayTitle)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                    .lineLimit(1)

                HStack(spacing: ECSpacing.sm) {
                    if let duration = activity.formattedDuration {
                        Text(duration)
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    if let distance = activity.formattedDistance {
                        Text(distance)
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }
            }

            Spacer()

            // TSS (utilise preferredTSSInt pour découplage Nolio)
            if let tss = activity.preferredTSSInt {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(tss)")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                    Text("TSS")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: themeManager.cardBorderWidth)
        )
        .shadow(color: themeManager.cardShadow, radius: themeManager.cardShadowRadius, x: 0, y: 2)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppState())
        .environmentObject(ThemeManager.shared)
}
