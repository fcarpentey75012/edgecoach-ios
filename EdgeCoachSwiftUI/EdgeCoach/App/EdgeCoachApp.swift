/**
 * EdgeCoach - Application SwiftUI Native
 * Application d'entraînement sportif (triathlon/cyclisme)
 */

import SwiftUI

@main
struct EdgeCoachApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(appState)
        }
    }
}

/// Vue racine qui gère l'état d'authentification
struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isLoading {
                SplashView()
            } else if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                AuthNavigationView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
    }
}

/// Vue de chargement initial
struct SplashView: View {
    var body: some View {
        ZStack {
            Color.ecBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "figure.run")
                    .font(.system(size: 60))
                    .foregroundColor(.ecPrimary)

                Text("EdgeCoach")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.ecPrimary)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .ecPrimary))
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppState())
}
