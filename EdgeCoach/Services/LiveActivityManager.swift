import Foundation
import ActivityKit

@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    // Référence vers l'activité en cours pour pouvoir la mettre à jour
    private var currentActivity: Activity<WorkoutAttributes>?
    
    private init() {}
    
    // MARK: - Start
    
    func startWorkout(name: String, type: String, duration: TimeInterval) {
        // 1. Vérifier si les Live Activities sont activées
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("🚫 Live Activities non autorisées")
            return
        }
        
        // 2. Définir les attributs statiques (ce qui ne change pas)
        let attributes = WorkoutAttributes(
            workoutName: name,
            workoutType: type,
            startTime: Date()
        )
        
        // 3. Définir l'état initial (ce qui change)
        let contentState = WorkoutAttributes.ContentState(
            remainingTime: formatDuration(duration),
            currentZone: 1, // Zone d'échauffement par défaut
            progress: 0.0
        )
        
        let content = ActivityContent(state: contentState, staleDate: nil)
        
        // 4. Demander le démarrage de l'activité
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil // Pas de push notification pour l'instant
            )
            print("✅ Live Activity démarrée: \(currentActivity?.id ?? "")")
        } catch {
            print("❌ Erreur au démarrage de la Live Activity: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Update
    
    func updateWorkout(remaining: TimeInterval, totalDuration: TimeInterval, zone: Int) async {
        guard let activity = currentActivity else { return }
        
        let progress = 1.0 - (remaining / totalDuration)
        
        let updatedState = WorkoutAttributes.ContentState(
            remainingTime: formatDuration(remaining),
            currentZone: zone,
            progress: min(max(progress, 0.0), 1.0)
        )
        
        let content = ActivityContent(state: updatedState, staleDate: nil)
        
        await activity.update(content)
    }
    
    // MARK: - Stop
    
    func stopWorkout() async {
        guard let activity = currentActivity else { return }
        
        // État final
        let finalState = WorkoutAttributes.ContentState(
            remainingTime: "Terminé",
            currentZone: 0,
            progress: 1.0
        )
        
        let content = ActivityContent(state: finalState, staleDate: nil)
        
        // .immediate : Disparaît tout de suite
        // .default : Reste sur l'écran de verrouillage un moment
        await activity.end(content, dismissalPolicy: .default)
        
        self.currentActivity = nil
        print("🛑 Live Activity arrêtée")
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
}
