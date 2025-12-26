//
//  CoachingConfig.swift
//  EdgeCoach
//
//  Configuration modulaire du coaching avec 3 axes :
//  - Sport (spécialisation)
//  - Level (niveau utilisateur)
//  - Style (personnalité du coach)
//

import Foundation
import SwiftUI

// MARK: - Sport Specialization

/// Spécialisation sportive du coach
enum SportSpecialization: String, Codable, CaseIterable, Identifiable {
    case triathlon = "triathlon"
    case running = "running"
    case cycling = "cycling"
    case swimming = "swimming"

    var id: String { rawValue }

    /// Nom d'affichage en français
    var displayName: String {
        switch self {
        case .triathlon: return "Triathlon"
        case .running: return "Course à pied"
        case .cycling: return "Cyclisme"
        case .swimming: return "Natation"
        }
    }

    /// Icône SF Symbol
    var icon: String {
        switch self {
        case .triathlon: return "figure.mixed.cardio"
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        }
    }

    /// Emoji associé
    var emoji: String {
        switch self {
        case .triathlon: return "🏊‍♂️🚴‍♂️🏃‍♂️"
        case .running: return "🏃‍♂️"
        case .cycling: return "🚴‍♂️"
        case .swimming: return "🏊‍♂️"
        }
    }

    /// Couleur associée
    var color: Color {
        switch self {
        case .triathlon: return .orange
        case .running: return .green
        case .cycling: return .blue
        case .swimming: return .cyan
        }
    }
}

// MARK: - User Level

/// Niveau de l'utilisateur
enum UserLevel: String, Codable, CaseIterable, Identifiable {
    case discovery = "discovery"
    case amateur = "amateur"
    case competitor = "competitor"

    var id: String { rawValue }

    /// Nom d'affichage en français
    var displayName: String {
        switch self {
        case .discovery: return "Découverte"
        case .amateur: return "Amateur"
        case .competitor: return "Compétiteur"
        }
    }

    /// Description du niveau
    var description: String {
        switch self {
        case .discovery: return "Je débute, je veux apprendre et prendre du plaisir"
        case .amateur: return "Je m'entraîne régulièrement et je veux progresser"
        case .competitor: return "Je vise la performance et je connais les fondamentaux"
        }
    }

    /// Icône SF Symbol
    var icon: String {
        switch self {
        case .discovery: return "leaf.fill"
        case .amateur: return "star.fill"
        case .competitor: return "trophy.fill"
        }
    }

    /// Emoji associé
    var emoji: String {
        switch self {
        case .discovery: return "🌱"
        case .amateur: return "⭐"
        case .competitor: return "🏆"
        }
    }
}

// MARK: - Coaching Style

/// Style de personnalité du coach
enum CoachingStyle: String, Codable, CaseIterable, Identifiable {
    case sergeant = "sergeant"
    case analytical = "analytical"
    case supportive = "supportive"

    var id: String { rawValue }

    /// Nom d'affichage en français
    var displayName: String {
        switch self {
        case .sergeant: return "Sergent"
        case .analytical: return "Analytique"
        case .supportive: return "Bienveillant"
        }
    }

    /// Description du style
    var description: String {
        switch self {
        case .sergeant: return "Direct, exigeant, pousse au dépassement"
        case .analytical: return "Basé sur les données, scientifique, précis"
        case .supportive: return "Encourageant, empathique, positif"
        }
    }

    /// Icône SF Symbol
    var icon: String {
        switch self {
        case .sergeant: return "shield.fill"
        case .analytical: return "chart.bar.fill"
        case .supportive: return "heart.fill"
        }
    }

    /// Emoji associé
    var emoji: String {
        switch self {
        case .sergeant: return "🎖️"
        case .analytical: return "📊"
        case .supportive: return "💪"
        }
    }

    /// Couleur associée
    var color: Color {
        switch self {
        case .sergeant: return .red
        case .analytical: return .purple
        case .supportive: return .green
        }
    }
}

// MARK: - Coaching Config

/// Configuration complète du coaching
struct CoachingConfig: Codable, Equatable {
    var sport: SportSpecialization
    var level: UserLevel
    var style: CoachingStyle

    /// Configuration par défaut
    static let `default` = CoachingConfig(
        sport: .triathlon,
        level: .amateur,
        style: .supportive
    )

    /// Chaîne d'affichage pour l'UI
    var displayString: String {
        "\(sport.emoji) \(sport.displayName) • \(level.emoji) \(level.displayName) • \(style.emoji) \(style.displayName)"
    }

    /// Version courte pour l'UI
    var shortDisplayString: String {
        "\(sport.displayName) • \(level.displayName) • \(style.displayName)"
    }

    /// Dictionnaire pour l'API
    var toDictionary: [String: String] {
        [
            "sport": sport.rawValue,
            "level": level.rawValue,
            "style": style.rawValue
        ]
    }
}

// MARK: - API Request Model

/// Structure pour l'envoi au backend
struct CoachingConfigRequest: Codable {
    let sport: String
    let level: String
    let style: String

    init(from config: CoachingConfig) {
        self.sport = config.sport.rawValue
        self.level = config.level.rawValue
        self.style = config.style.rawValue
    }
}
