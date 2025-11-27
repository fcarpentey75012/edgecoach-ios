/**
 * Modèles d'activité sportive
 * Correspond aux données brutes retournées par l'API /activities/history
 */

import Foundation

// MARK: - Discipline

enum Discipline: String, Codable, CaseIterable, Identifiable {
    case cyclisme = "cyclisme"
    case course = "course"
    case natation = "natation"
    case autre = "autre"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cyclisme: return "Vélo"
        case .course: return "Course"
        case .natation: return "Natation"
        case .autre: return "Autre"
        }
    }

    var icon: String {
        switch self {
        case .cyclisme: return "bicycle"
        case .course: return "figure.run"
        case .natation: return "figure.pool.swim"
        case .autre: return "figure.strengthtraining.functional"
        }
    }

    /// Convertit le sport de l'API vers une discipline
    static func from(sport: String?) -> Discipline {
        guard let sport = sport?.lowercased() else { return .autre }

        if sport.contains("vélo") || sport.contains("velo") || sport.contains("cycling") || sport.contains("home trainer") {
            return .cyclisme
        } else if sport.contains("course") || sport.contains("running") || sport.contains("run") {
            return .course
        } else if sport.contains("natation") || sport.contains("swimming") || sport.contains("swim") {
            return .natation
        }
        return .autre
    }
}

// MARK: - Activity Model (API Response)

