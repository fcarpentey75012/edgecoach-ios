/**
 * Navigation pour l'authentification
 */

import SwiftUI

struct AuthNavigationView: View {
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
}
