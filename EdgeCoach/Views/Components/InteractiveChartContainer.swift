import SwiftUI
import Charts

/// Conteneur générique pour rendre n'importe quel graphique interactif
/// Gère la sélection tactile (DragGesture) et l'affichage de la règle verticale
struct InteractiveChartContainer<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @Binding var selectedTime: Double? // Temps sélectionné (synchronisé entre graphiques)
    let dataPoints: [ChartDataService.DataPoint]
    let content: () -> Content
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var localSelection: Double? // Pour l'interaction locale si pas de binding externe
    
    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            // Header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                
                Spacer()
                
                // Affichage de la valeur sélectionnée
                if let time = selectedTime ?? localSelection,
                   let point = findPoint(at: time) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(formatValue(point.value))")
                            .font(.ecBodyBold)
                            .foregroundColor(themeManager.textPrimary)
                        Text(formatTime(point.elapsedSeconds))
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(themeManager.elevatedColor)
                    .cornerRadius(4)
                }
            }
            
            // Graphique interactif
            ZStack {
                content()
                    .chartOverlay { proxy in
                        GeometryReader { geometry in
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let x = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                            if let date: Date = proxy.value(atX: x) {
                                                // Convertir Date en elapsed seconds
                                                if let start = dataPoints.first?.timestamp {
                                                    let elapsed = date.timeIntervalSince(start)
                                                    selectedTime = elapsed
                                                    localSelection = elapsed
                                                }
                                            }
                                        }
                                        .onEnded { _ in
                                            // On peut choisir de garder la sélection ou l'effacer
                                            // selectedTime = nil 
                                            // localSelection = nil
                                        }
                                )
                        }
                    }
                
                // Règle verticale (Rule Mark)
                if let time = selectedTime ?? localSelection,
                   let start = dataPoints.first?.timestamp {
                    // Note: Idéalement ceci est fait dans le Chart via RuleMark, 
                    // mais ici on le simule par dessus si le content ne le gère pas.
                    // Pour une meilleure intégration, le Content doit gérer le RuleMark.
                    // Ici on ne fait rien de plus visuellement, on laisse le ChartContent gérer le RuleMark
                    // grâce à selectedTime passé en paramètre du Content.
                }
            }
        }
        .themedCard()
    }
    
    private func findPoint(at elapsed: Double) -> ChartDataService.DataPoint? {
        // Recherche binaire ou linéaire simple (les points sont triés par temps)
        return dataPoints.min(by: { abs($0.elapsedSeconds - elapsed) < abs($1.elapsedSeconds - elapsed) })
    }
    
    private func formatValue(_ value: Double) -> String {
        if value >= 100 { return String(format: "%.0f", value) }
        return String(format: "%.1f", value)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 { return String(format: "%dh%02d", h, m) }
        return String(format: "%02d:%02d", m, s)
    }
}
