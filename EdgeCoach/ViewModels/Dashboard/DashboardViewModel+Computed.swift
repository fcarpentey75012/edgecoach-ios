// MARK: - Dashboard ViewModel + Computed Properties

import Foundation

extension DashboardViewModel {
    
    // MARK: - Data Accessors

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
        // Le plan existe si un MacroPlan est chargé OU si on a des sessions planifiées
        macroPlan != nil || !plannedSessions.isEmpty
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
