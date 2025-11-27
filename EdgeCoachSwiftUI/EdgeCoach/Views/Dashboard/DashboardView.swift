/**
 * Vue Dashboard - Écran d'accueil
 */

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedDiscipline: Discipline?
    @State private var showingPlanCreator = false
    @State private var selectedPlannedSession: PlannedSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.md) {
                    // Weekly Summary Card
                    if let summary = viewModel.summary {
                        WeeklySummaryCard(summary: summary, weekStart: viewModel.weeklySummaryData?.weekStart, weekEnd: viewModel.weeklySummaryData?.weekEnd)
                    }
                    
                    // Training Load Card (TODO: Implement TrainingLoadCard and TrainingLoad model)
                    // if let trainingLoad = viewModel.trainingLoad {
                    //     TrainingLoadCard(load: trainingLoad)
                    // }

                    // Week Progress
                    if let progress = viewModel.weekProgress, progress.targetDuration > 0 {
                        WeekProgressCard(progress: progress)
                    }

                    // Sports Breakdown
                    if viewModel.hasAnySport, let byDiscipline = viewModel.byDiscipline {
                        SportsBreakdownSection(
                            byDiscipline: byDiscipline,
                            viewModel: viewModel,
                            weekStart: viewModel.weekStartDate,
                            selectedDiscipline: $selectedDiscipline
                        )
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

                    // Upcoming Sessions (from API)
                    if !viewModel.upcomingSessions.isEmpty {
                        UpcomingSessionsSection(sessions: viewModel.upcomingSessions)
                    }

                    // Recent Activities
                    if !viewModel.recentActivities.isEmpty {
                        RecentActivitiesSection(activities: viewModel.recentActivities)
                    }
                }
                .padding()
            }
            .background(Color.ecBackground)
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingPlanCreator = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.ecPrimary)
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
            }
            .sheet(isPresented: $showingPlanCreator) {
                TrainingPlanCreatorView()
                    .environmentObject(authViewModel)
                    .onDisappear {
                        // Refresh data after creating a plan
                        Task {
                            if let userId = authViewModel.user?.id {
                                await viewModel.refresh(userId: userId)
                            }
                        }
                    }
            }
            .sheet(item: $selectedPlannedSession) { session in
                PlannedSessionDetailSheet(session: session)
            }
        }
        .task {
            if let userId = authViewModel.user?.id {
                await viewModel.loadData(userId: userId)
            }
        }
    }
}

// MARK: - Weekly Summary Card

struct WeeklySummaryCard: View {
    let summary: WeeklySummary
    let weekStart: String?
    let weekEnd: String?

    var body: some View {
        VStack(spacing: ECSpacing.md) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.ecPrimary)
                Text("Résumé de la semaine")
                    .font(.ecLabelBold)
                    .foregroundColor(.ecSecondary800)
                Spacer()
                if let start = weekStart, let end = weekEnd {
                    Text("\(formatDateShort(start)) - \(formatDateShort(end))")
                        .font(.ecCaption)
                        .foregroundColor(.ecGray500)
                }
            }

            // Main Stats
            HStack(spacing: 0) {
                StatItem(
                    value: summary.formattedDuration,
                    label: "Volume",
                    color: .ecPrimary
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    value: summary.formattedDistance,
                    label: "Distance",
                    color: .ecPrimary
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    value: "\(summary.sessionsCount)",
                    label: "Séances",
                    color: .ecPrimary
                )
            }
            .padding(.vertical, ECSpacing.sm)
            .background(Color.ecPrimary50)
            .cornerRadius(ECRadius.md)
        }
        .ecCard()
    }

    private func formatDateShort(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "d MMM"
        outputFormatter.locale = Locale(identifier: "fr_FR")
        return outputFormatter.string(from: date)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.ecH3)
                .foregroundColor(color)

            Text(label)
                .font(.ecCaption)
                .foregroundColor(.ecGray500)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Week Progress Card

