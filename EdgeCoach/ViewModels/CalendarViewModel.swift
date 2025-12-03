/**
 * ViewModel pour le Calendrier
 */

import SwiftUI
import Combine

@MainActor
class CalendarViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentDate: Date = Date()
    @Published var selectedDate: Date = Date()
    @Published var viewMode: CalendarViewMode = .month

    @Published var completedActivities: [Activity] = []
    @Published var plannedSessions: [PlannedSession] = []

    @Published var isLoading: Bool = false
    @Published var error: String?

    // Cache des activités par mois pour éviter les rechargements
    private var activitiesCache: [String: [Activity]] = [:]
    private var plannedSessionsCache: [String: [PlannedSession]] = [:]

    // Navigation
    @Published var selectedActivity: Activity?
    @Published var selectedPlannedSession: PlannedSession?
    @Published var showingSessionDetail: Bool = false

    // MARK: - Services

    private let activitiesService = ActivitiesService.shared
    private let plansService = PlansService.shared

    // MARK: - Calendar View Mode

    enum CalendarViewMode: String, CaseIterable {
        case week = "Semaine"
        case month = "Mois"
    }

    // MARK: - Load Data

    func loadData(userId: String, forceReload: Bool = false) async {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        let monthKey = "\(year)-\(month)"

        // Éviter de recharger si le mois est déjà en cache
        guard forceReload || !loadedMonths.contains(monthKey) else {
            return
        }

        isLoading = true
        error = nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadActivities(userId: userId, year: year, month: month)
            }

            group.addTask {
                await self.loadPlannedSessions(userId: userId, year: year, month: month)
            }
        }

        loadedMonths.insert(monthKey)
        isLoading = false
    }

    // MARK: - Load Activities

    private func loadActivities(userId: String, year: Int, month: Int) async {
        do {
            completedActivities = try await activitiesService.getActivitiesForMonth(
                userId: userId,
                year: year,
                month: month
            )
        } catch {
            #if DEBUG
            print("Failed to load activities: \(error)")
            #endif
        }
    }

    // MARK: - Load Planned Sessions

    private func loadPlannedSessions(userId: String, year: Int, month: Int) async {
        do {
            let allSessions = try await plansService.getLastPlan(userId: userId)
            plannedSessions = plansService.filterByMonth(allSessions, year: year, month: month)
        } catch {
            #if DEBUG
            print("Failed to load planned sessions: \(error)")
            #endif
        }
    }

    // MARK: - Navigation

    func goToPreviousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
        }
    }

    func goToNextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
        }
    }

    func goToToday() {
        currentDate = Date()
        selectedDate = Date()
    }

    // MARK: - Date Helpers

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: currentDate).capitalized
    }

    var daysInMonth: [Date] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: currentDate)!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!

        // Calculer le nombre de jours de décalage (jours du mois précédent à afficher)
        let offsetDays = firstWeekday

        var days: [Date] = []

        // Ajouter les jours du mois précédent pour le décalage
        if offsetDays > 0 {
            for i in (1...offsetDays).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i, to: startOfMonth) {
                    days.append(date)
                }
            }
        }

        // Ajouter les jours du mois actuel
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }

        return days
    }

    var firstWeekday: Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        let weekday = calendar.component(.weekday, from: startOfMonth)
        // Adjust for Monday start (1 = Monday, 7 = Sunday)
        return (weekday + 5) % 7
    }

    // MARK: - Get Data for Date

    func activitiesForDate(_ date: Date) -> [Activity] {
        let calendar = Calendar.current
        return completedActivities.filter { activity in
            guard let activityDate = activity.date else { return false }
            return calendar.isDate(activityDate, inSameDayAs: date)
        }
    }

    func plannedSessionsForDate(_ date: Date) -> [PlannedSession] {
        let calendar = Calendar.current
        return plannedSessions.filter { session in
            guard let sessionDate = session.dateValue else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: date)
        }
    }

    func hasDataForDate(_ date: Date) -> Bool {
        !activitiesForDate(date).isEmpty || !plannedSessionsForDate(date).isEmpty
    }

    // MARK: - TSS Color

    func tssColor(for date: Date) -> Color {
        let activities = activitiesForDate(date)
        let totalTSS = activities.compactMap { $0.tss }.reduce(0, +)

        switch totalTSS {
        case 0:
            return .clear
        case 1..<50:
            return .ecSuccess.opacity(0.3)
        case 50..<100:
            return .ecSuccess.opacity(0.6)
        case 100..<150:
            return .ecWarning.opacity(0.5)
        case 150..<200:
            return .ecWarning.opacity(0.8)
        default:
            return .ecError.opacity(0.7)
        }
    }

    // MARK: - Selected Date Data

    var selectedDateActivities: [Activity] {
        activitiesForDate(selectedDate)
    }

    var selectedDatePlannedSessions: [PlannedSession] {
        plannedSessionsForDate(selectedDate)
    }

    var selectedDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: selectedDate).capitalized
    }

    // MARK: - Calendar Grid helpers (for CalendarView)

    var currentMonth: Date { currentDate }

    func previousMonth() {
        goToPreviousMonth()
    }

    func nextMonth() {
        goToNextMonth()
    }

    func selectDate(_ date: Date) {
        selectedDate = date
    }

    func isCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.month, from: date) == calendar.component(.month, from: currentDate)
    }

    func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }

    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    func hasActivity(on date: Date) -> Bool {
        !activitiesForDate(date).isEmpty
    }

    func hasPlannedSession(on date: Date) -> Bool {
        !plannedSessionsForDate(date).isEmpty
    }

    var activitiesForSelectedDate: [Activity] {
        selectedDateActivities
    }

    var plannedSessionsForSelectedDate: [PlannedSession] {
        selectedDatePlannedSessions
    }
}
