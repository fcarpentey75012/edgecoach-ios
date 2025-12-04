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
    private let cache = ActivityCacheService.shared

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

    // MARK: - Get Activities for Month (Cache-First)

    /// Résultat du chargement avec cache
    struct CachedResult {
        let activities: [Activity]
        let fromCache: Bool
        let cacheDate: Date?
    }

    /// Récupère les activités avec stratégie cache-first
    /// Retourne immédiatement le cache si disponible, puis met à jour en arrière-plan
    func getActivitiesForMonthCached(
        userId: String,
        year: Int,
        month: Int,
        forceRefresh: Bool = false
    ) async -> CachedResult {
        // Si force refresh, ignorer le cache
        if !forceRefresh {
            // Essayer de charger depuis le cache
            if let cached = cache.loadActivities(userId: userId, year: year, month: month) {
                let cacheDate = cache.getCacheDate(userId: userId, year: year, month: month)
                return CachedResult(activities: cached, fromCache: true, cacheDate: cacheDate)
            }
        }

        // Pas de cache ou force refresh - charger depuis l'API
        do {
            let activities = try await getActivitiesForMonth(userId: userId, year: year, month: month)
            // Sauvegarder en cache
            cache.saveActivities(activities, userId: userId, year: year, month: month)
            return CachedResult(activities: activities, fromCache: false, cacheDate: Date())
        } catch {
            // En cas d'erreur, retourner le cache même expiré
            if let cached = cache.loadActivities(userId: userId, year: year, month: month) {
                let cacheDate = cache.getCacheDate(userId: userId, year: year, month: month)
                return CachedResult(activities: cached, fromCache: true, cacheDate: cacheDate)
            }
            return CachedResult(activities: [], fromCache: false, cacheDate: nil)
        }
    }

    /// Rafraîchit le cache en arrière-plan et retourne les nouvelles données
    func refreshActivitiesForMonth(
        userId: String,
        year: Int,
        month: Int
    ) async -> [Activity] {
        do {
            let activities = try await getActivitiesForMonth(userId: userId, year: year, month: month)
            cache.saveActivities(activities, userId: userId, year: year, month: month)
            return activities
        } catch {
            return []
        }
    }

    /// Vérifie si le cache est valide pour un mois donné
    func isCacheValid(userId: String, year: Int, month: Int) -> Bool {
        return cache.isCacheValid(userId: userId, year: year, month: month)
    }

    /// Vide le cache pour un mois donné
    func clearCache(userId: String, year: Int, month: Int) {
        cache.clearCache(userId: userId, year: year, month: month)
    }

    /// Vide tout le cache
    func clearAllCache() {
        cache.clearAllCache()
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

        let activities: [Activity] = try await api.get(
            "/activities/history",
            queryParams: params
        )

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
