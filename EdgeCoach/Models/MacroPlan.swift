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
            level: .amateur,
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

/// Niveau de l'athlète (aligné avec backend: discovery, amateur, competitor)
enum AthleteLevel: String, Codable, CaseIterable, Identifiable {
    case discovery = "discovery"
    case amateur = "amateur"
    case competitor = "competitor"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .discovery: return "Découverte"
        case .amateur: return "Amateur"
        case .competitor: return "Compétiteur"
        }
    }

    var description: String {
        switch self {
        case .discovery: return "Je débute, je veux apprendre et prendre du plaisir"
        case .amateur: return "Je m'entraîne régulièrement et je veux progresser"
        case .competitor: return "Je vise la performance et je connais les fondamentaux"
        }
    }

    var icon: String {
        switch self {
        case .discovery: return "leaf.fill"
        case .amateur: return "star.fill"
        case .competitor: return "trophy.fill"
        }
    }

    var emoji: String {
        switch self {
        case .discovery: return "🌱"
        case .amateur: return "⭐"
        case .competitor: return "🏆"
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

// MARK: - API Response Models (Backend)

/// Réponse complète de l'API /plans/macro/user/<id>/active
struct MacroPlanAPIResponse: Decodable {
    let status: String
    let planId: String?
    let generatedAt: String?
    let masterPlan: MasterSeasonPlanAPI?
    let feasibility: FeasibilityAPI?
    let summary: MacroPlanSummaryAPI?

    enum CodingKeys: String, CodingKey {
        case status
        case planId = "plan_id"
        case generatedAt = "generated_at"
        case masterPlan = "master_plan"
        case feasibility
        case summary
    }
}

/// MasterSeasonPlan du backend
struct MasterSeasonPlanAPI: Decodable {
    let planId: String
    let seasonStart: String
    let seasonEnd: String
    let totalWeeks: Int
    let planningMode: String
    let objectives: [RaceObjectiveAPI]?
    let mainObjective: RaceObjectiveAPI?
    let secondaryObjectives: [RaceObjectiveAPI]?
    let subPlans: [SubPlanAPI]?
    let athleteSport: String?
    let athleteLevel: String?
    let createdAt: String?
    let coordinatorRationale: String?
    let coherenceScore: Double?

    enum CodingKeys: String, CodingKey {
        case planId = "plan_id"
        case seasonStart = "season_start"
        case seasonEnd = "season_end"
        case totalWeeks = "total_weeks"
        case planningMode = "planning_mode"
        case objectives
        case mainObjective = "main_objective"
        case secondaryObjectives = "secondary_objectives"
        case subPlans = "sub_plans"
        case athleteSport = "athlete_sport"
        case athleteLevel = "athlete_level"
        case createdAt = "created_at"
        case coordinatorRationale = "coordinator_rationale"
        case coherenceScore = "coherence_score"
    }
}

/// Objectif du backend
struct RaceObjectiveAPI: Decodable {
    let name: String
    let targetDate: String?
    let priority: String
    let objectiveType: String?
    let sport: String?
    let raceFormat: String?
    let distanceValue: Double?
    let distanceUnit: String?
    let targetTime: String?
    let location: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
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
        case description
    }
}

/// SubPlan du backend
struct SubPlanAPI: Decodable {
    let subplanId: String
    let name: String
    let weekStart: Int
    let weekEnd: Int
    let durationWeeks: Int
    let objective: RaceObjectiveAPI?
    let methodologyId: String?
    let methodologySegments: [MethodologySegmentAPI]?
    let phases: [SubPlanPhaseAPI]?
    let baseDistribution: [String: Double]?

    enum CodingKeys: String, CodingKey {
        case subplanId = "subplan_id"
        case name
        case weekStart = "week_start"
        case weekEnd = "week_end"
        case durationWeeks = "duration_weeks"
        case objective
        case methodologyId = "methodology_id"
        case methodologySegments = "methodology_segments"
        case phases
        case baseDistribution = "base_distribution"
    }
}

/// Segment de méthodologie du backend
struct MethodologySegmentAPI: Decodable {
    let segmentId: String
    let name: String
    let weekStart: Int
    let weekEnd: Int
    let durationWeeks: Int
    let segmentType: String
    let methodologyId: String
    let phases: [SubPlanPhaseAPI]?
    let intensityModifier: Double?
    let volumeModifier: Double?

    enum CodingKeys: String, CodingKey {
        case segmentId = "segment_id"
        case name
        case weekStart = "week_start"
        case weekEnd = "week_end"
        case durationWeeks = "duration_weeks"
        case segmentType = "segment_type"
        case methodologyId = "methodology_id"
        case phases
        case intensityModifier = "intensity_modifier"
        case volumeModifier = "volume_modifier"
    }
}

/// Phase d'un SubPlan du backend
struct SubPlanPhaseAPI: Decodable {
    let name: String
    let weekStart: Int
    let weekEnd: Int
    let durationWeeks: Int?
    let focus: String?
    let intensityLevel: Double?
    let volumeLevel: Double?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case name
        case weekStart = "week_start"
        case weekEnd = "week_end"
        case durationWeeks = "duration_weeks"
        case focus
        case intensityLevel = "intensity_level"
        case volumeLevel = "volume_level"
        case description
    }
}

