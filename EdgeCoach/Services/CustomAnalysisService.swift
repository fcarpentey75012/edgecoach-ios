/**
 * Service pour les analyses personnalisées
 * Gère la récupération et la sauvegarde des 4 analyses rapides de l'utilisateur
 */

import Foundation

// MARK: - Models

struct CustomAnalysis: Codable, Identifiable, Equatable {
    let id: String
    var icon: String
    var title: String
    var description: String

    enum CodingKeys: String, CodingKey {
        case id, icon, title, description
    }
}

struct CustomAnalysesResponse: Decodable {
    let analyses: [CustomAnalysis]
    let isDefault: Bool?
    let message: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case analyses
        case isDefault = "is_default"
        case message, error
    }
}

struct CustomAnalysesSaveRequest: Encodable {
    let analyses: [CustomAnalysis]
}

// MARK: - Default Analyses

extension CustomAnalysis {
    /// Analyses par défaut (identiques au backend)
    static let defaults: [CustomAnalysis] = [
        CustomAnalysis(
            id: "default_1",
            icon: "chart.line.uptrend.xyaxis",
            title: "Performance globale",
            description: "Analyse complète de la séance"
        ),
        CustomAnalysis(
            id: "default_2",
            icon: "heart.fill",
            title: "Zones cardiaques",
            description: "Temps dans les zones, efficacité"
        ),
        CustomAnalysis(
            id: "default_3",
            icon: "bolt.fill",
            title: "Puissance & Intensité",
            description: "FTP, zones de puissance, distribution"
        ),
        CustomAnalysis(
            id: "default_4",
            icon: "lightbulb.fill",
            title: "Conseils personnalisés",
            description: "Recommandations d'amélioration"
        )
    ]
}

// MARK: - Custom Analysis Service

@MainActor
class CustomAnalysisService {
    static let shared = CustomAnalysisService()
    private let api = APIService.shared

    /// Cache local des analyses
    private var cachedAnalyses: [CustomAnalysis]?
    private var cacheUserId: String?

    private init() {}

    // MARK: - Public Methods

    /// Récupère les analyses personnalisées de l'utilisateur
    /// - Parameter userId: ID de l'utilisateur
    /// - Returns: Liste des 4 analyses (personnalisées ou par défaut)
    func getAnalyses(for userId: String) async throws -> [CustomAnalysis] {
        // Retourner le cache si valide
        if let cached = cachedAnalyses, cacheUserId == userId {
            return cached
        }

        do {
            let response: CustomAnalysesResponse = try await api.get("/users/\(userId)/custom-analyses")
            cachedAnalyses = response.analyses
            cacheUserId = userId
            return response.analyses
        } catch {
            // En cas d'erreur, retourner les analyses par défaut
            print("CustomAnalysisService: Erreur lors de la récupération, utilisation des défauts - \(error)")
            return CustomAnalysis.defaults
        }
    }

    /// Sauvegarde les analyses personnalisées
    /// - Parameters:
    ///   - userId: ID de l'utilisateur
    ///   - analyses: Liste des 4 analyses à sauvegarder
    func saveAnalyses(for userId: String, analyses: [CustomAnalysis]) async throws {
        guard analyses.count == 4 else {
            throw CustomAnalysisError.invalidCount
        }

        let request = CustomAnalysesSaveRequest(analyses: analyses)
        let _: CustomAnalysesResponse = try await api.put("/users/\(userId)/custom-analyses", body: request)

        // Mettre à jour le cache
        cachedAnalyses = analyses
        cacheUserId = userId
    }

    /// Met à jour une seule analyse
    /// - Parameters:
    ///   - userId: ID de l'utilisateur
    ///   - index: Index de l'analyse (0-3)
    ///   - analysis: Nouvelle analyse
    func updateSingleAnalysis(for userId: String, at index: Int, analysis: CustomAnalysis) async throws {
        guard index >= 0 && index <= 3 else {
            throw CustomAnalysisError.invalidIndex
        }

        let _: CustomAnalysesResponse = try await api.put("/users/\(userId)/custom-analyses/\(index)", body: analysis)

        // Mettre à jour le cache
        if cachedAnalyses != nil && cacheUserId == userId {
            cachedAnalyses?[index] = analysis
        }
    }

    /// Réinitialise les analyses aux valeurs par défaut
    /// - Parameter userId: ID de l'utilisateur
    func resetToDefaults(for userId: String) async throws {
        struct EmptyResponse: Decodable {}
        let _: CustomAnalysesResponse = try await api.delete("/users/\(userId)/custom-analyses")

        // Réinitialiser le cache
        cachedAnalyses = CustomAnalysis.defaults
        cacheUserId = userId
    }

    /// Invalide le cache local
    func invalidateCache() {
        cachedAnalyses = nil
        cacheUserId = nil
    }
}

// MARK: - Errors

enum CustomAnalysisError: LocalizedError {
    case invalidCount
    case invalidIndex
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .invalidCount:
            return "Exactement 4 analyses sont requises"
        case .invalidIndex:
            return "L'index doit être entre 0 et 3"
        case .saveFailed:
            return "Erreur lors de la sauvegarde"
        }
    }
}
