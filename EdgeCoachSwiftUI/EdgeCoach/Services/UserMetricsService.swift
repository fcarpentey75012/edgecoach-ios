/**
 * Service User Metrics pour EdgeCoach iOS
 * Gestion des métriques personnelles utilisateur (poids, FC, objectifs, etc.)
 * Aligné avec frontendios/src/services/userMetricsService.ts
 */

import Foundation

// MARK: - User Metrics Models

struct UserMetricsData: Codable {
    var height: String
    var weight: String
    var weeklyVolume: String
    var primaryGoal: String
    var availableDays: String
    var preferredTrainingTime: String
    var equipment: String
    var medicalConditions: String
    var ftp: String
    var lthr: String
    var maxHr: String
    var restHr: String
    var vo2Max: String

    static func empty() -> UserMetricsData {
        return UserMetricsData(
            height: "",
            weight: "",
            weeklyVolume: "",
            primaryGoal: "",
            availableDays: "",
            preferredTrainingTime: "",
            equipment: "",
            medicalConditions: "",
            ftp: "",
            lthr: "",
            maxHr: "",
            restHr: "",
            vo2Max: ""
        )
    }
}

struct APIUserMetrics: Codable {
    let height: Double?
    let weight: Double?
    let weeklyVolume: Double?
    let primaryGoal: String?
    let availableDays: Int?
    let preferredTrainingTime: String?
    let equipment: String?
    let medicalConditions: String?
    let ftp: Double?
    let lthr: Int?
    let maxHr: Int?
    let restHr: Int?
    let vo2Max: Double?

    enum CodingKeys: String, CodingKey {
        case height
        case weight
        case weeklyVolume = "weekly_volume"
        case primaryGoal = "primary_goal"
        case availableDays = "available_days"
        case preferredTrainingTime = "preferred_training_time"
        case equipment
        case medicalConditions = "medical_conditions"
        case ftp
        case lthr
        case maxHr = "max_hr"
        case restHr = "rest_hr"
        case vo2Max = "vo2_max"
    }
}

struct MetricsSummary: Codable {
    let totalWorkouts: Int
    let totalDistance: Double
    let totalDuration: Int
    let averageHeartRate: Int
    let weeklyProgress: Double

    enum CodingKeys: String, CodingKey {
        case totalWorkouts = "total_workouts"
        case totalDistance = "total_distance"
        case totalDuration = "total_duration"
        case averageHeartRate = "average_heart_rate"
        case weeklyProgress = "weekly_progress"
    }
}

// MARK: - User Metrics Service

@MainActor
class UserMetricsService {
    static let shared = UserMetricsService()
    private let api = APIService.shared

    private init() {}

    // MARK: - Get Metrics

    func getMetrics(userId: String) async throws -> UserMetricsData {
        do {
            let response: APIUserMetrics = try await api.get("/users/\(userId)/metrics")
            return convertApiToFrontend(response)
        } catch {
            #if DEBUG
            print("Failed to get user metrics: \(error)")
            #endif
            return UserMetricsData.empty()
        }
    }

    // MARK: - Update Metrics