/// Faisabilité du backend
struct FeasibilityAPI: Decodable {
    let isFeasible: Bool?
    let warnings: [String]?
    let gapsAnalysis: [GapAnalysisAPI]?

    enum CodingKeys: String, CodingKey {
        case isFeasible = "is_feasible"
        case warnings
        case gapsAnalysis = "gaps_analysis"
    }
}

/// Analyse des gaps entre objectifs
struct GapAnalysisAPI: Decodable {
    let from: String?
    let to: String?
    let gapWeeks: Int?
    let requiredWeeks: Int?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case from
        case to
        case gapWeeks = "gap_weeks"
        case requiredWeeks = "required_weeks"
        case status
    }
}

/// Summary du plan (contient les visual_bars pour le frontend)
struct MacroPlanSummaryAPI: Decodable {
    let seasonStart: String?
    let seasonEnd: String?
    let totalWeeks: Int?
    let totalDays: Int?
    let planningMode: String?
    let subPlansCount: Int?
    let totalSegments: Int?
    let totalPhases: Int?
    let objectivesCount: Int?
    let principalObjectives: [String]?
    let focusWindowsCount: Int?
    let methodologiesUsed: [String]?
    let transferConfigsCount: Int?
    let objectivesTimeline: [ObjectiveTimelineAPI]?
    let subplansTimeline: [SubplanTimelineAPI]?
    let segmentsTimeline: [SegmentTimelineAPI]?
    let phasesTimeline: [PhaseTimelineAPI]?
    let weeksOverview: [WeekOverviewAPI]?
    let visualBars: [VisualBarAPI]?

    enum CodingKeys: String, CodingKey {
        case seasonStart = "season_start"
        case seasonEnd = "season_end"
        case totalWeeks = "total_weeks"
        case totalDays = "total_days"
        case planningMode = "planning_mode"
        case subPlansCount = "sub_plans_count"
        case totalSegments = "total_segments"
        case totalPhases = "total_phases"
        case objectivesCount = "objectives_count"
        case principalObjectives = "principal_objectives"
        case focusWindowsCount = "focus_windows_count"
        case methodologiesUsed = "methodologies_used"
        case transferConfigsCount = "transfer_configs_count"
        case objectivesTimeline = "objectives_timeline"
        case subplansTimeline = "subplans_timeline"
        case segmentsTimeline = "segments_timeline"
        case phasesTimeline = "phases_timeline"
        case weeksOverview = "weeks_overview"
        case visualBars = "visual_bars"
    }
}

/// Timeline d'un objectif
struct ObjectiveTimelineAPI: Decodable {
    let name: String
    let targetDate: String
    let priority: String
    let sport: String?
    let raceFormat: String?
    let weekNumber: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case targetDate = "target_date"
        case priority
        case sport
        case raceFormat = "race_format"
        case weekNumber = "week_number"
    }
}

/// Timeline d'un SubPlan
struct SubplanTimelineAPI: Decodable {
    let name: String
    let objectiveName: String
    let weekStart: Int
    let weekEnd: Int
    let durationWeeks: Int
    let startDate: String
    let endDate: String
    let segmentsCount: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case objectiveName = "objective_name"
        case weekStart = "week_start"
        case weekEnd = "week_end"
        case durationWeeks = "duration_weeks"
        case startDate = "start_date"
        case endDate = "end_date"
        case segmentsCount = "segments_count"
    }
}

/// Timeline d'un segment
struct SegmentTimelineAPI: Decodable {
    let name: String
    let subplanName: String
    let segmentType: String
    let weekStart: Int
    let weekEnd: Int
    let durationWeeks: Int
    let startDate: String
    let endDate: String
    let methodologyId: String?
    let methodologyName: String?

    enum CodingKeys: String, CodingKey {
        case name
        case subplanName = "subplan_name"
        case segmentType = "segment_type"
        case weekStart = "week_start"
        case weekEnd = "week_end"
        case durationWeeks = "duration_weeks"
        case startDate = "start_date"
        case endDate = "end_date"
        case methodologyId = "methodology_id"
        case methodologyName = "methodology_name"
    }
}

/// Timeline d'une phase
struct PhaseTimelineAPI: Decodable {
    let name: String
    let subplanName: String
    let objectiveName: String
    let focus: String?
    let weekStart: Int
    let weekEnd: Int
    let durationWeeks: Int
    let startDate: String
    let endDate: String

