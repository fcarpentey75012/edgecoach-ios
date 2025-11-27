/**
 * Carte État de Forme
 * Affiche la charge d'entraînement (CTL/ATL/TSB)
 */

import SwiftUI

struct TrainingLoadCard: View {
    let load: TrainingLoad

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            // Header
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundColor(load.status.color)
                Text("État de forme")
                    .font(.ecLabelBold)
                    .foregroundColor(.ecSecondary800)
                Spacer()
                
                // Badge TSB
                if let tsb = load.tsb {
                    Text(tsb > 0 ? "+\(Int(tsb))" : "\(Int(tsb))")
                        .font(.ecH4)
                        .foregroundColor(load.status.color)
                }
            }

            // Jauge visuelle simplifiée
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.ecGray200)
                        .frame(height: 8)
                    
                    // Position du marqueur (centré sur le 0, scale de -50 à +50)
                    if let tsb = load.tsb {
                        let width = geo.size.width
                        // Normalisation: -50 -> 0, 0 -> 0.5, +50 -> 1.0
                        let normalized = min(max((tsb + 50) / 100, 0), 1)
                        
                        Circle()
                            .fill(load.status.color)
                            .frame(width: 12, height: 12)
                            .position(x: width * normalized, y: 4)
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    }
                }
            }
            .frame(height: 12)

            // Status Text
            VStack(alignment: .leading, spacing: 4) {
                Text(load.status.title)
                    .font(.ecBodyBold)
                    .foregroundColor(load.status.color)
                
                Text(load.status.description)
                    .font(.ecCaption)
                    .foregroundColor(.ecGray500)
                    .lineLimit(2)
            }

            Divider()

            // Metrics Grid (Fitness vs Fatigue)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CONDITION (CTL)")
                        .font(.ecSmall)
                        .foregroundColor(.ecGray500)
                    Text("\(Int(load.ctl ?? 0))")
                        .font(.ecH3)
                        .foregroundColor(.ecSecondary800)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("FATIGUE (ATL)")
                        .font(.ecSmall)
                        .foregroundColor(.ecGray500)
                    Text("\(Int(load.atl ?? 0))")
                        .font(.ecH3)
                        .foregroundColor(.ecSecondary800)
                }
            }
        }
        .ecCard()
    }
}

#Preview {
    VStack {
        TrainingLoadCard(load: TrainingLoad(
            ctl: 42.5,
            atl: 55.0,
            tsb: -12.5,
            last7dTss: 350,
            last42dTss: 1800
        ))
        .padding()
        
        TrainingLoadCard(load: TrainingLoad(
            ctl: 60.0,
            atl: 40.0,
            tsb: 20.0,
            last7dTss: 200,
            last42dTss: 2500
        ))
        .padding()
    }
    .background(Color.ecBackground)
}
