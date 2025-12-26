/**
 * ComplianceService - Service pour le système de Compliance
 *
 * Gère les appels API pour:
 * - Récupérer les propositions d'adaptation en attente
 * - Soumettre la sélection d'option (étape 1)
 * - Confirmer la sélection (étape 2)
 * - Récupérer l'historique des propositions
 *
 * Architecture:
 *   ComplianceService
 *        │
 *        ├── getPendingProposals() → [ProposalView]
 *        ├── selectOption() → SelectionResult
 *        └── confirmSelection() → ConfirmationResult
 */

import Foundation

@MainActor
class ComplianceService {
    static let shared = ComplianceService()
    private let api = APIService.shared

    private init() {}

    // MARK: - Get Pending Proposals

    /// Récupère les propositions en attente pour l'utilisateur
    func getPendingProposals(userId: String) async throws -> [ProposalView] {
        let response: PendingProposalsResponse = try await api.get(
            "/compliance/\(userId)/proposals/pending"
        )
        return response
    }

    // MARK: - Get Active Alert

    /// Récupère l'alerte active pour l'utilisateur
    func getActiveAlert(userId: String) async throws -> ComplianceAlert {
        let response: ComplianceAlertResponse = try await api.get(
            "/compliance/\(userId)/alerts"
        )
        return response.toAlert()
    }

    // MARK: - Step 1: Select Option

    /// Étape 1: Sélectionne une option parmi les proposées
    /// Cette étape N'APPLIQUE PAS encore les modifications
    func selectOption(
        userId: String,
        proposalId: String,
        optionId: String,
        userComment: String? = nil
    ) async throws -> SelectionResult {
        let body = SelectOptionRequest(
            optionId: optionId,
            userComment: userComment ?? ""
        )

        let response: SelectionResultResponse = try await api.post(
            "/compliance/\(userId)/proposal/\(proposalId)/select",
            body: body
        )

        return response.toResult()
    }

    // MARK: - Step 2: Confirm Selection

    /// Étape 2: Confirme (ou annule) la sélection
    /// Si confirmé, les modifications sont appliquées au plan
    func confirmSelection(
        userId: String,
        proposalId: String,
        confirmed: Bool,
        applyFromDate: Date? = nil
    ) async throws -> ConfirmationResult {
        var applyFromDateString: String? = nil
        if let date = applyFromDate {
            let formatter = ISO8601DateFormatter()
            applyFromDateString = formatter.string(from: date)
        }

        let body = ConfirmSelectionRequest(
            confirmed: confirmed,
            applyFromDate: applyFromDateString
        )

        let response: ConfirmationResultResponse = try await api.post(
            "/compliance/\(userId)/proposal/\(proposalId)/confirm",
            body: body
        )

        return response.toResult()
    }

    // MARK: - Get Compliance Trend

    /// Récupère les tendances de compliance
    func getTrend(userId: String, days: Int = 30) async throws -> ComplianceTrend {
        let response: ComplianceTrendResponse = try await api.get(
            "/compliance/\(userId)/trend",
            queryParams: ["days": String(days)]
        )
        return response.toTrend()
    }

    // MARK: - Get Proposals History

    /// Récupère l'historique des propositions
    func getProposalsHistory(userId: String, days: Int = 30) async throws -> [ProposalView] {
        let response: ProposalsHistoryResponse = try await api.get(
            "/compliance/\(userId)/proposals/history",
            queryParams: ["days": String(days)]
        )
        return response
    }
}

// MARK: - Request Models

struct SelectOptionRequest: Encodable {
    let optionId: String
    let userComment: String

    enum CodingKeys: String, CodingKey {
        case optionId = "option_id"
        case userComment = "user_comment"
    }
}

struct ConfirmSelectionRequest: Encodable {
    let confirmed: Bool
    let applyFromDate: String?

    enum CodingKeys: String, CodingKey {
        case confirmed
        case applyFromDate = "apply_from_date"
    }
}

// MARK: - Response Models

typealias PendingProposalsResponse = [ProposalView]
typealias ProposalsHistoryResponse = [ProposalView]

// MARK: - Proposal View

struct ProposalView: Codable, Identifiable {
    var id: String { proposalId }

    let proposalId: String
    let athleteId: String
    let stage: String
    let status: String
    let alertLevel: String
    let context: String
    let options: [ProposalOption]
    let selectedOptionId: String?
    let selectedOption: ProposalOption?
    let createdAt: String
    let deadline: String
    let timeRemainingHours: Double
    let instructions: String
    let nextAction: String

