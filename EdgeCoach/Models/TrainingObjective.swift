/**
 * TrainingObjective - Modèle d'objectif d'entraînement structuré
 * Aligné avec le backend Python pour la planification multi-objectifs
 */

import Foundation
import SwiftUI

// MARK: - Training Objective Priority

/// Priorité de l'objectif avec terminologie d'affûtage
enum TrainingObjectivePriority: String, Codable, CaseIterable, Identifiable {
    case A = "principal"
    case B = "secondary"
    case C = "tertiary"
    case D = "training"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .A: return "Course Objectif"
        case .B: return "Course Cible"
        case .C: return "Course Test"
        case .D: return "Jalon"
        }
    }

    var description: String {
        switch self {
        case .A: return "Objectif principal avec affûtage complet"
        case .B: return "Objectif important avec affûtage léger"
        case .C: return "Course de préparation sans affûtage"
        case .D: return "Évaluation ou test d'entraînement"
        }
    }

    var color: Color {
        switch self {
        case .A: return .red
        case .B: return .orange
        case .C: return .blue
        case .D: return .gray
        }
    }

    var icon: String {
        switch self {
        case .A: return "trophy.fill"
        case .B: return "target"
        case .C: return "flag.fill"
        case .D: return "gauge.medium"
        }
    }

    /// Nécessite un affûtage (taper)
    var requiresTaper: Bool {
        self == .A || self == .B
    }
}

// MARK: - Training Objective Type

/// Type d'objectif
enum TrainingObjectiveType: String, Codable, CaseIterable, Identifiable {
    case race = "race"
    case focus = "focus"
    case milestone = "milestone"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .race: return "Course"
        case .focus: return "Focus"
        case .milestone: return "Jalon"
        }
    }

    var description: String {
        switch self {
        case .race: return "Compétition avec classement/temps"
        case .focus: return "Période de développement technique"
        case .milestone: return "Test ou évaluation (FTP, VMA...)"
        }
    }

    var icon: String {
        switch self {
        case .race: return "trophy"
        case .focus: return "target"
        case .milestone: return "flag.checkered"
        }
    }
}

// MARK: - Training Race Format

/// Format de course standard
enum TrainingRaceFormat: String, Codable, CaseIterable, Identifiable {
    // Running
    case fiveK = "5k"
    case tenK = "10k"
    case halfMarathon = "half_marathon"
    case marathon = "marathon"
    case ultraTrail = "ultra_trail"

    // Triathlon
    case superSprint = "super_sprint"
    case sprint = "sprint"
    case olympic = "olympic"
    case halfIronman = "70.3"
    case ironman = "ironman"

    // Cycling
    case criterium = "criterium"
    case roadRace = "road_race"
    case timeTrial = "time_trial"
    case granfondo = "granfondo"
    case cyclosportive = "cyclosportive"

    // Custom
    case custom = "custom"

    var id: String { rawValue }

    var label: String {
        switch self {
        // Running
        case .fiveK: return "5 km"
        case .tenK: return "10 km"
        case .halfMarathon: return "Semi-marathon"
        case .marathon: return "Marathon"
        case .ultraTrail: return "Ultra-trail"
        // Triathlon
        case .superSprint: return "Super Sprint"
        case .sprint: return "Sprint"
        case .olympic: return "Olympique (M)"
        case .halfIronman: return "70.3 / Half"
        case .ironman: return "Ironman"
        // Cycling
        case .criterium: return "Critérium"
        case .roadRace: return "Course sur route"
        case .timeTrial: return "Contre-la-montre"
        case .granfondo: return "Granfondo"
        case .cyclosportive: return "Cyclosportive"
        // Custom
        case .custom: return "Personnalisé"
        }
    }

    /// Sports compatibles avec ce format
    var compatibleSports: [ObjectiveSport] {
        switch self {
        case .fiveK, .tenK, .halfMarathon, .marathon, .ultraTrail:
            return [.running]
        case .superSprint, .sprint, .olympic, .halfIronman, .ironman:
            return [.triathlon]
        case .criterium, .roadRace, .timeTrial, .granfondo, .cyclosportive:
            return [.cycling]
        case .custom:
            return ObjectiveSport.allCases
        }
    }

    /// Formats disponibles pour un sport donné
    static func formats(for sport: ObjectiveSport) -> [TrainingRaceFormat] {
        switch sport {
        case .running:
            return [.fiveK, .tenK, .halfMarathon, .marathon, .ultraTrail, .custom]
        case .cycling:
            return [.criterium, .roadRace, .timeTrial, .granfondo, .cyclosportive, .custom]
        case .swimming:
            return [.custom]
        case .triathlon:
            return [.superSprint, .sprint, .olympic, .halfIronman, .ironman, .custom]
        case .duathlon:
            return [.sprint, .olympic, .custom]
        case .other:
            return [.custom]
        }
    }
}