struct WeekProgressCard: View {
    let progress: WeekProgress

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.ecSuccess)
                Text("Progression de la semaine")
                    .font(.ecLabelBold)
                    .foregroundColor(.ecSecondary800)
                Spacer()
                Text("\(Int(progress.percentage))%")
                    .font(.ecH4)
                    .foregroundColor(.ecSuccess)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.ecGray100)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.ecSuccess)
                        .frame(width: geometry.size.width * min(1, progress.percentage / 100), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(DashboardService.shared.formatDuration(progress.achievedDuration))")
                    .font(.ecCaption)
                    .foregroundColor(.ecGray600)
                Spacer()
                Text("Objectif: \(DashboardService.shared.formatDuration(progress.targetDuration))")
                    .font(.ecCaption)
                    .foregroundColor(.ecGray500)
            }
        }
        .ecCard()
    }
}

// MARK: - Sports Breakdown Section

struct SportsBreakdownSection: View {
    let byDiscipline: ByDiscipline
    @ObservedObject var viewModel: DashboardViewModel
    let weekStart: Date?
    @Binding var selectedDiscipline: Discipline?

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Par sport")
                .font(.ecLabelBold)
                .foregroundColor(.ecSecondary800)
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
    let discipline: Discipline
    let stats: DisciplineStat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ECSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.sportColor(for: discipline).opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: discipline.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color.sportColor(for: discipline))
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(discipline.displayName)
                        .font(.ecLabelBold)
                        .foregroundColor(.ecSecondary800)

                    Text("\(stats.count) séance\(stats.count > 1 ? "s" : "")")
                        .font(.ecCaption)
                        .foregroundColor(.ecGray500)
                }

                Spacer()

                // Duration + Chevron
                HStack(spacing: ECSpacing.sm) {
                    Text(stats.formattedDuration)
                        .font(.ecBodyMedium)
                        .foregroundColor(.ecSecondary800)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.ecGray400)
                }
            }
            .ecCard(padding: ECSpacing.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Upcoming Sessions Section

struct UpcomingSessionsSection: View {
    let sessions: [UpcomingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Prochaines séances")
                .font(.ecLabelBold)
                .foregroundColor(.ecSecondary800)
                .padding(.horizontal, ECSpacing.sm)

            ForEach(sessions) { session in
                UpcomingSessionCard(session: session)
            }
        }
    }
}

struct UpcomingSessionCard: View {
    let session: UpcomingSession

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Date
            VStack(spacing: 2) {
                Text(dayOfWeek)
                    .font(.ecCaption)
                    .foregroundColor(.ecGray500)
                Text(dayNumber)
                    .font(.ecH4)
                    .foregroundColor(.ecSecondary800)
            }
            .frame(width: 44)