/// Modèle correspondant exactement à la réponse de l'API /activities/history
struct Activity: Codable, Identifiable, Hashable {
    // Hashable conformance based on id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Activity, rhs: Activity) -> Bool {
        lhs.id == rhs.id
    }
    // Identifiants
    let id: String              // _id MongoDB
    let nolioId: Int?           // nolio_id (peut être Int ou absent)
    let userId: String

    // Infos de base
    let dateStart: String       // date_start (YYYY-MM-DD ou ISO)
    let sport: String?          // Sport brut de l'API
    let name: String?

    // Métriques numériques (en nombres, pas strings)
    let duration: Int?          // Durée en secondes
    let distance: Double?       // Distance en km
    let avgWatt: Double?
    let maxWatt: Double?
    let rpe: Int?               // Rating of Perceived Exertion
    let feeling: Int?           // Peut être Int (0-5) ou absent

    // Dénivelé
    let elevationGain: Double?
    let elevationLoss: Double?

    // Charge d'entraînement
    let loadFoster: Double?
    let loadCoggan: Double?     // TSS
    let isCompetition: Bool?
    let kilojoules: Double?

    // Métriques cardio
    let restHrUser: Double?
    let maxHrUser: Double?

    // Puissance
    let np: Double?             // Normalized Power
    let ftp: Double?            // FTP
    let criticalPower: Double?  // CP
    let weight: Double?

    // Zones
    let zones: [ActivityZone]?

    // Fichier et données GPS
    let fileUrl: String?
    let fileDatas: ActivityFileData?

    // Données de séance prévue
    let plannedName: String?
    let plannedSport: String?
    let plannedDescription: String?

    // Description
    let description: String?
    let hourStart: String?

    // Cache
    let cachedAt: String?
    let cacheKey: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case nolioId = "nolio_id"
        case userId = "user_id"
        case dateStart = "date_start"
        case sport
        case name
        case duration
        case distance
        case avgWatt = "avg_watt"
        case maxWatt = "max_watt"
        case rpe
        case feeling
        case elevationGain = "elevation_gain"
        case elevationLoss = "elevation_loss"
        case loadFoster = "load_foster"
        case loadCoggan = "load_coggan"
        case isCompetition = "is_competition"
        case kilojoules
        case restHrUser = "rest_hr_user"
        case maxHrUser = "max_hr_user"
        case np
        case ftp
        case criticalPower = "critical_power"
        case weight
        case zones
        case fileUrl = "file_url"
        case fileDatas = "file_datas"
        case plannedName = "planned_name"
        case plannedSport = "planned_sport"
        case plannedDescription = "planned_description"
        case description
        case hourStart = "hour_start"
        case cachedAt = "cached_at"
        case cacheKey = "cache_key"
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // ID obligatoire
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)

        // nolio_id peut être Int ou String selon l'API
        if let intId = try? container.decodeIfPresent(Int.self, forKey: .nolioId) {
            nolioId = intId
        } else if let stringId = try? container.decodeIfPresent(String.self, forKey: .nolioId),
                  let intValue = Int(stringId) {
            nolioId = intValue
        } else {
            nolioId = nil
        }

        // Date
        dateStart = try container.decode(String.self, forKey: .dateStart)

        // Infos textuelles
        sport = try container.decodeIfPresent(String.self, forKey: .sport)
        name = try container.decodeIfPresent(String.self, forKey: .name)

        // Duration peut être Int ou Double
        if let intDuration = try? container.decodeIfPresent(Int.self, forKey: .duration) {
            duration = intDuration
        } else if let doubleDuration = try? container.decodeIfPresent(Double.self, forKey: .duration) {
            duration = Int(doubleDuration)
        } else {
            duration = nil
        }

        // Distance (toujours en Double)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)

        // Puissance
        avgWatt = try container.decodeIfPresent(Double.self, forKey: .avgWatt)
        maxWatt = try container.decodeIfPresent(Double.self, forKey: .maxWatt)

        // RPE et feeling
        rpe = try container.decodeIfPresent(Int.self, forKey: .rpe)
        feeling = try container.decodeIfPresent(Int.self, forKey: .feeling)

        // Dénivelé
        elevationGain = try container.decodeIfPresent(Double.self, forKey: .elevationGain)
        elevationLoss = try container.decodeIfPresent(Double.self, forKey: .elevationLoss)

        // Charge
        loadFoster = try container.decodeIfPresent(Double.self, forKey: .loadFoster)
        loadCoggan = try container.decodeIfPresent(Double.self, forKey: .loadCoggan)
        isCompetition = try container.decodeIfPresent(Bool.self, forKey: .isCompetition)
        kilojoules = try container.decodeIfPresent(Double.self, forKey: .kilojoules)

        // Cardio
        restHrUser = try container.decodeIfPresent(Double.self, forKey: .restHrUser)
        maxHrUser = try container.decodeIfPresent(Double.self, forKey: .maxHrUser)

        // Puissance avancée
        np = try container.decodeIfPresent(Double.self, forKey: .np)
        ftp = try container.decodeIfPresent(Double.self, forKey: .ftp)
        criticalPower = try container.decodeIfPresent(Double.self, forKey: .criticalPower)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)

        // Zones - peut être un tableau [{zone: 1, ...}] ou un dictionnaire {power: [...], hr: [...]}
        if let zonesArray = try? container.decodeIfPresent([ActivityZone].self, forKey: .zones) {
            zones = zonesArray
        } else if let zonesDict = try? container.decodeIfPresent(ZonesDict.self, forKey: .zones) {
            // Convertir le dictionnaire en tableau de zones (prendre les zones de puissance ou HR)
            zones = zonesDict.toActivityZones()
        } else {
            zones = nil
        }

        // Fichier
        fileUrl = try container.decodeIfPresent(String.self, forKey: .fileUrl)
        fileDatas = try container.decodeIfPresent(ActivityFileData.self, forKey: .fileDatas)

        // Séance prévue
        plannedName = try container.decodeIfPresent(String.self, forKey: .plannedName)
        plannedSport = try container.decodeIfPresent(String.self, forKey: .plannedSport)
        plannedDescription = try container.decodeIfPresent(String.self, forKey: .plannedDescription)

        // Description
        description = try container.decodeIfPresent(String.self, forKey: .description)
        hourStart = try container.decodeIfPresent(String.self, forKey: .hourStart)

        // Cache
        cachedAt = try container.decodeIfPresent(String.self, forKey: .cachedAt)
        cacheKey = try container.decodeIfPresent(String.self, forKey: .cacheKey)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(nolioId, forKey: .nolioId)
        try container.encode(userId, forKey: .userId)
        try container.encode(dateStart, forKey: .dateStart)
        try container.encodeIfPresent(sport, forKey: .sport)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encodeIfPresent(avgWatt, forKey: .avgWatt)
        try container.encodeIfPresent(maxWatt, forKey: .maxWatt)
        try container.encodeIfPresent(rpe, forKey: .rpe)
        try container.encodeIfPresent(feeling, forKey: .feeling)
        try container.encodeIfPresent(elevationGain, forKey: .elevationGain)
        try container.encodeIfPresent(elevationLoss, forKey: .elevationLoss)
        try container.encodeIfPresent(loadFoster, forKey: .loadFoster)
        try container.encodeIfPresent(loadCoggan, forKey: .loadCoggan)
        try container.encodeIfPresent(isCompetition, forKey: .isCompetition)
        try container.encodeIfPresent(kilojoules, forKey: .kilojoules)
        try container.encodeIfPresent(restHrUser, forKey: .restHrUser)
        try container.encodeIfPresent(maxHrUser, forKey: .maxHrUser)
        try container.encodeIfPresent(np, forKey: .np)
        try container.encodeIfPresent(ftp, forKey: .ftp)
        try container.encodeIfPresent(criticalPower, forKey: .criticalPower)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(zones, forKey: .zones)
        try container.encodeIfPresent(fileUrl, forKey: .fileUrl)
        // fileDatas n'est pas encodable (Decodable seulement)
        try container.encodeIfPresent(plannedName, forKey: .plannedName)
        try container.encodeIfPresent(plannedSport, forKey: .plannedSport)
        try container.encodeIfPresent(plannedDescription, forKey: .plannedDescription)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(hourStart, forKey: .hourStart)
        try container.encodeIfPresent(cachedAt, forKey: .cachedAt)
        try container.encodeIfPresent(cacheKey, forKey: .cacheKey)
    }

    // MARK: - Computed Properties

    /// Discipline dérivée du sport
    var discipline: Discipline {
        Discipline.from(sport: sport)
    }

    /// Date parsée
    var date: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        if let date = formatter.date(from: dateStart) {
            return date
        }
        // Essayer format YYYY-MM-DD
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd"
        return simpleFormatter.date(from: dateStart)
    }

    /// Durée formatée (ex: "1:30" ou "45min")
    var formattedDuration: String? {
        guard let seconds = duration else { return nil }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return "\(minutes)min"
        }
    }

    /// Distance formatée (ex: "45.5 km" ou "1500 m")
    var formattedDistance: String? {
        guard let dist = distance else { return nil }
        if discipline == .natation {
            return String(format: "%.0f m", dist * 1000)
        }
        if dist < 1 {
            return String(format: "%.0f m", dist * 1000)
        }
        return dist.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f km", dist)
            : String(format: "%.1f km", dist)
    }

    /// Vitesse moyenne formatée
    var formattedAvgSpeed: String? {
        guard let fileDatas = fileDatas, let avgSpeed = fileDatas.avgSpeed else { return nil }
        return String(format: "%.1f km/h", avgSpeed)
    }

    /// Vitesse max formatée
    var formattedMaxSpeed: String? {
        guard let fileDatas = fileDatas, let maxSpeed = fileDatas.maxSpeed else { return nil }
        return String(format: "%.1f km/h", maxSpeed)
    }

    /// Puissance moyenne formatée
    var formattedAvgPower: String? {
        guard let watts = avgWatt else { return nil }
        return "\(Int(watts))W"
    }

    /// TSS (Training Stress Score)
    var tss: Int? {
        guard let load = loadCoggan else { return nil }
        return Int(load)
    }

    /// Titre affiché
    var displayTitle: String {
        name ?? plannedName ?? discipline.displayName
    }

    /// Notes combinées
    var notes: String? {
        description ?? plannedDescription
    }

    /// Points GPS depuis file_datas
    /// Gère la conversion du format Garmin FIT (semicircles) vers degrés décimaux
    var gpsPoints: [GPSPoint]? {
        fileDatas?.records?.compactMap { record in
            guard let lat = record.positionLat, let lng = record.positionLong else { return nil }

            // Constante pour conversion semicircles -> degrés
            // semicircles = degrés * (2^31 / 180)
            let semicircleToDegrees = 180.0 / pow(2.0, 31.0)

            // Détection du format: si les valeurs sont > 180 ou < -180, c'est en semicircles
            let latitude: Double
            let longitude: Double

            if abs(lat) > 180 || abs(lng) > 180 {
                // Format Garmin FIT semicircles
                latitude = lat * semicircleToDegrees
                longitude = lng * semicircleToDegrees
            } else {
                // Format standard degrés décimaux
                latitude = lat
                longitude = lng
            }

            // Validation des coordonnées
            guard latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180 else {
                return nil
            }

            return GPSPoint(latitude: latitude, longitude: longitude, altitude: record.altitude, timestamp: nil)
        }
    }

    // MARK: - Init for Preview/Testing

    init(id: String, userId: String, dateStart: String, sport: String? = nil, name: String? = nil,
         duration: Int? = nil, distance: Double? = nil, avgWatt: Double? = nil, maxWatt: Double? = nil,
         elevationGain: Double? = nil, elevationLoss: Double? = nil, loadCoggan: Double? = nil) {
        self.id = id
        self.nolioId = nil
        self.userId = userId
        self.dateStart = dateStart
        self.sport = sport
        self.name = name
        self.duration = duration
        self.distance = distance
        self.avgWatt = avgWatt
        self.maxWatt = maxWatt
        self.rpe = nil
        self.feeling = nil
        self.elevationGain = elevationGain
        self.elevationLoss = elevationLoss
        self.loadFoster = nil
        self.loadCoggan = loadCoggan
        self.isCompetition = nil
        self.kilojoules = nil
        self.restHrUser = nil
        self.maxHrUser = nil
        self.np = nil
        self.ftp = nil
        self.criticalPower = nil
        self.weight = nil
        self.zones = nil
        self.fileUrl = nil
        self.fileDatas = nil
        self.plannedName = nil
        self.plannedSport = nil
        self.plannedDescription = nil
        self.description = nil
        self.hourStart = nil
        self.cachedAt = nil
        self.cacheKey = nil
    }
}

