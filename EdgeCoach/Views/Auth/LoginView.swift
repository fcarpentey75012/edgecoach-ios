/**
 * Vue de connexion
 * Utilise ThemeManager pour les couleurs dynamiques
 */

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showingRegister: Bool

    @State private var showPassword = false
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        ScrollView {
            VStack(spacing: ECSpacing.xl) {
                // Logo & Title
                VStack(spacing: ECSpacing.md) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 60))
                        .foregroundColor(themeManager.accentColor)

                    Text("EdgeCoach")
                        .font(.ecH1)
                        .foregroundColor(themeManager.textPrimary)

                    Text("Connectez-vous pour continuer")
                        .font(.ecBody)
                        .foregroundColor(themeManager.textSecondary)
                }
                .padding(.top, ECSpacing.xxl)

                // Form
                VStack(spacing: ECSpacing.md) {
                    // Email
                    VStack(alignment: .leading, spacing: ECSpacing.xs) {
                        Text("Email")
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textSecondary)

                        TextField("votre@email.com", text: $authViewModel.email)
                            .textFieldStyle(ECThemedTextFieldStyle(themeManager: themeManager))
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                            .accessibilityIdentifier("loginEmailField")
                    }

                    // Password
                    VStack(alignment: .leading, spacing: ECSpacing.xs) {
                        Text("Mot de passe")
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textSecondary)

                        HStack {
                            if showPassword {
                                TextField("••••••••", text: $authViewModel.password)
                                    .accessibilityIdentifier("loginPasswordField")
                            } else {
                                SecureField("••••••••", text: $authViewModel.password)
                                    .accessibilityIdentifier("loginPasswordField")
                            }

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(themeManager.textTertiary)
                            }
                        }
                        .textFieldStyle(ECThemedTextFieldStyle(themeManager: themeManager))
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { login() }
                    }

                    // Error
                    if let error = authViewModel.error {
                        Text(error)
                            .font(.ecCaption)
                            .foregroundColor(themeManager.errorColor)
                            .padding(.horizontal)
                    }

                    // Login Button
                    Button {
                        login()
                    } label: {
                        HStack {
                            if authViewModel.isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text("Se connecter")
                        }
                        .font(.ecBodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ECSpacing.md)
                        .background(
                            (!authViewModel.isValidLogin || authViewModel.isSubmitting) 
                                ? themeManager.textTertiary 
                                : themeManager.accentColor
                        )
                        .cornerRadius(ECRadius.lg)
                    }
                    .disabled(!authViewModel.isValidLogin || authViewModel.isSubmitting)
                    .padding(.top, ECSpacing.sm)
                    .accessibilityIdentifier("loginButton")
                }
                .padding(.horizontal, ECSpacing.lg)

                // Register Link
                HStack {
                    Text("Pas encore de compte ?")
                        .font(.ecBody)
                        .foregroundColor(themeManager.textSecondary)

                    Button {
                        showingRegister = true
                    } label: {
                        Text("S'inscrire")
                            .font(.ecBodyMedium)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
                .padding(.top, ECSpacing.md)

                Spacer()
            }
        }
        .background(themeManager.backgroundColor)
        .navigationBarHidden(true)
    }

    private func login() {
        focusedField = nil
        Task {
            await authViewModel.login()
        }
    }
}

// MARK: - Themed Text Field Style

@MainActor
struct ECThemedTextFieldStyle: TextFieldStyle {
    let themeManager: ThemeManager

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(themeManager.surfaceColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
    }
}

#Preview {
    LoginView(showingRegister: .constant(false))
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager.shared)
}
