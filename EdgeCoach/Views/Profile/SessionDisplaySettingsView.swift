/**
 * SessionDisplaySettingsView - Personnalisation de l'affichage des sessions
 * Métriques, graphiques, unités et ordre des onglets
 */

import SwiftUI

// MARK: - Session Display Preferences

struct SessionDisplayPreferences: Codable {
    var visibleMetrics: [SessionMetric]
    var defaultGraphs: [GraphType]
    var unitSystem: UnitSystem
    var showAdvancedMetrics: Bool
    
    // Nouvelles options
    var sectionsOrder: [SessionSectionType]
    var graphSmoothing: GraphSmoothing
    var mapType: MapType
    var colorizeTrace: Bool
    var traceColorMetric: SessionMetric

    static let `default` = SessionDisplayPreferences(
        visibleMetrics: SessionMetric.allCases,
        defaultGraphs: [.heartRate, .speed],
        unitSystem: .metric,
        showAdvancedMetrics: true,
        sectionsOrder: SessionSectionType.allCases,
        graphSmoothing: .none,
        mapType: .standard,
        colorizeTrace: true,
        traceColorMetric: .heartRate
    )
}

// MARK: - Enums

enum SessionSectionType: String, Codable, CaseIterable, Identifiable {
    case summary = "Résumé"
    case power = "Puissance"
    case speed = "Vitesse / Allure"
    case heartRate = "Cardio"
    case zones = "Zones"
    case elevation = "Altitude"
    case cadence = "Cadence"
    case performance = "Performance"
    case notes = "Notes"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .summary: return "chart.bar.fill"
        case .power: return "bolt.fill"
        case .speed: return "speedometer"
        case .heartRate: return "heart.fill"
        case .zones: return "chart.pie.fill"
        case .elevation: return "mountain.2.fill"
        case .cadence: return "arrow.clockwise"
        case .performance: return "chart.line.uptrend.xyaxis"
        case .notes: return "note.text"
        }
    }
}

enum GraphSmoothing: String, Codable, CaseIterable, Identifiable {
    case none = "Aucun (Brut)"
    case low = "3 secondes"
    case medium = "10 secondes"
    case high = "30 secondes"
    
    var id: String { rawValue }
}

enum MapType: String, Codable, CaseIterable, Identifiable {
    case standard = "Standard"
    case hybrid = "Hybride"
    case satellite = "Satellite"
    
    var id: String { rawValue }
}

enum SessionMetric: String, Codable, CaseIterable, Identifiable {
    case duration = "Durée"
    case distance = "Distance"
    case speed = "Vitesse"
    case pace = "Allure"
    case heartRate = "FC moyenne"
    case heartRateMax = "FC max"
    case calories = "Calories"
    case elevation = "Dénivelé"
    case power = "Puissance"
    case cadence = "Cadence"
    case temperature = "Température"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .duration: return "clock"
        case .distance: return "arrow.left.and.right"
        case .speed: return "speedometer"
        case .pace: return "figure.run"
        case .heartRate, .heartRateMax: return "heart.fill"
        case .calories: return "flame.fill"
        case .elevation: return "mountain.2.fill"
        case .power: return "bolt.fill"
        case .cadence: return "arrow.triangle.2.circlepath"
        case .temperature: return "thermometer.medium"
        }
    }
}

enum GraphType: String, Codable, CaseIterable, Identifiable {
    case heartRate = "Fréquence cardiaque"
    case speed = "Vitesse"
    case elevation = "Altitude"
    case power = "Puissance"
    case cadence = "Cadence"
    case pace = "Allure"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .heartRate: return "heart.fill"
        case .speed: return "speedometer"
        case .elevation: return "mountain.2.fill"
        case .power: return "bolt.fill"
        case .cadence: return "arrow.triangle.2.circlepath"
        case .pace: return "figure.run"
        }
    }
}

enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    case metric = "Métrique"
    case imperial = "Impérial"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .metric: return "km, km/h, m"
        case .imperial: return "mi, mph, ft"
        }
    }
}

