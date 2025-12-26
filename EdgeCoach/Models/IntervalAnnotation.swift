/**
 * IntervalAnnotation - Modèles pour les annotations d'intervalles
 *
 * Permet d'enrichir chaque lap/intervalle avec :
 * - Équipement utilisé (spécifique par discipline)
 * - Commentaire libre
 * - Ressenti
 * - Données spécifiques par sport (nage, puissance cible, terrain...)
 */

import Foundation

// MARK: - Interval Annotation Model

/// Annotation complète pour un intervalle/lap
struct IntervalAnnotation: Codable, Identifiable, Equatable {
    let id: String
    var lapIndex: Int                           // Index du lap (0-based)
    var equipment: [String]                     // IDs des équipements
    var comment: String?                        // Commentaire libre
    var feeling: IntervalFeeling?               // Ressenti

    // Données spécifiques par sport
    var swimStyle: SwimStyle?                   // Natation uniquement
    var targetPower: Int?                       // Vélo: puissance cible (W)
    var targetCadence: Int?                     // Vélo/Course: cadence cible
    var position: CyclingPosition?              // Vélo: assis/danseuse
    var targetPace: String?                     // Course: allure cible (ex: "4:30")
    var terrain: TerrainType?                   // Course/Vélo: type de terrain

    enum CodingKeys: String, CodingKey {
        case id
        case lapIndex = "lap_index"
        case equipment
        case comment
        case feeling
        case swimStyle = "swim_style"
        case targetPower = "target_power"
        case targetCadence = "target_cadence"
        case position
        case targetPace = "target_pace"
        case terrain
    }

    init(
        id: String = UUID().uuidString,
        lapIndex: Int,
        equipment: [String] = [],
        comment: String? = nil,
        feeling: IntervalFeeling? = nil,
        swimStyle: SwimStyle? = nil,
        targetPower: Int? = nil,
        targetCadence: Int? = nil,
        position: CyclingPosition? = nil,
        targetPace: String? = nil,
        terrain: TerrainType? = nil
    ) {
        self.id = id
        self.lapIndex = lapIndex
        self.equipment = equipment
        self.comment = comment
        self.feeling = feeling
        self.swimStyle = swimStyle
        self.targetPower = targetPower
        self.targetCadence = targetCadence
        self.position = position
        self.targetPace = targetPace
        self.terrain = terrain
    }
}

// MARK: - Interval Group

/// Groupe d'intervalles consécutifs (ex: "Série principale")
struct IntervalGroup: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var lapIndices: [Int]                       // Indices des laps dans le groupe
    var description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case lapIndices = "lap_indices"
        case description
    }

    init(id: String = UUID().uuidString, name: String, lapIndices: [Int], description: String? = nil) {
        self.id = id
        self.name = name
        self.lapIndices = lapIndices
        self.description = description
    }
}

// MARK: - Interval Feeling

/// Ressenti sur un intervalle
enum IntervalFeeling: String, Codable, CaseIterable, Identifiable {
    case good = "good"
    case neutral = "neutral"
    case hard = "hard"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .good: return "Bien"
        case .neutral: return "Moyen"
        case .hard: return "Difficile"
        }
    }

    var icon: String {
        switch self {
        case .good: return "face.smiling"
        case .neutral: return "face.dashed"
        case .hard: return "face.dashed.fill"
        }
    }

    var color: String {
        switch self {
        case .good: return "ecSuccess"
        case .neutral: return "ecWarning"
        case .hard: return "ecError"
        }
    }
}

// MARK: - Swim Style

/// Styles de nage
enum SwimStyle: String, Codable, CaseIterable, Identifiable {
    case freestyle = "freestyle"
    case backstroke = "backstroke"
    case breaststroke = "breaststroke"
    case butterfly = "butterfly"
    case medley = "medley"
    case kick = "kick"
    case pull = "pull"
    case drill = "drill"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .freestyle: return "Crawl"
        case .backstroke: return "Dos"
        case .breaststroke: return "Brasse"
        case .butterfly: return "Papillon"
        case .medley: return "4 nages"
        case .kick: return "Jambes"
        case .pull: return "Bras"
        case .drill: return "Éducatif"
        }
    }

    var icon: String {
        switch self {
        case .freestyle: return "figure.pool.swim"
        case .backstroke: return "arrow.left.and.right"
        case .breaststroke: return "arrow.up.and.down.and.arrow.left.and.right"
        case .butterfly: return "bird"
        case .medley: return "4.circle"
        case .kick: return "figure.walk"
        case .pull: return "hand.raised"
        case .drill: return "wrench.and.screwdriver"
        }
    }
}

// MARK: - Cycling Position

/// Position sur le vélo
enum CyclingPosition: String, Codable, CaseIterable, Identifiable {
    case seated = "seated"
    case standing = "standing"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .seated: return "Assis"
        case .standing: return "Danseuse"
        }
    }
}

// MARK: - Terrain Type

