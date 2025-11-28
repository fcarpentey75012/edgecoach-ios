/**
 * Service Metrics pour EdgeCoach iOS
 * Gestion des métriques d'entraînement (zones, FC, FTP, etc.)
 */

import Foundation
import SwiftUI

// MARK: - Zone Models

struct HeartRateZone: Identifiable, Codable {
    var id: Int { zone }
    let zone: Int
    let name: String
    let min: Int
    let max: Int
    let pace: String?
    let color: String
    let description: String
}

struct PowerZone: Identifiable, Codable {
    var id: Int { zone }
    let zone: Int
    let name: String
    let min: Int
    let max: Int
    let percentage: String
    let color: String
    let description: String
}

struct PaceZone: Identifiable, Codable {
    var id: Int { zone }
    let zone: Int
    let name: String
    let pace: String
    let color: String
    let description: String
}

// MARK: - Sports Zones

struct RunningZones: Codable {
    let lactateThresholdHr: Int
    let thresholdPace: String?
    let heartRateZones: [HeartRateZone]
}

struct CyclingZones: Codable {
    let ftp: Int
    let powerZones: [PowerZone]
}

struct SwimmingZones: Codable {
    let cssPace: String
    let paceZones: [PaceZone]
}

struct SportsZones: Codable {
    let running: RunningZones?
    let cycling: CyclingZones?
    let swimming: SwimmingZones?
}

// MARK: - User Metrics

struct UserMetricsData: Codable, Identifiable {
    let id: String
    let userId: String
    let weight: Double?
    let restingHr: Int?
    let maxHr: Int?
    let lastUpdated: String?
    let sportsZones: SportsZones?
}

// MARK: - API Response Models

struct MetricsAPIResponse: Codable {
    let id: String?
    let userId: String?
    let weightKg: Double?
    let restingHrBpm: Int?
    let maxHrBpm: Int?
    let lastUpdated: String?
    let sportsZones: APISportsZones?

    // Handle both _id and id from API
    let _id: String?
    let user_id: String?
    let weight_kg: Double?
    let resting_hr_bpm: Int?
    let max_hr_bpm: Int?
    let last_updated: String?
    let sports_zones: APISportsZones?

    enum CodingKeys: String, CodingKey {
        case id, userId, weightKg, restingHrBpm, maxHrBpm, lastUpdated, sportsZones
        case _id, user_id, weight_kg, resting_hr_bpm, max_hr_bpm, last_updated, sports_zones
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try both naming conventions
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self._id = try container.decodeIfPresent(String.self, forKey: ._id)
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId)
        self.user_id = try container.decodeIfPresent(String.self, forKey: .user_id)
        self.weightKg = try container.decodeIfPresent(Double.self, forKey: .weightKg)
        self.weight_kg = try container.decodeIfPresent(Double.self, forKey: .weight_kg)
        self.restingHrBpm = try container.decodeIfPresent(Int.self, forKey: .restingHrBpm)
        self.resting_hr_bpm = try container.decodeIfPresent(Int.self, forKey: .resting_hr_bpm)
        self.maxHrBpm = try container.decodeIfPresent(Int.self, forKey: .maxHrBpm)
        self.max_hr_bpm = try container.decodeIfPresent(Int.self, forKey: .max_hr_bpm)
        self.lastUpdated = try container.decodeIfPresent(String.self, forKey: .lastUpdated)
        self.last_updated = try container.decodeIfPresent(String.self, forKey: .last_updated)
        self.sportsZones = try container.decodeIfPresent(APISportsZones.self, forKey: .sportsZones)
        self.sports_zones = try container.decodeIfPresent(APISportsZones.self, forKey: .sports_zones)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(weightKg, forKey: .weightKg)
        try container.encodeIfPresent(restingHrBpm, forKey: .restingHrBpm)
        try container.encodeIfPresent(maxHrBpm, forKey: .maxHrBpm)
        try container.encodeIfPresent(lastUpdated, forKey: .lastUpdated)
        try container.encodeIfPresent(sportsZones, forKey: .sportsZones)
    }
}

struct APISportsZones: Codable {
    let running: APIRunningZones?
    let cycling: APICyclingZones?
    let swimming: APISwimmingZones?
}

