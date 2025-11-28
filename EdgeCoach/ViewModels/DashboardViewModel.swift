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
    // @Published var trainingLoad: TrainingLoad? // TODO: Implement TrainingLoad model
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var error: String?
    
    // MARK: - Preferences
    
    @Published var preferences: DashboardPreferences {
        didSet {
            savePreferences()
        }
    }

    // MARK: - Services

    private let dashboardService = DashboardService.shared
    private let activitiesService = ActivitiesService.shared
    private let plansService = PlansService.shared
    // private let userMetricsService = UserMetricsService.shared // TODO: Implement UserMetricsService
    
    // MARK: - Initialization
    
    init() {
        // Charger les préférences sauvegardées ou utiliser les défauts
        if let data = UserDefaults.standard.data(forKey: "dashboard_preferences"),
           let decoded = try? JSONDecoder().decode(DashboardPreferences.self, from: data) {
            self.preferences = decoded
        } else {
            self.preferences = DashboardPreferences()
        }
    }
    
    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "dashboard_preferences")
        }
    }

    // MARK: - Load Data

    func loadData(userId: String) async {
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
            
            // Load training load
            // group.addTask {
            //     await self.loadTrainingLoad(userId: userId)
            // }
        }

        isLoading = false
    }

    // MARK: - Refresh

    func refresh(userId: String) async {
        isRefreshing = true
        await loadData(userId: userId) // TODO: Pass preferences.timeScope to services when API supports it
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
            recentActivities = try await activitiesService.getHistory(
                userId: userId,
                limit: 5
            )
        } catch {
            #if DEBUG
            print("Failed to load recent activities: \(error)")
            #endif
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: weekStart)
    }

    var hasCyclisme: Bool {
        (byDiscipline?.cyclisme.count ?? 0) > 0
    }

    var hasCourse: Bool {
        (byDiscipline?.course.count ?? 0) > 0
    }

    var hasNatation: Bool {
        (byDiscipline?.natation.count ?? 0) > 0
    }

    var hasAutre: Bool {
        (byDiscipline?.autre.count ?? 0) > 0
    }

    var hasAnySport: Bool {
        hasCyclisme || hasCourse || hasNatation || hasAutre
    }

    /// Indique si l'utilisateur a un plan d'entraînement
    var hasPlan: Bool {
        !plannedSessions.isEmpty
    }
}
