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
    @State private var selectedMacroPlan: MacroPlanData?
    @State private var navigateToPerformance = false

    // Widget config sheet states
    @State private var showingKPIConfig = false
    @State private var showingPMCDetail = false
    @State private var showingPerformanceConfig = false
    @State private var showingWeekProgressConfig = false
    @State private var showingSportsBreakdownConfig = false
    @State private var showingPlannedSessionsConfig = false
    @State private var showingUpcomingSessionsConfig = false
    @State private var showingRecentActivitiesConfig = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.md) {
                    if let error = viewModel.error {
                        VStack(spacing: 8) {
                            Text("Une erreur est survenue")
                                .font(.ecLabelBold)
                                .foregroundColor(.white)
                            Text(error)
                                .font(.ecCaption)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }

                    // Afficher les widgets dans l'ordre configuré
                    let enabledWidgets = viewModel.enabledWidgetTypes()
                    ForEach(Array(enabledWidgets.enumerated()), id: \.element) { index, widgetType in
                        widgetView(for: widgetType)
                            .staggeredAnimation(index: index, totalCount: enabledWidgets.count)
                    }
                }
                .padding(.vertical)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Dashboard")
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
                MacroPlanCreatorView()
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
            .sheet(item: $selectedMacroPlan) { plan in
                NavigationStack {
                    MacroPlanDetailView(plan: plan)
                        .environmentObject(themeManager)
                }
            }
            .sheet(isPresented: $navigateToPerformance) {
                PerformanceView()
                    .environmentObject(authViewModel)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingPMCDetail) {
                if let pmcStatus = viewModel.pmcStatus, let userId = authViewModel.user?.id {
                    PMCDetailView(pmcStatus: pmcStatus, userId: userId)
                        .environmentObject(themeManager)
                }
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
            .sheet(isPresented: $showingWeekProgressConfig) {
                WeekProgressConfigSheet(config: $viewModel.widgetPreferences.weekProgressConfig)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingSportsBreakdownConfig) {
                SportsBreakdownConfigSheet(config: $viewModel.widgetPreferences.sportsBreakdownConfig)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingPlannedSessionsConfig) {
                PlannedSessionsConfigSheet(config: $viewModel.widgetPreferences.plannedSessionsConfig)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingUpcomingSessionsConfig) {
                UpcomingSessionsConfigSheet(config: $viewModel.widgetPreferences.upcomingSessionsConfig)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingRecentActivitiesConfig) {
                RecentActivitiesConfigSheet(config: $viewModel.widgetPreferences.recentActivitiesConfig)
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
            kpiSummaryWidget
                .padding(.horizontal)

        case .pmcStatus:
            pmcStatusWidget
                .padding(.horizontal)

        case .performance:
            performanceWidget
                .padding(.horizontal)

        case .weekProgress:
            weekProgressWidget
                .padding(.horizontal)

        case .sportsBreakdown:
            sportsBreakdownWidget
                .padding(.horizontal)

        case .plannedSessions:
            plannedSessionsWidget
                .padding(.horizontal)

        case .upcomingSessions:
            upcomingSessionsWidget
                .padding(.horizontal)

        case .recentActivities:
            recentActivitiesWidget
                .padding(.horizontal)
        }
    }

    // MARK: - Individual Widgets

    private var kpiSummaryWidget: some View {
        let config = viewModel.widgetPreferences.kpiConfig
        let isEmpty = config.selectedMetrics.isEmpty

        return WidgetContainer(
            title: "Résumé",
            icon: "chart.bar.fill",
            iconColor: themeManager.accentColor,
            isEmpty: isEmpty,
            emptyMessage: "Aucune métrique sélectionnée",
            onConfigTap: { showingKPIConfig = true }
        ) {
            KPISummaryContent(
                timeScope: $viewModel.widgetPreferences.kpiConfig.timeScope,
                selectedMetrics: viewModel.widgetPreferences.kpiConfig.selectedMetrics,
                summary: viewModel.summary
            )
        }
    }

    private var pmcStatusWidget: some View {
        PMCStatusWidget(
            pmcStatus: viewModel.pmcStatus,
            isLoading: viewModel.isPMCLoading,
            onTap: { showingPMCDetail = true }
        )
    }

    private var performanceWidget: some View {
        let config = viewModel.widgetPreferences.performanceConfig
        let hasAnyCard = (config.showRunning && viewModel.hasRunningPerformance) ||
                         (config.showCycling && viewModel.hasCyclingPerformance) ||
                         (config.showSwimming && viewModel.hasSwimmingPerformance)
        let noCardsConfigured = !config.showRunning && !config.showCycling && !config.showSwimming

        return WidgetContainer(
            title: "Performance",
            icon: "gauge.with.dots.needle.67percent",
            iconColor: themeManager.warningColor,
            isEmpty: noCardsConfigured || !hasAnyCard,
            emptyMessage: noCardsConfigured ? "Aucune card sélectionnée" : "Aucune donnée de performance disponible",
            onConfigTap: { showingPerformanceConfig = true }
        ) {
            PerformanceCardsContent(
                viewModel: viewModel,
                config: config,
                onNavigateToPerformance: { navigateToPerformance = true }
            )
        }
    }

    private var weekProgressWidget: some View {
        let config = viewModel.widgetPreferences.weekProgressConfig
        let progress = viewModel.weekProgress
        let hasProgress = progress != nil && progress!.targetDuration > 0

        return WidgetContainer(
            title: "Progression semaine",
            icon: "chart.line.uptrend.xyaxis",
            iconColor: themeManager.successColor,
            isEmpty: !config.isVisible || !hasProgress,
            emptyMessage: config.isVisible ? "Définissez un objectif hebdomadaire" : "Widget masqué",
            onConfigTap: { showingWeekProgressConfig = true }
        ) {
            if let progress = progress, hasProgress {
                WeekProgressContent(progress: progress)
            }
        }
    }

    private var sportsBreakdownWidget: some View {
        let config = viewModel.widgetPreferences.sportsBreakdownConfig
        let byDiscipline = viewModel.byDiscipline

        // Vérifier si au moins un sport est activé ET a des données
        let hasVisibleSport = (config.showCyclisme && viewModel.hasCyclisme) ||
                              (config.showCourse && viewModel.hasCourse) ||
                              (config.showNatation && viewModel.hasNatation) ||
                              (config.showAutre && viewModel.hasAutre)

        let noSportsConfigured = !config.showCyclisme && !config.showCourse && !config.showNatation && !config.showAutre

        return WidgetContainer(
            title: "Par sport",
            icon: "figure.run.square.stack",
            iconColor: themeManager.infoColor,
            isEmpty: noSportsConfigured || !hasVisibleSport,
            emptyMessage: noSportsConfigured ? "Aucun sport sélectionné" : "Aucune activité cette semaine",
            onConfigTap: { showingSportsBreakdownConfig = true }
        ) {
            if let byDiscipline = byDiscipline {
                SportsBreakdownContent(
                    byDiscipline: byDiscipline,
                    config: config,
                    viewModel: viewModel,
                    selectedDiscipline: $selectedDiscipline
                )
            }
        }
    }

    private var plannedSessionsWidget: some View {
        let config = viewModel.widgetPreferences.plannedSessionsConfig
        let sessions = Array(viewModel.plannedSessions.prefix(config.maxItems))

        return WidgetContainer(
            title: "Plan d'entraînement",
            icon: "calendar.badge.clock",
            iconColor: themeManager.accentColor,
            isEmpty: false, // Toujours afficher, même vide (avec bouton créer plan)
            emptyMessage: "",
            onConfigTap: { showingPlannedSessionsConfig = true }
        ) {
            PlannedSessionsContent(
                sessions: sessions,
                hasPlan: viewModel.hasPlan,
                macroPlan: viewModel.macroPlan,
                onCreatePlan: { showingPlanCreator = true },
                onSessionTap: { session in
                    selectedPlannedSession = session
                },
                onPlanTap: { plan in
                    selectedMacroPlan = plan
                }
            )
        }
    }

    private var upcomingSessionsWidget: some View {
        let config = viewModel.widgetPreferences.upcomingSessionsConfig
        let sessions = Array(viewModel.upcomingSessions.prefix(config.maxItems))

        return WidgetContainer(
            title: "Prochaines séances",
            icon: "calendar",
            iconColor: themeManager.infoColor,
            isEmpty: sessions.isEmpty,
            emptyMessage: "Aucune séance à venir",
            onConfigTap: { showingUpcomingSessionsConfig = true }
        ) {
            UpcomingSessionsContent(sessions: sessions)
        }
    }

    private var recentActivitiesWidget: some View {
        let config = viewModel.widgetPreferences.recentActivitiesConfig
        let activities = Array(viewModel.recentActivities.prefix(config.maxItems))

        return WidgetContainer(
            title: "Activités récentes",
            icon: "clock.arrow.circlepath",
            iconColor: themeManager.successColor,
            isEmpty: activities.isEmpty,
            emptyMessage: "Aucune activité récente",
            onConfigTap: { showingRecentActivitiesConfig = true }
        ) {
            RecentActivitiesContent(activities: activities)
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
        .buttonStyle(.premium)
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
                    .buttonStyle(.premium)
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

// MARK: - Widget Content Views (sans header, pour WidgetContainer)

/// Contenu du widget KPI Summary (sans header)
struct KPISummaryContent: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var timeScope: DashboardTimeScope
    let selectedMetrics: [KPIMetricType]
    let summary: WeeklySummary?

    private var columns: [GridItem] {
        let count = selectedMetrics.count
        if count <= 2 {
            return [GridItem(.flexible()), GridItem(.flexible())]
        } else if count <= 3 {
            return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        } else {
            return [GridItem(.flexible()), GridItem(.flexible())]
        }
    }

    var body: some View {
        VStack(spacing: ECSpacing.sm) {
            // Picker de temporalité
            Picker("", selection: $timeScope) {
                Text("S").tag(DashboardTimeScope.week)
                Text("M").tag(DashboardTimeScope.month)
                Text("A").tag(DashboardTimeScope.year)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 150)

            // Grid des KPIs
            if let summary = summary {
                LazyVGrid(columns: columns, spacing: ECSpacing.sm) {
                    ForEach(selectedMetrics) { metric in
                        KPIMetricItem(
                            metric: metric,
                            value: value(for: metric, summary: summary)
                        )
                    }
                }
            } else {
                ProgressView()
                    .padding(.vertical, ECSpacing.md)
            }
        }
    }

    private func value(for metric: KPIMetricType, summary: WeeklySummary) -> String {
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

/// Contenu du widget Performance (sans header)
struct PerformanceCardsContent: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: DashboardViewModel
    let config: PerformanceWidgetConfig
    let onNavigateToPerformance: () -> Void

    var body: some View {
        VStack(spacing: ECSpacing.sm) {
            if config.showRunning && viewModel.hasRunningPerformance, let csDprime = viewModel.csDprime {
                RunningPerformanceMiniCard(csDprime: csDprime, onTap: onNavigateToPerformance)
            }

            if config.showCycling && viewModel.hasCyclingPerformance, let cpWprime = viewModel.cpWprime {
                CyclingPerformanceMiniCard(cpWprime: cpWprime, onTap: onNavigateToPerformance)
            }

            if config.showSwimming && viewModel.hasSwimmingPerformance, let css = viewModel.css {
                SwimmingPerformanceMiniCard(css: css, onTap: onNavigateToPerformance)
            }
        }
    }
}

/// Contenu du widget Week Progress (sans header)
struct WeekProgressContent: View {
    @EnvironmentObject var themeManager: ThemeManager
    let progress: WeekProgress

    var body: some View {
        VStack(spacing: ECSpacing.sm) {
            HStack {
                Text("\(Int(progress.percentage))%")
                    .font(.ecH4)
                    .foregroundColor(themeManager.successColor)
                Spacer()
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
    }
}

/// Contenu du widget Sports Breakdown (sans header)
struct SportsBreakdownContent: View {
    @EnvironmentObject var themeManager: ThemeManager
    let byDiscipline: ByDiscipline
    let config: SportsBreakdownConfig
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var selectedDiscipline: Discipline?

    var body: some View {
        VStack(spacing: ECSpacing.sm) {
            if config.showCyclisme && viewModel.hasCyclisme {
                SportCardCompact(discipline: .cyclisme, stats: byDiscipline.cyclisme) {
                    selectedDiscipline = .cyclisme
                }
            }

            if config.showCourse && viewModel.hasCourse {
                SportCardCompact(discipline: .course, stats: byDiscipline.course) {
                    selectedDiscipline = .course
                }
            }

            if config.showNatation && viewModel.hasNatation {
                SportCardCompact(discipline: .natation, stats: byDiscipline.natation) {
                    selectedDiscipline = .natation
                }
            }

            if config.showAutre && viewModel.hasAutre {
                SportCardCompact(discipline: .autre, stats: byDiscipline.autre) {
                    selectedDiscipline = .autre
                }
            }
        }
    }
}

/// Card compacte pour un sport (utilisé dans SportsBreakdownContent)
struct SportCardCompact: View {
    @EnvironmentObject var themeManager: ThemeManager
    let discipline: Discipline
    let stats: DisciplineStat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ECSpacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(themeManager.sportColorLight(for: discipline))
                        .frame(width: 36, height: 36)

                    Image(systemName: discipline.icon)
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.sportColor(for: discipline))
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(discipline.displayName)
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)

                    Text("\(stats.count) séance\(stats.count > 1 ? "s" : "")")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                }

                Spacer()

                Text(stats.formattedDuration)
                    .font(.ecBodyMedium)
                    .foregroundColor(themeManager.textPrimary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.textTertiary)
            }
            .padding(ECSpacing.sm)
            .background(themeManager.elevatedColor.opacity(0.5))
            .cornerRadius(ECRadius.md)
        }
        .buttonStyle(.premium)
    }
}

