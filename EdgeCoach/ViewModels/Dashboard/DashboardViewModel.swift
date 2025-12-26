/**
 * ViewModel pour le Dashboard
 * Orchestrateur principal de l'écran d'accueil
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
    @Published var macroPlan: MacroPlanData?
    @Published var pmcStatus: PMCStatus?
    @Published var isPMCLoading: Bool = false
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
    var lastLoadedUserId: String?
    var lastLoadTime: Date?
    let cacheValidityDuration: TimeInterval = 60 // 60 secondes

    // MARK: - Debounce pour sauvegarde préférences
    var savePreferencesTask: Task<Void, Never>?
    let saveDebounceDelay: UInt64 = 500_000_000 // 0.5 secondes en nanosecondes
    var saveWidgetPreferencesTask: Task<Void, Never>?

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

    // MARK: - Services (Internal to be accessible by extensions)

    let dashboardService = DashboardService.shared
    let activitiesService = ActivitiesService.shared
    let plansService = PlansService.shared
    let pmcService = PMCService.shared
    let api = APIService.shared
    // let userMetricsService = UserMetricsService.shared // TODO: Implement UserMetricsService

    // MARK: - Static DateFormatter (évite création répétée)
    static let weekStartFormatter: DateFormatter = {
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
    
    // MARK: - Internal Helpers
    
    func updateCachedSportFlags() {
        cachedHasCyclisme = (byDiscipline?.cyclisme.count ?? 0) > 0
        cachedHasCourse = (byDiscipline?.course.count ?? 0) > 0
        cachedHasNatation = (byDiscipline?.natation.count ?? 0) > 0
        cachedHasAutre = (byDiscipline?.autre.count ?? 0) > 0
        cachedHasAnySport = cachedHasCyclisme || cachedHasCourse || cachedHasNatation || cachedHasAutre
    }
}
