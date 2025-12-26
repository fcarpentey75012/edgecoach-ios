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
    @Published var isRefreshing: Bool = false  // Pour le rafraîchissement en arrière-plan
    @Published var error: String?

    // Cache en mémoire pour les séances planifiées uniquement
    private var plannedSessionsCache: [String: [PlannedSession]] = [:]

    // Navigation
    @Published var selectedActivity: Activity?
    @Published var selectedPlannedSession: PlannedSession?
    @Published var showingSessionDetail: Bool = false

    // MARK: - Services

    private let activitiesService = ActivitiesService.shared
    private let plansService = PlansService.shared
    private let cycleService = CycleService.shared

    // MARK: - Static DateFormatters (évite création répétée)
    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()

    private static let selectedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()

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

        // Charger les activités avec stratégie cache-first
        await loadActivitiesCacheFirst(userId: userId, year: year, month: month, forceReload: forceReload)

        // Charger les séances planifiées (cache mémoire)
        if !forceReload, let cachedPlanned = plannedSessionsCache[monthKey] {
            plannedSessions = cachedPlanned
        } else {
            await loadPlannedSessions(userId: userId, year: year, month: month)
            plannedSessionsCache[monthKey] = plannedSessions
        }
    }

    // MARK: - Load Activities (Cache-First)

    private func loadActivitiesCacheFirst(userId: String, year: Int, month: Int, forceReload: Bool) async {
        // 1. Charger depuis le cache persistant (instantané)
        let result = await activitiesService.getActivitiesForMonthCached(
            userId: userId,
            year: year,
            month: month,
            forceRefresh: forceReload
        )

        completedActivities = result.activities

        // 2. Si les données viennent du cache, rafraîchir en arrière-plan
        if result.fromCache && !forceReload {
            isRefreshing = true
            // Rafraîchir en arrière-plan
            Task {
                let freshActivities = await activitiesService.refreshActivitiesForMonth(
                    userId: userId,
                    year: year,
                    month: month
                )
                // Mettre à jour seulement si on est toujours sur le même mois
                let currentYear = Calendar.current.component(.year, from: currentDate)
                let currentMonth = Calendar.current.component(.month, from: currentDate)
                if currentYear == year && currentMonth == month && !freshActivities.isEmpty {
                    // Éviter re-render si les données sont identiques
                    if !areActivitiesEqual(completedActivities, freshActivities) {
                        completedActivities = freshActivities
                    }
                }
                isRefreshing = false
            }
        }
    }

    // MARK: - Helpers

    /// Compare deux listes d'activités pour éviter les mises à jour inutiles
    private func areActivitiesEqual(_ a: [Activity], _ b: [Activity]) -> Bool {
        guard a.count == b.count else { return false }
        for (activityA, activityB) in zip(a, b) {
            if activityA.id != activityB.id { return false }
        }
        return true
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
        Self.monthYearFormatter.string(from: currentDate).capitalized
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
        Self.selectedDateFormatter.string(from: selectedDate).capitalized
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

    // MARK: - Cycle Plan Support (for WeekPlanView)

    @Published var cyclePlan: CyclePlanData?
    @Published var moveState: SessionMoveState = SessionMoveState()
    @Published var showMoveResult: Bool = false
    @Published var showMoveConfirmation: Bool = false
    @Published var lastMoveWarnings: [MoveWarning] = []

    /// Index de la semaine sélectionnée (0-based)
    var selectedWeekIndex: Int {
        guard let plan = cyclePlan, !plan.weeks.isEmpty else { return 0 }
        // Trouver la semaine contenant la date sélectionnée
        for (index, week) in plan.weeks.enumerated() {
            for session in week.sessions {
                if let sessionDate = session.dateValue,
                   Calendar.current.isDate(sessionDate, inSameDayAs: selectedDate) {
                    return index
                }
            }
        }
        // Par défaut, retourner la semaine courante basée sur la date
        return currentWeekIndexFromDate()
    }

    /// Semaine courante du cycle
    var currentWeek: CycleWeek? {
        guard let plan = cyclePlan, selectedWeekIndex < plan.weeks.count else { return nil }
        return plan.weeks[selectedWeekIndex]
    }

    /// Jours de la semaine courante (Lundi à Dimanche)
    var daysInCurrentWeek: [Date] {
        let calendar = Calendar.current
        // Obtenir le lundi de la semaine de la date sélectionnée
        let weekday = calendar.component(.weekday, from: selectedDate)
        // weekday: 1 = dimanche, 2 = lundi, ..., 7 = samedi
        let daysFromMonday = (weekday + 5) % 7 // Convertir pour que lundi = 0
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: selectedDate) else {
            return []
        }

        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: monday)
        }
    }

    /// Mode déplacement actif
    var isInMoveMode: Bool {
        moveState.isMoving
    }

    /// Sessions du cycle pour la date sélectionnée
    var selectedDateCycleSessions: [CycleSession] {
        cycleSessionsForDate(selectedDate)
    }

    // MARK: - Cycle Methods

    /// Sélectionner la semaine courante (aujourd'hui)
    func selectCurrentWeek() {
        selectedDate = Date()
    }

    /// Sessions du cycle pour une date donnée
    func cycleSessionsForDate(_ date: Date) -> [CycleSession] {
        guard let plan = cyclePlan else { return [] }
        return plan.sessions(for: date)
    }

    /// Vérifie si une date est une cible valide pour le déplacement
    func isValidMoveTarget(date: Date) -> Bool {
        guard let plan = cyclePlan,
              let sourceDate = moveState.sourceDate else { return false }

        // Vérifier que la date est dans la plage du cycle
        guard let range = plan.dateRange else { return false }
        let calendar = Calendar.current

        // La date doit être dans le cycle
        guard date >= range.start && date <= range.end else { return false }

        // La date ne peut pas être la même que la source
        return !calendar.isDate(date, inSameDayAs: sourceDate)
    }

    /// Définir la date cible pour le déplacement
    func setMoveTarget(date: Date) {
        moveState.setTarget(date: date)
    }

    /// Préparer la confirmation de déplacement
    func prepareMoveConfirmation() {
        guard moveState.sourceDate != nil && moveState.targetDate != nil else { return }
        showMoveConfirmation = true
    }

    /// Annuler le déplacement en cours
    func cancelSessionMove() {
        moveState.reset()
        showMoveConfirmation = false
    }

    /// Démarrer le déplacement d'une session
    func startSessionMove(session: CycleSession, from date: Date) {
        moveState.startMove(session: session, from: date)
    }

    /// Fermer le résultat du déplacement
    func dismissMoveResult() {
        showMoveResult = false
        lastMoveWarnings = []
    }

    /// Exécuter le déplacement de la session
    func executeSessionMove(userId: String) async {
        guard let sourceDate = moveState.sourceDate,
              let targetDate = moveState.targetDate,
              let plan = cyclePlan else {
            moveState.error = "Données manquantes pour le déplacement"
            return
        }

        moveState.isLoading = true
        moveState.error = nil

        // TODO: Implémenter l'appel API réel pour déplacer la session
        // Pour l'instant, simulation d'un délai
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s

        // Simuler un succès
        moveState.isLoading = false
        lastMoveWarnings = moveState.previewWarnings
        showMoveResult = true
        showMoveConfirmation = false
        moveState.reset()

        // Recharger les données du cycle
        await loadCyclePlan(userId: userId)
    }

    // MARK: - Private Helpers

    private func currentWeekIndexFromDate() -> Int {
        guard let plan = cyclePlan, let range = plan.dateRange else { return 0 }
        let calendar = Calendar.current

        // Calculer le nombre de semaines depuis le début du cycle
        let components = calendar.dateComponents([.weekOfYear], from: range.start, to: selectedDate)
        let weekOffset = components.weekOfYear ?? 0

        return min(max(0, weekOffset), plan.weeks.count - 1)
    }

    // MARK: - Load Cycle Plan

    func loadCyclePlan(userId: String) async {
        do {
            cyclePlan = try await cycleService.getLatestCycle(userId: userId)

            #if DEBUG
            if let plan = cyclePlan {
                print("✅ CyclePlan loaded: \(plan.cycleName) - \(plan.weeks.count) weeks")
            } else {
                print("ℹ️ No cycle plan available")
            }
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to load cycle plan: \(error)")
            #endif
            cyclePlan = nil
        }
    }

    // MARK: - Execute Session Move (Real API)

    func executeSessionMoveAPI(userId: String) async {
        guard let sourceDate = moveState.sourceDate,
              let targetDate = moveState.targetDate,
              let plan = cyclePlan else {
            moveState.error = "Données manquantes pour le déplacement"
            return
        }

        moveState.isLoading = true
        moveState.error = nil

        do {
            let response = try await cycleService.moveSession(
                cycleTag: plan.cycleTag,
                sourceDate: sourceDate,
                targetDate: targetDate
            )

            if response.success {
                lastMoveWarnings = response.warnings
                showMoveResult = true
                showMoveConfirmation = false
                moveState.reset()

                // Recharger les données du cycle
                await loadCyclePlan(userId: userId)
            } else {
                moveState.error = response.errorMessage ?? "Échec du déplacement"
            }
        } catch {
            moveState.error = "Erreur: \(error.localizedDescription)"
        }

        moveState.isLoading = false
    }
}
