// MARK: - Discipline

import Foundation

enum Discipline: String, Codable, CaseIterable, Identifiable {
    case cyclisme = "cyclisme"
    case course = "course"
    case natation = "natation"
    case autre = "autre"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cyclisme: return "Vélo"
        case .course: return "Course"
        case .natation: return "Natation"
        case .autre: return "Autre"
        }
    }

    var icon: String {
        AppIcon.forDiscipline(self).symbolName
    }

    /// Convertit le sport de l'API vers une discipline
    static func from(sport: String?) -> Discipline {
        guard let sport = sport?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) else { return .autre }

        // 1. Essayer un match exact sur les mots-clés connus
        switch sport {
        case "cycling", "cyclisme", "vélo", "velo", "home trainer", "ht", "virtualride", "road":
            return .cyclisme
        case "running", "course", "course à pied", "run", "trail", "treadmill":
            return .course
        case "swimming", "natation", "swim", "pool swim", "open water swim":
            return .natation
        default:
            // 2. Fallback sur contains pour les variantes (ex: "Indoor Cycling")
            if sport.contains("cycl") || sport.contains("vélo") || sport.contains("velo") || sport.contains("bike") {
                return .cyclisme
            } else if sport.contains("run") || sport.contains("course") || sport.contains("jog") {
                return .course
            } else if sport.contains("swim") || sport.contains("natation") || sport.contains("eau libre") {
                return .natation
            }
            return .autre
        }
    }
}
