/**
 * Modèles pour le cycle d'entraînement (2 semaines)
 * Correspond à l'endpoint GET /api/users/{user_id}/cycles/latest
 */

import Foundation

// MARK: - Cycle Response

/// Réponse complète de l'API /cycles/latest
struct CycleResponse: Codable {
    let userId: String
    let planId: String
    let cycleNumber: Int
    let cycleTag: String
    let status: String
    let phase: String
    let weeks: [Int]
    let createdAt: String
    let generatedAt: String
    let completedAt: String?
    let athleteProfile: CycleAthleteProfile?
    let optimizedPlan: OptimizedPlan?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case planId = "plan_id"
        case cycleNumber = "cycle_number"
        case cycleTag = "cycle_tag"
        case status
        case phase
        case weeks
        case createdAt = "created_at"
        case generatedAt = "generated_at"
        case completedAt = "completed_at"
        case athleteProfile = "athlete_profile"
        case optimizedPlan = "optimized_plan"
    }
}

// MARK: - Athlete Profile (simplified)

struct CycleAthleteProfile: Codable {
    let userId: String?
    let sport: String?
    let level: String?
    let language: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case sport
        case level
        case language
    }
}

// MARK: - Optimized Plan

struct OptimizedPlan: Codable {
    let cycleName: String?
    let phase: String?
    let weeks: [CycleWeek]
    let notes: String?
    let warnings: [String]?

    enum CodingKeys: String, CodingKey {
        case cycleName = "cycle_name"
        case phase
        case weeks
        case notes
        case warnings
    }
}

// MARK: - Cycle Week

struct CycleWeek: Codable, Identifiable {
    let weekNumber: Int
    let totalDuration: Int
    let sessions: [CycleSession]

    var id: Int { weekNumber }

    enum CodingKeys: String, CodingKey {
        case weekNumber = "week_number"
        case totalDuration = "total_duration"
        case sessions
    }

    /// Durée totale formatée (ex: "8h00")
    var formattedTotalDuration: String {
        let hours = totalDuration / 60
        let minutes = totalDuration % 60
        if minutes == 0 {
            return "\(hours)h"
        }
        return String(format: "%dh%02d", hours, minutes)
    }
}

// MARK: - Cycle Session

struct CycleSession: Codable, Identifiable {
    let canonicalId: String
    let day: String
    let date: String
    let sessionName: String
    let sport: String
    let duration: Double
    let adjustedDuration: Double?
    let durationMultiplier: Double?
    let distance: Double?
    let adjustedDistance: Double?
    let intensity: String?
    let type: String?
    let description: String?
    let coachDescription: String?
    let workoutDescription: String?
    let workoutStructure: [WorkoutSegment]?
    let rationale: String?
    let source: String?
    let estimatedIf: Double?
    let estimatedTss: Double?
    let comparisonMetrics: ComparisonMetrics?

    var id: String { "\(date)_\(canonicalId)" }

    enum CodingKeys: String, CodingKey {
        case canonicalId = "canonical_id"
        case day
        case date
        case sessionName = "session_name"
        case sport
        case duration
        case adjustedDuration = "adjusted_duration"
        case durationMultiplier = "duration_multiplier"
        case distance
        case adjustedDistance = "adjusted_distance"
        case intensity
        case type
        case description
        case coachDescription = "coach_description"
        case workoutDescription = "workout_description"
        case workoutStructure = "_workout_structure_enriched"
        case rationale
        case source
        case estimatedIf = "estimated_if"
        case estimatedTss = "estimated_tss"
        case comparisonMetrics = "comparison_metrics"
    }

    // MARK: - Computed Properties

    /// Durée effective à afficher (ajustée si disponible)
    var effectiveDuration: Int {
        Int(adjustedDuration ?? duration)
    }

    /// Durée formatée pour l'affichage
    var formattedDuration: String {
        let mins = effectiveDuration
        if mins >= 60 {
            let hours = mins / 60
            let remainingMins = mins % 60
            if remainingMins == 0 {
                return "\(hours)h"
            }
            return String(format: "%dh%02d", hours, remainingMins)
        }
        return "\(mins)min"
    }

