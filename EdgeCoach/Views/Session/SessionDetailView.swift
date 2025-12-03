/**
 * Vue Détail Session - Affichage détaillé d'une activité
 * Utilise ThemeManager pour les couleurs dynamiques
 */

import SwiftUI
import Charts

struct SessionDetailView: View {
    let activity: Activity
    @Environment(\.dismiss) private var dismissView
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: SessionTab = .resume
    @State private var showingAnalysisSheet = false
    @State private var preferences = SessionDisplayPreferences.default

    // Position du bouton flottant (draggable)
    @State private var buttonPosition: CGPoint = .zero
    @State private var isDragging = false
    @State private var dragStartPosition: CGPoint = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollView {
                    VStack(spacing: ECSpacing.lg) {
                        // Header with main stats
                        SessionHeaderCard(activity: activity)

                        // Tab Selector
                        SessionTabSelector(selectedTab: $selectedTab)

                        // Content based on tab
                        switch selectedTab {
                        case .resume:
                            SessionResumeContent(activity: activity, preferences: preferences)
                        case .charts:
                            SessionChartsContent(activity: activity, preferences: preferences)
                        case .laps:
                            SessionLapsContent(activity: activity)
                        case .logbook:
                            SessionLogbookContent(activity: activity)
                        case .map:
                            SessionMapContent(activity: activity, preferences: preferences)
                        }
                    }
                    .padding()
                    .padding(.bottom, 80)
                }

                // Bouton flottant Coach IA (draggable)
                coachFloatingButton(in: geometry)
            }
        }
        .background(themeManager.backgroundColor)
        .navigationTitle(activity.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPreferences()
        }
        .sheet(isPresented: $showingAnalysisSheet) {
            SessionAnalysisSheet(
                context: sessionContext,
                onNavigateToChat: {
                    dismissView()
                }
            )
            .environmentObject(appState)
            .environmentObject(authViewModel)
            .environmentObject(themeManager)
        }
    }

    // MARK: - Coach Floating Button (Draggable)

    private func coachFloatingButton(in geometry: GeometryProxy) -> some View {
        let buttonSize: CGFloat = 44
        let padding: CGFloat = ECSpacing.lg

        // Position par défaut (bas droite)
        let defaultPosition = CGPoint(
            x: geometry.size.width - buttonSize - padding,
            y: geometry.size.height - buttonSize - padding - geometry.safeAreaInsets.bottom
        )

        // Initialiser la position si nécessaire
        let currentPosition = buttonPosition == .zero ? defaultPosition : buttonPosition

        return Image(systemName: "bubble.left.and.text.bubble.right.fill")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: buttonSize, height: buttonSize)
            .background(themeManager.accentColor)
            .clipShape(Circle())
            .shadow(color: themeManager.accentColor.opacity(isDragging ? 0.5 : 0.25), radius: isDragging ? 8 : 4, x: 0, y: 2)
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .opacity(isDragging ? 1.0 : 0.7)
            .position(currentPosition)
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            dragStartPosition = buttonPosition == .zero ? defaultPosition : buttonPosition
                        }

                        // Calculer la nouvelle position directement
                        var newX = dragStartPosition.x + value.translation.width
                        var newY = dragStartPosition.y + value.translation.height

                        // Contraindre dans les limites
                        let minX = buttonSize / 2 + padding
                        let maxX = geometry.size.width - buttonSize / 2 - padding
                        let minY = buttonSize / 2 + padding + geometry.safeAreaInsets.top
                        let maxY = geometry.size.height - buttonSize / 2 - padding - geometry.safeAreaInsets.bottom

                        newX = max(minX, min(maxX, newX))
                        newY = max(minY, min(maxY, newY))

                        buttonPosition = CGPoint(x: newX, y: newY)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .onTapGesture {
                if !isDragging {
                    showingAnalysisSheet = true
                }
            }
            .animation(.easeOut(duration: 0.15), value: isDragging)
    }

    // MARK: - Session Context

    private var sessionContext: SessionContext {
        SessionContext(
            sessionName: activity.displayTitle,
            sessionDate: activity.date ?? Date(),
            discipline: activity.discipline,
            duration: activity.fileDatas?.duration,
            distance: activity.preferredDistance.map { $0 * 1000 }, // Convertir km en mètres
            isCompleted: true
        )
    }

    private func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: "sessionDisplayPreferences"),
           let decoded = try? JSONDecoder().decode(SessionDisplayPreferences.self, from: data) {
            preferences = decoded
            if preferences.sectionsOrder.isEmpty {
                preferences.sectionsOrder = SessionSectionType.allCases
            }
        }
    }
}

enum SessionTab: String, CaseIterable {
    case resume = "Résumé"
    case charts = "Graphiques"
    case laps = "Intervalles"
    case logbook = "Carnet"
    case map = "Carte"
}

// MARK: - Session Header Card

struct SessionHeaderCard: View {
    let activity: Activity
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let sportColor = themeManager.sportColor(for: activity.discipline)

        VStack(spacing: ECSpacing.md) {
            // Discipline & Date
            HStack {
                ZStack {
                    Circle()
                        .fill(sportColor.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: activity.discipline.icon)
                        .font(.system(size: 22))
                        .foregroundColor(sportColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.discipline.displayName)
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)

                    if let date = activity.date {
                        Text(formatDate(date))
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }

                Spacer()

                if let tss = activity.tss {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(tss)")
                            .font(.ecH3)
                            .foregroundColor(themeManager.textPrimary)
                        Text("TSS")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }
            }

            Divider()

            // Main Stats
            HStack(spacing: 0) {
                if let duration = activity.formattedDuration {
                    MainStatItem(value: duration, label: "Durée", icon: "clock")
                }

                if let distance = activity.formattedDistance {
                    MainStatItem(value: distance, label: "Distance", icon: "arrow.left.and.right")
                }

                if let avgSpeed = activity.formattedAvgSpeed {
                    MainStatItem(value: avgSpeed, label: "Vit. moy", icon: "speedometer")
                }
            }

            // Secondary Stats
            HStack(spacing: 0) {
                if let avgHr = activity.fileDatas?.hrAvg {
                    MainStatItem(value: "\(Int(avgHr)) bpm", label: "FC moy", icon: "heart")
                }

                if let avgPower = activity.formattedAvgPower {
                    MainStatItem(value: avgPower, label: "Puiss. moy", icon: "bolt")
                }

                if let elevation = activity.preferredElevationGain {
                    MainStatItem(value: "\(Int(elevation)) m", label: "D+", icon: "arrow.up.right")
                }
            }
        }
        .themedCard()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date).capitalized
    }
}

struct MainStatItem: View {
    let value: String
    let label: String
    let icon: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textTertiary)
                Text(value)
                    .font(.ecBodyMedium)
                    .foregroundColor(themeManager.textPrimary)
            }
            Text(label)
                .font(.ecSmall)
                .foregroundColor(themeManager.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tab Selector

struct SessionTabSelector: View {
    @Binding var selectedTab: SessionTab
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: ECSpacing.xs) {
            ForEach(SessionTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.ecCaption)
                        .foregroundColor(selectedTab == tab ? .white : themeManager.textPrimary)
                        .padding(.horizontal, ECSpacing.md)
                        .padding(.vertical, ECSpacing.sm)
                        .background(
                            selectedTab == tab ? themeManager.accentColor : Color.clear
                        )
                        .cornerRadius(ECRadius.md)
                }
            }
        }
        .padding(ECSpacing.xs)
        .background(themeManager.elevatedColor)
        .cornerRadius(ECRadius.lg)
    }
}

// MARK: - Resume Content (Garmin/Wahoo Style)

struct SessionResumeContent: View {
    let activity: Activity
    let preferences: SessionDisplayPreferences

    var body: some View {
        VStack(spacing: ECSpacing.md) {
            ForEach(preferences.sectionsOrder) { section in
                sectionView(for: section)
            }
        }
    }
    
    @ViewBuilder
    private func sectionView(for section: SessionSectionType) -> some View {
        switch section {
        case .summary:
            QuickSummarySection(activity: activity, preferences: preferences)
        case .power:
            if hasPowerData { PowerMetricsSection(activity: activity, preferences: preferences) }
        case .speed:
            if hasSpeedData { SpeedPaceSection(activity: activity, preferences: preferences) }
        case .heartRate:
            if hasCardioData { CardioSection(activity: activity, preferences: preferences) }
        case .zones:
            if let zones = activity.zones, !zones.isEmpty { ZonesCard(zones: zones) }
        case .elevation:
            if hasElevationData { ElevationSection(activity: activity, preferences: preferences) }
        case .cadence:
            if hasCadenceData { CadenceSection(activity: activity, preferences: preferences) }
        case .performance:
            if hasPerformanceData { PerformanceSection(activity: activity, preferences: preferences) }
        case .notes:
            if let notes = activity.notes, !notes.isEmpty { NotesCard(notes: notes) }
        }
    }

    // MARK: - Data Availability Checks

    private var hasPowerData: Bool {
        activity.preferredAvgPower != nil || activity.preferredMaxPower != nil || activity.preferredNP != nil
    }

    private var hasSpeedData: Bool {
        activity.fileDatas?.avgSpeed != nil || activity.fileDatas?.maxSpeed != nil
    }

    private var hasCardioData: Bool {
        activity.fileDatas?.hrAvg != nil || activity.fileDatas?.hrMax != nil
    }

    private var hasElevationData: Bool {
        activity.preferredElevationGain != nil || activity.preferredElevationLoss != nil ||
        activity.fileDatas?.altitudeMax != nil
    }

    private var hasCadenceData: Bool {
        activity.fileDatas?.cadenceAvg != nil || activity.fileDatas?.cadenceMax != nil
    }

    private var hasPerformanceData: Bool {
        activity.preferredTSS != nil || activity.preferredTrimp != nil || activity.preferredKilojoules != nil
    }
}

// MARK: - Quick Summary Section

private struct QuickSummarySection: View {
    let activity: Activity
    var preferences: SessionDisplayPreferences?
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            SectionHeader(icon: "chart.bar.fill", title: "Résumé", color: themeManager.accentColor)

            // Grille 3 colonnes pour les métriques principales
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: ECSpacing.md) {
                // Durée
                if isMetricVisible(.duration), let duration = activity.preferredDuration {
                    QuickStatItem(
                        value: formatDuration(duration),
                        label: "Durée",
                        icon: "clock.fill"
                    )
                }

                // Distance
                if isMetricVisible(.distance), let distance = activity.preferredDistance {
                    QuickStatItem(
                        value: formatDistance(distance, discipline: activity.discipline),
                        label: "Distance",
                        icon: "arrow.left.and.right"
                    )
                }

                // Métrique principale selon le sport
                primaryMetric
            }
        }
        .themedCard()
    }
    
    private func isMetricVisible(_ metric: SessionMetric) -> Bool {
        guard let preferences = preferences else { return true }
        return preferences.visibleMetrics.contains(metric)
    }

    @ViewBuilder
    private var primaryMetric: some View {
        switch activity.discipline {
        case .cyclisme:
            if isMetricVisible(.power), let avgPower = activity.preferredAvgPower {
                QuickStatItem(
                    value: "\(Int(avgPower)) W",
                    label: "Puiss. moy",
                    icon: "bolt.fill"
                )
            } else if isMetricVisible(.speed), let avgSpeed = activity.fileDatas?.avgSpeed {
                QuickStatItem(
                    value: String(format: "%.1f km/h", avgSpeed),
                    label: "Vit. moy",
                    icon: "speedometer"
                )
            }

        case .course:
            if isMetricVisible(.pace), let avgSpeed = activity.fileDatas?.avgSpeed, avgSpeed > 0 {
                let paceMinKm = 60.0 / avgSpeed
                let minutes = Int(paceMinKm)
                let seconds = Int((paceMinKm - Double(minutes)) * 60)
                QuickStatItem(
                    value: String(format: "%d:%02d /km", minutes, seconds),
                    label: "Allure moy",
                    icon: "figure.run"
                )
            }

        case .natation:
            if isMetricVisible(.pace), let avgSpeed = activity.fileDatas?.avgSpeed, avgSpeed > 0 {
                // Pace per 100m
                let pacePer100m = 6.0 / avgSpeed
                let minutes = Int(pacePer100m)
                let seconds = Int((pacePer100m - Double(minutes)) * 60)
                QuickStatItem(
                    value: String(format: "%d:%02d /100m", minutes, seconds),
                    label: "Allure moy",
                    icon: "figure.pool.swim"
                )
            }

        case .autre:
            if isMetricVisible(.speed), let avgSpeed = activity.fileDatas?.avgSpeed {
                QuickStatItem(
                    value: String(format: "%.1f km/h", avgSpeed),
                    label: "Vit. moy",
                    icon: "speedometer"
                )
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return "\(minutes) min"
        }
    }

    private func formatDistance(_ km: Double, discipline: Discipline) -> String {
        if discipline == .natation {
            return String(format: "%.0f m", km * 1000)
        } else if km < 1 {
            return String(format: "%.0f m", km * 1000)
        } else {
            return String(format: "%.1f km", km)
        }
    }
}

