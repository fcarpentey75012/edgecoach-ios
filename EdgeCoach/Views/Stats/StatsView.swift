/**
 * Vue Statistiques - Analyses et métriques
 * Connectée à l'API backend /api/stats
 * Utilise ThemeManager pour les couleurs dynamiques
 */

import SwiftUI
import Charts

// MARK: - Stats API Response Models

struct StatsAPIResponse: Codable {
    let status: String
    let data: StatsAPIData
}

struct StatsAPIData: Codable {
    let period: String
    let startDate: String
    let endDate: String
    let summary: StatsAPISummary
    let byDiscipline: StatsAPIByDiscipline
    let performanceMetrics: StatsAPIPerformanceMetrics
    let evolution: [StatsAPIEvolutionPoint]

    enum CodingKeys: String, CodingKey {
        case period
        case startDate = "start_date"
        case endDate = "end_date"
        case summary
        case byDiscipline = "by_discipline"
        case performanceMetrics = "performance_metrics"
        case evolution
    }
}

struct StatsAPISummary: Codable {
    let totalDuration: Int
    let totalDistance: Double
    let totalCalories: Int
    let sessionsCount: Int

    enum CodingKeys: String, CodingKey {
        case totalDuration = "total_duration"
        case totalDistance = "total_distance"
        case totalCalories = "total_calories"
        case sessionsCount = "sessions_count"
    }
}

struct StatsAPIByDiscipline: Codable {
    let cyclisme: StatsAPIDisciplineData
    let course: StatsAPIDisciplineData
    let natation: StatsAPIDisciplineData
}

struct StatsAPIDisciplineData: Codable {
    let duration: Int
    let distance: Double
    let percentage: Int
}

struct StatsAPIPerformanceMetrics: Codable {
    let ftp: Int?
    let maxHr: Int?
    let vma: Double?
    let css: String?

    enum CodingKeys: String, CodingKey {
        case ftp
        case maxHr = "max_hr"
        case vma
        case css
    }
}

struct StatsAPIEvolutionPoint: Codable {
    let date: String
    let duration: Int
    let distance: Double
}

// MARK: - Stats View

struct StatsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    // Period Selector
                    PeriodSelector(
                        selectedPeriod: $viewModel.selectedPeriod
                    )

                    // Summary Cards
                    if let stats = viewModel.statsData {
                        SummaryCardsView(summary: stats.summary)
                    }

                    // Volume Chart
                    VolumeChartCard(viewModel: viewModel)

                    // TSS Chart
                    TSSChartCard(viewModel: viewModel)

                    // Discipline Distribution
                    DisciplineDistributionCard(viewModel: viewModel)

                    // Personal Records
                    if !viewModel.personalRecords.isEmpty {
                        PersonalRecordsCard(records: viewModel.personalRecords)
                    }

                    // Zones Distribution
                    ZonesDistributionCard(viewModel: viewModel)
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Statistiques")
            .refreshable {
                if let userId = authViewModel.user?.id {
                    await viewModel.refresh(userId: userId)
                }
            }
            .overlay {
                if viewModel.isLoading && viewModel.statsData == nil {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
        }
        .task {
            if let userId = authViewModel.user?.id {
                await viewModel.loadData(userId: userId)
            }
        }
    }
}

// MARK: - Summary Cards View

struct SummaryCardsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let summary: StatsSummaryData

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            SummaryCard(
                icon: "clock",
                iconColor: themeManager.accentColor,
                value: formatDuration(summary.totalDuration),
                label: "Temps"
            )
            SummaryCard(
                icon: "flame",
                iconColor: themeManager.errorColor,
                value: "\(summary.totalCalories)",
                label: "Calories"
            )
            SummaryCard(
                icon: "figure.run",
                iconColor: themeManager.successColor,
                value: "\(summary.sessionsCount)",
                label: "Séances"
            )
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h\(String(format: "%02d", minutes))"
        }
        return "\(minutes)min"
    }
}

