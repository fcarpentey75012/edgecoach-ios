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
/// FORMAT PIVOT: Utilise activity_id, provider, external_id pour l'identification
struct Activity: Codable, Identifiable, Hashable {
    // Hashable conformance based on id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Activity, rhs: Activity) -> Bool {
        lhs.id == rhs.id
    }

    // === IDENTIFIANTS FORMAT PIVOT ===
    let id: String              // _id MongoDB
    let activityId: String?     // activity_id (UUID) - NOUVEAU FORMAT PIVOT
    let provider: String?       // Provider source: "nolio", "wahoo", "fit_file", "tcx_file", etc.
    let externalId: String?     // ID externe du système source (ex-nolio_id, wahoo_id)
    let userId: String

    // === INFOS DE BASE ===
    let dateStart: String       // date_start (YYYY-MM-DD ou ISO)
    let startTime: String?      // Heure de début ISO
    let sport: String?          // Sport normalisé (cycling, running, swimming)
    let name: String?
    let description: String?
    let isCompetition: Bool?

    // === MÉTRIQUES (toutes depuis file_datas) ===
    // Note: Les métriques sont maintenant accessibles uniquement via fileDatas
    // Utiliser les computed properties: preferredDuration, preferredDistance, etc.

    // === FEEDBACK SUBJECTIF ===
    let rpe: Int?               // Rating of Perceived Exertion (0-10)
    let feeling: Int?           // Ressenti (0-5)

    // === PLANIFICATION ===
    let plannedSessionId: String? // ID séance planifiée liée
    let plannedName: String?
    let plannedDescription: String?

    // === SOURCE FICHIER ===
    let fileUrl: String?
    let fileHash: String?       // Hash SHA256 pour déduplication

    // === DONNÉES COMPLÈTES ===
    let fileDatas: ActivityFileData?

    // === MÉTADONNÉES ===
    let cachedAt: String?
    let createdAt: String?
    let updatedAt: String?

    // === COMPUTED PROPERTIES (compatibilité) ===

    /// Discipline calculée depuis le sport
    var discipline: Discipline {
        Discipline.from(sport: sport)
    }

    enum CodingKeys: String, CodingKey {
        // === IDENTIFIANTS FORMAT PIVOT ===
        case id = "_id"
        case activityId = "activity_id"
        case provider
        case externalId = "external_id"
        case userId = "user_id"

        // === INFOS DE BASE ===
        case dateStart = "date_start"
        case startTime = "start_time"
        case sport
        case name
        case description
        case isCompetition = "is_competition"

        // === MÉTRIQUES (toutes depuis file_datas) ===
        // Les métriques sont maintenant uniquement dans file_datas

        // === FEEDBACK SUBJECTIF ===
        case rpe
        case feeling

        // === PLANIFICATION ===
        case plannedSessionId = "planned_session_id"
        case plannedName = "planned_name"
        case plannedDescription = "planned_description"

        // === SOURCE FICHIER ===
        case fileUrl = "file_url"
        case fileHash = "file_hash"

        // === DONNÉES COMPLÈTES ===
        case fileDatas = "file_datas"

        // === MÉTADONNÉES ===
        case cachedAt = "cached_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // === IDENTIFIANTS FORMAT PIVOT ===
        id = try container.decode(String.self, forKey: .id)
        activityId = try container.decodeIfPresent(String.self, forKey: .activityId)
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        userId = try container.decode(String.self, forKey: .userId)

        // === INFOS DE BASE ===
        dateStart = try container.decode(String.self, forKey: .dateStart)
        startTime = try container.decodeIfPresent(String.self, forKey: .startTime)
        sport = try container.decodeIfPresent(String.self, forKey: .sport)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        isCompetition = try container.decodeIfPresent(Bool.self, forKey: .isCompetition)

        // === MÉTRIQUES ===
        // Toutes les métriques sont maintenant dans file_datas

        // === FEEDBACK SUBJECTIF ===
        rpe = try container.decodeIfPresent(Int.self, forKey: .rpe)
        feeling = try container.decodeIfPresent(Int.self, forKey: .feeling)

        // === PLANIFICATION ===
        plannedSessionId = try container.decodeIfPresent(String.self, forKey: .plannedSessionId)
        plannedName = try container.decodeIfPresent(String.self, forKey: .plannedName)
        plannedDescription = try container.decodeIfPresent(String.self, forKey: .plannedDescription)

        // === SOURCE FICHIER ===
        fileUrl = try container.decodeIfPresent(String.self, forKey: .fileUrl)
        fileHash = try container.decodeIfPresent(String.self, forKey: .fileHash)

        // === DONNÉES COMPLÈTES ===
        // file_datas peut être un String (JSON) ou un Object
        if let data = try? container.decodeIfPresent(ActivityFileData.self, forKey: .fileDatas) {
            fileDatas = data
        } else if let jsonString = try? container.decodeIfPresent(String.self, forKey: .fileDatas) {
            if let data = jsonString.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(ActivityFileData.self, from: data) {
                fileDatas = decoded
            } else {
                fileDatas = nil
            }
        } else {
            fileDatas = nil
        }

        // === MÉTADONNÉES ===
        cachedAt = try container.decodeIfPresent(String.self, forKey: .cachedAt)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // === IDENTIFIANTS FORMAT PIVOT ===
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(activityId, forKey: .activityId)
        try container.encodeIfPresent(provider, forKey: .provider)
        try container.encodeIfPresent(externalId, forKey: .externalId)
        try container.encode(userId, forKey: .userId)

        // === INFOS DE BASE ===
        try container.encode(dateStart, forKey: .dateStart)
        try container.encodeIfPresent(startTime, forKey: .startTime)
        try container.encodeIfPresent(sport, forKey: .sport)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(isCompetition, forKey: .isCompetition)

        // === MÉTRIQUES ===
        // Toutes les métriques sont dans file_datas

        // === FEEDBACK SUBJECTIF ===
        try container.encodeIfPresent(rpe, forKey: .rpe)
        try container.encodeIfPresent(feeling, forKey: .feeling)

        // === PLANIFICATION ===
        try container.encodeIfPresent(plannedSessionId, forKey: .plannedSessionId)
        try container.encodeIfPresent(plannedName, forKey: .plannedName)
        try container.encodeIfPresent(plannedDescription, forKey: .plannedDescription)

        // === SOURCE FICHIER ===
        try container.encodeIfPresent(fileUrl, forKey: .fileUrl)
        try container.encodeIfPresent(fileHash, forKey: .fileHash)

        // === MÉTADONNÉES ===
        try container.encodeIfPresent(cachedAt, forKey: .cachedAt)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }

    // MARK: - Computed Properties

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
    /// Utilise uniquement fileDatas.movingTime (temps en mouvement sans pauses)
    var formattedDuration: String? {
        guard let movingTime = fileDatas?.movingTime, movingTime > 0 else {
            // Fallback sur duration de fileDatas
            guard let dur = fileDatas?.duration, dur > 0 else { return nil }
            let seconds = Int(dur)
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            if hours > 0 {
                return String(format: "%d:%02d", hours, minutes)
            } else {
                return "\(minutes)min"
            }
        }

        let seconds = Int(movingTime)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return "\(minutes)min"
        }
    }

    /// Distance formatée (ex: "45.5 km" ou "1500 m")
    /// Utilise uniquement fileDatas.distance
    var formattedDistance: String? {
        guard let dist = fileDatas?.distance, dist > 0 else { return nil }
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

    /// Puissance moyenne formatée (file_datas uniquement - découplé de Nolio)
    var formattedAvgPower: String? {
        guard let watts = preferredAvgPower else { return nil }
        return "\(Int(watts))W"
    }

    /// TSS (Training Stress Score) (file_datas uniquement - découplé de Nolio)
    var tss: Int? {
        guard let tssValue = preferredTSS else { return nil }
        return Int(tssValue)
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

    init(
        id: String,
        userId: String,
        dateStart: String,
        sport: String? = nil,
        name: String? = nil,
        description: String? = nil,
        fileDatas: ActivityFileData? = nil
    ) {
        self.id = id
        self.activityId = nil
        self.provider = nil
        self.externalId = nil
        self.userId = userId
        self.dateStart = dateStart
        self.startTime = nil
        self.sport = sport
        self.name = name
        self.description = description
        self.isCompetition = nil
        self.rpe = nil
        self.feeling = nil
        self.plannedSessionId = nil
        self.plannedName = nil
        self.plannedDescription = nil
        self.fileUrl = nil
        self.fileHash = nil
        self.fileDatas = fileDatas
        self.cachedAt = nil
        self.createdAt = nil
        self.updatedAt = nil
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
    let movingTime: Double?          // Temps en mouvement (sans les pauses)
    let distance: Double?            // Distance totale en km
    let ascent: Double?
    let descent: Double?
    let avgSpeed: Double?            // Vitesse moyenne EN MOUVEMENT (km/h) - c'est ce qu'on veut afficher
    let avgSpeedTotal: Double?       // Vitesse moyenne totale incluant pauses (km/h)
    let maxSpeed: Double?            // Vitesse max (km/h)
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

    // MARK: - Power Metrics (découplage Nolio)
    let avgPower: Double?            // Puissance moyenne (W)
    let maxPower: Double?            // Puissance max (W)
    let normalizedPower: Double?     // Normalized Power - NP (W)
    let kilojoules: Double?          // Énergie totale (kJ)

    // MARK: - Training Load (découplage Nolio)
    let trainingStressScore: Double? // TSS
    let trimp: Double?               // TRIMP (Training Impulse)

    enum CodingKeys: String, CodingKey {
        case records
        case recordData = "record_data"
        case laps
        case allLaps = "all_laps"
        case duration
        case movingTime = "moving_time"
        case timerTime = "timer_time"
        case distance
        case distanceKm = "distance_km"
        case totalDistance = "total_distance"
        case ascent
        case descent
        // Vitesse - plusieurs formats possibles
        case avgSpeed = "avg_speed"
        case avgSpeedKmh = "avg_speed_kmh"
        case avgSpeedMovingKmh = "avg_speed_moving_kmh"
        case avgSpeedMs = "avg_speed_ms"
        case maxSpeed = "max_speed"
        case maxSpeedKmh = "max_speed_kmh"
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
        // Power metrics
        case avgPower = "avg_power"
        case maxPower = "max_power"
        case normalizedPower = "normalized_power"
        case npCalculated = "np_calculated"
        case kilojoules
        case kilojoulesCalculated = "kilojoules_calculated"
        // Training load
        case trainingStressScore = "training_stress_score"
        case tssDevice = "tss_device"
        case trimp
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

        // Moving time - peut être sous moving_time ou timer_time
        if let mt = try? container.decodeIfPresent(Double.self, forKey: .movingTime) {
            movingTime = mt
        } else if let tt = try? container.decodeIfPresent(Double.self, forKey: .timerTime) {
            movingTime = tt
        } else {
            movingTime = nil
        }

        // Distance - peut être sous distance, distance_km, ou total_distance (en km)
        if let dist = try? container.decodeIfPresent(Double.self, forKey: .distance), dist > 0 {
            distance = dist
        } else if let dist = try? container.decodeIfPresent(Double.self, forKey: .distanceKm), dist > 0 {
            distance = dist
        } else if let dist = try? container.decodeIfPresent(Double.self, forKey: .totalDistance), dist > 0 {
            // total_distance peut être en mètres, convertir en km
            distance = dist > 1000 ? dist / 1000 : dist
        } else {
            distance = nil
        }

        ascent = try container.decodeIfPresent(Double.self, forKey: .ascent)
        descent = try container.decodeIfPresent(Double.self, forKey: .descent)

        // Vitesses - Le backend renvoie maintenant TOUJOURS en km/h
        // Priorité: avg_speed_moving_kmh (vitesse en mouvement, sans pauses) > avg_speed_kmh > avg_speed
        if let speedMoving = try? container.decodeIfPresent(Double.self, forKey: .avgSpeedMovingKmh), speedMoving > 0 {
            avgSpeed = speedMoving  // Vitesse en mouvement (excluant les pauses) - la plus précise
        } else if let speedKmh = try? container.decodeIfPresent(Double.self, forKey: .avgSpeedKmh), speedKmh > 0 {
            avgSpeed = speedKmh
        } else if let speed = try? container.decodeIfPresent(Double.self, forKey: .avgSpeed), speed > 0 {
            avgSpeed = speed  // Déjà en km/h depuis le backend corrigé
        } else {
            avgSpeed = nil
        }
        avgSpeedTotal = nil

        // Vitesse max - aussi en km/h
        if let maxKmh = try? container.decodeIfPresent(Double.self, forKey: .maxSpeedKmh), maxKmh > 0 {
            maxSpeed = maxKmh
        } else if let max = try? container.decodeIfPresent(Double.self, forKey: .maxSpeed), max > 0 {
            maxSpeed = max  // Déjà en km/h depuis le backend corrigé
        } else {
            maxSpeed = nil
        }

        #if DEBUG
        print("🏃 Speeds (km/h): avg=\(avgSpeed ?? 0), max=\(maxSpeed ?? 0)")
        #endif

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

        // Power metrics - priorité aux valeurs calculées
        avgPower = try container.decodeIfPresent(Double.self, forKey: .avgPower)
        maxPower = try container.decodeIfPresent(Double.self, forKey: .maxPower)

        // NP - peut être sous normalized_power ou np_calculated
        if let np = try? container.decodeIfPresent(Double.self, forKey: .normalizedPower), np > 0 {
            normalizedPower = np
        } else if let np = try? container.decodeIfPresent(Double.self, forKey: .npCalculated), np > 0 {
            normalizedPower = np
        } else {
            normalizedPower = nil
        }

        // Kilojoules - peut être sous kilojoules ou kilojoules_calculated
        if let kj = try? container.decodeIfPresent(Double.self, forKey: .kilojoules), kj > 0 {
            kilojoules = kj
        } else if let kj = try? container.decodeIfPresent(Double.self, forKey: .kilojoulesCalculated), kj > 0 {
            kilojoules = kj
        } else {
            kilojoules = nil
        }

        // TSS - peut être sous training_stress_score ou tss_device
        if let tss = try? container.decodeIfPresent(Double.self, forKey: .trainingStressScore), tss > 0 {
            trainingStressScore = tss
        } else if let tss = try? container.decodeIfPresent(Double.self, forKey: .tssDevice), tss > 0 {
            trainingStressScore = tss
        } else {
            trainingStressScore = nil
        }

        trimp = try container.decodeIfPresent(Double.self, forKey: .trimp)

        #if DEBUG
        if avgPower != nil || normalizedPower != nil {
            print("⚡ Power: avg=\(avgPower ?? 0)W, NP=\(normalizedPower ?? 0)W, kJ=\(kilojoules ?? 0)")
        }
        if trainingStressScore != nil || trimp != nil {
            print("📊 Load: TSS=\(trainingStressScore ?? 0), TRIMP=\(trimp ?? 0)")
        }
        #endif
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
    
    // Métriques Avancées Cyclisme
    let leftRightBalance: Double? // 0-100 (ex: 50.0 = 50/50, ou format Garmin spécifique)
    let torqueEffectiveness: Double?
    let pedalSmoothness: Double?

    enum CodingKeys: String, CodingKey {
        case timestamp
        case time  // Format backend EdgeCoach
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
        case elevation  // Format backend EdgeCoach
        case enhancedAltitude = "enhanced_altitude"
        case heartRate = "heart_rate"
        case hrValue = "hr_value"  // Format backend EdgeCoach
        case hr
        case cadence
        case power
        case watts = "Watts"  // Format backend EdgeCoach (majuscule!)
        case speed
        case speedCapital = "Speed"  // Format backend EdgeCoach (majuscule!)
        case enhancedSpeed = "enhanced_speed"
        case temperature

        // Métriques avancées
        case leftRightBalance = "left_right_balance"
        case torqueEffectiveness = "torque_effectiveness"
        case pedalSmoothness = "pedal_smoothness"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Timestamp: Double, String numérique, ou String ISO8601
        // Supporte: "timestamp" (FIT natif) ou "time" (backend EdgeCoach)
        func parseTimestamp(_ stringVal: String) -> Double? {
            // Essayer d'abord comme nombre
            if let doubleVal = Double(stringVal) {
                return doubleVal
            }
            // Sinon parser comme date ISO8601
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: stringVal) {
                return date.timeIntervalSince1970
            }
            // Essayer sans fractions de secondes
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: stringVal) {
                return date.timeIntervalSince1970
            }
            // Format basique sans timezone (ex: "2025-10-31T23:44:04")
            let basicFormatter = DateFormatter()
            basicFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            basicFormatter.timeZone = TimeZone(identifier: "UTC")
            if let date = basicFormatter.date(from: stringVal) {
                return date.timeIntervalSince1970
            }
            // Format avec espace
            basicFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let date = basicFormatter.date(from: stringVal) {
                return date.timeIntervalSince1970
            }
            return nil
        }

        if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: .timestamp) {
            timestamp = doubleVal
        } else if let stringVal = try? container.decodeIfPresent(String.self, forKey: .timestamp) {
            timestamp = parseTimestamp(stringVal)
        } else if let stringVal = try? container.decodeIfPresent(String.self, forKey: .time) {
            // Format backend EdgeCoach: "time" comme string ISO
            timestamp = parseTimestamp(stringVal)
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

        // Altitude: supporte altitude, enhanced_altitude, ou elevation (backend EdgeCoach)
        if let val = try? container.decodeIfPresent(Double.self, forKey: .altitude) {
            altitude = val
        } else if let val = try? container.decodeIfPresent(Double.self, forKey: .enhancedAltitude) {
            altitude = val
        } else if let val = try? container.decodeIfPresent(Double.self, forKey: .elevation) {
            altitude = val
        } else {
            altitude = nil
        }

        // Speed: supporte speed, enhanced_speed, ou "Speed" (backend EdgeCoach avec majuscule)
        if let val = try? container.decodeIfPresent(Double.self, forKey: .speed) {
            speed = val
        } else if let val = try? container.decodeIfPresent(Double.self, forKey: .enhancedSpeed) {
            speed = val
        } else if let val = try? container.decodeIfPresent(Double.self, forKey: .speedCapital) {
            speed = val
        } else {
            speed = nil
        }

        temperature = try container.decodeIfPresent(Double.self, forKey: .temperature)

        // Heart Rate: supporte heart_rate, hr, ou hr_value (backend EdgeCoach)
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
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .hrValue) {
            // Format backend EdgeCoach: hr_value
            heartRate = Double(intVal)
        } else if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: .hrValue) {
            heartRate = doubleVal
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

        // Power: String, Int or Double - supporte power ou "Watts" (backend EdgeCoach)
        if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: .power) {
            power = doubleVal
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .power) {
            power = Double(intVal)
        } else if let stringVal = try? container.decodeIfPresent(String.self, forKey: .power),
                  let doubleVal = Double(stringVal) {
            power = doubleVal
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .watts) {
            // Format backend EdgeCoach: "Watts"
            power = Double(intVal)
        } else if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: .watts) {
            power = doubleVal
        } else {
            power = nil
        }
        
        // Métriques Avancées
        leftRightBalance = try container.decodeIfPresent(Double.self, forKey: .leftRightBalance)
        torqueEffectiveness = try container.decodeIfPresent(Double.self, forKey: .torqueEffectiveness)
        pedalSmoothness = try container.decodeIfPresent(Double.self, forKey: .pedalSmoothness)

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

