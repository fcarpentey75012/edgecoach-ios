/**
 * MacroPlanDetailView - Vue détaillée du planning de saison
 * Affiche les graphiques, timeline et données du MacroPlan
 */

import SwiftUI
import Charts

// MARK: - MacroPlan Detail View

struct MacroPlanDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    let plan: MacroPlanData

    var body: some View {
        ScrollView {
            VStack(spacing: ECSpacing.xl) {
                // Header avec infos principales
                headerSection

                // Timeline Gantt
                timelineSection

                // Objectifs
                objectivesSection

                // Statistiques du plan
                statsSection

                // Répartition par phase
                phasesSection

                // Volume hebdomadaire (graphique)
                weeklyVolumeChart
            }
            .padding()
        }
        .background(themeManager.backgroundColor)
        .navigationTitle(plan.name ?? "Plan de saison")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            // Description
            if let description = plan.description, !description.isEmpty {
                Text(description)
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
            }

            // Dates
            HStack(spacing: ECSpacing.xl) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Début")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                    Text(formatDate(plan.startDate))
                        .font(.ecBodyMedium)
                        .foregroundColor(themeManager.textPrimary)
                }

                Image(systemName: "arrow.right")
                    .foregroundColor(themeManager.textTertiary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Fin")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                    Text(formatDate(plan.endDate))
                        .font(.ecBodyMedium)
                        .foregroundColor(themeManager.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Durée")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                    Text("\(totalWeeks) semaines")
                        .font(.ecBodyMedium)
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .padding()
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
        }
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader("Timeline", icon: "calendar.badge.clock")

            if let bars = plan.visualBars, !bars.isEmpty {
                VStack(spacing: ECSpacing.sm) {
                    // Barres de phase
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: ECRadius.sm)
                                .fill(themeManager.cardColor)

                            // Barres
                            ForEach(bars) { bar in
                                RoundedRectangle(cornerRadius: ECRadius.sm)
                                    .fill(colorForSegment(bar.segmentType))
                                    .frame(width: geometry.size.width * bar.widthRatio)
                                    .offset(x: geometry.size.width * bar.startRatio)
                            }
                        }
                    }
                    .frame(height: 24)

                    // Légende des phases
                    HStack(spacing: ECSpacing.lg) {
                        ForEach(bars) { bar in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(colorForSegment(bar.segmentType))
                                    .frame(width: 10, height: 10)
                                Text(bar.subplanName)
                                    .font(.ecCaption)
                                    .foregroundColor(themeManager.textSecondary)
                            }
                        }
                    }
                    .padding(.top, ECSpacing.xs)
                }
                .padding()
                .background(themeManager.cardColor)
                .cornerRadius(ECRadius.lg)
            }
        }
    }

    // MARK: - Objectives Section

    private var objectivesSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader("Objectifs", icon: "target")

            if let objectives = plan.objectives, !objectives.isEmpty {
                VStack(spacing: ECSpacing.sm) {
                    ForEach(objectives) { objective in
                        HStack(spacing: ECSpacing.md) {
                            // Badge priorité
                            Text(objective.priority.shortName)
                                .font(.ecCaptionBold)
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(objective.priority == .principal ? themeManager.warningColor : themeManager.infoColor)
                                .cornerRadius(ECRadius.sm)

                            // Infos
                            VStack(alignment: .leading, spacing: 2) {
                                Text(objective.name)
                                    .font(.ecBodyMedium)
                                    .foregroundColor(themeManager.textPrimary)

                                HStack(spacing: ECSpacing.sm) {
                                    if let format = objective.raceFormat {
                                        Text(format.displayName)
                                            .font(.ecCaption)
                                            .foregroundColor(themeManager.textSecondary)
                                    }
                                    Text(objective.targetDate)
                                        .font(.ecCaption)
                                        .foregroundColor(themeManager.textTertiary)
                                }
                            }

                            Spacer()

                            // Temps cible
                            if let time = objective.targetTime {
                                Text(time)
                                    .font(.ecBodyMedium)
                                    .foregroundColor(themeManager.accentColor)
                            }
                        }
                        .padding()
                        .background(themeManager.cardColor)
                        .cornerRadius(ECRadius.md)
                    }
                }
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader("Statistiques", icon: "chart.bar")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ECSpacing.md) {
                StatCard(title: "Semaines totales", value: "\(totalWeeks)", icon: "calendar", color: themeManager.accentColor)
                StatCard(title: "Volume total", value: "\(mockTotalHours)h", icon: "clock", color: .ecCycling)
                StatCard(title: "Séances prévues", value: "\(mockTotalSessions)", icon: "figure.run", color: .ecRunning)
                StatCard(title: "Objectifs", value: "\(plan.objectives?.count ?? 0)", icon: "target", color: .ecSwimming)
            }
        }
    }

    // MARK: - Phases Section

    private var phasesSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader("Phases du plan", icon: "list.bullet")

            if let bars = plan.visualBars, !bars.isEmpty {
                VStack(spacing: ECSpacing.sm) {
                    ForEach(bars) { bar in
                        HStack {
                            Circle()
                                .fill(colorForSegment(bar.segmentType))
                                .frame(width: 12, height: 12)

                            Text(bar.subplanName)
                                .font(.ecBodyMedium)
                                .foregroundColor(themeManager.textPrimary)

                            Spacer()

                            Text("S\(bar.weekStart)-S\(bar.weekEnd)")
                                .font(.ecCaption)
                                .foregroundColor(themeManager.textSecondary)

                            Text("\(bar.durationWeeks) sem.")
                                .font(.ecCaptionBold)
                                .foregroundColor(themeManager.textPrimary)
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding()
                        .background(themeManager.cardColor)
                        .cornerRadius(ECRadius.md)
                    }
                }
            }
        }
    }

    // MARK: - Weekly Volume Chart

    private var weeklyVolumeChart: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            sectionHeader("Volume hebdomadaire", icon: "chart.line.uptrend.xyaxis")

            Chart {
                ForEach(mockWeeklyVolume, id: \.week) { data in
                    BarMark(
                        x: .value("Semaine", "S\(data.week)"),
                        y: .value("Heures", data.hours)
                    )
                    .foregroundStyle(colorForPhase(data.phase).gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.ecCaption)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(.ecCaption)
                        }
                    }
                }
            }
            .padding()
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: ECSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(themeManager.accentColor)
            Text(title)
                .font(.ecH4)
                .foregroundColor(themeManager.textPrimary)
        }
    }

    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "-" }
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = inputFormatter.date(from: dateString) else { return dateString }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "d MMM yyyy"
        outputFormatter.locale = Locale(identifier: "fr_FR")
        return outputFormatter.string(from: date)
    }

    private func colorForSegment(_ type: String) -> Color {
        switch type.lowercased() {
        case "prep": return .blue.opacity(0.6)
        case "base": return .blue
        case "build": return .orange
        case "race": return themeManager.accentColor
        case "recovery": return .green
        default: return .gray
        }
    }

    private func colorForPhase(_ phase: String) -> Color {
        colorForSegment(phase)
    }

    // MARK: - Computed Properties

    private var totalWeeks: Int {
        if let bars = plan.visualBars, let lastBar = bars.last {
            return lastBar.weekEnd
        }
        return 0
    }

    // MARK: - Mock Data

    private var mockTotalHours: Int { 320 }
    private var mockTotalSessions: Int { 156 }

    private var mockWeeklyVolume: [WeeklyVolumeData] {
        // Génère des données mockées basées sur les phases
        var data: [WeeklyVolumeData] = []

        if let bars = plan.visualBars {
            for bar in bars {
                for week in bar.weekStart...bar.weekEnd {
                    let baseHours: Double
                    switch bar.segmentType.lowercased() {
                    case "prep": baseHours = 8
                    case "base": baseHours = 10
                    case "build": baseHours = 12
                    case "race": baseHours = week == bar.weekEnd ? 6 : 10 // Taper
                    default: baseHours = 8
                    }
                    // Ajoute un peu de variation
                    let variation = Double.random(in: -1...1)
                    data.append(WeeklyVolumeData(week: week, hours: baseHours + variation, phase: bar.segmentType))
                }
            }
        }

        return data
    }
}

// MARK: - Supporting Types

private struct WeeklyVolumeData {
    let week: Int
    let hours: Double
    let phase: String
}

// MARK: - Stat Card

private struct StatCard: View {
    @EnvironmentObject var themeManager: ThemeManager

    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: ECSpacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.ecH2)
                .foregroundColor(themeManager.textPrimary)

            Text(title)
                .font(.ecCaption)
                .foregroundColor(themeManager.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MacroPlanDetailView(plan: MacroPlanData.mock)
            .environmentObject(ThemeManager.shared)
    }
}
