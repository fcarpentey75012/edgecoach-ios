/**
 * Écran des zones d'entraînement
 * Affiche les zones de FC, puissance et allure par sport
 */

import SwiftUI

struct ZonesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var selectedSport: SportType = .running
    @State private var metrics: UserMetricsData?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(error)
                } else {
                    contentView
                }
            }
            .navigationTitle("Zones d'entraînement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.ecSecondary)
                    }
                }
            }
        }
        .task {
            await loadMetrics()
        }
    }

    // MARK: - Views

    private var loadingView: some View {
        VStack(spacing: ECSpacing.md) {
            ProgressView()
            Text("Chargement des zones...")
                .font(.ecBody)
                .foregroundColor(.ecGray500)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: ECSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.ecError)

            Text("Erreur")
                .font(.ecH4)
                .foregroundColor(.ecError)

            Text(message)
                .font(.ecBody)
                .foregroundColor(.ecGray500)
                .multilineTextAlignment(.center)

            Button("Réessayer") {
                Task { await loadMetrics() }
            }
            .buttonStyle(.ecPrimary())
        }
        .padding()
    }

    private var contentView: some View {
        ScrollView {
            VStack(spacing: ECSpacing.lg) {
                // Sport Selector
                sportSelector

                // Reference Value
                if let refValue = getRefValue() {
                    refValueCard(refValue)
                }

                // Zones List
                zonesListView

                // Info Card
                infoCard
            }
            .padding()
        }
        .background(Color.ecBackground)
        .refreshable {
            await loadMetrics(forceRefresh: true)
        }
    }

    private var sportSelector: some View {
        HStack(spacing: ECSpacing.sm) {
            ForEach(SportType.allCases) { sport in
                let hasData = hasSportData(sport)

                Button {
                    if hasData {
                        selectedSport = sport
                    }
                } label: {
                    VStack(spacing: ECSpacing.xs) {
                        Image(systemName: sport.icon)
                            .font(.system(size: 24))

                        Text(sport.label)
                            .font(.ecCaption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ECSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: ECRadius.md)
                            .fill(selectedSport == sport ? sport.color.opacity(0.1) : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: ECRadius.md)
                            .stroke(selectedSport == sport ? sport.color : Color.clear, lineWidth: 2)
                    )
                    .foregroundColor(selectedSport == sport ? sport.color : (hasData ? .ecGray500 : .ecGray300))
                    .opacity(hasData ? 1 : 0.5)
                }
                .disabled(!hasData)
                .overlay(alignment: .topTrailing) {
                    if !hasData {
                        Text("N/A")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.ecGray500)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.ecGray200)
                            .cornerRadius(4)
                            .offset(x: -4, y: 4)
                    }
                }
            }
        }
    }

    private func refValueCard(_ value: (label: String, value: String)) -> some View {
        HStack {
            Text(value.label)
                .font(.ecLabel)
                .foregroundColor(.ecGray600)

            Spacer()

            Text(value.value)
                .font(.ecH3)
                .fontWeight(.bold)
                .foregroundColor(selectedSport.color)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(ECRadius.md)
        .overlay(
            Rectangle()
                .fill(selectedSport.color)
                .frame(width: 4),
            alignment: .leading
        )
        .clipShape(RoundedRectangle(cornerRadius: ECRadius.md))
    }

    @ViewBuilder
    private var zonesListView: some View {
        let zones = getCurrentZones()
        if !zones.isEmpty {
            VStack(spacing: ECSpacing.sm) {
                switch selectedSport {
                case .running:
                    ForEach(zones.compactMap { $0 as? HeartRateZone }) { zone in
                        runningZoneCard(zone)
                    }
                case .cycling:
                    ForEach(zones.compactMap { $0 as? PowerZone }) { zone in
                        cyclingZoneCard(zone)
                    }
                case .swimming:
                    ForEach(zones.compactMap { $0 as? PaceZone }) { zone in
                        swimmingZoneCard(zone)
                    }
                }
            }
        } else {
            emptyZonesView
        }
    }

    private func getCurrentZones() -> [Any] {
        guard let zones = metrics?.sportsZones else { return [] }

        switch selectedSport {
        case .running:
            return zones.running?.heartRateZones ?? []
        case .cycling:
            return zones.cycling?.powerZones ?? []
        case .swimming:
            return zones.swimming?.paceZones ?? []
        }
    }

    private var emptyZonesView: some View {
        VStack(spacing: ECSpacing.md) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 48))
                .foregroundColor(.ecGray300)

            Text("Aucune zone définie")
                .font(.ecH4)
                .foregroundColor(.ecGray500)

            Text("Les zones d'entraînement pour ce sport n'ont pas encore été calculées.")
                .font(.ecBody)
                .foregroundColor(.ecGray400)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, ECSpacing.xl)
    }

    private func runningZoneCard(_ zone: HeartRateZone) -> some View {
        HStack(spacing: 0) {
            // Zone Indicator
            VStack {
                Text("Z\(zone.zone)")
                    .font(.ecLabel)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 48)
            .frame(maxHeight: .infinity)
            .background(Color(hex: zone.color))

            // Zone Content
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text(zone.name)
                    .font(.ecLabel)
                    .foregroundColor(.ecSecondary)

                HStack(spacing: ECSpacing.md) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.ecError)
                        Text("\(zone.min) - \(zone.max) bpm")
                            .font(.ecCaption)
                            .foregroundColor(.ecSecondary500)
                    }

                    if let pace = zone.pace, !pace.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "speedometer")
                                .font(.system(size: 12))
                                .foregroundColor(.ecPrimary)
                            Text(pace)
                                .font(.ecCaption)
                                .foregroundColor(.ecSecondary500)
                        }
                    }
                }

                Text(zone.description)
                    .font(.ecCaption)
                    .foregroundColor(.ecGray500)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .cornerRadius(ECRadius.md)
    }

    private func cyclingZoneCard(_ zone: PowerZone) -> some View {
        HStack(spacing: 0) {
            // Zone Indicator
            VStack {
                Text("Z\(zone.zone)")
                    .font(.ecLabel)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 48)
            .frame(maxHeight: .infinity)
            .background(Color(hex: zone.color))

            // Zone Content
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text(zone.name)
                    .font(.ecLabel)
                    .foregroundColor(.ecSecondary)

                HStack(spacing: ECSpacing.md) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.ecWarning)
                        Text("\(zone.min) - \(zone.max) W")
                            .font(.ecCaption)
                            .foregroundColor(.ecSecondary500)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 12))
                            .foregroundColor(.ecPrimary)
                        Text(zone.percentage)
                            .font(.ecCaption)
                            .foregroundColor(.ecSecondary500)
                    }
                }

                Text(zone.description)
                    .font(.ecCaption)
                    .foregroundColor(.ecGray500)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .cornerRadius(ECRadius.md)
    }

    private func swimmingZoneCard(_ zone: PaceZone) -> some View {
        HStack(spacing: 0) {
            // Zone Indicator
            VStack {
                Text("Z\(zone.zone)")
                    .font(.ecLabel)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 48)
            .frame(maxHeight: .infinity)
            .background(Color(hex: zone.color))

            // Zone Content
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text(zone.name)
                    .font(.ecLabel)
                    .foregroundColor(.ecSecondary)

                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 12))
                        .foregroundColor(.ecSportNatation)
                    Text("\(zone.pace) /100m")
                        .font(.ecCaption)
                        .foregroundColor(.ecSecondary500)
                }

                Text(zone.description)
                    .font(.ecCaption)
                    .foregroundColor(.ecGray500)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .cornerRadius(ECRadius.md)
    }

    private var infoCard: some View {
        HStack(alignment: .top, spacing: ECSpacing.sm) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.ecPrimary)

            Text("Les zones sont calculées automatiquement à partir de vos données d'entraînement et tests de terrain.")
                .font(.ecCaption)
                .foregroundColor(.ecPrimary700)
        }
        .padding()
        .background(Color.ecPrimary.opacity(0.1))
        .cornerRadius(ECRadius.md)
    }

    // MARK: - Data Methods

    private func loadMetrics(forceRefresh: Bool = false) async {
        guard let userId = authViewModel.user?.id else {
            error = "Utilisateur non connecté"
            isLoading = false
            return
        }

        isLoading = true
        error = nil

        do {
            if forceRefresh {
                metrics = try await MetricsService.shared.refreshMetrics(userId: userId)
            } else {
                metrics = try await MetricsService.shared.getMetrics(userId: userId)
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func hasSportData(_ sport: SportType) -> Bool {
        guard let zones = metrics?.sportsZones else { return false }

        switch sport {
        case .running: return zones.running != nil
        case .cycling: return zones.cycling != nil
        case .swimming: return zones.swimming != nil
        }
    }

    private func getRefValue() -> (label: String, value: String)? {
        guard let zones = metrics?.sportsZones else { return nil }

        switch selectedSport {
        case .running:
            if let running = zones.running {
                return ("FC Seuil", "\(running.lactateThresholdHr) bpm")
            }
        case .cycling:
            if let cycling = zones.cycling {
                return ("FTP", "\(cycling.ftp) W")
            }
        case .swimming:
            if let swimming = zones.swimming {
                return ("CSS", swimming.cssPace)
            }
        }
        return nil
    }
}

#Preview {
    ZonesView()
        .environmentObject(AuthViewModel())
}
