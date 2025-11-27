/**
 * Vue Calendrier - Planning des entraînements
 */

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = CalendarViewModel()

    // Navigation states
    @State private var selectedActivity: Activity?
    @State private var selectedPlannedSession: PlannedSession?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Month Header
                CalendarHeader(
                    currentMonth: viewModel.currentMonth,
                    onPreviousMonth: { viewModel.previousMonth() },
                    onNextMonth: { viewModel.nextMonth() },
                    onToday: { viewModel.goToToday() }
                )

                // Week Days Header
                WeekDaysHeader()

                // Calendar Grid
                CalendarGrid(
                    viewModel: viewModel,
                    onDateSelected: { date in
                        viewModel.selectDate(date)
                    }
                )

                Divider()
                    .padding(.vertical, ECSpacing.sm)

                // Selected Date Content
                SelectedDateContent(
                    viewModel: viewModel,
                    onActivityTap: { activity in
                        selectedActivity = activity
                    },
                    onPlannedSessionTap: { session in
                        selectedPlannedSession = session
                    }
                )
            }
            .background(Color.ecBackground)
            .navigationTitle("Calendrier")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedActivity) { activity in
                NavigationStack {
                    SessionDetailView(activity: activity)
                }
            }
            .sheet(item: $selectedPlannedSession) { session in
                PlannedSessionDetailView(session: session)
            }
        }
        .task {
            if let userId = authViewModel.user?.id {
                await viewModel.loadData(userId: userId)
            }
        }
        .onChange(of: viewModel.currentDate) { newValue in
            Task {
                if let userId = authViewModel.user?.id {
                    await viewModel.loadData(userId: userId)
                }
            }
        }
    }
}

// MARK: - Calendar Header

struct CalendarHeader: View {
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
                    .foregroundColor(.ecPrimary)
            }

            Spacer()

            Button(action: onToday) {
                Text(monthYearString)
                    .font(.ecH4)
                    .foregroundColor(.ecSecondary800)
            }

            Spacer()

            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.ecBody)
                    .foregroundColor(.ecPrimary)
            }
        }
        .padding(.horizontal, ECSpacing.lg)
        .padding(.vertical, ECSpacing.md)
    }
}

// MARK: - Week Days Header

struct WeekDaysHeader: View {
    private let weekDays = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                Text(day)
                    .font(.ecCaption)
                    .foregroundColor(.ecGray500)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, ECSpacing.sm)
        .padding(.bottom, ECSpacing.xs)
    }
}

// MARK: - Calendar Grid

struct CalendarGrid: View {
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
            VStack(spacing: 2) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.ecPrimary)
                            .frame(width: 36, height: 36)
                    } else if isToday {
                        Circle()
                            .stroke(Color.ecPrimary, lineWidth: 2)
                            .frame(width: 36, height: 36)
                    }

                    Text(dayNumber)
                        .font(.ecBody)
                        .foregroundColor(textColor)
                }

                // Indicators
                HStack(spacing: 2) {
                    if hasActivity {
                        Circle()
                            .fill(Color.ecSuccess)
                            .frame(width: 5, height: 5)
                    }
                    if hasPlannedSession {
                        Circle()
                            .fill(Color.ecPrimary)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
        }
        .frame(height: 50)
        .opacity(isCurrentMonth ? 1 : 0.3)
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .ecPrimary
        } else if !isCurrentMonth {
            return .ecGray400
        } else {
            return .ecSecondary800
        }
    }
}

// MARK: - Selected Date Content

struct SelectedDateContent: View {
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
                    .foregroundColor(.ecSecondary800)
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
                                .foregroundColor(.ecGray500)
                                .padding(.horizontal, ECSpacing.md)

                            ForEach(sessions) { session in
                                Button {
                                    onPlannedSessionTap(session)
                                } label: {
                                    CalendarSessionCard(session: session)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Activities
                    if !activities.isEmpty {
                        VStack(alignment: .leading, spacing: ECSpacing.sm) {
                            Text("Activités réalisées")
                                .font(.ecCaption)
                                .foregroundColor(.ecGray500)
                                .padding(.horizontal, ECSpacing.md)

                            ForEach(activities) { activity in
                                Button {
                                    onActivityTap(activity)
                                } label: {
                                    CalendarActivityCard(activity: activity)
                                }
                                .buttonStyle(.plain)
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
    var body: some View {
        VStack(spacing: ECSpacing.sm) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.ecGray300)

            Text("Aucune activité ce jour")
                .font(.ecBody)
                .foregroundColor(.ecGray500)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ECSpacing.xl)
    }
}

struct CalendarSessionCard: View {
    let session: PlannedSession

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            Rectangle()
                .fill(Color.sportColor(for: session.discipline))
                .frame(width: 4)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayTitle)
                    .font(.ecLabelBold)
                    .foregroundColor(.ecSecondary800)
                    .lineLimit(1)

                HStack(spacing: ECSpacing.sm) {
                    if let duration = session.estimatedDuration {
                        Label(duration, systemImage: "clock")
                            .font(.ecCaption)
                            .foregroundColor(.ecGray500)
                    }

                    if let distance = session.estimatedDistance {
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
        .padding(ECSpacing.md)
        .background(Color.ecSurface)
        .cornerRadius(ECRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal, ECSpacing.md)
    }
}

struct CalendarActivityCard: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.sportColor(for: activity.discipline).opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: activity.discipline.icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color.sportColor(for: activity.discipline))
            }

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

