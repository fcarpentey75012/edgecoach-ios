/**
 * Vue Coach Chat - Conversation avec l'IA
 * Supporte le streaming, la sélection de coach et plusieurs conversations (style ChatGPT)
 */

import SwiftUI

// MARK: - CoachChatView (legacy wrapper)

struct CoachChatView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        CoachChatContentView(viewModel: viewModel)
    }
}

// MARK: - CoachChatContentView (utilisé par MainTabView)

struct CoachChatContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: ChatViewModel
    @State private var messageText = ""
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

            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: ECSpacing.md) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                coachAvatar: viewModel.selectedCoach.avatar,
                                coachIcon: viewModel.selectedCoach.icon,
                                coachColor: Color.sportColor(for: viewModel.selectedCoach.discipline)
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

            Divider()

            // Input Bar
            ChatInputBar(
                text: $messageText,
                isLoading: viewModel.isSending,
                isFocused: $isInputFocused,
                onSend: sendMessage
            )
        }
        .background(Color.ecBackground)
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
            .presentationDetents([.medium, .large])
        }
    }

    private var sidebarButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                appState.showingChatSidebar.toggle()
            }
        } label: {
            Image(systemName: appState.showingChatSidebar ? "xmark" : "line.3.horizontal")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.ecPrimary)
        }
    }

    private var toolbarMenuButton: some View {
        HStack(spacing: ECSpacing.sm) {
            Button {
                viewModel.startNewConversation()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.ecPrimary)
            }

            Menu {
                Button {
                    viewModel.showingCoachSelector = true
                } label: {
                    Label("Changer de coach", systemImage: "person.2")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.ecPrimary)
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
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let userId = authViewModel.user?.id else { return }

        let text = messageText
        messageText = ""

        Task {
            await viewModel.sendMessage(text, userId: userId)
        }
    }
}

// MARK: - Conversations Sidebar

struct ConversationsSidebar: View {
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
            Color.ecSurface.opacity(0.98)
                .background(.ultraThinMaterial)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 5, y: 0)
    }

    private var sidebarHeader: some View {
        HStack {
            Text("Conversations")
                .font(.ecH4)
                .foregroundColor(.ecSecondary800)

            Spacer()

            Button(action: onNewConversation) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.ecPrimary)
            }
        }
        .padding(.horizontal, ECSpacing.md)
        .padding(.vertical, ECSpacing.md)
        .background(Color.ecBackground)
    }

    private var sidebarFooter: some View {
        VStack(spacing: ECSpacing.sm) {
            Divider()

            HStack(spacing: ECSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.sportColor(for: selectedCoach.discipline).opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: selectedCoach.icon)
                        .font(.system(size: 16))
                        .foregroundColor(Color.sportColor(for: selectedCoach.discipline))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedCoach.name)
                        .font(.ecLabelBold)
                        .foregroundColor(.ecSecondary800)
                    Text(selectedCoach.speciality)
                        .font(.ecSmall)
                        .foregroundColor(.ecGray500)
                }

                Spacer()
            }
            .padding(.horizontal, ECSpacing.md)
            .padding(.vertical, ECSpacing.sm)
        }
        .background(Color.ecBackground)
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
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
                    .foregroundColor(isSelected ? .ecPrimary : .ecGray500)

                VStack(alignment: .leading, spacing: 2) {
                    Text(conversation.title)
                        .font(.ecLabel)
                        .foregroundColor(isSelected ? .ecPrimary : .ecSecondary800)
                        .lineLimit(1)

                    Text(formatDate(conversation.updatedAt))
                        .font(.ecSmall)
                        .foregroundColor(.ecGray400)
                }

                Spacer()
            }
            .padding(.horizontal, ECSpacing.sm)
            .padding(.vertical, ECSpacing.sm)
            .background(isSelected ? Color.ecPrimary.opacity(0.1) : Color.clear)
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
    let coach: SelectedCoach
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ECSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.sportColor(for: coach.discipline).opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: coach.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color.sportColor(for: coach.discipline))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: ECSpacing.xs) {
                        Text(coach.name)
                            .font(.ecLabelBold)
                            .foregroundColor(.ecSecondary800)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.ecGray400)
                    }

                    Text(coach.speciality)
                        .font(.ecCaption)
                        .foregroundColor(.ecGray500)
                }

                Spacer()

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.ecSuccess)
                        .frame(width: 8, height: 8)
                    Text("En ligne")
                        .font(.ecSmall)
                        .foregroundColor(.ecGray500)
                }
            }
            .padding(.horizontal, ECSpacing.md)
            .padding(.vertical, ECSpacing.sm)
            .background(Color.ecSurface)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Coach Selector Sheet

struct CoachSelectorSheet: View {
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