// MARK: - Power Metrics Section (Cycling)

private struct PowerMetricsSection: View {
    let activity: Activity
    var preferences: SessionDisplayPreferences?
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            SectionHeader(icon: "bolt.fill", title: "Puissance", color: themeManager.sportColor(for: .cyclisme))

            let cyclingColor = themeManager.sportColor(for: .cyclisme)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ECSpacing.md) {
                // Puissance moyenne (priorité file_datas)
                if isMetricVisible(.power), let avgPower = activity.preferredAvgPower {
                    MetricCard(
                        value: "\(Int(avgPower))",
                        unit: "W",
                        label: "Moyenne",
                        icon: "bolt.fill",
                        color: cyclingColor
                    )
                }

                // Puissance max (priorité file_datas)
                if isMetricVisible(.power), let maxPower = activity.preferredMaxPower {
                    MetricCard(
                        value: "\(Int(maxPower))",
                        unit: "W",
                        label: "Maximum",
                        icon: "bolt",
                        color: cyclingColor.opacity(0.7)
                    )
                }

                // Normalized Power (NP) (priorité file_datas)
                if isAdvancedMetricVisible(), let np = activity.preferredNP {
                    MetricCard(
                        value: "\(Int(np))",
                        unit: "W",
                        label: "NP",
                        icon: "waveform.path.ecg",
                        color: themeManager.infoColor
                    )
                }

                // Intensity Factor (IF) = NP / FTP
                if isAdvancedMetricVisible(), let np = activity.preferredNP, let ftp = activity.ftp, ftp > 0 {
                    let intensityFactor = np / ftp
                    MetricCard(
                        value: String(format: "%.2f", intensityFactor),
                        unit: "",
                        label: "IF",
                        icon: "gauge.with.dots.needle.bottom.50percent",
                        color: intensityColor(intensityFactor)
                    )
                }

                // W/kg si poids disponible
                if isAdvancedMetricVisible(), let avgPower = activity.preferredAvgPower, let weight = activity.weight, weight > 0 {
                    let wattsPerKg = avgPower / weight
                    MetricCard(
                        value: String(format: "%.2f", wattsPerKg),
                        unit: "W/kg",
                        label: "Puiss. relative",
                        icon: "scalemass",
                        color: themeManager.successColor
                    )
                }

                // FTP de référence
                if isAdvancedMetricVisible(), let ftp = activity.ftp {
                    MetricCard(
                        value: "\(Int(ftp))",
                        unit: "W",
                        label: "FTP",
                        icon: "target",
                        color: themeManager.textSecondary
                    )
                }
            }
        }
        .themedCard()
    }
    
    private func isMetricVisible(_ metric: SessionMetric) -> Bool {
        guard let preferences = preferences else { return true }
        return preferences.visibleMetrics.contains(metric)
    }
    
    private func isAdvancedMetricVisible() -> Bool {
        guard let preferences = preferences else { return true }
        return preferences.showAdvancedMetrics
    }

    private func intensityColor(_ if_value: Double) -> Color {
        switch if_value {
        case ..<0.75: return themeManager.zoneColor(for: 2)
        case 0.75..<0.90: return themeManager.zoneColor(for: 3)
        case 0.90..<1.05: return themeManager.zoneColor(for: 4)
        default: return themeManager.zoneColor(for: 5)
        }
    }
}

// MARK: - Speed/Pace Section

private struct SpeedPaceSection: View {
    let activity: Activity
    var preferences: SessionDisplayPreferences?
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let sportColor = themeManager.sportColor(for: activity.discipline)

        VStack(alignment: .leading, spacing: ECSpacing.md) {
            SectionHeader(
                icon: activity.discipline == .course ? "figure.run" : "speedometer",
                title: activity.discipline == .course || activity.discipline == .natation ? "Allure" : "Vitesse",
                color: sportColor
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ECSpacing.md) {
                switch activity.discipline {
                case .course:
                    // Allure moyenne
                    if isMetricVisible(.pace), let avgSpeed = activity.fileDatas?.avgSpeed, avgSpeed > 0 {
                        let paceMinKm = 60.0 / avgSpeed
                        let minutes = Int(paceMinKm)
                        let seconds = Int((paceMinKm - Double(minutes)) * 60)
                        MetricCard(
                            value: String(format: "%d:%02d", minutes, seconds),
                            unit: "/km",
                            label: "Allure moy",
                            icon: "figure.run",
                            color: sportColor
                        )
                    }

                    // Allure la plus rapide
                    if isMetricVisible(.pace), let maxSpeed = activity.fileDatas?.maxSpeed, maxSpeed > 0 {
                        let paceMinKm = 60.0 / maxSpeed
                        let minutes = Int(paceMinKm)
                        let seconds = Int((paceMinKm - Double(minutes)) * 60)
                        MetricCard(
                            value: String(format: "%d:%02d", minutes, seconds),
                            unit: "/km",
                            label: "Meilleure allure",
                            icon: "hare.fill",
                            color: themeManager.successColor
                        )
                    }

                    // Vitesse moyenne (km/h)
                    if isMetricVisible(.speed), let avgSpeed = activity.fileDatas?.avgSpeed {
                        MetricCard(
                            value: String(format: "%.1f", avgSpeed),
                            unit: "km/h",
                            label: "Vit. moyenne",
                            icon: "speedometer",
                            color: themeManager.textSecondary
                        )
                    }

                case .natation:
                    // Allure /100m
                    if isMetricVisible(.pace), let avgSpeed = activity.fileDatas?.avgSpeed, avgSpeed > 0 {
                        let pacePer100m = 6.0 / avgSpeed
                        let minutes = Int(pacePer100m)
                        let seconds = Int((pacePer100m - Double(minutes)) * 60)
                        MetricCard(
                            value: String(format: "%d:%02d", minutes, seconds),
                            unit: "/100m",
                            label: "Allure moy",
                            icon: "figure.pool.swim",
                            color: sportColor
                        )
                    }

                    // Meilleure allure
                    if isMetricVisible(.pace), let maxSpeed = activity.fileDatas?.maxSpeed, maxSpeed > 0 {
                        let pacePer100m = 6.0 / maxSpeed
                        let minutes = Int(pacePer100m)
                        let seconds = Int((pacePer100m - Double(minutes)) * 60)
                        MetricCard(
                            value: String(format: "%d:%02d", minutes, seconds),
                            unit: "/100m",
                            label: "Meilleure allure",
                            icon: "hare.fill",
                            color: themeManager.successColor
                        )
                    }

                default:
                    // Vitesse moyenne (en mouvement - sans les pauses)
                    if isMetricVisible(.speed), let avgSpeed = activity.fileDatas?.avgSpeed {
                        MetricCard(
                            value: String(format: "%.1f", avgSpeed),
                            unit: "km/h",
                            label: "Vit. moyenne",
                            icon: "speedometer",
                            color: sportColor
                        )
                    }

                    // Vitesse max
                    if isMetricVisible(.speed), let maxSpeed = activity.fileDatas?.maxSpeed {
                        MetricCard(
                            value: String(format: "%.1f", maxSpeed),
                            unit: "km/h",
                            label: "Vit. max",
                            icon: "gauge.with.dots.needle.bottom.100percent",
                            color: themeManager.successColor
                        )
                    }
                }
            }
        }
        .themedCard()
    }
    
    private func isMetricVisible(_ metric: SessionMetric) -> Bool {
        guard let preferences = preferences else { return true }
        return preferences.visibleMetrics.contains(metric)
    }
}

// MARK: - Cardio Section

private struct CardioSection: View {
    let activity: Activity
    var preferences: SessionDisplayPreferences?
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            SectionHeader(icon: "heart.fill", title: "Fréquence cardiaque", color: themeManager.errorColor)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: ECSpacing.md) {
                // FC moyenne
                if isMetricVisible(.heartRate), let hrAvg = activity.fileDatas?.hrAvg {
                    MetricCard(
                        value: "\(Int(hrAvg))",
                        unit: "bpm",
                        label: "Moyenne",
                        icon: "heart.fill",
                        color: themeManager.errorColor
                    )
                }

                // FC max
                if isMetricVisible(.heartRateMax), let hrMax = activity.fileDatas?.hrMax {
                    MetricCard(
                        value: "\(Int(hrMax))",
                        unit: "bpm",
                        label: "Maximum",
                        icon: "heart",
                        color: themeManager.zoneColor(for: 5)
                    )
                }

                // FC min
                if isMetricVisible(.heartRate), let hrMin = activity.fileDatas?.hrMin {
                    MetricCard(
                        value: "\(Int(hrMin))",
                        unit: "bpm",
                        label: "Minimum",
                        icon: "heart",
                        color: themeManager.zoneColor(for: 1)
                    )
                }
            }

            // % de FC max si disponible
            if isAdvancedMetricVisible(),
               let hrMax = activity.fileDatas?.hrMax,
               let maxHrUser = activity.maxHrUser,
               maxHrUser > 0 {
                let hrMaxPercent = (hrMax / maxHrUser) * 100
                HStack {
                    Text("% FC max atteint:")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                    Spacer()
                    Text(String(format: "%.0f%%", hrMaxPercent))
                        .font(.ecBodyMedium)
                        .foregroundColor(hrMaxPercent > 95 ? themeManager.zoneColor(for: 5) : themeManager.textPrimary)
                }
                .padding(.top, ECSpacing.xs)
            }
        }
        .themedCard()
    }
    
    private func isMetricVisible(_ metric: SessionMetric) -> Bool {
        guard let preferences = preferences else { return true }
        return preferences.visibleMetrics.contains(metric)
    }
    
    private func isAdvancedMetricVisible() -> Bool {
        guard let preferences = preferences else { return true }
        return preferences.showAdvancedMetrics
    }
}

// MARK: - Elevation Section