            Image(systemName: "chevron.right")
                .font(.ecCaption)
                .foregroundColor(.ecGray400)
        }
        .padding(ECSpacing.md)
        .background(Color.ecSurface)
        .cornerRadius(ECRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal, ECSpacing.md)
    }
}

// MARK: - Planned Session Detail View

struct PlannedSessionDetailView: View {
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
                                .fill(Color.sportColor(for: session.discipline).opacity(0.15))
                                .frame(width: 80, height: 80)

                            Image(systemName: session.discipline.icon)
                                .font(.system(size: 36))
                                .foregroundColor(Color.sportColor(for: session.discipline))
                        }

                        Text(session.displayTitle)
                            .font(.ecH3)
                            .foregroundColor(.ecSecondary800)
                            .multilineTextAlignment(.center)

                        if let dateValue = session.dateValue {
                            Text(formatDate(dateValue))
                                .font(.ecBody)
                                .foregroundColor(.ecGray500)
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
                    .ecCard()

                    // Zone & Intensity
                    if session.targetPace != nil || session.zone != nil {
                        VStack(alignment: .leading, spacing: ECSpacing.md) {
                            HStack {
                                Image(systemName: "gauge.with.needle")
                                    .foregroundColor(.ecPrimary)
                                Text("Intensité")
                                    .font(.ecLabelBold)
                                    .foregroundColor(.ecSecondary800)
                                Spacer()
                            }

                            HStack(spacing: ECSpacing.lg) {
                                if let zone = session.zone {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Zone")
                                            .font(.ecSmall)
                                            .foregroundColor(.ecGray500)
                                        Text(zone)
                                            .font(.ecBodyMedium)
                                            .foregroundColor(.ecSecondary800)
                                    }
                                }

                                if let pace = session.targetPace {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Cible")
                                            .font(.ecSmall)
                                            .foregroundColor(.ecGray500)
                                        Text(pace)
                                            .font(.ecBodyMedium)
                                            .foregroundColor(.ecSecondary800)
                                    }
                                }
                            }
                        }
                        .ecCard()
                    }

                    // Description
                    if let description = session.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: ECSpacing.sm) {
                            HStack {
                                Image(systemName: "text.alignleft")
                                    .foregroundColor(.ecWarning)
                                Text("Description")
                                    .font(.ecLabelBold)
                                    .foregroundColor(.ecSecondary800)
                                Spacer()
                            }

                            Text(description)
                                .font(.ecBody)
                                .foregroundColor(.ecSecondary700)
                        }
                        .ecCard()
                    }

                    // Focus
                    if let focus = session.focus, !focus.isEmpty {
                        VStack(alignment: .leading, spacing: ECSpacing.sm) {
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(.ecSuccess)
                                Text("Focus")
                                    .font(.ecLabelBold)
                                    .foregroundColor(.ecSecondary800)
                                Spacer()
                            }

                            Text(focus)
                                .font(.ecBody)
                                .foregroundColor(.ecSecondary700)
                        }
                        .ecCard()
                    }

                    // Educatifs
                    if !session.educatifs.isEmpty {
                        VStack(alignment: .leading, spacing: ECSpacing.sm) {
                            HStack {
                                Image(systemName: "lightbulb")
                                    .foregroundColor(.ecInfo)
                                Text("Éducatifs")
                                    .font(.ecLabelBold)
                                    .foregroundColor(.ecSecondary800)
                                Spacer()
                            }

                            ForEach(session.educatifs, id: \.self) { educatif in
                                HStack(alignment: .top, spacing: ECSpacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.ecSuccess)
                                    Text(educatif)
                                        .font(.ecBody)
                                        .foregroundColor(.ecSecondary700)
                                }
                            }
                        }
                        .ecCard()
                    }

                    Spacer(minLength: ECSpacing.xl)
                }
                .padding()
            }
            .background(Color.ecBackground)
            .navigationTitle("Séance planifiée")
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date).capitalized
    }
}

struct PlannedSessionStatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.ecSmall)
                    .foregroundColor(.ecGray400)
                Text(value)
                    .font(.ecBodyMedium)
                    .foregroundColor(.ecSecondary800)
            }
            Text(label)
                .font(.ecSmall)
                .foregroundColor(.ecGray500)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CalendarView()
        .environmentObject(AuthViewModel())
}
