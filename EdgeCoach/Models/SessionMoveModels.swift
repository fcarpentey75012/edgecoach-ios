//
//  SessionMoveModels.swift
//  EdgeCoach
//
//  Models for session move/reschedule functionality.
//  Maps to backend API: PUT /api/cycles/<cycle_tag>/sessions/move
//

import Foundation

// MARK: - Request Model

/// Request body for moving a session to a new date
struct SessionMoveRequest: Codable {
    let sourceDate: String
    let targetDate: String

    enum CodingKeys: String, CodingKey {
        case sourceDate = "source_date"
        case targetDate = "target_date"
    }

    init(sourceDate: Date, targetDate: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.sourceDate = formatter.string(from: sourceDate)
        self.targetDate = formatter.string(from: targetDate)
    }

    init(sourceDate: String, targetDate: String) {
        self.sourceDate = sourceDate
        self.targetDate = targetDate
    }
}

// MARK: - Response Models

/// Complete response from session move API
struct SessionMoveResponse: Codable {
    let success: Bool
    let movedSession: MovedSessionInfo?
    let warnings: [MoveWarning]
    let complianceImpact: ComplianceImpact?
    let errorMessage: String?
    let planVersion: Int?

    enum CodingKeys: String, CodingKey {
        case success
        case movedSession = "moved_session"
        case warnings
        case complianceImpact = "compliance_impact"
        case errorMessage = "error_message"
        case planVersion = "plan_version"
    }
}

/// Information about the moved session
struct MovedSessionInfo: Codable {
    let sessionName: String?
    let sessionType: String?
    let sport: String?
    let originalDate: String
    let newDate: String
    let weekChanged: Bool
    let originalWeek: Int?
    let newWeek: Int?

    enum CodingKeys: String, CodingKey {
        case sessionName = "session_name"
        case sessionType = "session_type"
        case sport
        case originalDate = "original_date"
        case newDate = "new_date"
        case weekChanged = "week_changed"
        case originalWeek = "original_week"
        case newWeek = "new_week"
    }
}

/// Warning returned by the move validation
struct MoveWarning: Codable, Identifiable {
    let code: String
    let message: String
    let severity: String
    let details: [String: AnyCodable]?

    var id: String { code }

    /// Severity level for UI styling
    var severityLevel: WarningSeverity {
        WarningSeverity(rawValue: severity) ?? .low
    }

    /// Icon name based on warning code
    var iconName: String {
        switch code {
        case "conflict_same_day":
            return "exclamationmark.triangle.fill"
        case "consecutive_intensity":
            return "flame.fill"
        case "rest_day_removed":
            return "moon.zzz.fill"
        case "out_of_cycle_range":
            return "calendar.badge.exclamationmark"
        case "cross_week_move":
            return "arrow.left.arrow.right"
        case "key_session_moved":
            return "star.fill"
        default:
            return "info.circle.fill"
        }
    }
}

/// Warning severity levels
enum WarningSeverity: String, Codable {
    case low
    case medium
    case high

    var color: String {
        switch self {
        case .low: return "ecSuccess"
        case .medium: return "ecWarning"
        case .high: return "ecError"
        }
    }
}

/// Impact on compliance system
struct ComplianceImpact: Codable {
    let recordsInvalidated: Int
    let recalculationTriggered: Bool
    let datesAffected: [String]

    enum CodingKeys: String, CodingKey {
        case recordsInvalidated = "records_invalidated"
        case recalculationTriggered = "recalculation_triggered"
        case datesAffected = "dates_affected"
    }
}

// MARK: - Helper for decoding arbitrary JSON

/// Type-erased Codable wrapper for arbitrary JSON values
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            // Encoder récursivement les tableaux
            let codableArray = array.map { AnyCodable($0) }
            try container.encode(codableArray)
        case let dict as [String: Any]:
            // Encoder récursivement les dictionnaires
            let codableDict = dict.mapValues { AnyCodable($0) }
            try container.encode(codableDict)
        case is NSNull:
            try container.encodeNil()
        default:
            // Tenter de convertir en String pour les types non supportés
            try container.encode(String(describing: value))
        }
    }
}

// MARK: - Move State for UI

/// State object for tracking a session move operation
struct SessionMoveState {
    var isMoving: Bool = false
    var sourceSession: CycleSession?
    var sourceDate: Date?
    var targetDate: Date?
    var previewWarnings: [MoveWarning] = []
    var showConfirmation: Bool = false
    var isLoading: Bool = false
    var error: String?
    var lastMoveResult: SessionMoveResponse?

    mutating func reset() {
        isMoving = false
        sourceSession = nil
        sourceDate = nil
        targetDate = nil
        previewWarnings = []
        showConfirmation = false
        isLoading = false
        error = nil
    }

    mutating func startMove(session: CycleSession, from date: Date) {
        isMoving = true
        sourceSession = session
        sourceDate = date
        targetDate = nil
        previewWarnings = []
        error = nil
    }

    mutating func setTarget(date: Date) {
        targetDate = date
    }
}

// MARK: - Plan History Response

/// Response for plan history endpoint
struct PlanHistoryResponse: Codable {
    let cycleTag: String
    let historyCount: Int
    let history: [PlanHistoryEntry]

    enum CodingKeys: String, CodingKey {
        case cycleTag = "cycle_tag"
        case historyCount = "history_count"
        case history
    }
}

/// Single entry in plan history
struct PlanHistoryEntry: Codable, Identifiable {
    let version: Int
    let modifiedAt: String
    let modificationType: String
    let details: PlanHistoryDetails?

    var id: Int { version }

    enum CodingKeys: String, CodingKey {
        case version
        case modifiedAt = "modified_at"
        case modificationType = "modification_type"
        case details
    }
}

/// Details of a plan modification
struct PlanHistoryDetails: Codable {
    let sessionName: String?
    let fromDate: String?
    let toDate: String?

    enum CodingKeys: String, CodingKey {
        case sessionName = "session_name"
        case fromDate = "from_date"
        case toDate = "to_date"
    }
}

// MARK: - Date Extension

extension Date {
    /// Format date as YYYY-MM-DD string
    var apiDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}