struct SummaryCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: ECSpacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            Text(value)
                .font(.ecH4)
                .foregroundColor(themeManager.textPrimary)
            Text(label)
                .font(.ecCaption)
                .foregroundColor(themeManager.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Stats ViewModel

@MainActor
class StatsViewModel: ObservableObject {
    @Published var selectedPeriod: StatsPeriod = .month {
        didSet {
            if oldValue != selectedPeriod {
                Task { [weak self] in
                    guard let self = self, let userId = self.currentUserId else { return }
                    await self.loadData(userId: userId)
                }
            }
        }
    }
    @Published var statsData: StatsViewData?
    @Published var volumeData: [VolumeDataPoint] = []
    @Published var tssData: [TSSDataPoint] = []
    @Published var disciplineDistribution: [DisciplineShare] = []
    @Published var personalRecords: [PersonalRecord] = []
    @Published var zonesDistribution: [ZoneShare] = []
    @Published var isLoading = false

    private var currentUserId: String?
    private let api = APIService.shared

    func loadData(userId: String) async {
        currentUserId = userId
        isLoading = true

        #if DEBUG
        print("📊 [StatsViewModel] Loading data for period=\(selectedPeriod.apiValue), userId=\(userId)")
        #endif

        do {
            let params: [String: String] = [
                "user_id": userId,
                "period": selectedPeriod.apiValue
            ]

            let response: StatsAPIResponse = try await api.get("/stats", queryParams: params)
            let data = response.data

            #if DEBUG
            print("📊 [StatsViewModel] Received \(data.summary.sessionsCount) sessions, \(data.summary.totalDuration)s total")
            #endif

            // Convertir en données pour la vue
            statsData = StatsViewData(
                period: data.period,
                startDate: data.startDate,
                endDate: data.endDate,
                summary: StatsSummaryData(
                    totalDuration: data.summary.totalDuration,
                    totalDistance: data.summary.totalDistance,
                    totalCalories: data.summary.totalCalories,
                    sessionsCount: data.summary.sessionsCount
                )
            )

            // Convertir évolution en données de graphique
            volumeData = convertEvolutionToVolume(data.evolution)
            tssData = generateTSSFromEvolution(data.evolution)

            // Répartition par discipline
            disciplineDistribution = [
                DisciplineShare(
                    discipline: .cyclisme,
                    hours: Double(data.byDiscipline.cyclisme.duration) / 3600,
                    percentage: data.byDiscipline.cyclisme.percentage
                ),
                DisciplineShare(
                    discipline: .course,
                    hours: Double(data.byDiscipline.course.duration) / 3600,
                    percentage: data.byDiscipline.course.percentage
                ),
                DisciplineShare(
                    discipline: .natation,
                    hours: Double(data.byDiscipline.natation.duration) / 3600,
                    percentage: data.byDiscipline.natation.percentage
                )
            ].filter { $0.percentage > 0 }

            // Records depuis les métriques
            var records: [PersonalRecord] = []
            if let ftp = data.performanceMetrics.ftp {
                records.append(PersonalRecord(title: "FTP", value: "\(ftp) W", date: "", discipline: .cyclisme))
            }
            if let vma = data.performanceMetrics.vma {
                records.append(PersonalRecord(title: "VMA", value: String(format: "%.1f km/h", vma), date: "", discipline: .course))
            }
            if let css = data.performanceMetrics.css {
                records.append(PersonalRecord(title: "CSS", value: css, date: "", discipline: .natation))
            }
            personalRecords = records

            // Zones (statiques pour l'instant - les couleurs seront appliquées dynamiquement dans la vue)
            zonesDistribution = [
                ZoneShare(zone: 1, name: "Récupération", percentage: 15),
                ZoneShare(zone: 2, name: "Endurance", percentage: 45),
                ZoneShare(zone: 3, name: "Tempo", percentage: 20),
                ZoneShare(zone: 4, name: "Seuil", percentage: 12),
                ZoneShare(zone: 5, name: "VO2max", percentage: 8)
            ]

        } catch {
            #if DEBUG
            print("❌ [StatsViewModel] Error: \(error)")
            #endif
            // Données vides en cas d'erreur
            statsData = nil
            volumeData = []
            disciplineDistribution = []
        }

        isLoading = false
    }

    func refresh(userId: String) async {
        await loadData(userId: userId)
    }

    private func convertEvolutionToVolume(_ evolution: [StatsAPIEvolutionPoint]) -> [VolumeDataPoint] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return evolution.compactMap { point -> VolumeDataPoint? in
            guard let date = dateFormatter.date(from: point.date) else { return nil }
            return VolumeDataPoint(
                date: date,
                hours: Double(point.duration) / 3600
            )
        }
    }

    private func generateTSSFromEvolution(_ evolution: [StatsAPIEvolutionPoint]) -> [TSSDataPoint] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return evolution.compactMap { point -> TSSDataPoint? in
            guard let date = dateFormatter.date(from: point.date) else { return nil }
            let estimatedTSS = Int(Double(point.duration) / 3600 * 60)
            return TSSDataPoint(date: date, tss: estimatedTSS)
        }
    }
}

