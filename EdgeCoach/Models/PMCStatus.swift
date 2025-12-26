/**
 * PMCStatus - Performance Management Chart Status
 * Données de forme physique (CTL, ATL, TSB)
 */

import Foundation
import SwiftUI

// MARK: - PMC Status Response

struct PMCStatusResponse: Codable {
    let status: String
    let data: PMCStatus
}

// MARK: - PMC Status

struct PMCStatus: Codable {
    let date: String
    let ctl: Double          // Chronic Training Load (Fitness ~42j)
    let atl: Double          // Acute Training Load (Fatigue ~7j)
    let tsb: Double          // Training Stress Balance (Form = CTL - ATL)
    let rampRate: Double?    // Taux de progression (peut être null)
    let dailyTss: Double?    // TSS du jour (peut être null)
    let formStatus: String   // "neutral", "fresh", "fatigued", "peaking"
    let formLabel: String    // "Équilibré", "Frais", "Fatigué", "Au top"
    let formEmoji: String    // Emoji correspondant
    let alertStrings: [String]  // L'API renvoie des strings, pas des objets PMCAlert
    let alertsCount: Int
    let hasCriticalAlert: Bool
    let modulationFactor: Double?  // Peut être null
    let recommendation: String?    // Peut être null
    let dataCoverage: PMCDataCoverage?

    enum CodingKeys: String, CodingKey {
        case date, ctl, atl, tsb
        case rampRate = "ramp_rate"
        case dailyTss = "daily_tss"
        case formStatus = "form_status"
        case formLabel = "form_label"
        case formEmoji = "form_emoji"
        case alertStrings = "alerts"
        case alertsCount = "alerts_count"
        case hasCriticalAlert = "has_critical_alert"
        case modulationFactor = "modulation_factor"
        case recommendation
        case dataCoverage = "data_coverage"
    }

    /// Convertit les alertes strings en objets PMCAlert pour l'affichage
    var alerts: [PMCAlert] {
        alertStrings.map { alertCode in
            PMCAlert.fromCode(alertCode)
        }
    }

    // MARK: - Computed Properties

    /// Couleur basée sur le TSB
    var tsbColor: Color {
        switch tsb {
        case ..<(-20):
            return .red          // Très fatigué
        case -20..<(-10):
            return .orange       // Fatigué
        case -10..<5:
            return .yellow       // Équilibré
        case 5..<15:
            return .green        // Frais
        case 15..<25:
            return .blue         // Très frais
        default:
            return .purple       // Peaking
        }
    }

    /// Couleur du statut de forme
    var formColor: Color {
        switch formStatus.lowercased() {
        case "fatigued", "very_fatigued":
            return .red
        case "tired":
            return .orange
        case "neutral":
            return .yellow
        case "fresh":
            return .green
        case "very_fresh", "peaking":
            return .blue
        default:
            return .gray
        }
    }

    /// Icône SF Symbol pour le statut
    var formIcon: String {
        switch formStatus.lowercased() {
        case "fatigued", "very_fatigued":
            return "battery.25"
        case "tired":
            return "battery.50"
        case "neutral":
            return "battery.75"
        case "fresh":
            return "battery.100"
        case "very_fresh", "peaking":
            return "battery.100.bolt"
        default:
            return "battery.50"
        }
    }

    /// Tendance du ramp rate
    var rampTrend: String {
        guard let rate = rampRate else { return "→" }
        if rate > 2 {
            return "↗↗"  // Montée rapide
        } else if rate > 0.5 {
            return "↗"   // Montée
        } else if rate < -2 {
            return "↘↘"  // Descente rapide
        } else if rate < -0.5 {
            return "↘"   // Descente
        } else {
            return "→"   // Stable
        }
    }

    /// Description du TSB
    var tsbDescription: String {
        switch tsb {
        case ..<(-20):
            return "Fatigue élevée"
        case -20..<(-10):
            return "Fatigué"
        case -10..<5:
            return "Équilibré"
        case 5..<15:
            return "Frais"
        case 15..<25:
            return "Très frais"
        default:
            return "Forme optimale"
        }
    }
}

// MARK: - PMC Alert