// MARK: - Activity Zone

struct ActivityZone: Codable, Identifiable {
    var id: Int { zone }
    let zone: Int
    let timeSeconds: Double
    let percentage: Double

    enum CodingKeys: String, CodingKey {
        case zone
        case timeSeconds = "time_seconds"
        case percentage
    }

    var formattedDuration: String {
        let totalSeconds = Int(timeSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    init(zone: Int, timeSeconds: Double, percentage: Double) {
        self.zone = zone
        self.timeSeconds = timeSeconds
        self.percentage = percentage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        zone = try container.decode(Int.self, forKey: .zone)
        
        if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: .timeSeconds) {
            timeSeconds = doubleVal
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .timeSeconds) {
            timeSeconds = Double(intVal)
        } else {
            timeSeconds = 0
        }
        
        percentage = try container.decode(Double.self, forKey: .percentage)
    }
}

// MARK: - Zones Dictionary Format

/// Structure pour gérer le format dictionnaire des zones {power: [...], hr: [...]}
struct ZonesDict: Codable {
    let power: [ZoneDictEntry]?
    let hr: [ZoneDictEntry]?

    struct ZoneDictEntry: Codable {
        let zone: Int?
        let zoneNumber: Int?
        let timeSeconds: Int?
        let time: Int?
        let percentage: Double?
        let percent: Double?