/// Contenu du widget Planned Sessions (sans header)
struct PlannedSessionsContent: View {
    @EnvironmentObject var themeManager: ThemeManager
    let sessions: [PlannedSession]
    let hasPlan: Bool
    let macroPlan: MacroPlanData?
    let onCreatePlan: () -> Void
    let onSessionTap: (PlannedSession) -> Void
    let onPlanTap: (MacroPlanData) -> Void

    var body: some View {
        VStack(spacing: ECSpacing.sm) {

            // Planning de saison (si disponible) - Affichage simplifié
            if let macroPlan = macroPlan {
                MacroPlanCard(plan: macroPlan, onTap: { onPlanTap(macroPlan) })
            }

            if sessions.isEmpty {
                VStack(spacing: ECSpacing.sm) {
                    if macroPlan == nil {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 24))
                            .foregroundColor(themeManager.textTertiary)
                        Text("Créez un plan d'entraînement")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                        Button(action: onCreatePlan) {
                            Text("Créer un plan")
                                .font(.ecCaption)
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ECSpacing.sm)
            } else {
                ForEach(sessions) { session in
                    Button {
                        onSessionTap(session)
                    } label: {
                        PlannedSessionRowCompact(session: session)
                    }
                    .buttonStyle(.premium)
                }
            }
        }
    }
}

