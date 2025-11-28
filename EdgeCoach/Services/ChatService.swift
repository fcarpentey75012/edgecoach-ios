/**
 * Service Chat
 * Communication avec le coach IA avec support streaming
 * Aligné avec l'API backend Flask /api/chat
 */

import Foundation

// MARK: - API Request/Response Models

struct APIChatMessage: Codable {
    let content: String
    let isAi: Bool
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case content
        case isAi = "is_ai"
        case timestamp
    }
}

struct ConversationSummary: Decodable, Identifiable {
    let id: String
    let title: String?
    let lastMessage: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title
        case lastMessage = "last_message"
        case updatedAt = "updated_at"
    }
}

// MARK: - Chat Service

@MainActor
class ChatService {
    static let shared = ChatService()
    private let api = APIService.shared

    private init() {}

    // MARK: - Send Message with Streaming

    /// Envoie un message au coach IA avec streaming de la réponse
    /// Le callback onChunk est appelé pour chaque morceau de texte reçu
    func sendMessageStreaming(
        userId: String,
        message: String,
        conversationHistory: [ChatMessage] = [],
        onChunk: @escaping (String) -> Void
    ) async throws -> String {
        // Construire l'URL avec les query params
        let baseUrl = api.baseURL.replacingOccurrences(of: "/api", with: "")
        let urlString = "\(baseUrl)/api/chat?user_id=\(userId)"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        // Préparer le body
        let isoFormatter = ISO8601DateFormatter()
        let historyMessages = conversationHistory.map { msg in
            APIChatMessage(
                content: msg.content,
                isAi: msg.role == .assistant,
                timestamp: msg.timestamp.map { isoFormatter.string(from: $0) }
            )
        }

        struct ChatBody: Encodable {
            let message: String
            let conversationHistory: [APIChatMessage]

            enum CodingKeys: String, CodingKey {
                case message
                case conversationHistory = "conversation_history"
            }
        }

        let body = ChatBody(message: message, conversationHistory: historyMessages)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/plain", forHTTPHeaderField: "Accept")

        // Ajouter le token d'auth si disponible
        if let token = api.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder().encode(body)

        // Utiliser URLSession avec bytes pour le streaming
        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "", code: -1))
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode, "Erreur serveur")
        }

        // Lire les bytes en streaming mot par mot
        var fullResponse = ""
        var wordBuffer = ""

        for try await byte in bytes {
            if let char = String(bytes: [byte], encoding: .utf8) {
                fullResponse += char
                wordBuffer += char

                // Détecter la fin d'un mot (espace, ponctuation, nouvelle ligne)
                let isWordBoundary = char == " " || char == "\n" || char == "." ||
                                     char == "," || char == "!" || char == "?" ||
                                     char == ":" || char == ";"

                if isWordBoundary && !wordBuffer.isEmpty {
                    let wordToSend = wordBuffer
                    wordBuffer = ""

                    // Envoyer le mot au callback
                    await MainActor.run {
                        onChunk(wordToSend)
                    }

                    // Petit délai pour effet visuel de streaming
                    try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
                }
            }
        }

        // Envoyer le reste du buffer s'il y en a
        if !wordBuffer.isEmpty {
            await MainActor.run {
                onChunk(wordBuffer)
            }
        }

        return fullResponse
    }

    // MARK: - Send Message with Simulated Streaming

    /// Envoie un message et simule le streaming mot par mot côté client
    /// Utile si le backend ne supporte pas le vrai streaming
    func sendMessageWithSimulatedStreaming(
        userId: String,
        message: String,
        conversationHistory: [ChatMessage] = [],
        onChunk: @escaping (String) -> Void
    ) async throws -> String {
        // D'abord, obtenir la réponse complète
        let (fullResponse, _) = try await sendMessage(
            userId: userId,
            message: message,
            conversationHistory: conversationHistory
        )

        // Simuler le streaming mot par mot
        let words = fullResponse.components(separatedBy: .whitespaces)
        var streamedText = ""

        for (index, word) in words.enumerated() {
            // Ajouter l'espace avant le mot (sauf pour le premier)
            let chunk = index == 0 ? word : " " + word
            streamedText += chunk

            await MainActor.run {
                onChunk(chunk)
            }

            // Délai entre les mots pour l'effet de streaming (30-50ms)
            let delay = UInt64.random(in: 25_000_000...45_000_000)
            try? await Task.sleep(nanoseconds: delay)
        }

        return fullResponse
    }

    // MARK: - Send Message (non-streaming fallback)

    /// Envoie un message au coach IA via l'endpoint /api/chat
    /// L'API renvoie directement le texte de la réponse (pas de JSON)
    func sendMessage(
        userId: String,
        message: String,
        conversationHistory: [ChatMessage] = [],
        conversationId: String? = nil,
        coachId: String? = nil
    ) async throws -> (response: String, conversationId: String?) {
        // Construire l'URL avec les query params
        let baseUrl = api.baseURL.replacingOccurrences(of: "/api", with: "")
        let urlString = "\(baseUrl)/api/chat?user_id=\(userId)"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        // Préparer le body
        let isoFormatter = ISO8601DateFormatter()
        let historyMessages = conversationHistory.map { msg in
            APIChatMessage(
                content: msg.content,
                isAi: msg.role == .assistant,
                timestamp: msg.timestamp.map { isoFormatter.string(from: $0) }
            )
        }

        struct ChatBody: Encodable {
            let message: String
            let conversationHistory: [APIChatMessage]

            enum CodingKeys: String, CodingKey {
                case message
                case conversationHistory = "conversation_history"
            }
        }

        let body = ChatBody(message: message, conversationHistory: historyMessages)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/plain", forHTTPHeaderField: "Accept")

        // Ajouter le token d'auth si disponible
        if let token = api.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "", code: -1))
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Erreur inconnue"
            throw APIError.httpError(httpResponse.statusCode, errorMessage)
        }

        // L'API renvoie directement le texte
        let responseText = String(data: data, encoding: .utf8) ?? ""

        return (responseText, conversationId)
    }

    // MARK: - Get Conversations

    func getConversations(userId: String) async throws -> [ConversationSummary] {
        struct ConversationsResponse: Decodable {
            let success: Bool?
            let conversations: [ConversationSummary]?
        }

        do {
            let response: ConversationsResponse = try await api.get(
                "/chat/conversations",
                queryParams: ["user_id": userId]
            )
            return response.conversations ?? []
        } catch {
            // L'endpoint peut ne pas exister
            return []
        }
    }

    // MARK: - Get Conversation History

    func getConversationHistory(
        conversationId: String
    ) async throws -> [ChatMessage] {
        struct HistoryResponse: Decodable {
            let success: Bool?
            let messages: [MessageData]?

            struct MessageData: Decodable {
                let id: String?
                let role: String?
                let content: String
                let isAi: Bool?
                let timestamp: String?

                enum CodingKeys: String, CodingKey {
                    case id = "_id"
                    case role
                    case content
                    case isAi = "is_ai"
                    case timestamp
                }
            }
        }

        let response: HistoryResponse = try await api.get(
            "/chat/conversations/\(conversationId)"
        )

        return (response.messages ?? []).map { msg in
            let role: MessageRole
            if let isAi = msg.isAi {
                role = isAi ? .assistant : .user
            } else if let roleStr = msg.role {
                role = MessageRole(rawValue: roleStr) ?? .user
            } else {
                role = .user
            }

            return ChatMessage(
                id: msg.id ?? UUID().uuidString,
                role: role,
                content: msg.content,
                timestamp: parseTimestamp(msg.timestamp) ?? Date()
            )
        }
    }

    // MARK: - Delete Conversation

    func deleteConversation(conversationId: String) async throws {
        struct DeleteResponse: Decodable {
            let success: Bool?
        }

        let _: DeleteResponse = try await api.delete("/chat/conversations/\(conversationId)")
    }

    // MARK: - Helpers

    private func parseTimestamp(_ string: String?) -> Date? {
        guard let string = string else { return nil }

        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss"
        ]

        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }
}
