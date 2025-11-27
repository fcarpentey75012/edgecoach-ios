/**
 * Module natif SwiftUI Charts pour EdgeCoach
 * Fournit des graphiques natifs iOS 16+ à React Native
 */

import Foundation
import React
import SwiftUI
import Charts

// MARK: - Structures de données

/// Point de données pour les graphiques linéaires
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
}

/// Zone de données pour les graphiques de répartition
struct ZoneData: Identifiable {
    let id = UUID()
    let zone: Int
    let percentage: Double
    let timeSeconds: Int
    let color: Color
}

// MARK: - Couleurs EdgeCoach

struct EdgeCoachColors {
    static let primary = Color(red: 59/255, green: 130/255, blue: 246/255)      // #3B82F6
    static let cycling = Color(red: 168/255, green: 85/255, blue: 247/255)      // #A855F7
    static let running = Color(red: 34/255, green: 197/255, blue: 94/255)       // #22C55E
    static let swimming = Color(red: 6/255, green: 182/255, blue: 212/255)      // #06B6D4
    static let heartRate = Color(red: 239/255, green: 68/255, blue: 68/255)     // #EF4444
    static let power = Color(red: 245/255, green: 158/255, blue: 11/255)        // #F59E0B

    // Zones FC/Puissance
    static let zones: [Color] = [
        Color(red: 148/255, green: 163/255, blue: 184/255),  // Z1 - Récup (gris)
        Color(red: 34/255, green: 197/255, blue: 94/255),    // Z2 - Endurance (vert)
        Color(red: 132/255, green: 204/255, blue: 22/255),   // Z3 - Tempo (vert-jaune)
        Color(red: 234/255, green: 179/255, blue: 8/255),    // Z4 - Seuil (jaune)
        Color(red: 249/255, green: 115/255, blue: 22/255),   // Z5 - VO2max (orange)
        Color(red: 239/255, green: 68/255, blue: 68/255),    // Z6 - Anaérobie (rouge)
        Color(red: 220/255, green: 38/255, blue: 38/255),    // Z7 - Neuromuscular (rouge foncé)
    ]

    static func zoneColor(for zone: Int) -> Color {
        let index = max(0, min(zone - 1, zones.count - 1))
        return zones[index]
    }
}

// MARK: - SwiftUI Line Chart View

@available(iOS 16.0, *)
struct NativeLineChartView: View {
    let data: [ChartDataPoint]
    let color: Color
    let showGradient: Bool
    let height: CGFloat
    let showInteraction: Bool

    @State private var selectedPoint: ChartDataPoint?

    var body: some View {
        VStack(spacing: 0) {
            Chart(data) { point in
                // Area avec gradient
                if showGradient {
                    AreaMark(
                        x: .value("Index", point.index),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.4), color.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                // Ligne principale
                LineMark(
                    x: .value("Index", point.index),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)

                // Point sélectionné
                if showInteraction, let selected = selectedPoint, selected.id == point.id {
                    PointMark(
                        x: .value("Index", point.index),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(color)
                    .symbolSize(100)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .frame(height: height)
            .if(showInteraction) { view in
                view.chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let x = value.location.x
                                        if let index: Int = proxy.value(atX: x) {
                                            selectedPoint = data.first { $0.index == index }
                                        }
                                    }
                                    .onEnded { _ in
                                        selectedPoint = nil
                                    }
                            )
                    }
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - SwiftUI Zones Bar Chart

@available(iOS 16.0, *)
struct NativeZonesChartView: View {
    let zones: [ZoneData]
    let showLabels: Bool

    var body: some View {
        VStack(spacing: 8) {
            ForEach(zones) { zone in
                HStack(spacing: 8) {
                    // Label zone
                    HStack(spacing: 4) {
                        Circle()
                            .fill(zone.color)
                            .frame(width: 8, height: 8)
                        Text("Z\(zone.zone)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 45, alignment: .leading)

                    // Barre
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(zone.color)
                                .frame(width: geometry.size.width * CGFloat(zone.percentage / 100))
                        }
                    }
                    .frame(height: 20)

                    // Pourcentage
                    Text("\(Int(zone.percentage))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(width: 35, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - SwiftUI Pie Chart (Donut) pour zones FC

@available(iOS 16.0, *)
struct NativeDonutChartView: View {
    let zones: [ZoneData]
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    var body: some View {
        Chart(zones) { zone in
            SectorMark(
                angle: .value("Pourcentage", zone.percentage),
                innerRadius: .ratio(innerRadius),
                outerRadius: .ratio(outerRadius)
            )
            .foregroundStyle(zone.color)
        }
        .chartLegend(.hidden)
    }
}

// MARK: - Bar Chart pour les laps

@available(iOS 16.0, *)
struct NativeBarChartView: View {
    let data: [ChartDataPoint]
    let color: Color
    let avgValue: Double?
    let height: CGFloat

    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Lap", point.index + 1),
                y: .value("Value", point.value)
            )
            .foregroundStyle(barColor(for: point.value))
            .cornerRadius(4)

            // Ligne moyenne
            if let avg = avgValue {
                RuleMark(y: .value("Moyenne", avg))
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartYAxis(.hidden)
        .frame(height: height)
        .background(Color.white)
    }

    private func barColor(for value: Double) -> Color {
        guard let avg = avgValue else { return color }
        if value < avg * 0.95 {
            return EdgeCoachColors.running  // Vert - meilleur
        } else if value > avg * 1.05 {
            return Color.red  // Rouge - moins bon
        }
        return color
    }
}

// MARK: - View Extension pour conditionals

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
