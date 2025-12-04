/**
 * Vue Coach Chat - Conversation avec l'IA
 * Supporte le streaming, la sélection de coach et plusieurs conversations (style ChatGPT)
 * Utilise ThemeManager pour les couleurs dynamiques
 */

import SwiftUI

// MARK: - CoachChatView (legacy wrapper)
// NOTE: Cette vue n'est plus utilisée directement.
// Utiliser CoachChatContentView avec un ChatViewModel partagé depuis MainTabView
// pour éviter la duplication de ViewModel et améliorer les performances.

struct CoachChatView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    // Récupère le ChatViewModel depuis l'environnement au lieu d'en créer un nouveau
    @EnvironmentObject var chatViewModel: ChatViewModel

    var body: some View {
        CoachChatContentView(viewModel: chatViewModel)
    }
}

// MARK: - CoachChatContentView (utilisé par MainTabView)

struct CoachChatContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            chatContent
        }
        .task {
            await viewModel.initialize(userId: authViewModel.user?.id)
        }
    }

    private var chatContent: some View {
        VStack(spacing: 0) {
            // Coach Header
            CoachHeader(
                coach: viewModel.selectedCoach,
                onTap: { viewModel.showingCoachSelector = true }
            )

            Divider()
                .background(themeManager.borderColor)

            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: ECSpacing.md) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleWithMedia(
                                message: message,
                                coachAvatar: viewModel.selectedCoach.avatar,
                                coachIcon: viewModel.selectedCoach.icon,
                                coachColor: themeManager.sportColor(for: viewModel.selectedCoach.discipline)
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, ECSpacing.md)
                    .padding(.vertical, ECSpacing.sm)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.messages.last?.content) { _ in
                    scrollToBottom(proxy: proxy)
                }
            }

            // Indicateur d'upload/transcription
            if viewModel.isUploading || viewModel.isTranscribing {
                uploadIndicator
            }

            Divider()
                .background(themeManager.borderColor)

            // Input Bar avec support média
            ChatInputBar(
                text: $viewModel.inputText,
                isLoading: viewModel.isSending,
                isFocused: $isInputFocused,
                onSend: sendMessage,
                selectedImages: $viewModel.selectedImages,
                selectedFiles: $viewModel.selectedFiles,
                audioRecorder: viewModel.audioRecorder,
                onVoiceRecordingComplete: handleVoiceRecording
            )
        }
        .background(themeManager.backgroundColor)
        .navigationTitle("Coach")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: sidebarButton,
            trailing: toolbarMenuButton
        )
        .sheet(isPresented: $viewModel.showingCoachSelector) {
            CoachSelectorSheet(
                coaches: viewModel.availableCoaches,
                selectedCoach: viewModel.selectedCoach,
                onSelect: { coach in
                    Task {
                        await viewModel.selectCoach(coach, userId: authViewModel.user?.id)
                    }
                }
            )
            .environmentObject(themeManager)
            .presentationDetents([.medium, .large])
        }
        .alert("Erreur", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    private var uploadIndicator: some View {
        HStack(spacing: ECSpacing.sm) {
            ProgressView()
                .scaleEffect(0.8)

            Text(viewModel.isTranscribing ? "Transcription en cours..." : "Upload en cours...")
                .font(.ecSmall)
                .foregroundColor(themeManager.textSecondary)

            Spacer()
        }
        .padding(.horizontal, ECSpacing.md)
        .padding(.vertical, ECSpacing.xs)
        .background(themeManager.surfaceColor)
    }

    private var sidebarButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                appState.showingChatSidebar.toggle()
            }
        } label: {
            Image(systemName: appState.showingChatSidebar ? "xmark" : "line.3.horizontal")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(themeManager.accentColor)
        }
    }

    private var toolbarMenuButton: some View {
        HStack(spacing: ECSpacing.sm) {
            Button {
                viewModel.startNewConversation()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeManager.accentColor)
            }

            Menu {
                Button {
                    viewModel.showingCoachSelector = true
                } label: {
                    Label("Changer de coach", systemImage: "person.2")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(themeManager.accentColor)
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    private func sendMessage() {
        guard let userId = authViewModel.user?.id else { return }

        // Vérifier s'il y a du contenu à envoyer
        let hasText = !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAttachments = !viewModel.selectedImages.isEmpty || !viewModel.selectedFiles.isEmpty

        guard hasText || hasAttachments else { return }

        Task {
            if hasAttachments {
                await viewModel.sendMessageWithAttachments(userId: userId)
            } else {
                await viewModel.sendMessage(userId: userId)
            }
        }
    }

    private func handleVoiceRecording(url: URL) {
        guard let userId = authViewModel.user?.id else { return }

        Task {
            await viewModel.handleVoiceRecording(url: url, userId: userId)
        }
    }
}

// MARK: - Message Bubble with Media Support

struct MessageBubbleWithMedia: View {
    @EnvironmentObject var themeManager: ThemeManager
    let message: ChatMessage
    var coachAvatar: String = "JF"
    var coachIcon: String = "trophy"
    var coachColor: Color = .blue

    var body: some View {
        HStack(alignment: .bottom, spacing: ECSpacing.sm) {
            if message.isUser {
                Spacer(minLength: 60)
            } else {
                // Coach Avatar
                ZStack {
                    Circle()
                        .fill(coachColor.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: coachIcon)
                        .font(.system(size: 16))
                        .foregroundColor(coachColor)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                // Voice message
                if let voiceMessage = message.voiceMessage {
                    VoiceMessageBubble(
                        voiceMessage: voiceMessage,
                        isUser: message.isUser
                    )
                }

                // Attachments
                if let attachments = message.attachments, !attachments.isEmpty {
                    ForEach(attachments) { attachment in
                        AttachmentBubbleView(
                            attachment: attachment,
                            isUser: message.isUser
                        )
                    }
                }

                // Text content
                if message.isLoading && message.content.isEmpty {
                    // Typing indicator
                    TypingIndicatorBubble(sportIcon: coachIcon, sportColor: coachColor)
                } else if !message.content.isEmpty {
                    HStack(spacing: 0) {
                        Text(message.content)
                            .font(.ecBody)
                            .foregroundColor(message.isUser ? .white : themeManager.textPrimary)

                        // Streaming cursor
                        if message.isLoading && !message.content.isEmpty {
                            StreamingCursor()
                        }
                    }
                    .padding(.horizontal, ECSpacing.md)
                    .padding(.vertical, ECSpacing.sm)
                    .background(
                        message.isUser ? themeManager.accentColor : themeManager.surfaceColor
                    )
                    .clipShape(RoundedRectangle(cornerRadius: ECRadius.lg))
                }

                // Timestamp
                if let timestamp = message.timestamp, !message.isLoading {
                    Text(formatTime(timestamp))
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textTertiary)
                }
            }

            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Conversations Sidebar

struct ConversationsSidebar: View {
    @EnvironmentObject var themeManager: ThemeManager
    let conversations: [LocalConversation]
    let currentConversationId: String?
    let selectedCoach: SelectedCoach
    @Binding var isShowing: Bool
    let onSelectConversation: (LocalConversation) -> Void
    let onNewConversation: () -> Void
    let onDeleteConversation: (LocalConversation) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            sidebarHeader

            Divider()
                .background(themeManager.borderColor)

            // Liste des conversations
            ScrollView {
                LazyVStack(spacing: ECSpacing.xs) {
                    ForEach(conversations) { conversation in
                        ConversationRow(
                            conversation: conversation,
                            isSelected: conversation.id == currentConversationId,
                            onSelect: {
                                onSelectConversation(conversation)
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isShowing = false
                                }
                            },
                            onDelete: {
                                onDeleteConversation(conversation)
                            }
                        )
                    }
                }
                .padding(.horizontal, ECSpacing.sm)
                .padding(.vertical, ECSpacing.md)
            }

            Spacer()

            // Footer avec info coach
            sidebarFooter
        }
        .background(
            themeManager.surfaceColor.opacity(0.98)
                .background(.ultraThinMaterial)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 5, y: 0)
    }

    private var sidebarHeader: some View {
        HStack {
            Text("Conversations")
                .font(.ecH4)
                .foregroundColor(themeManager.textPrimary)

            Spacer()

            Button(action: onNewConversation) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeManager.accentColor)
            }
        }
        .padding(.horizontal, ECSpacing.md)
        .padding(.vertical, ECSpacing.md)
        .background(themeManager.backgroundColor)
    }

    private var sidebarFooter: some View {
        VStack(spacing: ECSpacing.sm) {
            Divider()
                .background(themeManager.borderColor)

            HStack(spacing: ECSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(themeManager.sportColor(for: selectedCoach.discipline).opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: selectedCoach.icon)
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.sportColor(for: selectedCoach.discipline))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedCoach.name)
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                    Text(selectedCoach.speciality)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, ECSpacing.md)
            .padding(.vertical, ECSpacing.sm)
        }
        .background(themeManager.backgroundColor)
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let conversation: LocalConversation
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteConfirm = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: ECSpacing.sm) {
                Image(systemName: "message")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.textSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(conversation.title)
                        .font(.ecLabel)
                        .foregroundColor(isSelected ? themeManager.accentColor : themeManager.textPrimary)
                        .lineLimit(1)

                    Text(formatDate(conversation.updatedAt))
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textTertiary)
                }

                Spacer()
            }
            .padding(.horizontal, ECSpacing.sm)
            .padding(.vertical, ECSpacing.sm)
            .background(isSelected ? themeManager.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(ECRadius.md)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteConfirm = true
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Supprimer cette conversation ?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Supprimer", role: .destructive) {
                onDelete()
            }
            Button("Annuler", role: .cancel) {}
        }
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Hier"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Coach Header