// MARK: - Distance Unit

/// Unité de distance
enum DistanceUnit: String, Codable, CaseIterable, Identifiable {
    case km = "km"
    case m = "m"
    case miles = "miles"
    case hours = "hours"
    case laps = "laps"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .km: return "km"
        case .m: return "m"
        case .miles: return "miles"
        case .hours: return "heures"
        case .laps: return "tours"
        }
    }
}

// MARK: - Objective Sport

/// Sport de l'objectif
enum ObjectiveSport: String, Codable, CaseIterable, Identifiable {
    case running = "running"
    case cycling = "cycling"
    case swimming = "swimming"
    case triathlon = "triathlon"
    case duathlon = "duathlon"
    case other = "other"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .running: return "Course à pied"
        case .cycling: return "Cyclisme"
        case .swimming: return "Natation"
        case .triathlon: return "Triathlon"
        case .duathlon: return "Duathlon"
        case .other: return "Autre"
        }
    }

    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .triathlon: return "trophy"
        case .duathlon: return "figure.run"
        case .other: return "figure.mixed.cardio"
        }
    }

    var color: Color {
        switch self {
        case .running: return .ecRunning
        case .cycling: return .ecCycling
        case .swimming: return .ecSwimming
        case .triathlon: return .ecTriathlon
        case .duathlon: return .orange
        case .other: return .gray
        }
    }

    /// Convertit depuis PlanSport
    init(from planSport: PlanSport) {
        switch planSport {
        case .running: self = .running
        case .cycling: self = .cycling
        case .swimming: self = .swimming
        case .triathlon: self = .triathlon
        }
    }
}

// MARK: - Training Objective

/// Objectif d'entraînement structuré
struct TrainingObjective: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var targetDate: Date
    var priority: TrainingObjectivePriority
    var objectiveType: TrainingObjectiveType
    var sport: ObjectiveSport
    var raceFormat: TrainingRaceFormat?
    var distanceValue: Double?
    var distanceUnit: DistanceUnit?
    var description: String?
    var targetTime: String?
    var location: String?

    // MARK: - Computed Properties

    /// Est-ce une course/compétition ?
    var isRace: Bool {
        objectiveType == .race
    }

    /// Est-ce l'objectif principal ?
    var isPrimary: Bool {
        priority == .A
    }

    /// Affichage de la distance
    var displayDistance: String {
        if let format = raceFormat, format != .custom {
            return format.label
        }
        if let value = distanceValue, let unit = distanceUnit {
            if value == floor(value) {
                return "\(Int(value)) \(unit.label)"
            }
            return String(format: "%.1f %@", value, unit.label)
        }
        return "N/A"
    }

    /// Date formatée
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: targetDate)
    }

    /// Jours restants
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
    }

    /// Semaines restantes
    var weeksRemaining: Int {
        daysRemaining / 7
    }

    // MARK: - Init

    init(
        id: String = UUID().uuidString,
        name: String = "",
        targetDate: Date = Date().addingTimeInterval(60 * 60 * 24 * 90), // +90 jours par défaut
        priority: TrainingObjectivePriority = .A,
        objectiveType: TrainingObjectiveType = .race,
        sport: ObjectiveSport = .running,
        raceFormat: TrainingRaceFormat? = nil,
        distanceValue: Double? = nil,
        distanceUnit: DistanceUnit? = .km,
        description: String? = nil,
        targetTime: String? = nil,
        location: String? = nil
    ) {
        self.id = id
        self.name = name
        self.targetDate = targetDate
        self.priority = priority
        self.objectiveType = objectiveType
        self.sport = sport
        self.raceFormat = raceFormat
        self.distanceValue = distanceValue
        self.distanceUnit = distanceUnit
        self.description = description
        self.targetTime = targetTime
        self.location = location
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id = "objective_id"
        case name
        case targetDate = "target_date"
        case priority
        case objectiveType = "objective_type"
        case sport
        case raceFormat = "race_format"
        case distanceValue = "distance_value"
        case distanceUnit = "distance_unit"
        case description
        case targetTime = "target_time"
        case location
    }

    // MARK: - Encoding

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)

        // Date en format ISO
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        try container.encode(formatter.string(from: targetDate), forKey: .targetDate)

        // Priority: envoyer la lettre (A, B, C, D)
        let priorityLetter: String
        switch priority {
        case .A: priorityLetter = "A"
        case .B: priorityLetter = "B"
        case .C: priorityLetter = "C"
        case .D: priorityLetter = "D"
        }
        try container.encode(priorityLetter, forKey: .priority)

        try container.encode(objectiveType.rawValue, forKey: .objectiveType)
        try container.encode(sport.rawValue, forKey: .sport)
        try container.encodeIfPresent(raceFormat?.rawValue, forKey: .raceFormat)
        try container.encodeIfPresent(distanceValue, forKey: .distanceValue)
        try container.encodeIfPresent(distanceUnit?.rawValue, forKey: .distanceUnit)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(targetTime, forKey: .targetTime)
        try container.encodeIfPresent(location, forKey: .location)
    }

    // MARK: - Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decode(String.self, forKey: .name)

        // Date parsing
        if let dateString = try? container.decode(String.self, forKey: .targetDate) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            targetDate = formatter.date(from: dateString) ?? Date()
        } else {
            targetDate = Date()
        }

        // Priority parsing (accepte "A", "B", "C", "D" ou les valeurs complètes)
        if let priorityStr = try? container.decode(String.self, forKey: .priority) {
            switch priorityStr.uppercased() {
            case "A", "PRINCIPAL": priority = .A
            case "B", "SECONDARY": priority = .B
            case "C", "TERTIARY": priority = .C
            case "D", "TRAINING": priority = .D
            default: priority = .A
            }
        } else {
            priority = .A
        }

        objectiveType = try container.decodeIfPresent(TrainingObjectiveType.self, forKey: .objectiveType) ?? .race
        sport = try container.decodeIfPresent(ObjectiveSport.self, forKey: .sport) ?? .running
        raceFormat = try container.decodeIfPresent(TrainingRaceFormat.self, forKey: .raceFormat)
        distanceValue = try container.decodeIfPresent(Double.self, forKey: .distanceValue)
        distanceUnit = try container.decodeIfPresent(DistanceUnit.self, forKey: .distanceUnit)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        targetTime = try container.decodeIfPresent(String.self, forKey: .targetTime)
        location = try container.decodeIfPresent(String.self, forKey: .location)
    }

    // MARK: - To Dictionary (for API)

    func toDictionary() -> [String: Any] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var dict: [String: Any] = [
            "name": name,
            "target_date": formatter.string(from: targetDate),
            "priority": priority.rawValue, // "principal", "secondary", "tertiary", "training"
            "objective_type": objectiveType.rawValue,
            "sport": sport.rawValue
        ]

        if let raceFormat = raceFormat {
            dict["race_format"] = raceFormat.rawValue
        }
        if let distanceValue = distanceValue {
            dict["distance_value"] = distanceValue
        }
        if let distanceUnit = distanceUnit {
            dict["distance_unit"] = distanceUnit.rawValue
        }
        if let description = description, !description.isEmpty {
            dict["description"] = description
        }
        if let targetTime = targetTime, !targetTime.isEmpty {
            dict["target_time"] = targetTime
        }
        if let location = location, !location.isEmpty {
            dict["location"] = location
        }

        return dict
    }
}

