// MARK: - Activity Light (Calendar Listing)

import Foundation

/// Modèle léger pour l'affichage calendrier (endpoint /activities/calendar)
/// Contient uniquement les champs nécessaires pour le listing
struct ActivityLight: Codable, Identifiable, Hashable {
    let id: String
    let date: String
    let sport: String?
    let name: String?
    let duration: Int?      // en secondes
    let distance: Double?   // en km
    let tss: Int?

    /// Discipline calculée depuis le sport
    var discipline: Discipline {
        Discipline.from(sport: sport)
    }

    /// Date parsée
    var dateValue: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        if let date = formatter.date(from: date) {
            return date
        }
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd"
        return simpleFormatter.date(from: date)
    }

    /// Durée formatée (ex: "1:30" ou "45min")
    var formattedDuration: String? {
        guard let dur = duration, dur > 0 else { return nil }
        let hours = dur / 3600
        let minutes = (dur % 3600) / 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return "\(minutes)min"
        }
    }

    /// Distance formatée (ex: "45.5 km" ou "1500 m")
    var formattedDistance: String? {
        guard let dist = distance, dist > 0 else { return nil }
        if discipline == .natation {
            return String(format: "%.0f m", dist * 1000)
        }
        if dist < 1 {
            return String(format: "%.0f m", dist * 1000)
        }
        return dist.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f km", dist)
            : String(format: "%.1f km", dist)
    }

    /// Titre affiché
    var displayTitle: String {
        name ?? discipline.displayName
    }
}
