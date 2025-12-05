/**
 * Modèles MacroPlan pour EdgeCoach iOS
 * Correspond à l'endpoint POST /api/plans/macro
 */

import Foundation

// MARK: - MacroPlan Request

/// Requête principale pour créer un MacroPlan
struct MacroPlanRequest: Encodable {
    let userId: String
    let athleteProfile: AthleteProfile
    let objectives: [RaceObjective]
    let options: MacroPlanOptions?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case athleteProfile = "athlete_profile"
        case objectives
        case options
    }
}

// MARK: - Athlete Profile

/// Profil de l'athlète incluant sport, niveau, configuration et contraintes
struct AthleteProfile: Codable {
    var sport: MacroPlanSport
    var level: AthleteLevel
    var planConfig: PlanConfig
    var softConstraints: SoftConstraints?

    enum CodingKeys: String, CodingKey {
        case sport
        case level
        case planConfig = "plan_config"
        case softConstraints = "soft_constraints"
    }

    static var `default`: AthleteProfile {
        AthleteProfile(
            sport: .triathlon,
            level: .intermediate,
            planConfig: .default,
            softConstraints: .default
        )
    }
}

// MARK: - MacroPlan Sport

/// Sports disponibles pour le MacroPlan
enum MacroPlanSport: String, Codable, CaseIterable, Identifiable {
    case triathlon
    case cyclisme = "cycling"
    case courseAPied = "running"
    case natation = "swimming"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .triathlon: return "Triathlon"
        case .cyclisme: return "Cyclisme"
        case .courseAPied: return "Course à pied"
        case .natation: return "Natation"
        }
    }

    var icon: String {
        switch self {
        case .triathlon: return "figure.mixed.cardio"
        case .cyclisme: return "bicycle"
        case .courseAPied: return "figure.run"
        case .natation: return "figure.pool.swim"
        }
    }
}

// MARK: - Athlete Level

/// Niveau de l'athlète
enum AthleteLevel: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced
    case expert

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner: return "Débutant"
        case .intermediate: return "Intermédiaire"
        case .advanced: return "Avancé"
        case .expert: return "Expert"
        }
    }

    var description: String {
        switch self {
        case .beginner: return "Nouveau dans le sport, moins d'1 an de pratique"
        case .intermediate: return "1-3 ans de pratique régulière"
        case .advanced: return "Plus de 3 ans, compétitions régulières"
        case .expert: return "Athlète confirmé, haut niveau"
        }
    }
}

// MARK: - Plan Config

/// Configuration du plan d'entraînement
struct PlanConfig: Codable {
    var startDate: String
    var weeklyTimeAvailable: Int // en heures (pas minutes)
    var constraints: String?     // String libre, pas un objet
    var perSportSessions: PerSportSessions?

    enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case weeklyTimeAvailable = "weekly_time_available"
        case constraints
        case perSportSessions = "per_sport_sessions"
    }

    static var `default`: PlanConfig {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startDate = formatter.string(from: Date())

        return PlanConfig(
            startDate: startDate,
            weeklyTimeAvailable: 12, // 12h par défaut
            constraints: "long vélo dimanche, sortie longue samedi",
            perSportSessions: .defaultTriathlon
        )
    }
}

// MARK: - Per Sport Sessions

/// Nombre de séances par sport par semaine
struct PerSportSessions: Codable {
    var swimming: Int?
    var cycling: Int?
    var running: Int?

    static var defaultTriathlon: PerSportSessions {
        PerSportSessions(swimming: 3, cycling: 3, running: 3)
    }
}

// MARK: - Soft Constraints

/// Contraintes souples de planning
struct SoftConstraints: Codable {
    var unavailableDays: [String]?           // ["monday", "tuesday", ...]
    var preferredEasyDays: [String]?         // ["tuesday", "friday", ...]
    var preferredLongWorkoutDays: [String]?  // ["saturday", "sunday", ...]
    var maxSessionsPerWeek: Int?
    var noDoubles: Bool?                     // pas de biquotidien

    enum CodingKeys: String, CodingKey {
        case unavailableDays = "unavailable_days"
        case preferredEasyDays = "preferred_easy_days"
        case preferredLongWorkoutDays = "preferred_long_workout_days"
        case maxSessionsPerWeek = "max_sessions_per_week"
        case noDoubles = "no_doubles"
    }

