/**
 * LayoutManager - Gestionnaire de mise en page modulaire
 * Permet à l'utilisateur de personnaliser l'ordre et la visibilité des widgets du dashboard
 */

import SwiftUI

// MARK: - Dashboard Widget Type

/// Types de widgets disponibles sur le dashboard
enum DashboardWidgetType: String, CaseIterable, Identifiable, Codable {
    case kpiSummary = "kpi_summary"
    case pmcStatus = "pmc_status"
    case performance = "performance"
    case weekProgress = "week_progress"
    case sportsBreakdown = "sports_breakdown"
    case plannedSessions = "planned_sessions"
    case upcomingSessions = "upcoming_sessions"
    case recentActivities = "recent_activities"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kpiSummary: return "Résumé"
        case .pmcStatus: return "État de forme"
        case .performance: return "Performance"
        case .weekProgress: return "Progression semaine"
        case .sportsBreakdown: return "Par sport"
        case .plannedSessions: return "Séances prévues"
        case .upcomingSessions: return "Prochaines séances"
        case .recentActivities: return "Activités récentes"
        }
    }

    var icon: String {
        switch self {
        case .kpiSummary: return "chart.bar.fill"
        case .pmcStatus: return "waveform.path.ecg"
        case .performance: return "gauge.with.dots.needle.67percent"
        case .weekProgress: return "chart.line.uptrend.xyaxis"
        case .sportsBreakdown: return "figure.run.square.stack"
        case .plannedSessions: return "calendar.badge.clock"
        case .upcomingSessions: return "calendar"
        case .recentActivities: return "clock.arrow.circlepath"
        }
    }

    var description: String {
        switch self {
        case .kpiSummary: return "Volume, distance, séances..."
        case .pmcStatus: return "CTL, ATL, TSB, fatigue"
        case .performance: return "CS/D', CP/W', CSS"
        case .weekProgress: return "Objectif hebdomadaire"
        case .sportsBreakdown: return "Répartition par discipline"
        case .plannedSessions: return "Séances du plan d'entraînement"
        case .upcomingSessions: return "Prochaines séances programmées"
        case .recentActivities: return "Dernières activités réalisées"
        }
    }

    /// Indique si ce widget a des options de configuration
    var isConfigurable: Bool {
        switch self {
        case .kpiSummary, .performance:
            return true
        default:
            return false
        }
    }

    /// Widgets affichés par défaut
    static var defaultWidgets: [DashboardWidgetType] {
        [.kpiSummary, .pmcStatus, .performance, .weekProgress, .sportsBreakdown, .plannedSessions, .recentActivities]
    }
}

// MARK: - Widget Configuration

/// Configuration d'un widget (ordre + visibilité)
struct WidgetConfiguration: Codable, Identifiable, Equatable {
    let type: DashboardWidgetType
    var isVisible: Bool
    var order: Int
    
    var id: String { type.rawValue }
    
    init(type: DashboardWidgetType, isVisible: Bool = true, order: Int = 0) {
        self.type = type
        self.isVisible = isVisible
        self.order = order
    }
}

// MARK: - Layout Manager

/// Gestionnaire de mise en page - Observable dans toute l'app
@MainActor
class LayoutManager: ObservableObject {
    // MARK: - Singleton
    static let shared = LayoutManager()
    
    // MARK: - Published Properties
    
    @Published var widgetConfigurations: [WidgetConfiguration] {
        didSet {
            saveConfigurations()
        }
    }
    
    // MARK: - Private Properties
    
    private let userDefaultsKey = "dashboardWidgetConfigurations"
    
    // MARK: - Init
    
    private init() {
        self.widgetConfigurations = Self.loadConfigurations()
    }
    
    // MARK: - Computed Properties
    
    /// Widgets visibles triés par ordre
    var visibleWidgets: [DashboardWidgetType] {
        widgetConfigurations
            .filter { $0.isVisible }
            .sorted { $0.order < $1.order }
            .map { $0.type }
    }
    
    /// Widgets masqués
    var hiddenWidgets: [DashboardWidgetType] {
        widgetConfigurations
            .filter { !$0.isVisible }
            .map { $0.type }
    }
    
    // MARK: - Public Methods
    
    /// Active/désactive un widget
    func toggleWidget(_ type: DashboardWidgetType) {
        if let index = widgetConfigurations.firstIndex(where: { $0.type == type }) {
            widgetConfigurations[index].isVisible.toggle()
        }
    }
    
