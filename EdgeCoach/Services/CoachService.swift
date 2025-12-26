/**
 * Service de gestion du coach sélectionné
 * Gère la persistance et la synchronisation avec le backend
 * Aligné avec l'API backend /api/coach/selection
 */

import Foundation

// MARK: - Coach Selection Models

struct CoachSelection: Codable {
    let sport: String
    let coachId: String

    enum CodingKeys: String, CodingKey {
        case sport
        case coachId = "coach_id"
    }
}

struct SelectedCoach: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let sport: String
    let speciality: String
    let description: String
    let avatar: String
    let experience: String?
    let expertise: [String]?

    /// Icône SF Symbol basée sur le sport
    var icon: String {
        switch sport.lowercased() {
        case "triathlon":
            return "trophy"
        case "natation", "swimming":
            return "figure.pool.swim"
        case "course", "course à pied", "running":
            return "figure.run"
        case "cyclisme", "cycling":
            return "figure.outdoor.cycle"
        default:
            return "figure.run"
        }
    }

    /// Discipline correspondante
    var discipline: Discipline {
        switch sport.lowercased() {
        case "triathlon":
            return .autre
        case "natation", "swimming":
            return .natation
        case "course", "course à pied", "running":
            return .course
        case "cyclisme", "cycling":
            return .cyclisme
        default:
            return .autre
        }
    }
}

// MARK: - API Responses

struct CoachSelectionAPIResponse: Codable {
    let status: String
    let message: String?
    let userId: String?
    let coachContext: CoachContext?

    enum CodingKeys: String, CodingKey {
        case status
        case message
        case userId = "user_id"
        case coachContext = "coach_context"
    }
}

struct CoachContext: Codable {
    let userId: String?
    let selectedCoach: CoachAPIData?
    let timestamp: String?
    let contextForAgent: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case selectedCoach = "selected_coach"
        case timestamp
        case contextForAgent = "context_for_agent"
    }
}

struct GetCoachAPIResponse: Codable {
    let status: String
    let userId: String?
    let coach: CoachAPIData?

    enum CodingKeys: String, CodingKey {
        case status
        case userId = "user_id"
        case coach
    }
}

struct CoachAPIData: Codable {
    let coachId: String
    let name: String
    let sport: String
    let speciality: String
    let description: String?
    let avatar: String?
    let experience: String?
    let expertise: [String]?
    let selectedAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case coachId = "coach_id"
        case name
        case sport
        case speciality
        case description
        case avatar
        case experience
        case expertise
        case selectedAt = "selected_at"
        case updatedAt = "updated_at"
    }

    func toSelectedCoach() -> SelectedCoach {
        SelectedCoach(
            id: coachId,
            name: name,
            sport: sport,
            speciality: speciality,
            description: description ?? "",
            avatar: avatar ?? name.prefix(2).uppercased(),
            experience: experience,
            expertise: expertise
        )
    }
}

// MARK: - Coach Service

@MainActor
class CoachService {
    static let shared = CoachService()
    private let api = APIService.shared
    private let storageKey = "selectedCoach"

    private var currentCoach: SelectedCoach?
    private var listeners: [(SelectedCoach) -> Void] = []

    private init() {}

    // MARK: - Coach from Config (système modulaire sans coachs nommés)

    /// Génère un coach virtuel basé sur la configuration (Sport + Level + Style)
    static func coachFromConfig(_ config: CoachingConfig) -> SelectedCoach {
        SelectedCoach(
            id: "\(config.sport.rawValue)_\(config.style.rawValue)",
            name: "Coach",  // Pas de nom personnalisé
            sport: config.sport.rawValue,
            speciality: config.sport.displayName,
            description: config.style.description,
            avatar: config.sport.icon,
            experience: nil,
            expertise: nil
        )
    }

    /// Coach par défaut basé sur la configuration actuelle
    static var defaultCoach: SelectedCoach {
        coachFromConfig(CoachingConfigService.shared.config)
    }

    // MARK: - Initialize