        var color: Color {
            switch self {
            case .triathlon: return .ecTriathlon
            case .natation: return .ecSwimming
            case .course: return .ecRunning
            case .cyclisme: return .ecCycling
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
            .background(Color.ecBackground)
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
                .foregroundColor(.ecGray600)
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
                .foregroundColor(.ecGray400)

            Text("Aucun coach disponible")
                .font(.ecLabelBold)
                .foregroundColor(.ecGray600)

            Text("Pas de coach disponible pour cette discipline pour le moment.")
                .font(.ecCaption)
                .foregroundColor(.ecGray500)
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
            .foregroundColor(.ecPrimary)
        }
    }

    private var closeButton: some View {
        Button("Fermer") {
            dismiss()
        }
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
    let sport: CoachSelectorSheet.SportCategory
    let coachCount: Int
    let isCurrentSport: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ECSpacing.md) {
                // Icône du sport
                ZStack {
                    Circle()
                        .fill(sport.color.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: sport.icon)
                        .font(.system(size: 28))
                        .foregroundColor(sport.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(sport.rawValue)
                            .font(.ecLabelBold)
                            .foregroundColor(.ecSecondary800)

                        if isCurrentSport {
                            Text("Actuel")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(sport.color)
                                .cornerRadius(4)
                        }
                    }

                    Text("\(coachCount) coach\(coachCount > 1 ? "s" : "") disponible\(coachCount > 1 ? "s" : "")")
                        .font(.ecCaption)
                        .foregroundColor(.ecGray500)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.ecGray400)
            }
            .padding(ECSpacing.md)
            .background(isCurrentSport ? sport.color.opacity(0.05) : Color.ecSurface)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(isCurrentSport ? sport.color : Color.ecGray200, lineWidth: isCurrentSport ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CoachCard: View {
    let coach: SelectedCoach
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: ECSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.sportColor(for: coach.discipline).opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: coach.icon)
                        .font(.system(size: 24))
                        .foregroundColor(Color.sportColor(for: coach.discipline))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(coach.name)
                            .font(.ecLabelBold)
                            .foregroundColor(.ecSecondary800)

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.ecSuccess)
                                .font(.system(size: 14))
                        }
                    }

                    Text(coach.speciality)
                        .font(.ecCaption)
                        .foregroundColor(Color.sportColor(for: coach.discipline))

                    Text(coach.description)
                        .font(.ecSmall)
                        .foregroundColor(.ecGray500)
                        .lineLimit(2)

                    // Expertise tags
                    if let expertise = coach.expertise, !expertise.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(expertise.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 10))
                                        .foregroundColor(.ecGray600)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.ecGray100)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(ECSpacing.md)
            .background(isSelected ? Color.ecPrimary.opacity(0.05) : Color.ecSurface)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(isSelected ? Color.ecPrimary : Color.ecGray200, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    var coachAvatar: String = "JF"
    var coachIcon: String = "trophy"
    var coachColor: Color = .ecPrimary

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
                            .foregroundColor(message.isUser ? .white : .ecSecondary800)

                        // Streaming cursor
                        if message.isLoading && !message.content.isEmpty {
                            StreamingCursor()
                        }
                    }
                    .padding(.horizontal, ECSpacing.md)
                    .padding(.vertical, ECSpacing.sm)
                    .background(
                        message.isUser ? Color.ecPrimary : Color.ecSurface
                    )
                    .clipShape(RoundedRectangle(cornerRadius: ECRadius.lg))
                }

                if let timestamp = message.timestamp, !message.isLoading {
                    Text(formatTime(timestamp))
                        .font(.ecSmall)
                        .foregroundColor(.ecGray400)
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
    @State private var isVisible = true

    var body: some View {
        Rectangle()
            .fill(Color.ecPrimary)
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
    var sportIcon: String = "trophy"
    var sportColor: Color = .ecPrimary

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
        .background(Color.ecSurface)
        .cornerRadius(ECRadius.lg)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
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
    @State private var animationPhase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: ECSpacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.ecPrimary100)
                    .frame(width: 32, height: 32)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16))
                    .foregroundColor(.ecPrimary)
            }

            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.ecGray400)
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
            .background(Color.ecSurface)
            .cornerRadius(ECRadius.lg)

            Spacer()
        }
        .onAppear {
            animationPhase = 1
        }
    }
}

// MARK: - Chat Input Bar

struct ChatInputBar: View {
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
                .background(Color.ecSurface)
                .cornerRadius(ECRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: ECRadius.lg)
                        .stroke(Color.ecGray200, lineWidth: 1)
                )
                .lineLimit(1...5)
                .focused(isFocused)

            Button(action: onSend) {
                ZStack {
                    Circle()
                        .fill(canSend ? Color.ecPrimary : Color.ecGray300)
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
        .background(Color.ecBackground)
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
}

// MARK: - Quick Actions

struct QuickActionsView: View {
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
                        .background(Color.ecPrimary50)
                        .foregroundColor(.ecPrimary)
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
}
