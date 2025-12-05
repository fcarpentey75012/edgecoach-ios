/**
 * Modèles pour le Dashboard
 * Alignés avec l'API backend Flask
 */

import Foundation

// MARK: - API Response Wrapper

struct APIWeeklySummaryResponse: Codable {
    let status: String
    let data: APIWeeklySummaryData
}

struct APIWeeklySummaryData: Codable {
    let weekStart: String
    let weekEnd: String
    let summary: APISummary
    let byDiscipline: APIByDiscipline
    let upcomingSessions: [APIUpcomingSession]
    let weekProgress: APIWeekProgress

    enum CodingKeys: String, CodingKey {
        case weekStart = "week_start"
        case weekEnd = "week_end"
        case summary
        case byDiscipline = "by_discipline"
        case upcomingSessions = "upcoming_sessions"
        case weekProgress = "week_progress"
    }
}

struct APISummary: Codable {
    let totalDuration: Int
    let totalDistance: Double
    let sessionsCount: Int
    let totalElevation: Int
    let totalCalories: Int

    enum CodingKeys: String, CodingKey {
        case totalDuration = "total_duration"
        case totalDistance = "total_distance"
        case sessionsCount = "sessions_count"
        case totalElevation = "total_elevation"
        case totalCalories = "total_calories"
    }
}

struct APIByDiscipline: Codable {
    let cyclisme: APIDisciplineStats
    let course: APIDisciplineStats
    let natation: APIDisciplineStats
    let autre: APIDisciplineStats
}

struct APIDisciplineStats: Codable {
    let count: Int
    let duration: Int
    let distance: Double
}

struct APIUpcomingSession: Codable {
    let id: String
    let date: String
    let sport: String
    let name: String
    let duration: Int
    let distance: Double?
}

struct APIWeekProgress: Codable {
    let targetDuration: Int
    let achievedDuration: Int
    let percentage: Double

    enum CodingKeys: String, CodingKey {
        case targetDuration = "target_duration"
        case achievedDuration = "achieved_duration"
        case percentage
    }
}

// MARK: - Frontend Models

struct WeeklySummaryData {
    let weekStart: String
    let weekEnd: String
    let summary: WeeklySummary
    let byDiscipline: ByDiscipline
    let upcomingSessions: [UpcomingSession]
    let weekProgress: WeekProgress
}

struct WeeklySummary {
    let totalDuration: Int // en secondes
    let totalDistance: Double // en mètres
    let sessionsCount: Int
    let totalElevation: Int
    let totalCalories: Int

    var formattedDuration: String {
        if totalDuration == 0 { return "0h" }
        let hours = totalDuration / 3600
        let minutes = (totalDuration % 3600) / 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h\(String(format: "%02d", minutes))" : "\(hours)h"
        }
        return "\(minutes)min"
    }

    var formattedDistance: String {
        if totalDistance == 0 { return "0 km" }
        let km = totalDistance / 1000
        return km.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(km)) km" : String(format: "%.1f km", km)
    }
}

struct ByDiscipline {
    let cyclisme: DisciplineStat
    let course: DisciplineStat
    let natation: DisciplineStat
    let autre: DisciplineStat
}

struct DisciplineStat {
    let count: Int
    let duration: Int // en secondes
    let distance: Double // en mètres

    var formattedDuration: String {
        if duration == 0 { return "0h" }
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h\(String(format: "%02d", minutes))" : "\(hours)h"
        }
        return "\(minutes)min"
    }
}

struct UpcomingSession: Identifiable {
    let id: String
    let date: String
    let sport: String
    let name: String
    let duration: Int // en minutes
    let distance: Double? // en mètres

    var discipline: Discipline {
        switch sport.lowercased() {
        case "cyclisme", "vélo", "cycling", "vélo - route", "vélo - home trainer":
            return .cyclisme
        case "course", "course à pied", "running":
            return .course
        case "natation", "swimming":
            return .natation
        default:
            return .autre
        }
    }

    var parsedDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: date) ?? Date()
    }

    var formattedDuration: String {
        let hours = duration / 60
        let minutes = duration % 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h\(String(format: "%02d", minutes))" : "\(hours)h"
        }
        return "\(minutes)min"
    }

    var formattedDistance: String? {
        guard let distance = distance, distance > 0 else { return nil }
        if discipline == .natation && distance < 10000 {
            return "\(Int(distance)) m"
        }
        let km = distance / 1000
        return km.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(km)) km" : String(format: "%.1f km", km)
    }
}

struct WeekProgress {
    let targetDuration: Int // en secondes
    let achievedDuration: Int // en secondes
    let percentage: Double
}

// MARK: - Sessions by Discipline Response

struct APISessionsByDisciplineResponse: Codable {
    let status: String
    let data: APISessionsByDisciplineData
}