        enum CodingKeys: String, CodingKey {
            case zone
            case zoneNumber = "zone_number"
            case timeSeconds = "time_seconds"
            case time
            case percentage
            case percent
        }

        var resolvedZone: Int {
            zone ?? zoneNumber ?? 0
        }

        var resolvedTimeSeconds: Int {
            timeSeconds ?? time ?? 0
        }

        var resolvedPercentage: Double {
            percentage ?? percent ?? 0
        }
    }

    /// Convertit le dictionnaire en tableau d'ActivityZone
    func toActivityZones() -> [ActivityZone]? {
        // Préférer les zones de puissance, sinon utiliser HR
        let entries = power ?? hr
        guard let entries = entries, !entries.isEmpty else { return nil }

        return entries.compactMap { entry in
            let zone = entry.resolvedZone
            guard zone > 0 else { return nil }
            return ActivityZone(
                zone: zone,
                timeSeconds: Double(entry.resolvedTimeSeconds),
                percentage: entry.resolvedPercentage
            )
        }.sorted { $0.zone < $1.zone }
    }
}

// MARK: - Activity File Data

struct ActivityFileData: Decodable {
    let records: [ActivityRecord]?
    let laps: [ActivityLap]?
    let duration: Double?
    let ascent: Double?
    let descent: Double?
    let avgSpeed: Double?
    let maxSpeed: Double?
    let avgSpeedMovingKmh: Double?
    let hrAvg: Double?
    let hrMax: Double?
    let hrMin: Double?
    let cadenceAvg: Double?
    let cadenceMax: Double?
    let calories: Double?
    let startTime: String?
    let endTime: String?
    let altitudeAvg: Double?
    let altitudeMin: Double?
    let altitudeMax: Double?

