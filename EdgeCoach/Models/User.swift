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
        case id = "_id"  // MongoDB utilise _id comme clé primaire
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case experienceLevel = "experience_level"
        case profilePicture = "profile_picture"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Support both "id" and "_id" from backend
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Essayer d'abord avec _id, sinon fallback sur id
        if let mongoId = try? container.decode(String.self, forKey: .id) {
            self.id = mongoId
        } else {
            // Fallback: essayer avec une clé "id" dynamique
            let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
            if let idKey = DynamicCodingKey(stringValue: "id"),
               let plainId = try? dynamicContainer.decode(String.self, forKey: idKey) {
                self.id = plainId
            } else {
                throw DecodingError.keyNotFound(CodingKeys.id,
                    DecodingError.Context(codingPath: decoder.codingPath,
                                         debugDescription: "Neither 'id' nor '_id' found"))
            }
        }

        self.email = try container.decode(String.self, forKey: .email)
        self.firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        self.lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        self.experienceLevel = try container.decodeIfPresent(ExperienceLevel.self, forKey: .experienceLevel)
        self.profilePicture = try container.decodeIfPresent(String.self, forKey: .profilePicture)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

// Helper pour le décodage dynamique
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}

// MARK: - Experience Level

/// Niveau d'expérience de l'utilisateur (aligné avec backend: discovery, amateur, competitor, expert)
enum ExperienceLevel: String, Codable, CaseIterable {
    case discovery = "discovery"
    case amateur = "amateur"
    case competitor = "competitor"
    case expert = "expert"

    var displayName: String {
        switch self {
        case .discovery: return "Découverte"
        case .amateur: return "Amateur"
        case .competitor: return "Compétiteur"
        case .expert: return "Expert"
        }
    }

    var description: String {
        switch self {
        case .discovery: return "Je débute, je veux apprendre et prendre du plaisir"
        case .amateur: return "Je m'entraîne régulièrement et je veux progresser"
        case .competitor: return "Je vise la performance et je connais les fondamentaux"
        case .expert: return "Je maîtrise l'entraînement et je vise l'excellence"
        }
    }

    var icon: String {
        switch self {
        case .discovery: return "leaf.fill"
        case .amateur: return "star.fill"
        case .competitor: return "trophy.fill"
        case .expert: return "crown.fill"
        }
    }

    var emoji: String {
        switch self {
        case .discovery: return "🌱"
        case .amateur: return "⭐"
        case .competitor: return "🏆"
        case .expert: return "👑"
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