private struct ElevationSection: View {
    let activity: Activity
    var preferences: SessionDisplayPreferences?
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            SectionHeader(icon: "mountain.2.fill", title: "Altitude", color: themeManager.successColor)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ECSpacing.md) {
                // D+
                if isMetricVisible(.elevation), let gain = activity.preferredElevationGain {
                    MetricCard(
                        value: "+\(Int(gain))",
                        unit: "m",
                        label: "Dénivelé +",
                        icon: "arrow.up.right",
                        color: themeManager.successColor
                    )
                }

                // D-
                if isMetricVisible(.elevation), let loss = activity.preferredElevationLoss {
                    MetricCard(
                        value: "-\(Int(loss))",
                        unit: "m",
                        label: "Dénivelé -",
                        icon: "arrow.down.right",
                        color: themeManager.errorColor
                    )
                }

                // Altitude max
                if isAdvancedMetricVisible(), let altMax = activity.fileDatas?.altitudeMax {
                    MetricCard(
                        value: "\(Int(altMax))",
                        unit: "m",
                        label: "Alt. max",
                        icon: "arrow.up.to.line",
                        color: themeManager.infoColor
                    )
                }

                // Altitude min
                if isAdvancedMetricVisible(), let altMin = activity.fileDatas?.altitudeMin {
                    MetricCard(
                        value: "\(Int(altMin))",
                        unit: "m",
                        label: "Alt. min",
                        icon: "arrow.down.to.line",
                        color: themeManager.textSecondary
                    )
                }

                // Altitude moyenne
                if isAdvancedMetricVisible(), let altAvg = activity.fileDatas?.altitudeAvg {
                    MetricCard(
                        value: "\(Int(altAvg))",
                        unit: "m",
                        label: "Alt. moy",
                        icon: "minus",
                        color: themeManager.textTertiary
                    )
                }

                // VAM (Vélo: Vitesse Ascensionnelle Moyenne) si D+ significatif
                if isAdvancedMetricVisible(),
                   activity.discipline == .cyclisme,
                   let vam = activity.preferredVAM {
                    MetricCard(
                        value: "\(Int(vam))",
                        unit: "m/h",
                        label: "VAM",
                        icon: "chart.line.uptrend.xyaxis",
                        color: themeManager.warningColor
                    )
                }
            }
        }
        .themedCard()
    }
    
    private func isMetricVisible(_ metric: SessionMetric) -> Bool {
        guard let preferences = preferences else { return true }
        return preferences.visibleMetrics.contains(metric)
    }
    
    private func isAdvancedMetricVisible() -> Bool {
        guard let preferences = preferences else { return true }
        return preferences.showAdvancedMetrics
    }
}

// MARK: - Cadence Section

private struct CadenceSection: View {
    let activity: Activity
    var preferences: SessionDisplayPreferences?
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            SectionHeader(
                icon: activity.discipline == .cyclisme ? "arrow.clockwise" : "metronome.fill",
                title: "Cadence",
                color: themeManager.infoColor
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ECSpacing.md) {
                // Cadence moyenne
                if isMetricVisible(.cadence), let cadAvg = activity.fileDatas?.cadenceAvg {
                    let (value, unit) = formatCadence(cadAvg, discipline: activity.discipline)
                    MetricCard(
                        value: value,
                        unit: unit,
                        label: "Moyenne",
                        icon: activity.discipline == .cyclisme ? "arrow.clockwise" : "metronome.fill",
                        color: themeManager.infoColor
                    )
                }

                // Cadence max
                if isMetricVisible(.cadence), let cadMax = activity.fileDatas?.cadenceMax {
                    let (value, unit) = formatCadence(cadMax, discipline: activity.discipline)
                    MetricCard(
                        value: value,
                        unit: unit,
                        label: "Maximum",
                        icon: activity.discipline == .cyclisme ? "arrow.clockwise" : "metronome",
                        color: themeManager.infoColor.opacity(0.7)
                    )
                }
            }
        }
        .themedCard()
    }
    
    private func isMetricVisible(_ metric: SessionMetric) -> Bool {
        guard let preferences = preferences else { return true }
        return preferences.visibleMetrics.contains(metric)
    }

    private func formatCadence(_ cadence: Double, discipline: Discipline) -> (String, String) {
        switch discipline {
        case .cyclisme:
            return ("\(Int(cadence))", "rpm")
        case .course:
            // Course: doubler car souvent stocké en steps/min/2
            return ("\(Int(cadence * 2))", "ppm")
        case .natation:
            return ("\(Int(cadence))", "mvt/min")
        case .autre:
            return ("\(Int(cadence))", "/min")
        }
    }
}

// MARK: - Performance Section

private struct PerformanceSection: View {
    let activity: Activity
    var preferences: SessionDisplayPreferences?
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            SectionHeader(icon: "chart.line.uptrend.xyaxis", title: "Performance & Charge", color: themeManager.warningColor)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ECSpacing.md) {
                // TSS (Training Stress Score) - priorité file_datas
                if isAdvancedMetricVisible(), let tss = activity.preferredTSS {
                    MetricCard(
                        value: "\(Int(tss))",
                        unit: "",
                        label: "TSS",
                        icon: "flame.fill",
                        color: tssColor(Int(tss))
                    )
                }

                // Load Foster (TRIMP) - priorité file_datas
                if isAdvancedMetricVisible(), let load = activity.preferredTrimp {
                    MetricCard(
                        value: "\(Int(load))",
                        unit: "",
                        label: "Charge (TRIMP)",
                        icon: "heart.text.square.fill",
                        color: themeManager.errorColor
                    )
                }

                // Kilojoules - priorité file_datas
                if isAdvancedMetricVisible(), let kj = activity.preferredKilojoules {
                    MetricCard(
                        value: "\(Int(kj))",
                        unit: "kJ",
                        label: "Énergie",
                        icon: "bolt.circle.fill",
                        color: themeManager.warningColor
                    )
                }

                // Calories
                if isMetricVisible(.calories), let cal = activity.fileDatas?.calories {
                    MetricCard(
                        value: "\(Int(cal))",
                        unit: "kcal",
                        label: "Calories",
                        icon: "flame",
                        color: themeManager.errorColor.opacity(0.7)
                    )
                }
            }

            // Description du TSS si présent
            if isAdvancedMetricVisible(), let tss = activity.preferredTSS {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(themeManager.textTertiary)
                    Text(tssDescription(Int(tss)))
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }
                .padding(.top, ECSpacing.xs)
            }
        }
        .themedCard()
    }
    
    private func isMetricVisible(_ metric: SessionMetric) -> Bool {
        guard let preferences = preferences else { return true }
        return preferences.visibleMetrics.contains(metric)
    }
    
    private func isAdvancedMetricVisible() -> Bool {
        guard let preferences = preferences else { return true }
        return preferences.showAdvancedMetrics
    }

    private func tssColor(_ tss: Int) -> Color {
        switch tss {
        case ..<50: return themeManager.zoneColor(for: 1)
        case 50..<100: return themeManager.zoneColor(for: 2)
        case 100..<150: return themeManager.zoneColor(for: 3)
        case 150..<250: return themeManager.zoneColor(for: 4)
        default: return themeManager.zoneColor(for: 5)
        }
    }

    private func tssDescription(_ tss: Int) -> String {
        switch tss {
        case ..<50: return "Séance de récupération"
        case 50..<100: return "Séance légère à modérée"
        case 100..<150: return "Séance modérée"
        case 150..<250: return "Séance difficile"
        default: return "Séance très difficile"
        }
    }
}

// MARK: - Supporting Views

private struct SectionHeader: View {
    let icon: String
    let title: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: ECSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16, weight: .semibold))
            Text(title)
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)
            Spacer()
        }
    }
}

private struct QuickStatItem: View {
    let value: String
    let label: String
    let icon: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(themeManager.textTertiary)
            Text(value)
                .font(.ecBodyMedium)
                .foregroundColor(themeManager.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.ecSmall)
                .foregroundColor(themeManager.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MetricCard: View {
    let value: String
    let unit: String
    let label: String
    let icon: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.xs) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(label)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textSecondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(themeManager.textPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ECSpacing.sm)
        .background(themeManager.elevatedColor)
        .cornerRadius(ECRadius.sm)
    }
}

struct ZonesCard: View {
    let zones: [ActivityZone]
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(themeManager.errorColor)
                Text("Temps dans les zones")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
            }

            ForEach(zones) { zone in
                HStack(spacing: ECSpacing.sm) {
                    Text("Z\(zone.zone)")
                        .font(.ecCaptionBold)
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(themeManager.zoneColor(for: zone.zone))
                        .cornerRadius(6)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.elevatedColor)
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.zoneColor(for: zone.zone))
                                .frame(width: geometry.size.width * CGFloat(zone.percentage) / 100, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(zone.percentage))%")
                        .font(.ecCaptionBold)
                        .foregroundColor(themeManager.textSecondary)
                        .frame(width: 40, alignment: .trailing)

                    Text(zone.formattedDuration)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textTertiary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
        .themedCard()
    }
}

struct NotesCard: View {
    let notes: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(themeManager.warningColor)
                Text("Notes")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
            }

            Text(notes)
                .font(.ecBody)
                .foregroundColor(themeManager.textPrimary)
        }
        .themedCard()
    }
}

// MARK: - Charts Content

struct SessionChartsContent: View {
    let activity: Activity
    let preferences: SessionDisplayPreferences
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        AdvancedChartsView(activity: activity)
            .padding(.horizontal, ECSpacing.xs)
    }
}

// MARK: - Laps Content

struct SessionLapsContent: View {
    let activity: Activity
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var laps: [ActivityLap]?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedLap: ActivityLap?
    @State private var selectedLapIndex: Int?

    // Métriques max pour l'échelle relative
    private var maxLapPower: Double { laps?.compactMap { $0.avgPower }.max() ?? 1 }
    private var maxLapHR: Double { laps?.compactMap { $0.avgHeartRate }.max() ?? 1 }
    private var maxLapSpeed: Double { laps?.compactMap { $0.avgSpeedKmh }.max() ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            if isLoading {
                VStack(spacing: ECSpacing.sm) {
                    ProgressView()
                    Text("Chargement des intervalles...")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ECSpacing.xl)
                .themedCard()
            } else if let laps = laps, !laps.isEmpty {
                // Header avec le nombre d'intervalles
                HStack {
                    Image(systemName: "list.number")
                        .foregroundColor(themeManager.accentColor)
                    Text(laps.count == 1 ? "1 intervalle" : "\(laps.count) intervalles")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                    Spacer()

                    // Résumé global
                    if let totalDistance = laps.compactMap({ $0.distance }).reduce(0, +) as Double?,
                       totalDistance > 0 {
                        Text(formatTotalDistance(totalDistance))
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }
                .padding(.horizontal, ECSpacing.md)
                .padding(.top, ECSpacing.sm)

                // Si un seul intervalle, afficher directement les détails
                if laps.count == 1 {
                    SingleLapDetailView(lap: laps[0], discipline: activity.discipline)
                        .themedCard()
                } else {
                    // Plusieurs intervalles: liste cliquable avec analyse visuelle
                    VStack(spacing: 0) {
                        ForEach(Array(laps.enumerated()), id: \.element.id) { index, lap in
                            LapRowInteractive(
                                index: index + 1,
                                lap: lap,
                                discipline: activity.discipline,
                                isSelected: selectedLapIndex == index,
                                context: LapContext(maxPower: maxLapPower, maxHR: maxLapHR, maxSpeed: maxLapSpeed)
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedLapIndex == index {
                                        selectedLapIndex = nil
                                        selectedLap = nil
                                    } else {
                                        selectedLapIndex = index
                                        selectedLap = lap
                                    }
                                }
                            }

                            // Détails expandables
                            if selectedLapIndex == index {
                                LapDetailExpandedView(lap: lap, discipline: activity.discipline)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            if index < laps.count - 1 {
                                Divider()
                                    .padding(.horizontal, ECSpacing.md)
                            }
                        }
                    }
                    .themedCard()
                }
            } else {
                VStack(spacing: ECSpacing.sm) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 40))
                        .foregroundColor(themeManager.textTertiary)
                    Text(errorMessage ?? "Aucun intervalle enregistré")
                        .font(.ecBody)
                        .foregroundColor(themeManager.textSecondary)
                    Text("Cette activité n'a pas d'intervalles ou de tours enregistrés.")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ECSpacing.xl)
                .padding(.horizontal, ECSpacing.md)
                .themedCard()
            }
        }
        .task {
            await loadLapsData()
        }
    }

    private func loadLapsData() async {
        // D'abord vérifier si les laps sont déjà chargés
        if let existingLaps = activity.fileDatas?.laps, !existingLaps.isEmpty {
            #if DEBUG
            print("🏃 Laps: Using existing \(existingLaps.count) laps from activity")
            for (i, lap) in existingLaps.enumerated() {
                print("  Lap \(i): idx=\(lap.lapIndex), dist=\(lap.distance ?? 0)m, dur=\(lap.duration ?? 0)s, hr=\(lap.avgHeartRate ?? 0)")
            }
            #endif
            self.laps = existingLaps
            isLoading = false
            return
        }

        // Sinon charger avec records=true
        guard let userId = authViewModel.user?.id,
              let activityDate = activity.date else {
            isLoading = false
            return
        }

        do {
            let (_, fileData) = try await ActivitiesService.shared.getActivityGPSData(
                userId: userId,
                activityDate: activityDate,
                forceReload: false
            )
            #if DEBUG
            if let loadedLaps = fileData?.laps {
                print("🏃 Laps: Loaded \(loadedLaps.count) laps from API")
                for (i, lap) in loadedLaps.enumerated() {
                    print("  Lap \(i): idx=\(lap.lapIndex), dist=\(lap.distance ?? 0)m, dur=\(lap.duration ?? 0)s, hr=\(lap.avgHeartRate ?? 0)")
                }
            }
            #endif
            self.laps = fileData?.laps
        } catch {
            #if DEBUG
            print("❌ Error loading laps: \(error)")
            #endif
            errorMessage = "Erreur de chargement"
        }

        isLoading = false
    }

    private func formatTotalDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.2f km total", meters / 1000)
        } else {
            return String(format: "%.0f m total", meters)
        }
    }
}

