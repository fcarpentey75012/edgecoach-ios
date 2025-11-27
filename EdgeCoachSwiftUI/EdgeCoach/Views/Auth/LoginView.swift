/**
 * Vue de connexion
 */

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
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
                        .foregroundColor(.ecPrimary)

                    Text("EdgeCoach")
                        .font(.ecH1)
                        .foregroundColor(.ecSecondary800)

                    Text("Connectez-vous pour continuer")
                        .font(.ecBody)
                        .foregroundColor(.ecGray500)
                }
                .padding(.top, ECSpacing.xxl)

                // Form
                VStack(spacing: ECSpacing.md) {
                    // Email
                    VStack(alignment: .leading, spacing: ECSpacing.xs) {
                        Text("Email")
                            .font(.ecLabel)
                            .foregroundColor(.ecSecondary700)

                        TextField("votre@email.com", text: $authViewModel.email)
                            .textFieldStyle(ECTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                    }

                    // Password
                    VStack(alignment: .leading, spacing: ECSpacing.xs) {
                        Text("Mot de passe")
                            .font(.ecLabel)
                            .foregroundColor(.ecSecondary700)

                        HStack {
                            if showPassword {
                                TextField("••••••••", text: $authViewModel.password)
                            } else {
                                SecureField("••••••••", text: $authViewModel.password)
                            }

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.ecGray400)
                            }
                        }
                        .textFieldStyle(ECTextFieldStyle())
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { login() }
                    }

                    // Error
                    if let error = authViewModel.error {
                        Text(error)
                            .font(.ecCaption)
                            .foregroundColor(.ecError)
                            .padding(.horizontal)
                    }

                    // Login Button
                    Button {
                        login()
                    } label: {
                        Text("Se connecter")
                    }
                    .buttonStyle(.ecPrimary(
                        isLoading: authViewModel.isSubmitting,
                        isDisabled: !authViewModel.isValidLogin
                    ))
                    .disabled(!authViewModel.isValidLogin || authViewModel.isSubmitting)
                    .padding(.top, ECSpacing.sm)
                }
                .padding(.horizontal, ECSpacing.lg)

                // Register Link
                HStack {
                    Text("Pas encore de compte ?")
                        .font(.ecBody)
                        .foregroundColor(.ecGray500)

                    Button {
                        showingRegister = true
                    } label: {
                        Text("S'inscrire")
                            .font(.ecBodyMedium)
                            .foregroundColor(.ecPrimary)
                    }
                }
                .padding(.top, ECSpacing.md)

                Spacer()
            }
        }
        .background(Color.ecBackground)
        .navigationBarHidden(true)
    }

    private func login() {
        focusedField = nil
        Task {
            await authViewModel.login()
        }
    }
}

// MARK: - Text Field Style

struct ECTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.ecSurface)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(Color.ecGray200, lineWidth: 1)
            )
    }
}

#Preview {
    LoginView(showingRegister: .constant(false))
        .environmentObject(AuthViewModel())
}
