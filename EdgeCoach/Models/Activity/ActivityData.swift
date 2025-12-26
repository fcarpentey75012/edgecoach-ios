// MARK: - Activity Data Models

import Foundation

// MARK: - Activity File Data

struct ActivityFileData: Codable {
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
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(records, forKey: .records)
        try container.encodeIfPresent(laps, forKey: .laps)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(movingTime, forKey: .movingTime)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encodeIfPresent(ascent, forKey: .ascent)
        try container.encodeIfPresent(descent, forKey: .descent)
        try container.encodeIfPresent(avgSpeed, forKey: .avgSpeed)
        try container.encodeIfPresent(maxSpeed, forKey: .maxSpeed)
        try container.encodeIfPresent(hrAvg, forKey: .hrAvg)
        try container.encodeIfPresent(hrMax, forKey: .hrMax)
        try container.encodeIfPresent(hrMin, forKey: .hrMin)
        try container.encodeIfPresent(cadenceAvg, forKey: .cadenceAvg)
        try container.encodeIfPresent(cadenceMax, forKey: .cadenceMax)
        try container.encodeIfPresent(calories, forKey: .calories)
        try container.encodeIfPresent(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encodeIfPresent(altitudeAvg, forKey: .altitudeAvg)
        try container.encodeIfPresent(altitudeMin, forKey: .altitudeMin)
        try container.encodeIfPresent(altitudeMax, forKey: .altitudeMax)
        try container.encodeIfPresent(avgPower, forKey: .avgPower)
        try container.encodeIfPresent(maxPower, forKey: .maxPower)
        try container.encodeIfPresent(normalizedPower, forKey: .normalizedPower)
        try container.encodeIfPresent(kilojoules, forKey: .kilojoules)
        try container.encodeIfPresent(trainingStressScore, forKey: .trainingStressScore)
        try container.encodeIfPresent(trimp, forKey: .trimp)
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

        return unique
    }
}

// MARK: - Activity Record (GPS point with metrics)

/// Supporte plusieurs formats de coordonnées GPS:
/// - Format Garmin FIT: position_lat/position_long (en semicircles)
/// - Format TCX: lat/lng ou lat/lon
/// - Format standard: latitude/longitude
struct ActivityRecord: Codable {
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(positionLat, forKey: .positionLat)
        try container.encodeIfPresent(positionLong, forKey: .positionLong)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encodeIfPresent(altitude, forKey: .altitude)
        try container.encodeIfPresent(heartRate, forKey: .heartRate)
        try container.encodeIfPresent(cadence, forKey: .cadence)
        try container.encodeIfPresent(power, forKey: .power)
        try container.encodeIfPresent(speed, forKey: .speed)
        try container.encodeIfPresent(temperature, forKey: .temperature)
        try container.encodeIfPresent(leftRightBalance, forKey: .leftRightBalance)
        try container.encodeIfPresent(torqueEffectiveness, forKey: .torqueEffectiveness)
        try container.encodeIfPresent(pedalSmoothness, forKey: .pedalSmoothness)
    }
}

// MARK: - Activity Lap

/// Supporte plusieurs formats de données laps de l'API:
/// - Format Garmin FIT: total_elapsed_time, avg_speed (m/s), avg_heart_rate, avg_power, avg_cadence
/// - Format traité: duration, avg_speed_kmh, hr_avg, tpx_ext_stats.Watts.avg, cadence_avg
struct ActivityLap: Codable, Identifiable {
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(startTime, forKey: .startTime)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(avgSpeedKmh, forKey: .avgSpeedKmh)
        try container.encodeIfPresent(maxSpeedKmh, forKey: .maxSpeedKmh)
        try container.encodeIfPresent(avgHeartRate, forKey: .avgHeartRate)
        try container.encodeIfPresent(maxHeartRate, forKey: .maxHeartRate)
        try container.encodeIfPresent(avgPower, forKey: .avgPower)
        try container.encodeIfPresent(maxPower, forKey: .maxPower)
        try container.encodeIfPresent(avgCadence, forKey: .avgCadence)
        try container.encodeIfPresent(ascent, forKey: .ascent)
        try container.encodeIfPresent(descent, forKey: .descent)
        try container.encodeIfPresent(calories, forKey: .calories)
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
