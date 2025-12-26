/**
 * MacroPlanDetailView - Interface Storyline Verticale du Plan de Saison
 * Focus sur la narration du parcours et les détails techniques par phase.
 */

import SwiftUI
import Charts

struct MacroPlanDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    let plan: MacroPlanData
    
    @State private var selectedPhase: VisualBar?
    
    // Calcul de la semaine actuelle (simulation pour la démo ou calcul réel)
    private var currentWeek: Int {
        guard let startStr = plan.startDate, let startDate = parseDate(startStr) else { return 1 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: startDate, to: Date())
        let week = (components.weekOfYear ?? 0) + 1
        return max(1, week)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // 1. Header Résumé
                    headerView
                        .padding(.bottom, 20)
                    
                    // 2. La Storyline
                    ZStack(alignment: .leading) {
                        // Ligne de vie
                        Rectangle()
                            .fill(themeManager.borderColor)
                            .frame(width: 2)
                            .padding(.leading, 34)
                            .padding(.vertical, 20)
                        
                        VStack(spacing: 0) {
                            if let bars = plan.visualBars {
                                ForEach(Array(bars.enumerated()), id: \.element.id) { index, bar in
                                    TimelineItemRow(
                                        bar: bar,
                                        isLast: index == bars.count - 1,
                                        isCurrent: isCurrentPhase(bar),
                                        themeManager: themeManager,
                                        onTap: { selectedPhase = bar }
                                    )
                                    .id(bar.id)
                                }
                            }
                            
                            // Fin
                            HStack(alignment: .top, spacing: 16) {
                                Circle()
                                    .fill(themeManager.textTertiary)
                                    .frame(width: 12, height: 12)
                                    .padding(14)
                                    .background(themeManager.backgroundColor)
                                
                                Text("Fin de saison")
                                    .font(.ecCaption)
                                    .foregroundColor(themeManager.textTertiary)
                                    .padding(.top, 12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle(plan.name ?? "Plan de saison")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Auto-scroll vers aujourd'hui
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let currentPhase = plan.visualBars?.first(where: { isCurrentPhase($0) }) {
                        withAnimation {
                            proxy.scrollTo(currentPhase.id, anchor: .center)
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedPhase) { phase in
            PhaseDetailView(phase: phase, plan: plan)
                .environmentObject(themeManager)
        }
    }
    
    // MARK: - Components
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let mainObj = plan.objectives?.first(where: { $0.priority == .principal }) {
                    Text("Objectif Principal")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                    Text(mainObj.name)
                        .font(.ecH3)
                        .foregroundColor(themeManager.textPrimary)
                    Text(countdownString(to: mainObj.targetDate))
                        .font(.ecBodyMedium)
                        .foregroundColor(themeManager.accentColor)
                } else {
                    Text(plan.name ?? "Saison")
                        .font(.ecH3)
                        .foregroundColor(themeManager.textPrimary)
                }
            }
            Spacer()
            
            CircularProgress(progress: calculateProgress())
                .frame(width: 60, height: 60)
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Helpers
    
    private func isCurrentPhase(_ bar: VisualBar) -> Bool {
        return bar.weekStart <= currentWeek && bar.weekEnd >= currentWeek
    }
    
    private func countdownString(to dateStr: String) -> String {
        guard let date = parseDate(dateStr) else { return dateStr }
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if diff < 0 { return "Terminé" }
        if diff == 0 { return "Aujourd'hui !" }
        return "J-\(diff)"
    }
    
    private func calculateProgress() -> Double {
        guard let bars = plan.visualBars, let last = bars.last else { return 0 }
        return Double(currentWeek) / Double(last.weekEnd)
    }
    
    private func parseDate(_ str: String) -> Date? {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.date(from: str)
    }
}

// MARK: - Timeline Components

private struct TimelineItemRow: View {
    let bar: VisualBar
    let isLast: Bool
    let isCurrent: Bool
    let themeManager: ThemeManager
    let onTap: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                ZStack {
                    if bar.segmentType.lowercased() == "race" {
                        Circle().fill(themeManager.warningColor).frame(width: 40, height: 40)
                            .shadow(color: themeManager.warningColor.opacity(0.4), radius: 6)
                        Image(systemName: "trophy.fill").foregroundColor(.white).font(.system(size: 18))
                    } else if bar.segmentType.lowercased().contains("recovery") {
                        Circle().fill(themeManager.backgroundColor).frame(width: 32, height: 32)
                            .overlay(Circle().stroke(themeManager.successColor, lineWidth: 2))
                        Image(systemName: "leaf.fill").foregroundColor(themeManager.successColor).font(.system(size: 14))
                    } else {
                        Circle().fill(isCurrent ? themeManager.accentColor : themeManager.cardColor).frame(width: 40, height: 40)
                            .overlay(Circle().stroke(colorFor(bar.segmentType), lineWidth: isCurrent ? 0 : 3))
                        if isCurrent { Image(systemName: "mappin").foregroundColor(.white).font(.system(size: 14, weight: .bold)) }
                        else { Text("S\(bar.weekStart)").font(.system(size: 10, weight: .bold)).foregroundColor(themeManager.textSecondary) }
                    }
                }
                .background(themeManager.backgroundColor).zIndex(1)
                Color.clear.frame(width: 40, height: bar.segmentType.lowercased() == "race" ? 60 : 100)
            }
            
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if isCurrent { Text("ACTUEL").font(.system(size: 9, weight: .bold)).foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(themeManager.accentColor)) }
                        Text("Semaines \(bar.weekStart) - \(bar.weekEnd)").font(.ecCaption).foregroundColor(isCurrent ? themeManager.accentColor : themeManager.textTertiary)
                        Spacer()
                        Text("\(bar.durationWeeks) s.").font(.ecCaptionBold).foregroundColor(themeManager.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(bar.subplanName).font(.ecH4).foregroundColor(themeManager.textPrimary).multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(themeManager.textTertiary)
                        }
                        
                        if bar.segmentType.lowercased() == "race" {
                            Label("Jour de compétition", systemImage: "flag.checkered").font(.ecCaption).foregroundColor(themeManager.warningColor)
                        } else {
                            HStack(spacing: 12) {
                                Label("Volume", systemImage: "chart.bar.fill")
                                Label("Intensité", systemImage: "heart.fill")
                            }
                            .font(.system(size: 9, weight: .medium)).foregroundColor(themeManager.textSecondary)
                        }
                    }
                    .padding()
                    .background(themeManager.cardColor)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(isCurrent ? themeManager.accentColor : themeManager.borderColor, lineWidth: isCurrent ? 2 : 1))
                    .shadow(color: isCurrent ? themeManager.accentColor.opacity(0.1) : .clear, radius: 10)
                }
                .padding(.bottom, 24)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func colorFor(_ type: String) -> Color {
        switch type.lowercased() {
        case "foundation", "prep": return .blue
        case "base": return .indigo
        case "specific", "build": return .orange
        case "race": return themeManager.accentColor
        case "transition", "recovery": return .green
        default: return .gray
        }
    }
}