    enum CodingKeys: String, CodingKey {
        case proposalId = "proposal_id"
        case athleteId = "athlete_id"
        case stage
        case status
        case alertLevel = "alert_level"
        case context
        case options
        case selectedOptionId = "selected_option_id"
        case selectedOption = "selected_option"
        case createdAt = "created_at"
        case deadline
        case timeRemainingHours = "time_remaining_hours"
        case instructions
        case nextAction = "next_action"
    }

    // Computed properties
    var isAwaitingSelection: Bool {
        stage == "awaiting_selection"
    }

    var isAwaitingConfirmation: Bool {
        stage == "awaiting_confirmation"
    }

    var isUrgent: Bool {
        timeRemainingHours < 12
    }

    var alertLevelEnum: AlertLevel {
        AlertLevel(rawValue: alertLevel) ?? .none
    }

    var deadlineDate: Date? {
        ISO8601DateFormatter().date(from: deadline)
    }

    var createdAtDate: Date? {
        ISO8601DateFormatter().date(from: createdAt)
    }
}

// MARK: - Proposal Option

struct ProposalOption: Codable, Identifiable {
    var id: String { optionId ?? UUID().uuidString }

    let optionId: String?
    let type: String?
    let description: String?
    let modulationFactor: Double?
    let riskLevel: String?
    let rationale: String?
    let affectedDays: Int?

    enum CodingKeys: String, CodingKey {
        case optionId = "id"
        case type
        case description
        case modulationFactor = "modulation_factor"
        case riskLevel = "risk_level"
        case rationale
        case affectedDays = "affected_days"
    }

    var riskLevelEnum: RiskLevel {
        guard let level = riskLevel else { return .low }
        return RiskLevel(rawValue: level) ?? .low
    }

    /// Formatted description avec emoji selon le type
    var formattedDescription: String {
        let emoji: String
        switch type {
        case "reduce_volume": emoji = "📉"
        case "reduce_intensity": emoji = "🔻"
        case "add_rest": emoji = "😴"
        case "extend_recovery": emoji = "🔄"
        case "continue": emoji = "▶️"
        case "monitor": emoji = "👁️"
        case "increase_load": emoji = "📈"
        case "schedule_test": emoji = "🎯"
        case "recalibrate_zones": emoji = "⚡"
        default: emoji = "•"
        }
        return "\(emoji) \(description ?? "")"
    }
}

// MARK: - Selection Result

struct SelectionResult {
    let success: Bool
    let proposalId: String
    let selectedOptionId: String?
    let message: String
    let nextStage: String

    var isAwaitingConfirmation: Bool {
        nextStage == "awaiting_confirmation"
    }
}

struct SelectionResultResponse: Codable {
    let success: Bool
    let proposalId: String
    let selectedOptionId: String?
    let message: String
    let nextStage: String

    enum CodingKeys: String, CodingKey {
        case success
        case proposalId = "proposal_id"
        case selectedOptionId = "selected_option_id"
        case message
        case nextStage = "next_stage"
    }

    func toResult() -> SelectionResult {
        SelectionResult(
            success: success,
            proposalId: proposalId,
            selectedOptionId: selectedOptionId,
            message: message,
            nextStage: nextStage
        )
    }
}

// MARK: - Confirmation Result

struct ConfirmationResult {
    let success: Bool
    let proposalId: String
    let confirmed: Bool
    let message: String
    let nextStage: String
    let applied: Bool

    var isCompleted: Bool {
        nextStage == "completed"
    }
}

struct ConfirmationResultResponse: Codable {
    let success: Bool
    let proposalId: String
    let confirmed: Bool
    let message: String
    let nextStage: String
    let applied: Bool

    enum CodingKeys: String, CodingKey {
        case success
        case proposalId = "proposal_id"
        case confirmed
        case message
        case nextStage = "next_stage"
        case applied
    }

    func toResult() -> ConfirmationResult {
        ConfirmationResult(
            success: success,
            proposalId: proposalId,
            confirmed: confirmed,
            message: message,
            nextStage: nextStage,
            applied: applied
        )
    }
}

// MARK: - Compliance Alert

struct ComplianceAlert {
    let level: AlertLevel
    let action: String?
    let reason: String?
    let consecutiveFailures: Int
    let primaryReason: String?
    let message: String?

