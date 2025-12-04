/**
 * Sheets de configuration des widgets du Dashboard
 * Accessibles via long press sur chaque widget
 */

import SwiftUI

// MARK: - KPI Summary Config Sheet

struct KPISummaryConfigSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Binding var config: KPISummaryConfig

    // État local pour l'édition
    @State private var localTimeScope: DashboardTimeScope = .week
    @State private var localSelectedMetrics: [KPIMetricType] = []

    var body: some View {
        NavigationStack {
            List {
                // Section: Période par défaut
                Section {
                    Picker("Période", selection: $localTimeScope) {
                        Text("Semaine").tag(DashboardTimeScope.week)
                        Text("Mois").tag(DashboardTimeScope.month)
                        Text("Année").tag(DashboardTimeScope.year)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(themeManager.cardColor)
                } header: {
                    Text("Période par défaut")
                        .foregroundColor(themeManager.textSecondary)
                }

                // Section: Métriques à afficher
                Section {
                    ForEach(KPIMetricType.allCases) { metric in
                        Toggle(isOn: binding(for: metric)) {
                            HStack(spacing: ECSpacing.sm) {
                                Image(systemName: metric.icon)
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
                    Text("Sélectionnez les métriques à afficher dans la card de résumé.")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor)
            .navigationTitle("Configurer Résumé")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        saveAndDismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.textSecondary)
                }
            }
            .onAppear {
                localTimeScope = config.timeScope
                localSelectedMetrics = config.selectedMetrics
            }
        }
    }

    private func binding(for metric: KPIMetricType) -> Binding<Bool> {
        Binding(
            get: { localSelectedMetrics.contains(metric) },
            set: { isSelected in
                if isSelected {
                    if !localSelectedMetrics.contains(metric) {
                        localSelectedMetrics.append(metric)
                    }
                } else {
                    localSelectedMetrics.removeAll { $0 == metric }
                }
            }
        )
    }

    private func saveAndDismiss() {
        config.timeScope = localTimeScope
        config.selectedMetrics = localSelectedMetrics
        dismiss()
    }
}

// MARK: - Performance Widget Config Sheet

struct PerformanceWidgetConfigSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Binding var config: PerformanceWidgetConfig

    // État local
    @State private var showRunning: Bool = true
    @State private var showCycling: Bool = true
    @State private var showSwimming: Bool = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Course à pied (CS/D')
                    Toggle(isOn: $showRunning) {
                        HStack(spacing: ECSpacing.sm) {
                            Image(systemName: "figure.run")
                                .foregroundColor(themeManager.sportColor(for: .course))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Course à pied")
                                    .font(.ecBody)
                                    .foregroundColor(themeManager.textPrimary)
                                Text("Critical Speed & D'")
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textTertiary)
                            }
                        }
                    }
                    .tint(themeManager.sportColor(for: .course))
                    .listRowBackground(themeManager.cardColor)

                    // Cyclisme (CP/W')
                    Toggle(isOn: $showCycling) {
                        HStack(spacing: ECSpacing.sm) {
                            Image(systemName: "bicycle")
                                .foregroundColor(themeManager.sportColor(for: .cyclisme))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cyclisme")
                                    .font(.ecBody)
                                    .foregroundColor(themeManager.textPrimary)
                                Text("Critical Power & W'")
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textTertiary)
                            }
                        }
                    }
                    .tint(themeManager.sportColor(for: .cyclisme))
                    .listRowBackground(themeManager.cardColor)

                    // Natation (CSS)
                    Toggle(isOn: $showSwimming) {
                        HStack(spacing: ECSpacing.sm) {
                            Image(systemName: "figure.pool.swim")
                                .foregroundColor(themeManager.sportColor(for: .natation))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Natation")
                                    .font(.ecBody)
                                    .foregroundColor(themeManager.textPrimary)
                                Text("Critical Swim Speed")
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textTertiary)
                            }
                        }
                    }
                    .tint(themeManager.sportColor(for: .natation))
                    .listRowBackground(themeManager.cardColor)
                } header: {
                    Text("Cards de performance")
                        .foregroundColor(themeManager.textSecondary)
                } footer: {
                    Text("Les cards ne s'affichent que si les données de performance sont disponibles.")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor)
            .navigationTitle("Configurer Performance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        saveAndDismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.textSecondary)
                }
            }
            .onAppear {
                showRunning = config.showRunning
                showCycling = config.showCycling
                showSwimming = config.showSwimming
            }
        }
    }

    private func saveAndDismiss() {
        config.showRunning = showRunning
        config.showCycling = showCycling
        config.showSwimming = showSwimming
        dismiss()
    }
}

// MARK: - Previews

#Preview("KPI Config") {
    KPISummaryConfigSheet(config: .constant(KPISummaryConfig()))
        .environmentObject(ThemeManager.shared)
}

#Preview("Performance Config") {
    PerformanceWidgetConfigSheet(config: .constant(PerformanceWidgetConfig()))
        .environmentObject(ThemeManager.shared)
}