    static var `default`: SoftConstraints {
        SoftConstraints(
            unavailableDays: ["monday"],
            preferredEasyDays: ["tuesday", "friday"],
            preferredLongWorkoutDays: ["saturday", "sunday"],
            maxSessionsPerWeek: 8,
            noDoubles: false
        )
    }
}

// MARK: - Race Objective

/// Objectif de course/compétition (correspond au backend TrainingObjective)
struct RaceObjective: Codable, Identifiable {
    let id: String
    var name: String
    var targetDate: String
    var priority: ObjectivePriority
    var objectiveType: ObjectiveType
    var sport: MacroPlanSport
    var raceFormat: RaceFormat?
    var distanceValue: Double?
    var distanceUnit: String?
    var targetTime: String?
    var location: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case targetDate = "target_date"
        case priority
        case objectiveType = "objective_type"
        case sport
        case raceFormat = "race_format"
        case distanceValue = "distance_value"
        case distanceUnit = "distance_unit"
        case targetTime = "target_time"
        case location
    }

    init(id: String = UUID().uuidString,
         name: String = "",
         targetDate: String = "",
         priority: ObjectivePriority = .principal,
         objectiveType: ObjectiveType = .race,
         sport: MacroPlanSport = .triathlon,
         raceFormat: RaceFormat? = nil,
         distanceValue: Double? = nil,
         distanceUnit: String? = "km",
         targetTime: String? = nil,
         location: String? = nil) {
        self.id = id
        self.name = name
        self.targetDate = targetDate
        self.priority = priority
        self.objectiveType = objectiveType
        self.sport = sport
        self.raceFormat = raceFormat
        self.distanceValue = distanceValue
        self.distanceUnit = distanceUnit
        self.targetTime = targetTime
        self.location = location
    }

    /// Crée un objectif avec distance calculée automatiquement depuis le format
    static func triathlon(name: String, targetDate: String, priority: ObjectivePriority, format: RaceFormat, targetTime: String? = nil, location: String? = nil) -> RaceObjective {
        RaceObjective(
            name: name,
            targetDate: targetDate,
            priority: priority,
            objectiveType: .race,
            sport: .triathlon,
            raceFormat: format,
            distanceValue: format.totalDistanceKm,
            distanceUnit: "km",
            targetTime: targetTime,
            location: location
        )
    }

    static var empty: RaceObjective {
        RaceObjective()
    }

    // MARK: - Exemples pour le dev

    /// Objectifs par défaut pour le développement (hardcodé temporairement)
    static var devExamples: [RaceObjective] {
        [
            RaceObjective(
                name: "10k Paris",
                targetDate: "2026-02-01",
                priority: .secondary,
                objectiveType: .race,
                sport: .courseAPied,
                raceFormat: .tenK,
                distanceValue: 10.0,
                distanceUnit: "km",
                targetTime: "42:00"
            ),
            RaceObjective(
                name: "Ironman 70.3 Carcans",
                targetDate: "2026-05-16",
                priority: .principal,
                objectiveType: .race,
                sport: .triathlon,
                raceFormat: .halfIronman,
                distanceValue: 113.0,
                distanceUnit: "km",
                targetTime: "5:30:00"
            )
        ]
    }
}

// MARK: - Objective Priority

/// Priorité de l'objectif (correspond au backend TrainingObjective)
enum ObjectivePriority: String, Codable, CaseIterable, Identifiable {
    case principal = "principal"
    case secondary = "secondary"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .principal: return "Objectif Principal"
        case .secondary: return "Objectif Secondaire"
        }
    }

    var shortName: String {
        switch self {
        case .principal: return "A"
        case .secondary: return "B"
        }
    }

    var color: String {
        switch self {
        case .principal: return "warning"  // Or/Jaune
        case .secondary: return "info"     // Bleu
        }
    }
}

// MARK: - Objective Type

/// Type d'objectif (correspond au backend TrainingObjective)
enum ObjectiveType: String, Codable, CaseIterable, Identifiable {
    case race = "race"
    case focus = "focus"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .race: return "Course/Compétition"
        case .focus: return "Préparation/Focus"
        }
    }
}

