import ActivityKit
import Foundation

struct WorkoutAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Données qui changent en temps réel (Dynamique)
        var remainingTime: String
        var currentZone: Int
        var progress: Double
    }

    // Données fixes au lancement de l'activité
    var workoutName: String
    var workoutType: String // "Run", "Bike", "Swim"
    var startTime: Date
}