// Helper struct for context
struct LapContext {
    let maxPower: Double
    let maxHR: Double
    let maxSpeed: Double
}

// MARK: - Single Lap Detail View (quand il n'y a qu'un intervalle)

private struct SingleLapDetailView: View {
    let lap: ActivityLap
    let discipline: Discipline
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let sportColor = themeManager.sportColor(for: discipline)

        VStack(spacing: ECSpacing.md) {
            // Titre
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(themeManager.accentColor)
                Text("Détail de l'intervalle")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
            }

            Divider()

            // Grille de stats selon la discipline
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: ECSpacing.md) {
                // Durée - toujours affiché
                LapStatCell(
                    icon: "clock",
                    value: lap.formattedDuration,
                    label: "Durée",
                    color: themeManager.accentColor
                )

                // Distance - toujours affiché
                LapStatCell(
                    icon: "arrow.left.and.right",
                    value: lap.formattedDistance,
                    label: "Distance",
                    color: themeManager.accentColor
                )

                // Stats spécifiques au sport
                switch discipline {
                case .cyclisme:
                    // Vélo: Puissance, Cadence, Vitesse
                    if let avgPower = lap.avgPower {
                        LapStatCell(
                            icon: "bolt.fill",
                            value: "\(Int(avgPower)) W",
                            label: "Puiss. moy",
                            color: sportColor
                        )
                    }
                    if let maxPower = lap.maxPower {
                        LapStatCell(
                            icon: "bolt",
                            value: "\(Int(maxPower)) W",
                            label: "Puiss. max",
                            color: sportColor.opacity(0.7)
                        )
                    }
                    if let avgCadence = lap.avgCadence {
                        LapStatCell(
                            icon: "arrow.clockwise",
                            value: "\(Int(avgCadence)) rpm",
                            label: "Cadence",
                            color: themeManager.infoColor
                        )
                    }
                    if let speed = lap.formattedSpeed {
                        LapStatCell(
                            icon: "speedometer",
                            value: speed,
                            label: "Vit. moy",
                            color: themeManager.successColor
                        )
                    }

                case .course:
                    // Course: Allure, Cadence, Vitesse
                    if let pace = lap.formattedPacePerKm {
                        LapStatCell(
                            icon: "figure.run",
                            value: "\(pace) /km",
                            label: "Allure",
                            color: sportColor
                        )
                    }
                    if let avgCadence = lap.avgCadence {
                        LapStatCell(
                            icon: "metronome",
                            value: "\(Int(avgCadence * 2)) ppm",
                            label: "Cadence",
                            color: themeManager.infoColor
                        )
                    }
                    if let maxSpeed = lap.maxSpeedKmh {
                        LapStatCell(
                            icon: "hare",
                            value: String(format: "%.1f km/h", maxSpeed),
                            label: "Vit. max",
                            color: themeManager.successColor
                        )
                    }

                case .natation:
                    // Natation: Allure /100m
                    if let pace = lap.formattedPacePer100m {
                        LapStatCell(
                            icon: "figure.pool.swim",
                            value: "\(pace) /100m",
                            label: "Allure",
                            color: sportColor
                        )
                    }
                    if let avgCadence = lap.avgCadence {
                        LapStatCell(
                            icon: "water.waves",
                            value: "\(Int(avgCadence)) mvt/min",
                            label: "Mouvements",
                            color: themeManager.infoColor
                        )
                    }

                case .autre:
                    // Générique
                    if let speed = lap.formattedSpeed {
                        LapStatCell(
                            icon: "speedometer",
                            value: speed,
                            label: "Vit. moy",
                            color: themeManager.successColor
                        )
                    }
                }

                // Dénivelé si disponible
                if let ascent = lap.ascent, ascent > 0 {
                    LapStatCell(
                        icon: "arrow.up.right",
                        value: "+\(Int(ascent)) m",
                        label: "D+",
                        color: themeManager.successColor
                    )
                }

                // FC - toujours affiché si disponible (tous sports)
                if let avgHr = lap.avgHeartRate {
                    LapStatCell(
                        icon: "heart.fill",
                        value: "\(Int(avgHr)) bpm",
                        label: "FC moy",
                        color: themeManager.errorColor
                    )
                }
                if let maxHr = lap.maxHeartRate {
                    LapStatCell(
                        icon: "heart",
                        value: "\(Int(maxHr)) bpm",
                        label: "FC max",
                        color: themeManager.errorColor.opacity(0.7)
                    )
                }
            }
        }
        .padding(ECSpacing.md)
    }
}

// MARK: - Lap Row Interactive (cliquable)

private struct LapRowInteractive: View {
    let index: Int
    let lap: ActivityLap
    let discipline: Discipline
    let isSelected: Bool
    var context: LapContext?
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let sportColor = themeManager.sportColor(for: discipline)

        Button(action: onTap) {
            HStack(spacing: ECSpacing.md) {
                // Numéro
                Text("\(index)")
                    .font(.ecCaptionBold)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(isSelected ? themeManager.accentColor : themeManager.textTertiary)
                    .cornerRadius(6)

                // Durée et distance (Colonne fixe)
                VStack(alignment: .leading, spacing: 2) {
                    Text(lap.formattedDuration)
                        .font(.ecBodyMedium)
                        .foregroundColor(themeManager.textPrimary)
                        .monospacedDigit()

                    Text(lap.formattedDistance)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                }
                .frame(width: 70, alignment: .leading)

                Spacer()
                
                // Métrique principale avec barre d'intensité
                mainMetricView(sportColor: sportColor)
                
                // Secondaire (FC) si dispo
                if let avgHr = lap.avgHeartRate {
                    let isMax = (context != nil && context!.maxHR > 0) ? (avgHr >= context!.maxHR) : false
                    VStack(alignment: .trailing, spacing: 0) {
                        HStack(spacing: 2) {
                            if isMax { Text("🏆").font(.system(size: 8)) }
                            Text("\(Int(avgHr))")
                                .font(.ecBodyMedium)
                                .foregroundColor(themeManager.errorColor)
                        }
                        Text("bpm")
                            .font(.system(size: 9))
                            .foregroundColor(themeManager.textTertiary)
                    }
                    .frame(width: 40, alignment: .trailing)
                }

                // Indicateur d'expansion
                Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textTertiary)
                    .frame(width: 12)
            }
            .padding(.horizontal, ECSpacing.md)
            .padding(.vertical, ECSpacing.sm)
            .background(isSelected ? themeManager.accentColor.opacity(0.05) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func mainMetricView(sportColor: Color) -> some View {
        // Déterminer la valeur et le max pour la barre
        let (valueStr, unit, ratio, isBest) = getMainMetricData()
        
        ZStack(alignment: .leading) {
            // Barre de fond (intensité)
            if ratio > 0 {
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(sportColor.opacity(0.15))
                        .frame(width: geo.size.width * ratio, height: geo.size.height)
                }
            }
            
            // Texte
            HStack(spacing: 4) {
                if isBest { Text("🏆").font(.system(size: 10)) }
                Text(valueStr)
                    .font(.ecBodyBold)
                    .foregroundColor(themeManager.textPrimary)
                Text(unit)
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
        }
        .frame(height: 24)
        .cornerRadius(4)
        // Largeur fixe pour alignement
        .frame(width: 110, alignment: .leading)
    }
    
    private func getMainMetricData() -> (String, String, Double, Bool) {
        guard let ctx = context else { return ("-", "", 0, false) }
        
        switch discipline {
        case .cyclisme:
            if let pwr = lap.avgPower {
                let ratio = ctx.maxPower > 0 ? (pwr / ctx.maxPower) : 0
                return ("\(Int(pwr))", "W", ratio, pwr >= ctx.maxPower)
            }
        case .course:
            if let pace = lap.formattedPacePerKm, let speed = lap.avgSpeedKmh {
                let ratio = ctx.maxSpeed > 0 ? (speed / ctx.maxSpeed) : 0
                return (pace, "/km", ratio, speed >= ctx.maxSpeed)
            }
        case .natation:
            if let pace = lap.formattedPacePer100m, let speed = lap.avgSpeedKmh {
                let ratio = ctx.maxSpeed > 0 ? (speed / ctx.maxSpeed) : 0
                return (pace, "/100m", ratio, speed >= ctx.maxSpeed)
            }
        default:
            break
        }
        
        // Fallback: Vitesse ou FC
        if let speed = lap.formattedSpeed, let rawSpeed = lap.avgSpeedKmh {
            let ratio = ctx.maxSpeed > 0 ? (rawSpeed / ctx.maxSpeed) : 0
            return (speed, "", ratio, rawSpeed >= ctx.maxSpeed)
        }
        
        return ("-", "", 0, false)
    }
}
// Extensions pour Optional Bool
extension Optional where Wrapped == Bool {
    var unavailable: Bool { self == nil }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let value: String
    let unit: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 2) {
            Text(value)
                .font(.ecBodyMedium)
                .foregroundColor(color)
            Text(unit)
                .font(.ecSmall)
                .foregroundColor(themeManager.textSecondary)
        }
    }
}

// MARK: - Lap Detail Expanded View

private struct LapDetailExpandedView: View {
    let lap: ActivityLap
    let discipline: Discipline
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: ECSpacing.sm) {
            // Grille de stats compacte
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: ECSpacing.sm) {
                // Stats selon discipline
                switch discipline {
                case .cyclisme:
                    if let avgPower = lap.avgPower {
                        MiniStatCell(label: "P. moy", value: "\(Int(avgPower))W")
                    }
                    if let maxPower = lap.maxPower {
                        MiniStatCell(label: "P. max", value: "\(Int(maxPower))W")
                    }
                    if let avgCadence = lap.avgCadence {
                        MiniStatCell(label: "Cadence", value: "\(Int(avgCadence))rpm")
                    }
                    if let speed = lap.avgSpeedKmh {
                        MiniStatCell(label: "Vit.", value: String(format: "%.1fkm/h", speed))
                    }
                    if let maxSpeed = lap.maxSpeedKmh {
                        MiniStatCell(label: "V. max", value: String(format: "%.1fkm/h", maxSpeed))
                    }

                case .course:
                    if let pace = lap.formattedPacePerKm {
                        MiniStatCell(label: "Allure", value: "\(pace)/km")
                    }
                    if let avgCadence = lap.avgCadence {
                        MiniStatCell(label: "Cadence", value: "\(Int(avgCadence * 2))ppm")
                    }
                    if let maxSpeed = lap.maxSpeedKmh {
                        MiniStatCell(label: "V. max", value: String(format: "%.1fkm/h", maxSpeed))
                    }

                case .natation:
                    if let pace = lap.formattedPacePer100m {
                        MiniStatCell(label: "Allure", value: "\(pace)/100m")
                    }
                    if let avgCadence = lap.avgCadence {
                        MiniStatCell(label: "Mouv.", value: "\(Int(avgCadence))/min")
                    }

                case .autre:
                    if let speed = lap.avgSpeedKmh {
                        MiniStatCell(label: "Vitesse", value: String(format: "%.1fkm/h", speed))
                    }
                }

                // Dénivelé
                if let ascent = lap.ascent, ascent > 0 {
                    MiniStatCell(label: "D+", value: "+\(Int(ascent))m")
                }

                // FC toujours affiché
                if let avgHr = lap.avgHeartRate {
                    MiniStatCell(label: "FC moy", value: "\(Int(avgHr))bpm")
                }
                if let maxHr = lap.maxHeartRate {
                    MiniStatCell(label: "FC max", value: "\(Int(maxHr))bpm")
                }
            }
        }
        .padding(.horizontal, ECSpacing.md)
        .padding(.bottom, ECSpacing.md)
        .background(themeManager.elevatedColor)
    }
}

