/**
 * EdgeCoach - Application SwiftUI Native
 * Application d'entraînement sportif (triathlon/cyclisme)
 */

import SwiftUI

@main
struct EdgeCoachApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var appState = AppState()
    
    // Utiliser ObservedObject pour les singletons déjà initialisés
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var layoutManager = LayoutManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(appState)
                .environmentObject(themeManager)
                .environmentObject(layoutManager)
                .withTheme(themeManager)
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
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "figure.run")
                    .font(.system(size: 60))
                    .foregroundColor(themeManager.accentColor)

                Text("EdgeCoach")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.accentColor)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager.accentColor))
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppState())
}
