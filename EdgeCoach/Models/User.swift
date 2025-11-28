/**
 * Modèles utilisateur
 */

import Foundation

// MARK: - User Model

struct User: Codable, Identifiable {
    let id: String
    let email: String
    var firstName: String?
    var lastName: String?
    var experienceLevel: ExperienceLevel?
    var profilePicture: String?
    var createdAt: Date?
    var updatedAt: Date?

    var fullName: String {
        if let first = firstName, let last = lastName {
            return "\(first) \(last)"
        } else if let first = firstName {
            return first
        } else if let last = lastName {
            return last
        }
        return email.components(separatedBy: "@").first ?? email
    }

    var initials: String {
        let parts = fullName.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(fullName.prefix(2)).uppercased()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case experienceLevel = "experience_level"
        case profilePicture = "profile_picture"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Experience Level

enum ExperienceLevel: String, Codable, CaseIterable {
    case debutant = "debutant"
    case intermediaire = "intermediaire"
    case avance = "avance"
    case expert = "expert"

    var displayName: String {
        switch self {
        case .debutant: return "Débutant"
        case .intermediaire: return "Intermédiaire"
        case .avance: return "Avancé"
        case .expert: return "Expert"
        }
    }
}

// MARK: - Auth Models

struct LoginCredentials {
    let email: String
    let password: String
}

struct RegisterData {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let experienceLevel: ExperienceLevel
}

struct AuthResponse: Codable {
    let success: Bool
    let token: String?
    let user: User?
    let message: String?
}

// MARK: - User Metrics

struct UserMetrics: Codable {
    var ftpWatts: Int?
    var maxHeartRate: Int?
    var restingHeartRate: Int?
    var weight: Double?
    var height: Double?
    var birthDate: Date?
    var gender: String?

    enum CodingKeys: String, CodingKey {
        case ftpWatts = "ftp_watts"
        case maxHeartRate = "max_heart_rate"
        case restingHeartRate = "resting_heart_rate"
        case weight
        case height
        case birthDate = "birth_date"
        case gender
    }
}