/// Carte simplifiée du MacroPlan - affiche juste le nom, cliquable
struct MacroPlanCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let plan: MacroPlanData
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ECSpacing.md) {
                // Icône
                ZStack {
                    Circle()
                        .fill(themeManager.accentColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.accentColor)
                }

                // Infos
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.name ?? "Plan de saison")
                        .font(.ecBodyMedium)
                        .foregroundColor(themeManager.textPrimary)
                        .lineLimit(1)

                    if let bars = plan.visualBars, !bars.isEmpty {
                        let totalWeeks = bars.map { $0.weekEnd }.max() ?? 0
                        Text("\(totalWeeks) semaines • \(plan.objectives?.count ?? 0) objectif(s)")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.textTertiary)
            }
            .padding()
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.premium)
    }
}

/// Row compacte pour une séance planifiée
struct PlannedSessionRowCompact: View {
    @EnvironmentObject var themeManager: ThemeManager
    let session: PlannedSession

    var body: some View {
        HStack(spacing: ECSpacing.sm) {
            Rectangle()
                .fill(themeManager.sportColor(for: session.discipline))
                .frame(width: 3)
                .cornerRadius(1.5)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                    .lineLimit(1)

                if let duration = session.formattedDuration {
                    Text(duration)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                }
            }

            Spacer()

            Text("Prévu")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(themeManager.accentColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(themeManager.accentColorLight)
                .cornerRadius(ECRadius.sm)

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(themeManager.textTertiary)
        }
        .padding(ECSpacing.sm)
        .background(themeManager.elevatedColor.opacity(0.5))
        .cornerRadius(ECRadius.md)
    }
}

