/**
 * ViewModel pour le Dashboard
 */

import SwiftUI
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var weeklySummaryData: WeeklySummaryData?
    @Published var recentActivities: [Activity] = []
    @Published var plannedSessions: [PlannedSession] = []
    @Published var performanceReport: PerformanceReport?
    // @Published var trainingLoad: TrainingLoad? // TODO: Implement TrainingLoad model
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var error: String?

    // MARK: - Cached computed values (évite recalculs répétés)
    @Published private(set) var cachedHasCyclisme: Bool = false
    @Published private(set) var cachedHasCourse: Bool = false
    @Published private(set) var cachedHasNatation: Bool = false
    @Published private(set) var cachedHasAutre: Bool = false
    @Published private(set) var cachedHasAnySport: Bool = false

    // MARK: - Cache pour éviter rechargements inutiles
    private var lastLoadedUserId: String?
    private var lastLoadTime: Date?
    private let cacheValidityDuration: TimeInterval = 60 // 60 secondes

    // MARK: - Debounce pour sauvegarde préférences
    private var savePreferencesTask: Task<Void, Never>?
    private let saveDebounceDelay: UInt64 = 500_000_000 // 0.5 secondes en nanosecondes

    // MARK: - Preferences (anciennes, à migrer)

    @Published var preferences: DashboardPreferences {
        didSet {
            debouncedSavePreferences()
        }
    }

    // MARK: - Widget Preferences (nouvelles)

    @Published var widgetPreferences: DashboardWidgetsPreferences {
        didSet {
            debouncedSaveWidgetPreferences()
        }
    }

    // MARK: - Services

    private let dashboardService = DashboardService.shared
    private let activitiesService = ActivitiesService.shared
    private let plansService = PlansService.shared
    private let api = APIService.shared
    // private let userMetricsService = UserMetricsService.shared // TODO: Implement UserMetricsService

    // MARK: - Static DateFormatter (évite création répétée)
    private static let weekStartFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    // MARK: - Initialization

    init() {
        // Charger les anciennes préférences
        if let data = UserDefaults.standard.data(forKey: "dashboard_preferences"),
           let decoded = try? JSONDecoder().decode(DashboardPreferences.self, from: data) {
            self.preferences = decoded
        } else {
            self.preferences = DashboardPreferences()
        }

        // Charger les nouvelles préférences de widgets
        if let data = UserDefaults.standard.data(forKey: "dashboard_widgets_preferences"),
           let decoded = try? JSONDecoder().decode(DashboardWidgetsPreferences.self, from: data) {
            self.widgetPreferences = decoded
        } else {
            self.widgetPreferences = .default
        }
    }
    
    private func debouncedSavePreferences() {
        // Annuler la tâche précédente si elle existe
        savePreferencesTask?.cancel()

        // Créer une nouvelle tâche avec délai
        savePreferencesTask = Task {
            do {
                try await Task.sleep(nanoseconds: saveDebounceDelay)
                // Vérifier que la tâche n'a pas été annulée
                if !Task.isCancelled {
                    savePreferencesImmediately()
                }
            } catch {
                // Task was cancelled, ignore
            }
        }
    }

    private func savePreferencesImmediately() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "dashboard_preferences")
            #if DEBUG
            print("✅ [Dashboard] Préférences sauvegardées")
            #endif
        }
    }

    // MARK: - Widget Preferences Save

    private var saveWidgetPreferencesTask: Task<Void, Never>?

    private func debouncedSaveWidgetPreferences() {
        saveWidgetPreferencesTask?.cancel()
        saveWidgetPreferencesTask = Task {
            do {
                try await Task.sleep(nanoseconds: saveDebounceDelay)
                if !Task.isCancelled {
                    saveWidgetPreferencesImmediately()
                }
            } catch {
                // Task cancelled
            }
        }
    }

    private func saveWidgetPreferencesImmediately() {
        if let encoded = try? JSONEncoder().encode(widgetPreferences) {
            UserDefaults.standard.set(encoded, forKey: "dashboard_widgets_preferences")
            #if DEBUG
            print("✅ [Dashboard] Widget preferences sauvegardées")
            #endif
        }
    }

    // MARK: - Widget Helpers

    func isWidgetEnabled(_ type: DashboardWidgetType) -> Bool {
        widgetPreferences.widgets.first { $0.type == type }?.isEnabled ?? false
    }

    func enabledWidgetTypes() -> [DashboardWidgetType] {
        widgetPreferences.enabledWidgets.map { $0.type }
    }

    // MARK: - Load Data

    func loadData(userId: String, forceRefresh: Bool = false) async {
        // Vérifier si le cache est encore valide
        if !forceRefresh,
           lastLoadedUserId == userId,
           let lastLoad = lastLoadTime,
           Date().timeIntervalSince(lastLoad) < cacheValidityDuration,
           weeklySummaryData != nil {
            // Cache valide, pas besoin de recharger
            return
        }

        isLoading = true
        error = nil

        await withTaskGroup(of: Void.self) { group in
            // Load weekly summary
            group.addTask {
                await self.loadWeeklySummary(userId: userId)
            }

            // Load recent activities
            group.addTask {
                await self.loadRecentActivities(userId: userId)
            }

            // Load planned sessions
            group.addTask {
                await self.loadPlannedSessions(userId: userId)
            }

            // Load performance report (for performance cards)
            group.addTask {
                await self.loadPerformanceReport(userId: userId)
            }

            // Load training load
            // group.addTask {
            //     await self.loadTrainingLoad(userId: userId)
            // }
        }

        // Mettre à jour les valeurs cachées après le chargement
        updateCachedSportFlags()

        // Marquer le cache comme valide
        lastLoadedUserId = userId
        lastLoadTime = Date()

        isLoading = false
    }

    // MARK: - Update Cached Sport Flags

    private func updateCachedSportFlags() {
        cachedHasCyclisme = (byDiscipline?.cyclisme.count ?? 0) > 0
        cachedHasCourse = (byDiscipline?.course.count ?? 0) > 0
        cachedHasNatation = (byDiscipline?.natation.count ?? 0) > 0
        cachedHasAutre = (byDiscipline?.autre.count ?? 0) > 0
        cachedHasAnySport = cachedHasCyclisme || cachedHasCourse || cachedHasNatation || cachedHasAutre
    }

    // MARK: - Refresh

    func refresh(userId: String) async {
        isRefreshing = true
        await loadData(userId: userId, forceRefresh: true) // Force refresh bypass le cache
        isRefreshing = false
    }

    // MARK: - Load Weekly Summary

    private func loadWeeklySummary(userId: String) async {
        do {
            weeklySummaryData = try await dashboardService.getWeeklySummary(userId: userId)
        } catch {
            #if DEBUG
            print("Failed to load weekly summary: \(error)")
            #endif
            // Use empty data on error
            weeklySummaryData = WeeklySummaryData.empty()
        }
    }

    // MARK: - Load Recent Activities

    private func loadRecentActivities(userId: String) async {
        do {
            // Charger les activités des 90 derniers jours
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -90, to: endDate) ?? endDate

            recentActivities = try await activitiesService.getHistory(
                userId: userId,
                startDate: startDate,
                endDate: endDate,
                limit: 5
            )
        } catch {
            // Erreur silencieuse - les activités restent vides
        }
    }

    // MARK: - Load Planned Sessions

    private func loadPlannedSessions(userId: String) async {
        do {
            let allSessions = try await plansService.getLastPlan(userId: userId)
            // Filtrer pour ne garder que les séances futures (à partir d'aujourd'hui)
            let today = Calendar.current.startOfDay(for: Date())
            plannedSessions = allSessions
                .filter { session in
                    guard let sessionDate = session.dateValue else { return false }
                    return sessionDate >= today
                }
                .sorted { s1, s2 in
                    guard let d1 = s1.dateValue, let d2 = s2.dateValue else { return false }
                    return d1 < d2
                }
                .prefix(5)
                .map { $0 }

            #if DEBUG
            print("✅ Loaded \(plannedSessions.count) upcoming planned sessions")
            #endif
        } catch {
            #if DEBUG
            print("Failed to load planned sessions: \(error)")
            #endif
        }
    }
    
    // MARK: - Load Performance Report

    private func loadPerformanceReport(userId: String) async {
        do {
            performanceReport = try await api.get("/users/\(userId)/performance-report")
            #if DEBUG
            print("✅ [Dashboard] Loaded performance report")
            #endif
        } catch {
            #if DEBUG
            print("Failed to load performance report: \(error)")
            #endif
            // Erreur silencieuse - le rapport reste nil
        }
    }

    // MARK: - Load Training Load

    // TODO: Implement when UserMetricsService and TrainingLoad are available
    // private func loadTrainingLoad(userId: String) async {
    //     do {
    //         trainingLoad = try await userMetricsService.getAggregatedMetrics(userId: userId)
    //     } catch {
    //         #if DEBUG
    //         print("Failed to load training load: \(error)")
    //         #endif
    //     }
    // }

    // MARK: - Computed Properties

    var summary: WeeklySummary? {
        weeklySummaryData?.summary
    }

    var byDiscipline: ByDiscipline? {
        weeklySummaryData?.byDiscipline
    }

    var upcomingSessions: [UpcomingSession] {
        weeklySummaryData?.upcomingSessions ?? []
    }

    var weekProgress: WeekProgress? {
        weeklySummaryData?.weekProgress
    }

    var weekStartDate: Date? {
        guard let weekStart = weeklySummaryData?.weekStart else { return nil }
        return Self.weekStartFormatter.date(from: weekStart)
    }

    // Utiliser les valeurs cachées pour éviter les recalculs
    var hasCyclisme: Bool { cachedHasCyclisme }
    var hasCourse: Bool { cachedHasCourse }
    var hasNatation: Bool { cachedHasNatation }
    var hasAutre: Bool { cachedHasAutre }
    var hasAnySport: Bool { cachedHasAnySport }

    /// Indique si l'utilisateur a un plan d'entraînement
    var hasPlan: Bool {
        !plannedSessions.isEmpty
    }

    // MARK: - Performance Computed Properties

    /// CS/D' disponible (Course à pied)
    var hasRunningPerformance: Bool {
        performanceReport?.metrics.csDprime != nil
    }

    /// CP/W' disponible (Cyclisme)
    var hasCyclingPerformance: Bool {
        performanceReport?.metrics.cpWprime != nil
    }

    /// CSS disponible (Natation)
    var hasSwimmingPerformance: Bool {
        performanceReport?.metrics.css != nil
    }

    /// CS/D' data
    var csDprime: CSDprimeMetric? {
        performanceReport?.metrics.csDprime
    }

    /// CP/W' data
    var cpWprime: CPWprimeMetric? {
        performanceReport?.metrics.cpWprime
    }

    /// CSS data
    var css: CSSMetric? {
        performanceReport?.metrics.css
    }
}