struct APISessionsByDisciplineData: Codable {
    let weekStart: String
    let weekEnd: String
    let discipline: String
    let sessions: [APISessionDetail]
    let count: Int

    enum CodingKeys: String, CodingKey {
        case weekStart = "week_start"
        case weekEnd = "week_end"
        case discipline
        case sessions
        case count
    }
}

struct APISessionDetail: Codable, Identifiable {
    let id: String
    let date: String
    let sport: String
    let discipline: String
    let name: String
    let duration: Int // en secondes
    let distance: Double // en mètres
    let elevation: Int
    let calories: Int
    let avgHr: Int?
    let avgPower: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case sport
        case discipline
        case name
        case duration
        case distance
        case elevation
        case calories
        case avgHr = "avg_hr"
        case avgPower = "avg_power"
    }
}

// MARK: - Conversion Helpers

extension WeeklySummaryData {
    static func from(api: APIWeeklySummaryData) -> WeeklySummaryData {
        return WeeklySummaryData(
            weekStart: api.weekStart,
            weekEnd: api.weekEnd,
            summary: WeeklySummary(
                totalDuration: api.summary.totalDuration,
                totalDistance: api.summary.totalDistance,
                sessionsCount: api.summary.sessionsCount,
                totalElevation: api.summary.totalElevation,
                totalCalories: api.summary.totalCalories
            ),
            byDiscipline: ByDiscipline(
                cyclisme: DisciplineStat(count: api.byDiscipline.cyclisme.count, duration: api.byDiscipline.cyclisme.duration, distance: api.byDiscipline.cyclisme.distance),
                course: DisciplineStat(count: api.byDiscipline.course.count, duration: api.byDiscipline.course.duration, distance: api.byDiscipline.course.distance),
                natation: DisciplineStat(count: api.byDiscipline.natation.count, duration: api.byDiscipline.natation.duration, distance: api.byDiscipline.natation.distance),
                autre: DisciplineStat(count: api.byDiscipline.autre.count, duration: api.byDiscipline.autre.duration, distance: api.byDiscipline.autre.distance)
            ),
            upcomingSessions: api.upcomingSessions.map { session in
                UpcomingSession(
                    id: session.id,
                    date: session.date,
                    sport: session.sport,
                    name: session.name,
                    duration: session.duration,
                    distance: session.distance
                )
            },
            weekProgress: WeekProgress(
                targetDuration: api.weekProgress.targetDuration,
                achievedDuration: api.weekProgress.achievedDuration,
                percentage: api.weekProgress.percentage
            )
        )
    }


    static func empty() -> WeeklySummaryData {
        let today = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: today)
        let daysToMonday = weekday == 1 ? -6 : -(weekday - 2)
        let monday = calendar.date(byAdding: .day, value: daysToMonday, to: today)!
        let sunday = calendar.date(byAdding: .day, value: 6, to: monday)!

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return WeeklySummaryData(
            weekStart: formatter.string(from: monday),
            weekEnd: formatter.string(from: sunday),
            summary: WeeklySummary(totalDuration: 0, totalDistance: 0, sessionsCount: 0, totalElevation: 0, totalCalories: 0),
            byDiscipline: ByDiscipline(
                cyclisme: DisciplineStat(count: 0, duration: 0, distance: 0),
                course: DisciplineStat(count: 0, duration: 0, distance: 0),
                natation: DisciplineStat(count: 0, duration: 0, distance: 0),
                autre: DisciplineStat(count: 0, duration: 0, distance: 0)
            ),
            upcomingSessions: [],
            weekProgress: WeekProgress(targetDuration: 0, achievedDuration: 0, percentage: 0)
        )
    }
}

// MARK: - Dashboard Customization Models

enum DashboardTimeScope: String, CaseIterable, Codable, Identifiable {
    case week = "Semaine"
    case month = "Mois"
    case year = "Année"

    var id: String { rawValue }
}

enum DashboardMetric: String, CaseIterable, Codable, Identifiable {
    case volume = "Volume"
    case distance = "Distance"
    case sessions = "Séances"
    case elevation = "Dénivelé"
    case calories = "Calories"
    // Performance metrics
    case performanceRunning = "Perf. Course"
    case performanceCycling = "Perf. Cyclisme"
    case performanceSwimming = "Perf. Natation"
    // case ctl = "Forme (CTL)" // À activer quand le calcul CTL sera prêt
    // case weight = "Poids"    // À activer quand le service UserMetrics sera prêt

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .volume: return "clock"
        case .distance: return "map"
        case .sessions: return "figure.run"
        case .elevation: return "mountain.2"
        case .calories: return "flame"
        case .performanceRunning: return "figure.run"
        case .performanceCycling: return "figure.outdoor.cycle"
        case .performanceSwimming: return "figure.pool.swim"
        }
    }

    var unit: String {
        switch self {
        case .volume: return "h"
        case .distance: return "km"
        case .sessions: return ""
        case .elevation: return "m"
        case .calories: return "kcal"
        case .performanceRunning: return ""
        case .performanceCycling: return ""
        case .performanceSwimming: return ""
        }
    }

    /// Indique si cette métrique est une card de performance (affichage spécial)
    var isPerformanceCard: Bool {
        switch self {
        case .performanceRunning, .performanceCycling, .performanceSwimming:
            return true
        default:
            return false
        }
    }
}