    /// Initialise le service en chargeant le coach depuis l'API ou le stockage local
    func initialize(userId: String?) async -> SelectedCoach {
        // Essayer de charger depuis l'API si userId disponible
        if let userId = userId {
            if let apiCoach = try? await getSelectedCoachFromAPI(userId: userId) {
                currentCoach = apiCoach
                saveLocally(coach: apiCoach)
                return apiCoach
            }
        }

        // Charger depuis le stockage local
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let coach = try? JSONDecoder().decode(SelectedCoach.self, from: data) {
            currentCoach = coach
            return coach
        }

        // Par défaut, retourne le coach basé sur la config
        let defaultCoach = Self.defaultCoach
        currentCoach = defaultCoach
        return defaultCoach
    }

    // MARK: - Get Coach from API

    /// Récupère le coach sélectionné depuis l'API backend
    func getSelectedCoachFromAPI(userId: String) async throws -> SelectedCoach? {
        do {
            let response: GetCoachAPIResponse = try await api.get(
                "/coach/selection",
                queryParams: ["user_id": userId]
            )

            if response.status == "success", let coachData = response.coach {
                return coachData.toSelectedCoach()
            }
            return nil
        } catch let apiError as APIError {
            // 404 = aucun coach sélectionné
            if case .httpError(let code, _) = apiError, code == 404 {
                return nil
            }
            throw apiError
        }
    }

    // MARK: - Get Coach

    func getCurrentCoach() -> SelectedCoach {
        if currentCoach == nil {
            currentCoach = Self.defaultCoach
        }
        return currentCoach!
    }

    /// Retourne le coach actuel basé sur la configuration
    func getCoachFromCurrentConfig() -> SelectedCoach {
        return Self.coachFromConfig(CoachingConfigService.shared.config)
    }

    /// Met à jour le coach quand la configuration change
    func updateFromConfig() {
        let newCoach = Self.defaultCoach
        currentCoach = newCoach
        saveLocally(coach: newCoach)
        notifyListeners(newCoach)
    }

    // MARK: - Select Coach

    /// Sélectionne un coach et synchronise avec le backend
    func selectCoach(_ coach: SelectedCoach, userId: String?) async -> Bool {
        currentCoach = coach
        saveLocally(coach: coach)

        // Synchroniser avec le backend si userId disponible
        if let userId = userId {
            do {
                try await syncWithBackend(userId: userId, coach: coach)
                #if DEBUG
                print("✅ Coach \(coach.name) synced with backend")
                #endif
            } catch {
                #if DEBUG
                print("❌ Error syncing coach: \(error)")
                #endif
            }
        }

        // Notifier les listeners
        notifyListeners(coach)
        return true
    }

    // MARK: - Save Locally

    private func saveLocally(coach: SelectedCoach) {
        if let data = try? JSONEncoder().encode(coach) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    // MARK: - Sync with Backend

    private func syncWithBackend(userId: String, coach: SelectedCoach) async throws {
        struct SyncRequest: Encodable {
            let coachId: String
            let name: String
            let sport: String
            let speciality: String
            let description: String
            let avatar: String
            let experience: String?
            let expertise: [String]?

            enum CodingKeys: String, CodingKey {
                case coachId = "coach_id"
                case name, sport, speciality, description, avatar, experience, expertise
            }
        }

        let request = SyncRequest(
            coachId: coach.id,
            name: coach.name,
            sport: coach.sport,
            speciality: coach.speciality,
            description: coach.description,
            avatar: coach.avatar,
            experience: coach.experience,
            expertise: coach.expertise
        )

        let _: CoachSelectionAPIResponse = try await api.post(
            "/coach/selection?user_id=\(userId)",
            body: request
        )
    }

    // MARK: - Listeners

    func addListener(_ callback: @escaping (SelectedCoach) -> Void) -> () -> Void {
        listeners.append(callback)
        let index = listeners.count - 1
        return {
            if index < self.listeners.count {
                self.listeners.remove(at: index)
            }
        }
    }

    private func notifyListeners(_ coach: SelectedCoach) {
        listeners.forEach { $0(coach) }
    }
}