    var hasAlert: Bool {
        level != .none && level != .green
    }

    var isWarning: Bool {
        level == .yellow || level == .orange
    }

    var isCritical: Bool {
        level == .red
    }

    var isPositive: Bool {
        level == .positiveReadiness || level == .positiveBreakthrough || level == .positiveEfficiency
    }
}

struct ComplianceAlertResponse: Codable {
    let level: String
    let action: String?
    let reason: String?
    let consecutiveFailures: Int
    let primaryReason: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case level
        case action
        case reason
        case consecutiveFailures = "consecutive_failures"
        case primaryReason = "primary_reason"
        case message
    }

    func toAlert() -> ComplianceAlert {
        ComplianceAlert(
            level: AlertLevel(rawValue: level) ?? .none,
            action: action,
            reason: reason,
            consecutiveFailures: consecutiveFailures,
            primaryReason: primaryReason,
            message: message
        )
    }
}

// MARK: - Compliance Trend

struct ComplianceTrend {
    let periodDays: Int
    let totalSessions: Int
    let avgCompliance: Double
    let compliantCount: Int
    let partialCount: Int
    let skipCount: Int
    let trendDirection: String
    let failureReasonsDistribution: [String: Int]

    var isImproving: Bool {
        trendDirection == "UP"
    }

    var isDeclining: Bool {
        trendDirection == "DOWN"
    }

    var compliancePercentage: Int {
        Int(avgCompliance * 100)
    }
}

struct ComplianceTrendResponse: Codable {
    let periodDays: Int
    let totalSessions: Int
    let avgCompliance: Double
    let compliantCount: Int
    let partialCount: Int
    let skipCount: Int
    let trendDirection: String
    let failureReasonsDistribution: [String: Int]

    enum CodingKeys: String, CodingKey {
        case periodDays = "period_days"
        case totalSessions = "total_sessions"
        case avgCompliance = "avg_compliance"
        case compliantCount = "compliant_count"
        case partialCount = "partial_count"
        case skipCount = "skip_count"
        case trendDirection = "trend_direction"
        case failureReasonsDistribution = "failure_reasons_distribution"
    }

    func toTrend() -> ComplianceTrend {
        ComplianceTrend(
            periodDays: periodDays,
            totalSessions: totalSessions,
            avgCompliance: avgCompliance,
            compliantCount: compliantCount,
            partialCount: partialCount,
            skipCount: skipCount,
            trendDirection: trendDirection,
            failureReasonsDistribution: failureReasonsDistribution
        )
    }
}

// MARK: - Enums

enum AlertLevel: String, Codable {
    case none = "none"
    case green = "green"
    case yellow = "yellow"
    case orange = "orange"
    case red = "red"
    case warning = "warning"
    case positiveReadiness = "positive_readiness"
    case positiveBreakthrough = "positive_breakthrough"
    case positiveEfficiency = "positive_efficiency"

    var color: String {
        switch self {
        case .none, .green: return "green"
        case .yellow: return "yellow"
        case .orange: return "orange"
        case .red: return "red"
        case .warning: return "yellow"
        case .positiveReadiness, .positiveBreakthrough, .positiveEfficiency: return "blue"
        }
    }

    var icon: String {
        switch self {
        case .none, .green: return "checkmark.circle.fill"
        case .yellow: return "exclamationmark.triangle.fill"
        case .orange: return "exclamationmark.circle.fill"
        case .red: return "xmark.octagon.fill"
        case .warning: return "eye.fill"
        case .positiveReadiness: return "star.fill"
        case .positiveBreakthrough: return "flame.fill"
        case .positiveEfficiency: return "bolt.fill"
        }
    }

    var displayName: String {
        switch self {
        case .none: return "Aucune alerte"
        case .green: return "Tout va bien"
        case .yellow: return "Attention"
        case .orange: return "Alerte modérée"
        case .red: return "Alerte critique"
        case .warning: return "Surveillance"
        case .positiveReadiness: return "Prêt pour un test"
        case .positiveBreakthrough: return "Performance exceptionnelle"
        case .positiveEfficiency: return "Efficacité remarquable"
        }
    }
}

enum RiskLevel: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var displayName: String {
        switch self {
        case .low: return "Faible"
        case .medium: return "Modéré"
        case .high: return "Élevé"
        }
    }

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "red"
        }
    }
}