/// Contenu du widget Upcoming Sessions (sans header)
struct UpcomingSessionsContent: View {
    @EnvironmentObject var themeManager: ThemeManager
    let sessions: [UpcomingSession]

    var body: some View {
        VStack(spacing: ECSpacing.sm) {
            ForEach(sessions) { session in
                UpcomingSessionRowCompact(session: session)
            }
        }
    }
}

/// Row compacte pour une prochaine séance
struct UpcomingSessionRowCompact: View {
    @EnvironmentObject var themeManager: ThemeManager
    let session: UpcomingSession

    var body: some View {
        HStack(spacing: ECSpacing.sm) {
            // Date compacte
            VStack(spacing: 0) {
                Text(dayOfWeek)
                    .font(.system(size: 9))
                    .foregroundColor(themeManager.textTertiary)
                Text(dayNumber)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }
            .frame(width: 32)

            Rectangle()
                .fill(themeManager.sportColor(for: session.discipline))
                .frame(width: 3)
                .cornerRadius(1.5)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                    .lineLimit(1)

                HStack(spacing: ECSpacing.xs) {
                    Text(session.formattedDuration)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)

                    if let distance = session.formattedDistance {
                        Text("•")
                            .foregroundColor(themeManager.textTertiary)
                        Text(distance)
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }
            }

            Spacer()
        }
        .padding(ECSpacing.sm)
        .background(themeManager.elevatedColor.opacity(0.5))
        .cornerRadius(ECRadius.md)
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

/// Contenu du widget Recent Activities (sans header)
struct RecentActivitiesContent: View {
    @EnvironmentObject var themeManager: ThemeManager
    let activities: [Activity]

