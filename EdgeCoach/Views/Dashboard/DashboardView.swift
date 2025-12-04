/**
 * Vue Dashboard - Écran d'accueil
 * Utilise ThemeManager pour les couleurs dynamiques
 */

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = DashboardViewModel()

    // Navigation states
    @State private var selectedDiscipline: Discipline?
    @State private var showingPlanCreator = false
    @State private var selectedPlannedSession: PlannedSession?
    @State private var navigateToPerformance = false

    // Widget config sheet states
    @State private var showingKPIConfig = false
    @State private var showingPerformanceConfig = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.md) {
                    // Afficher les widgets dans l'ordre configuré
                    ForEach(viewModel.enabledWidgetTypes(), id: \.self) { widgetType in
                        widgetView(for: widgetType)
                    }
                }
                .padding(.vertical)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Dashboard")
            .toolbar {
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
            // Sheets de navigation
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
                        Task {
                            if let userId = authViewModel.user?.id {
                                await viewModel.refresh(userId: userId)
                            }
                        }
                    }
            }
            .sheet(item: $selectedPlannedSession) { session in
                PlannedSessionDetailSheet(session: session)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $navigateToPerformance) {
                PerformanceView()
                    .environmentObject(authViewModel)
                    .environmentObject(themeManager)
            }
            // Sheets de configuration des widgets
            .sheet(isPresented: $showingKPIConfig) {
                KPISummaryConfigSheet(config: $viewModel.widgetPreferences.kpiConfig)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingPerformanceConfig) {
                PerformanceWidgetConfigSheet(config: $viewModel.widgetPreferences.performanceConfig)
                    .environmentObject(themeManager)
            }
        }
        .task {
            if let userId = authViewModel.user?.id {
                await viewModel.loadData(userId: userId)
            }
        }
    }

    // MARK: - Widget View Builder

    @ViewBuilder
    private func widgetView(for type: DashboardWidgetType) -> some View {
        switch type {
        case .kpiSummary:
            KPISummaryCard(
                timeScope: $viewModel.widgetPreferences.kpiConfig.timeScope,
                selectedMetrics: $viewModel.widgetPreferences.kpiConfig.selectedMetrics,
                summary: viewModel.summary
            )
            .padding(.horizontal)
            .onLongPressGesture {
                showingKPIConfig = true
            }

        case .performance:
            PerformanceCardsSection(
                viewModel: viewModel,
                config: viewModel.widgetPreferences.performanceConfig,
                onNavigateToPerformance: { navigateToPerformance = true }
            )
            .padding(.horizontal)
            .onLongPressGesture {
                showingPerformanceConfig = true
            }

        case .weekProgress:
            if let progress = viewModel.weekProgress, progress.targetDuration > 0 {
                WeekProgressCard(progress: progress)
                    .padding(.horizontal)
            }

        case .sportsBreakdown:
            if viewModel.hasAnySport, let byDiscipline = viewModel.byDiscipline {
                SportsBreakdownSection(
                    byDiscipline: byDiscipline,
                    viewModel: viewModel,
                    weekStart: viewModel.weekStartDate,
                    selectedDiscipline: $selectedDiscipline
                )
                .padding(.horizontal)
            }

        case .plannedSessions:
            PlannedSessionsSection(
                sessions: viewModel.plannedSessions,
                hasPlan: viewModel.hasPlan,
                onCreatePlan: { showingPlanCreator = true },
                onSessionTap: { session in
                    selectedPlannedSession = session
                }
            )
            .padding(.horizontal)

        case .upcomingSessions:
            if !viewModel.upcomingSessions.isEmpty {
                UpcomingSessionsSection(sessions: viewModel.upcomingSessions)
                    .padding(.horizontal)
            }

        case .recentActivities:
            if !viewModel.recentActivities.isEmpty {
                RecentActivitiesSection(activities: viewModel.recentActivities)
                    .padding(.horizontal)
            }
        }
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