    /// Déplace un widget
    func moveWidget(from source: IndexSet, to destination: Int) {
        var visible = widgetConfigurations.filter { $0.isVisible }.sorted { $0.order < $1.order }
        visible.move(fromOffsets: source, toOffset: destination)
        
        // Mettre à jour les ordres
        for (index, config) in visible.enumerated() {
            if let configIndex = widgetConfigurations.firstIndex(where: { $0.type == config.type }) {
                widgetConfigurations[configIndex].order = index
            }
        }
    }
    
    /// Réinitialise la configuration par défaut
    func resetToDefault() {
        widgetConfigurations = Self.createDefaultConfigurations()
    }
    
    /// Vérifie si un widget est visible
    func isWidgetVisible(_ type: DashboardWidgetType) -> Bool {
        widgetConfigurations.first(where: { $0.type == type })?.isVisible ?? false
    }
    
    // MARK: - Private Methods
    
    private func saveConfigurations() {
        if let encoded = try? JSONEncoder().encode(widgetConfigurations) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private static func loadConfigurations() -> [WidgetConfiguration] {
        guard let data = UserDefaults.standard.data(forKey: "dashboardWidgetConfigurations"),
              let configurations = try? JSONDecoder().decode([WidgetConfiguration].self, from: data) else {
            return createDefaultConfigurations()
        }
        
        // S'assurer que tous les types de widgets existent dans la config
        var updatedConfigs = configurations
        for type in DashboardWidgetType.allCases {
            if !updatedConfigs.contains(where: { $0.type == type }) {
                let newConfig = WidgetConfiguration(
                    type: type,
                    isVisible: DashboardWidgetType.defaultWidgets.contains(type),
                    order: updatedConfigs.count
                )
                updatedConfigs.append(newConfig)
            }
        }
        
        return updatedConfigs
    }
    
    private static func createDefaultConfigurations() -> [WidgetConfiguration] {
        DashboardWidgetType.allCases.enumerated().map { index, type in
            WidgetConfiguration(
                type: type,
                isVisible: DashboardWidgetType.defaultWidgets.contains(type),
                order: index
            )
        }
    }
}

// MARK: - Widget Editor View

/// Vue pour éditer la configuration des widgets
struct WidgetEditorView: View {
    @StateObject private var layoutManager = LayoutManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Section des widgets visibles (réordonnables)
                Section {
                    ForEach(layoutManager.widgetConfigurations.filter { $0.isVisible }.sorted { $0.order < $1.order }) { config in
                        WidgetRowView(config: config, isVisible: true) {
                            layoutManager.toggleWidget(config.type)
                        }
                    }
                    .onMove { source, destination in
                        layoutManager.moveWidget(from: source, to: destination)
                    }
                } header: {
                    Text("Widgets affichés")
                } footer: {
                    Text("Maintenez et faites glisser pour réorganiser")
                }
                
                // Section des widgets masqués
                if !layoutManager.hiddenWidgets.isEmpty {
                    Section("Widgets masqués") {
                        ForEach(layoutManager.widgetConfigurations.filter { !$0.isVisible }) { config in
                            WidgetRowView(config: config, isVisible: false) {
                                layoutManager.toggleWidget(config.type)
                            }
                        }
                    }
                }
                
                // Bouton de réinitialisation
                Section {
                    Button(role: .destructive) {
                        layoutManager.resetToDefault()
                    } label: {
                        Label("Réinitialiser", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Personnaliser")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        dismiss()
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
        }
    }
}

/// Ligne de widget dans l'éditeur
struct WidgetRowView: View {
    let config: WidgetConfiguration
    let isVisible: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: config.type.icon)
                .font(.system(size: 20))
                .foregroundColor(isVisible ? .accentColor : .secondary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(config.type.displayName)
                    .font(.body)
                Text(config.type.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                onToggle()
            } label: {
                Image(systemName: isVisible ? "minus.circle.fill" : "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(isVisible ? .red : .green)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Environment Key

private struct LayoutManagerKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue = LayoutManager.shared
}

extension EnvironmentValues {
    var layoutManager: LayoutManager {
        get { self[LayoutManagerKey.self] }
        set { self[LayoutManagerKey.self] = newValue }
    }
}

// MARK: - Preview

#Preview {
    WidgetEditorView()
        .environmentObject(ThemeManager.shared)
}
