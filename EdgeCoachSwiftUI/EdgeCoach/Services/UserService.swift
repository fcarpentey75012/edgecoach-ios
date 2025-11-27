/**
 * Service utilisateur
 * Gestion de l'authentification et du profil
 */

import Foundation

// MARK: - Auth Request/Response Models

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let experienceLevel: String

    enum CodingKeys: String, CodingKey {
        case email, password
        case firstName = "first_name"
        case lastName = "last_name"
        case experienceLevel = "experience_level"
    }
}

struct UserResponse: Decodable {
    let success: Bool?
    let user: User?
    let token: String?
    let message: String?
}

// MARK: - User Service

@MainActor
class UserService {
    static let shared = UserService()
    private let api = APIService.shared

    private init() {}

    // MARK: - Authentication

    func login(email: String, password: String) async throws -> (User, String?) {
        let request = LoginRequest(email: email, password: password)
        let response: UserResponse = try await api.post("/users/login", body: request)

        guard let user = response.user else {
            throw APIError.httpError(401, response.message ?? "Identifiants invalides")
        }

        // Save token if present
        if let token = response.token {
            api.setToken(token)
        }
        saveUser(user)

        return (user, response.token)
    }

    func register(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        experienceLevel: ExperienceLevel
    ) async throws -> (User, String) {
        let request = RegisterRequest(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            experienceLevel: experienceLevel.rawValue
        )

        let response: UserResponse = try await api.post("/users/register", body: request)

        guard let user = response.user, let token = response.token else {
            throw APIError.httpError(400, response.message ?? "Erreur lors de l'inscription")
        }

        // Save token
        api.setToken(token)
        saveUser(user)

        return (user, token)
    }

    func logout() {
        api.clearToken()
        clearUser()
    }

    // MARK: - Profile

    func getProfile() async throws -> User {
        let response: UserResponse = try await api.get("/users/profile")
        guard let user = response.user else {
            throw APIError.noData
        }
        return user
    }

    func getUserById(_ userId: String) async throws -> User {
        let response: UserResponse = try await api.get("/users/\(userId)")
        guard let user = response.user else {
            throw APIError.notFound
        }
        return user
    }

    func updateProfile(_ updates: [String: Any]) async throws -> User {
        // Convert to encodable
        struct ProfileUpdate: Encodable {
            let firstName: String?
            let lastName: String?
            let experienceLevel: String?

            enum CodingKeys: String, CodingKey {
                case firstName = "first_name"
                case lastName = "last_name"
                case experienceLevel = "experience_level"
            }
        }

        let update = ProfileUpdate(
            firstName: updates["first_name"] as? String,
            lastName: updates["last_name"] as? String,
            experienceLevel: updates["experience_level"] as? String
        )

        let response: UserResponse = try await api.put("/users/profile", body: update)
        guard let user = response.user else {
            throw APIError.noData
        }

        saveUser(user)
        return user
    }

    // MARK: - Local Storage

    func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "userData")
        }
    }

    func loadUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: "userData") else {
            return nil
        }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    func clearUser() {
        UserDefaults.standard.removeObject(forKey: "userData")
        UserDefaults.standard.removeObject(forKey: "authToken")
    }

    func hasStoredCredentials() -> Bool {
        return UserDefaults.standard.string(forKey: "authToken") != nil &&
               UserDefaults.standard.data(forKey: "userData") != nil
    }
}
