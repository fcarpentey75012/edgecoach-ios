//
//  EdgeCoachWidget.swift
//  EdgeCoachWidget
//
//  Created for EdgeCoach iOS.
//

import WidgetKit
import SwiftUI
import ActivityKit

// MARK: - 1. Attributes (Model)
// Définit les données dynamiques et statiques de l'activité

struct WorkoutAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Données qui changent en temps réel (Dynamique)
        var remainingTime: String
        var currentZone: Int
        var progress: Double
    }

    // Données fixes au lancement de l'activité
    var workoutName: String
    var workoutType: String // "Run", "Bike", "Swim"
    var startTime: Date
}

// MARK: - 2. Widget View
// L'interface de la Live Activity et de la Dynamic Island

struct EdgeCoachWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutAttributes.self) { context in
            // 📱 LOCK SCREEN PRESENTATION
            VStack(spacing: 0) {
                HStack {
                    // Icone Sport
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon(for: context.attributes.workoutType))
                            .foregroundColor(.accentColor)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(context.attributes.workoutName)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(context.state.remainingTime) restante")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Progress Ring
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: context.state.progress)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 30, height: 30)
                }
                .padding()
            }
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            // 🏝️ DYNAMIC ISLAND PRESENTATION
            DynamicIsland {
                // Expanded View (Appui long)
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.remainingTime, systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Label {
                        Text("Zone \(context.state.currentZone)")
                    } icon: {
                        Image(systemName: "waveform.path.ecg")
                    }
                    .foregroundColor(.red)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(.accentColor)
                        .padding(.horizontal)
                }
            } compactLeading: {
                // Petite vue gauche
                Image(systemName: icon(for: context.attributes.workoutType))
                    .foregroundColor(.accentColor)
            } compactTrailing: {
                // Petite vue droite
                Text(context.state.remainingTime)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(.white)
            } minimal: {
                // Vue minimale (quand plusieurs apps utilisent l'île)
                Image(systemName: "timer")
                    .foregroundColor(.accentColor)
            }
            .widgetURL(URL(string: "edgecoach://workout/current"))
            .keylineTint(Color.accentColor)
        }
    }
    
    func icon(for type: String) -> String {
        switch type {
        case "Run": return "figure.run"
        case "Bike": return "figure.outdoor.cycle"
        case "Swim": return "figure.pool.swim"
        default: return "figure.mixed.cardio"
        }
    }
}

// Pour preview SwiftUI (Xcode 15+)
#Preview("Lock Screen", as: .content, using: WorkoutAttributes(workoutName: "Sortie Longue", workoutType: "Bike", startTime: Date())) {
   EdgeCoachWidgetLiveActivity()
} contentStates: {
    WorkoutAttributes.ContentState(remainingTime: "45:00", currentZone: 2, progress: 0.3)
}