struct APIRunningZones: Codable {
    let lactate_threshold_hr_bpm: Int?
    let threshold_pace_per_km: String?
    let zone_1: APIZoneRange?
    let zone_2: APIZoneRange?
    let zone_3: APIZoneRange?
    let zone_4: APIZoneRange?
    let zone_5: APIZoneRange?
    let zone_6: APIZoneRange?
    let pace_zones: APIPaceZones?
}

struct APICyclingZones: Codable {
    let ftp_watts: Int?
    let zone_1: APIZoneRange?
    let zone_2: APIZoneRange?
    let zone_3: APIZoneRange?
    let zone_4: APIZoneRange?
    let zone_5: APIZoneRange?
    let zone_6: APIZoneRange?
}

struct APISwimmingZones: Codable {
    let css_pace_per_100m: String?
    let zone_1: String?
    let zone_2: String?
    let zone_3: String?
    let zone_4: String?
    let zone_5: String?
}

struct APIZoneRange: Codable {
    let min: Int?
    let max: Int?
}

struct APIPaceZones: Codable {
    let zone_1: String?
    let zone_2: String?
    let zone_3: String?
    let zone_4: String?
    let zone_5: String?
    let zone_6: String?
}

// MARK: - Metrics Service

@MainActor
class MetricsService {
    static let shared = MetricsService()
    private let api = APIService.shared

    private init() {}

    // MARK: - API Calls

    func getMetrics(userId: String) async throws -> UserMetricsData {
        let response: MetricsAPIResponse = try await api.get("/metrics", queryParams: ["user_id": userId])
        return convertAPIToFrontend(response)
    }

    func refreshMetrics(userId: String) async throws -> UserMetricsData {
        let response: MetricsAPIResponse = try await api.get("/metrics", queryParams: [
            "user_id": userId,
            "refresh": "true"
        ])
        return convertAPIToFrontend(response)
    }

    // MARK: - Conversion

    private func convertAPIToFrontend(_ api: MetricsAPIResponse) -> UserMetricsData {
        let resolvedId = api.id ?? api._id ?? ""
        let resolvedUserId = api.userId ?? api.user_id ?? ""
        let resolvedWeight = api.weightKg ?? api.weight_kg
        let resolvedRestingHr = api.restingHrBpm ?? api.resting_hr_bpm
        let resolvedMaxHr = api.maxHrBpm ?? api.max_hr_bpm
        let resolvedLastUpdated = api.lastUpdated ?? api.last_updated
        let resolvedSportsZones = api.sportsZones ?? api.sports_zones

        return UserMetricsData(
            id: resolvedId,
            userId: resolvedUserId,
            weight: resolvedWeight,
            restingHr: resolvedRestingHr,
            maxHr: resolvedMaxHr,
            lastUpdated: resolvedLastUpdated,
            sportsZones: convertSportsZones(resolvedSportsZones)
        )
    }

    private func convertSportsZones(_ api: APISportsZones?) -> SportsZones? {
        guard let api = api else { return nil }

        return SportsZones(
            running: convertRunningZones(api.running),
            cycling: convertCyclingZones(api.cycling),
            swimming: convertSwimmingZones(api.swimming)
        )
    }

    private func convertRunningZones(_ api: APIRunningZones?) -> RunningZones? {
        guard let api = api else { return nil }

        let zones: [HeartRateZone] = [
            HeartRateZone(
                zone: 1,
                name: "Récupération active",
                min: api.zone_1?.min ?? 0,
                max: api.zone_1?.max ?? 0,
                pace: api.pace_zones?.zone_1,
                color: "#10B981",
                description: "Récupération et échauffement"
            ),
            HeartRateZone(
                zone: 2,
                name: "Endurance fondamentale",
                min: api.zone_2?.min ?? 0,
                max: api.zone_2?.max ?? 0,
                pace: api.pace_zones?.zone_2,
                color: "#3B82F6",
                description: "Base aérobie"
            ),
            HeartRateZone(
                zone: 3,
                name: "Endurance active",
                min: api.zone_3?.min ?? 0,
                max: api.zone_3?.max ?? 0,
                pace: api.pace_zones?.zone_3,
                color: "#F59E0B",
                description: "Tempo modéré"
            ),
            HeartRateZone(
                zone: 4,
                name: "Seuil lactique",
                min: api.zone_4?.min ?? 0,
                max: api.zone_4?.max ?? 0,
                pace: api.pace_zones?.zone_4,
                color: "#EF4444",
                description: "Seuil anaérobie"
            ),
            HeartRateZone(
                zone: 5,
                name: "VO2 Max",
                min: api.zone_5?.min ?? 0,
                max: api.zone_5?.max ?? 0,
                pace: api.pace_zones?.zone_5,
                color: "#DC2626",
                description: "Puissance aérobie maximale"
            ),
            HeartRateZone(
                zone: 6,
                name: "Neuromusculaire",
                min: api.zone_6?.min ?? 0,
                max: api.zone_6?.max ?? 0,
                pace: api.pace_zones?.zone_6,
                color: "#7C2D12",
                description: "Vitesse maximale"
            )
        ]

        return RunningZones(
            lactateThresholdHr: api.lactate_threshold_hr_bpm ?? 0,
            thresholdPace: api.threshold_pace_per_km,
            heartRateZones: zones
        )
    }