// MARK: - Mini Stat Cell (for expanded view)

private struct MiniStatCell: View {
    let label: String
    let value: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.ecCaptionBold)
                .foregroundColor(themeManager.textPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(themeManager.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Lap Stat Cell (for single lap detail)

private struct LapStatCell: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: ECSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.ecBodyMedium)
                    .foregroundColor(themeManager.textPrimary)
                Text(label)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textSecondary)
            }

            Spacer()
        }
        .padding(ECSpacing.sm)
        .background(themeManager.elevatedColor)
        .cornerRadius(ECRadius.sm)
    }
}

// MARK: - Logbook Data

private struct Gel: Identifiable, Hashable {
    let id: String
    let name: String
    let brand: String
    let calories: Int
    let carbs: Int
    let caffeine: Int
    let color: String
}

private let gelsData: [Gel] = [
    Gel(id: "precision-fuel-pf30", name: "PF 30", brand: "Precision Fuel", calories: 120, carbs: 30, caffeine: 0, color: "#4A90E2"),
    Gel(id: "precision-fuel-pf30-cafeine", name: "PF 30 Caféine", brand: "Precision Fuel", calories: 120, carbs: 30, caffeine: 100, color: "#E94B3C"),
    Gel(id: "gu-energy-original", name: "Energy Gel", brand: "GU", calories: 100, carbs: 22, caffeine: 20, color: "#00A86B"),
    Gel(id: "gu-roctane", name: "Roctane", brand: "GU", calories: 100, carbs: 21, caffeine: 35, color: "#FF6B35"),
    Gel(id: "maurten-gel-100", name: "Gel 100", brand: "Maurten", calories: 100, carbs: 25, caffeine: 0, color: "#1A1A1A"),
    Gel(id: "maurten-gel-100-caf", name: "Gel 100 CAF", brand: "Maurten", calories: 100, carbs: 25, caffeine: 100, color: "#8B4513"),
    Gel(id: "science-in-sport-go", name: "GO Isotonic", brand: "SiS", calories: 87, carbs: 22, caffeine: 0, color: "#0066CC"),
    Gel(id: "science-in-sport-go-caf", name: "GO + Caffeine", brand: "SiS", calories: 87, carbs: 22, caffeine: 75, color: "#CC0066"),
    Gel(id: "clif-shot", name: "Shot", brand: "Clif", calories: 100, carbs: 24, caffeine: 0, color: "#228B22"),
    Gel(id: "high5-energy", name: "Energy Gel", brand: "HIGH5", calories: 92, carbs: 23, caffeine: 0, color: "#FFD700"),
    Gel(id: "high5-energy-caf", name: "Energy Gel Caffeine", brand: "HIGH5", calories: 92, carbs: 23, caffeine: 30, color: "#FF4500"),
    Gel(id: "powerbar-powergel", name: "PowerGel", brand: "PowerBar", calories: 110, carbs: 27, caffeine: 0, color: "#4169E1"),
]

private func getGelById(_ id: String) -> Gel? { gelsData.first { $0.id == id } }

private struct HydrationOptionData: Identifiable, Hashable {
    let id: String; let name: String; let volume: Int; let icon: String
}

private struct HydrationContentTypeData: Identifiable, Hashable {
    let id: String; let name: String; let color: Color
}

private let hydrationOptionsData: [HydrationOptionData] = [
    HydrationOptionData(id: "bidon-500", name: "Bidon 500ml", volume: 500, icon: "drop.fill"),
    HydrationOptionData(id: "bidon-750", name: "Bidon 750ml", volume: 750, icon: "drop.fill"),
    HydrationOptionData(id: "gourde-1000", name: "Gourde 1L", volume: 1000, icon: "drop.fill"),
]

private let hydrationContentTypesData: [HydrationContentTypeData] = [
    HydrationContentTypeData(id: "water", name: "Eau", color: Color(hex: "#3B82F6")),
    HydrationContentTypeData(id: "electrolytes", name: "Électrolytes", color: Color(hex: "#10B981")),
    HydrationContentTypeData(id: "isotonic", name: "Boisson isotonique", color: Color(hex: "#F59E0B")),
    HydrationContentTypeData(id: "energy", name: "Boisson énergétique", color: Color(hex: "#EF4444")),
    HydrationContentTypeData(id: "bcaa", name: "BCAA", color: Color(hex: "#8B5CF6")),
]

private func getContentTypeById(_ id: String) -> HydrationContentTypeData? { hydrationContentTypesData.first { $0.id == id } }

// MARK: - Logbook Content

struct SessionLogbookContent: View {
    let activity: Activity
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showSaveSuccess = false
    @State private var effortRating: Int?
    @State private var notes: String = ""
    @State private var nutritionItems: [NutritionItem] = []
    @State private var hydrationItems: [HydrationItem] = []
    @State private var equipment: SessionEquipmentData = SessionEquipmentData(bikes: nil, shoes: nil, wetsuits: nil)
    @State private var expandedSections: Set<String> = ["effort", "notes", "nutrition", "hydration", "equipment"]

    var body: some View {
        VStack(spacing: ECSpacing.md) {
            if isLoading {
                ProgressView("Chargement du carnet...").frame(maxWidth: .infinity).padding(.vertical, ECSpacing.xl)
            } else {
                collapsibleSection(id: "effort", title: "Ressenti d'effort", icon: "gauge.with.needle", iconColor: themeManager.warningColor) {
                    EffortRatingEditorView(value: $effortRating)
                }
                collapsibleSection(id: "notes", title: "Notes", icon: "note.text", iconColor: themeManager.accentColor) {
                    TextEditor(text: $notes).font(.ecBody).foregroundColor(themeManager.textPrimary).frame(minHeight: 100).padding(ECSpacing.sm)
                        .background(themeManager.elevatedColor).cornerRadius(ECRadius.md)
                        .overlay(Group { if notes.isEmpty { Text("Ajoutez vos notes...").font(.ecBody).foregroundColor(themeManager.textTertiary).padding(ECSpacing.md).allowsHitTesting(false) } }, alignment: .topLeading)
                }
                collapsibleSection(id: "nutrition", title: "Nutrition", icon: "leaf.fill", iconColor: themeManager.warningColor) {
                    NutritionEditorView(items: $nutritionItems)
                }
                collapsibleSection(id: "hydration", title: "Hydratation", icon: "drop.fill", iconColor: themeManager.infoColor) {
                    HydrationEditorView(items: $hydrationItems)
                }
                if let userId = authViewModel.user?.id {
                    collapsibleSection(id: "equipment", title: "Équipement", icon: "bicycle", iconColor: themeManager.accentColor) {
                        EquipmentSelectorView(userId: userId, discipline: activity.discipline, selectedEquipment: $equipment)
                    }
                }
                Button { Task { await saveLogbook() } } label: {
                    HStack(spacing: ECSpacing.sm) {
                        if isSaving { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                        else { Image(systemName: "square.and.arrow.down"); Text("Sauvegarder") }
                    }
                    .font(.ecLabelBold).foregroundColor(.white).frame(maxWidth: .infinity).padding(ECSpacing.md)
                    .background(isSaving ? themeManager.textTertiary : themeManager.accentColor).cornerRadius(ECRadius.md)
                }
                .disabled(isSaving)

                if showSaveSuccess {
                    HStack { Image(systemName: "checkmark.circle.fill").foregroundColor(themeManager.successColor); Text("Carnet sauvegardé").font(.ecLabel).foregroundColor(themeManager.successColor) }
                        .padding(ECSpacing.sm).background(themeManager.successColor.opacity(0.1)).cornerRadius(ECRadius.md).transition(.opacity)
                }
            }
        }
        .task { await loadLogbook() }
    }

    @ViewBuilder private func collapsibleSection<Content: View>(id: String, title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { if expandedSections.contains(id) { expandedSections.remove(id) } else { expandedSections.insert(id) } }
            } label: {
                HStack { Image(systemName: icon).foregroundColor(iconColor); Text(title).font(.ecLabelBold).foregroundColor(themeManager.textPrimary); Spacer()
                    Image(systemName: expandedSections.contains(id) ? "chevron.up" : "chevron.down").font(.system(size: 14)).foregroundColor(themeManager.textTertiary) }
                    .padding(ECSpacing.md)
            }
            if expandedSections.contains(id) { VStack { content() }.padding(.horizontal, ECSpacing.md).padding(.bottom, ECSpacing.md) }
        }
        .background(themeManager.cardColor).cornerRadius(ECRadius.lg).shadow(color: themeManager.cardShadow, radius: themeManager.cardShadowRadius, x: 0, y: 2)
    }

    private func loadLogbook() async {
        guard let userId = authViewModel.user?.id else { isLoading = false; return }
        do {
            if let logbook = try await LogbookService.shared.getLogbookBySessionId(userId: userId, sessionId: activity.id) {
                effortRating = logbook.effortRating; notes = logbook.notes; nutritionItems = logbook.nutrition.items; hydrationItems = logbook.hydration.items
                if let eq = logbook.equipment { equipment = eq }
            }
        } catch { print("Error loading logbook: \(error)") }
        isLoading = false
    }

    private func saveLogbook() async {
        guard let userId = authViewModel.user?.id else { return }
        isSaving = true; showSaveSuccess = false
        let nutritionTotals = LogbookService.shared.calculateNutritionTotals(nutritionItems)
        let hydrationTotal = LogbookService.shared.calculateHydrationTotal(hydrationItems)
        let logbookData = LogbookData(nutrition: NutritionData(items: nutritionItems, totals: nutritionTotals, timeline: nil), hydration: HydrationData(items: hydrationItems, totalVolume: hydrationTotal), notes: notes, weather: .empty, equipment: equipment, effortRating: effortRating, perceivedEffort: nil)
        do {
            try await LogbookService.shared.saveLogbook(userId: userId, sessionId: activity.id, mongoId: activity.id, logbook: logbookData, sessionDate: activity.dateStart, sessionName: activity.displayTitle)
            withAnimation { showSaveSuccess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { withAnimation { showSaveSuccess = false } }
        } catch { print("Error saving logbook: \(error)") }
        isSaving = false
    }
}

// MARK: - Effort Rating Editor

private struct EffortRatingEditorView: View {
    @Binding var value: Int?
    @EnvironmentObject var themeManager: ThemeManager
    private let effortLevels: [(value: Int, label: String, color: Color)] = [
        (1, "Très facile", Color(hex: "#10B981")), (2, "Facile", Color(hex: "#34D399")), (3, "Modéré", Color(hex: "#FBBF24")),
        (4, "Difficile", Color(hex: "#F97316")), (5, "Très difficile", Color(hex: "#EF4444")),
    ]