/// Types de terrain
enum TerrainType: String, Codable, CaseIterable, Identifiable {
    case track = "track"
    case road = "road"
    case trail = "trail"
    case treadmill = "treadmill"
    case flat = "flat"
    case hilly = "hilly"
    case mountain = "mountain"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .track: return "Piste"
        case .road: return "Route"
        case .trail: return "Trail"
        case .treadmill: return "Tapis"
        case .flat: return "Plat"
        case .hilly: return "Vallonné"
        case .mountain: return "Montagne"
        }
    }

    var icon: String {
        switch self {
        case .track: return "oval"
        case .road: return "road.lanes"
        case .trail: return "mountain.2"
        case .treadmill: return "figure.run"
        case .flat: return "arrow.right"
        case .hilly: return "chart.line.uptrend.xyaxis"
        case .mountain: return "triangle"
        }
    }

    /// Terrains pour la course
    static var runningTerrains: [TerrainType] {
        [.track, .road, .trail, .treadmill]
    }

    /// Terrains pour le vélo
    static var cyclingTerrains: [TerrainType] {
        [.road, .flat, .hilly, .mountain]
    }
}

// MARK: - Swimming Equipment

/// Équipements de natation
enum SwimmingEquipmentType: String, Codable, CaseIterable, Identifiable {
    case paddlesS = "paddles_s"
    case paddlesM = "paddles_m"
    case paddlesL = "paddles_l"
    case pullBuoy = "pull_buoy"
    case finsShort = "fins_short"
    case finsLong = "fins_long"
    case snorkel = "snorkel"
    case ankleBand = "ankle_band"
    case wetsuit = "wetsuit"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .paddlesS: return "Plaquettes S"
        case .paddlesM: return "Plaquettes M"
        case .paddlesL: return "Plaquettes L"
        case .pullBuoy: return "Pull-buoy"
        case .finsShort: return "Palmes courtes"
        case .finsLong: return "Palmes longues"
        case .snorkel: return "Tuba frontal"
        case .ankleBand: return "Élastique chevilles"
        case .wetsuit: return "Combinaison"
        }
    }

    var icon: String {
        switch self {
        case .paddlesS, .paddlesM, .paddlesL: return "hand.raised"
        case .pullBuoy: return "figure.pool.swim"
        case .finsShort, .finsLong: return "shoe"
        case .snorkel: return "wind"
        case .ankleBand: return "link"
        case .wetsuit: return "tshirt"
        }
    }
}

// MARK: - Cycling Equipment (for intervals)

/// Équipements vélo pour les intervalles
enum CyclingEquipmentType: String, Codable, CaseIterable, Identifiable {
    case roadBike = "road_bike"
    case ttBike = "tt_bike"
    case gravel = "gravel"
    case mtb = "mtb"
    case trainer = "trainer"
    case powerMeter = "power_meter"
    case carbonWheels = "carbon_wheels"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .roadBike: return "Vélo route"
        case .ttBike: return "Vélo CLM"
        case .gravel: return "Gravel"
        case .mtb: return "VTT"
        case .trainer: return "Home trainer"
        case .powerMeter: return "Capteur puissance"
        case .carbonWheels: return "Roues carbone"
        }
    }

    var icon: String {
        switch self {
        case .roadBike: return "bicycle"
        case .ttBike: return "figure.outdoor.cycle"
        case .gravel, .mtb: return "mountain.2"
        case .trainer: return "house"
        case .powerMeter: return "bolt"
        case .carbonWheels: return "circle.circle"
        }
    }
}

// MARK: - Running Equipment (for intervals)

/// Équipements course pour les intervalles
enum RunningEquipmentType: String, Codable, CaseIterable, Identifiable {
    case roadShoes = "road_shoes"
    case trailShoes = "trail_shoes"
    case spikes = "spikes"
    case carbonPlate = "carbon_plate"
    case hrStrap = "hr_strap"
    case stryd = "stryd"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .roadShoes: return "Chaussures route"
        case .trailShoes: return "Chaussures trail"
        case .spikes: return "Pointes"
        case .carbonPlate: return "Plaque carbone"
        case .hrStrap: return "Ceinture cardio"
        case .stryd: return "Stryd"
        }
    }

    var icon: String {
        switch self {
        case .roadShoes, .trailShoes, .spikes, .carbonPlate: return "shoe"
        case .hrStrap: return "heart"
        case .stryd: return "gauge"
        }
    }
}

// MARK: - Helper to get equipment options by discipline

extension Discipline {
    /// Retourne les options d'équipement pour les intervalles selon la discipline
    var intervalEquipmentOptions: [(id: String, label: String, icon: String)] {
        switch self {
        case .natation:
            return SwimmingEquipmentType.allCases.map { ($0.rawValue, $0.label, $0.icon) }
        case .cyclisme:
            return CyclingEquipmentType.allCases.map { ($0.rawValue, $0.label, $0.icon) }
        case .course:
            return RunningEquipmentType.allCases.map { ($0.rawValue, $0.label, $0.icon) }
        case .autre:
            return []
        }
    }
}
