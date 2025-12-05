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
                if case .httpError(let code, let message) = apiError {
                    if code == 404 { return [] }
                    
                    if message?.contains("Aucun plan") == true || message?.contains("No training plan") == true {
                        return []
                    }
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

    /// Génère un nouveau plan d'entraînement (legacy)
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

    // MARK: - Generate Plan with Structured Objectives

    struct GeneratePlanWithObjectivesRequest: Codable {
        let userId: String
        let sport: String
        let experienceLevel: String
        let objectives: [[String: Any]]
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
            case durationWeeks = "duration_weeks"
            case startDate = "start_date"
            case weeklyHours = "weekly_hours"
            case constraints
            case unavailableDays = "unavailable_days"
            case language
        }

        // Custom encoding pour gérer [[String: Any]]
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(userId, forKey: .userId)
            try container.encode(sport, forKey: .sport)
            try container.encode(experienceLevel, forKey: .experienceLevel)
            try container.encode(durationWeeks, forKey: .durationWeeks)
            try container.encode(startDate, forKey: .startDate)
            try container.encode(weeklyHours, forKey: .weeklyHours)
            try container.encodeIfPresent(constraints, forKey: .constraints)
            try container.encodeIfPresent(unavailableDays, forKey: .unavailableDays)
            try container.encode(language, forKey: .language)
            // objectives sera géré manuellement dans la requête
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            userId = try container.decode(String.self, forKey: .userId)
            sport = try container.decode(String.self, forKey: .sport)
            experienceLevel = try container.decode(String.self, forKey: .experienceLevel)
            durationWeeks = try container.decode(Int.self, forKey: .durationWeeks)
            startDate = try container.decode(String.self, forKey: .startDate)
            weeklyHours = try container.decode(Int.self, forKey: .weeklyHours)
            constraints = try container.decodeIfPresent(String.self, forKey: .constraints)
            unavailableDays = try container.decodeIfPresent([String].self, forKey: .unavailableDays)
            language = try container.decode(String.self, forKey: .language)
            objectives = []
        }

        init(
            userId: String,
            sport: String,
            experienceLevel: String,
            objectives: [[String: Any]],
            durationWeeks: Int,
            startDate: String,
            weeklyHours: Int,
            constraints: String?,
            unavailableDays: [String]?,
            language: String
        ) {
            self.userId = userId
            self.sport = sport
            self.experienceLevel = experienceLevel
            self.objectives = objectives
            self.durationWeeks = durationWeeks
            self.startDate = startDate
            self.weeklyHours = weeklyHours
            self.constraints = constraints
            self.unavailableDays = unavailableDays
            self.language = language
        }
    }

    /// Génère un nouveau plan d'entraînement avec objectifs structurés
    /// Format aligné avec le backend Python
    func generatePlanWithObjectives(
        userId: String,
        sport: String,
        experienceLevel: String,
        objectives: [[String: Any]],
        durationWeeks: Int,
        startDate: Date,
        weeklyHours: Int,
        constraints: String?,
        unavailableDays: [String]?,
        softConstraintsText: String?,
        perSportSessions: [String: Int]?
    ) async throws -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Plan config
        var planConfig: [String: Any] = [
            "start_date": formatter.string(from: startDate),
            "weekly_time_available": weeklyHours
        ]

        if let constraints = constraints, !constraints.isEmpty {
            planConfig["constraints"] = constraints
        }

        if let perSportSessions = perSportSessions {
            planConfig["per_sport_sessions"] = perSportSessions
        }

        // Soft constraints (format structuré)
        var softConstraints: [String: Any] = [
            "max_sessions_per_week": 8,
            "no_doubles": false
        ]

        if let unavailableDays = unavailableDays, !unavailableDays.isEmpty {
            softConstraints["unavailable_days"] = unavailableDays.map { $0.lowercased() }
        }

        // Valeurs par défaut pour les jours préférés
        softConstraints["preferred_easy_days"] = ["tuesday", "friday"]
        softConstraints["preferred_long_workout_days"] = ["saturday", "sunday"]

        // Athlete profile
        let athleteProfile: [String: Any] = [
            "sport": sport,
            "level": experienceLevel,
            "plan_config": planConfig,
            "soft_constraints": softConstraints
        ]

        // Options
        let options: [String: Any] = [
            "use_coordinator": true,
            "language": "fr"
        ]

        // Body final
        let body: [String: Any] = [
            "user_id": userId,
            "athlete_profile": athleteProfile,
            "objectives": objectives,
            "options": options
        ]

        #if DEBUG
        if let jsonData = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 Plan generation request:\n\(jsonString)")
        }
        #endif

        let response: GeneratePlanResponse = try await api.postRaw("/plans/generate", body: body)

        if response.success == true, let planId = response.planId {
            return planId
        }

        throw APIError.httpError(400, response.message ?? "Erreur lors de la génération du plan")
    }
}