    var body: some View {
        VStack(spacing: ECSpacing.md) {
            HStack(spacing: ECSpacing.xs) {
                ForEach(effortLevels, id: \.value) { level in
                    Button { withAnimation(.easeInOut(duration: 0.2)) { value = level.value } } label: {
                        Image(systemName: isSelected(level.value) ? "star.fill" : "star").font(.system(size: 28))
                            .foregroundColor(isSelected(level.value) ? colorForRating(level.value) : themeManager.textTertiary)
                    }
                    .padding(ECSpacing.sm).background(value == level.value ? level.color.opacity(0.2) : Color.clear).cornerRadius(ECRadius.md)
                }
            }
            if let selectedValue = value, let selectedLevel = effortLevels.first(where: { $0.value == selectedValue }) {
                Text(selectedLevel.label).font(.ecLabelBold).foregroundColor(selectedLevel.color)
                    .padding(.horizontal, ECSpacing.lg).padding(.vertical, ECSpacing.sm).background(selectedLevel.color.opacity(0.15)).cornerRadius(ECRadius.full)
            } else { Text("Évaluez la difficulté ressentie").font(.ecCaption).foregroundColor(themeManager.textTertiary) }
        }
    }
    private func isSelected(_ rating: Int) -> Bool { guard let value = value else { return false }; return value >= rating }
    private func colorForRating(_ rating: Int) -> Color { effortLevels.first { $0.value == rating }?.color ?? themeManager.textTertiary }
}

// MARK: - Nutrition Editor

private struct NutritionEditorView: View {
    @Binding var items: [NutritionItem]
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showGelPicker = false
    @State private var editingTimingId: String?
    @State private var timingInput: String = ""

    private var totals: (calories: Int, carbs: Int, caffeine: Int) {
        items.reduce((0, 0, 0)) { ($0.0 + $1.calories * $1.quantity, $0.1 + $1.carbs * $1.quantity, $0.2 + $1.caffeine * $1.quantity) }
    }

    var body: some View {
        VStack(spacing: ECSpacing.md) {
            if !items.isEmpty {
                HStack(spacing: 0) {
                    totalItem(value: "\(totals.calories)", label: "kcal"); Divider().frame(height: 30)
                    totalItem(value: "\(totals.carbs)g", label: "glucides"); Divider().frame(height: 30)
                    totalItem(value: "\(totals.caffeine)mg", label: "caféine")
                }.padding(ECSpacing.md).background(themeManager.warningColor.opacity(0.15)).cornerRadius(ECRadius.md)
            }
            ForEach(items) { item in nutritionItemRow(item) }
            if let editingId = editingTimingId { timingInputView(for: editingId) }
            Button { showGelPicker = true } label: {
                HStack(spacing: ECSpacing.xs) { Image(systemName: "plus.circle"); Text("Ajouter un gel") }
                    .font(.ecLabel).foregroundColor(themeManager.accentColor).frame(maxWidth: .infinity).padding(ECSpacing.md)
                    .background(RoundedRectangle(cornerRadius: ECRadius.md).strokeBorder(themeManager.accentColor.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5])))
            }
        }
        .sheet(isPresented: $showGelPicker) { GelPickerSheet { gel in addGel(gel); showGelPicker = false }.environmentObject(themeManager) }
    }

    private func totalItem(value: String, label: String) -> some View {
        VStack(spacing: 4) { Text(value).font(.ecH4).foregroundColor(themeManager.textPrimary); Text(label).font(.ecCaption).foregroundColor(themeManager.textSecondary) }.frame(maxWidth: .infinity)
    }

    private func nutritionItemRow(_ item: NutritionItem) -> some View {
        HStack(spacing: ECSpacing.sm) {
            Circle().fill(colorForGel(item.uniqueId)).frame(width: 36, height: 36).overlay(Image(systemName: "leaf.fill").font(.system(size: 16)).foregroundColor(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(item.brand) \(item.name)").font(.ecLabel).foregroundColor(themeManager.textPrimary)
                Text("\(item.calories) kcal • \(item.carbs)g glucides\(item.caffeine > 0 ? " • \(item.caffeine)mg caféine" : "")").font(.ecCaption).foregroundColor(themeManager.textSecondary)
            }
            Spacer()
            Button {
                if editingTimingId == item.uniqueId { editingTimingId = nil } else { editingTimingId = item.uniqueId; timingInput = item.timingMinutes.map { String($0) } ?? "" }
            } label: {
                HStack(spacing: 4) { Image(systemName: "clock").font(.system(size: 12)); Text(item.timingMinutes.map { formatTiming($0) } ?? "Timing").font(.ecCaption) }
                    .foregroundColor(themeManager.accentColor).padding(.horizontal, ECSpacing.sm).padding(.vertical, ECSpacing.xs).background(themeManager.accentColor.opacity(0.1)).cornerRadius(ECRadius.sm)
            }
            Button { removeItem(item.uniqueId) } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(themeManager.errorColor) }
        }.padding(ECSpacing.sm).background(themeManager.elevatedColor).cornerRadius(ECRadius.md)
    }

    private func timingInputView(for itemId: String) -> some View {
        VStack(alignment: .leading, spacing: ECSpacing.xs) {
            Text("Timing (minutes depuis le début) :").font(.ecCaption).foregroundColor(themeManager.accentColor)
            HStack {
                TextField("ex: 45", text: $timingInput).keyboardType(.numberPad).font(.ecBody).padding(ECSpacing.sm).background(themeManager.cardColor).cornerRadius(ECRadius.sm)
                Button("OK") { updateTiming(itemId: itemId, timing: timingInput); editingTimingId = nil }
                    .font(.ecLabelBold).foregroundColor(themeManager.accentColor).padding(.horizontal, ECSpacing.md).padding(.vertical, ECSpacing.sm).background(themeManager.accentColor.opacity(0.1)).cornerRadius(ECRadius.sm)
            }
        }.padding(ECSpacing.sm).background(themeManager.accentColor.opacity(0.1)).cornerRadius(ECRadius.md)
    }

    private func addGel(_ gel: Gel) {
        let newItem = NutritionItem(uniqueId: "\(gel.id)-\(Int(Date().timeIntervalSince1970 * 1000))", brand: gel.brand, name: gel.name, type: "gel", calories: gel.calories, carbs: gel.carbs, caffeine: gel.caffeine, timingMinutes: nil, quantity: 1)
        items.append(newItem)
    }
    private func removeItem(_ uniqueId: String) { items.removeAll { $0.uniqueId == uniqueId } }
    private func updateTiming(itemId: String, timing: String) { guard let index = items.firstIndex(where: { $0.uniqueId == itemId }), let minutes = Int(timing) else { return }; items[index].timingMinutes = minutes }
    private func formatTiming(_ minutes: Int) -> String { let h = minutes / 60; let m = minutes % 60; return h > 0 ? "\(h)h\(String(format: "%02d", m))" : "\(m)min" }
    private func colorForGel(_ uniqueId: String) -> Color { let gelId = uniqueId.components(separatedBy: "-").dropLast().joined(separator: "-"); if let gel = getGelById(gelId) { return Color(hex: gel.color) }; return themeManager.accentColor }
}

private struct GelPickerSheet: View {
    let onSelect: (Gel) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: ECSpacing.sm) {
                    ForEach(gelsData) { gel in
                        Button { onSelect(gel) } label: {
                            HStack(spacing: ECSpacing.md) {
                                Circle().fill(Color(hex: gel.color)).frame(width: 48, height: 48).overlay(Image(systemName: "leaf.fill").font(.system(size: 20)).foregroundColor(.white))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(gel.brand) \(gel.name)").font(.ecLabel).foregroundColor(themeManager.textPrimary)
                                    Text("\(gel.calories) kcal • \(gel.carbs)g glucides\(gel.caffeine > 0 ? " • \(gel.caffeine)mg caféine" : "")").font(.ecCaption).foregroundColor(themeManager.textSecondary)
                                }
                                Spacer(); Image(systemName: "plus").font(.system(size: 20)).foregroundColor(themeManager.accentColor)
                            }.padding(ECSpacing.md).background(themeManager.cardColor).cornerRadius(ECRadius.md)
                        }
                    }
                }.padding(ECSpacing.md)
            }
            .background(themeManager.backgroundColor).navigationTitle("Choisir un gel").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(themeManager.textPrimary) } } }
        }
    }
}

// MARK: - Hydration Editor

private struct HydrationEditorView: View {
    @Binding var items: [HydrationItem]
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showHydrationPicker = false
    private var totalVolume: Int { items.reduce(0) { $0 + $1.volume * $1.quantity } }

    var body: some View {
        VStack(spacing: ECSpacing.md) {
            if !items.isEmpty {
                HStack(spacing: ECSpacing.sm) {
                    Image(systemName: "drop.fill").font(.system(size: 24)).foregroundColor(themeManager.infoColor)
                    Text("\(totalVolume) ml").font(.ecH3).foregroundColor(themeManager.infoColor)
                    Text("Volume total").font(.ecCaption).foregroundColor(themeManager.textSecondary)
                }.frame(maxWidth: .infinity).padding(ECSpacing.md).background(themeManager.infoColor.opacity(0.15)).cornerRadius(ECRadius.md)
            }
            ForEach(items) { item in hydrationItemRow(item) }
            Button { showHydrationPicker = true } label: {
                HStack(spacing: ECSpacing.xs) { Image(systemName: "plus.circle"); Text("Ajouter hydratation") }
                    .font(.ecLabel).foregroundColor(themeManager.infoColor).frame(maxWidth: .infinity).padding(ECSpacing.md)
                    .background(RoundedRectangle(cornerRadius: ECRadius.md).strokeBorder(themeManager.infoColor.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5])))
            }
        }
        .sheet(isPresented: $showHydrationPicker) { HydrationPickerSheet { option, contentType in addHydration(option: option, contentType: contentType); showHydrationPicker = false }.environmentObject(themeManager) }
    }

    private func hydrationItemRow(_ item: HydrationItem) -> some View {
        HStack(spacing: ECSpacing.sm) {
            RoundedRectangle(cornerRadius: 3).fill(contentColor(for: item.type)).frame(width: 6, height: 36)
            VStack(alignment: .leading, spacing: 2) { Text("\(item.volume)ml").font(.ecLabel).foregroundColor(themeManager.textPrimary); Text(contentName(for: item.type)).font(.ecCaption).foregroundColor(themeManager.textSecondary) }
            Spacer()
            HStack(spacing: 0) {
                Button { updateQuantity(item.id, delta: -1) } label: { Image(systemName: "minus").font(.system(size: 14)).foregroundColor(themeManager.textPrimary).frame(width: 32, height: 32) }
                Text("\(item.quantity)").font(.ecLabel).foregroundColor(themeManager.textPrimary).frame(minWidth: 24)
                Button { updateQuantity(item.id, delta: 1) } label: { Image(systemName: "plus").font(.system(size: 14)).foregroundColor(themeManager.textPrimary).frame(width: 32, height: 32) }
            }.background(themeManager.cardColor).cornerRadius(ECRadius.md)
            Button { removeItem(item.id) } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(themeManager.errorColor) }
        }.padding(ECSpacing.sm).background(themeManager.elevatedColor).cornerRadius(ECRadius.md)
    }

    private func addHydration(option: HydrationOptionData, contentType: HydrationContentTypeData) {
        let newItem = HydrationItem(id: "\(option.id)-\(contentType.id)-\(Int(Date().timeIntervalSince1970 * 1000))", name: "\(option.name) - \(contentType.name)", type: contentType.id, quantity: 1, volume: option.volume)
        items.append(newItem)
    }
    private func removeItem(_ id: String) { items.removeAll { $0.id == id } }
    private func updateQuantity(_ id: String, delta: Int) { guard let index = items.firstIndex(where: { $0.id == id }) else { return }; items[index].quantity = max(1, items[index].quantity + delta) }
    private func contentColor(for content: String) -> Color { getContentTypeById(content)?.color ?? themeManager.infoColor }
    private func contentName(for content: String) -> String { getContentTypeById(content)?.name ?? content }
}