// MARK: - Data Models

struct StatsViewData {
    let period: String
    let startDate: String
    let endDate: String
    let summary: StatsSummaryData
}

struct StatsSummaryData {
    let totalDuration: Int
    let totalDistance: Double
    let totalCalories: Int
    let sessionsCount: Int
}

enum StatsPeriod: String, CaseIterable {
    case week = "Semaine"
    case month = "Mois"
    case quarter = "Trimestre"
    case year = "Année"

    var apiValue: String {
        switch self {
        case .week: return "week"
        case .month: return "month"
        case .quarter: return "month"
        case .year: return "year"
        }
    }
}

struct VolumeDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let hours: Double
}

struct TSSDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let tss: Int
}

struct DisciplineShare: Identifiable {
    let id = UUID()
    let discipline: Discipline
    let hours: Double
    let percentage: Int
}

struct PersonalRecord: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let date: String
    let discipline: Discipline
}

struct ZoneShare: Identifiable {
    let id = UUID()
    let zone: Int
    let name: String
    let percentage: Int
}

// MARK: - Period Selector

struct PeriodSelector: View {
    @Binding var selectedPeriod: StatsPeriod

    var body: some View {
        Picker("Période", selection: $selectedPeriod) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - Volume Chart Card

struct VolumeChartCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(themeManager.accentColor)
                Text("Volume d'entraînement")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
            }

