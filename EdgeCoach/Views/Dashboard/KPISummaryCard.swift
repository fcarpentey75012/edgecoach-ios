/**
 * KPI Summary Card - Card regroupant les métriques de volume
 * Avec sélecteur de temporalité intégré et menu contextuel de personnalisation
 */

import SwiftUI

// MARK: - KPI Summary Card

struct KPISummaryCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var timeScope: DashboardTimeScope
    @Binding var selectedMetrics: [KPIMetricType]
    let summary: WeeklySummary?

    // Colonnes adaptatives selon le nombre de métriques
    private var columns: [GridItem] {
        let count = selectedMetrics.count
        if count <= 2 {
            return [GridItem(.flexible()), GridItem(.flexible())]
        } else if count <= 3 {
            return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        } else {
            return [GridItem(.flexible()), GridItem(.flexible())]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header avec titre et picker de temporalité
            headerView
                .padding(.horizontal, ECSpacing.md)
                .padding(.top, ECSpacing.md)
                .padding(.bottom, ECSpacing.sm)

            Divider()
                .padding(.horizontal, ECSpacing.md)

            // Grid des KPIs
            if let summary = summary, !selectedMetrics.isEmpty {
                LazyVGrid(columns: columns, spacing: ECSpacing.sm) {
                    ForEach(Array(selectedMetrics.enumerated()), id: \.element.id) { index, metric in
                        KPIMetricItem(
                            metric: metric,
                            value: value(for: metric, summary: summary)
                        )
                        .staggeredAnimation(index: index, totalCount: selectedMetrics.count)
                    }
                }
                .padding(ECSpacing.md)
            } else if selectedMetrics.isEmpty {
                emptyStateView
                    .padding(ECSpacing.md)
            } else {
                loadingView
                    .padding(ECSpacing.md)
            }
        }
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: themeManager.cardBorderWidth)
        )
        .shadow(color: themeManager.cardShadow, radius: themeManager.cardShadowRadius, x: 0, y: 2)
        .contextMenu {
            metricsContextMenu
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.accentColor)
                Text("Résumé")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            Spacer()

            // Picker de temporalité compact
            Picker("", selection: $timeScope) {
                Text("S").tag(DashboardTimeScope.week)
                Text("M").tag(DashboardTimeScope.month)
                Text("A").tag(DashboardTimeScope.year)
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: ECSpacing.sm) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 24))
                .foregroundColor(themeManager.textTertiary)
            Text("Aucune métrique sélectionnée")
                .font(.ecCaption)
                .foregroundColor(themeManager.textSecondary)
            Text("Maintenez appuyé pour configurer")
                .font(.ecSmall)
                .foregroundColor(themeManager.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ECSpacing.md)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Spacer()
        }
        .padding(.vertical, ECSpacing.lg)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var metricsContextMenu: some View {
        Text("Métriques affichées")
            .font(.headline)

        ForEach(KPIMetricType.allCases) { metric in
            Button {
                toggleMetric(metric)
            } label: {
                Label {
                    Text(metric.rawValue)
                } icon: {
                    Image(systemName: selectedMetrics.contains(metric) ? "checkmark.circle.fill" : "circle")
                }
            }
        }
    }

    // MARK: - Helpers

    private func toggleMetric(_ metric: KPIMetricType) {
        if let index = selectedMetrics.firstIndex(of: metric) {
            selectedMetrics.remove(at: index)
        } else {
            selectedMetrics.append(metric)
        }
    }

    private func value(for metric: KPIMetricType, summary: WeeklySummary) -> String {
        switch metric {
        case .volume:
            return summary.formattedDuration
        case .distance:
            return summary.formattedDistance
        case .sessions:
            return "\(summary.sessionsCount)"
        case .elevation:
            return "\(summary.totalElevation) m"
        case .calories:
            return "\(summary.totalCalories)"
        }
    }
}

// MARK: - KPI Metric Item

struct KPIMetricItem: View {
    @EnvironmentObject var themeManager: ThemeManager
    let metric: KPIMetricType
    let value: String

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: metric.icon)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.accentColor)

                if !metric.unit.isEmpty {
                    Text(metric.unit)
                        .font(.system(size: 10))
                        .foregroundColor(themeManager.textTertiary)
                }
            }

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(metric.rawValue)
                .font(.ecSmall)
                .foregroundColor(themeManager.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ECSpacing.sm)
        .background(themeManager.elevatedColor.opacity(0.5))
        .cornerRadius(ECRadius.md)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        KPISummaryCard(
            timeScope: .constant(.week),
            selectedMetrics: .constant([KPIMetricType.volume, KPIMetricType.distance, KPIMetricType.sessions]),
            summary: WeeklySummary(
                totalDuration: 18000,
                totalDistance: 85000,
                sessionsCount: 5,
                totalElevation: 1250,
                totalCalories: 2340
            )
        )
        .padding()
    }
    .background(Color.gray.opacity(0.1))
    .environmentObject(ThemeManager.shared)
}