// MARK: - Activity Extension - Découplage Nolio -> fileDatas

/**
 * Extension pour le découplage progressif du modèle Nolio.
 * Ces computed properties privilégient les données file_datas (enrichies depuis FIT/TCX)
 * avec fallback sur les champs Nolio de premier niveau.
 *
 * Objectif: Permettre de changer de source de données sans modifier les vues.
 */
extension Activity {

    // MARK: - Duration (file_datas uniquement - découplé de Nolio)

    /// Durée depuis file_datas uniquement (movingTime = temps effectif sans pauses)
    var preferredDuration: Int? {
        guard let movingTime = fileDatas?.movingTime, movingTime > 0 else { return nil }
        return Int(movingTime)
    }

    /// Durée préférée formatée
    var preferredFormattedDuration: String {
        guard let dur = preferredDuration else { return "--:--" }
        let hours = dur / 3600
        let minutes = (dur % 3600) / 60
        let secs = dur % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    // MARK: - Distance (file_datas uniquement - découplé de Nolio)

    /// Distance depuis file_datas uniquement (km)
    var preferredDistance: Double? {
        guard let dist = fileDatas?.distance, dist > 0 else { return nil }
        return dist
    }

    // MARK: - Elevation (file_datas uniquement - découplé de Nolio)

    /// Dénivelé positif depuis file_datas uniquement
    var preferredElevationGain: Double? {
        guard let ascent = fileDatas?.ascent, ascent > 0 else { return nil }
        return ascent
    }

    /// Dénivelé négatif depuis file_datas uniquement
    var preferredElevationLoss: Double? {
        guard let descent = fileDatas?.descent, descent > 0 else { return nil }
        return descent
    }

    // MARK: - Power (file_datas uniquement - découplé de Nolio)

    /// Puissance moyenne depuis file_datas uniquement
    var preferredAvgPower: Double? {
        guard let power = fileDatas?.avgPower, power > 0 else { return nil }
        return power
    }

    /// Puissance max depuis file_datas uniquement
    var preferredMaxPower: Double? {
        guard let power = fileDatas?.maxPower, power > 0 else { return nil }
        return power
    }

    /// Puissance normalisée depuis file_datas uniquement
    var preferredNP: Double? {
        guard let power = fileDatas?.normalizedPower, power > 0 else { return nil }
        return power
    }

    // MARK: - TSS / Load (file_datas uniquement - découplé de Nolio)

    /// TSS depuis file_datas uniquement
    var preferredTSS: Double? {
        guard let tss = fileDatas?.trainingStressScore, tss > 0 else { return nil }
        return tss
    }

    /// TSS en Int pour affichage
    var preferredTSSInt: Int? {
        guard let tss = preferredTSS else { return nil }
        return Int(tss)
    }

    // MARK: - Energy (file_datas uniquement - découplé de Nolio)

    /// Kilojoules depuis file_datas uniquement
    var preferredKilojoules: Double? {
        guard let kj = fileDatas?.kilojoules, kj > 0 else { return nil }
        return kj
    }

    /// TRIMP depuis file_datas uniquement
    var preferredTrimp: Double? {
        guard let t = fileDatas?.trimp, t > 0 else { return nil }
        return t
    }

    // MARK: - Heart Rate

    /// FC moyenne préférée: fileDatas.hrAvg avec fallback
    var preferredHrAvg: Double? {
        if let hrAvg = fileDatas?.hrAvg, hrAvg > 0 {
            return hrAvg
        }
        return nil
    }

    /// FC max préférée: fileDatas.hrMax avec fallback
    var preferredHrMax: Double? {
        if let hrMax = fileDatas?.hrMax, hrMax > 0 {
            return hrMax
        }
        return nil
    }

    /// FC min préférée
    var preferredHrMin: Double? {
        fileDatas?.hrMin
    }

    // MARK: - Speed

    /// Vitesse moyenne préférée (déjà calculée avec priorité dans ActivityFileData)
    var preferredAvgSpeed: Double? {
        fileDatas?.avgSpeed
    }

    /// Vitesse max préférée
    var preferredMaxSpeed: Double? {
        fileDatas?.maxSpeed
    }

    // MARK: - Altitude

    /// Altitude moyenne préférée
    var preferredAltitudeAvg: Double? {
        fileDatas?.altitudeAvg
    }

    /// Altitude max préférée
    var preferredAltitudeMax: Double? {
        fileDatas?.altitudeMax
    }

    /// Altitude min préférée
    var preferredAltitudeMin: Double? {
        fileDatas?.altitudeMin
    }

    // MARK: - Cadence

    /// Cadence moyenne préférée
    var preferredCadenceAvg: Double? {
        fileDatas?.cadenceAvg
    }

    /// Cadence max préférée
    var preferredCadenceMax: Double? {
        fileDatas?.cadenceMax
    }

    // MARK: - Calories

    /// Calories préférées: fileDatas.calories
    var preferredCalories: Double? {
        fileDatas?.calories
    }

    // MARK: - Helper pour VAM (Vélo)

    /// VAM calculée depuis données préférées (m/h)
    var preferredVAM: Double? {
        guard let gain = preferredElevationGain,
              let dur = preferredDuration,
              gain > 100 && dur > 0 else {
            return nil
        }
        return (gain / Double(dur)) * 3600
    }

    // MARK: - Checks for data availability

    /// Vérifie si des données file_datas existent
    var hasFileData: Bool {
        fileDatas != nil
    }

    /// Vérifie si des données d'élévation sont disponibles (depuis file_datas ou Nolio)
    var hasPreferredElevationData: Bool {
        preferredElevationGain != nil || preferredElevationLoss != nil
    }

    /// Vérifie si des données HR sont disponibles
    var hasPreferredHRData: Bool {
        preferredHrAvg != nil || preferredHrMax != nil
    }

    // MARK: - Compatibilité (champs supprimés - retournent nil)
    // Ces données utilisateur ne sont plus dans Activity, elles doivent venir du profil

    /// FTP (Functional Threshold Power) - supprimé, utiliser UserProfile
    var ftp: Double? { nil }

    /// Poids de l'athlète - supprimé, utiliser UserProfile
    var weight: Double? { nil }

    /// FC max de l'utilisateur - supprimé, utiliser UserProfile
    var maxHrUser: Double? { nil }

    /// Zones de puissance/FC calculées - supprimé
    var zones: [ActivityZone]? { nil }

    // MARK: - Helper Methods

    /// Crée une copie de l'activité avec de nouvelles données de fichier
    func with(fileDatas newFileDatas: ActivityFileData?) -> Activity {
        Activity(
            id: id,
            userId: userId,
            dateStart: dateStart,
            sport: sport,
            name: name,
            description: description,
            fileDatas: newFileDatas
        )
    }
}