// MARK: - Preview Helpers

extension TrainingObjective {
    static var preview: TrainingObjective {
        TrainingObjective(
            name: "Marathon de Paris",
            targetDate: Date().addingTimeInterval(60 * 60 * 24 * 120),
            priority: .A,
            objectiveType: .race,
            sport: .running,
            raceFormat: .marathon,
            targetTime: "3h30",
            location: "Paris, France"
        )
    }

    static var previewList: [TrainingObjective] {
        [
            TrainingObjective(
                name: "Marathon de Paris",
                targetDate: Date().addingTimeInterval(60 * 60 * 24 * 120),
                priority: .A,
                objectiveType: .race,
                sport: .running,
                raceFormat: .marathon,
                targetTime: "3h30",
                location: "Paris"
            ),
            TrainingObjective(
                name: "Semi de préparation",
                targetDate: Date().addingTimeInterval(60 * 60 * 24 * 60),
                priority: .B,
                objectiveType: .race,
                sport: .running,
                raceFormat: .halfMarathon,
                targetTime: "1h35",
                location: "Lyon"
            ),
            TrainingObjective(
                name: "Test VMA",
                targetDate: Date().addingTimeInterval(60 * 60 * 24 * 30),
                priority: .D,
                objectiveType: .milestone,
                sport: .running
            )
        ]
    }

    // MARK: - Dev Examples (hardcodé temporairement)

    /// Objectifs par défaut pour le développement - TODO: Supprimer après dev
    static var devExamples: [TrainingObjective] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return [
            TrainingObjective(
                name: "10k Paris",
                targetDate: dateFormatter.date(from: "2026-02-01") ?? Date(),
                priority: .B,
                objectiveType: .race,
                sport: .running,
                raceFormat: .tenK,
                distanceValue: 10.0,
                distanceUnit: .km,
                targetTime: "42:00"
            ),
            TrainingObjective(
                name: "Ironman 70.3 Carcans",
                targetDate: dateFormatter.date(from: "2026-05-16") ?? Date(),
                priority: .A,
                objectiveType: .race,
                sport: .triathlon,
                raceFormat: .halfIronman,
                distanceValue: 113.0,
                distanceUnit: .km,
                targetTime: "5:30:00"
            )
        ]
    }
}
