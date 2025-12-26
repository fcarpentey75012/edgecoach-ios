import SwiftUI

extension Image {
    /// Initialise une Image directement à partir d'une AppIcon
    /// - Parameter icon: L'icône de l'application à afficher
    init(icon: AppIcon) {
        self.init(systemName: icon.rawValue)
    }
}

extension Label where Title == Text, Icon == Image {
    /// Initialise un Label directement à partir d'une AppIcon
    /// - Parameters:
    ///   - titleKey: Le texte du label (clé de localisation)
    ///   - icon: L'icône de l'application à afficher
    init(_ titleKey: LocalizedStringKey, icon: AppIcon) {
        self.init(titleKey, systemImage: icon.rawValue)
    }
    
    /// Initialise un Label directement à partir d'une AppIcon (String simple)
    /// - Parameters:
    ///   - title: Le texte du label
    ///   - icon: L'icône de l'application à afficher
    init<S>(_ title: S, icon: AppIcon) where S : StringProtocol {
        self.init(title, systemImage: icon.rawValue)
    }
}
