/**
 * ViewModel pour le Chat Coach
 * Supporte le streaming de la réponse et la sélection de coach via API
 * Gère plusieurs conversations locales (style ChatGPT)
 */

import SwiftUI
import Combine

// MARK: - Local Conversation Model

struct LocalConversation: Identifiable, Codable {
    let id: String
    var title: String
    var messages: [ChatMessage]
    var coachId: String
    var createdAt: Date
    var updatedAt: Date

    init(id: String = UUID().uuidString, title: String = "Nouvelle conversation", messages: [ChatMessage] = [], coachId: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.messages = messages
        self.coachId = coachId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Génère un titre basé sur le premier message utilisateur
    mutating func generateTitle() {
        if let firstUserMessage = messages.first(where: { $0.role == .user }) {
            let content = firstUserMessage.content
            title = String(content.prefix(40)) + (content.count > 40 ? "..." : "")
        }
    }
}

@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var isSending: Bool = false
    @Published var isStreaming: Bool = false
    @Published var error: String?

    @Published var selectedCoach: SelectedCoach = CoachService.availableCoaches[0]
    @Published var availableCoaches: [SelectedCoach] = CoachService.availableCoaches
    @Published var conversationId: String?

    // Conversations locales
    @Published var localConversations: [LocalConversation] = []
    @Published var currentConversationId: String?
    @Published var showingConversationList: Bool = false
    @Published var showingCoachSelector: Bool = false

    // ID du message en cours de streaming
    private var streamingMessageId: String?

    // Storage key pour les conversations locales
    private let conversationsStorageKey = "localConversations"

    // MARK: - Services

    private let chatService = ChatService.shared
    private let coachService = CoachService.shared

    // MARK: - Initialize

    private var isInitialized = false

    func initialize(userId: String?) async {
        // Éviter de réinitialiser si déjà fait
        guard !isInitialized else { return }
        isInitialized = true

        // Charger le coach sélectionné depuis l'API ou le stockage local
        selectedCoach = await coachService.initialize(userId: userId)
        availableCoaches = coachService.getAllCoaches()

        // Charger les conversations locales
        loadLocalConversations()

        // Démarrer une nouvelle conversation avec le message de bienvenue seulement si pas de messages
        if messages.isEmpty && currentConversationId == nil {
            startNewConversation()
        }
    }

    // MARK: - Local Conversations Management