    enum CodingKeys: String, CodingKey {
        case records
        case recordData = "record_data"
        case laps
        case allLaps = "all_laps"
        case duration
        case ascent
        case descent
        case avgSpeed = "avg_speed"
        case maxSpeed = "max_speed"
        case avgSpeedMovingKmh = "avg_speed_moving_kmh"
        case hrAvg = "hr_avg"
        case hrMax = "hr_max"
        case hrMin = "hr_min"
        case cadenceAvg = "cadence_avg"
        case cadenceMax = "cadence_max"
        case calories
        case startTime = "start_time"
        case endTime = "end_time"
        case altitudeAvg = "altitude_avg"
        case altitudeMin = "altitude_min"
        case altitudeMax = "altitude_max"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Records peut être sous "records" ou "record_data"
        if let recs = try container.decodeIfPresent([ActivityRecord].self, forKey: .records) {
            records = recs
        } else if let recs = try container.decodeIfPresent([ActivityRecord].self, forKey: .recordData) {
            records = recs
        } else {
            records = nil
        }

        // Laps peut être sous "laps" ou "all_laps"
        // On assigne les index après décodage pour avoir des IDs uniques
        // On déduplique aussi les laps identiques (même distance, durée, et données)
        if var lapsData = try container.decodeIfPresent([ActivityLap].self, forKey: .laps) {
            lapsData = Self.deduplicateLaps(lapsData)
            for i in 0..<lapsData.count {
                lapsData[i].lapIndex = i
            }
            laps = lapsData
        } else if var lapsData = try container.decodeIfPresent([ActivityLap].self, forKey: .allLaps) {
            lapsData = Self.deduplicateLaps(lapsData)
            for i in 0..<lapsData.count {
                lapsData[i].lapIndex = i
            }
            laps = lapsData
        } else {
            laps = nil
        }

        duration = try container.decodeIfPresent(Double.self, forKey: .duration)
        ascent = try container.decodeIfPresent(Double.self, forKey: .ascent)
        descent = try container.decodeIfPresent(Double.self, forKey: .descent)
        avgSpeed = try container.decodeIfPresent(Double.self, forKey: .avgSpeed)
        maxSpeed = try container.decodeIfPresent(Double.self, forKey: .maxSpeed)
        avgSpeedMovingKmh = try container.decodeIfPresent(Double.self, forKey: .avgSpeedMovingKmh)
        hrAvg = try container.decodeIfPresent(Double.self, forKey: .hrAvg)
        hrMax = try container.decodeIfPresent(Double.self, forKey: .hrMax)
        hrMin = try container.decodeIfPresent(Double.self, forKey: .hrMin)
        cadenceAvg = try container.decodeIfPresent(Double.self, forKey: .cadenceAvg)
        cadenceMax = try container.decodeIfPresent(Double.self, forKey: .cadenceMax)
        calories = try container.decodeIfPresent(Double.self, forKey: .calories)
        startTime = try container.decodeIfPresent(String.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(String.self, forKey: .endTime)
        altitudeAvg = try container.decodeIfPresent(Double.self, forKey: .altitudeAvg)
        altitudeMin = try container.decodeIfPresent(Double.self, forKey: .altitudeMin)
        altitudeMax = try container.decodeIfPresent(Double.self, forKey: .altitudeMax)
    }

    // MARK: - Lap Deduplication

    /// Déduplique les laps qui ont exactement les mêmes données
    /// Cela arrive quand l'API renvoie le même lap plusieurs fois
    static func deduplicateLaps(_ laps: [ActivityLap]) -> [ActivityLap] {
        var seen = Set<String>()
        var unique: [ActivityLap] = []

        for lap in laps {
            // Créer une clé unique basée sur les données du lap
            let key = "\(lap.distance ?? 0)-\(lap.duration ?? 0)-\(lap.avgHeartRate ?? 0)-\(lap.avgSpeedKmh ?? 0)-\(lap.startTime ?? 0)"

            if !seen.contains(key) {
                seen.insert(key)
                unique.append(lap)
            }
        }

        #if DEBUG
        if unique.count != laps.count {
            print("🏃 Laps: Deduplicated from \(laps.count) to \(unique.count) laps")
        }
        #endif

        return unique
    }
}

// MARK: - Activity Record (GPS point with metrics)

/// Supporte plusieurs formats de coordonnées GPS:
/// - Format Garmin FIT: position_lat/position_long (en semicircles)
/// - Format TCX: lat/lng ou lat/lon
/// - Format standard: latitude/longitude
struct ActivityRecord: Decodable {
    let timestamp: Double?
    let positionLat: Double?
    let positionLong: Double?
    let distance: Double?
    let altitude: Double?
    let heartRate: Double?
    let cadence: Double?
    let power: Double?
    let speed: Double?
    let temperature: Double?

