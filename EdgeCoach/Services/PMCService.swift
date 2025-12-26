/**
 * PMCService - Service pour les données PMC (Performance Management Chart)
 * Gère les appels API pour CTL, ATL, TSB
 */

import Foundation

@MainActor
class PMCService {
    static let shared = PMCService()
    private let api = APIService.shared

    private init() {}

    // MARK: - Get PMC Status

    /// Récupère le statut PMC actuel de l'utilisateur
    func getStatus(userId: String) async throws -> PMCStatus {
        let response: PMCStatusResponse = try await api.get(
            "/users/\(userId)/pmc/status"
        )
        return response.data
    }

    // MARK: - Get PMC History (si disponible)

    /// Récupère l'historique PMC pour les graphiques
    func getHistory(userId: String, days: Int = 90) async throws -> [PMCHistoryPoint] {
        let response: PMCHistoryResponse = try await api.get(
            "/users/\(userId)/pmc/history",
            queryParams: ["days": String(days)]
        )

        return response.data.history
    }

    // MARK: - Get PMC Analysis (Coach IA)

    /// Demande une analyse PMC personnalisée par le coach IA
    func getAnalysis(userId: String, type: PMCAnalysisType = .general) async throws -> PMCAnalysisResult {
        let response: PMCAnalysisResponse = try await api.get(
            "/users/\(userId)/pmc/analysis",
            queryParams: ["type": type.rawValue]
        )

        return PMCAnalysisResult(
            response: response.response,
            insights: response.insights ?? [],
            actionItems: response.actionItems ?? [],
            analysisType: response.analysisType ?? type.rawValue,
            error: response.error
        )
    }

    /// Pose une question spécifique sur l'état de forme
    func askQuestion(userId: String, question: String) async throws -> PMCAnalysisResult {
        let body = PMCAskRequest(question: question)

        let response: PMCAnalysisResponse = try await api.post(
            "/users/\(userId)/pmc/analysis/ask",
            body: body
        )

        return PMCAnalysisResult(
            response: response.response,
            insights: response.insights ?? [],
            actionItems: response.actionItems ?? [],
            analysisType: response.analysisType ?? "question",
            error: response.error
        )
    }

    /// Récupère un statut rapide avec interprétations (sans LLM)
    func getQuickStatus(userId: String) async throws -> PMCQuickStatusResult {
        let response: PMCQuickStatusResponse = try await api.get(
            "/users/\(userId)/pmc/quick-status"
        )

        return PMCQuickStatusResult(
            metrics: response.metrics,
            historicalSummary: response.historicalSummary,
            interpretations: response.interpretations,
            alerts: response.alerts ?? []
        )
    }
}

// MARK: - PMC Analysis Types

enum PMCAnalysisType: String {
    case general = "general"
    case preRace = "pre_race"
    case recovery = "recovery"
    case trend = "trend"
}

// MARK: - PMC History Response

struct PMCHistoryResponse: Codable {
    let status: String
    let data: PMCHistoryData
}

struct PMCHistoryData: Codable {
    let userId: String?
    let startDate: String?
    let endDate: String?
    let daysCount: Int?
    let history: [PMCHistoryPoint]
    let stats: PMCHistoryStats?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case daysCount = "days_count"
        case history
        case stats
    }
}

struct PMCHistoryStats: Codable {
    let ctl: PMCStatRange?
    let atl: PMCStatRange?
    let tsb: PMCStatRange?
    let tss: PMCTssStats?
}

struct PMCStatRange: Codable {
    let current: Double?
    let max: Double?
    let min: Double?
    let avg: Double?
}

struct PMCTssStats: Codable {
    let total: Double?
    let avgPerDay: Double?
    let maxDay: Double?

    enum CodingKeys: String, CodingKey {
        case total
        case avgPerDay = "avg_per_day"
        case maxDay = "max_day"
    }
}

// MARK: - PMC History Point

struct PMCHistoryPoint: Codable, Identifiable {
    var id: String { date }
    let date: String
    let ctl: Double
    let atl: Double
    let tsb: Double
    let dailyTss: Double?
    let sessionsCount: Int?
    let rampRate: Double?

    enum CodingKeys: String, CodingKey {
        case date, ctl, atl, tsb
        case dailyTss = "daily_tss"
        case sessionsCount = "sessions_count"
        case rampRate = "ramp_rate"
    }

    var dateValue: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
}

// MARK: - PMC Analysis Response Models

struct PMCAnalysisResponse: Codable {
    let response: String
    let insights: [String]?
    let actionItems: [String]?
    let analysisType: String?
    let currentMetrics: PMCCurrentMetrics?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case response, insights, error
        case actionItems = "action_items"
        case analysisType = "analysis_type"
        case currentMetrics = "current_metrics"
    }
}

struct PMCCurrentMetrics: Codable {
    let ctl: Double?
    let atl: Double?
    let tsb: Double?
    let rampRate: Double?

    enum CodingKeys: String, CodingKey {
        case ctl, atl, tsb
        case rampRate = "ramp_rate"
    }
}

struct PMCAnalysisResult {
    let response: String
    let insights: [String]
    let actionItems: [String]
    let analysisType: String
    let error: String?
}

// MARK: - PMC Quick Status Response Models

struct PMCQuickStatusResponse: Codable {
    let metrics: PMCQuickMetrics?
    let historicalSummary: PMCHistoricalSummary?
    let interpretations: PMCInterpretations?
    let alerts: [String]?

    enum CodingKeys: String, CodingKey {
        case metrics, alerts
        case historicalSummary = "historical_summary"
        case interpretations
    }
}

struct PMCQuickMetrics: Codable {
    let ctl: Double?
    let atl: Double?
    let tsb: Double?
    let rampRate: Double?
    let formStatus: String?

    enum CodingKeys: String, CodingKey {
        case ctl, atl, tsb
        case rampRate = "ramp_rate"
        case formStatus = "form_status"
    }
}

struct PMCHistoricalSummary: Codable {
    let ctlTrend: String?
    let atlTrend: String?
    let tsbTrend: String?
    let weeklyAvgTss: Double?

    enum CodingKeys: String, CodingKey {
        case ctlTrend = "ctl_trend"
        case atlTrend = "atl_trend"
        case tsbTrend = "tsb_trend"
        case weeklyAvgTss = "weekly_avg_tss"
    }
}

struct PMCInterpretations: Codable {
    let ctl: String?
    let atl: String?
    let tsb: String?
    let rampRate: String?
    let overall: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ctl, atl, tsb, overall, error
        case rampRate = "ramp_rate"
    }
}

struct PMCQuickStatusResult {
    let metrics: PMCQuickMetrics?
    let historicalSummary: PMCHistoricalSummary?
    let interpretations: PMCInterpretations?
    let alerts: [String]
}

// MARK: - PMC Request Models

struct PMCAskRequest: Encodable {
    let question: String
}