    var body: some View {
        VStack(spacing: ECSpacing.sm) {
            ForEach(activities) { activity in
                ActivityRowCompact(activity: activity)
            }
        }
    }
}

/// Row compacte pour une activité
struct ActivityRowCompact: View {
    @EnvironmentObject var themeManager: ThemeManager
    let activity: Activity

    var body: some View {
        HStack(spacing: ECSpacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(themeManager.sportColorLight(for: activity.discipline))
                    .frame(width: 32, height: 32)

                Image(systemName: activity.discipline.icon)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.sportColor(for: activity.discipline))
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.displayTitle)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                    .lineLimit(1)

                HStack(spacing: ECSpacing.xs) {
                    if let duration = activity.formattedDuration {
                        Text(duration)
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    if let distance = activity.formattedDistance {
                        Text("•")
                            .foregroundColor(themeManager.textTertiary)
                        Text(distance)
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }
            }

            Spacer()

            // TSS
            if let tss = activity.preferredTSSInt {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(tss)")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                    Text("TSS")
                        .font(.system(size: 8))
                        .foregroundColor(themeManager.textTertiary)
                }
            }
        }
        .padding(ECSpacing.sm)
        .background(themeManager.elevatedColor.opacity(0.5))
        .cornerRadius(ECRadius.md)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppState())
        .environmentObject(ThemeManager.shared)
}

// MARK: - Season Timeline View (Embedded)

struct SeasonTimelineView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let bars: [VisualBar]
    let totalWeeks: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Planning de la saison")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)
            
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(themeManager.cardColor)
                        .frame(height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(themeManager.borderColor, lineWidth: 1)
                        )
                    
                    // Bars
                    ForEach(bars) { bar in
                        barView(for: bar, totalWidth: totalWidth)
                    }
                }
            }
            .frame(height: 32)
            
            // Legend / Time markers
            HStack {
                Text("Semaine 1")
                Spacer()
                Text("Semaine \(totalWeeks)")
            }
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
    }
    
    private func barView(for bar: VisualBar, totalWidth: CGFloat) -> some View {
        let width = max(4, bar.widthRatio * totalWidth) // Min width 4px to be visible
        let xOffset = bar.startRatio * totalWidth
        
        return ZStack {
            Rectangle()
                .fill(colorFor(segmentType: bar.segmentType))
                .cornerRadius(4)
            
            if width > 40 {
                Text(bar.subplanName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 2)
            }
        }
        .frame(width: width, height: 24)
        .offset(x: xOffset)
    }
    
    private func colorFor(segmentType: String) -> Color {
        switch segmentType.lowercased() {
        case "general", "preparatory", "preparation":
            return themeManager.infoColor.opacity(0.8) // Blue
        case "specific", "build":
            return themeManager.warningColor.opacity(0.8) // Yellow/Orange
        case "taper", "recovery":
            return themeManager.successColor.opacity(0.8) // Green
        case "race", "competition":
            return themeManager.accentColor // Primary/Red
        default:
            return themeManager.textTertiary
        }
    }
}
