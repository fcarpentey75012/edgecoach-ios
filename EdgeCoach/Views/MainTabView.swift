/**
 * Vue principale avec les onglets
 * Gère la sidebar du chat au niveau global pour couvrir la tab bar
 */

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var chatViewModel = ChatViewModel()

    private let sidebarWidth: CGFloat = 280

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Main TabView - se décale vers la droite quand sidebar ouverte
                TabView(selection: $appState.selectedTab) {
                    DashboardView()
                        .tabItem {
                            Label(MainTab.dashboard.title, systemImage: MainTab.dashboard.icon)
                        }
                        .tag(MainTab.dashboard)

                    CoachChatContentView(viewModel: chatViewModel)
                        .tabItem {
                            Label(MainTab.coach.title, systemImage: MainTab.coach.icon)
                        }
                        .tag(MainTab.coach)

                    CalendarView()
                        .tabItem {
                            Label(MainTab.calendar.title, systemImage: MainTab.calendar.icon)
                        }
                        .tag(MainTab.calendar)

                    StatsView()
                        .tabItem {
                            Label(MainTab.stats.title, systemImage: MainTab.stats.icon)
                        }
                        .tag(MainTab.stats)

                    ProfileView()
                        .tabItem {
                            Label(MainTab.profile.title, systemImage: MainTab.profile.icon)
                        }
                        .tag(MainTab.profile)
                }
                .tint(themeManager.accentColor)
                .offset(x: appState.showingChatSidebar ? sidebarWidth : 0)
                .disabled(appState.showingChatSidebar)
                .accessibilityIdentifier("mainTabView")

                // Overlay sombre quand sidebar ouverte
                if appState.showingChatSidebar {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .offset(x: sidebarWidth)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                appState.showingChatSidebar = false
                            }
                        }
                }

                // Sidebar des conversations (visible uniquement sur l'onglet Coach)
                if appState.selectedTab == .coach {
                    ConversationsSidebar(
                        conversations: chatViewModel.localConversations,
                        currentConversationId: chatViewModel.currentConversationId,
                        selectedCoach: chatViewModel.selectedCoach,
                        isShowing: $appState.showingChatSidebar,
                        onSelectConversation: { conversation in
                            chatViewModel.selectConversation(conversation)
                        },
                        onNewConversation: {
                            chatViewModel.startNewConversation()
                        },
                        onDeleteConversation: { conversation in
                            chatViewModel.deleteLocalConversation(conversation)
                        }
                    )
                    .frame(width: sidebarWidth)
                    .offset(x: appState.showingChatSidebar ? 0 : -sidebarWidth)
                    .ignoresSafeArea(.container, edges: .vertical)
                }
            }
        }
        .onChange(of: appState.selectedTab) { newTab in
            // Fermer la sidebar si on change d'onglet
            if newTab != .coach && appState.showingChatSidebar {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    appState.showingChatSidebar = false
                }
            }
        }
        .onChange(of: appState.prefilledChatMessage) { newMessage in
            // Quand un message pré-rempli est défini (depuis une séance), le passer au chat
            if let message = newMessage {
                chatViewModel.setPrefilledMessage(message)
                appState.prefilledChatMessage = nil
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppState())
        .environmentObject(ThemeManager.shared)
}
