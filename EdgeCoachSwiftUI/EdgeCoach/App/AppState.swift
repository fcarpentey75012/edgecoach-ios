/**
 * État global de l'application
 */

import SwiftUI
import Combine

/// État global partagé dans toute l'app
@MainActor
class AppState: ObservableObject {
    // Navigation state
    @Published var selectedTab: MainTab = .dashboard
    @Published var showingSessionDetail: Activity? = nil
    @Published var showingPlannedSession: PlannedSession? = nil

    // Coach chat sidebar state
    @Published var showingChatSidebar: Bool = false

    // Alert state
    @Published var alertMessage: String? = nil
    @Published var showAlert: Bool = false

    // Loading states
    @Published var isRefreshing: Bool = false

    // Network status
    @Published var isOnline: Bool = true

    func showError(_ message: String) {
        alertMessage = message
        showAlert = true
    }

    func dismissAlert() {
        alertMessage = nil
        showAlert = false
    }
}

/// Onglets principaux de l'app
enum MainTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case coach = "Coach"
    case calendar = "Calendrier"
    case stats = "Stats"
    case profile = "Profil"

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .coach: return "bubble.left.and.bubble.right.fill"
        case .calendar: return "calendar"
        case .stats: return "chart.bar.fill"
        case .profile: return "person.fill"
        }
    }

    var title: String {
        rawValue
    }
}