// MARK: - Race Format

/// Format de course (correspond au backend TrainingObjective)
enum RaceFormat: String, Codable, CaseIterable, Identifiable {
    case tenK = "10k"
    case sprint = "sprint"
    case olympic = "olympic"
    case halfIronman = "70.3"
    case ironman = "ironman"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tenK: return "10 km"
        case .sprint: return "Sprint"
        case .olympic: return "Olympique (M)"
        case .halfIronman: return "70.3 (Half-Ironman)"
        case .ironman: return "Ironman"
        case .other: return "Autre"
        }
    }

    var distances: String {
        switch self {
        case .tenK: return "10 km"
        case .sprint: return "750m / 20km / 5km"
        case .olympic: return "1.5km / 40km / 10km"
        case .halfIronman: return "1.9km / 90km / 21km"
        case .ironman: return "3.8km / 180km / 42km"
        case .other: return ""
        }
    }

    /// Distance totale en km pour ce format
    var totalDistanceKm: Double {
        switch self {
        case .tenK: return 10.0
        case .sprint: return 25.75      // 0.75 + 20 + 5
        case .olympic: return 51.5      // 1.5 + 40 + 10
        case .halfIronman: return 113.0 // 1.9 + 90 + 21.1
        case .ironman: return 226.0     // 3.8 + 180 + 42.2
        case .other: return 0
        }
    }
}

// MARK: - MacroPlan Options

/// Options pour la génération du plan
struct MacroPlanOptions: Codable {
    var useCoordinator: Bool?
    var language: String?
    var seasonEnd: String?  // Date de fin de saison

    enum CodingKeys: String, CodingKey {
        case useCoordinator = "use_coordinator"
        case language
        case seasonEnd = "season_end"
    }

    static var `default`: MacroPlanOptions {
        MacroPlanOptions(
            useCoordinator: true,
            language: "fr",
            seasonEnd: nil
        )
    }
}

// MARK: - MacroPlan Response

/// Réponse de création d'un MacroPlan
struct MacroPlanResponse: Decodable {
    let status: String?
    let message: String?
    let planId: String?
    let plan: MacroPlanData?

    enum CodingKeys: String, CodingKey {
        case status
        case message
        case planId = "plan_id"
        case plan
    }
}

/// Données du MacroPlan généré
struct MacroPlanData: Decodable, Identifiable {
    let id: String
    let userId: String
    let name: String?
    let description: String?
    let startDate: String?
    let endDate: String?
    let objectives: [RaceObjective]?
    let weeks: [MacroPlanWeek]?
    let visualBars: [VisualBar]?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId = "user_id"
        case name
        case description
        case startDate = "start_date"
        case endDate = "end_date"
        case objectives
        case weeks
        case visualBars = "visual_bars"
        case createdAt = "created_at"
    }

    // MARK: - Mock Data
    static var mock: MacroPlanData {
        let bars = [
            VisualBar(id: "1", subplanName: "Préparation Générale", segmentType: "prep", weekStart: 1, weekEnd: 8, durationWeeks: 8, startRatio: 0.0, widthRatio: 0.25),
            VisualBar(id: "2", subplanName: "Développement Base", segmentType: "base", weekStart: 9, weekEnd: 16, durationWeeks: 8, startRatio: 0.25, widthRatio: 0.25),
            VisualBar(id: "3", subplanName: "Spécifique Build", segmentType: "build", weekStart: 17, weekEnd: 24, durationWeeks: 8, startRatio: 0.50, widthRatio: 0.25),
            VisualBar(id: "4", subplanName: "Affûtage & Course", segmentType: "race", weekStart: 25, weekEnd: 28, durationWeeks: 4, startRatio: 0.75, widthRatio: 0.125)
        ]

        return MacroPlanData(
            id: "mock-plan-id",
            userId: "mock-user-id",
            name: "Plan Triathlon 2026",
            description: "Plan généré automatiquement pour Iroman 70.3",
            startDate: "2026-01-01",
            endDate: "2026-06-30",
            objectives: RaceObjective.devExamples,
            weeks: [],
            visualBars: bars,
            createdAt: Date().ISO8601Format()
        )
    }

    // Helper init for mock
    init(id: String, userId: String, name: String?, description: String?, startDate: String?, endDate: String?, objectives: [RaceObjective]?, weeks: [MacroPlanWeek]?, visualBars: [VisualBar]?, createdAt: String?) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.objectives = objectives
        self.weeks = weeks
        self.visualBars = visualBars
        self.createdAt = createdAt
    }
}