    enum CodingKeys: String, CodingKey {
        case timestamp
        // Format Garmin FIT
        case positionLat = "position_lat"
        case positionLong = "position_long"
        // Format TCX/alternatif
        case lat
        case lng
        case lon
        // Format standard
        case latitude
        case longitude
        // Autres
        case distance
        case altitude
        case enhancedAltitude = "enhanced_altitude"
        case heartRate = "heart_rate"
        case hr
        case cadence
        case power
        case speed
        case enhancedSpeed = "enhanced_speed"
        case temperature
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Timestamp: String or Double
        if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: .timestamp) {
            timestamp = doubleVal
        } else if let stringVal = try? container.decodeIfPresent(String.self, forKey: .timestamp),
                  let doubleVal = Double(stringVal) {
            timestamp = doubleVal
        } else {
            timestamp = nil
        }

        // Position Latitude: supporte position_lat, lat, ou latitude
        if let val = try? container.decodeIfPresent(Double.self, forKey: .positionLat) {
            positionLat = val
        } else if let val = try? container.decodeIfPresent(Double.self, forKey: .lat) {
            positionLat = val
        } else if let val = try? container.decodeIfPresent(Double.self, forKey: .latitude) {
            positionLat = val
        } else {
            positionLat = nil
        }

        // Position Longitude: supporte position_long, lng, lon, ou longitude
        if let val = try? container.decodeIfPresent(Double.self, forKey: .positionLong) {
            positionLong = val
        } else if let val = try? container.decodeIfPresent(Double.self, forKey: .lng) {
            positionLong = val
        } else if let val = try? container.decodeIfPresent(Double.self, forKey: .lon) {
            positionLong = val
        } else if let val = try? container.decodeIfPresent(Double.self, forKey: .longitude) {
            positionLong = val
        } else {
            positionLong = nil
        }

        distance = try container.decodeIfPresent(Double.self, forKey: .distance)

        // Altitude: supporte altitude ou enhanced_altitude
        if let val = try? container.decodeIfPresent(Double.self, forKey: .altitude) {
            altitude = val
        } else if let val = try? container.decodeIfPresent(Double.self, forKey: .enhancedAltitude) {
            altitude = val
        } else {
            altitude = nil
        }

        // Speed: supporte speed ou enhanced_speed
        if let val = try? container.decodeIfPresent(Double.self, forKey: .speed) {
            speed = val
        } else if let val = try? container.decodeIfPresent(Double.self, forKey: .enhancedSpeed) {
            speed = val
        } else {
            speed = nil
        }

        temperature = try container.decodeIfPresent(Double.self, forKey: .temperature)

        // Heart Rate: supporte heart_rate ou hr, et String/Int/Double
        if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: .heartRate) {
            heartRate = doubleVal
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .heartRate) {
            heartRate = Double(intVal)
        } else if let stringVal = try? container.decodeIfPresent(String.self, forKey: .heartRate),
                  let doubleVal = Double(stringVal) {
            heartRate = doubleVal
        } else if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: .hr) {
            heartRate = doubleVal
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .hr) {
            heartRate = Double(intVal)
        } else {
            heartRate = nil
        }

        // Cadence: String, Int or Double
        if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: .cadence) {
            cadence = doubleVal
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .cadence) {
            cadence = Double(intVal)
        } else if let stringVal = try? container.decodeIfPresent(String.self, forKey: .cadence),
                  let doubleVal = Double(stringVal) {
            cadence = doubleVal
        } else {
            cadence = nil
        }

        // Power: String, Int or Double
        if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: .power) {
            power = doubleVal
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .power) {
            power = Double(intVal)
        } else if let stringVal = try? container.decodeIfPresent(String.self, forKey: .power),
                  let doubleVal = Double(stringVal) {
            power = doubleVal
        } else {
            power = nil
        }
    }
}

// MARK: - Activity Lap

