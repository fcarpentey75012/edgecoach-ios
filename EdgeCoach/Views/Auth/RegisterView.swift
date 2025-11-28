/**
 * Vue d'inscription
 * Utilise ThemeManager pour les couleurs dynamiques
 */

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showingRegister: Bool

    @State private var showPassword = false
    @FocusState private var focusedField: Field?

    enum Field: Int, CaseIterable {
        case firstName, lastName, email, password
    }

    var body: some View {
        ScrollView {
            VStack(spacing: ECSpacing.lg) {
                // Header
                VStack(spacing: ECSpacing.sm) {
                    Text("Créer un compte")
                        .font(.ecH2)
                        .foregroundColor(themeManager.textPrimary)

                    Text("Rejoignez EdgeCoach et commencez votre entraînement")
                        .font(.ecBody)
                        .foregroundColor(themeManager.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, ECSpacing.lg)

                // Form
                VStack(spacing: ECSpacing.md) {
                    // First Name
                    VStack(alignment: .leading, spacing: ECSpacing.xs) {
                        Text("Prénom")
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textSecondary)

                        TextField("Jean", text: $authViewModel.firstName)
                            .textFieldStyle(ECThemedTextFieldStyle(themeManager: themeManager))
                            .textContentType(.givenName)
                            .focused($focusedField, equals: .firstName)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .lastName }
                    }

                    // Last Name
                    VStack(alignment: .leading, spacing: ECSpacing.xs) {
                        Text("Nom")
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textSecondary)

                        TextField("Dupont", text: $authViewModel.lastName)
                            .textFieldStyle(ECThemedTextFieldStyle(themeManager: themeManager))
                            .textContentType(.familyName)
                            .focused($focusedField, equals: .lastName)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .email }
                    }

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
                    }

                    // Password
                    VStack(alignment: .leading, spacing: ECSpacing.xs) {
                        Text("Mot de passe")
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textSecondary)

                        HStack {
                            if showPassword {
                                TextField("Minimum 6 caractères", text: $authViewModel.password)
                            } else {
                                SecureField("Minimum 6 caractères", text: $authViewModel.password)
                            }

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(themeManager.textTertiary)
                            }
                        }
                        .textFieldStyle(ECThemedTextFieldStyle(themeManager: themeManager))
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.done)
                        .onSubmit { register() }
                    }

                    // Experience Level
                    VStack(alignment: .leading, spacing: ECSpacing.xs) {
                        Text("Niveau d'expérience")
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textSecondary)

                        Picker("Niveau", selection: $authViewModel.experienceLevel) {
                            ForEach(ExperienceLevel.allCases, id: \.self) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Error
                    if let error = authViewModel.error {
                        Text(error)
                            .font(.ecCaption)
                            .foregroundColor(themeManager.errorColor)
                            .padding(.horizontal)
                    }

                    // Register Button
                    Button {
                        register()
                    } label: {
                        HStack {
                            if authViewModel.isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text("S'inscrire")
                        }
                        .font(.ecBodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ECSpacing.md)
                        .background(
                            (!authViewModel.isValidRegister || authViewModel.isSubmitting)
                                ? themeManager.textTertiary
                                : themeManager.accentColor
                        )
                        .cornerRadius(ECRadius.lg)
                    }
                    .disabled(!authViewModel.isValidRegister || authViewModel.isSubmitting)
                    .padding(.top, ECSpacing.sm)
                }
                .padding(.horizontal, ECSpacing.lg)

                // Login Link
                HStack {
                    Text("Déjà un compte ?")
                        .font(.ecBody)
                        .foregroundColor(themeManager.textSecondary)

                    Button {
                        showingRegister = false
                    } label: {
                        Text("Se connecter")
                            .font(.ecBodyMedium)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
                .padding(.top, ECSpacing.md)
                .padding(.bottom, ECSpacing.xl)
            }
        }
        .background(themeManager.backgroundColor)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingRegister = false
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }

    private func register() {
        focusedField = nil
        Task {
            await authViewModel.register()
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView(showingRegister: .constant(true))
            .environmentObject(AuthViewModel())
            .environmentObject(ThemeManager.shared)
    }
}
