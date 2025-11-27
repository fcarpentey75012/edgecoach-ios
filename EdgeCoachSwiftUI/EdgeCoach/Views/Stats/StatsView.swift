/**
 * Vue Statistiques - Analyses et métriques
 */

import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    // Period Selector
                    PeriodSelector(
                        selectedPeriod: $viewModel.selectedPeriod
                    )

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
            .background(Color.ecBackground)
            .navigationTitle("Statistiques")
            .refreshable {
                if let userId = authViewModel.user?.id {
                    await viewModel.refresh(userId: userId)
                }
            }
            .overlay {
                if viewModel.isLoading && viewModel.volumeData.isEmpty {
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

// MARK: - Stats ViewModel

@MainActor
class StatsViewModel: ObservableObject {
    @Published var selectedPeriod: StatsPeriod = .month
    @Published var volumeData: [VolumeDataPoint] = []
    @Published var tssData: [TSSDataPoint] = []
    @Published var disciplineDistribution: [DisciplineShare] = []
    @Published var personalRecords: [PersonalRecord] = []
    @Published var zonesDistribution: [ZoneShare] = []
    @Published var isLoading = false

    func loadData(userId: String) async {
        isLoading = true
        // Simuler le chargement des données
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Données de démonstration
        volumeData = generateVolumeData()
        tssData = generateTSSData()
        disciplineDistribution = [
            DisciplineShare(discipline: .cyclisme, hours: 12.5, percentage: 55),
            DisciplineShare(discipline: .course, hours: 6.0, percentage: 26),
            DisciplineShare(discipline: .natation, hours: 3.5, percentage: 15),
            DisciplineShare(discipline: .autre, hours: 1.0, percentage: 4)
        ]
        personalRecords = [
            PersonalRecord(title: "FTP", value: "285 W", date: "15 Nov 2024", discipline: .cyclisme),
            PersonalRecord(title: "VMA", value: "18.5 km/h", date: "10 Nov 2024", discipline: .course),
            PersonalRecord(title: "CSS", value: "1:45/100m", date: "8 Nov 2024", discipline: .natation)
        ]
        zonesDistribution = [
            ZoneShare(zone: 1, name: "Récupération", percentage: 15, color: .ecZone1),
            ZoneShare(zone: 2, name: "Endurance", percentage: 45, color: .ecZone2),
            ZoneShare(zone: 3, name: "Tempo", percentage: 20, color: .ecZone3),
            ZoneShare(zone: 4, name: "Seuil", percentage: 12, color: .ecZone4),
            ZoneShare(zone: 5, name: "VO2max", percentage: 8, color: .ecZone5)
        ]

        isLoading = false
    }

    func refresh(userId: String) async {
        await loadData(userId: userId)
    }

    private func generateVolumeData() -> [VolumeDataPoint] {
        let calendar = Calendar.current
        var data: [VolumeDataPoint] = []
        for i in (0..<12).reversed() {
            if let date = calendar.date(byAdding: .weekOfYear, value: -i, to: Date()) {
                data.append(VolumeDataPoint(
                    date: date,
                    hours: Double.random(in: 5...15)
                ))
            }
        }
        return data
    }

    private func generateTSSData() -> [TSSDataPoint] {
        let calendar = Calendar.current
        var data: [TSSDataPoint] = []
        for i in (0..<12).reversed() {
            if let date = calendar.date(byAdding: .weekOfYear, value: -i, to: Date()) {
                data.append(TSSDataPoint(
                    date: date,
                    tss: Int.random(in: 200...600)
                ))
            }
        }
        return data
    }
}

// MARK: - Data Models

enum StatsPeriod: String, CaseIterable {
    case week = "Semaine"
    case month = "Mois"
    case quarter = "Trimestre"
    case year = "Année"
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
    let color: Color
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
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.ecPrimary)
                Text("Volume d'entraînement")
                    .font(.ecLabelBold)
                    .foregroundColor(.ecSecondary800)
                Spacer()
            }

            if #available(iOS 16.0, *) {
                Chart(viewModel.volumeData) { dataPoint in
                    BarMark(
                        x: .value("Semaine", dataPoint.date, unit: .weekOfYear),
                        y: .value("Heures", dataPoint.hours)
                    )
                    .foregroundStyle(Color.ecPrimary.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.week(), centered: true)
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
            } else {
                Text("iOS 16+ requis pour les graphiques")
                    .font(.ecCaption)
                    .foregroundColor(.ecGray500)
                    .frame(height: 200)
            }

            // Summary
            HStack(spacing: ECSpacing.lg) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total")
                        .font(.ecCaption)
                        .foregroundColor(.ecGray500)
                    Text("\(String(format: "%.1f", viewModel.volumeData.reduce(0) { $0 + $1.hours }))h")
                        .font(.ecH4)
                        .foregroundColor(.ecSecondary800)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Moyenne/sem")
                        .font(.ecCaption)
                        .foregroundColor(.ecGray500)
                    let avg = viewModel.volumeData.isEmpty ? 0 : viewModel.volumeData.reduce(0) { $0 + $1.hours } / Double(viewModel.volumeData.count)
                    Text("\(String(format: "%.1f", avg))h")
                        .font(.ecH4)
                        .foregroundColor(.ecSecondary800)
                }
            }
        }
        .ecCard()
    }
}

