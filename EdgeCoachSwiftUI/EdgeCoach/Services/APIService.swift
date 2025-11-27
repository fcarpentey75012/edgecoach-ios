/**
 * Service API principal
 * Gère les appels HTTP vers le backend Flask
 */

import Foundation

// MARK: - API Error

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case httpError(Int, String?)
    case decodingError(Error)
    case unauthorized
    case notFound
    case serverError
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .httpError(let code, let message):
            return "Erreur HTTP \(code): \(message ?? "Inconnue")"
        case .decodingError(let error):
            return "Erreur de décodage: \(error.localizedDescription)"
        case .unauthorized:
            return "Non autorisé. Veuillez vous reconnecter."
        case .notFound:
            return "Ressource non trouvée"
        case .serverError:
            return "Erreur serveur"
        case .noData:
            return "Aucune donnée reçue"
        }
    }
}

// MARK: - API Service

@MainActor
class APIService {
    static let shared = APIService()

    let baseURL = "http://127.0.0.1:5002/api"
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)

        // Utiliser un décodeur JSON personnalisé qui gère mieux les nombres flottants
        decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "Infinity",
            negativeInfinity: "-Infinity",
            nan: "NaN"
        )
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try multiple date formats
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",  // Microsecondes sans timezone
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSX", // Microsecondes avec timezone
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSS",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd"
            ]

            for format in formats {
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.locale = Locale(identifier: "en_US_POSIX")
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }

            // Try ISO8601
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Token Management

    var authToken: String? {
        get { UserDefaults.standard.string(forKey: "authToken") }
        set { UserDefaults.standard.set(newValue, forKey: "authToken") }
    }

    func setToken(_ token: String?) {
        authToken = token
    }

    func clearToken() {
        authToken = nil
    }

    // MARK: - Request Builder

    private func buildRequest(
        endpoint: String,
        method: String,
        body: Data? = nil,
        queryParams: [String: String]? = nil
    ) throws -> URLRequest {
        var urlString = "\(baseURL)\(endpoint)"

        // Add query parameters
        if let params = queryParams, !params.isEmpty {
            var components = URLComponents(string: urlString)
            components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            urlString = components?.string ?? urlString
        }

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        return request
    }

    // MARK: - Generic Request

    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        queryParams: [String: String]? = nil
    ) async throws -> T {
        var bodyData: Data? = nil
        if let body = body {
            bodyData = try encoder.encode(body)
        }

        let request = try buildRequest(
            endpoint: endpoint,
            method: method,
            body: bodyData,
            queryParams: queryParams
        )

        #if DEBUG
        print("🌐 API Request: \(method) \(endpoint)")
        #endif

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        #if DEBUG
        print("📥 API Response: \(httpResponse.statusCode)")
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 Data: \(jsonString.prefix(500))...")
        }
        #endif

        switch httpResponse.statusCode {
        case 200...299:
            do {
                // Utiliser un décodeur avec gestion des nombres flottants problématiques
                return try APIService.decodeJSON(T.self, from: data, decoder: decoder)
            } catch {
                #if DEBUG
                print("❌ Decoding error: \(error)")
                #endif
                throw APIError.decodingError(error)
            }
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError
        default:
            let message = String(data: data, encoding: .utf8)
            throw APIError.httpError(httpResponse.statusCode, message)
        }
    }

    // MARK: - Convenience Methods

    func get<T: Decodable>(
        _ endpoint: String,
        queryParams: [String: String]? = nil
    ) async throws -> T {
        try await request(endpoint: endpoint, method: "GET", queryParams: queryParams)
    }

    func post<T: Decodable, B: Encodable>(
        _ endpoint: String,
        body: B
    ) async throws -> T {
        try await request(endpoint: endpoint, method: "POST", body: body)
    }

    func put<T: Decodable, B: Encodable>(
        _ endpoint: String,
        body: B
    ) async throws -> T {
        try await request(endpoint: endpoint, method: "PUT", body: body)
    }

    func delete<T: Decodable>(
        _ endpoint: String
    ) async throws -> T {
        try await request(endpoint: endpoint, method: "DELETE")
    }

    // MARK: - Health Check

    func healthCheck() async -> Bool {
        do {
            let _: [String: String] = try await get("/health")
            return true
        } catch {
            return false
        }
    }

    // MARK: - Custom JSON Decoding

    /// Décode le JSON en gérant les problèmes de précision des nombres flottants
    private static func decodeJSON<T: Decodable>(_ type: T.Type, from data: Data, decoder: JSONDecoder) throws -> T {
        // Prétraiter les données pour arrondir les nombres à haute précision
        let processedData = preprocessJSONWithSerialization(data)
        return try decoder.decode(T.self, from: processedData)
    }

    /// Prétraite le JSON en utilisant JSONSerialization pour arrondir les floats problématiques
    private static func preprocessJSONWithSerialization(_ data: Data) -> Data {
        do {
            // Parser le JSON en objets Swift
            var jsonObject = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)

            // Traiter récursivement pour arrondir les nombres
            jsonObject = processJSONValue(jsonObject)

            // Re-sérialiser en Data
            return try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        } catch {
            #if DEBUG
            print("⚠️ JSON preprocessing failed, using original data: \(error)")
            #endif
            return data
        }
    }

    /// Traite récursivement les valeurs JSON pour arrondir les nombres à haute précision
    private static func processJSONValue(_ value: Any) -> Any {
        if let dict = value as? [String: Any] {
            var newDict = [String: Any]()
            for (key, val) in dict {
                newDict[key] = processJSONValue(val)
            }
            return newDict
        } else if let array = value as? [Any] {
            return array.map { processJSONValue($0) }
        } else if let number = value as? NSNumber {
            // Vérifier si c'est un Double (pas un Bool ou Int)
            let objCType = String(cString: number.objCType)
            if objCType == "d" || objCType == "f" {
                let doubleValue = number.doubleValue
                // Arrondir à 4 décimales pour éviter les problèmes de précision
                let rounded = (doubleValue * 10000).rounded() / 10000
                return NSNumber(value: rounded)
            }
            return number
        } else {
            return value
        }
    }
}