    private func convertCyclingZones(_ api: APICyclingZones?) -> CyclingZones? {
        guard let api = api else { return nil }

        let zones: [PowerZone] = [
            PowerZone(
                zone: 1,
                name: "Récupération active",
                min: api.zone_1?.min ?? 0,
                max: api.zone_1?.max ?? 0,
                percentage: "< 55%",
                color: "#10B981",
                description: "Récupération et échauffement"
            ),
            PowerZone(
                zone: 2,
                name: "Endurance",
                min: api.zone_2?.min ?? 0,
                max: api.zone_2?.max ?? 0,
                percentage: "56-75%",
                color: "#3B82F6",
                description: "Base aérobie"
            ),
            PowerZone(
                zone: 3,
                name: "Tempo",
                min: api.zone_3?.min ?? 0,
                max: api.zone_3?.max ?? 0,
                percentage: "76-90%",
                color: "#F59E0B",
                description: "Effort soutenu"
            ),
            PowerZone(
                zone: 4,
                name: "Seuil lactique",
                min: api.zone_4?.min ?? 0,
                max: api.zone_4?.max ?? 0,
                percentage: "91-105%",
                color: "#EF4444",
                description: "Seuil FTP"
            ),
            PowerZone(
                zone: 5,
                name: "VO2 Max",
                min: api.zone_5?.min ?? 0,
                max: api.zone_5?.max ?? 0,
                percentage: "106-120%",
                color: "#DC2626",
                description: "Puissance aérobie maximale"
            ),
            PowerZone(
                zone: 6,
                name: "Neuromusculaire",
                min: api.zone_6?.min ?? 0,
                max: api.zone_6?.max ?? 0,
                percentage: "> 120%",
                color: "#7C2D12",
                description: "Puissance maximale"
            )
        ]

        return CyclingZones(
            ftp: api.ftp_watts ?? 0,
            powerZones: zones
        )
    }

    private func convertSwimmingZones(_ api: APISwimmingZones?) -> SwimmingZones? {
        guard let api = api else { return nil }

        let zones: [PaceZone] = [
            PaceZone(
                zone: 1,
                name: "Récupération",
                pace: api.zone_1 ?? "",
                color: "#10B981",
                description: "Nage facile et technique"
            ),
            PaceZone(
                zone: 2,
                name: "Endurance",
                pace: api.zone_2 ?? "",
                color: "#3B82F6",
                description: "Base aérobie"
            ),
            PaceZone(
                zone: 3,
                name: "Tempo",
                pace: api.zone_3 ?? "",
                color: "#F59E0B",
                description: "Effort soutenu"
            ),
            PaceZone(
                zone: 4,
                name: "Seuil",
                pace: api.zone_4 ?? "",
                color: "#EF4444",
                description: "Seuil CSS"
            ),
            PaceZone(
                zone: 5,
                name: "VO2 Max",
                pace: api.zone_5 ?? "",
                color: "#DC2626",
                description: "Vitesse maximale"
            )
        ]

        return SwimmingZones(
            cssPace: api.css_pace_per_100m ?? "",
            paceZones: zones
        )
    }

    // MARK: - Helper Methods

    func getZoneColor(_ hexColor: String) -> Color {
        Color(hex: hexColor) ?? .gray
    }
}