    /// Distance formatée (si disponible)
    var formattedDistance: String? {
        guard let dist = adjustedDistance ?? distance, dist > 0 else { return nil }
        if sport == "swim" {
            return String(format: "%.0fm", dist)
        }
        let km = dist / 1000.0
        if km.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0fkm", km)
        }
        return String(format: "%.1fkm", km)
    }

    /// Date parsée
    var dateValue: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }

    /// Discipline convertie
    var discipline: Discipline {
        switch sport.lowercased() {
        case "run", "running":
            return .course
        case "bike", "cycling":
            return .cyclisme
        case "swim", "swimming":
            return .natation
        default:
            return .autre
        }
    }

    /// TSS estimé formaté
    var formattedTss: String? {
        guard let tss = estimatedTss else { return nil }
        return String(format: "%.0f", tss)
    }

    /// Titre affiché
    var displayTitle: String {
        sessionName
    }
}

// MARK: - Workout Segment

struct WorkoutSegment: Codable, Identifiable {
    let segmentType: String?
    let durationType: String?
    let durationValue: Int?
    let intensityTarget: String?
    let description: String?

    var id: String { "\(segmentType ?? "segment")_\(durationValue ?? 0)" }

    enum CodingKeys: String, CodingKey {
        case segmentType = "segment_type"
        case durationType = "duration_type"
        case durationValue = "duration_value"
        case intensityTarget = "intensity_target"
        case description
    }

    /// Durée formatée en minutes
    var formattedDuration: String {
        guard let value = durationValue else { return "-" }
        let minutes = value / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h\(mins)" : "\(hours)h"
        }
        return "\(minutes)min"
    }

    /// Type de segment traduit
    var displayType: String {
        guard let type = segmentType else { return "Segment" }
        switch type.lowercased() {
        case "warmup": return "Échauffement"
        case "work": return "Travail"
        case "steady": return "Régulier"
        case "cooldown": return "Retour au calme"
        case "recovery": return "Récupération"
        case "interval": return "Intervalle"
        default: return type.capitalized
        }
    }
}

// MARK: - Comparison Metrics

struct ComparisonMetrics: Codable {
    let plannedDurationMin: Double?
    let plannedWorkDurationMin: Double?
    let expectedIf: Double?
    let expectedRpe: Double?
    let primaryZone: String?
    let plannedZoneDistribution: [String: Double]?

    enum CodingKeys: String, CodingKey {
        case plannedDurationMin = "planned_duration_min"
        case plannedWorkDurationMin = "planned_work_duration_min"
        case expectedIf = "expected_if"
        case expectedRpe = "expected_rpe"
        case primaryZone = "primary_zone"
        case plannedZoneDistribution = "planned_zone_distribution"
    }
}

// MARK: - Cycle Plan Data (for ViewModel)

/// Modèle simplifié pour le ViewModel
struct CyclePlanData {
    let userId: String
    let planId: String
    let cycleNumber: Int
    let cycleTag: String
    let status: String
    let phase: String
    let cycleName: String
    let weeks: [CycleWeek]
    let notes: String?
    let warnings: [String]?
    let createdAt: Date?

    init(from response: CycleResponse) {
        self.userId = response.userId
        self.planId = response.planId
        self.cycleNumber = response.cycleNumber
        self.cycleTag = response.cycleTag
        self.status = response.status
        // Utiliser la phase de l'optimizedPlan si disponible, sinon celle du cycle racine
        // Évite le bug "Unknown" quand la phase racine n'est pas définie correctement
        self.phase = response.optimizedPlan?.phase ?? response.phase
        self.cycleName = response.optimizedPlan?.cycleName ?? "Cycle \(response.cycleNumber)"
        self.weeks = response.optimizedPlan?.weeks ?? []
        self.notes = response.optimizedPlan?.notes
        self.warnings = response.optimizedPlan?.warnings

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.createdAt = formatter.date(from: response.createdAt)
    }

    /// Toutes les sessions du cycle
    var allSessions: [CycleSession] {
        weeks.flatMap { $0.sessions }
    }

    /// Sessions pour une date donnée
    func sessions(for date: Date) -> [CycleSession] {
        let calendar = Calendar.current
        return allSessions.filter { session in
            guard let sessionDate = session.dateValue else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: date)
        }
    }

    /// Plage de dates du cycle
    var dateRange: (start: Date, end: Date)? {
        let dates = allSessions.compactMap { $0.dateValue }
        guard let minDate = dates.min(), let maxDate = dates.max() else { return nil }
        return (minDate, maxDate)
    }

    /// Phase traduite
    var phaseDisplayName: String {
        switch phase.uppercased() {
        case "BASE": return "Base"
        case "BUILD": return "Construction"
        case "PEAK": return "Pic"
        case "RACE": return "Compétition"
        case "RECOVERY": return "Récupération"
        case "TRANSITION": return "Transition"
        default: return phase.capitalized
        }
    }
}
