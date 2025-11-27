/**
 * Service Plans
 * Gestion des plans d'entraînement et séances prévues
 * Compatible avec le frontend TypeScript
 */

import Foundation

// MARK: - Plans Service

@MainActor
class PlansService {
    static let shared = PlansService()
    private let api = APIService.shared

    private init() {}

    // MARK: - Get Last Plan

    /// Récupère le dernier plan d'entraînement de l'utilisateur
    /// L'API peut retourner soit directement TrainingPlanData, soit une structure avec cycle
    func getLastPlan(userId: String) async throws -> [PlannedSession] {
        do {
            // D'abord essayer le format direct (comme dans le frontend TypeScript)
            let planData: TrainingPlanData = try await api.get(
                "/plans/last",
                queryParams: ["user_id": userId]
            )

            #if DEBUG
            print("✅ Plans loaded successfully: \(planData.plannedSessions.count) sessions")
            #endif

            return planData.plannedSessions

        } catch {
            // Si ça échoue, essayer le format avec cycle
            do {
                let response: TrainingPlanResponse = try await api.get(
                    "/plans/last",
                    queryParams: ["user_id": userId]
                )

                guard let planData = response.cycle else {
                    #if DEBUG
                    print("⚠️ No cycle in response")
                    #endif
                    return []
                }

                #if DEBUG
                print("✅ Plans loaded via cycle: \(planData.plannedSessions.count) sessions")
                #endif

                return planData.plannedSessions

            } catch APIError.notFound {
                return []
            } catch let apiError as APIError {
                if case .httpError(_, let message) = apiError,
                   message?.contains("Aucun plan") == true || message?.contains("No training plan") == true {
                    return []
                }

                #if DEBUG
                print("❌ Plans error: \(apiError)")
                #endif
                throw apiError
            } catch {
                #if DEBUG
                print("❌ Plans error: \(error)")
                #endif
                throw error
            }
        }
    }

    // MARK: - Filter by Month

    /// Filtre les sessions par mois (mois 1-indexed comme dans Calendar)
    func filterByMonth(_ sessions: [PlannedSession], year: Int, month: Int) -> [PlannedSession] {
        return sessions.filter { session in
            guard let date = session.dateValue else { return false }
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month], from: date)
            return components.year == year && components.month == month
        }
    }

    // MARK: - Group by Date

    /// Groupe les sessions par date (format YYYY-MM-DD)
    func groupByDate(_ sessions: [PlannedSession]) -> [String: [PlannedSession]] {
        return Dictionary(grouping: sessions) { session in
            String(session.date.prefix(10)) // Prend YYYY-MM-DD
        }
    }

    // MARK: - Generate Plan

    struct GeneratePlanRequest: Codable {
        let userId: String
        let sport: String
        let experienceLevel: String
        let objectives: [String]
        let customObjective: String?
        let durationWeeks: Int
        let startDate: String
        let weeklyHours: Int
        let constraints: String?
        let unavailableDays: [String]?
        let language: String

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case sport
            case experienceLevel = "experience_level"
            case objectives
            case customObjective = "custom_objective"
            case durationWeeks = "duration_weeks"
            case startDate = "start_date"
            case weeklyHours = "weekly_hours"
            case constraints
            case unavailableDays = "unavailable_days"
            case language
        }
    }

    struct GeneratePlanResponse: Codable {
        let success: Bool?
        let message: String?
        let planId: String?

        enum CodingKeys: String, CodingKey {
            case success
            case message
            case planId = "plan_id"
        }
    }

    /// Génère un nouveau plan d'entraînement
    func generatePlan(
        userId: String,
        sport: String,
        experienceLevel: String,
        objectives: [String],
        customObjective: String?,
        durationWeeks: Int,
        startDate: Date,
        weeklyHours: Int,
        constraints: String?,
        unavailableDays: [String]?
    ) async throws -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let request = GeneratePlanRequest(
            userId: userId,
            sport: sport,
            experienceLevel: experienceLevel,
            objectives: objectives,
            customObjective: customObjective,
            durationWeeks: durationWeeks,
            startDate: formatter.string(from: startDate),
            weeklyHours: weeklyHours,
            constraints: constraints,
            unavailableDays: unavailableDays,
            language: "fr"
        )

        let response: GeneratePlanResponse = try await api.post("/plans/generate", body: request)

        if response.success == true, let planId = response.planId {
            return planId
        }

        throw APIError.httpError(400, response.message ?? "Erreur lors de la génération du plan")
    }
}