/// Barre visuelle pour la timeline (Gantt)
struct VisualBar: Decodable, Identifiable {
    let id: String
    let subplanName: String
    let segmentType: String
    let weekStart: Int
    let weekEnd: Int
    let durationWeeks: Int
    let startRatio: Double
    let widthRatio: Double

    enum CodingKeys: String, CodingKey {
        case subplanName = "subplan_name"
        case segmentType = "segment_type"
        case weekStart = "week_start"
        case weekEnd = "week_end"
        case durationWeeks = "duration_weeks"
        case startRatio = "start_ratio"
        case widthRatio = "width_ratio"
    }

    /// Init memberwise pour création manuelle (mock data)
    init(id: String, subplanName: String, segmentType: String, weekStart: Int, weekEnd: Int, durationWeeks: Int, startRatio: Double, widthRatio: Double) {
        self.id = id
        self.subplanName = subplanName
        self.segmentType = segmentType
        self.weekStart = weekStart
        self.weekEnd = weekEnd
        self.durationWeeks = durationWeeks
        self.startRatio = startRatio
        self.widthRatio = widthRatio
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.subplanName = try container.decode(String.self, forKey: .subplanName)
        self.segmentType = try container.decode(String.self, forKey: .segmentType)
        self.weekStart = try container.decode(Int.self, forKey: .weekStart)
        self.weekEnd = try container.decode(Int.self, forKey: .weekEnd)
        self.durationWeeks = try container.decode(Int.self, forKey: .durationWeeks)
        self.startRatio = try container.decode(Double.self, forKey: .startRatio)
        self.widthRatio = try container.decode(Double.self, forKey: .widthRatio)
        self.id = UUID().uuidString
    }
}

/// Semaine du MacroPlan
struct MacroPlanWeek: Decodable, Identifiable {
    let id: String
    let weekNumber: Int
    let startDate: String
    let endDate: String
    let focus: String?
    let totalHours: Double?
    let sessions: [PlannedSession]?

    enum CodingKeys: String, CodingKey {
        case id
        case weekNumber = "week_number"
        case startDate = "start_date"
        case endDate = "end_date"
        case focus
        case totalHours = "total_hours"
        case sessions
    }
}

// MARK: - Day of Week Helper

/// Jours de la semaine pour les contraintes
enum DayOfWeek: Int, CaseIterable, Identifiable {
    case monday = 0
    case tuesday = 1
    case wednesday = 2
    case thursday = 3
    case friday = 4
    case saturday = 5
    case sunday = 6

    var id: Int { rawValue }

    /// Nom pour l'API backend (en anglais, minuscules)
    var apiName: String {
        switch self {
        case .monday: return "monday"
        case .tuesday: return "tuesday"
        case .wednesday: return "wednesday"
        case .thursday: return "thursday"
        case .friday: return "friday"
        case .saturday: return "saturday"
        case .sunday: return "sunday"
        }
    }

    var shortName: String {
        switch self {
        case .monday: return "Lun"
        case .tuesday: return "Mar"
        case .wednesday: return "Mer"
        case .thursday: return "Jeu"
        case .friday: return "Ven"
        case .saturday: return "Sam"
        case .sunday: return "Dim"
        }
    }

    var fullName: String {
        switch self {
        case .monday: return "Lundi"
        case .tuesday: return "Mardi"
        case .wednesday: return "Mercredi"
        case .thursday: return "Jeudi"
        case .friday: return "Vendredi"
        case .saturday: return "Samedi"
        case .sunday: return "Dimanche"
        }
    }

    /// Créer depuis un nom API
    static func from(apiName: String) -> DayOfWeek? {
        allCases.first { $0.apiName == apiName.lowercased() }
    }
}
