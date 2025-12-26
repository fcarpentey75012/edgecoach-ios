/**
 * Modèle Performance Report
 * Correspond aux données de l'API /api/users/{id}/performance-report
 * Métriques de haut niveau calculées en temps réel
 */

import Foundation

// MARK: - Performance Report (Root)

struct PerformanceReport: Codable {
    let id: String?
    let user: PerformanceReportUser?
    let date: String
    let metrics: PerformanceMetrics
    let meta: PerformanceMeta?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case date
        case metrics
        case meta
    }
}

// MARK: - User Info

struct PerformanceReportUser: Codable {
    let userId: String
    let hrMax: Int?
    let weightKg: Double?
    let hrMaxBySport: HrMaxBySport?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case hrMax = "hr_max"
        case weightKg = "weight_kg"
        case hrMaxBySport = "hr_max_by_sport"
    }
}

struct HrMaxBySport: Codable {
    let running: Int?
    let cycling: Int?
    let swimming: Int?
}

// MARK: - Performance Metrics

struct PerformanceMetrics: Codable {
    // Core metrics
    let vma: VMAMetric?
    let bestDistances: [String: BestDistanceRecord]?
    let ftp: FTPMetric?
    let ftpHybrid: FTPHybridMetric?
    let cpWprime: CPWprimeMetric?
    let css: CSSMetric?
    let csDprime: CSDprimeMetric?

    // Running zones
    let vmaZones: GenericZones?
    let paceZones: GenericZones?
    let hrZones: GenericZones?
    let hrZonesMeta: ZonesMeta?
    let csZones: CSZones?
    let csZonesPace: CSZonesPace?

    // Cycling zones
    let ftpZones: GenericZones?
    let ftpZonesMeta: ZonesMeta?
    let cpZones: CPZones?

    // Swimming zones
    let cssZones: GenericZones?
    let cssZonesFormatted: GenericZones?
    let cssZonesMeta: ZonesMeta?

    enum CodingKeys: String, CodingKey {
        case vma
        case bestDistances = "best_distances"
        case ftp
        case ftpHybrid = "ftp_hybrid"
        case cpWprime = "cp_wprime"
        case css
        case csDprime = "cs_dprime"
        // Running zones
        case vmaZones = "vma_zones"
        case paceZones = "pace_zones"
        case hrZones = "hr_zones"
        case hrZonesMeta = "hr_zones_meta"
        case csZones = "cs_zones"
        case csZonesPace = "cs_zones_pace"
        // Cycling zones
        case ftpZones = "ftp_zones"
        case ftpZonesMeta = "ftp_zones_meta"
        case cpZones = "cp_zones"
        // Swimming zones
        case cssZones = "css_zones"
        case cssZonesFormatted = "css_zones_formatted"
        case cssZonesMeta = "css_zones_meta"
    }
}

// MARK: - VMA Metric

struct VMAMetric: Codable {
    let value: Double
    let unit: String
    let confidence: Double?
    let standardDeviation: Double?
    let contributors: [VMAContributor]?
    let trainingZones: [TrainingZone]?
    let metadata: VMAMetadata?

    enum CodingKeys: String, CodingKey {
        case value, unit, confidence
        case standardDeviation = "standard_deviation"
        case contributors
        case trainingZones = "training_zones"
        case metadata
    }

    /// VMA formatée avec unité
    var formattedValue: String {
        String(format: "%.1f %@", value, unit)
    }

    /// Niveau de confiance en pourcentage
    var confidencePercent: Int {
        Int((confidence ?? 0) * 100)
    }
}

struct VMAContributor: Codable, Identifiable {
    var id: String { "\(sessionName ?? "unknown")-\(sessionDate ?? "unknown")" }

    let kind: String?
    let sessionName: String?
    let sessionDate: String?
    let vmaCandidateKmh: Double?
    let weight: Double?
    let hrPct: Double?
    let ageDays: Double?