private struct HydrationPickerSheet: View {
    let onSelect: (HydrationOptionData, HydrationContentTypeData) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedOption: HydrationOptionData?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.md) {
                    if selectedOption == nil {
                        ForEach(hydrationOptionsData) { option in
                            Button { withAnimation { selectedOption = option } } label: {
                                HStack(spacing: ECSpacing.md) {
                                    Circle().fill(themeManager.infoColor.opacity(0.15)).frame(width: 48, height: 48).overlay(Image(systemName: option.icon).font(.system(size: 24)).foregroundColor(themeManager.infoColor))
                                    Text(option.name).font(.ecLabel).foregroundColor(themeManager.textPrimary); Spacer()
                                    Text("\(option.volume)ml").font(.ecBody).foregroundColor(themeManager.textSecondary)
                                    Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(themeManager.textTertiary)
                                }.padding(ECSpacing.md).background(themeManager.cardColor).cornerRadius(ECRadius.md)
                            }
                        }
                    } else if let option = selectedOption {
                        Text("\(option.name) (\(option.volume)ml)").font(.ecBody).foregroundColor(themeManager.textSecondary)
                        ForEach(hydrationContentTypesData) { contentType in
                            Button { onSelect(option, contentType) } label: {
                                HStack(spacing: ECSpacing.md) {
                                    Circle().fill(contentType.color).frame(width: 12, height: 12)
                                    Text(contentType.name).font(.ecLabel).foregroundColor(themeManager.textPrimary); Spacer()
                                    Image(systemName: "plus").font(.system(size: 20)).foregroundColor(themeManager.accentColor)
                                }.padding(ECSpacing.md).background(themeManager.cardColor).cornerRadius(ECRadius.md)
                            }
                        }
                    }
                }.padding(ECSpacing.md)
            }
            .background(themeManager.backgroundColor).navigationTitle(selectedOption == nil ? "Choisir un contenant" : "Type de contenu").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { if selectedOption != nil { Button { withAnimation { selectedOption = nil } } label: { Image(systemName: "arrow.left").foregroundColor(themeManager.textPrimary) } } }
                ToolbarItem(placement: .navigationBarTrailing) { Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(themeManager.textPrimary) } }
            }
        }
    }
}

// MARK: - Equipment Selector

private struct EquipmentCategoryConfig { let key: EquipmentCategory; let label: String; let icon: String; let sport: SportType }

private struct EquipmentSelectorView: View {
    let userId: String
    let discipline: Discipline
    @Binding var selectedEquipment: SessionEquipmentData
    @EnvironmentObject var themeManager: ThemeManager
    @State private var userEquipment: UserEquipment?
    @State private var isLoading = false
    @State private var showPicker = false
    @State private var selectedCategory: EquipmentCategoryConfig?

    private var categories: [EquipmentCategoryConfig] {
        switch discipline {
        case .cyclisme: return [EquipmentCategoryConfig(key: .bikes, label: "Vélo", icon: "bicycle", sport: .cycling), EquipmentCategoryConfig(key: .shoes, label: "Chaussures", icon: "shoeprint.fill", sport: .cycling)]
        case .course: return [EquipmentCategoryConfig(key: .shoes, label: "Chaussures", icon: "shoeprint.fill", sport: .running)]
        case .natation: return [EquipmentCategoryConfig(key: .suits, label: "Combinaison", icon: "figure.pool.swim", sport: .swimming)]
        case .autre: return []
        }
    }

    var body: some View {
        VStack(spacing: ECSpacing.xs) {
            if categories.isEmpty { EmptyView() }
            else if isLoading { HStack(spacing: ECSpacing.sm) { ProgressView(); Text("Chargement équipement...").font(.ecCaption).foregroundColor(themeManager.textSecondary) }.frame(maxWidth: .infinity).padding(ECSpacing.md) }
            else { ForEach(categories, id: \.key) { config in equipmentRow(for: config) } }
        }
        .task { await loadEquipment() }
        .sheet(isPresented: $showPicker) { if let config = selectedCategory { EquipmentPickerSheet(config: config, equipment: userEquipment, selectedId: getSelectedId(for: config.key), onSelect: { itemId in selectEquipment(category: config.key, itemId: itemId); showPicker = false }).environmentObject(themeManager) } }
    }

    private func equipmentRow(for config: EquipmentCategoryConfig) -> some View {
        Button { selectedCategory = config; showPicker = true } label: {
            HStack(spacing: ECSpacing.md) {
                Circle().fill(themeManager.accentColor.opacity(0.15)).frame(width: 40, height: 40).overlay(Image(systemName: config.icon).font(.system(size: 18)).foregroundColor(themeManager.accentColor))
                VStack(alignment: .leading, spacing: 2) {
                    Text(config.label).font(.ecCaption).foregroundColor(themeManager.textSecondary)
                    if let selectedItem = getSelectedItem(for: config) { Text("\(selectedItem.brand) \(selectedItem.name)").font(.ecLabel).foregroundColor(themeManager.textPrimary) }
                    else { Text(getCategoryItems(for: config).isEmpty ? "Aucun équipement" : "Non sélectionné").font(.ecBody).foregroundColor(themeManager.textTertiary).italic() }
                }
                Spacer(); Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(themeManager.textTertiary)
            }.padding(ECSpacing.md).background(themeManager.elevatedColor).cornerRadius(ECRadius.md)
        }
    }

    private func loadEquipment() async { guard !userId.isEmpty else { return }; isLoading = true; do { userEquipment = try await EquipmentService.shared.getEquipment(userId: userId) } catch { print("Error: \(error)") }; isLoading = false }
    private func selectEquipment(category: EquipmentCategory, itemId: String?) { switch category { case .bikes: selectedEquipment.bikes = itemId; case .shoes: selectedEquipment.shoes = itemId; case .suits: selectedEquipment.wetsuits = itemId; default: break } }
    private func getSelectedId(for category: EquipmentCategory) -> String? { switch category { case .bikes: return selectedEquipment.bikes; case .shoes: return selectedEquipment.shoes; case .suits: return selectedEquipment.wetsuits; default: return nil } }
    private func getCategoryItems(for config: EquipmentCategoryConfig) -> [EquipmentItem] { guard let equipment = userEquipment else { return [] }; return EquipmentService.shared.getItems(from: equipment, sport: config.sport, category: config.key).filter { $0.isActive } }
    private func getSelectedItem(for config: EquipmentCategoryConfig) -> EquipmentItem? { guard let selectedId = getSelectedId(for: config.key) else { return nil }; return getCategoryItems(for: config).first { $0.id == selectedId } }
}

private struct EquipmentPickerSheet: View {
    let config: EquipmentCategoryConfig
    let equipment: UserEquipment?
    let selectedId: String?
    let onSelect: (String?) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    private var items: [EquipmentItem] {
        guard let equipment = equipment else { return [] }
        return EquipmentService.shared.getItems(from: equipment, sport: config.sport, category: config.key).filter { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.sm) {
                    noneOptionButton
                    ForEach(items) { item in
                        equipmentItemButton(item)
                    }
                    if items.isEmpty {
                        emptyStateView
                    }
                }
                .padding(ECSpacing.md)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Sélectionner \(config.label.lowercased())")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundColor(themeManager.textPrimary)
                    }
                }
            }
        }
    }

    private var noneOptionButton: some View {
        let isSelected = selectedId == nil
        return Button { onSelect(nil) } label: {
            HStack(spacing: ECSpacing.md) {
                Circle()
                    .fill(themeManager.elevatedColor)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.textTertiary)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Aucun").font(.ecLabel).foregroundColor(themeManager.textPrimary)
                    Text("Ne pas enregistrer d'équipement").font(.ecCaption).foregroundColor(themeManager.textSecondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 24)).foregroundColor(themeManager.accentColor)
                }
            }
            .padding(ECSpacing.md)
            .background(isSelected ? themeManager.accentColor.opacity(0.1) : themeManager.cardColor)
            .overlay(RoundedRectangle(cornerRadius: ECRadius.md).stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 1))
            .cornerRadius(ECRadius.md)
        }
    }

    private func equipmentItemButton(_ item: EquipmentItem) -> some View {
        let isSelected = selectedId == item.id
        let brandName = item.brand ?? ""
        let modelName = item.model ?? ""
        let displayText = "\(brandName) \(item.name)".trimmingCharacters(in: .whitespaces)

        return Button { onSelect(item.id) } label: {
            HStack(spacing: ECSpacing.md) {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: config.icon)
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.accentColor)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayText).font(.ecLabel).foregroundColor(themeManager.textPrimary)
                    if !modelName.isEmpty {
                        Text(modelName).font(.ecCaption).foregroundColor(themeManager.textSecondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 24)).foregroundColor(themeManager.accentColor)
                }
            }
            .padding(ECSpacing.md)
            .background(isSelected ? themeManager.accentColor.opacity(0.1) : themeManager.cardColor)
            .overlay(RoundedRectangle(cornerRadius: ECRadius.md).stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 1))
            .cornerRadius(ECRadius.md)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: ECSpacing.md) {
            Image(systemName: "cube").font(.system(size: 48)).foregroundColor(themeManager.textTertiary)
            Text("Aucun équipement").font(.ecH4).foregroundColor(themeManager.textSecondary)
            Text("Ajoutez votre équipement dans les paramètres du profil")
                .font(.ecBody)
                .foregroundColor(themeManager.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, ECSpacing.xl * 2)
    }
}

struct NutritionStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(value)
                    .font(.ecBodyMedium)
                    .foregroundColor(themeManager.textPrimary)
            }
            Text(label)
                .font(.ecSmall)
                .foregroundColor(themeManager.textSecondary)
        }
    }
}

// MARK: - Map Content

import MapKit

struct SessionMapContent: View {
    let activity: Activity
    var preferences: SessionDisplayPreferences?
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var gpsPoints: [GPSPoint]?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var debugInfo: String = ""
    @State private var isIndoorActivity = false

