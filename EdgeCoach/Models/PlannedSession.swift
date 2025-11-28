/**
 * Modèles de séance planifiée
 * Correspond aux données retournées par l'API /plans/last
 */

import Foundation

// MARK: - Training Plan Response (from API /plans/last)

/// Réponse complète de l'API /plans/last
struct TrainingPlanResponse: Codable {
    let status: String?
    let userId: String?
    let cycle: TrainingPlanData?
    let retrievedAt: String?

    enum CodingKeys: String, CodingKey {
        case status
        case userId = "user_id"
        case cycle
        case retrievedAt = "retrieved_at"
    }
}

// MARK: - Training Plan Data

/// Données du plan d'entraînement stocké en base
struct TrainingPlanData: Codable, Identifiable {
    let id: String
    let userId: String
    let iaAnswer: IAAnswer?
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId = "user_id"
        case iaAnswer = "ia_answer"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Extrait les sessions planifiées du plan
    var plannedSessions: [PlannedSession] {
        guard let activities = iaAnswer?.activitiesJson?.plan else { return [] }
        return activities.map { activity in
            PlannedSession(
                from: activity,
                planId: id,
                userId: userId,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }
}

// MARK: - IA Answer

struct IAAnswer: Codable {
    let activitiesJson: ActivitiesJson?

    enum CodingKeys: String, CodingKey {
        case activitiesJson = "activities_json"
    }
}

// MARK: - Activities Json

struct ActivitiesJson: Codable {
    let plan: [PlannedActivityRaw]?
}

// MARK: - Planned Activity Raw (from API)

/// Activité planifiée brute telle que retournée par l'API
struct PlannedActivityRaw: Codable {
    let id: RawId              // Peut être Int ou String
    let date: String           // YYYY-MM-DD
    let sport: String          // "Cyclisme", "Course à pied", "Natation"
    let nom: String            // Nom de la séance
    let duree: Int             // Durée en minutes
    let volume: Int?           // Volume en mètres (optionnel)
    let intensite: String?     // Ex: "Z2", "Z4"
    let type: String?          // Ex: "Endurance", "Intervalle"
    let zone: String?
    let focus: String?
    let description: String?
    let educatifs: [String]?

    /// Wrapper pour gérer id qui peut être Int ou String
    enum RawId: Codable {
        case int(Int)
        case string(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let intValue = try? container.decode(Int.self) {
                self = .int(intValue)
            } else if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else {
                throw DecodingError.typeMismatch(
                    RawId.self,
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Int or String")
                )
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .int(let value):
                try container.encode(value)
            case .string(let value):
                try container.encode(value)
            }
        }

        var stringValue: String {
            switch self {
            case .int(let value): return String(value)
            case .string(let value): return value
            }
        }
    }
}

// MARK: - Planned Session (Frontend Model)

/// Modèle de séance planifiée pour l'affichage
struct PlannedSession: Codable, Identifiable {
    let id: String
    let planId: String?
    let userId: String
    let date: String               // YYYY-MM-DD
    let discipline: Discipline
    let name: String
    let title: String
    let dureeMinutes: Int          // Durée originale en minutes
    let volumeMeters: Int?         // Volume original en mètres
    let estimatedDuration: String? // Durée formatée (ex: "1:30" ou "45min")
    let estimatedDistance: String? // Distance formatée (ex: "45 km" ou "1500 m")
    let targetPace: String?        // Intensité cible (ex: "Z2")
    let intensity: String?         // Type (ex: "Endurance")
    let zone: String?
    let focus: String?
    let scheduledTime: String?
    let timeOfDay: String?
    let description: String?
    let notes: String?
    let coachInstructions: String?
    let educatifs: [String]
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case planId = "plan_id"
        case userId = "user_id"
        case date
        case discipline
        case name
        case title
        case dureeMinutes = "duree_minutes"
        case volumeMeters = "volume_meters"
        case estimatedDuration = "estimated_duration"
        case estimatedDistance = "estimated_distance"
        case targetPace = "target_pace"
        case intensity
        case zone
        case focus
        case scheduledTime = "scheduled_time"
        case timeOfDay = "time_of_day"
        case description
        case notes
        case coachInstructions = "coach_instructions"
        case educatifs
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Initialise depuis les données brutes de l'API
    init(from raw: PlannedActivityRaw, planId: String, userId: String, createdAt: String, updatedAt: String?) {
        self.id = "plan_\(raw.id.stringValue)"
        self.planId = planId
        self.userId = userId
        self.date = raw.date
        self.discipline = Discipline.from(sport: raw.sport)
        self.name = raw.nom
        self.title = raw.nom
        self.dureeMinutes = raw.duree
        self.volumeMeters = raw.volume
        self.estimatedDuration = PlannedSession.formatDuration(minutes: raw.duree)
        self.estimatedDistance = PlannedSession.formatDistance(meters: raw.volume, discipline: Discipline.from(sport: raw.sport))
        self.targetPace = raw.intensite
        self.intensity = raw.type
        self.zone = raw.zone
        self.focus = raw.focus
        self.scheduledTime = nil
        self.timeOfDay = nil
        self.description = raw.description
        self.notes = raw.focus
        self.coachInstructions = raw.description
        self.educatifs = raw.educatifs ?? []
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Init pour preview/testing
    init(id: String, userId: String, date: String, discipline: Discipline, name: String,
         dureeMinutes: Int, volumeMeters: Int? = nil, intensity: String? = nil,
         description: String? = nil, educatifs: [String] = []) {
        self.id = id
        self.planId = nil
        self.userId = userId
        self.date = date
        self.discipline = discipline
        self.name = name
        self.title = name
        self.dureeMinutes = dureeMinutes
        self.volumeMeters = volumeMeters
        self.estimatedDuration = PlannedSession.formatDuration(minutes: dureeMinutes)
        self.estimatedDistance = PlannedSession.formatDistance(meters: volumeMeters, discipline: discipline)
        self.targetPace = nil
        self.intensity = intensity
        self.zone = nil
        self.focus = nil
        self.scheduledTime = nil
        self.timeOfDay = nil
        self.description = description
        self.notes = nil
        self.coachInstructions = description
        self.educatifs = educatifs
        self.createdAt = ISO8601DateFormatter().string(from: Date())
        self.updatedAt = nil
    }

    // MARK: - Computed Properties

    /// Date parsée
    var dateValue: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }

    /// Titre affiché
    var displayTitle: String {
        title.isEmpty ? name : title
    }

    /// Durée formatée pour l'affichage
    var formattedDuration: String? {
        estimatedDuration
    }

    /// Distance formatée pour l'affichage
    var formattedDistance: String? {
        estimatedDistance
    }

    /// Date formatée pour l'affichage (ex: "Lundi 25 novembre 2024")
    var formattedDate: String? {
        guard let dateValue = dateValue else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: dateValue).capitalized
    }

    // MARK: - Static Formatters

    /// Formate la durée en minutes vers "HH:MM" ou "XXmin"
    static func formatDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, mins)
        }
        return "\(mins)min"
    }

    /// Formate la distance en mètres selon la discipline
    static func formatDistance(meters: Int?, discipline: Discipline) -> String? {
        guard let meters = meters, meters > 0 else { return nil }

        switch discipline {
        case .natation:
            return "\(meters) m"
        case .cyclisme, .course:
            let km = Double(meters) / 1000.0
            if km.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0f km", km)
            }
            return String(format: "%.1f km", km)
        case .autre:
            if meters >= 1000 {
                return String(format: "%.1f km", Double(meters) / 1000.0)
            }
            return "\(meters) m"
        }
    }
}

// MARK: - Training Plan (Legacy compatibility)

/// Ancien modèle pour compatibilité
struct TrainingPlan: Codable, Identifiable {
    let id: String
    let userId: String
    let sessions: [PlannedSession]
    let createdAt: Date
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId = "user_id"
        case sessions
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