    enum CodingKeys: String, CodingKey {
        case kind
        case sessionName = "session_name"
        case sessionDate = "session_date"
        case vmaCandidateKmh = "vma_candidate_kmh"
        case weight
        case hrPct = "hr_pct"
        case ageDays = "age_days"
    }
}

struct VMAMetadata: Codable {
    let hrAdjustmentKmh: Double?
    let candidatesCount: Int?
    let timeWeighting: TimeWeighting?

    enum CodingKeys: String, CodingKey {
        case hrAdjustmentKmh = "hr_adjustment_kmh"
        case candidatesCount = "candidates_count"
        case timeWeighting = "time_weighting"
    }
}

// MARK: - FTP Metric

struct FTPMetric: Codable {
    let value: Double
    let unit: String
    let confidence: Double?
    let standardDeviation: Double?
    let contributors: [FTPContributor]?
    let trainingZones: [TrainingZone]?
    let metadata: FTPMetadata?

    enum CodingKeys: String, CodingKey {
        case value, unit, confidence
        case standardDeviation = "standard_deviation"
        case contributors
        case trainingZones = "training_zones"
        case metadata
    }

    /// FTP formatée avec unité
    var formattedValue: String {
        String(format: "%.0f %@", value, unit)
    }

    /// Niveau de confiance en pourcentage
    var confidencePercent: Int {
        Int((confidence ?? 0) * 100)
    }
}

struct FTPContributor: Codable, Identifiable {
    var id: String { "\(sessionName ?? "unknown")-\(sessionDate ?? "unknown")" }

    let sessionName: String?
    let sessionDate: String?
    let power: Double?
    let hr: Int?
    let durationMin: Double?
    let ftpCalculated: Double?
    let hrPercentage: Double?
    let fT: Double?  // Facteur de durée
    let cHr: Double? // Correction HR

    enum CodingKeys: String, CodingKey {
        case sessionName = "session_name"
        case sessionDate = "session_date"
        case power, hr
        case durationMin = "duration_min"
        case ftpCalculated = "ftp_calculated"
        case hrPercentage = "hr_percentage"
        case fT = "f_t"
        case cHr = "c_hr"
    }
}

struct FTPMetadata: Codable {
    let ftpWithoutDrift: Double?
    let driftApplied: Bool?
    let driftPercent: Double?
    let timeWeighting: TimeWeighting?
    let relativeStdDev: Double?
    let classicFtp: Double?
    let gainVsClassic: Double?
    let gainPercentage: Double?

    enum CodingKeys: String, CodingKey {
        case ftpWithoutDrift = "ftp_without_drift"
        case driftApplied = "drift_applied"
        case driftPercent = "drift_percent"
        case timeWeighting = "time_weighting"
        case relativeStdDev = "relative_std_dev"
        case classicFtp = "classic_ftp"
        case gainVsClassic = "gain_vs_classic"
        case gainPercentage = "gain_percentage"
    }
}

// MARK: - FTP Hybrid Metric

struct FTPHybridMetric: Codable {
    let value: Double
    let details: [FTPHybridDetail]?
    let meta: FTPHybridMeta?
    let wPerKg: WPerKg?

    enum CodingKeys: String, CodingKey {
        case value, details, meta
        case wPerKg = "w_per_kg"
    }

    /// FTP Hybrid formaté
    var formattedValue: String {
        String(format: "%.0f W", value)
    }
}

struct FTPHybridDetail: Codable, Identifiable {
    var id: Int { Int(durationMin ?? 0) }

    let durationMin: Double?
    let np: Double?
    let ftpEst: Double?
    let hrAvg: Double?
    let hrPct: Double?

    enum CodingKeys: String, CodingKey {
        case durationMin = "duration_min"
        case np
        case ftpEst = "ftp_est"
        case hrAvg = "hr_avg"
        case hrPct = "hr_pct"
    }

