/**
 * Navigation pour l'authentification
 * Utilise ThemeManager pour les couleurs dynamiques
 */

import SwiftUI

struct AuthNavigationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingRegister = false

    var body: some View {
        NavigationStack {
            LoginView(showingRegister: $showingRegister)
                .navigationDestination(isPresented: $showingRegister) {
                    RegisterView(showingRegister: $showingRegister)
                }
        }
    }
}

#Preview {
    AuthNavigationView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager.shared)
}
