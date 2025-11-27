/**
 * Service Wahoo OAuth pour EdgeCoach iOS
 * Gestion de l'intégration Wahoo (connexion, synchronisation)
 * Aligné avec frontendios/src/services/wahooService.ts
 */

import Foundation
import UIKit

// MARK: - Wahoo Configuration

private enum WahooConfig {
    static let clientId = "aSnKputUgUtaCxtVlAImFyp-EyYQQoFUmBZnCyTC1lM"
    static let redirectUri = "edgecoach://auth/wahoo/callback"
    static let scopes = "email user_read workouts_read offline_data"
    static let authUrl = "https://api.wahooligan.com/oauth/authorize"
    static let tokenUrl = "https://api.wahooligan.com/oauth/token"
    static let apiUrl = "https://api.wahooligan.com/v1"
}

// MARK: - Wahoo Models

struct WahooTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

struct WahooProfile: Codable {
    let id: Int
    let email: String
    let name: String
    let firstName: String?
    let lastName: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email, name
        case firstName = "first_name"
        case lastName = "last_name"
        case createdAt = "created_at"
    }
}

struct WahooWorkout: Codable, Identifiable {
    let id: Int
    let name: String
    let sport: String
    let durationSeconds: Double
    let distanceMeters: Double?
    let calories: Double?
    let avgHeartRate: Double?
    let maxHeartRate: Double?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, sport
        case durationSeconds = "duration_seconds"
        case distanceMeters = "distance_meters"
        case calories
        case avgHeartRate = "avg_heart_rate"
        case maxHeartRate = "max_heart_rate"
        case createdAt = "created_at"
    }
}

struct WahooConnectionStatus {
    let isConnected: Bool
    let profile: WahooProfile?
    let lastSync: String?
    let error: String?
}

// MARK: - Storage Keys

private enum WahooStorageKeys {
    static let state = "wahoo_oauth_state"
    static let userId = "wahoo_oauth_user_id"
    static let tokens = "wahoo_tokens"
    static let profile = "wahoo_profile"
}

// MARK: - Wahoo Service

@MainActor
class WahooService {
    static let shared = WahooService()
    private let api = APIService.shared

    private init() {}

    // MARK: - Generate Auth URL