    /// Durée formatée
    var formattedDuration: String {
        guard let dur = durationMin else { return "--" }
        return "\(Int(dur)) min"
    }
}

struct FTPHybridMeta: Codable {
    let method: String?
    let driftChecked: Bool?
    let params: FTPHybridParams?

    enum CodingKeys: String, CodingKey {
        case method
        case driftChecked = "drift_checked"
        case params
    }
}

struct FTPHybridParams: Codable {
    let durationFactors: [String: Double]?
    let weights: [String: Double]?
    let minHrmaxPct: Double?
    let targetHrmaxPct: Double?
    let hrCorrectionCap: Double?

    enum CodingKeys: String, CodingKey {
        case durationFactors = "duration_factors"
        case weights
        case minHrmaxPct = "min_hrmax_pct"
        case targetHrmaxPct = "target_hrmax_pct"
        case hrCorrectionCap = "hr_correction_cap"
    }
}

struct WPerKg: Codable {
    let value: Double
    let unit: String

    var formattedValue: String {
        String(format: "%.2f %@", value, unit)
    }
}

// MARK: - CSS Metric (Swimming)

struct CSSMetric: Codable {
    let value: Double
    let unit: String
    let confidence: Double?
    let standardDeviation: Double?
    let trainingZones: [TrainingZone]?
    let metadata: CSSMetadata?

    enum CodingKeys: String, CodingKey {
        case value, unit, confidence
        case standardDeviation = "standard_deviation"
        case trainingZones = "training_zones"
        case metadata
    }

    /// CSS formatée (pace per 100m) avec unité
    var formattedValue: String {
        // value est en secondes/100m, convertir en min:sec
        let totalSeconds = Int(value)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d /100m", minutes, seconds)
    }

    /// Pace formaté sans unité (pour affichage séparé)
    var formattedPace: String {
        let totalSeconds = Int(value)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Niveau de confiance en pourcentage
    var confidencePercent: Int {
        Int((confidence ?? 0) * 100)
    }
}

struct CSSMetadata: Codable {
    let cssMs: Double?
    let cssMethods: CSSMethods?
    let effortsAnalyzed: Int?
    let calculationDate: String?

    enum CodingKeys: String, CodingKey {
        case cssMs = "css_m_s"
        case cssMethods = "css_methods"
        case effortsAnalyzed = "efforts_analyzed"
        case calculationDate = "calculation_date"
    }
}

struct CSSMethods: Codable {
    let timeTrials: CSSMethodResult?
    let regression: CSSRegressionResult?
    let bestEfforts: CSSBestEffortsResult?

    enum CodingKeys: String, CodingKey {
        case timeTrials = "time_trials"
        case regression
        case bestEfforts = "best_efforts"
    }

    /// Retourne la méthode principale utilisée (celle avec une valeur)
    var primaryMethod: String? {
        if bestEfforts?.value != nil { return "best_efforts" }
        if timeTrials?.value != nil { return "time_trials" }
        if regression?.value != nil { return "regression" }
        return nil
    }
}

struct CSSMethodResult: Codable {
    let value: Double?
    let confidence: Double?
    let method: String?

    /// Confiance en pourcentage
    var confidencePercent: Int {
        Int((confidence ?? 0) * 100)
    }
}

struct CSSRegressionResult: Codable {
    let value: Double?
    let confidence: Double?
    let method: String?
    let rSquared: Double?
    let anaerobicDistance: Double?

    enum CodingKeys: String, CodingKey {
        case value, confidence, method
        case rSquared = "r_squared"
        case anaerobicDistance = "anaerobic_distance"
    }

    /// Confiance en pourcentage
    var confidencePercent: Int {
        Int((confidence ?? 0) * 100)
    }
}

struct CSSBestEffortsResult: Codable {
    let value: Double?
    let confidence: Double?
    let method: String?
    let medianSpeed: Double?
    let thresholdFactor: Double?
    let nEfforts: Int?
    let avgDurationS: Double?
    let speedCv: Double?
    let bestEfforts: [CSSBestEffort]?

