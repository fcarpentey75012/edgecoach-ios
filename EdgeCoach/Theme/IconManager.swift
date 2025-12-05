/**
 * IconManager - Gestionnaire d'icônes centralisé
 * Fournit une abstraction sur SF Symbols avec support des styles par thème
 */

import SwiftUI

// MARK: - Icon Style

/// Style d'icône selon le thème
enum IconStyle: String, CaseIterable, Identifiable, Codable {
    case regular = "regular"    // Icônes outline
    case filled = "filled"      // Icônes pleines
    case auto = "auto"          // Automatique selon le thème
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .regular: return "Contour"
        case .filled: return "Plein"
        case .auto: return "Automatique"
        }
    }
}

// MARK: - App Icons Catalog

/// Catalogue centralisé de toutes les icônes de l'app
enum AppIcon: String, CaseIterable {
    // MARK: - Navigation
    case dashboard = "house"
    case coach = "bubble.left.and.bubble.right"
    case calendar = "calendar"
    case stats = "chart.bar"
    case profile = "person"
    case settings = "gearshape"
    
    // MARK: - Sports
    case cycling = "figure.outdoor.cycle"
    case running = "figure.run"
    case swimming = "figure.pool.swim"
    case triathlon = "figure.mixed.cardio"
    case otherSport = "figure.strengthtraining.functional"
    
    // MARK: - Actions
    case add = "plus"
    case addCircle = "plus.circle"
    case edit = "pencil"
    case delete = "trash"
    case share = "square.and.arrow.up"
    case close = "xmark"
    case back = "chevron.left"
    case forward = "chevron.right"
    case up = "chevron.up"
    case down = "chevron.down"
    case menu = "line.3.horizontal"
    case filter = "line.3.horizontal.decrease"
    case search = "magnifyingglass"
    case refresh = "arrow.clockwise"
    
    // MARK: - Data & Metrics
    case clock = "clock"
    case distance = "arrow.left.and.right"
    case speed = "speedometer"
    case heartRate = "heart"
    case power = "bolt"
    case elevation = "mountain.2"
    case calories = "flame"
    case tss = "chart.line.uptrend.xyaxis"
    
    // MARK: - Status
    case success = "checkmark.circle"
    case warning = "exclamationmark.triangle"
    case error = "xmark.circle"
    case info = "info.circle"
    
    // MARK: - Training
    case plan = "doc.text"
    case session = "figure.strengthtraining.traditional"
    case workout = "dumbbell"
    case rest = "bed.double"
    case warmup = "sunrise"
    case cooldown = "sunset"
    
    // MARK: - Progress
    case progress = "chart.bar.xaxis"
    case goal = "target"
    case trophy = "trophy"
    case medal = "medal"
    case streak = "flame.circle"
    
    // MARK: - Equipment
    case equipment = "wrench.and.screwdriver"
    case bike = "bicycle.circle"
    case shoes = "shoe"
    case watch = "applewatch"
    case sensor = "sensor.tag.radiowaves.forward"
    
    // MARK: - Communication
    case message = "message"
    case notification = "bell"
    case send = "paperplane"
    
    // MARK: - User
    case user = "person.crop.circle"
    case userCircle = "person.circle"
    case users = "person.2"
    case coachIcon = "person.badge.shield.checkmark"
    
    // MARK: - Misc
    case sun = "sun.max"
    case moon = "moon"
    case theme = "circle.lefthalf.filled"
    case color = "paintpalette"
    case widget = "square.grid.2x2"
    case lock = "lock"
    case unlock = "lock.open"
    case link = "link"
    case external = "arrow.up.right.square"
    
    /// Nom SF Symbol de base (outline)
    var symbolName: String { rawValue }
    