            // Discipline indicator
            Rectangle()
                .fill(Color.sportColor(for: session.discipline))
                .frame(width: 4)
                .cornerRadius(2)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.ecLabelBold)
                    .foregroundColor(.ecSecondary800)
                    .lineLimit(1)

                HStack(spacing: ECSpacing.sm) {
                    Label(session.formattedDuration, systemImage: "clock")
                        .font(.ecCaption)
                        .foregroundColor(.ecGray500)

                    if let distance = session.formattedDistance {
                        Label(distance, systemImage: "arrow.left.and.right")
                            .font(.ecCaption)
                            .foregroundColor(.ecGray500)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.ecCaption)
                .foregroundColor(.ecGray400)
        }
        .ecCard(padding: ECSpacing.md)
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
    let sessions: [PlannedSession]
    let hasPlan: Bool
    let onCreatePlan: () -> Void
    let onSessionTap: (PlannedSession) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            HStack {
                Text("Séances prévues")
                    .font(.ecLabelBold)
                    .foregroundColor(.ecSecondary800)
                Spacer()
                if !hasPlan {
                    Button(action: onCreatePlan) {
                        Text("Créer un plan")
                            .font(.ecCaption)
                            .foregroundColor(.ecPrimary)
                    }
                }
            }
            .padding(.horizontal, ECSpacing.sm)

            if sessions.isEmpty {
                VStack(spacing: ECSpacing.sm) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 30))
                        .foregroundColor(.ecGray300)
                    Text(hasPlan ? "Aucune séance prévue cette semaine" : "Créez un plan d'entraînement")
                        .font(.ecCaption)
                        .foregroundColor(.ecGray500)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ECSpacing.lg)
                .background(Color.white)
                .cornerRadius(ECRadius.lg)
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
    let session: PlannedSession

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Discipline indicator
            Rectangle()
                .fill(Color.sportColor(for: session.discipline))
                .frame(width: 4)
                .cornerRadius(2)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.ecLabelBold)
                    .foregroundColor(.ecSecondary800)
                    .lineLimit(1)

                HStack(spacing: ECSpacing.sm) {
                    if let duration = session.formattedDuration {
                        Label(duration, systemImage: "clock")
                            .font(.ecCaption)
                            .foregroundColor(.ecGray500)
                    }
                }
            }

            Spacer()

            // Badge "Prévu"
            Text("Prévu")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.ecPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.ecPrimary.opacity(0.1))
                .cornerRadius(ECRadius.sm)

            Image(systemName: "chevron.right")
                .font(.ecCaption)
                .foregroundColor(.ecGray400)
        }
        .padding(ECSpacing.md)
        .background(Color.white)
        .cornerRadius(ECRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct PlannedSessionDetailSheet: View {
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
                                .fill(Color.sportColor(for: session.discipline).opacity(0.15))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: session.discipline.icon)
                                        .font(.title2)
                                        .foregroundColor(Color.sportColor(for: session.discipline))
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title)
                                    .font(.ecH4)
                                    .foregroundColor(.ecSecondary800)

                                Text(session.formattedDate ?? session.date)
                                    .font(.ecCaption)
                                    .foregroundColor(.ecGray500)
                            }
                        }
                    }
                    .ecCard()

                    // Stats
                    HStack(spacing: ECSpacing.md) {
                        if let duration = session.formattedDuration {
                            PlannedStatItem(icon: "clock", value: duration, label: "Durée")
                        }
                        if let distance = session.formattedDistance {
                            PlannedStatItem(icon: "arrow.left.and.right", value: distance, label: "Distance")
                        }
                    }
                    .ecCard()

                    // Description
                    if let description = session.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: ECSpacing.sm) {
                            Text("Description")
                                .font(.ecLabelBold)
                                .foregroundColor(.ecSecondary800)
                            Text(description)
                                .font(.ecBody)
                                .foregroundColor(.ecGray600)
                        }
                        .ecCard()
                    }
                }
                .padding()
            }
            .background(Color.ecBackground)
            .navigationTitle("Séance prévue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PlannedStatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.ecPrimary)
                Text(value)
                    .font(.ecBodyMedium)
                    .foregroundColor(.ecSecondary800)
            }
            Text(label)
                .font(.ecCaption)
                .foregroundColor(.ecGray500)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recent Activities Section

struct RecentActivitiesSection: View {
    let activities: [Activity]

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text("Activités récentes")
                .font(.ecLabelBold)
                .foregroundColor(.ecSecondary800)
                .padding(.horizontal, ECSpacing.sm)

            ForEach(activities) { activity in
                ActivityCard(activity: activity)
            }
        }
    }
}

struct ActivityCard: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.sportColor(for: activity.discipline).opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: activity.discipline.icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color.sportColor(for: activity.discipline))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.displayTitle)
                    .font(.ecLabelBold)
                    .foregroundColor(.ecSecondary800)
                    .lineLimit(1)

                HStack(spacing: ECSpacing.sm) {
                    if let duration = activity.formattedDuration {
                        Text(duration)
                            .font(.ecCaption)
                            .foregroundColor(.ecGray500)
                    }

                    if let distance = activity.formattedDistance {
                        Text(distance)
                            .font(.ecCaption)
                            .foregroundColor(.ecGray500)
                    }
                }
            }

            Spacer()

            // TSS
            if let tss = activity.tss {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(tss)")
                        .font(.ecLabelBold)
                        .foregroundColor(.ecSecondary800)
                    Text("TSS")
                        .font(.ecSmall)
                        .foregroundColor(.ecGray500)
                }
            }
        }
        .ecCard(padding: ECSpacing.md)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppState())
}
