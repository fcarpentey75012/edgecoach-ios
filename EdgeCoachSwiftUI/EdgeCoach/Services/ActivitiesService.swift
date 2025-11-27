/**
 * Service Activités
 * Gestion de l'historique des séances effectuées
 * Utilise directement le modèle Activity qui décode les données API
 */

import Foundation

// MARK: - Activities Service

@MainActor
class ActivitiesService {
    static let shared = ActivitiesService()
    private let api = APIService.shared

    private init() {}

    // MARK: - Get History

    /// Récupère l'historique des activités pour une période donnée
    /// - Parameters:
    ///   - userId: ID de l'utilisateur
    ///   - startDate: Date de début (optionnelle)
    ///   - endDate: Date de fin (optionnelle)
    ///   - forceApiCall: Force un appel API au lieu d'utiliser le cache
    ///   - limit: Nombre maximum d'activités à retourner (optionnel, filtrage côté client)
    /// - Returns: Liste des activités
    func getHistory(
        userId: String,
        startDate: Date? = nil,
        endDate: Date? = nil,
        forceApiCall: Bool = false,
        limit: Int? = nil
    ) async throws -> [Activity] {
        var params: [String: String] = ["user_id": userId]

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        if let startDate = startDate {
            params["start_date"] = formatter.string(from: startDate)
        }
        if let endDate = endDate {
            params["end_date"] = formatter.string(from: endDate)
        }
        if forceApiCall {
            params["force_api_call"] = "true"
        }

        // L'API renvoie directement un tableau d'activités
        // Le modèle Activity gère le décodage des données brutes
        var activities: [Activity] = try await api.get(
            "/activities/history",
            queryParams: params
        )

        // Trier par date décroissante
        activities.sort { a1, a2 in
            guard let d1 = a1.date, let d2 = a2.date else {
                return a1.dateStart > a2.dateStart
            }
            return d1 > d2
        }

        // Appliquer la limite si spécifiée
        if let limit = limit, activities.count > limit {
            activities = Array(activities.prefix(limit))
        }

        return activities
    }

    // MARK: - Get Activities for Month

    /// Récupère les activités pour un mois donné
    func getActivitiesForMonth(
        userId: String,
        year: Int,
        month: Int
    ) async throws -> [Activity] {
        let calendar = Calendar.current
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = month
        startComponents.day = 1

        guard let startDate = calendar.date(from: startComponents) else {
            throw APIError.invalidURL
        }

        var endComponents = startComponents
        endComponents.month = month + 1
        let endDate = calendar.date(from: endComponents) ?? startDate

        return try await getHistory(
            userId: userId,
            startDate: startDate,
            endDate: endDate
        )
    }

    // MARK: - Get Activities for Date Range

    /// Récupère les activités pour une plage de dates
    func getActivitiesForDateRange(
        userId: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [Activity] {
        return try await getHistory(
            userId: userId,
            startDate: startDate,
            endDate: endDate
        )
    }

    // MARK: - Get GPS Data

    /// Récupère les données GPS d'une activité
    func getActivityGPSData(
        userId: String,
        activityDate: Date,
        forceReload: Bool = false
    ) async throws -> (recordData: [ActivityRecord]?, fileData: ActivityFileData?) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: activityDate)

        var params: [String: String] = [
            "user_id": userId,
            "start_date": dateStr,
            "end_date": dateStr,
            "records": "true",
            "force_api_call": "true"  // Forcer pour avoir les record_data
        ]

        #if DEBUG
        print("🗺️ GPS: Fetching GPS data for date: \(dateStr)")
        #endif

        let activities: [Activity] = try await api.get(
            "/activities/history",
            queryParams: params
        )

        #if DEBUG
        print("🗺️ GPS: Found \(activities.count) activities")
        if let activity = activities.first {
            print("🗺️ GPS: Activity ID: \(activity.id)")
            print("🗺️ GPS: Has fileDatas: \(activity.fileDatas != nil)")
            if let fileDatas = activity.fileDatas {
                print("🗺️ GPS: Records count: \(fileDatas.records?.count ?? 0)")
                print("🗺️ GPS: Laps count: \(fileDatas.laps?.count ?? 0)")
                // Debug chaque lap
                if let laps = fileDatas.laps {
                    for (i, lap) in laps.enumerated() {
                        print("🗺️ GPS: Lap[\(i)] idx=\(lap.lapIndex) dist=\(lap.distance ?? 0)m dur=\(lap.duration ?? 0)s hr=\(lap.avgHeartRate ?? 0) startTime=\(lap.startTime ?? 0)")
                    }
                }
                if let firstRecord = fileDatas.records?.first {
                    print("🗺️ GPS: First record - lat: \(firstRecord.positionLat ?? 0), lng: \(firstRecord.positionLong ?? 0)")
                }
            }
        }
        #endif

        guard let activity = activities.first else {
            return (nil, nil)
        }

        return (activity.fileDatas?.records, activity.fileDatas)
    }

    // MARK: - Group by Date

    /// Groupe les activités par date (format YYYY-MM-DD)
    func groupByDate(_ activities: [Activity]) -> [String: [Activity]] {
        return Dictionary(grouping: activities) { activity in
            activity.dateStart.prefix(10).description // Prend YYYY-MM-DD
        }
    }
}