struct CoachHeader: View {
    @EnvironmentObject var themeManager: ThemeManager
    let coach: SelectedCoach
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ECSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(themeManager.sportColor(for: coach.discipline).opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: coach.icon)
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.sportColor(for: coach.discipline))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: ECSpacing.xs) {
                        Text(coach.name)
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(themeManager.textTertiary)
                    }

                    Text(coach.speciality)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }

                Spacer()

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(themeManager.successColor)
                        .frame(width: 8, height: 8)
                    Text("En ligne")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                }
            }
            .padding(.horizontal, ECSpacing.md)
            .padding(.vertical, ECSpacing.sm)
            .background(themeManager.surfaceColor)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Coach Selector Sheet

struct CoachSelectorSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    let coaches: [SelectedCoach]
    let selectedCoach: SelectedCoach
    let onSelect: (SelectedCoach) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSport: SportCategory? = nil

    // Catégories de sport pour la sélection
    enum SportCategory: String, CaseIterable, Identifiable {
        case triathlon = "Triathlon"
        case natation = "Natation"
        case course = "Course à pied"
        case cyclisme = "Cyclisme"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .triathlon: return "trophy"
            case .natation: return "figure.pool.swim"
            case .course: return "figure.run"
            case .cyclisme: return "bicycle"
            }
        }

        var sportKeys: [String] {
            switch self {
            case .triathlon: return ["triathlon"]
            case .natation: return ["natation", "swimming"]
            case .course: return ["course", "course à pied", "running"]
            case .cyclisme: return ["cyclisme", "cycling"]
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    if selectedSport == nil {
                        // Vue principale : sélection du sport
                        sportSelectionView
                    } else {
                        // Vue des coachs pour le sport sélectionné
                        coachListView
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle(selectedSport == nil ? "Choisir un sport" : selectedSport!.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: selectedSport != nil ? backButton : nil,
                trailing: closeButton
            )
        }
    }

    // MARK: - Sport Selection View

    private var sportSelectionView: some View {
        VStack(spacing: ECSpacing.md) {
            Text("Sélectionnez votre discipline")
                .font(.ecBody)
                .foregroundColor(themeManager.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(SportCategory.allCases) { sport in
                SportCategoryCard(
                    sport: sport,
                    coachCount: coachesForSport(sport).count,
                    isCurrentSport: isCurrentCoachSport(sport),
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSport = sport
                        }
                    }
                )
            }
        }
    }

    // MARK: - Coach List View

    private var coachListView: some View {
        VStack(spacing: ECSpacing.md) {
            let sportCoaches = coachesForSport(selectedSport!)

            if sportCoaches.isEmpty {
                emptyStateView
            } else {
                ForEach(sportCoaches) { coach in
                    CoachCard(
                        coach: coach,
                        isSelected: coach.id == selectedCoach.id,
                        onSelect: {
                            onSelect(coach)
                            dismiss()
                        }
                    )
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: ECSpacing.md) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(themeManager.textTertiary)

            Text("Aucun coach disponible")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textSecondary)

            Text("Pas de coach disponible pour cette discipline pour le moment.")
                .font(.ecCaption)
                .foregroundColor(themeManager.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, ECSpacing.xl)
    }

    // MARK: - Navigation Buttons

    private var backButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSport = nil
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("Sports")
            }
            .foregroundColor(themeManager.accentColor)
        }
    }

    private var closeButton: some View {
        Button("Fermer") {
            dismiss()
        }
        .foregroundColor(themeManager.accentColor)
    }

    // MARK: - Helpers

    private func coachesForSport(_ sport: SportCategory) -> [SelectedCoach] {
        coaches.filter { coach in
            sport.sportKeys.contains(coach.sport.lowercased())
        }
    }

    private func isCurrentCoachSport(_ sport: SportCategory) -> Bool {
        sport.sportKeys.contains(selectedCoach.sport.lowercased())
    }
}

