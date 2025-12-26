/**
 * Modèles pour le Chat Coach
 */

import Foundation

// MARK: - Chat Message

struct ChatMessage: Codable, Identifiable {
    let id: String
    let role: MessageRole
    var content: String
    let timestamp: Date?
    var isLoading: Bool = false

    // Support média
    var attachments: [MessageAttachment]?
    var voiceMessage: VoiceMessage?

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case timestamp
        case attachments
        case voiceMessage
    }

    init(
        id: String = UUID().uuidString,
        role: MessageRole,
        content: String,
        timestamp: Date? = Date(),
        isLoading: Bool = false,
        attachments: [MessageAttachment]? = nil,
        voiceMessage: VoiceMessage? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isLoading = isLoading
        self.attachments = attachments
        self.voiceMessage = voiceMessage
    }

    var isUser: Bool {
        role == .user
    }

    var hasAttachments: Bool {
        attachments?.isEmpty == false
    }

    var hasVoiceMessage: Bool {
        voiceMessage != nil
    }

    var isVoiceOnly: Bool {
        hasVoiceMessage && content.isEmpty
    }

    var imageAttachments: [MessageAttachment] {
        attachments?.filter { $0.type == .image } ?? []
    }

    var documentAttachments: [MessageAttachment] {
        attachments?.filter { $0.type == .document } ?? []
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

// MARK: - Conversation

struct Conversation: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String?
    let messages: [ChatMessage]
    let createdAt: Date
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId = "user_id"
        case title
        case messages
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Coach

struct Coach: Identifiable {
    let id: String
    let name: String
    let sport: Discipline
    let specialty: String
    let avatar: String
    let bio: String

    var systemPrompt: String {
        "Tu es \(name), un coach spécialisé en \(sport.displayName). \(bio)"
    }
}

// Coach généré dynamiquement depuis CoachingConfig (pas de coachs nommés)
extension Coach {
    /// Crée un coach basé sur la configuration actuelle
    static func fromConfig(_ config: CoachingConfig) -> Coach {
        let discipline: Discipline
        switch config.sport {
        case .triathlon: discipline = .autre
        case .running: discipline = .course
        case .cycling: discipline = .cyclisme
        case .swimming: discipline = .natation
        }

        return Coach(
            id: "\(config.sport.rawValue)_\(config.style.rawValue)",
            name: "Coach",
            sport: discipline,
            specialty: config.sport.displayName,
            avatar: config.sport.icon,
            bio: config.style.description
        )
    }

    /// Coach par défaut basé sur la configuration actuelle
    static var current: Coach {
        fromConfig(CoachingConfigService.shared.config)
    }
}