/// Supporte plusieurs formats de données laps de l'API:
/// - Format Garmin FIT: total_elapsed_time, avg_speed (m/s), avg_heart_rate, avg_power, avg_cadence
/// - Format traité: duration, avg_speed_kmh, hr_avg, tpx_ext_stats.Watts.avg, cadence_avg
struct ActivityLap: Decodable, Identifiable {
    // ID unique - assigné après décodage
    var lapIndex: Int = 0
    var id: Int { lapIndex }

    // Timestamp de début du lap (pour différencier les laps)
    let startTime: Double?

    // Données de base
    let distance: Double?      // en mètres
    let duration: Double?      // en secondes

    // Vitesse (stockée en km/h pour uniformité)
    let avgSpeedKmh: Double?
    let maxSpeedKmh: Double?

    // Cardio
    let avgHeartRate: Double?
    let maxHeartRate: Double?

    // Puissance
    let avgPower: Double?
    let maxPower: Double?

    // Cadence
    let avgCadence: Double?

    // Dénivelé
    let ascent: Double?
    let descent: Double?

    // Calories
    let calories: Double?

    enum CodingKeys: String, CodingKey {
        case distance
        // Duration formats
        case duration
        case totalElapsedTime = "total_elapsed_time"
        // Start time (pour identifier chaque lap)
        case startTime = "start_time"
        case timestamp
        // Speed formats
        case avgSpeed = "avg_speed"
        case avgSpeedKmh = "avg_speed_kmh"
        case maxSpeed = "max_speed"
        case maxSpeedKmh = "max_speed_kmh"
        // Heart rate formats
        case avgHeartRate = "avg_heart_rate"
        case hrAvg = "hr_avg"
        case maxHeartRate = "max_heart_rate"
        case hrMax = "hr_max"
        // Power formats
        case avgPower = "avg_power"
        case maxPower = "max_power"
        case tpxExtStats = "tpx_ext_stats"
        // Cadence formats
        case avgCadence = "avg_cadence"
        case cadenceAvg = "cadence_avg"
        // Elevation
        case ascent
        case descent
        // Calories
        case calories
    }

    // Structure pour les stats TPX (Garmin extension)
    struct TpxExtStats: Decodable {
        let watts: WattsStats?

        enum CodingKeys: String, CodingKey {
            case watts = "Watts"
        }

        struct WattsStats: Decodable {
            let avg: Double?
            let max: Double?
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // lapIndex sera assigné après décodage par ActivityFileData
        lapIndex = 0

        // Start time - pour identifier chaque lap
        if let st = try? container.decodeIfPresent(Double.self, forKey: .startTime) {
            startTime = st
        } else if let ts = try? container.decodeIfPresent(Double.self, forKey: .timestamp) {
            startTime = ts
        } else {
            startTime = nil
        }

        // Distance
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)

        // Duration: chercher "duration" ou "total_elapsed_time"
        if let dur = try? container.decodeIfPresent(Double.self, forKey: .duration) {
            duration = dur
        } else if let dur = try? container.decodeIfPresent(Double.self, forKey: .totalElapsedTime) {
            duration = dur
        } else {
            duration = nil
        }

        // Vitesse moyenne: chercher avg_speed_kmh (déjà en km/h) ou avg_speed (en m/s)
        if let speedKmh = try? container.decodeIfPresent(Double.self, forKey: .avgSpeedKmh) {
            avgSpeedKmh = speedKmh
        } else if let speedMs = try? container.decodeIfPresent(Double.self, forKey: .avgSpeed) {
            // Convertir m/s en km/h
            avgSpeedKmh = speedMs * 3.6
        } else {
            avgSpeedKmh = nil
        }

        // Vitesse max
        if let speedKmh = try? container.decodeIfPresent(Double.self, forKey: .maxSpeedKmh) {
            maxSpeedKmh = speedKmh
        } else if let speedMs = try? container.decodeIfPresent(Double.self, forKey: .maxSpeed) {
            maxSpeedKmh = speedMs * 3.6
        } else {
            maxSpeedKmh = nil
        }

        // FC moyenne: chercher hr_avg ou avg_heart_rate
        if let hr = try? container.decodeIfPresent(Double.self, forKey: .hrAvg) {
            avgHeartRate = hr
        } else if let hr = try? container.decodeIfPresent(Double.self, forKey: .avgHeartRate) {
            avgHeartRate = hr
        } else if let hr = try? container.decodeIfPresent(Int.self, forKey: .hrAvg) {
            avgHeartRate = Double(hr)
        } else if let hr = try? container.decodeIfPresent(Int.self, forKey: .avgHeartRate) {
            avgHeartRate = Double(hr)
        } else {
            avgHeartRate = nil
        }