    var body: some View {
        VStack(spacing: ECSpacing.md) {
            if isLoading {
                VStack(spacing: ECSpacing.sm) {
                    ProgressView()
                    Text("Chargement des données GPS...")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .background(themeManager.elevatedColor)
                .cornerRadius(ECRadius.lg)
            } else if let gpsPoints = gpsPoints, !gpsPoints.isEmpty {
                GPSMapView(
                    gpsPoints: gpsPoints,
                    discipline: activity.discipline,
                    mapType: preferences?.mapType ?? .standard,
                    colorizeTrace: preferences?.colorizeTrace ?? true,
                    traceMetric: preferences?.traceColorMetric ?? .heartRate
                )
                    .frame(height: 300)
                    .cornerRadius(ECRadius.lg)

                // Stats card
                GPSStatsCard(gpsPoints: gpsPoints)
            } else {
                VStack(spacing: ECSpacing.sm) {
                    Image(systemName: isIndoorActivity ? "house.fill" : "location.slash")
                        .font(.system(size: 40))
                        .foregroundColor(isIndoorActivity ? themeManager.accentColor.opacity(0.5) : themeManager.textTertiary)

                    if isIndoorActivity {
                        Text("Activité indoor")
                            .font(.ecBodyMedium)
                            .foregroundColor(themeManager.textPrimary)
                        Text("Cette séance a été effectuée en intérieur (home trainer, tapis de course, etc.) et ne dispose pas de données GPS.")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(errorMessage ?? "Aucune donnée GPS disponible")
                            .font(.ecBody)
                            .foregroundColor(themeManager.textSecondary)
                        Text("Cette activité ne contient pas de tracé GPS.")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textTertiary)
                            .multilineTextAlignment(.center)
                    }

                    #if DEBUG
                    if !debugInfo.isEmpty {
                        Text(debugInfo)
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.top, ECSpacing.sm)
                    }
                    #endif
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ECSpacing.xl)
                .padding(.horizontal, ECSpacing.md)
                .themedCard()
            }
        }
        .task {
            await loadGPSData()
        }
    }

    private func loadGPSData() async {
        // Détecter si c'est une activité indoor
        let sportLower = activity.sport?.lowercased() ?? ""
        isIndoorActivity = sportLower.contains("home trainer") ||
                          sportLower.contains("indoor") ||
                          sportLower.contains("tapis") ||
                          sportLower.contains("zwift") ||
                          sportLower.contains("trainer") ||
                          sportLower.contains("piscine")

        #if DEBUG
        print("🗺️ GPS: Starting load for activity: \(activity.id)")
        print("🗺️ GPS: Activity sport: \(activity.sport ?? "nil")")
        print("🗺️ GPS: Activity date: \(activity.dateStart)")
        print("🗺️ GPS: Is indoor: \(isIndoorActivity)")
        print("🗺️ GPS: Activity has fileDatas: \(activity.fileDatas != nil)")
        if let fileDatas = activity.fileDatas {
            print("🗺️ GPS: fileDatas.records count: \(fileDatas.records?.count ?? 0)")
            if let firstRecord = fileDatas.records?.first {
                print("🗺️ GPS: First record has lat: \(firstRecord.positionLat != nil), lng: \(firstRecord.positionLong != nil)")
                if let lat = firstRecord.positionLat, let lng = firstRecord.positionLong {
                    print("🗺️ GPS: First record coords: lat=\(lat), lng=\(lng)")
                }
            }
        }
        #endif

        // D'abord vérifier si les GPS points sont déjà chargés dans activity
        if let existingPoints = activity.gpsPoints, !existingPoints.isEmpty {
            #if DEBUG
            print("🗺️ GPS: Using existing \(existingPoints.count) points from activity")
            #endif
            self.gpsPoints = existingPoints
            isLoading = false
            return
        }

        // Vérifier directement les records dans fileDatas
        if let records = activity.fileDatas?.records, !records.isEmpty {
            #if DEBUG
            print("🗺️ GPS: Found \(records.count) records in fileDatas, converting...")
            let recordsWithGPS = records.filter { $0.positionLat != nil && $0.positionLong != nil }
            print("🗺️ GPS: Records with GPS coords: \(recordsWithGPS.count)/\(records.count)")
            #endif
            let points = convertRecordsToGPSPoints(records)
            if !points.isEmpty {
                #if DEBUG
                print("🗺️ GPS: Converted \(points.count) valid GPS points from fileDatas")
                #endif
                self.gpsPoints = points
                isLoading = false
                return
            } else {
                #if DEBUG
                debugInfo = "Records: \(records.count), GPS: 0"
                print("🗺️ GPS: No valid GPS points found in \(records.count) records")
                #endif
            }
        }

        // Sinon charger avec records=true via l'API
        guard let userId = authViewModel.user?.id else {
            #if DEBUG
            print("🗺️ GPS: No user ID")
            debugInfo = "User ID manquant"
            #endif
            isLoading = false
            return
        }

        guard let activityDate = activity.date else {
            #if DEBUG
            print("🗺️ GPS: Could not parse activity date from: \(activity.dateStart)")
            debugInfo = "Date invalide: \(activity.dateStart)"
            #endif
            isLoading = false
            return
        }

        #if DEBUG
        print("🗺️ GPS: Fetching from API for date: \(activityDate)")
        #endif

        do {
            let (recordData, fileData) = try await ActivitiesService.shared.getActivityGPSData(
                userId: userId,
                activityDate: activityDate,
                forceReload: true
            )

            #if DEBUG
            print("🗺️ GPS: API returned recordData: \(recordData?.count ?? 0) records")
            print("🗺️ GPS: API returned fileData: \(fileData != nil)")
            if let fileData = fileData {
                print("🗺️ GPS: fileData.records: \(fileData.records?.count ?? 0)")
            }
            if let records = recordData, let firstRecord = records.first {
                print("🗺️ GPS: API first record has lat: \(firstRecord.positionLat != nil), lng: \(firstRecord.positionLong != nil)")
            }
            #endif

            // Convertir les records en GPS points
            if let records = recordData, !records.isEmpty {
                #if DEBUG
                let recordsWithGPS = records.filter { $0.positionLat != nil && $0.positionLong != nil }
                print("🗺️ GPS: API Records with GPS coords: \(recordsWithGPS.count)/\(records.count)")
                #endif

                let points = convertRecordsToGPSPoints(records)

                if !points.isEmpty {
                    self.gpsPoints = points
                    #if DEBUG
                    print("✅ GPS: Converted to \(points.count) GPS points")
                    if let first = points.first {
                        print("✅ GPS: First point: \(first.latitude), \(first.longitude)")
                    }
                    #endif
                } else {
                    #if DEBUG
                    debugInfo = "API: \(records.count) records, 0 GPS"
                    print("🗺️ GPS: API returned records but no valid GPS coordinates")
                    #endif
                }
            } else {
                #if DEBUG
                debugInfo = "API: 0 records"
                print("🗺️ GPS: API returned no records")
                #endif
            }
        } catch {
            #if DEBUG
            print("❌ GPS Error: \(error)")
            debugInfo = "Erreur: \(error.localizedDescription)"
            #endif
            errorMessage = "Erreur de chargement GPS"
        }

        isLoading = false
    }

    private func convertRecordsToGPSPoints(_ records: [ActivityRecord]) -> [GPSPoint] {
        let semicircleToDegrees = 180.0 / pow(2.0, 31.0)

        return records.compactMap { record in
            guard let lat = record.positionLat, let lng = record.positionLong else { return nil }

            let latitude: Double
            let longitude: Double

            // Conversion semicircles -> degrés si nécessaire
            if abs(lat) > 180 || abs(lng) > 180 {
                latitude = lat * semicircleToDegrees
                longitude = lng * semicircleToDegrees
            } else {
                latitude = lat
                longitude = lng
            }

            // Validation des coordonnées
            guard latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180 else {
                return nil
            }

            return GPSPoint(latitude: latitude, longitude: longitude, altitude: record.altitude, timestamp: nil)
        }
    }
}

// MARK: - GPS Map View with MKMapView

struct GPSMapView: UIViewRepresentable {
    let gpsPoints: [GPSPoint]
    let discipline: Discipline
    var showMarkers: Bool = true
    var mapType: MapType = .standard
    var colorizeTrace: Bool = false
    var traceMetric: SessionMetric = .heartRate

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.showsScale = true
        updateMapType(mapView)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        updateMapType(mapView)
        
        // Clear existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        guard !gpsPoints.isEmpty else { return }

        // Decimate points for performance (max 400 points)
        let decimatedPoints = decimatePoints(gpsPoints, maxPoints: 400)

        // Create polyline coordinates
        let coordinates = decimatedPoints.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }

        // Add polyline overlay
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)

        // Add start and end markers
        if showMarkers, let first = coordinates.first, let last = coordinates.last {
            let startAnnotation = GPSAnnotation(coordinate: first, type: .start)
            let endAnnotation = GPSAnnotation(coordinate: last, type: .end)
            mapView.addAnnotations([startAnnotation, endAnnotation])
        }

        // Calculate and set the region
        let region = calculateRegion(from: coordinates)
        mapView.setRegion(region, animated: false)
        
        // Update coordinator with new props
        context.coordinator.discipline = discipline
        context.coordinator.colorizeTrace = colorizeTrace
        context.coordinator.traceMetric = traceMetric
    }
    
    private func updateMapType(_ mapView: MKMapView) {
        switch mapType {
        case .standard: mapView.mapType = .standard
        case .hybrid: mapView.mapType = .hybrid
        case .satellite: mapView.mapType = .satellite
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(discipline: discipline, colorizeTrace: colorizeTrace, traceMetric: traceMetric)
    }

    // Decimate points to improve performance
    private func decimatePoints(_ points: [GPSPoint], maxPoints: Int) -> [GPSPoint] {
        guard points.count > maxPoints else { return points }

        var result = [GPSPoint]()
        result.append(points.first!)

        let step = Double(points.count - 2) / Double(maxPoints - 2)
        for i in 1..<(maxPoints - 1) {
            let index = Int(Double(i) * step)
            result.append(points[index])
        }

        result.append(points.last!)
        return result
    }

    private func calculateRegion(from coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion()
        }

        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }

        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        // Add 20% margin
        let latDelta = max((maxLat - minLat) * 1.2, 0.01)
        let lonDelta = max((maxLon - minLon) * 1.2, 0.01)

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, MKMapViewDelegate {
        var discipline: Discipline
        var colorizeTrace: Bool
        var traceMetric: SessionMetric

        init(discipline: Discipline, colorizeTrace: Bool, traceMetric: SessionMetric) {
            self.discipline = discipline
            self.colorizeTrace = colorizeTrace
            self.traceMetric = traceMetric
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                
                if colorizeTrace {
                    switch traceMetric {
                    case .heartRate: renderer.strokeColor = UIColor(ThemeManager.shared.errorColor)
                    case .power: renderer.strokeColor = UIColor(ThemeManager.shared.warningColor)
                    case .speed: renderer.strokeColor = UIColor(ThemeManager.shared.infoColor)
                    case .elevation: renderer.strokeColor = UIColor(ThemeManager.shared.successColor)
                    default: renderer.strokeColor = UIColor(ThemeManager.shared.accentColor)
                    }
                } else {
                    renderer.strokeColor = UIColor(ThemeManager.shared.sportColor(for: discipline))
                }
                
                renderer.lineWidth = 3
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let gpsAnnotation = annotation as? GPSAnnotation else { return nil }

            let identifier = gpsAnnotation.type == .start ? "StartMarker" : "EndMarker"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            // Create marker view
            let markerSize: CGFloat = 28
            let markerView = UIView(frame: CGRect(x: 0, y: 0, width: markerSize, height: markerSize))
            markerView.layer.cornerRadius = markerSize / 2
            markerView.layer.borderWidth = 2
            markerView.layer.borderColor = UIColor.white.cgColor
            markerView.layer.shadowColor = UIColor.black.cgColor
            markerView.layer.shadowOffset = CGSize(width: 0, height: 2)
            markerView.layer.shadowOpacity = 0.25
            markerView.layer.shadowRadius = 4

            if gpsAnnotation.type == .start {
                markerView.backgroundColor = UIColor(ThemeManager.shared.successColor)
            } else {
                markerView.backgroundColor = UIColor(ThemeManager.shared.errorColor)
            }

            // Add icon
            let iconLabel = UILabel(frame: markerView.bounds)
            iconLabel.textAlignment = .center
            iconLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
            iconLabel.textColor = .white
            iconLabel.text = gpsAnnotation.type == .start ? "▶" : "◼"
            markerView.addSubview(iconLabel)

            // Convert to image
            let renderer = UIGraphicsImageRenderer(size: markerView.bounds.size)
            let image = renderer.image { _ in
                markerView.drawHierarchy(in: markerView.bounds, afterScreenUpdates: true)
            }

            annotationView?.image = image
            annotationView?.centerOffset = CGPoint(x: 0, y: -markerSize / 2)

            return annotationView
        }
    }
}

// MARK: - GPS Annotation

class GPSAnnotation: NSObject, MKAnnotation {
    enum AnnotationType {
        case start
        case end
    }

    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType

    var title: String? {
        type == .start ? "Départ" : "Arrivée"
    }

    init(coordinate: CLLocationCoordinate2D, type: AnnotationType) {
        self.coordinate = coordinate
        self.type = type
        super.init()
    }
}

struct GPSStatsCard: View {
    let gpsPoints: [GPSPoint]
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 0) {
            GPSStatItem(
                icon: "location.fill",
                value: "\(gpsPoints.count)",
                label: "Points GPS"
            )

            if let minAlt = gpsPoints.compactMap({ $0.altitude }).min(),
               let maxAlt = gpsPoints.compactMap({ $0.altitude }).max() {
                GPSStatItem(
                    icon: "arrow.down",
                    value: "\(Int(minAlt))m",
                    label: "Alt. min"
                )

                GPSStatItem(
                    icon: "arrow.up",
                    value: "\(Int(maxAlt))m",
                    label: "Alt. max"
                )
            }
        }
        .themedCard()
    }
}

struct GPSStatItem: View {
    let icon: String
    let value: String
    let label: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.accentColor)
                Text(value)
                    .font(.ecBodyMedium)
                    .foregroundColor(themeManager.textPrimary)
            }
            Text(label)
                .font(.ecSmall)
                .foregroundColor(themeManager.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(activity: Activity(
            id: "1",
            userId: "1",
            dateStart: "2025-11-27",
            sport: "Vélo - Route",
            name: "Sortie vélo matinale"
        ))
    }
    .environmentObject(ThemeManager.shared)
    .environmentObject(AuthViewModel())
}
