import SwiftUI

struct DashboardSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var preferences: DashboardPreferences
    @Environment(\.dismiss) private var dismiss
    
    // État local pour l'édition des métriques
    @State private var availableMetrics: [DashboardMetric] = DashboardMetric.allCases
    
    var body: some View {
        NavigationStack {
            List {
                // Section 1: Granularité Temporelle
                Section {
                    Picker("Période par défaut", selection: $preferences.timeScope) {
                        ForEach(DashboardTimeScope.allCases) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(themeManager.cardColor)
                } header: {
                    Text("Affichage")
                        .foregroundColor(themeManager.textSecondary)
                } footer: {
                    Text("Cette période sera sélectionnée par défaut au démarrage.")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
                
                // Section 2: KPIs (Indicateurs Clés)
                Section {
                    ForEach(preferences.selectedMetrics) { metric in
                        HStack {
                            Image(systemName: metric.icon)
                                .foregroundColor(themeManager.accentColor)
                                .frame(width: 24)
                            Text(metric.rawValue)
                                .foregroundColor(themeManager.textPrimary)
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(themeManager.textTertiary)
                        }
                        .listRowBackground(themeManager.cardColor)
                    }
                    .onMove(perform: moveMetrics)
                    .onDelete(perform: deleteMetrics)
                    
                    NavigationLink {
                        AddMetricView(
                            availableMetrics: availableMetrics,
                            selectedMetrics: $preferences.selectedMetrics
                        )
                        .environmentObject(themeManager)
                    } label: {
                        Label("Ajouter un indicateur", systemImage: "plus.circle")
                            .foregroundColor(themeManager.accentColor)
                    }
                    .listRowBackground(themeManager.cardColor)
                    
                } header: {
                    Text("Indicateurs Clés (KPIs)")
                        .foregroundColor(themeManager.textSecondary)
                } footer: {
                    Text("Choisissez et ordonnez les indicateurs affichés en haut du dashboard.")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor)
            .navigationTitle("Personnaliser")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
    
    private func moveMetrics(from source: IndexSet, to destination: Int) {
        preferences.selectedMetrics.move(fromOffsets: source, toOffset: destination)
    }
    
    private func deleteMetrics(at offsets: IndexSet) {
        preferences.selectedMetrics.remove(atOffsets: offsets)
    }
}

struct AddMetricView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let availableMetrics: [DashboardMetric]
    @Binding var selectedMetrics: [DashboardMetric]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(availableMetrics) { metric in
                if !selectedMetrics.contains(metric) {
                    Button {
                        withAnimation {
                            selectedMetrics.append(metric)
                        }
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: metric.icon)
                                .foregroundColor(themeManager.accentColor)
                                .frame(width: 24)
                            Text(metric.rawValue)
                                .foregroundColor(themeManager.textPrimary)
                            Spacer()
                            Image(systemName: "plus.circle")
                                .foregroundColor(themeManager.successColor)
                        }
                    }
                    .listRowBackground(themeManager.cardColor)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(themeManager.backgroundColor)
        .navigationTitle("Ajouter un indicateur")
    }
}