// MARK: - Sport Category Card

struct SportCategoryCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let sport: CoachSelectorSheet.SportCategory
    let coachCount: Int
    let isCurrentSport: Bool
    let onTap: () -> Void

    private var sportColor: Color {
        switch sport {
        case .triathlon: return themeManager.accentColor
        case .natation: return themeManager.sportColor(for: .natation)
        case .course: return themeManager.sportColor(for: .course)
        case .cyclisme: return themeManager.sportColor(for: .cyclisme)
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ECSpacing.md) {
                // Icône du sport
                ZStack {
                    Circle()
                        .fill(sportColor.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: sport.icon)
                        .font(.system(size: 28))
                        .foregroundColor(sportColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(sport.rawValue)
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)

                        if isCurrentSport {
                            Text("Actuel")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(sportColor)
                                .cornerRadius(4)
                        }
                    }

                    Text("\(coachCount) coach\(coachCount > 1 ? "s" : "") disponible\(coachCount > 1 ? "s" : "")")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.textTertiary)
            }
            .padding(ECSpacing.md)
            .background(isCurrentSport ? sportColor.opacity(0.05) : themeManager.surfaceColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(isCurrentSport ? sportColor : themeManager.borderColor, lineWidth: isCurrentSport ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CoachCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let coach: SelectedCoach
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: ECSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(themeManager.sportColor(for: coach.discipline).opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: coach.icon)
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.sportColor(for: coach.discipline))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(coach.name)
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(themeManager.successColor)
                                .font(.system(size: 14))
                        }
                    }

                    Text(coach.speciality)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.sportColor(for: coach.discipline))

                    Text(coach.description)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                        .lineLimit(2)

                    // Expertise tags
                    if let expertise = coach.expertise, !expertise.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(expertise.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 10))
                                        .foregroundColor(themeManager.textSecondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(themeManager.surfaceColor)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(ECSpacing.md)
            .background(isSelected ? themeManager.accentColor.opacity(0.05) : themeManager.surfaceColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(isSelected ? themeManager.accentColor : themeManager.borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    @EnvironmentObject var themeManager: ThemeManager
    let message: ChatMessage
    var coachAvatar: String = "JF"
    var coachIcon: String = "trophy"
    var coachColor: Color = .blue

    var body: some View {
        HStack(alignment: .bottom, spacing: ECSpacing.sm) {
            if message.isUser {
                Spacer(minLength: 60)
            } else {
                // Coach Avatar
                ZStack {
                    Circle()
                        .fill(coachColor.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: coachIcon)
                        .font(.system(size: 16))
                        .foregroundColor(coachColor)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if message.isLoading && message.content.isEmpty {
                    // Typing indicator avec icône du sport
                    TypingIndicatorBubble(sportIcon: coachIcon, sportColor: coachColor)
                } else {
                    // Message content with streaming cursor
                    HStack(spacing: 0) {
                        Text(message.content)
                            .font(.ecBody)
                            .foregroundColor(message.isUser ? .white : themeManager.textPrimary)

                        // Streaming cursor
                        if message.isLoading && !message.content.isEmpty {
                            StreamingCursor()
                        }
                    }
                    .padding(.horizontal, ECSpacing.md)
                    .padding(.vertical, ECSpacing.sm)
                    .background(
                        message.isUser ? themeManager.accentColor : themeManager.surfaceColor
                    )
                    .clipShape(RoundedRectangle(cornerRadius: ECRadius.lg))
                }

                if let timestamp = message.timestamp, !message.isLoading {
                    Text(formatTime(timestamp))
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textTertiary)
                }
            }

            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Streaming Cursor

struct StreamingCursor: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isVisible = true

    var body: some View {
        Rectangle()
            .fill(themeManager.accentColor)
            .frame(width: 2, height: 16)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                    isVisible.toggle()
                }
            }
    }
}

// MARK: - Typing Indicator Bubble (avec icône sport animée)

struct TypingIndicatorBubble: View {
    @EnvironmentObject var themeManager: ThemeManager
    var sportIcon: String = "trophy"
    var sportColor: Color = .blue

    @State private var iconScale: CGFloat = 1.0
    @State private var iconRotation: Double = 0
    @State private var dotPhase: Int = 0

    var body: some View {
        HStack(spacing: ECSpacing.sm) {
            // Icône sport animée
            ZStack {
                // Cercle pulse en arrière-plan
                Circle()
                    .fill(sportColor.opacity(0.15))
                    .frame(width: 28, height: 28)
                    .scaleEffect(iconScale)

                Image(systemName: sportIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(sportColor)
                    .rotationEffect(.degrees(iconRotation))
            }

            // Points animés
            HStack(spacing: 3) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(sportColor.opacity(dotPhase == index ? 1.0 : 0.4))
                        .frame(width: 6, height: 6)
                        .scaleEffect(dotPhase == index ? 1.2 : 0.9)
                }
            }
        }
        .padding(.horizontal, ECSpacing.md)
        .padding(.vertical, ECSpacing.sm)
        .background(themeManager.surfaceColor)
        .cornerRadius(ECRadius.lg)
        .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
        .onAppear {
            // Animation de l'icône (pulse)
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                iconScale = 1.15
            }

            // Animation de rotation légère
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                iconRotation = 10
            }

            // Animation des points
            animateDots()
        }
    }

    private func animateDots() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                dotPhase = (dotPhase + 1) % 3
            }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var animationPhase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: ECSpacing.sm) {
            ZStack {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.accentColor)
            }

            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(themeManager.textTertiary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 0.4)
                                .repeatForever()
                                .delay(Double(index) * 0.15),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, ECSpacing.md)
            .padding(.vertical, ECSpacing.sm)
            .background(themeManager.surfaceColor)
            .cornerRadius(ECRadius.lg)

            Spacer()
        }
        .onAppear {
            animationPhase = 1
        }
    }
}

