/**
 * ThemeManager - Gestionnaire de thème centralisé
 * Gère les modes d'apparence et les couleurs d'accent personnalisables
 * Inspiré du style Apple Fitness (fond noir OLED, couleurs néon)
 */

import SwiftUI

// MARK: - Theme Mode

/// Modes d'apparence disponibles
enum ThemeMode: String, CaseIterable, Identifiable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case fitness = "fitness"  // Style Apple Fitness (noir OLED + contraste élevé)
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "Système"
        case .light: return "Clair"
        case .dark: return "Sombre"
        case .fitness: return "Fitness"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .fitness: return "figure.run"
        }
    }
    
    /// Convertit en ColorScheme SwiftUI (nil pour système)
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark, .fitness: return .dark
        }
    }
}

// MARK: - Accent Color

/// Couleurs d'accent personnalisables
enum AccentColorOption: String, CaseIterable, Identifiable, Codable {
    case blue = "blue"
    case green = "green"
    case red = "red"
    case orange = "orange"
    case pink = "pink"
    case purple = "purple"
    case cyan = "cyan"
    case yellow = "yellow"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .blue: return "Bleu"
        case .green: return "Vert"
        case .red: return "Rouge"
        case .orange: return "Orange"
        case .pink: return "Rose"
        case .purple: return "Violet"
        case .cyan: return "Cyan"
        case .yellow: return "Jaune"
        }
    }
    
    /// Couleur standard (mode clair/sombre classique)
    var color: Color {
        switch self {
        case .blue: return .ecPrimary
        case .green: return .ecSuccess
        case .red: return .ecError
        case .orange: return .ecWarning
        case .pink: return Color(hex: "#EC4899")
        case .purple: return .ecTriathlon
        case .cyan: return .ecSwimming
        case .yellow: return Color(hex: "#EAB308")
        }
    }
    
    /// Couleur néon (mode Fitness - plus saturée/lumineuse)
    var neonColor: Color {
        switch self {
        case .blue: return Color(hex: "#60A5FA")
        case .green: return Color(hex: "#4ADE80")
        case .red: return Color(hex: "#F87171")
        case .orange: return Color(hex: "#FB923C")
        case .pink: return Color(hex: "#F472B6")
        case .purple: return Color(hex: "#A78BFA")
        case .cyan: return Color(hex: "#22D3EE")
        case .yellow: return Color(hex: "#FACC15")
        }
    }
    
    /// Couleur atténuée pour les backgrounds
    var lightVariant: Color {
        color.opacity(0.15)
    }
    
    /// Couleur atténuée pour le mode Fitness
    var neonLightVariant: Color {
        neonColor.opacity(0.2)
    }
}

// MARK: - Theme Manager

/// Gestionnaire de thème centralisé - Observable dans toute l'app
@MainActor
class ThemeManager: ObservableObject {
    // MARK: - Singleton
    static let shared = ThemeManager()
    
    // MARK: - UserDefaults Keys
    private static let themeModeKey = "ec_themeMode"
    private static let accentColorKey = "ec_accentColor"
    
    // MARK: - Published Properties (avec persistance)
    
    @Published var themeMode: ThemeMode {
        didSet {
            UserDefaults.standard.set(themeMode.rawValue, forKey: Self.themeModeKey)
            UserDefaults.standard.synchronize()
            #if DEBUG
            print("🎨 Theme changed to: \(themeMode.displayName)")
            #endif
        }
    }
    
    @Published var accentColorOption: AccentColorOption {
        didSet {
            UserDefaults.standard.set(accentColorOption.rawValue, forKey: Self.accentColorKey)
            UserDefaults.standard.synchronize()
            #if DEBUG
            print("🎨 Accent color changed to: \(accentColorOption.displayName)")
            #endif
        }
    }
    
    // MARK: - Init
    
    private init() {
        // Lire les valeurs persistées - Fitness par défaut
        let storedThemeModeRaw = UserDefaults.standard.string(forKey: Self.themeModeKey) ?? ThemeMode.fitness.rawValue
        let storedAccentColorRaw = UserDefaults.standard.string(forKey: Self.accentColorKey) ?? AccentColorOption.blue.rawValue
        
        self.themeMode = ThemeMode(rawValue: storedThemeModeRaw) ?? .fitness
        self.accentColorOption = AccentColorOption(rawValue: storedAccentColorRaw) ?? .blue
        
        #if DEBUG
        print("🎨 ThemeManager initialized - Mode: \(themeMode.displayName), Accent: \(accentColorOption.displayName)")
        #endif
    }
    
    // MARK: - Computed Properties
    
    /// Mode Fitness actif ?
    var isFitnessMode: Bool {
        themeMode == .fitness
    }
    
    /// ColorScheme à appliquer (nil = suivre le système)
    var preferredColorScheme: ColorScheme? {
        themeMode.colorScheme
    }
    
    /// Couleur d'accent active (adaptée au mode)
    var accentColor: Color {
        isFitnessMode ? accentColorOption.neonColor : accentColorOption.color
    }
    