    func generateAuthUrl(userId: String) -> String {
        let stateToken = "wahoo_\(userId)_\(Int(Date().timeIntervalSince1970))"

        // Store state for verification
        UserDefaults.standard.set(stateToken, forKey: WahooStorageKeys.state)
        UserDefaults.standard.set(userId, forKey: WahooStorageKeys.userId)

        var components = URLComponents(string: WahooConfig.authUrl)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: WahooConfig.clientId),
            URLQueryItem(name: "redirect_uri", value: WahooConfig.redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: WahooConfig.scopes),
            URLQueryItem(name: "state", value: stateToken)
        ]

        return components.url!.absoluteString
    }

    // MARK: - Start OAuth

    func startOAuth(userId: String) async -> (success: Bool, authUrl: String?, instructions: [String]?, error: String?) {
        let authUrl = generateAuthUrl(userId: userId)

        guard let url = URL(string: authUrl) else {
            return (false, nil, nil, "URL d'authentification invalide")
        }

        // Open URL in browser
        if await UIApplication.shared.canOpenURL(url) {
            await UIApplication.shared.open(url)

            return (
                true,
                authUrl,
                [
                    "1. Connectez-vous avec vos identifiants Wahoo",
                    "2. Cliquez sur \"Autoriser\" pour EdgeCoach",
                    "3. Vous serez redirigé vers l'application"
                ],
                nil
            )
        } else {
            return (false, nil, nil, "Impossible d'ouvrir le navigateur pour l'authentification Wahoo")
        }
    }

    // MARK: - Check Callback URL

    func isWahooCallbackUrl(_ url: URL) -> Bool {
        return url.absoluteString.hasPrefix("edgecoach://auth/wahoo/callback")
    }

    // MARK: - Extract Auth Code

    func extractAuthCodeFromUrl(_ url: URL) -> (code: String?, state: String?, error: String?) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return (nil, nil, nil)
        }

        let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        let state = components.queryItems?.first(where: { $0.name == "state" })?.value
        let error = components.queryItems?.first(where: { $0.name == "error" })?.value

        return (code, state, error)
    }

    // MARK: - Handle Callback

    func handleCallback(callbackUrl: URL) async -> (success: Bool, tokens: WahooTokens?, profile: WahooProfile?, message: String?, error: String?) {
        let (code, state, errorParam) = extractAuthCodeFromUrl(callbackUrl)

        if let errorParam = errorParam {
            return (false, nil, nil, nil, "Erreur OAuth: \(errorParam)")
        }

        guard let code = code else {
            return (false, nil, nil, nil, "Code d'autorisation non trouvé dans l'URL")
        }

        // Verify state
        let storedState = UserDefaults.standard.string(forKey: WahooStorageKeys.state)
        if state != storedState {
            return (false, nil, nil, nil, "État OAuth invalide. Veuillez réessayer.")
        }

        // Get user ID
        guard let userId = UserDefaults.standard.string(forKey: WahooStorageKeys.userId) else {
            return (false, nil, nil, nil, "ID utilisateur non trouvé")
        }

        // Exchange code for tokens
        return await exchangeCodeForTokens(code: code, userId: userId)
    }

    // MARK: - Exchange Code for Tokens

    func exchangeCodeForTokens(code: String, userId: String) async -> (success: Bool, tokens: WahooTokens?, profile: WahooProfile?, message: String?, error: String?) {
        struct ExchangeRequest: Encodable {
            let code: String
            let userId: String
            let redirectUri: String

            enum CodingKeys: String, CodingKey {
                case code
                case userId = "user_id"
                case redirectUri = "redirect_uri"
            }
        }

        struct ExchangeResponse: Decodable {
            let accessToken: String
            let refreshToken: String
            let expiresIn: Int
            let tokenType: String
            let profile: WahooProfile?

            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case refreshToken = "refresh_token"
                case expiresIn = "expires_in"
                case tokenType = "token_type"
                case profile
            }
        }

        do {
            let request = ExchangeRequest(
                code: code,
                userId: userId,
                redirectUri: WahooConfig.redirectUri
            )

            let response: ExchangeResponse = try await api.post("/auth/wahoo/exchange", body: request)

            let tokens = WahooTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                expiresIn: response.expiresIn,
                tokenType: response.tokenType
            )

            // Store tokens
            if let data = try? JSONEncoder().encode(tokens) {
                UserDefaults.standard.set(data, forKey: WahooStorageKeys.tokens)
            }

            // Store profile if available
            if let profile = response.profile, let data = try? JSONEncoder().encode(profile) {
                UserDefaults.standard.set(data, forKey: WahooStorageKeys.profile)
            }

            // Clean up temporary data
            UserDefaults.standard.removeObject(forKey: WahooStorageKeys.state)
            UserDefaults.standard.removeObject(forKey: WahooStorageKeys.userId)

            return (true, tokens, response.profile, "Connexion Wahoo établie avec succès!", nil)
        } catch {
            return (false, nil, nil, nil, error.localizedDescription)
        }
    }

    // MARK: - Get Connection Status

    func getConnectionStatus(userId: String) async -> WahooConnectionStatus {
        struct StatusResponse: Decodable {
            let connected: Bool
            let profile: WahooProfile?
            let lastSync: String?

            enum CodingKeys: String, CodingKey {
                case connected
                case profile
                case lastSync = "last_sync"
            }
        }

        do {
            let response: StatusResponse = try await api.get(
                "/auth/wahoo/status",
                queryParams: ["user_id": userId]
            )

            return WahooConnectionStatus(
                isConnected: response.connected,
                profile: response.profile,
                lastSync: response.lastSync,
                error: nil
            )
        } catch {
            // Try to read from local storage
            if let data = UserDefaults.standard.data(forKey: WahooStorageKeys.tokens),
               let _ = try? JSONDecoder().decode(WahooTokens.self, from: data) {

                var profile: WahooProfile? = nil
                if let profileData = UserDefaults.standard.data(forKey: WahooStorageKeys.profile) {
                    profile = try? JSONDecoder().decode(WahooProfile.self, from: profileData)
                }

                return WahooConnectionStatus(
                    isConnected: true,
                    profile: profile,
                    lastSync: nil,
                    error: nil
                )
            }

            return WahooConnectionStatus(
                isConnected: false,
                profile: nil,
                lastSync: nil,
                error: error.localizedDescription
            )
        }
    }

    // MARK: - Disconnect

    func disconnect(userId: String) async -> (success: Bool, error: String?) {
        struct DisconnectResponse: Decodable {
            let message: String
        }

        struct DisconnectRequest: Encodable {
            let userId: String

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
            }
        }

        do {
            let _: DisconnectResponse = try await api.post(
                "/auth/wahoo/disconnect",
                body: DisconnectRequest(userId: userId)
            )

            // Clean up local storage
            UserDefaults.standard.removeObject(forKey: WahooStorageKeys.tokens)
            UserDefaults.standard.removeObject(forKey: WahooStorageKeys.profile)
            UserDefaults.standard.removeObject(forKey: WahooStorageKeys.state)
            UserDefaults.standard.removeObject(forKey: WahooStorageKeys.userId)

            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    // MARK: - Sync Workouts

    func syncWorkouts(userId: String) async -> (success: Bool, workouts: [WahooWorkout]?, error: String?) {
        struct SyncRequest: Encodable {
            let userId: String

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
            }
        }

        struct SyncResponse: Decodable {
            let workouts: [WahooWorkout]
            let count: Int
        }

        do {
            let response: SyncResponse = try await api.post(
                "/auth/wahoo/sync",
                body: SyncRequest(userId: userId)
            )

            return (true, response.workouts, nil)
        } catch {
            return (false, nil, error.localizedDescription)
        }
    }

    // MARK: - Get Recent Workouts

    func getRecentWorkouts(userId: String, limit: Int = 10) async -> (success: Bool, workouts: [WahooWorkout]?, error: String?) {
        struct WorkoutsResponse: Decodable {
            let workouts: [WahooWorkout]
        }

        do {
            let response: WorkoutsResponse = try await api.get(
                "/auth/wahoo/workouts",
                queryParams: [
                    "user_id": userId,
                    "limit": String(limit)
                ]
            )

            return (true, response.workouts, nil)
        } catch {
            return (false, nil, error.localizedDescription)
        }
    }
}
