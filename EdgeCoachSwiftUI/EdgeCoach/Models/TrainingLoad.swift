/**
 * Modèle de Charge d'Entraînement (Training Load)
 * Basé sur les métriques Coggan (CTL, ATL, TSB) calculées par le backend
 */

import SwiftUI

// Structure correspondant à "meta.training_load" du backend
struct TrainingLoad: Codable {
    let ctl: Double? // Fitness (Chronic Training Load)
    let atl: Double? // Fatigue (Acute Training Load)
    let tsb: Double? // Forme (Training Stress Balance)
    let last7dTss: Double?
    let last42dTss: Double?

    enum CodingKeys: String, CodingKey {
        case ctl, atl, tsb
        case last7dTss = "last_7d_tss"
        case last42dTss = "last_42d_tss"
    }

    // Calcul dynamique de l'état de forme basé sur le TSB
    var status: FormStatus {
        guard let tsb = tsb else { return .unknown }
        switch tsb {
        case ..<(-30): return .overload
        case -30..<(-10): return .optimal
        case -10..<5: return .neutral
        case 5..<25: return .fresh
        default: return .transition // > 25
        }
    }
}

// Structure racine pour parser la réponse de l'endpoint /aggregate-metrics
struct AggregatedMetricsResponse: Codable {
    let meta: MetricsMeta?
}

struct MetricsMeta: Codable {
    let trainingLoad: TrainingLoad?
    
    enum CodingKeys: String, CodingKey {
        case trainingLoad = "training_load"
    }
}

enum FormStatus {
    case overload, optimal, neutral, fresh, transition, unknown

    var title: String {
        switch self {
        case .overload: return "Surcharge"
        case .optimal: return "Optimal"
        case .neutral: return "Maintien"
        case .fresh: return "Fraîcheur"
        case .transition: return "Transition"
        case .unknown: return "Inconnu"
        }
    }

    var description: String {
        switch self {
        case .overload: return "Risque de blessure élevé. Pensez à récupérer."
        case .optimal: return "Zone idéale pour progresser efficacement."
        case .neutral: return "Charge équilibrée, maintien des acquis."
        case .fresh: return "Prêt pour la performance (course)."
        case .transition: return "Désentraînement possible, reprenez le rythme."
        case .unknown: return "Données insuffisantes."
        }
    }

    var color: Color {
        switch self {
        case .overload: return .ecError
        case .optimal: return .ecSuccess
        case .neutral: return .ecInfo
        case .fresh: return .ecPrimary
        case .transition: return .ecGray500
        case .unknown: return .ecGray400
        }
    }
}