    /// Variante claire de l'accent
    var accentColorLight: Color {
        isFitnessMode ? accentColorOption.neonLightVariant : accentColorOption.lightVariant
    }
    
    // MARK: - Background Colors
    
    /// Fond principal de l'app
    var backgroundColor: Color {
        isFitnessMode ? .ecFitnessBackground : .ecBackground
    }
    
    /// Fond des cartes/surfaces
    var surfaceColor: Color {
        isFitnessMode ? .ecFitnessSurface : .white
    }
    
    /// Fond des cartes secondaires
    var cardColor: Color {
        isFitnessMode ? .ecFitnessCard : .white
    }
    
    /// Fond des éléments surélevés
    var elevatedColor: Color {
        isFitnessMode ? .ecFitnessElevated : .ecSecondary50
    }
    
    // MARK: - Text Colors
    
    /// Texte principal
    var textPrimary: Color {
        isFitnessMode ? .ecFitnessTextPrimary : .ecSecondary800
    }
    
    /// Texte secondaire
    var textSecondary: Color {
        isFitnessMode ? .ecFitnessTextSecondary : .ecSecondary500
    }
    
    /// Texte tertiaire/désactivé
    var textTertiary: Color {
        isFitnessMode ? .ecFitnessTextTertiary : .ecGray400
    }
    
    // MARK: - Separator & Border
    
    var separatorColor: Color {
        isFitnessMode ? .ecFitnessSeparator : .ecSecondary200
    }
    
    var borderColor: Color {
        isFitnessMode ? .ecFitnessBorder : .ecSecondary200
    }
    
    // MARK: - Status Colors (adaptées au mode)
    
    var successColor: Color {
        isFitnessMode ? .ecNeonRunning : .ecSuccess
    }
    
    var warningColor: Color {
        isFitnessMode ? .ecNeonCycling : .ecWarning
    }
    
    var errorColor: Color {
        isFitnessMode ? Color(hex: "#F87171") : .ecError
    }
    
    var infoColor: Color {
        accentColor
    }
    
    // MARK: - Sport Colors (adaptées au mode Fitness)
    
    func sportColor(for discipline: Discipline) -> Color {
        if isFitnessMode {
            return Color.neonSportColor(for: discipline)
        } else {
            return Color.sportColor(for: discipline)
        }
    }
    
    func sportColorLight(for discipline: Discipline) -> Color {
        sportColor(for: discipline).opacity(isFitnessMode ? 0.2 : 0.15)
    }
    
    // MARK: - Zone Colors
    
    func zoneColor(for zone: Int) -> Color {
        let neonColors: [Color] = [
            Color(hex: "#A1A1AA"),  // Z1 - Recovery
            Color(hex: "#4ADE80"),  // Z2 - Endurance
            Color(hex: "#A3E635"),  // Z3 - Tempo
            Color(hex: "#FACC15"),  // Z4 - Threshold
            Color(hex: "#FB923C"),  // Z5 - VO2max
            Color(hex: "#F87171"),  // Z6 - Anaerobic
            Color(hex: "#EF4444")   // Z7 - Neuromuscular
        ]
        
        let standardColors: [Color] = [
            .ecZone1, .ecZone2, .ecZone3, .ecZone4, .ecZone5, .ecZone6, .ecZone7
        ]
        
        guard zone >= 1 && zone <= 7 else { return textTertiary }
        
        let colors = isFitnessMode ? neonColors : standardColors
        return colors[zone - 1]
    }
    
    // MARK: - Tab Bar Appearance
    
    var tabBarBackgroundColor: Color {
        isFitnessMode ? .ecFitnessSurface : .white
    }
    
    // MARK: - Card Style
    
    /// Ombre pour les cartes (pas d'ombre en mode Fitness)
    var cardShadow: Color {
        isFitnessMode ? .clear : .black.opacity(0.05)
    }
    
    var cardShadowRadius: CGFloat {
        isFitnessMode ? 0 : 4
    }
    
    /// Border pour les cartes en mode Fitness
    var cardBorderWidth: CGFloat {
        isFitnessMode ? 1 : 0
    }
}

// MARK: - Environment Key

private struct ThemeManagerKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Applique le thème global à une vue
    func withTheme(_ themeManager: ThemeManager) -> some View {
        self
            .environment(\.themeManager, themeManager)
            .preferredColorScheme(themeManager.preferredColorScheme)
            .tint(themeManager.accentColor)
    }
}

// MARK: - Themed Card Modifier

struct ThemedCardStyle: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    var padding: CGFloat = ECSpacing.md
    var cornerRadius: CGFloat = ECRadius.lg
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(themeManager.cardColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(themeManager.borderColor, lineWidth: themeManager.cardBorderWidth)
            )
            .shadow(
                color: themeManager.cardShadow,
                radius: themeManager.cardShadowRadius,
                x: 0,
                y: 2
            )
    }
}

extension View {
    /// Applique un style de carte thématisé
    func themedCard(
        padding: CGFloat = ECSpacing.md,
        cornerRadius: CGFloat = ECRadius.lg
    ) -> some View {
        modifier(ThemedCardStyle(padding: padding, cornerRadius: cornerRadius))
    }
}
