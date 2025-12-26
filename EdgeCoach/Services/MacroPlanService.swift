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

    /// Crée un nouveau MacroPlan via l'API backend
    func createMacroPlan(request: MacroPlanRequest) async throws -> MacroPlanResponse {
        // Appel au vrai endpoint backend
        let apiResponse: MacroPlanAPIResponse = try await api.post("/plans/macro", body: request)

        // Convertir en MacroPlanResponse iOS
        return MacroPlanResponse(
            status: apiResponse.status,
            message: nil,
            planId: apiResponse.planId,
            plan: apiResponse.toMacroPlanData()
        )
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

    /// Récupère le plan actif de l'utilisateur depuis le backend
    func getLastMacroPlan(userId: String) async throws -> MacroPlanData? {
        #if DEBUG
        print("🔍 [MacroPlanService] ==========================================")
        print("🔍 [MacroPlanService] Appel API pour userId: '\(userId)'")
        print("🔍 [MacroPlanService] URL: /plans/macro/user/\(userId)/active")
        #endif

        do {
            // Appel au vrai endpoint backend
            let response: MacroPlanAPIResponse = try await api.get("/plans/macro/user/\(userId)/active")

            #if DEBUG
            print("📥 [MacroPlanService] Réponse reçue:")
            print("   - status: \(response.status)")
            print("   - planId: \(response.planId ?? "nil")")
            print("   - masterPlan présent: \(response.masterPlan != nil)")
            if let mp = response.masterPlan {
                print("   - masterPlan.planId: \(mp.planId)")
                print("   - masterPlan.totalWeeks: \(mp.totalWeeks)")
                print("   - masterPlan.objectives: \(mp.objectives?.count ?? 0)")
            }
            print("   - summary présent: \(response.summary != nil)")
            if let summary = response.summary {
                print("   - summary.visualBars: \(summary.visualBars?.count ?? 0)")
            }
            #endif

            // Vérifier le statut
            guard response.status == "success" else {
                #if DEBUG
                print("⚠️ [MacroPlanService] API returned status '\(response.status)'")
                #endif
                return nil
            }

            // Convertir la réponse API en modèle iOS
            let planData = response.toMacroPlanData()

            #if DEBUG
            if let plan = planData {
                print("✅ [MacroPlanService] Conversion réussie:")
                print("   - id: \(plan.id)")
                print("   - name: \(plan.name ?? "nil")")
                print("   - objectives: \(plan.objectives?.count ?? 0)")
                print("   - visualBars: \(plan.visualBars?.count ?? 0)")
            } else {
                print("⚠️ [MacroPlanService] Conversion retourne nil")
            }
            print("🔍 [MacroPlanService] ==========================================")
            #endif

            return planData

        } catch APIError.notFound {
            #if DEBUG
            print("ℹ️ [MacroPlanService] 404 - Aucun plan actif pour userId: '\(userId)'")
            #endif
            return nil
        } catch APIError.httpError(404, let message) {
            #if DEBUG
            print("ℹ️ [MacroPlanService] HTTP 404 - \(message ?? "no message")")
            #endif
            return nil
        } catch {
            #if DEBUG
            print("❌ [MacroPlanService] ERREUR:")
            print("   - Type: \(type(of: error))")
            print("   - Description: \(error.localizedDescription)")
            print("   - Détail: \(error)")
            #endif
            throw error
        }
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
    private var level: AthleteLevel = .amateur
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