    func updateMetrics(userId: String, metricsData: UserMetricsData) async throws -> UserMetricsData {
        struct UpdateResponse: Decodable {
            let metrics: APIUserMetrics?
            let message: String?
        }

        var apiData: [String: Any] = [:]

        if !metricsData.height.isEmpty, let value = Double(metricsData.height) {
            apiData["height"] = value
        }
        if !metricsData.weight.isEmpty, let value = Double(metricsData.weight) {
            apiData["weight"] = value
        }
        if !metricsData.weeklyVolume.isEmpty, let value = Double(metricsData.weeklyVolume) {
            apiData["weekly_volume"] = value
        }
        if !metricsData.primaryGoal.isEmpty {
            apiData["primary_goal"] = metricsData.primaryGoal
        }
        if !metricsData.availableDays.isEmpty, let value = Int(metricsData.availableDays) {
            apiData["available_days"] = value
        }
        if !metricsData.preferredTrainingTime.isEmpty {
            apiData["preferred_training_time"] = metricsData.preferredTrainingTime
        }
        if !metricsData.equipment.isEmpty {
            apiData["equipment"] = metricsData.equipment
        }
        if !metricsData.medicalConditions.isEmpty {
            apiData["medical_conditions"] = metricsData.medicalConditions
        }
        if !metricsData.ftp.isEmpty, let value = Double(metricsData.ftp) {
            apiData["ftp"] = value
        }
        if !metricsData.lthr.isEmpty, let value = Int(metricsData.lthr) {
            apiData["lthr"] = value
        }
        if !metricsData.maxHr.isEmpty, let value = Int(metricsData.maxHr) {
            apiData["max_hr"] = value
        }
        if !metricsData.restHr.isEmpty, let value = Int(metricsData.restHr) {
            apiData["rest_hr"] = value
        }
        if !metricsData.vo2Max.isEmpty, let value = Double(metricsData.vo2Max) {
            apiData["vo2_max"] = value
        }

        // Create encodable struct dynamically
        struct MetricsUpdate: Encodable {
            let height: Double?
            let weight: Double?
            let weeklyVolume: Double?
            let primaryGoal: String?
            let availableDays: Int?
            let preferredTrainingTime: String?
            let equipment: String?
            let medicalConditions: String?
            let ftp: Double?
            let lthr: Int?
            let maxHr: Int?
            let restHr: Int?
            let vo2Max: Double?

            enum CodingKeys: String, CodingKey {
                case height, weight
                case weeklyVolume = "weekly_volume"
                case primaryGoal = "primary_goal"
                case availableDays = "available_days"
                case preferredTrainingTime = "preferred_training_time"
                case equipment
                case medicalConditions = "medical_conditions"
                case ftp, lthr
                case maxHr = "max_hr"
                case restHr = "rest_hr"
                case vo2Max = "vo2_max"
            }
        }

        let update = MetricsUpdate(
            height: Double(metricsData.height),
            weight: Double(metricsData.weight),
            weeklyVolume: Double(metricsData.weeklyVolume),
            primaryGoal: metricsData.primaryGoal.isEmpty ? nil : metricsData.primaryGoal,
            availableDays: Int(metricsData.availableDays),
            preferredTrainingTime: metricsData.preferredTrainingTime.isEmpty ? nil : metricsData.preferredTrainingTime,
            equipment: metricsData.equipment.isEmpty ? nil : metricsData.equipment,
            medicalConditions: metricsData.medicalConditions.isEmpty ? nil : metricsData.medicalConditions,
            ftp: Double(metricsData.ftp),
            lthr: Int(metricsData.lthr),
            maxHr: Int(metricsData.maxHr),
            restHr: Int(metricsData.restHr),
            vo2Max: Double(metricsData.vo2Max)
        )

        let response: UpdateResponse = try await api.put("/users/\(userId)/metrics", body: update)

        if let metrics = response.metrics {
            return convertApiToFrontend(metrics)
        }

        return metricsData
    }

    // MARK: - Get Summary

    func getMetricsSummary(userId: String) async throws -> MetricsSummary {
        return try await api.get("/users/\(userId)/metrics/summary")
    }

    // MARK: - Aggregated Metrics

    func getAggregatedMetrics(userId: String) async throws -> TrainingLoad? {
        struct Response: Codable {
            let meta: Meta?
            
            struct Meta: Codable {
                let trainingLoad: TrainingLoad?
                
                enum CodingKeys: String, CodingKey {
                    case trainingLoad = "training_load"
                }
            }
        }

        let response: Response = try await api.get(
            "/users/\(userId)/aggregate-metrics",
            queryParams: ["use_cache": "true"]
        )
        return response.meta?.trainingLoad
    }

    // MARK: - Convert API to Frontend

    private func convertApiToFrontend(_ apiMetrics: APIUserMetrics?) -> UserMetricsData {
        guard let api = apiMetrics else {
            return UserMetricsData.empty()
        }

        return UserMetricsData(
            height: api.height.map { String($0) } ?? "",
            weight: api.weight.map { String($0) } ?? "",
            weeklyVolume: api.weeklyVolume.map { String($0) } ?? "",
            primaryGoal: api.primaryGoal ?? "",
            availableDays: api.availableDays.map { String($0) } ?? "",
            preferredTrainingTime: api.preferredTrainingTime ?? "",
            equipment: api.equipment ?? "",
            medicalConditions: api.medicalConditions ?? "",
            ftp: api.ftp.map { String($0) } ?? "",
            lthr: api.lthr.map { String($0) } ?? "",
            maxHr: api.maxHr.map { String($0) } ?? "",
            restHr: api.restHr.map { String($0) } ?? "",
            vo2Max: api.vo2Max.map { String($0) } ?? ""
        )
    }
}