// MARK: - TSS Chart Card

struct TSSChartCard: View {
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "bolt")
                    .foregroundColor(.ecWarning)
                Text("Charge d'entraînement (TSS)")
                    .font(.ecLabelBold)
                    .foregroundColor(.ecSecondary800)
                Spacer()
            }

            if #available(iOS 16.0, *) {
                Chart(viewModel.tssData) { dataPoint in
                    LineMark(
                        x: .value("Semaine", dataPoint.date, unit: .weekOfYear),
                        y: .value("TSS", dataPoint.tss)
                    )
                    .foregroundStyle(Color.ecWarning)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Semaine", dataPoint.date, unit: .weekOfYear),
                        y: .value("TSS", dataPoint.tss)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.ecWarning.opacity(0.3), Color.ecWarning.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.week(), centered: true)
                    }
                }
            } else {
                Text("iOS 16+ requis pour les graphiques")
                    .font(.ecCaption)
                    .foregroundColor(.ecGray500)
                    .frame(height: 180)
            }
        }
        .ecCard()
    }
}

// MARK: - Discipline Distribution Card

struct DisciplineDistributionCard: View {
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "chart.pie")
                    .foregroundColor(.ecPrimary)
                Text("Répartition par sport")
                    .font(.ecLabelBold)
                    .foregroundColor(.ecSecondary800)
                Spacer()
            }

            HStack(spacing: ECSpacing.lg) {
                // Donut Chart
                if #available(iOS 17.0, *) {
                    Chart(viewModel.disciplineDistribution) { share in
                        SectorMark(
                            angle: .value("Heures", share.hours),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(Color.sportColor(for: share.discipline))
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
                                .fill(Color.sportColor(for: share.discipline))
                                .frame(width: 10, height: 10)

                            Text(share.discipline.displayName)
                                .font(.ecCaption)
                                .foregroundColor(.ecSecondary800)

                            Spacer()

                            Text("\(share.percentage)%")
                                .font(.ecCaptionBold)
                                .foregroundColor(.ecGray500)
                        }
                    }
                }
            }
        }
        .ecCard()
    }
}

struct DonutChartFallback: View {
    let data: [DisciplineShare]

    var body: some View {
        ZStack {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, share in
                Circle()
                    .trim(from: startAngle(for: index), to: endAngle(for: index))
                    .stroke(Color.sportColor(for: share.discipline), lineWidth: 20)
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
    let records: [PersonalRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "trophy")
                    .foregroundColor(.ecWarning)
                Text("Records personnels")
                    .font(.ecLabelBold)
                    .foregroundColor(.ecSecondary800)
                Spacer()
            }

            ForEach(records) { record in
                HStack(spacing: ECSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.sportColor(for: record.discipline).opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: record.discipline.icon)
                            .font(.system(size: 16))
                            .foregroundColor(Color.sportColor(for: record.discipline))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.title)
                            .font(.ecLabel)
                            .foregroundColor(.ecSecondary800)
                        Text(record.date)
                            .font(.ecSmall)
                            .foregroundColor(.ecGray500)
                    }

                    Spacer()

                    Text(record.value)
                        .font(.ecH4)
                        .foregroundColor(.ecPrimary)
                }

                if record.id != records.last?.id {
                    Divider()
                }
            }
        }
        .ecCard()
    }
}

// MARK: - Zones Distribution Card

struct ZonesDistributionCard: View {
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.ecError)
                Text("Temps dans les zones")
                    .font(.ecLabelBold)
                    .foregroundColor(.ecSecondary800)
                Spacer()
            }

            VStack(spacing: ECSpacing.sm) {
                ForEach(viewModel.zonesDistribution) { zone in
                    HStack(spacing: ECSpacing.sm) {
                        Text("Z\(zone.zone)")
                            .font(.ecCaptionBold)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(zone.color)
                            .cornerRadius(6)

                        Text(zone.name)
                            .font(.ecCaption)
                            .foregroundColor(.ecSecondary800)
                            .frame(width: 80, alignment: .leading)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.ecGray100)
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(zone.color)
                                    .frame(width: geometry.size.width * CGFloat(zone.percentage) / 100, height: 8)
                            }
                        }
                        .frame(height: 8)

                        Text("\(zone.percentage)%")
                            .font(.ecCaptionBold)
                            .foregroundColor(.ecGray500)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .ecCard()
    }
}

#Preview {
    StatsView()
        .environmentObject(AuthViewModel())
}