struct DashboardPreferences: Codable {
    var timeScope: DashboardTimeScope = .week
    var selectedMetrics: [DashboardMetric] = [.volume, .distance, .sessions]

    // Nouvelles préférences pour la KPI Summary Card
    var kpiTimeScope: DashboardTimeScope = .week
    var selectedKPIMetrics: [KPIMetricType] = [.volume, .distance, .sessions]
}

// MARK: - Widget Configuration Types

/// Configuration pour la KPI Summary Card
struct KPISummaryConfig: Codable {
    var timeScope: DashboardTimeScope = .week
    var selectedMetrics: [KPIMetricType] = [.volume, .distance, .sessions]
}

/// Configuration pour le widget Performance
struct PerformanceWidgetConfig: Codable {
    var showRunning: Bool = true
    var showCycling: Bool = true
    var showSwimming: Bool = true
}

/// Configuration pour le widget Week Progress
struct WeekProgressConfig: Codable {
    var isVisible: Bool = true
}

/// Configuration pour le widget Sports Breakdown
struct SportsBreakdownConfig: Codable {
    var showCyclisme: Bool = true
    var showCourse: Bool = true
    var showNatation: Bool = true
    var showAutre: Bool = true
}

/// Configuration pour le widget Planned Sessions
struct PlannedSessionsConfig: Codable {
    var maxItems: Int = 5

    static let itemOptions = [3, 5, 10]
}

/// Configuration pour le widget Upcoming Sessions
struct UpcomingSessionsConfig: Codable {
    var maxItems: Int = 5

    static let itemOptions = [3, 5, 10]
}

/// Configuration pour le widget Recent Activities
struct RecentActivitiesConfig: Codable {
    var maxItems: Int = 5

    static let itemOptions = [3, 5, 10]
}

/// Configuration d'un widget individuel
struct DashboardWidgetConfig: Codable, Identifiable, Equatable {
    let type: DashboardWidgetType
    var isEnabled: Bool
    var order: Int

    var id: String { type.rawValue }

    init(type: DashboardWidgetType, isEnabled: Bool = true, order: Int = 0) {
        self.type = type
        self.isEnabled = isEnabled
        self.order = order
    }
}

/// Préférences globales des widgets du dashboard
struct DashboardWidgetsPreferences: Codable {
    var widgets: [DashboardWidgetConfig]
    var kpiConfig: KPISummaryConfig
    var performanceConfig: PerformanceWidgetConfig
    var weekProgressConfig: WeekProgressConfig
    var sportsBreakdownConfig: SportsBreakdownConfig
    var plannedSessionsConfig: PlannedSessionsConfig
    var upcomingSessionsConfig: UpcomingSessionsConfig
    var recentActivitiesConfig: RecentActivitiesConfig

    /// Widgets actifs triés par ordre
    var enabledWidgets: [DashboardWidgetConfig] {
        widgets
            .filter { $0.isEnabled }
            .sorted { $0.order < $1.order }
    }

    /// Configuration par défaut
    static var `default`: DashboardWidgetsPreferences {
        DashboardWidgetsPreferences(
            widgets: DashboardWidgetType.allCases.enumerated().map { index, type in
                DashboardWidgetConfig(
                    type: type,
                    isEnabled: DashboardWidgetType.defaultWidgets.contains(type),
                    order: index
                )
            },
            kpiConfig: KPISummaryConfig(),
            performanceConfig: PerformanceWidgetConfig(),
            weekProgressConfig: WeekProgressConfig(),
            sportsBreakdownConfig: SportsBreakdownConfig(),
            plannedSessionsConfig: PlannedSessionsConfig(),
            upcomingSessionsConfig: UpcomingSessionsConfig(),
            recentActivitiesConfig: RecentActivitiesConfig()
        )
    }
}

// MARK: - KPI Metric Type (pour la KPI Summary Card)

enum KPIMetricType: String, CaseIterable, Codable, Identifiable {
    case volume = "Volume"
    case distance = "Distance"
    case sessions = "Séances"
    case elevation = "Dénivelé"
    case calories = "Calories"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .volume: return "clock"
        case .distance: return "map"
        case .sessions: return "figure.run"
        case .elevation: return "mountain.2"
        case .calories: return "flame"
        }
    }

    var unit: String {
        switch self {
        case .volume: return "h"
        case .distance: return "km"
        case .sessions: return ""
        case .elevation: return "m"
        case .calories: return "kcal"
        }
    }
}
