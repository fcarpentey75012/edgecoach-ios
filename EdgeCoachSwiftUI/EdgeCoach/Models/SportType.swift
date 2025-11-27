/**
 * Type de sport pour les zones d'entraînement
 * Utilisé pour les zones FC/Puissance/Allure
 */

import SwiftUI

enum SportType: String, CaseIterable, Identifiable, Codable {
    case running = "running"
    case cycling = "cycling"
    case swimming = "swimming"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .running: return "Course"
        case .cycling: return "Vélo"
        case .swimming: return "Natation"
        }
    }

    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        }
    }

    var color: Color {
        switch self {
        case .running: return .ecRunning
        case .cycling: return .ecCycling
        case .swimming: return .ecSwimming
        }
    }

    /// Convertit depuis Discipline (modèle activité)
    init?(from discipline: Discipline) {
        switch discipline {
        case .course: self = .running
        case .cyclisme: self = .cycling
        case .natation: self = .swimming
        case .autre: return nil
        }
    }

    /// Convertit vers Discipline (modèle activité)
    var discipline: Discipline {
        switch self {
        case .running: return .course
        case .cycling: return .cyclisme
        case .swimming: return .natation
        }
    }
}
