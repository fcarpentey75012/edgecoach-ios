/**
 * ViewModel pour le Chat Coach
 * Supporte le streaming de la réponse et la sélection de coach via API
 * Gère plusieurs conversations locales (style ChatGPT)
 * Support des médias (fichiers, images, messages vocaux)
 */

import SwiftUI
import Combine
import UIKit
import AVFoundation

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

    @Published var selectedCoach: SelectedCoach = CoachService.defaultCoach
    @Published var conversationId: String?

    // Conversations locales
    @Published var localConversations: [LocalConversation] = []
    @Published var currentConversationId: String?
    @Published var showingConversationList: Bool = false
    @Published var showingCoachingConfig: Bool = false
    @Published var coachingConfig: CoachingConfig = CoachingConfigService.shared.config

    // Support média
    @Published var selectedImages: [UIImage] = []
    @Published var selectedFiles: [URL] = []
    @Published var isUploading: Bool = false
    @Published var isTranscribing: Bool = false
    @Published var uploadProgress: Double = 0

    // ID du message en cours de streaming
    private var streamingMessageId: String?

    // Storage key pour les conversations locales
    private let conversationsStorageKey = "localConversations"

    // MARK: - Services

    private let chatService = ChatService.shared
    private let coachService = CoachService.shared
    private let mediaService = MediaService.shared
    let audioRecorder = AudioRecorderService.shared

    // MARK: - Initialize

    private var isInitialized = false

    func initialize(userId: String?) async {
        // Éviter de réinitialiser si déjà fait
        guard !isInitialized else { return }
        isInitialized = true

        // Charger le coach basé sur la configuration actuelle
        selectedCoach = await coachService.initialize(userId: userId)

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

        // Utiliser le coach basé sur la config actuelle
        selectedCoach = CoachService.defaultCoach

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
        let config = CoachingConfigService.shared.config
        let welcomeMessage = ChatMessage(
            role: .assistant,
            content: "Bonjour ! Je suis votre coach \(config.sport.displayName). \(config.style.description) Comment puis-je vous aider aujourd'hui ?"
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

    /// Met à jour la configuration du coaching
    func updateCoachingConfig(_ newConfig: CoachingConfig, userId: String?) async {
        coachingConfig = newConfig
        CoachingConfigService.shared.updateConfig(newConfig)

        // Mettre à jour le coach basé sur la nouvelle config
        selectedCoach = CoachService.coachFromConfig(newConfig)
        coachService.updateFromConfig()

        showingCoachingConfig = false

        // Démarrer une nouvelle conversation avec la nouvelle config
        startNewConversation()
    }

    // MARK: - Prefilled Message (from session context)

    /// Définit un message pré-rempli dans le champ de saisie
    func setPrefilledMessage(_ message: String) {
        inputText = message
    }

    // MARK: - Computed Properties

    var canSend: Bool {
        let hasText = !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAttachments = !selectedImages.isEmpty || !selectedFiles.isEmpty
        return (hasText || hasAttachments) && !isSending
    }

    var hasAttachments: Bool {
        !selectedImages.isEmpty || !selectedFiles.isEmpty
    }

    // MARK: - Media Methods

    /// Efface les attachements sélectionnés
    func clearAttachments() {
        selectedImages.removeAll()
        selectedFiles.removeAll()
    }

    /// Envoie un message avec des attachements
    func sendMessageWithAttachments(userId: String) async {
        let messageText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Vérifier qu'il y a quelque chose à envoyer
        guard !messageText.isEmpty || !selectedImages.isEmpty || !selectedFiles.isEmpty else { return }

        // Clear input immediately
        let imagesToUpload = selectedImages
        let filesToUpload = selectedFiles
        inputText = ""
        clearAttachments()

        isSending = true
        isUploading = true
        error = nil

        // Upload les fichiers et créer les attachements
        var attachments: [MessageAttachment] = []

        do {
            // Upload images
            for (index, image) in imagesToUpload.enumerated() {
                let fileName = "image_\(UUID().uuidString.prefix(8)).jpg"
                let attachment = try await mediaService.uploadImage(image, fileName: fileName)
                attachments.append(attachment)
                uploadProgress = Double(index + 1) / Double(imagesToUpload.count + filesToUpload.count)
            }

            // Upload fichiers
            for (index, fileURL) in filesToUpload.enumerated() {
                let attachment = try await mediaService.uploadFromURL(fileURL)
                attachments.append(attachment)
                uploadProgress = Double(imagesToUpload.count + index + 1) / Double(imagesToUpload.count + filesToUpload.count)
            }

        } catch {
            self.error = "Erreur upload: \(error.localizedDescription)"
            isSending = false
            isUploading = false
            return
        }

        isUploading = false

        // Construire le contenu du message pour l'IA
        var aiMessageContent = messageText

        // Ajouter les infos sur les fichiers pour le contexte de l'IA
        for attachment in attachments {
            if attachment.type == .document, let extractedText = attachment.extractedText {
                aiMessageContent += "\n\n[Document: \(attachment.fileName)]\n\(extractedText.prefix(2000))"
            } else if attachment.type == .image {
                aiMessageContent += "\n\n[Image jointe: \(attachment.fileName)]"
            }
        }

        // Créer le message utilisateur avec attachements
        let userMessageId = UUID().uuidString
        let userMessage = ChatMessage(
            id: userMessageId,
            role: .user,
            content: messageText,
            attachments: attachments.isEmpty ? nil : attachments
        )
        messages.append(userMessage)

        #if DEBUG
        print("📤 User message with \(attachments.count) attachments")
        #endif

        // Envoyer au chat et recevoir la réponse
        await sendAssistantResponse(userId: userId, userMessageContent: aiMessageContent, userMessageId: userMessageId)
    }

    /// Traite un enregistrement vocal
    func handleVoiceRecording(url: URL, userId: String) async {
        isSending = true
        isTranscribing = true
        error = nil

        // Obtenir la durée audio
        let duration = getAudioDuration(url: url)

        // Créer un message vocal temporaire (en cours de transcription)
        let voiceMessageId = UUID().uuidString
        var voiceMessage = VoiceMessage(
            id: voiceMessageId,
            duration: duration,
            localURL: url,
            isTranscribing: true
        )

        let userMessage = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: "",
            voiceMessage: voiceMessage
        )
        messages.append(userMessage)

        #if DEBUG
        print("🎤 Voice message added, transcribing...")
        #endif

        do {
            // Transcrire l'audio
            let transcriptionResult = try await mediaService.transcribeAudio(fileURL: url)

            guard let transcribedText = transcriptionResult.text, !transcribedText.isEmpty else {
                throw MediaServiceError.transcriptionFailed("Transcription vide")
            }

            // Mettre à jour le message avec la transcription
            voiceMessage = VoiceMessage(
                id: voiceMessageId,
                duration: duration,
                localURL: url,
                transcription: transcribedText,
                isTranscribing: false
            )

            if let index = messages.lastIndex(where: { $0.voiceMessage?.id == voiceMessageId }) {
                messages[index].voiceMessage = voiceMessage
                messages[index].content = transcribedText
            }

            #if DEBUG
            print("✅ Transcription: \(transcribedText.prefix(50))...")
            #endif

            isTranscribing = false

            // Envoyer au chat
            await sendAssistantResponse(userId: userId, userMessageContent: transcribedText, userMessageId: userMessage.id)

        } catch {
            // En cas d'erreur, marquer comme échoué
            if let index = messages.lastIndex(where: { $0.voiceMessage?.id == voiceMessageId }) {
                messages[index].voiceMessage = VoiceMessage(
                    id: voiceMessageId,
                    duration: duration,
                    localURL: url,
                    transcription: nil,
                    isTranscribing: false
                )
            }

            self.error = "Erreur transcription: \(error.localizedDescription)"
            isTranscribing = false
            isSending = false

            #if DEBUG
            print("❌ Transcription error: \(error)")
            #endif
        }
    }

    /// Envoie la réponse de l'assistant (utilisé après upload ou transcription)
    private func sendAssistantResponse(userId: String, userMessageContent: String, userMessageId: String) async {
        isStreaming = true

        // Ajouter un message assistant vide pour le streaming
        let assistantMessageId = UUID().uuidString
        streamingMessageId = assistantMessageId
        let assistantMessage = ChatMessage(
            id: assistantMessageId,
            role: .assistant,
            content: "",
            isLoading: true
        )
        messages.append(assistantMessage)

        do {
            // Préparer l'historique
            let historyMessages = messages.filter {
                $0.id != assistantMessageId && $0.id != userMessageId
            }

            // Envoyer au chat avec streaming
            let fullResponse = try await chatService.sendMessageWithSimulatedStreaming(
                userId: userId,
                message: userMessageContent,
                conversationHistory: historyMessages
            ) { [weak self] chunk in
                guard let self = self else { return }
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

            // Finaliser
            if let index = messages.firstIndex(where: { $0.id == assistantMessageId }) {
                messages[index] = ChatMessage(
                    id: assistantMessageId,
                    role: .assistant,
                    content: fullResponse,
                    isLoading: false
                )
            }

        } catch {
            messages.removeAll { $0.id == assistantMessageId }
            self.error = "Erreur: \(error.localizedDescription)"

            #if DEBUG
            print("❌ Chat error: \(error)")
            #endif
        }

        streamingMessageId = nil
        isStreaming = false
        isSending = false
        saveCurrentConversation()
    }

    /// Obtient la durée d'un fichier audio
    private func getAudioDuration(url: URL) -> TimeInterval {
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            return audioPlayer.duration
        } catch {
            return 0
        }
    }
}