    enum CodingKeys: String, CodingKey {
        case value, confidence, method
        case medianSpeed = "median_speed"
        case thresholdFactor = "threshold_factor"
        case nEfforts = "n_efforts"
        case avgDurationS = "avg_duration_s"
        case speedCv = "speed_cv"
        case bestEfforts = "best_efforts"
    }

    /// Confiance en pourcentage
    var confidencePercent: Int {
        Int((confidence ?? 0) * 100)
    }

    /// Durée moyenne formatée
    var formattedAvgDuration: String {
        guard let duration = avgDurationS else { return "--" }
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct CSSBestEffort: Codable, Identifiable {
    var id: String { "\(sessionName ?? "unknown")-\(date ?? "unknown")" }

    let sessionName: String?
    let date: String?
    let speed: Double?
    let durationS: Double?
    let distance: Double?

    enum CodingKeys: String, CodingKey {
        case sessionName = "session_name"
        case date
        case speed
        case durationS = "duration_s"
        case distance
    }

    /// Vitesse formatée en pace (min/100m)
    var formattedPace: String {
        guard let spd = speed, spd > 0 else { return "--:--" }
        let secPer100m = 100 / spd
        let minutes = Int(secPer100m / 60)
        let seconds = Int(secPer100m.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Durée formatée
    var formattedDuration: String {
        guard let dur = durationS else { return "--" }
        let minutes = Int(dur / 60)
        let seconds = Int(dur.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - CP/W' Metric (Advanced Cycling)

struct CPWprimeMetric: Codable {
    let cp: CPValue?
    let wPrime: WPrimeValue?
    let fitStats: FitStats?
    let predictions: [String: DurationPrediction]?
    let meta: CPWprimeMeta?

    enum CodingKeys: String, CodingKey {
        case cp
        case wPrime = "w_prime"
        case fitStats = "fit_stats"
        case predictions
        case meta
    }
}

struct CPValue: Codable {
    let value: Double
    let unit: String

    var formattedValue: String {
        String(format: "%.0f %@", value, unit)
    }
}

struct WPrimeValue: Codable {
    let value: Double
    let unit: String

    var formattedValue: String {
        String(format: "%.1f %@", value, unit)
    }
}

struct FitStats: Codable {
    let r2: Double?
    let rmse: Double?
    let n: Int?
}

struct DurationPrediction: Codable {
    let durationMin: Double?

    enum CodingKeys: String, CodingKey {
        case durationMin = "duration_min"
    }
}

struct CPWprimeMeta: Codable {
    let method: String?
    let huberDelta: Double?
    let constrained: Bool?
    let minFitDurationS: Double?

    enum CodingKeys: String, CodingKey {
        case method
        case huberDelta = "huber_delta"
        case constrained
        case minFitDurationS = "min_fit_duration_s"
    }
}

struct CPZones: Codable {
    let unit: String?
    let zone1: String?
    let zone2: String?
    let zone3: String?
    let zone4: String?
    let zone5: String?
    let zone6: String?

    enum CodingKeys: String, CodingKey {
        case unit
        case zone1 = "zone_1"
        case zone2 = "zone_2"
        case zone3 = "zone_3"
        case zone4 = "zone_4"
        case zone5 = "zone_5"
        case zone6 = "zone_6"
    }
}

// MARK: - CS/D' Metric (Running - équivalent CP/W' pour la course)

struct CSDprimeMetric: Codable {
    let cs: CSValue?
    let dPrime: DPrimeValue?
    let fitStats: FitStats?
    let predictions: [String: DurationPrediction]?
    let meta: CSDprimeMeta?

    enum CodingKeys: String, CodingKey {
        case cs
        case dPrime = "d_prime"
        case fitStats = "fit_stats"
        case predictions
        case meta
    }
}

struct CSValue: Codable {
    let value: Double
    let unit: String

    /// CS formatée en km/h
    var valueKmh: Double {
        value * 3.6
    }

    /// CS formatée en min/km
    var paceMinKm: String {
        guard value > 0 else { return "--:--" }
        let minPerKm = 1000 / value / 60
        let minutes = Int(minPerKm)
        let seconds = Int((minPerKm - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedValue: String {
        String(format: "%.2f %@", value, unit)
    }
}

struct DPrimeValue: Codable {
    let value: Double
    let unit: String

    var formattedValue: String {
        String(format: "%.0f %@", value, unit)
    }
}

struct CSDprimeMeta: Codable {
    let method: String?
    let halfLifeDays: Double?
    let minFitDurationS: Double?
    let dprimeBoundsM: [Double]?

    enum CodingKeys: String, CodingKey {
        case method
        case halfLifeDays = "half_life_days"
        case minFitDurationS = "min_fit_duration_s"
        case dprimeBoundsM = "dprime_bounds_m"
    }
}

// MARK: - CS Zones (Running zones based on Critical Speed)

struct CSZones: Codable {
    let unit: String?
    let zone1: String?
    let zone2: String?
    let zone3: String?
    let zone4: String?
    let zone5: String?
    let zone6: String?

    enum CodingKeys: String, CodingKey {
        case unit
        case zone1 = "zone_1"
        case zone2 = "zone_2"
        case zone3 = "zone_3"
        case zone4 = "zone_4"
        case zone5 = "zone_5"
        case zone6 = "zone_6"
    }

    /// Retourne les zones sous forme de tableau
    var zonesArray: [(name: String, range: String)] {
        var zones: [(String, String)] = []
        if let z1 = zone1 { zones.append(("Z1", z1)) }
        if let z2 = zone2 { zones.append(("Z2", z2)) }
        if let z3 = zone3 { zones.append(("Z3", z3)) }
        if let z4 = zone4 { zones.append(("Z4", z4)) }
        if let z5 = zone5 { zones.append(("Z5", z5)) }
        if let z6 = zone6 { zones.append(("Z6", z6)) }
        return zones
    }
}

struct CSZonesPace: Codable {
    let zone1: String?
    let zone2: String?
    let zone3: String?
    let zone4: String?
    let zone5: String?
    let zone6: String?

    enum CodingKeys: String, CodingKey {
        case zone1 = "zone_1"
        case zone2 = "zone_2"
        case zone3 = "zone_3"
        case zone4 = "zone_4"
        case zone5 = "zone_5"
        case zone6 = "zone_6"
    }

    /// Retourne les zones sous forme de tableau
    var zonesArray: [(name: String, range: String)] {
        var zones: [(String, String)] = []
        if let z1 = zone1 { zones.append(("Z1", z1)) }
        if let z2 = zone2 { zones.append(("Z2", z2)) }
        if let z3 = zone3 { zones.append(("Z3", z3)) }
        if let z4 = zone4 { zones.append(("Z4", z4)) }
        if let z5 = zone5 { zones.append(("Z5", z5)) }
        if let z6 = zone6 { zones.append(("Z6", z6)) }
        return zones
    }
}

// MARK: - Generic Zones (réutilisable pour VMA, Pace, HR, FTP, CSS)

struct GenericZones: Codable {
    let unit: String?
    let zone1: String?
    let zone2: String?
    let zone3: String?
    let zone4: String?
    let zone5: String?
    let zone6: String?

    enum CodingKeys: String, CodingKey {
        case unit
        case zone1 = "zone_1"
        case zone2 = "zone_2"
        case zone3 = "zone_3"
        case zone4 = "zone_4"
        case zone5 = "zone_5"
        case zone6 = "zone_6"
    }

    /// Retourne les zones sous forme de tableau
    var zonesArray: [(name: String, range: String)] {
        var zones: [(String, String)] = []
        if let z1 = zone1 { zones.append(("Z1", z1)) }
        if let z2 = zone2 { zones.append(("Z2", z2)) }
        if let z3 = zone3 { zones.append(("Z3", z3)) }
        if let z4 = zone4 { zones.append(("Z4", z4)) }
        if let z5 = zone5 { zones.append(("Z5", z5)) }
        if let z6 = zone6 { zones.append(("Z6", z6)) }
        return zones
    }

    /// Nombre de zones disponibles
    var zoneCount: Int {
        zonesArray.count
    }
}

struct ZonesMeta: Codable {
    let method: String?
    let names: [String]?
}

// MARK: - Best Distance Records

struct BestDistanceRecord: Codable, Identifiable {
    var id: String { "\(distanceKm ?? 0)" }

    let timeMin: Double?
    let pace: String?
    let date: String?
    let hr: Double?
    let method: String?
    let distanceKm: Double?
    let sessionName: String?

    enum CodingKeys: String, CodingKey {
        case timeMin = "time_min"
        case pace, date, hr, method
        case distanceKm = "distance_km"
        case sessionName = "session_name"
    }

    /// Temps formaté (ex: "27:03")
    var formattedTime: String {
        guard let time = timeMin else { return "--:--" }
        let totalSeconds = Int(time * 60)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Training Zone (Generic)

struct TrainingZone: Codable, Identifiable {
    var id: String { name }

    let name: String
    let minValue: Double
    let maxValue: Double
    let unit: String
    let minPercentage: Double?
    let maxPercentage: Double?
    let metadata: TrainingZoneMetadata?

    enum CodingKeys: String, CodingKey {
        case name
        case minValue = "min_value"
        case maxValue = "max_value"
        case unit
        case minPercentage = "min_percentage"
        case maxPercentage = "max_percentage"
        case metadata
    }

    /// Plage formatée (ex: "9.1 - 10.4 km/h")
    var formattedRange: String {
        if unit == "m/100m" {
            // Pour la natation, convertir en min:sec
            let minSec = Int(minValue)
            let maxSec = Int(maxValue)
            let minMin = minSec / 60
            let minS = minSec % 60
            let maxMin = maxSec / 60
            let maxS = maxSec % 60
            return String(format: "%d:%02d - %d:%02d", minMin, minS, maxMin, maxS)
        }
        return String(format: "%.1f - %.1f %@", minValue, maxValue, unit)
    }

    /// Nom court de la zone (ex: "Z2" depuis "Zone 2 - Endurance")
    var shortName: String {
        if let range = name.range(of: "Zone \\d", options: .regularExpression) {
            let zoneNum = name[range].replacingOccurrences(of: "Zone ", with: "")
            return "Z\(zoneNum)"
        }
        return name
    }

    /// Description de la zone (partie après le tiret)
    var zoneDescription: String {
        if let range = name.range(of: " - ") {
            return String(name[range.upperBound...])
        }
        return name
    }
}

struct TrainingZoneMetadata: Codable {
    let minSpeedMs: Double?
    let maxSpeedMs: Double?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case minSpeedMs = "min_speed_m_s"
        case maxSpeedMs = "max_speed_m_s"
        case description
    }
}

// MARK: - Time Weighting (Shared)

struct TimeWeighting: Codable {
    let enabled: Bool?
    let halfLifeDays: Double?
    let maxAgeDays: Int?
    let topK: Int?
    let quantile: Double?
    let effectiveSampleSize: Double?
    let sumWeights: Double?
    let autoTuned: Bool?

    enum CodingKeys: String, CodingKey {
        case enabled
        case halfLifeDays = "half_life_days"
        case maxAgeDays = "max_age_days"
        case topK = "top_k"
        case quantile
        case effectiveSampleSize = "effective_sample_size"
        case sumWeights = "sum_weights"
        case autoTuned = "auto_tuned"
    }
}

// MARK: - Performance Meta (Technique)

struct PerformanceMeta: Codable {
    let technique: TechniqueMetrics?
}

struct TechniqueMetrics: Codable {
    let swimming: SwimmingTechnique?
    let running: RunningTechnique?
    let cycling: CyclingTechnique?
    let multiSport: MultiSportTechnique?

    enum CodingKeys: String, CodingKey {
        case swimming, running, cycling
        case multiSport = "multi_sport"
    }
}

struct SwimmingTechnique: Codable {
    let swolf: Double?
    let strokeRateCpm: Double?
    let strokeLengthMPerCycle: Double?
    let distancePerStrokeM: Double?
    let efficiencyIndex: Double?
    let breathsPerSession: Int?
    let symmetryPct: Double?

    enum CodingKeys: String, CodingKey {
        case swolf
        case strokeRateCpm = "stroke_rate_cpm"
        case strokeLengthMPerCycle = "stroke_length_m_per_cycle"
        case distancePerStrokeM = "distance_per_stroke_m"
        case efficiencyIndex = "efficiency_index"
        case breathsPerSession = "breaths_per_session"
        case symmetryPct = "symmetry_pct"
    }
}

struct RunningTechnique: Codable {
    let paHrMedianPct: Double?
    let efficiencyIndex: Double?
    let runningEffectiveness: Double?
    let cadenceSpm: Double?
    let strideLengthM: Double?
    let gctMs: Double?
    let verticalOscillationCm: Double?
    let cvActive: Double?

    enum CodingKeys: String, CodingKey {
        case paHrMedianPct = "pa_hr_median_pct"
        case efficiencyIndex = "efficiency_index"
        case runningEffectiveness = "running_effectiveness"
        case cadenceSpm = "cadence_spm"
        case strideLengthM = "stride_length_m"
        case gctMs = "gct_ms"
        case verticalOscillationCm = "vertical_oscillation_cm"
        case cvActive = "cv_active"
    }
}

struct CyclingTechnique: Codable {
    let pwHrMedianPct: Double?
    let efficiencyFactor: Double?
    let variabilityIndex: Double?
    let cadenceRpm: Double?
    let leftRightBalancePct: Double?
    let torqueEffectivenessPct: Double?
    let pedalSmoothnessPct: Double?
    let pmaBestW: Double?

    enum CodingKeys: String, CodingKey {
        case pwHrMedianPct = "pw_hr_median_pct"
        case efficiencyFactor = "efficiency_factor"
        case variabilityIndex = "variability_index"
        case cadenceRpm = "cadence_rpm"
        case leftRightBalancePct = "left_right_balance_pct"
        case torqueEffectivenessPct = "torque_effectiveness_pct"
        case pedalSmoothnessPct = "pedal_smoothness_pct"
        case pmaBestW = "pma_best_w"
    }
}

struct MultiSportTechnique: Codable {
    let economyCrossDiscipline: EconomyCrossDiscipline?
    let constanceTechnique: ConstanceTechnique?
    let fatigueIndexPct: Double?

    enum CodingKeys: String, CodingKey {
        case economyCrossDiscipline = "economy_cross_discipline"
        case constanceTechnique = "constance_technique"
        case fatigueIndexPct = "fatigue_index_pct"
    }
}

struct EconomyCrossDiscipline: Codable {
    let paHrRunPct: Double?
    let pwHrBikePct: Double?
    let diffPct: Double?

    enum CodingKeys: String, CodingKey {
        case paHrRunPct = "pa_hr_run_pct"
        case pwHrBikePct = "pw_hr_bike_pct"
        case diffPct = "diff_pct"
    }
}

struct ConstanceTechnique: Codable {
    let cvActiveRun: Double?

    enum CodingKeys: String, CodingKey {
        case cvActiveRun = "cv_active_run"
    }
}