// MARK: - Phase Detail View (Les outils techniques)

private struct PhaseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    let phase: VisualBar
    let plan: MacroPlanData

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.xl) {
                    // 1. Header & Dates
                    headerSection
                    
                    // 2. Description
                    descriptionSection
                    
                    // 3. Répartition Sport & Intensité (Les outils)
                    intensityDistributionSection
                    sportDistributionSection
                    
                    // 4. Volume Hebdo
                    volumeSection
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle(phase.subplanName)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Fermer") { dismiss() } } }
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(colorFor(phase.segmentType).opacity(0.1)).frame(width: 60, height: 60)
                Text(phaseIcon).font(.system(size: 30))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(phase.segmentType.uppercased()).font(.ecCaptionBold).foregroundColor(colorFor(phase.segmentType))
                Text("Semaines \(phase.weekStart) à \(phase.weekEnd)").font(.ecBody).foregroundColor(themeManager.textSecondary)
            }
            Spacer()
        }
        .padding()
        .background(themeManager.cardColor).cornerRadius(16)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Focus de la phase").font(.ecH4).foregroundColor(themeManager.textPrimary)
            Text(descriptionFor(phase.segmentType))
                .font(.ecBody).foregroundColor(themeManager.textSecondary)
                .padding().frame(maxWidth: .infinity, alignment: .leading)
                .background(themeManager.cardColor).cornerRadius(12)
        }
    }

    private var intensityDistributionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Intensité", systemImage: "heart.fill").font(.ecH4)
            
            HStack(spacing: 4) {
                distributionBar(color: .green, ratio: 0.7, label: "Z1-Z2")
                distributionBar(color: .orange, ratio: 0.2, label: "Z3")
                distributionBar(color: .red, ratio: 0.1, label: "Z4+")
            }
            .frame(height: 40)
        }
    }
    
    private var sportDistributionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Répartition Sport", systemImage: "figure.run").font(.ecH4)
            
            VStack(spacing: 8) {
                sportRow(name: "Natation", ratio: 0.2, color: .ecSwimming)
                sportRow(name: "Vélo", ratio: 0.5, color: .ecCycling)
                sportRow(name: "Course", ratio: 0.3, color: .ecRunning)
            }
            .padding().background(themeManager.cardColor).cornerRadius(12)
        }
    }
    
    private var volumeSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Volume cible").font(.ecCaption).foregroundColor(themeManager.textSecondary)
                Text("12h30 / sem.").font(.ecH3).foregroundColor(themeManager.textPrimary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("Séances").font(.ecCaption).foregroundColor(themeManager.textSecondary)
                Text("6 séances").font(.ecH3).foregroundColor(themeManager.textPrimary)
            }
        }
        .padding().background(themeManager.cardColor).cornerRadius(12)
    }

    // MARK: - Small Helpers
    
    private func distributionBar(color: Color, ratio: Double, label: String) -> some View {
        VStack(spacing: 4) {
            Rectangle().fill(color.gradient).cornerRadius(4)
            Text(label).font(.system(size: 8)).foregroundColor(themeManager.textSecondary)
        }
    }
    
    private func sportRow(name: String, ratio: Double, color: Color) -> some View {
        HStack {
            Text(name).font(.ecCaption).frame(width: 60, alignment: .leading)
            GeometryReader { g in
                RoundedRectangle(cornerRadius: 2).fill(color.gradient).frame(width: g.size.width * ratio)
            }.frame(height: 6)
            Text("\(Int(ratio * 100))%").font(.system(size: 10, weight: .bold)).frame(width: 30)
        }
    }

    private var phaseIcon: String {
        let t = phase.segmentType.lowercased()
        if t == "race" { return "🏁" }
        if t.contains("recovery") { return "🍃" }
        if t.contains("build") || t.contains("specific") { return "🎯" }
        return "🏗️"
    }

    private func colorFor(_ type: String) -> Color {
        let t = type.lowercased()
        if t == "race" { return themeManager.accentColor }
        if t.contains("recovery") { return .green }
        if t.contains("build") || t.contains("specific") { return .orange }
        return .blue
    }
    
    private func descriptionFor(_ type: String) -> String {
        let t = type.lowercased()
        if t == "race" { return "Phase d'affûtage final. On réduit le volume pour maximiser la fraîcheur tout en gardant un peu d'intensité." }
        if t.contains("recovery") { return "Récupération active. On laisse le corps assimiler la charge de travail des semaines précédentes." }
        if t.contains("build") || t.contains("specific") { return "Travail spécifique aux allures de course. On augmente l'exigence des séances clés." }
        return "Construction des bases. On privilégie le volume à basse intensité et le renforcement technique."
    }
}

// MARK: - Circular Progress

private struct CircularProgress: View {
    let progress: Double
    var body: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.1), lineWidth: 6)
            Circle().trim(from: 0, to: progress).stroke(Color.orange.gradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(Int(progress * 100))%").font(.system(size: 12, weight: .bold))
                Text("FAIT").font(.system(size: 7)).foregroundColor(.gray)
            }
        }
    }
}

private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity; var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}