    enum CodingKeys: String, CodingKey {
        case name
        case subplanName = "subplan_name"
        case objectiveName = "objective_name"
        case focus
        case weekStart = "week_start"
        case weekEnd = "week_end"
        case durationWeeks = "duration_weeks"
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

/// Aperçu d'une semaine
struct WeekOverviewAPI: Decodable {
    let weekNumber: Int
    let startDate: String
    let endDate: String
    let subplan: String?
    let segment: WeekSegmentAPI?
    let phase: WeekPhaseAPI?
    let objective: WeekObjectiveAPI?
    let isRaceWeek: Bool?

    enum CodingKeys: String, CodingKey {
        case weekNumber = "week_number"
        case startDate = "start_date"
        case endDate = "end_date"
        case subplan
        case segment
        case phase
        case objective
        case isRaceWeek = "is_race_week"
    }
}

struct WeekSegmentAPI: Decodable {
    let name: String
    let type: String
}

struct WeekPhaseAPI: Decodable {
    let name: String
    let focus: String?
}

struct WeekObjectiveAPI: Decodable {
    let name: String
    let priority: String
    let date: String
}

/// Barre visuelle du backend (pour timeline Gantt)
struct VisualBarAPI: Decodable {
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

    /// Convertit en VisualBar iOS
    func toVisualBar() -> VisualBar {
        VisualBar(
            id: UUID().uuidString,
            subplanName: subplanName,
            segmentType: segmentType,
            weekStart: weekStart,
            weekEnd: weekEnd,
            durationWeeks: durationWeeks,
            startRatio: startRatio,
            widthRatio: widthRatio
        )
    }
}

// MARK: - API → iOS Conversion Extensions

extension MacroPlanAPIResponse {
    /// Convertit la réponse API en MacroPlanData iOS
    func toMacroPlanData() -> MacroPlanData? {
        guard let masterPlan = masterPlan else { return nil }

        // Convertir les objectifs
        let objectives: [RaceObjective] = masterPlan.objectives?.map { $0.toRaceObjective() } ?? []

        // Convertir les visual bars depuis le summary
        let visualBars: [VisualBar] = summary?.visualBars?.map { $0.toVisualBar() } ?? []

        // Générer un nom de plan
        let planName: String
        if let mainObj = masterPlan.mainObjective {
            planName = "Plan \(mainObj.name)"
        } else if let firstObj = objectives.first {
            planName = "Plan \(firstObj.name)"
        } else {
            planName = "Plan de saison"
        }

        // Description
        let description = masterPlan.coordinatorRationale ?? "Plan généré automatiquement"

        return MacroPlanData(
            id: masterPlan.planId,
            userId: "",  // Non disponible dans la réponse API
            name: planName,
            description: description,
            startDate: masterPlan.seasonStart,
            endDate: masterPlan.seasonEnd,
            objectives: objectives,
            weeks: nil,  // Non utilisé pour l'affichage du widget
            visualBars: visualBars,
            createdAt: masterPlan.createdAt
        )
    }
}

extension RaceObjectiveAPI {
    /// Convertit un objectif API en RaceObjective iOS
    func toRaceObjective() -> RaceObjective {
        // Convertir la priorité
        let iOSPriority: ObjectivePriority
        switch priority.lowercased() {
        case "principal", "a":
            iOSPriority = .principal
        default:
            iOSPriority = .secondary
        }

        // Convertir le type d'objectif
        let iOSObjectiveType: ObjectiveType
        switch (objectiveType ?? "race").lowercased() {
        case "focus":
            iOSObjectiveType = .focus
        default:
            iOSObjectiveType = .race
        }

        // Convertir le sport
        let iOSSport: MacroPlanSport
        switch (sport ?? "triathlon").lowercased() {
        case "running":
            iOSSport = .courseAPied
        case "cycling":
            iOSSport = .cyclisme
        case "swimming":
            iOSSport = .natation
        default:
            iOSSport = .triathlon
        }

        // Convertir le format de course
        var iOSRaceFormat: RaceFormat? = nil
        if let format = raceFormat?.lowercased() {
            switch format {
            case "10k":
                iOSRaceFormat = .tenK
            case "sprint":
                iOSRaceFormat = .sprint
            case "olympic":
                iOSRaceFormat = .olympic
            case "70.3", "half_ironman":
                iOSRaceFormat = .halfIronman
            case "ironman":
                iOSRaceFormat = .ironman
            default:
                iOSRaceFormat = .other
            }
        }

        return RaceObjective(
            id: UUID().uuidString,
            name: name,
            targetDate: targetDate ?? "",
            priority: iOSPriority,
            objectiveType: iOSObjectiveType,
            sport: iOSSport,
            raceFormat: iOSRaceFormat,
            distanceValue: distanceValue,
            distanceUnit: distanceUnit,
            targetTime: targetTime,
            location: location
        )
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
