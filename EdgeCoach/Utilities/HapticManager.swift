import UIKit
import SwiftUI

/// Gère les retours haptiques de manière centralisée pour assurer une cohérence sensorielle.
final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    /// Feedback léger pour les interactions simples (boutons, navigation).
    func playTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Feedback moyen pour les actions significatives (ouverture de menu, toggle).
    func playImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Feedback lourd pour les validations critiques ou les changements d'état majeurs.
    func playLock() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Notification de succès (ex: séance complétée).
    func playSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Notification d'erreur ou d'alerte.
    func playError() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    /// Feedback de sélection discret (ex: changement de jour dans un calendrier).
    func playSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

// MARK: - View Extension
extension View {
    /// Ajoute un retour haptique automatique lors du changement d'une valeur.
    func hapticFeedback<V: Equatable>(on value: V, style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onChange(of: value) { _ in
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
}