// MARK: - Chat Input Bar (avec support média)

struct ChatInputBar: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var text: String
    let isLoading: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    // Support média
    @Binding var selectedImages: [UIImage]
    @Binding var selectedFiles: [URL]
    @ObservedObject var audioRecorder: AudioRecorderService
    let onVoiceRecordingComplete: (URL) -> Void

    @State private var showingAttachmentPicker = false

    init(
        text: Binding<String>,
        isLoading: Bool,
        isFocused: FocusState<Bool>.Binding,
        onSend: @escaping () -> Void,
        selectedImages: Binding<[UIImage]> = .constant([]),
        selectedFiles: Binding<[URL]> = .constant([]),
        audioRecorder: AudioRecorderService = AudioRecorderService.shared,
        onVoiceRecordingComplete: @escaping (URL) -> Void = { _ in }
    ) {
        self._text = text
        self.isLoading = isLoading
        self.isFocused = isFocused
        self.onSend = onSend
        self._selectedImages = selectedImages
        self._selectedFiles = selectedFiles
        self.audioRecorder = audioRecorder
        self.onVoiceRecordingComplete = onVoiceRecordingComplete
    }

    var body: some View {
        VStack(spacing: 0) {
            // Prévisualisation des attachements
            if !selectedImages.isEmpty || !selectedFiles.isEmpty {
                AttachmentPreviewRow(
                    images: selectedImages,
                    files: selectedFiles,
                    onRemoveImage: { index in
                        selectedImages.remove(at: index)
                    },
                    onRemoveFile: { index in
                        selectedFiles.remove(at: index)
                    }
                )
                .padding(.top, ECSpacing.sm)

                Divider()
                    .background(themeManager.borderColor)
            }

            // Barre d'input principale
            if audioRecorder.state.isRecording || audioRecorder.state == .paused {
                // Mode enregistrement vocal
                VoiceRecordButton(
                    recorder: audioRecorder,
                    onRecordingComplete: onVoiceRecordingComplete,
                    onCancel: {}
                )
                .padding(.horizontal, ECSpacing.md)
                .padding(.vertical, ECSpacing.sm)
            } else {
                // Mode texte normal
                HStack(spacing: ECSpacing.sm) {
                    // Bouton attachement
                    AttachmentPickerButton(
                        selectedImages: $selectedImages,
                        selectedFiles: $selectedFiles,
                        showingPicker: $showingAttachmentPicker
                    )

                    // Champ texte
                    TextField("Écrivez votre message...", text: $text, axis: .vertical)
                        .font(.ecBody)
                        .padding(.horizontal, ECSpacing.md)
                        .padding(.vertical, ECSpacing.sm)
                        .background(themeManager.surfaceColor)
                        .cornerRadius(ECRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: ECRadius.lg)
                                .stroke(themeManager.borderColor, lineWidth: 1)
                        )
                        .lineLimit(1...5)
                        .focused(isFocused)

                    // Bouton micro ou envoyer
                    if canSend {
                        Button(action: onSend) {
                            ZStack {
                                Circle()
                                    .fill(themeManager.accentColor)
                                    .frame(width: 24, height: 24)

                                Image(systemName: "arrow.up")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(isLoading)
                    } else {
                        // Bouton microphone
                        Button {
                            Task {
                                await audioRecorder.startRecording()
                            }
                        } label: {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.textSecondary)
                                .frame(width: 24, height: 24)
                        }
                    }
                }
                .padding(.horizontal, ECSpacing.md)
                .padding(.vertical, ECSpacing.sm)
            }
        }
        .background(themeManager.backgroundColor)
    }

    private var canSend: Bool {
        let hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAttachments = !selectedImages.isEmpty || !selectedFiles.isEmpty
        return (hasText || hasAttachments) && !isLoading
    }
}

