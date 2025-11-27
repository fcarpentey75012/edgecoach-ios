/**
 * Vue principale avec les onglets
 */

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tabItem {
                    Label(MainTab.dashboard.title, systemImage: MainTab.dashboard.icon)
                }
                .tag(MainTab.dashboard)

            CoachChatView()
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
        .tint(.ecPrimary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppState())
}
