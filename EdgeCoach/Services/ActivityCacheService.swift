/**
 * Service de cache local pour les activités
 * Stocke les données en JSON pour un chargement instantané
 */

import Foundation

@MainActor
class ActivityCacheService {
    static let shared = ActivityCacheService()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let cacheValidityDuration: TimeInterval = 3600 // 1 heure

    private init() {
        // Dossier Documents/ActivityCache
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("ActivityCache", isDirectory: true)

        // Créer le dossier si nécessaire
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Cache Key Generation

    private func cacheKey(userId: String, year: Int, month: Int) -> String {
        return "\(userId)_\(year)_\(month)"
    }

    private func cacheFile(for key: String) -> URL {
        return cacheDirectory.appendingPathComponent("\(key).json")
    }

    private func metadataFile(for key: String) -> URL {
        return cacheDirectory.appendingPathComponent("\(key)_meta.json")
    }

    // MARK: - Cache Metadata

    private struct CacheMetadata: Codable {
        let cachedAt: Date
        let count: Int
    }

    // MARK: - Save to Cache

    func saveActivities(_ activities: [Activity], userId: String, year: Int, month: Int) {
        let key = cacheKey(userId: userId, year: year, month: month)
        let file = cacheFile(for: key)
        let metaFile = metadataFile(for: key)

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            // Sauvegarder les activités
            let data = try encoder.encode(activities)
            try data.write(to: file)

            // Sauvegarder les métadonnées
            let metadata = CacheMetadata(cachedAt: Date(), count: activities.count)
            let metaData = try encoder.encode(metadata)
            try metaData.write(to: metaFile)
        } catch {
            // Échec silencieux - le cache n'est pas critique
        }
    }

    // MARK: - Load from Cache

    func loadActivities(userId: String, year: Int, month: Int) -> [Activity]? {
        let key = cacheKey(userId: userId, year: year, month: month)
        let file = cacheFile(for: key)

        guard fileManager.fileExists(atPath: file.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: file)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Activity].self, from: data)
        } catch {
            // Cache corrompu - supprimer
            try? fileManager.removeItem(at: file)
            return nil
        }
    }

    // MARK: - Cache Validity

    func isCacheValid(userId: String, year: Int, month: Int) -> Bool {
        let key = cacheKey(userId: userId, year: year, month: month)
        let metaFile = metadataFile(for: key)

        guard fileManager.fileExists(atPath: metaFile.path) else {
            return false
        }

        do {
            let data = try Data(contentsOf: metaFile)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let metadata = try decoder.decode(CacheMetadata.self, from: data)

            // Vérifier si le cache est encore valide
            let age = Date().timeIntervalSince(metadata.cachedAt)
            return age < cacheValidityDuration
        } catch {
            return false
        }
    }

    // MARK: - Cache Info

    func getCacheDate(userId: String, year: Int, month: Int) -> Date? {
        let key = cacheKey(userId: userId, year: year, month: month)
        let metaFile = metadataFile(for: key)

        guard let data = try? Data(contentsOf: metaFile),
              let metadata = try? JSONDecoder().decode(CacheMetadata.self, from: data) else {
            return nil
        }

        return metadata.cachedAt
    }

    // MARK: - Clear Cache

    func clearCache(userId: String, year: Int, month: Int) {
        let key = cacheKey(userId: userId, year: year, month: month)
        try? fileManager.removeItem(at: cacheFile(for: key))
        try? fileManager.removeItem(at: metadataFile(for: key))
    }

    func clearAllCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Cache Size

    func getCacheSize() -> Int64 {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        return files.reduce(0) { total, file in
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }

    var formattedCacheSize: String {
        let bytes = getCacheSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