            if #available(iOS 16.0, *) {
                if viewModel.volumeData.isEmpty {
                    Text("Aucune donnée pour cette période")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                } else {
                    Chart(viewModel.volumeData) { dataPoint in
                        BarMark(
                            x: .value("Date", dataPoint.date, unit: .day),
                            y: .value("Heures", dataPoint.hours)
                        )
                        .foregroundStyle(themeManager.accentColor.gradient)
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month(), centered: true)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let hours = value.as(Double.self) {
                                    Text("\(Int(hours))h")
                                        .font(.ecSmall)
                                }
                            }
                        }
                    }
                }
            } else {
                Text("iOS 16+ requis pour les graphiques")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
                    .frame(height: 200)
            }

            // Summary
            HStack(spacing: ECSpacing.lg) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                    Text("\(String(format: "%.1f", viewModel.volumeData.reduce(0) { $0 + $1.hours }))h")
                        .font(.ecH4)
                        .foregroundColor(themeManager.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Moyenne/jour")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                    let avg = viewModel.volumeData.isEmpty ? 0 : viewModel.volumeData.reduce(0) { $0 + $1.hours } / Double(viewModel.volumeData.count)
                    Text("\(String(format: "%.1f", avg))h")
                        .font(.ecH4)
                        .foregroundColor(themeManager.textPrimary)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - TSS Chart Card

struct TSSChartCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "bolt")
                    .foregroundColor(themeManager.warningColor)
                Text("Charge d'entraînement (TSS)")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
            }

            if #available(iOS 16.0, *) {
                if viewModel.tssData.isEmpty {
                    Text("Aucune donnée pour cette période")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                } else {
                    Chart(viewModel.tssData) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date, unit: .day),
                            y: .value("TSS", dataPoint.tss)
                        )
                        .foregroundStyle(themeManager.warningColor)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", dataPoint.date, unit: .day),
                            y: .value("TSS", dataPoint.tss)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeManager.warningColor.opacity(0.3), themeManager.warningColor.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 180)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month(), centered: true)
                        }
                    }
                }
            } else {
                Text("iOS 16+ requis pour les graphiques")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
                    .frame(height: 180)
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Discipline Distribution Card

struct DisciplineDistributionCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "chart.pie")
                    .foregroundColor(themeManager.accentColor)
                Text("Répartition par sport")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
            }

            if viewModel.disciplineDistribution.isEmpty {
                Text("Aucune donnée pour cette période")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                HStack(spacing: ECSpacing.lg) {
                    // Donut Chart
                    if #available(iOS 17.0, *) {
                        Chart(viewModel.disciplineDistribution) { share in
                            SectorMark(
                                angle: .value("Heures", share.hours),
                                innerRadius: .ratio(0.6),
                                angularInset: 2
                            )
                            .foregroundStyle(themeManager.sportColor(for: share.discipline))
                            .cornerRadius(4)
                        }
                        .frame(width: 120, height: 120)
                    } else {
                        DonutChartFallback(data: viewModel.disciplineDistribution)
                            .frame(width: 120, height: 120)
                    }

                    // Legend
                    VStack(alignment: .leading, spacing: ECSpacing.sm) {
                        ForEach(viewModel.disciplineDistribution) { share in
                            HStack(spacing: ECSpacing.sm) {
                                Circle()
                                    .fill(themeManager.sportColor(for: share.discipline))
                                    .frame(width: 10, height: 10)

                                Text(share.discipline.displayName)
                                    .font(.ecCaption)
                                    .foregroundColor(themeManager.textPrimary)

                                Spacer()

                                Text("\(share.percentage)%")
                                    .font(.ecCaptionBold)
                                    .foregroundColor(themeManager.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
    }
}

struct DonutChartFallback: View {
    @EnvironmentObject var themeManager: ThemeManager
    let data: [DisciplineShare]

    var body: some View {
        ZStack {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, share in
                Circle()
                    .trim(from: startAngle(for: index), to: endAngle(for: index))
                    .stroke(themeManager.sportColor(for: share.discipline), lineWidth: 20)
                    .rotationEffect(.degrees(-90))
            }
        }
    }

    private func startAngle(for index: Int) -> CGFloat {
        let total = data.reduce(0) { $0 + $1.hours }
        let preceding = data.prefix(index).reduce(0) { $0 + $1.hours }
        return CGFloat(preceding / total)
    }

    private func endAngle(for index: Int) -> CGFloat {
        let total = data.reduce(0) { $0 + $1.hours }
        let upTo = data.prefix(index + 1).reduce(0) { $0 + $1.hours }
        return CGFloat(upTo / total)
    }
}

// MARK: - Personal Records Card

struct PersonalRecordsCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let records: [PersonalRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "trophy")
                    .foregroundColor(themeManager.warningColor)
                Text("Records personnels")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
            }

            ForEach(records) { record in
                HStack(spacing: ECSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(themeManager.sportColor(for: record.discipline).opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: record.discipline.icon)
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.sportColor(for: record.discipline))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.title)
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textPrimary)
                        if !record.date.isEmpty {
                            Text(record.date)
                                .font(.ecSmall)
                                .foregroundColor(themeManager.textSecondary)
                        }
                    }

                    Spacer()

                    Text(record.value)
                        .font(.ecH4)
                        .foregroundColor(themeManager.accentColor)
                }

                if record.id != records.last?.id {
                    Divider()
                        .background(themeManager.borderColor)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Zones Distribution Card

struct ZonesDistributionCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: StatsViewModel

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

            VStack(spacing: ECSpacing.sm) {
                ForEach(viewModel.zonesDistribution) { zone in
                    HStack(spacing: ECSpacing.sm) {
                        Text("Z\(zone.zone)")
                            .font(.ecCaptionBold)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(themeManager.zoneColor(for: zone.zone))
                            .cornerRadius(6)

                        Text(zone.name)
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textPrimary)
                            .frame(width: 80, alignment: .leading)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(themeManager.surfaceColor)
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(themeManager.zoneColor(for: zone.zone))
                                    .frame(width: geometry.size.width * CGFloat(zone.percentage) / 100, height: 8)
                            }
                        }
                        .frame(height: 8)

                        Text("\(zone.percentage)%")
                            .font(.ecCaptionBold)
                            .foregroundColor(themeManager.textSecondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
    }
}

#Preview {
    StatsView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager.shared)
}