// MARK: - Session Display Settings View

struct SessionDisplaySettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var preferences = SessionDisplayPreferences.default
    @State private var hasChanges = false
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            List {
                // Organisation
                layoutSection
                
                // Graphiques & Carte (Nouveau)
                visualisationSection
                
                // Unités
                unitsSection

                // Métriques visibles
                metricsSection

                // Graphiques par défaut
                graphsSection

                // Options avancées
                advancedSection
            }
            .listStyle(.insetGrouped)
            .environment(\.editMode, $editMode)
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor)
            .navigationTitle("Affichage sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        savePreferences()
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
        }
        .onAppear {
            loadPreferences()
        }
    }
    
    // MARK: - Layout Section (Reorder)
    
    private var layoutSection: some View {
        Section {
            ForEach(preferences.sectionsOrder) { section in
                HStack {
                    Image(systemName: section.icon)
                        .foregroundColor(themeManager.textSecondary)
                        .frame(width: 24)
                    Text(section.rawValue)
                        .font(.ecBody)
                        .foregroundColor(themeManager.textPrimary)
                }
                .listRowBackground(themeManager.cardColor)
            }
            .onMove { from, to in
                preferences.sectionsOrder.move(fromOffsets: from, toOffset: to)
                hasChanges = true
            }
        } header: {
            HStack {
                Text("Organisation")
                Spacer()
                Button(editMode == .active ? "Terminé" : "Modifier") {
                    withAnimation {
                        editMode = editMode == .active ? .inactive : .active
                    }
                }
                .font(.ecCaption)
                .foregroundColor(themeManager.accentColor)
            }
            .foregroundColor(themeManager.textSecondary)
        } footer: {
            if editMode == .active {
                Text("Déplacez les éléments pour changer l'ordre d'affichage.")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textTertiary)
            }
        }
    }
    
    // MARK: - Visualisation Section
    
    private var visualisationSection: some View {
        Section {
            // Lissage
            Picker("Lissage graphiques", selection: $preferences.graphSmoothing) {
                ForEach(GraphSmoothing.allCases) { smoothing in
                    Text(smoothing.rawValue).tag(smoothing)
                }
            }
            .listRowBackground(themeManager.cardColor)
            .onChange(of: preferences.graphSmoothing) { _ in hasChanges = true }
            
            // Carte
            Picker("Type de carte", selection: $preferences.mapType) {
                ForEach(MapType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .listRowBackground(themeManager.cardColor)
            .onChange(of: preferences.mapType) { _ in hasChanges = true }
            
            // Heatmap Toggle
            Toggle("Colorer la trace GPS", isOn: $preferences.colorizeTrace)
                .tint(themeManager.accentColor)
                .listRowBackground(themeManager.cardColor)
                .onChange(of: preferences.colorizeTrace) { _ in hasChanges = true }
                
            // Heatmap Metric
            if preferences.colorizeTrace {
                Picker("Métrique de trace", selection: $preferences.traceColorMetric) {
                    Text("Fréquence cardiaque").tag(SessionMetric.heartRate)
                    Text("Puissance").tag(SessionMetric.power)
                    Text("Vitesse").tag(SessionMetric.speed)
                    Text("Altitude").tag(SessionMetric.elevation)
                }
                .listRowBackground(themeManager.cardColor)
                .onChange(of: preferences.traceColorMetric) { _ in hasChanges = true }
            }
        } header: {
            Text("Visualisation")
                .foregroundColor(themeManager.textSecondary)
        }
    }

    // MARK: - Units Section

    private var unitsSection: some View {
        Section {
            ForEach(UnitSystem.allCases) { system in
                Button {
                    preferences.unitSystem = system
                    hasChanges = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(system.rawValue)
                                .font(.ecBody)
                                .foregroundColor(themeManager.textPrimary)
                            Text(system.description)
                                .font(.ecCaption)
                                .foregroundColor(themeManager.textSecondary)
                        }

                        Spacer()

                        if preferences.unitSystem == system {
                            Image(systemName: "checkmark")
                                .foregroundColor(themeManager.accentColor)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .listRowBackground(themeManager.cardColor)
            }
        } header: {
            Text("Système d'unités")
                .foregroundColor(themeManager.textSecondary)
        }
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        Section {
            ForEach(SessionMetric.allCases) { metric in
                Toggle(isOn: Binding(
                    get: { preferences.visibleMetrics.contains(metric) },
                    set: { isOn in
                        if isOn {
                            if !preferences.visibleMetrics.contains(metric) {
                                preferences.visibleMetrics.append(metric)
                            }
                        } else {
                            preferences.visibleMetrics.removeAll { $0 == metric }
                        }
                        hasChanges = true
                    }
                )) {
                    HStack(spacing: 12) {
                        Image(systemName: metric.icon)
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.accentColor)
                            .frame(width: 24)

                        Text(metric.rawValue)
                            .font(.ecBody)
                            .foregroundColor(themeManager.textPrimary)
                    }
                }
                .tint(themeManager.accentColor)
                .listRowBackground(themeManager.cardColor)
            }
        } header: {
            Text("Métriques affichées")
                .foregroundColor(themeManager.textSecondary)
        } footer: {
            Text("Sélectionnez les métriques à afficher dans le résumé des sessions.")
                .font(.ecCaption)
                .foregroundColor(themeManager.textTertiary)
        }
    }

    // MARK: - Graphs Section

    private var graphsSection: some View {
        Section {
            ForEach(GraphType.allCases) { graph in
                Toggle(isOn: Binding(
                    get: { preferences.defaultGraphs.contains(graph) },
                    set: { isOn in
                        if isOn {
                            if !preferences.defaultGraphs.contains(graph) {
                                preferences.defaultGraphs.append(graph)
                            }
                        } else {
                            preferences.defaultGraphs.removeAll { $0 == graph }
                        }
                        hasChanges = true
                    }
                )) {
                    HStack(spacing: 12) {
                        Image(systemName: graph.icon)
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.sportColor(for: .cyclisme))
                            .frame(width: 24)

                        Text(graph.rawValue)
                            .font(.ecBody)
                            .foregroundColor(themeManager.textPrimary)
                    }
                }
                .tint(themeManager.accentColor)
                .listRowBackground(themeManager.cardColor)
            }
        } header: {
            Text("Graphiques par défaut")
                .foregroundColor(themeManager.textSecondary)
        } footer: {
            Text("Ces graphiques s'afficheront automatiquement lors de l'ouverture d'une session.")
                .font(.ecCaption)
                .foregroundColor(themeManager.textTertiary)
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        Section {
            Toggle(isOn: $preferences.showAdvancedMetrics) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Métriques avancées")
                        .font(.ecBody)
                        .foregroundColor(themeManager.textPrimary)
                    Text("TSS, IF, NP, VI...")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }
            }
            .tint(themeManager.accentColor)
            .listRowBackground(themeManager.cardColor)
            .onChange(of: preferences.showAdvancedMetrics) { _ in
                hasChanges = true
            }

            Button(role: .destructive) {
                resetToDefaults()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Réinitialiser les paramètres")
                }
            }
            .listRowBackground(themeManager.cardColor)
        } header: {
            Text("Options")
                .foregroundColor(themeManager.textSecondary)
        }
    }

    // MARK: - Actions

    private func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: "sessionDisplayPreferences"),
           let decoded = try? JSONDecoder().decode(SessionDisplayPreferences.self, from: data) {
            preferences = decoded
            
            // Migration: si sectionsOrder est vide (nouvelle prop), on met la valeur par défaut
            if preferences.sectionsOrder.isEmpty {
                preferences.sectionsOrder = SessionSectionType.allCases
            }
        }
    }

    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "sessionDisplayPreferences")
        }
    }

    private func resetToDefaults() {
        preferences = SessionDisplayPreferences.default
        hasChanges = true
    }
}

// MARK: - Preview

#Preview {
    SessionDisplaySettingsView()
        .environmentObject(ThemeManager.shared)
}