struct PMCAlert: Codable, Identifiable {
    var id: String { type + severity }
    let type: String
    let severity: String
    let message: String

    /// Crée une alerte à partir d'un code string retourné par l'API
    static func fromCode(_ code: String) -> PMCAlert {
        // Mapping des codes d'alerte vers les objets PMCAlert
        switch code.lowercased() {
        case "tsb_critical":
            return PMCAlert(
                type: "tsb_critical",
                severity: "critical",
                message: "Fatigue extrême - repos recommandé"
            )
        case "tsb_warning":
            return PMCAlert(
                type: "tsb_warning",
                severity: "warning",
                message: "Fatigue accumulée - attention"
            )
        case "ramp_rate_critical":
            return PMCAlert(
                type: "ramp_rate_critical",
                severity: "critical",
                message: "Progression trop rapide"
            )
        case "ramp_rate_high":
            return PMCAlert(
                type: "ramp_rate_high",
                severity: "warning",
                message: "Progression rapide - surveiller"
            )
        case "overreaching":
            return PMCAlert(
                type: "overreaching",
                severity: "critical",
                message: "Surmenage détecté"
            )
        case "freshness":
            return PMCAlert(
                type: "freshness",
                severity: "info",
                message: "Fraîcheur élevée - idéal compétition"
            )
        default:
            return PMCAlert(
                type: code,
                severity: "info",
                message: code.replacingOccurrences(of: "_", with: " ").capitalized
            )
        }
    }

    var severityColor: Color {
        switch severity.lowercased() {
        case "critical":
            return .red
        case "warning":
            return .orange
        case "info":
            return .blue
        default:
            return .gray
        }
    }

    var severityIcon: String {
        switch severity.lowercased() {
        case "critical":
            return "exclamationmark.triangle.fill"
        case "warning":
            return "exclamationmark.circle.fill"
        case "info":
            return "info.circle.fill"
        default:
            return "circle.fill"
        }
    }
}

// MARK: - PMC Data Coverage

struct PMCDataCoverage: Codable {
    let count: Int
    let dateRange: PMCDateRange?

    enum CodingKeys: String, CodingKey {
        case count
        case dateRange = "date_range"
    }
}

struct PMCDateRange: Codable {
    let from: String
    let to: String
}

// MARK: - Preview Helpers

extension PMCStatus {
    static var preview: PMCStatus {
        PMCStatus(
            date: "2025-12-05",
            ctl: 34.5,
            atl: 36.6,
            tsb: -2.1,
            rampRate: 1.3,
            dailyTss: 0.0,
            formStatus: "neutral",
            formLabel: "Équilibré",
            formEmoji: "🟡",
            alertStrings: [],
            alertsCount: 0,
            hasCriticalAlert: false,
            modulationFactor: 1.0,
            recommendation: "Zone optimale. Continuer le plan normalement.",
            dataCoverage: PMCDataCoverage(
                count: 91,
                dateRange: PMCDateRange(from: "2025-09-06", to: "2025-12-05")
            )
        )
    }

    static var previewFatigued: PMCStatus {
        PMCStatus(
            date: "2025-12-05",
            ctl: 45.0,
            atl: 65.0,
            tsb: -20.0,
            rampRate: 3.5,
            dailyTss: 120.0,
            formStatus: "fatigued",
            formLabel: "Fatigué",
            formEmoji: "🔴",
            alertStrings: ["tsb_warning"],
            alertsCount: 1,
            hasCriticalAlert: false,
            modulationFactor: 0.8,
            recommendation: "Réduire l'intensité. Privilégier la récupération.",
            dataCoverage: nil
        )
    }

    static var previewFresh: PMCStatus {
        PMCStatus(
            date: "2025-12-05",
            ctl: 50.0,
            atl: 35.0,
            tsb: 15.0,
            rampRate: -1.0,
            dailyTss: 45.0,
            formStatus: "fresh",
            formLabel: "Frais",
            formEmoji: "🟢",
            alertStrings: [],
            alertsCount: 0,
            hasCriticalAlert: false,
            modulationFactor: 1.1,
            recommendation: "Forme optimale pour une compétition ou séance clé.",
            dataCoverage: nil
        )
    }
}