    /// Charge les conversations depuis UserDefaults
    private func loadLocalConversations() {
        if let data = UserDefaults.standard.data(forKey: conversationsStorageKey),
           let conversations = try? JSONDecoder().decode([LocalConversation].self, from: data) {
            localConversations = conversations.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    /// Sauvegarde les conversations dans UserDefaults
    private func saveLocalConversations() {
        if let data = try? JSONEncoder().encode(localConversations) {
            UserDefaults.standard.set(data, forKey: conversationsStorageKey)
        }
    }

    /// Sauvegarde la conversation actuelle
    private func saveCurrentConversation() {
        guard let currentId = currentConversationId else { return }

        if let index = localConversations.firstIndex(where: { $0.id == currentId }) {
            localConversations[index].messages = messages
            localConversations[index].updatedAt = Date()
            localConversations[index].generateTitle()
        }

        // Trier par date de mise à jour
        localConversations.sort { $0.updatedAt > $1.updatedAt }
        saveLocalConversations()
    }

    /// Sélectionne une conversation existante
    func selectConversation(_ conversation: LocalConversation) {
        // Sauvegarder la conversation actuelle avant de changer
        saveCurrentConversation()

        currentConversationId = conversation.id
        messages = conversation.messages

        // Charger le coach associé
        if let coach = availableCoaches.first(where: { $0.id == conversation.coachId }) {
            selectedCoach = coach
        }

        showingConversationList = false
    }

    /// Supprime une conversation locale
    func deleteLocalConversation(_ conversation: LocalConversation) {
        localConversations.removeAll { $0.id == conversation.id }
        saveLocalConversations()

        // Si c'était la conversation active, en créer une nouvelle
        if currentConversationId == conversation.id {
            startNewConversation()
        }
    }

    /// Renomme une conversation
    func renameConversation(_ conversation: LocalConversation, newTitle: String) {
        if let index = localConversations.firstIndex(where: { $0.id == conversation.id }) {
            localConversations[index].title = newTitle
            saveLocalConversations()
        }
    }

    // MARK: - Send Message with Streaming

    func sendMessage(_ text: String, userId: String) async {
        inputText = text
        await sendMessage(userId: userId)
    }

    func sendMessage(userId: String) async {
        let messageText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }

        // Clear input immediately
        inputText = ""
        isSending = true
        isStreaming = true
        error = nil

        // Add user message
        let userMessageId = UUID().uuidString
        let userMessage = ChatMessage(
            id: userMessageId,
            role: .user,
            content: messageText
        )
        messages.append(userMessage)

        #if DEBUG
        print("📤 User message added: \(messageText) (id: \(userMessageId))")
        print("📊 Total messages: \(messages.count)")
        #endif

        // Add empty assistant message for streaming
        let assistantMessageId = UUID().uuidString
        streamingMessageId = assistantMessageId
        let assistantMessage = ChatMessage(
            id: assistantMessageId,
            role: .assistant,
            content: "",
            isLoading: true
        )
        messages.append(assistantMessage)

        #if DEBUG
        print("🤖 Assistant message placeholder added (id: \(assistantMessageId))")
        print("📊 Total messages: \(messages.count)")
        #endif

        do {
            // Préparer l'historique (sans le message en cours de streaming et le message actuel)
            let historyMessages = messages.filter {
                $0.id != assistantMessageId && $0.id != userMessage.id
            }

            // Utiliser le streaming simulé pour garantir l'effet mot par mot
            let fullResponse = try await chatService.sendMessageWithSimulatedStreaming(
                userId: userId,
                message: messageText,
                conversationHistory: historyMessages
            ) { [weak self] chunk in
                guard let self = self else { return }
                // Mettre à jour le message avec le nouveau chunk
                if let index = self.messages.firstIndex(where: { $0.id == assistantMessageId }) {
                    let currentContent = self.messages[index].content
                    self.messages[index] = ChatMessage(
                        id: assistantMessageId,
                        role: .assistant,
                        content: currentContent + chunk,
                        isLoading: true
                    )
                }
            }

            // Finaliser le message (enlever l'état loading)
            if let index = messages.firstIndex(where: { $0.id == assistantMessageId }) {
                messages[index] = ChatMessage(
                    id: assistantMessageId,
                    role: .assistant,
                    content: fullResponse,
                    isLoading: false
                )
            }

            #if DEBUG
            print("✅ Streaming complete. Total messages: \(messages.count)")
            for (i, msg) in messages.enumerated() {
                print("  [\(i)] \(msg.role): \(msg.content.prefix(50))...")
            }
            #endif

        } catch {
            // En cas d'erreur, supprimer le message vide
            messages.removeAll { $0.id == assistantMessageId }
            self.error = "Erreur: \(error.localizedDescription)"

            #if DEBUG
            print("❌ Chat error: \(error)")
            #endif
        }

        streamingMessageId = nil
        isStreaming = false
        isSending = false

        // Sauvegarder la conversation après chaque échange
        saveCurrentConversation()
    }

    // MARK: - Load Messages (initial load)

    func loadMessages(userId: String) async {
        await initialize(userId: userId)
    }


    // MARK: - New Conversation

    func startNewConversation() {
        // Sauvegarder la conversation actuelle avant d'en créer une nouvelle
        saveCurrentConversation()

        // Créer une nouvelle conversation locale
        let newConversationId = UUID().uuidString
        let welcomeMessage = ChatMessage(
            role: .assistant,
            content: "Bonjour ! Je suis \(selectedCoach.name), votre coach \(selectedCoach.speciality). \(selectedCoach.description) Comment puis-je vous aider aujourd'hui ?"
        )

        let newConversation = LocalConversation(
            id: newConversationId,
            title: "Nouvelle conversation",
            messages: [welcomeMessage],
            coachId: selectedCoach.id
        )

        localConversations.insert(newConversation, at: 0)
        currentConversationId = newConversationId
        messages = [welcomeMessage]
        showingConversationList = false

        saveLocalConversations()
    }

    // MARK: - Change Coach

    func selectCoach(_ coach: SelectedCoach, userId: String?) async {
        selectedCoach = coach
        showingCoachSelector = false

        // Synchroniser avec le backend
        _ = await coachService.selectCoach(coach, userId: userId)

        // Démarrer une nouvelle conversation avec le nouveau coach
        startNewConversation()
    }

    // MARK: - Prefilled Message (from session context)

    /// Définit un message pré-rempli dans le champ de saisie
    func setPrefilledMessage(_ message: String) {
        inputText = message
    }

    // MARK: - Computed Properties

    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }
}