    /// Nom SF Symbol plein (filled)
    var filledSymbolName: String {
        // Certaines icônes ont un variant ".fill"
        let fillable = [
            "house", "calendar", "chart.bar", "person", "gearshape",
            "plus.circle", "trash", "clock", "heart", "bolt",
            "flame", "checkmark.circle", "xmark.circle", "info.circle",
            "exclamationmark.triangle", "bell", "message", "paperplane",
            "person.circle", "sun.max", "moon", "lock", "lock.open",
            "target", "trophy", "medal", "person.crop.circle"
        ]
        
        if fillable.contains(rawValue) {
            return rawValue + ".fill"
        }
        return rawValue
    }
}

// MARK: - Icon Manager

/// Gestionnaire d'icônes avec support des thèmes
@MainActor
class IconManager: ObservableObject {
    // MARK: - Singleton
    static let shared = IconManager()
    
    // MARK: - Properties
    @Published var iconStyle: IconStyle {
        didSet {
            UserDefaults.standard.set(iconStyle.rawValue, forKey: "iconStyle")
        }
    }
    
    private init() {
        let storedIconStyle = UserDefaults.standard.string(forKey: "iconStyle") ?? IconStyle.auto.rawValue
        self.iconStyle = IconStyle(rawValue: storedIconStyle) ?? .auto
    }
    
    // MARK: - Methods
    
    /// Retourne le nom de l'icône selon le style actuel et le thème
    func symbolName(for icon: AppIcon, isFitnessMode: Bool) -> String {
        switch iconStyle {
        case .regular:
            return icon.symbolName
        case .filled:
            return icon.filledSymbolName
        case .auto:
            // En mode Fitness, on utilise les icônes pleines pour plus de contraste
            return isFitnessMode ? icon.filledSymbolName : icon.symbolName
        }
    }
    
    /// Retourne une Image SwiftUI pour l'icône
    func image(for icon: AppIcon, isFitnessMode: Bool) -> Image {
        Image(systemName: symbolName(for: icon, isFitnessMode: isFitnessMode))
    }
}

// MARK: - Sport Icon Helper

extension AppIcon {
    /// Icône pour une discipline sportive
    static func forDiscipline(_ discipline: Discipline) -> AppIcon {
        switch discipline {
        case .cyclisme: return .cycling
        case .course: return .running
        case .natation: return .swimming
        case .autre: return .otherSport
        }
    }
    
    /// Icône pour un SportType
    static func forSportType(_ sportType: SportType) -> AppIcon {
        switch sportType {
        case .cycling: return .cycling
        case .running: return .running
        case .swimming: return .swimming
        }
    }
}

// MARK: - View Extension

extension View {
    /// Crée une icône thématisée
    func themedIcon(_ icon: AppIcon, size: CGFloat = 20) -> some View {
        ThemedIconView(icon: icon, size: size)
    }
}

/// Vue d'icône thématisée
struct ThemedIconView: View {
    let icon: AppIcon
    var size: CGFloat = 20
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Image(systemName: IconManager.shared.symbolName(for: icon, isFitnessMode: themeManager.isFitnessMode))
            .font(.system(size: size))
    }
}

// MARK: - Icon Picker View

/// Sélecteur de style d'icône pour les paramètres
struct IconStylePicker: View {
    @StateObject private var iconManager = IconManager.shared
    
    var body: some View {
        Picker("Style d'icônes", selection: $iconManager.iconStyle) {
            ForEach(IconStyle.allCases) { style in
                Text(style.displayName).tag(style)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - Preview Helpers

#Preview("Icon Catalog") {
    ScrollView {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            ForEach([
                AppIcon.dashboard, .coach, .calendar, .stats, .profile,
                .cycling, .running, .swimming,
                .clock, .distance, .heartRate, .power,
                .success, .warning, .error, .info
            ], id: \.rawValue) { icon in
                VStack(spacing: 8) {
                    Image(systemName: icon.filledSymbolName)
                        .font(.title)
                    Text(icon.rawValue)
                        .font(.caption2)
                        .lineLimit(1)
                }
            }
        }
        .padding()
    }
}
