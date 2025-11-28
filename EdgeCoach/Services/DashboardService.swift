/**
 * Service Dashboard
 * Récupère le résumé hebdomadaire et les statistiques
 * Aligné avec l'API backend Flask
 */

import Foundation

// MARK: - Dashboard Service

@MainActor
class DashboardService {
    static let shared = DashboardService()
    private let api = APIService.shared

    private init() {}

    // MARK: - Weekly Summary

    func getWeeklySummary(userId: String, weekStart: String? = nil) async throws -> WeeklySummaryData {
        var params: [String: String] = ["user_id": userId]
        if let weekStart = weekStart {
            params["week_start"] = weekStart
        }

        do {
            let response: APIWeeklySummaryResponse = try await api.get(
                "/dashboard/weekly-summary",
                queryParams: params
            )
            return WeeklySummaryData.from(api: response.data)
        } catch APIError.httpError(404, _) {
            // Endpoint doesn't exist yet, return empty data
            return WeeklySummaryData.empty()
        } catch APIError.notFound {
            return WeeklySummaryData.empty()
        }
    }

    // MARK: - Sessions by Discipline

    func getSessionsByDiscipline(
        userId: String,
        discipline: Discipline,
        weekStart: String? = nil
    ) async throws -> [APISessionDetail] {
        var params: [String: String] = [
            "user_id": userId,
            "discipline": discipline.rawValue
        ]
        if let weekStart = weekStart {
            params["week_start"] = weekStart
        }

        let response: APISessionsByDisciplineResponse = try await api.get(
            "/dashboard/sessions",
            queryParams: params
        )

        return response.data.sessions
    }

    // MARK: - Formatting Helpers

    func formatDuration(_ seconds: Int) -> String {
        if seconds == 0 { return "0h" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h\(String(format: "%02d", minutes))" : "\(hours)h"
        }
        return "\(minutes)min"
    }

    func formatDistance(_ meters: Double, discipline: Discipline? = nil) -> String {
        if meters == 0 { return "0 km" }

        // Natation en mètres si < 10km
        if discipline == .natation && meters < 10000 {
            return "\(Int(meters)) m"
        }

        // Autres sports en km
        let km = meters / 1000
        return km.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(km)) km" : String(format: "%.1f km", km)
    }

    func getDisciplineName(_ discipline: Discipline) -> String {
        return discipline.displayName
    }

    func getDisciplineIcon(_ discipline: Discipline) -> String {
        return discipline.icon
    }
}