// MARK: - Legacy ChatInputBar (rétrocompatibilité)

struct ChatInputBarSimple: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var text: String
    let isLoading: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: ECSpacing.sm) {
            TextField("Écrivez votre message...", text: $text, axis: .vertical)
                .font(.ecBody)
                .padding(.horizontal, ECSpacing.md)
                .padding(.vertical, ECSpacing.sm)
                .background(themeManager.surfaceColor)
                .cornerRadius(ECRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: ECRadius.lg)
                        .stroke(themeManager.borderColor, lineWidth: 1)
                )
                .lineLimit(1...5)
                .focused(isFocused)

            Button(action: onSend) {
                ZStack {
                    Circle()
                        .fill(canSend ? themeManager.accentColor : themeManager.textTertiary)
                        .frame(width: 44, height: 44)

                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, ECSpacing.md)
        .padding(.vertical, ECSpacing.sm)
        .background(themeManager.backgroundColor)
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
}

// MARK: - Quick Actions

struct QuickActionsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let onAction: (String) -> Void

    private let actions = [
        ("Analyser ma semaine", "chart.bar"),
        ("Conseil récupération", "heart.circle"),
        ("Préparer une course", "flag.checkered"),
        ("Ajuster mon plan", "calendar.badge.clock")
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ECSpacing.sm) {
                ForEach(actions, id: \.0) { action in
                    Button {
                        onAction(action.0)
                    } label: {
                        HStack(spacing: ECSpacing.xs) {
                            Image(systemName: action.1)
                                .font(.ecCaption)
                            Text(action.0)
                                .font(.ecCaption)
                        }
                        .padding(.horizontal, ECSpacing.md)
                        .padding(.vertical, ECSpacing.sm)
                        .background(themeManager.accentColor.opacity(0.1))
                        .foregroundColor(themeManager.accentColor)
                        .cornerRadius(ECRadius.full)
                    }
                }
            }
            .padding(.horizontal, ECSpacing.md)
        }
    }
}

#Preview {
    CoachChatView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager.shared)
}
