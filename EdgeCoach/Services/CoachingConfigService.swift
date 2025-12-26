//
//  CoachingConfigService.swift
//  EdgeCoach
//
//  Service de gestion de la configuration de coaching.
//  Gère la persistance locale et la synchronisation avec le backend.
//

import Foundation
import Combine

/// Service de gestion de la configuration de coaching
final class CoachingConfigService: ObservableObject {

    // MARK: - Properties

    /// Configuration actuelle
    @Published private(set) var config: CoachingConfig

    /// Clé UserDefaults pour la persistance
    private let storageKey = "coachingConfig"

    // MARK: - Singleton

    /// Instance partagée
    static let shared = CoachingConfigService()

    // MARK: - Init

    private init() {
        // Charger depuis UserDefaults ou utiliser la config par défaut
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let savedConfig = try? JSONDecoder().decode(CoachingConfig.self, from: data) {
            self.config = savedConfig
        } else {
            self.config = .default
        }
    }

    // MARK: - Public Methods

    /// Met à jour la configuration
    /// - Parameter newConfig: Nouvelle configuration
    func updateConfig(_ newConfig: CoachingConfig) {
        config = newConfig
        saveToLocal()
    }

    /// Met à jour le sport
    /// - Parameter sport: Nouvelle spécialisation sportive
    func updateSport(_ sport: SportSpecialization) {
        config.sport = sport
        saveToLocal()
    }

    /// Met à jour le niveau
    /// - Parameter level: Nouveau niveau utilisateur
    func updateLevel(_ level: UserLevel) {
        config.level = level
        saveToLocal()
    }

    /// Met à jour le style
    /// - Parameter style: Nouveau style de coaching
    func updateStyle(_ style: CoachingStyle) {
        config.style = style
        saveToLocal()
    }

    /// Réinitialise à la configuration par défaut
    func resetToDefault() {
        config = .default
        saveToLocal()
    }

    /// Synchronise avec le backend (si nécessaire)
    /// - Parameter userId: ID de l'utilisateur
    func syncWithBackend(userId: String) async throws {
        // Pour l'instant, la config est envoyée avec chaque message
        // Ce endpoint pourrait être utilisé pour sauvegarder la config côté serveur
        // TODO: Implémenter quand l'endpoint backend /api/coaching/config sera prêt
    }

    // MARK: - Private Methods

    /// Sauvegarde en local
    private func saveToLocal() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

// MARK: - Preview Helper

extension CoachingConfigService {
    /// Instance pour les previews
    static var preview: CoachingConfigService {
        let service = CoachingConfigService()
        service.config = CoachingConfig(
            sport: .running,
            level: .amateur,
            style: .supportive
        )
        return service
    }
}
