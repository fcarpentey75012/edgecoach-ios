/**
 * Sheets de configuration des widgets du Dashboard
 * Accessibles via l'icône gearshape sur chaque widget
 */

import SwiftUI

// MARK: - Widget Container

/// Container réutilisable pour les widgets avec header et icône de configuration
struct WidgetContainer<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager

    let title: String
    let icon: String
    let iconColor: Color
    let isEmpty: Bool
    let emptyMessage: String
    let onConfigTap: () -> Void
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        icon: String,
        iconColor: Color,
        isEmpty: Bool = false,
        emptyMessage: String = "Aucun élément configuré",
        onConfigTap: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.isEmpty = isEmpty
        self.emptyMessage = emptyMessage
        self.onConfigTap = onConfigTap
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            // Header avec titre et icône de configuration
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
                Button {
                    onConfigTap()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.textSecondary)
                }
            }

            // Contenu ou message vide
            if isEmpty {
                emptyStateView
            } else {
                content()
            }
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
    }

    private var emptyStateView: some View {
        HStack {
            Spacer()
            VStack(spacing: ECSpacing.xs) {
                Image(systemName: "tray")
                    .font(.title2)
                    .foregroundColor(themeManager.textTertiary)
                Text(emptyMessage)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, ECSpacing.lg)
            Spacer()
        }
    }
}

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
                            Image(systemName: "figure.outdoor.cycle")
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

// MARK: - Week Progress Config Sheet

struct WeekProgressConfigSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Binding var config: WeekProgressConfig

    @State private var isVisible: Bool = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $isVisible) {
                        HStack(spacing: ECSpacing.sm) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(themeManager.successColor)
                                .frame(width: 24)
                            Text("Afficher la progression")
                                .font(.ecBody)
                                .foregroundColor(themeManager.textPrimary)
                        }
                    }
                    .tint(themeManager.accentColor)
                    .listRowBackground(themeManager.cardColor)
                } header: {
                    Text("Affichage")
                        .foregroundColor(themeManager.textSecondary)
                } footer: {
                    Text("La barre de progression s'affiche uniquement si un objectif hebdomadaire est défini.")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor)
            .navigationTitle("Progression semaine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        config.isVisible = isVisible
                        dismiss()
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
                isVisible = config.isVisible
            }
        }
    }
}

// MARK: - Sports Breakdown Config Sheet

struct SportsBreakdownConfigSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Binding var config: SportsBreakdownConfig

    @State private var showCyclisme: Bool = true
    @State private var showCourse: Bool = true
    @State private var showNatation: Bool = true
    @State private var showAutre: Bool = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $showCyclisme) {
                        HStack(spacing: ECSpacing.sm) {
                            Image(systemName: "figure.outdoor.cycle")
                                .foregroundColor(themeManager.sportColor(for: .cyclisme))
                                .frame(width: 24)
                            Text("Cyclisme")
                                .font(.ecBody)
                                .foregroundColor(themeManager.textPrimary)
                        }
                    }
                    .tint(themeManager.sportColor(for: .cyclisme))
                    .listRowBackground(themeManager.cardColor)

                    Toggle(isOn: $showCourse) {
                        HStack(spacing: ECSpacing.sm) {
                            Image(systemName: "figure.run")
                                .foregroundColor(themeManager.sportColor(for: .course))
                                .frame(width: 24)
                            Text("Course à pied")
                                .font(.ecBody)
                                .foregroundColor(themeManager.textPrimary)
                        }
                    }
                    .tint(themeManager.sportColor(for: .course))
                    .listRowBackground(themeManager.cardColor)

                    Toggle(isOn: $showNatation) {
                        HStack(spacing: ECSpacing.sm) {
                            Image(systemName: "figure.pool.swim")
                                .foregroundColor(themeManager.sportColor(for: .natation))
                                .frame(width: 24)
                            Text("Natation")
                                .font(.ecBody)
                                .foregroundColor(themeManager.textPrimary)
                        }
                    }
                    .tint(themeManager.sportColor(for: .natation))
                    .listRowBackground(themeManager.cardColor)

                    Toggle(isOn: $showAutre) {
                        HStack(spacing: ECSpacing.sm) {
                            Image(systemName: "figure.mixed.cardio")
                                .foregroundColor(themeManager.sportColor(for: .autre))
                                .frame(width: 24)
                            Text("Autre")
                                .font(.ecBody)
                                .foregroundColor(themeManager.textPrimary)
                        }
                    }
                    .tint(themeManager.sportColor(for: .autre))
                    .listRowBackground(themeManager.cardColor)
                } header: {
                    Text("Sports à afficher")
                        .foregroundColor(themeManager.textSecondary)
                } footer: {
                    Text("Sélectionnez les disciplines à afficher dans la répartition par sport.")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor)
            .navigationTitle("Par sport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        config.showCyclisme = showCyclisme
                        config.showCourse = showCourse
                        config.showNatation = showNatation
                        config.showAutre = showAutre
                        dismiss()
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
                showCyclisme = config.showCyclisme
                showCourse = config.showCourse
                showNatation = config.showNatation
                showAutre = config.showAutre
            }
        }
    }
}

// MARK: - Planned Sessions Config Sheet

struct PlannedSessionsConfigSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Binding var config: PlannedSessionsConfig

    @State private var maxItems: Int = 5

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Nombre de séances", selection: $maxItems) {
                        ForEach(PlannedSessionsConfig.itemOptions, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(themeManager.cardColor)
                } header: {
                    Text("Nombre maximum")
                        .foregroundColor(themeManager.textSecondary)
                } footer: {
                    Text("Nombre de séances planifiées à afficher dans le widget.")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor)
            .navigationTitle("Séances prévues")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        config.maxItems = maxItems
                        dismiss()
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
                maxItems = config.maxItems
            }
        }
    }
}

// MARK: - Upcoming Sessions Config Sheet

struct UpcomingSessionsConfigSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Binding var config: UpcomingSessionsConfig

    @State private var maxItems: Int = 5

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Nombre de séances", selection: $maxItems) {
                        ForEach(UpcomingSessionsConfig.itemOptions, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(themeManager.cardColor)
                } header: {
                    Text("Nombre maximum")
                        .foregroundColor(themeManager.textSecondary)
                } footer: {
                    Text("Nombre de prochaines séances à afficher dans le widget.")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor)
            .navigationTitle("Prochaines séances")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        config.maxItems = maxItems
                        dismiss()
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
                maxItems = config.maxItems
            }
        }
    }
}

// MARK: - Recent Activities Config Sheet

struct RecentActivitiesConfigSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Binding var config: RecentActivitiesConfig

    @State private var maxItems: Int = 5

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Nombre d'activités", selection: $maxItems) {
                        ForEach(RecentActivitiesConfig.itemOptions, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(themeManager.cardColor)
                } header: {
                    Text("Nombre maximum")
                        .foregroundColor(themeManager.textSecondary)
                } footer: {
                    Text("Nombre d'activités récentes à afficher dans le widget.")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor)
            .navigationTitle("Activités récentes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        config.maxItems = maxItems
                        dismiss()
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
                maxItems = config.maxItems
            }
        }
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

#Preview("Sports Breakdown Config") {
    SportsBreakdownConfigSheet(config: .constant(SportsBreakdownConfig()))
        .environmentObject(ThemeManager.shared)
}

#Preview("Planned Sessions Config") {
    PlannedSessionsConfigSheet(config: .constant(PlannedSessionsConfig()))
        .environmentObject(ThemeManager.shared)
}
