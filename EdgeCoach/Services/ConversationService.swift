/**
 * Service Conversation pour EdgeCoach iOS
 * Gestion des conversations (CRUD)
 * Aligné avec frontendios/src/services/conversationService.ts
 */

import Foundation

// MARK: - Conversation Models

struct ConversationMessage: Codable, Identifiable {
    let id: String
    let content: String
    let isAi: Bool
    let messageType: String
    let timestamp: String
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case isAi = "is_ai"
        case messageType = "message_type"
        case timestamp
        case metadata
    }
}

struct Conversation: Codable, Identifiable {
    let id: String
    let conversationId: String
    let userId: String
    let title: String
    let messages: [ConversationMessage]
    let createdAt: String
    let updatedAt: String
    let isArchived: Bool
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case conversationId = "conversation_id"
        case userId = "user_id"
        case title
        case messages
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isArchived = "is_archived"
        case tags
    }
}

struct ConversationListItem: Codable, Identifiable {
    let id: String
    let conversationId: String
    let title: String
    let messageCount: Int
    let lastMessagePreview: String
    let createdAt: String
    let updatedAt: String
    let isArchived: Bool
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case conversationId = "conversation_id"
        case title
        case messageCount = "message_count"
        case lastMessagePreview = "last_message_preview"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isArchived = "is_archived"
        case tags
    }
}

struct ConversationStats: Codable {
    let totalConversations: Int
    let activeConversations: Int
    let archivedConversations: Int
    let totalMessages: Int
    let averageMessagesPerConversation: Double
    let mostRecentConversation: String?

    enum CodingKeys: String, CodingKey {
        case totalConversations = "total_conversations"
        case activeConversations = "active_conversations"
        case archivedConversations = "archived_conversations"
        case totalMessages = "total_messages"
        case averageMessagesPerConversation = "average_messages_per_conversation"
        case mostRecentConversation = "most_recent_conversation"
    }
}

// MARK: - Conversation Service

@MainActor
class ConversationService {
    static let shared = ConversationService()
    private let api = APIService.shared

    private init() {}

    // MARK: - Get Conversations

    func getConversations(
        userId: String,
        limit: Int = 50,
        offset: Int = 0,
        includeArchived: Bool = false
    ) async throws -> [ConversationListItem] {
        let params: [String: String] = [
            "user_id": userId,
            "limit": String(limit),
            "offset": String(offset),
            "include_archived": String(includeArchived)
        ]

        return try await api.get("/conversations/", queryParams: params)
    }

    // MARK: - Create Conversation

    func createConversation(
        userId: String,
        conversationId: String,
        title: String? = nil,
        initialMessage: String? = nil
    ) async throws -> Conversation {
        struct CreateRequest: Encodable {
            let userId: String
            let conversationId: String
            let title: String?
            let initialMessage: String?

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case conversationId = "conversation_id"
                case title
                case initialMessage = "initial_message"
            }
        }

        let request = CreateRequest(
            userId: userId,
            conversationId: conversationId,
            title: title,
            initialMessage: initialMessage
        )

        return try await api.post("/conversations/", body: request)
    }

    // MARK: - Get Conversation

    func getConversation(conversationId: String) async throws -> Conversation {
        return try await api.get("/conversations/\(conversationId)")
    }

    // MARK: - Update Conversation

    func updateConversation(
        conversationId: String,
        title: String? = nil,
        isArchived: Bool? = nil,
        tags: [String]? = nil
    ) async throws -> Conversation {
        struct UpdateRequest: Encodable {
            let title: String?
            let isArchived: Bool?
            let tags: [String]?

            enum CodingKeys: String, CodingKey {
                case title
                case isArchived = "is_archived"
                case tags
            }
        }

        let request = UpdateRequest(
            title: title,
            isArchived: isArchived,
            tags: tags
        )

        return try await api.put("/conversations/\(conversationId)", body: request)
    }

    // MARK: - Add Message

    func addMessage(
        conversationId: String,
        content: String,
        isAi: Bool,
        messageType: String = "text",
        metadata: [String: String]? = nil
    ) async throws -> Conversation {
        struct MessageRequest: Encodable {
            let content: String
            let isAi: Bool
            let messageType: String
            let metadata: [String: String]?

            enum CodingKeys: String, CodingKey {
                case content
                case isAi = "is_ai"
                case messageType = "message_type"
                case metadata
            }
        }

        let request = MessageRequest(
            content: content,
            isAi: isAi,
            messageType: messageType,
            metadata: metadata
        )

        return try await api.post("/conversations/\(conversationId)/messages", body: request)
    }

    // MARK: - Archive Conversation

    func archiveConversation(conversationId: String) async throws {
        struct ArchiveResponse: Decodable {
            let message: String
        }

        struct EmptyBody: Encodable {}

        let _: ArchiveResponse = try await api.post(
            "/conversations/\(conversationId)/archive",
            body: EmptyBody()
        )
    }

    // MARK: - Delete Conversation

    func deleteConversation(conversationId: String) async throws {
        struct DeleteResponse: Decodable {
            let message: String
        }

        let _: DeleteResponse = try await api.delete("/conversations/\(conversationId)")
    }

    // MARK: - Get Stats

    func getConversationStats(userId: String) async throws -> ConversationStats {
        return try await api.get(
            "/conversations/stats",
            queryParams: ["user_id": userId]
        )
    }

    // MARK: - Generate Conversation ID

    func generateConversationId() -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let random = String((0..<9).map { _ in "abcdefghijklmnopqrstuvwxyz0123456789".randomElement()! })
        return "conv_\(timestamp)_\(random)"
    }
}
