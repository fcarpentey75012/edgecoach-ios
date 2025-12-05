/**
 * Service MacroPlan pour EdgeCoach iOS
 * Gestion de la création et récupération des MacroPlans
 */

import Foundation

// MARK: - MacroPlan Service

@MainActor
class MacroPlanService {
    static let shared = MacroPlanService()
    private let api = APIService.shared

    private init() {}

    struct PlanConstraints: Codable {
        var maxSessionsPerWeek: Int
        var maxSessionsPerDay: Int
        var minRestDays: Int

        static var `default`: PlanConstraints {
            PlanConstraints(maxSessionsPerWeek: 7, maxSessionsPerDay: 2, minRestDays: 1)
        }

        var description: String {
            "Max sessions/week: \(maxSessionsPerWeek), Max sessions/day: \(maxSessionsPerDay), Min rest days: \(minRestDays)"
        }
    }

    // MARK: - Create MacroPlan

    /// Crée un nouveau MacroPlan
    func createMacroPlan(request: MacroPlanRequest) async throws -> MacroPlanResponse {
        // MOCK: Return simulated success immediately
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000) // 1s delay
        return MacroPlanResponse(
            status: "success",
            message: "Plan généré (MOCK)",
            planId: "mock-id",
            plan: MacroPlanData.mock
        )
        // return try await api.post("/plans/macro", body: request)
    }

    /// Crée un MacroPlan avec les paramètres individuels
    func createMacroPlan(
        userId: String,
        athleteProfile: AthleteProfile,
        objectives: [RaceObjective],
        options: MacroPlanOptions? = nil
    ) async throws -> MacroPlanResponse {
        let request = MacroPlanRequest(
            userId: userId,
            athleteProfile: athleteProfile,
            objectives: objectives,
            options: options ?? .default
        )
        return try await createMacroPlan(request: request)
    }

    // MARK: - Get MacroPlan

    /// Récupère le dernier MacroPlan de l'utilisateur
    func getLastMacroPlan(userId: String) async throws -> MacroPlanData? {
        // MOCK: Return mock plan immediately
        return MacroPlanData.mock
        
        /*
        struct Response: Decodable {
            let plan: MacroPlanData?
        }
        let response: Response = try await api.get("/users/\(userId)/plans/macro/last")
        return response.plan
        */
    }

    /// Récupère un MacroPlan par son ID
    func getMacroPlan(planId: String) async throws -> MacroPlanData {
        struct Response: Decodable {
            let plan: MacroPlanData
        }
        let response: Response = try await api.get("/plans/macro/\(planId)")
        return response.plan
    }

    /// Liste tous les MacroPlans de l'utilisateur
    func listMacroPlans(userId: String) async throws -> [MacroPlanData] {
        struct Response: Decodable {
            let plans: [MacroPlanData]
        }
        let response: Response = try await api.get("/users/\(userId)/plans/macro")
        return response.plans
    }

    // MARK: - Delete MacroPlan

    /// Supprime un MacroPlan
    func deleteMacroPlan(planId: String) async throws {
        struct Response: Decodable {
            let message: String?
        }
        let _: Response = try await api.delete("/plans/macro/\(planId)")
    }
}

// MARK: - Validation Helpers

extension MacroPlanService {

    /// Valide un profil athlète avant envoi
    func validateAthleteProfile(_ profile: AthleteProfile) -> [String] {
        var errors: [String] = []

        // weeklyTimeAvailable est maintenant en heures
        if profile.planConfig.weeklyTimeAvailable < 1 {
            errors.append("Le temps hebdomadaire doit être d'au moins 1 heure")
        }

        if profile.planConfig.weeklyTimeAvailable > 42 {
            errors.append("Le temps hebdomadaire ne peut pas dépasser 42 heures")
        }

        return errors
    }

    /// Valide un objectif avant envoi
    func validateObjective(_ objective: RaceObjective) -> [String] {
        var errors: [String] = []

        if objective.name.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Le nom de l'objectif est requis")
        }

        if objective.targetDate.isEmpty {
            errors.append("La date cible est requise")
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: objective.targetDate), date < Date() {
                errors.append("La date cible doit être dans le futur")
            }
        }

        return errors
    }

    /// Valide une requête complète
    func validateRequest(_ request: MacroPlanRequest) -> [String] {
        var errors: [String] = []

        errors.append(contentsOf: validateAthleteProfile(request.athleteProfile))

        if request.objectives.isEmpty {
            errors.append("Au moins un objectif est requis")
        }

        for objective in request.objectives {
            errors.append(contentsOf: validateObjective(objective))
        }

        // Vérifier qu'il y a au moins un objectif A
        let hasMainObjective = request.objectives.contains { $0.priority == .principal }
        if !hasMainObjective {
            errors.append("Au moins un objectif principal (A) est requis")
        }

        return errors
    }
}

// MARK: - Request Builder

/// Builder pour construire facilement une requête MacroPlan
class MacroPlanRequestBuilder {
    private var userId: String = ""
    private var sport: MacroPlanSport = .triathlon
    private var level: AthleteLevel = .intermediate
    private var startDate: Date = Date()
    private var weeklyTimeHours: Int = 12  // en heures
    private var perSportSessions: PerSportSessions?
    private var constraintsText: String?
    private var softConstraints: SoftConstraints = .default
    private var objectives: [RaceObjective] = []
    private var options: MacroPlanOptions = .default

    func setUserId(_ id: String) -> MacroPlanRequestBuilder {
        userId = id
        return self
    }

    func setSport(_ sport: MacroPlanSport) -> MacroPlanRequestBuilder {
        self.sport = sport
        return self
    }

    func setLevel(_ level: AthleteLevel) -> MacroPlanRequestBuilder {
        self.level = level
        return self
    }

    func setStartDate(_ date: Date) -> MacroPlanRequestBuilder {
        self.startDate = date
        return self
    }

    func setWeeklyTime(hours: Int) -> MacroPlanRequestBuilder {
        self.weeklyTimeHours = hours
        return self
    }

    func setConstraintsText(_ text: String?) -> MacroPlanRequestBuilder {
        self.constraintsText = text
        return self
    }

    func setPerSportSessions(_ sessions: PerSportSessions?) -> MacroPlanRequestBuilder {
        self.perSportSessions = sessions
        return self
    }

    func setSoftConstraints(_ softConstraints: SoftConstraints) -> MacroPlanRequestBuilder {
        self.softConstraints = softConstraints
        return self
    }

    func addObjective(_ objective: RaceObjective) -> MacroPlanRequestBuilder {
        objectives.append(objective)
        return self
    }

    func setObjectives(_ objectives: [RaceObjective]) -> MacroPlanRequestBuilder {
        self.objectives = objectives
        return self
    }

    func setOptions(_ options: MacroPlanOptions) -> MacroPlanRequestBuilder {
        self.options = options
        return self
    }

    func build() -> MacroPlanRequest {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let planConfig = PlanConfig(
            startDate: formatter.string(from: startDate),
            weeklyTimeAvailable: weeklyTimeHours,
            constraints: constraintsText,
            perSportSessions: perSportSessions
        )

        let athleteProfile = AthleteProfile(
            sport: sport,
            level: level,
            planConfig: planConfig,
            softConstraints: softConstraints
        )

        return MacroPlanRequest(
            userId: userId,
            athleteProfile: athleteProfile,
            objectives: objectives,
            options: options
        )
    }
}
