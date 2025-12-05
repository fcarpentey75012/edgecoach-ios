/**
 * ViewModel pour l'authentification
 */

import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var user: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true
    @Published var error: String?

    // Form states - valeurs par défaut pour faciliter les tests en DEBUG
    #if DEBUG
    @Published var email: String = "florian.carpentey49@me.com"
    @Published var password: String = "Florian1991-"
    #else
    @Published var email: String = ""
    @Published var password: String = ""
    #endif
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var experienceLevel: ExperienceLevel = .intermediaire
    @Published var isSubmitting: Bool = false

    // MARK: - Services

    private let userService = UserService.shared

    // MARK: - Init

    init() {
        checkStoredAuth()
    }

    // MARK: - Check Stored Auth

    private func checkStoredAuth() {
        isLoading = true

        if userService.hasStoredCredentials(),
           let storedUser = userService.loadUser() {
            self.user = storedUser
            self.isAuthenticated = true

            // Optionally refresh user data from server
            /*Task {
                await refreshUserProfile()
            }*/
        }

        isLoading = false
    }

    // MARK: - Login

    func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Veuillez remplir tous les champs"
            return
        }

        isSubmitting = true
        error = nil

        do {
            let (user, _) = try await userService.login(email: email, password: password)
            self.user = user
            self.isAuthenticated = true
            clearForm()
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch {
            self.error = "Erreur de connexion: \(error.localizedDescription)"
        }

        isSubmitting = false
    }

    // MARK: - Register

    func register() async {
        guard !email.isEmpty, !password.isEmpty, !firstName.isEmpty, !lastName.isEmpty else {
            error = "Veuillez remplir tous les champs"
            return
        }

        guard password.count >= 6 else {
            error = "Le mot de passe doit contenir au moins 6 caractères"
            return
        }

        isSubmitting = true
        error = nil

        do {
            let (user, _) = try await userService.register(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName,
                experienceLevel: experienceLevel
            )
            self.user = user
            self.isAuthenticated = true
            clearForm()
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch {
            self.error = "Erreur d'inscription: \(error.localizedDescription)"
        }

        isSubmitting = false
    }

    // MARK: - Logout

    func logout() {
        userService.logout()
        user = nil
        isAuthenticated = false
        clearForm()
    }

    // MARK: - Update Profile

    func updateProfile(firstName: String?, lastName: String?, experienceLevel: ExperienceLevel?) async {
        var updates: [String: Any] = [:]

        if let firstName = firstName {
            updates["first_name"] = firstName
        }
        if let lastName = lastName {
            updates["last_name"] = lastName
        }
        if let level = experienceLevel {
            updates["experience_level"] = level.rawValue
        }

        do {
            let updatedUser = try await userService.updateProfile(updates)
            self.user = updatedUser
        } catch {
            self.error = "Erreur de mise à jour: \(error.localizedDescription)"
        }
    }

    // MARK: - Refresh Profile

    func refreshUserProfile() async {
        do {
            let freshUser = try await userService.getProfile()
            self.user = freshUser
            userService.saveUser(freshUser)
        } catch {
            // Silent fail - user data is still valid from cache
            #if DEBUG
            print("Failed to refresh user profile: \(error)")
            #endif
        }
    }

    // MARK: - Helpers

    private func clearForm() {
        email = ""
        password = ""
        firstName = ""
        lastName = ""
        error = nil
    }

    var isValidLogin: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var isValidRegister: Bool {
        !email.isEmpty && password.count >= 6 && !firstName.isEmpty && !lastName.isEmpty
    }
}
