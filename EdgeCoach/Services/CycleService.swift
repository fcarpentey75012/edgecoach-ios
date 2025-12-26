/**
 * Service Cycle
 * Gestion des cycles d'entraînement (2 semaines)
 * Endpoint: GET /api/users/{user_id}/cycles/latest
 */

import Foundation

// MARK: - Cycle Service

@MainActor
class CycleService {
    static let shared = CycleService()
    private let api = APIService.shared

    private init() {}

    // MARK: - Get Latest Cycle

    /// Récupère le dernier cycle d'entraînement de l'utilisateur
    /// - Parameter userId: ID de l'utilisateur
    /// - Returns: CyclePlanData ou nil si aucun cycle
    func getLatestCycle(userId: String) async throws -> CyclePlanData? {
        do {
            let response: CycleResponse = try await api.get(
                "/users/\(userId)/cycles/latest"
            )

            #if DEBUG
            print("✅ Cycle loaded: \(response.cycleTag) - \(response.optimizedPlan?.weeks.count ?? 0) weeks")
            #endif

            return CyclePlanData(from: response)

        } catch APIError.notFound {
            #if DEBUG
            print("ℹ️ No cycle found for user")
            #endif
            return nil

        } catch let apiError as APIError {
            if case .httpError(let code, let message) = apiError {
                if code == 404 { return nil }

                if message?.contains("No cycle") == true ||
                   message?.contains("Aucun cycle") == true {
                    return nil
                }
            }

            #if DEBUG
            print("❌ Cycle error: \(apiError)")
            #endif
            throw apiError
        }
    }

    // MARK: - Move Session

    /// Déplace une session vers une nouvelle date
    /// - Parameters:
    ///   - cycleTag: Tag du cycle (ex: "2024-W49")
    ///   - sourceDate: Date d'origine
    ///   - targetDate: Nouvelle date
    /// - Returns: Résultat du déplacement
    func moveSession(
        cycleTag: String,
        sourceDate: Date,
        targetDate: Date
    ) async throws -> SessionMoveResponse {
        let request = SessionMoveRequest(sourceDate: sourceDate, targetDate: targetDate)

        let response: SessionMoveResponse = try await api.put(
            "/cycles/\(cycleTag)/sessions/move",
            body: request
        )

        #if DEBUG
        if response.success {
            print("✅ Session moved successfully")
        } else {
            print("❌ Session move failed: \(response.errorMessage ?? "Unknown error")")
        }
        #endif

        return response
    }

    // MARK: - Get Plan History

    /// Récupère l'historique des modifications du plan
    /// - Parameter cycleTag: Tag du cycle
    /// - Returns: Historique des modifications
    func getPlanHistory(cycleTag: String) async throws -> PlanHistoryResponse {
        let response: PlanHistoryResponse = try await api.get(
            "/cycles/\(cycleTag)/history"
        )

        return response
    }
}