        // FC max
        if let hr = try? container.decodeIfPresent(Double.self, forKey: .hrMax) {
            maxHeartRate = hr
        } else if let hr = try? container.decodeIfPresent(Double.self, forKey: .maxHeartRate) {
            maxHeartRate = hr
        } else if let hr = try? container.decodeIfPresent(Int.self, forKey: .hrMax) {
            maxHeartRate = Double(hr)
        } else if let hr = try? container.decodeIfPresent(Int.self, forKey: .maxHeartRate) {
            maxHeartRate = Double(hr)
        } else {
            maxHeartRate = nil
        }

        // Puissance: chercher dans tpx_ext_stats.Watts ou avg_power
        let tpxStats = try? container.decodeIfPresent(TpxExtStats.self, forKey: .tpxExtStats)
        if let power = tpxStats?.watts?.avg {
            avgPower = power
        } else if let power = try? container.decodeIfPresent(Double.self, forKey: .avgPower) {
            avgPower = power
        } else if let power = try? container.decodeIfPresent(Int.self, forKey: .avgPower) {
            avgPower = Double(power)
        } else {
            avgPower = nil
        }

        if let power = tpxStats?.watts?.max {
            maxPower = power
        } else if let power = try? container.decodeIfPresent(Double.self, forKey: .maxPower) {
            maxPower = power
        } else if let power = try? container.decodeIfPresent(Int.self, forKey: .maxPower) {
            maxPower = Double(power)
        } else {
            maxPower = nil
        }

        // Cadence: chercher cadence_avg ou avg_cadence
        if let cad = try? container.decodeIfPresent(Double.self, forKey: .cadenceAvg) {
            avgCadence = cad
        } else if let cad = try? container.decodeIfPresent(Double.self, forKey: .avgCadence) {
            avgCadence = cad
        } else if let cad = try? container.decodeIfPresent(Int.self, forKey: .cadenceAvg) {
            avgCadence = Double(cad)
        } else if let cad = try? container.decodeIfPresent(Int.self, forKey: .avgCadence) {
            avgCadence = Double(cad)
        } else {
            avgCadence = nil
        }

        // Dénivelé
        ascent = try container.decodeIfPresent(Double.self, forKey: .ascent)
        descent = try container.decodeIfPresent(Double.self, forKey: .descent)

        // Calories
        calories = try container.decodeIfPresent(Double.self, forKey: .calories)
    }

    // MARK: - Computed Properties

    /// Durée formatée (MM:SS ou HH:MM:SS)
    var formattedDuration: String {
        guard let dur = duration else { return "--:--" }
        let seconds = Int(dur)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    /// Distance formatée
    var formattedDistance: String {
        guard let dist = distance else { return "-" }
        if dist >= 1000 {
            return String(format: "%.2f km", dist / 1000)
        } else {
            return String(format: "%.0f m", dist)
        }
    }

    /// Allure formatée (min:sec /km) - pour course
    var formattedPacePerKm: String? {
        guard let speed = avgSpeedKmh, speed > 0 else { return nil }
        let paceMinKm = 60.0 / speed
        let minutes = Int(paceMinKm)
        let seconds = Int((paceMinKm - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Allure formatée (min:sec /100m) - pour natation
    var formattedPacePer100m: String? {
        guard let speed = avgSpeedKmh, speed > 0 else { return nil }
        // speed est en km/h, on veut min/100m
        let pacePer100m = 6.0 / speed // 60 / (speed * 10) = 6 / speed
        let minutes = Int(pacePer100m)
        let seconds = Int((pacePer100m - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Vitesse formatée (km/h)
    var formattedSpeed: String? {
        guard let speed = avgSpeedKmh, speed > 0 else { return nil }
        return String(format: "%.1f km/h", speed)
    }
}

// MARK: - GPS Point

struct GPSPoint: Codable, Identifiable, Equatable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lng"
        case altitude
        case timestamp
    }

    init(latitude: Double, longitude: Double, altitude: Double? = nil, timestamp: Date? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
    }

    static func == (lhs: GPSPoint, rhs: GPSPoint) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
