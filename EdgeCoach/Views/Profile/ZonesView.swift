/**
 * Écran des zones d'entraînement
 * Affiche les zones de FC, puissance et allure par sport
 * Utilise ThemeManager pour les couleurs dynamiques
 */

import SwiftUI

struct ZonesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager

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
                            .foregroundColor(themeManager.textSecondary)
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
                .foregroundColor(themeManager.textSecondary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: ECSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(themeManager.errorColor)

            Text("Erreur")
                .font(.ecH4)
                .foregroundColor(themeManager.errorColor)

            Text(message)
                .font(.ecBody)
                .foregroundColor(themeManager.textSecondary)
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
        .background(themeManager.backgroundColor)
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
                            .fill(selectedSport == sport ? themeManager.sportColor(for: sport.discipline).opacity(0.1) : themeManager.cardColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: ECRadius.md)
                            .stroke(selectedSport == sport ? themeManager.sportColor(for: sport.discipline) : Color.clear, lineWidth: 2)
                    )
                    .foregroundColor(selectedSport == sport ? themeManager.sportColor(for: sport.discipline) : (hasData ? themeManager.textSecondary : themeManager.textTertiary))
                    .opacity(hasData ? 1 : 0.5)
                }
                .disabled(!hasData)
                .overlay(alignment: .topTrailing) {
                    if !hasData {
                        Text("N/A")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(themeManager.textSecondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(themeManager.surfaceColor)
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
                .foregroundColor(themeManager.textSecondary)

            Spacer()

            Text(value.value)
                .font(.ecH3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.sportColor(for: selectedSport.discipline))
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.md)
        .overlay(
            Rectangle()
                .fill(themeManager.sportColor(for: selectedSport.discipline))
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
                .foregroundColor(themeManager.textTertiary)

            Text("Aucune zone définie")
                .font(.ecH4)
                .foregroundColor(themeManager.textSecondary)

            Text("Les zones d'entraînement pour ce sport n'ont pas encore été calculées.")
                .font(.ecBody)
                .foregroundColor(themeManager.textTertiary)
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
                    .foregroundColor(themeManager.textPrimary)

                HStack(spacing: ECSpacing.md) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.errorColor)
                        Text("\(zone.min) - \(zone.max) bpm")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    if let pace = zone.pace, !pace.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "speedometer")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.accentColor)
                            Text(pace)
                                .font(.ecCaption)
                                .foregroundColor(themeManager.textSecondary)
                        }
                    }
                }

                Text(zone.description)
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(themeManager.cardColor)
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
                    .foregroundColor(themeManager.textPrimary)

                HStack(spacing: ECSpacing.md) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.warningColor)
                        Text("\(zone.min) - \(zone.max) W")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.accentColor)
                        Text(zone.percentage)
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }

                Text(zone.description)
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(themeManager.cardColor)
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
                    .foregroundColor(themeManager.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.sportColor(for: .natation))
                    Text("\(zone.pace) /100m")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }

                Text(zone.description)
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.md)
    }

    private var infoCard: some View {
        HStack(alignment: .top, spacing: ECSpacing.sm) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(themeManager.accentColor)

            Text("Les zones sont calculées automatiquement à partir de vos données d'entraînement et tests de terrain.")
                .font(.ecCaption)
                .foregroundColor(themeManager.accentColor)
        }
        .padding()
        .background(themeManager.accentColor.opacity(0.1))
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
        .environmentObject(ThemeManager.shared)
}
