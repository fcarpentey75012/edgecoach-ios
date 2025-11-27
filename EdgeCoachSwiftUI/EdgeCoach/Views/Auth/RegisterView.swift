/**
 * Vue d'inscription
 */

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
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
                        .foregroundColor(.ecSecondary800)

                    Text("Rejoignez EdgeCoach et commencez votre entraînement")
                        .font(.ecBody)
                        .foregroundColor(.ecGray500)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, ECSpacing.lg)

                // Form
                VStack(spacing: ECSpacing.md) {
                    // First Name
                    VStack(alignment: .leading, spacing: ECSpacing.xs) {
                        Text("Prénom")
                            .font(.ecLabel)
                            .foregroundColor(.ecSecondary700)

                        TextField("Jean", text: $authViewModel.firstName)
                            .textFieldStyle(ECTextFieldStyle())
                            .textContentType(.givenName)
                            .focused($focusedField, equals: .firstName)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .lastName }
                    }

                    // Last Name
                    VStack(alignment: .leading, spacing: ECSpacing.xs) {
                        Text("Nom")
                            .font(.ecLabel)
                            .foregroundColor(.ecSecondary700)

                        TextField("Dupont", text: $authViewModel.lastName)
                            .textFieldStyle(ECTextFieldStyle())
                            .textContentType(.familyName)
                            .focused($focusedField, equals: .lastName)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .email }
                    }

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
                                TextField("Minimum 6 caractères", text: $authViewModel.password)
                            } else {
                                SecureField("Minimum 6 caractères", text: $authViewModel.password)
                            }

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.ecGray400)
                            }
                        }
                        .textFieldStyle(ECTextFieldStyle())
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.done)
                        .onSubmit { register() }
                    }

                    // Experience Level
                    VStack(alignment: .leading, spacing: ECSpacing.xs) {
                        Text("Niveau d'expérience")
                            .font(.ecLabel)
                            .foregroundColor(.ecSecondary700)

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
                            .foregroundColor(.ecError)
                            .padding(.horizontal)
                    }

                    // Register Button
                    Button {
                        register()
                    } label: {
                        Text("S'inscrire")
                    }
                    .buttonStyle(.ecPrimary(
                        isLoading: authViewModel.isSubmitting,
                        isDisabled: !authViewModel.isValidRegister
                    ))
                    .disabled(!authViewModel.isValidRegister || authViewModel.isSubmitting)
                    .padding(.top, ECSpacing.sm)
                }
                .padding(.horizontal, ECSpacing.lg)

                // Login Link
                HStack {
                    Text("Déjà un compte ?")
                        .font(.ecBody)
                        .foregroundColor(.ecGray500)

                    Button {
                        showingRegister = false
                    } label: {
                        Text("Se connecter")
                            .font(.ecBodyMedium)
                            .foregroundColor(.ecPrimary)
                    }
                }
                .padding(.top, ECSpacing.md)
                .padding(.bottom, ECSpacing.xl)
            }
        }
        .background(Color.ecBackground)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingRegister = false
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.ecPrimary)
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
    }
}
