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

// Static coaches data
extension Coach {
    static let coaches: [Coach] = [
        Coach(
            id: "coach_velo",
            name: "Marc",
            sport: .cyclisme,
            specialty: "Cyclisme & Performance",
            avatar: "figure.outdoor.cycle",
            bio: "Expert en cyclisme avec 15 ans d'expérience dans l'entraînement de cyclistes amateurs et professionnels. Spécialisé dans l'optimisation de la puissance et l'analyse des données."
        ),
        Coach(
            id: "coach_course",
            name: "Sophie",
            sport: .course,
            specialty: "Course à pied",
            avatar: "figure.run",
            bio: "Ancienne athlète de haut niveau, spécialisée dans le marathon et le trail. J'aide les coureurs à améliorer leur technique et à atteindre leurs objectifs."
        ),
        Coach(
            id: "coach_natation",
            name: "Thomas",
            sport: .natation,
            specialty: "Natation",
            avatar: "figure.pool.swim",
            bio: "Coach de natation certifié, ancien nageur de compétition. Expert en technique de nage et préparation physique aquatique."
        ),
        Coach(
            id: "coach_tri",
            name: "Julie",
            sport: .autre,
            specialty: "Triathlon",
            avatar: "figure.strengthtraining.functional",
            bio: "Triathlète Ironman et coach certifiée. Je vous accompagne dans la préparation de vos défis multi-disciplines."
        )
    ]

    static func coach(for sport: Discipline) -> Coach {
        coaches.first { $0.sport == sport } ?? coaches[0]
    }
}
