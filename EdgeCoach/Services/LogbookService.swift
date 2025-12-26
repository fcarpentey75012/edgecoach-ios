/**
 * Service Logbook pour EdgeCoach iOS
 * Gestion du carnet de bord d'entraînement (nutrition, hydratation, notes, météo, équipement)
 */

import Foundation

// MARK: - Nutrition Models

struct NutritionItem: Codable, Identifiable {
    let uniqueId: String
    let brand: String
    let name: String
    let type: String
    let calories: Int
    let carbs: Int
    let caffeine: Int
    var timingMinutes: Int?
    var quantity: Int

    var id: String { uniqueId }
}

struct NutritionTotals: Codable {
    var calories: Int
    var carbs: Int
    var caffeine: Int

    static var zero: NutritionTotals {
        NutritionTotals(calories: 0, carbs: 0, caffeine: 0)
    }
}

struct NutritionData: Codable {
    var items: [NutritionItem]
    var totals: NutritionTotals
    var timeline: [NutritionItem]?

    static var empty: NutritionData {
        NutritionData(items: [], totals: .zero, timeline: nil)
    }
}

// MARK: - Hydration Models

struct HydrationItem: Codable, Identifiable {
    let id: String
    let name: String
    let type: String
    var quantity: Int
    let volume: Int // in ml
}

struct HydrationData: Codable {
    var items: [HydrationItem]
    var totalVolume: Int

    static var empty: HydrationData {
        HydrationData(items: [], totalVolume: 0)
    }
}

// MARK: - Weather & Equipment

struct WeatherData: Codable {
    var temperature: String?
    var conditions: String?

    static var empty: WeatherData {
        WeatherData(temperature: nil, conditions: nil)
    }
}

struct SessionEquipmentData: Codable {
    var bikes: String?
    var shoes: String?
    var wetsuits: String?
}

// MARK: - Logbook Data

struct LogbookData: Codable {
    var nutrition: NutritionData
    var hydration: HydrationData
    var notes: String
    var weather: WeatherData
    var equipment: SessionEquipmentData?
    var effortRating: Int?
    var perceivedEffort: String?
    var intervalAnnotations: [IntervalAnnotation]?

    enum CodingKeys: String, CodingKey {
        case nutrition
        case hydration
        case notes
        case weather
        case equipment
        case effortRating = "effort_rating"
        case perceivedEffort = "perceived_effort"
        case intervalAnnotations = "interval_annotations"
    }

    static var empty: LogbookData {
        LogbookData(
            nutrition: .empty,
            hydration: .empty,
            notes: "",
            weather: .empty,
            equipment: nil,
            effortRating: nil,
            perceivedEffort: nil,
            intervalAnnotations: nil
        )
    }
}

// MARK: - API Response Models

struct LogbookDocument: Codable, Identifiable {
    let _id: String?
    let user_id: String
    let session_id: String
    let mongo_id: String
    let session_date: String?
    let session_name: String?
    let timestamp: String?
    let created_at: String?
    let logbook_data: LogbookDataWrapper?

    var id: String { _id ?? mongo_id }
}

struct LogbookDataWrapper: Codable {
    let sessionId: String?
    let mongoId: String?
    let logbook: LogbookData?
}

struct LogbookListResponse: Codable {
    let status: String
    let count: Int
    let data: [LogbookDocument]
}

struct SaveLogbookResponse: Codable {
    let status: String
    let message: String
    let formatted_text: String?
}

// MARK: - Save Request

struct SaveLogbookRequest: Encodable {
    let sessionId: String
    let mongoId: String
    let sessionDate: String?
    let sessionName: String?
    let timestamp: String
    let logbook: LogbookData
}

// MARK: - Logbook Service

@MainActor
class LogbookService {
    static let shared = LogbookService()
    private let api = APIService.shared

    private init() {}

    // MARK: - Get Logbook

    func getLogbookByMongoId(userId: String, mongoId: String) async throws -> LogbookData? {
        do {
            let response: LogbookListResponse = try await api.get("/logbook", queryParams: [
                "user_id": userId,
                "mongo_id": mongoId
            ])

            if let first = response.data.first, let data = first.logbook_data?.logbook {
                return data
            }
            return nil
        } catch let error as APIError {
            // 404 = no logbook found, not an error
            if case .notFound = error {
                return nil
            }
            if case .httpError(let code, _) = error, code == 404 {
                return nil
            }
            throw error
        }
    }

    func getLogbookBySessionId(userId: String, sessionId: String) async throws -> LogbookData? {
        do {
            let response: LogbookListResponse = try await api.get("/logbook", queryParams: [
                "user_id": userId,
                "session_id": sessionId
            ])

            if let first = response.data.first, let data = first.logbook_data?.logbook {
                return data
            }
            return nil
        } catch let error as APIError {
            if case .notFound = error {
                return nil
            }
            if case .httpError(let code, _) = error, code == 404 {
                return nil
            }
            throw error
        }
    }

    func getAllLogbooks(userId: String) async throws -> [LogbookDocument] {
        do {
            let response: LogbookListResponse = try await api.get("/logbook", queryParams: [
                "user_id": userId
            ])
            return response.data
        } catch let error as APIError {
            if case .notFound = error {
                return []
            }
            if case .httpError(let code, _) = error, code == 404 {
                return []
            }
            throw error
        }
    }

    // MARK: - Save Logbook

    func saveLogbook(userId: String, sessionId: String, mongoId: String, logbook: LogbookData, sessionDate: String? = nil, sessionName: String? = nil) async throws {
        let request = SaveLogbookRequest(
            sessionId: sessionId,
            mongoId: mongoId,
            sessionDate: sessionDate,
            sessionName: sessionName,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            logbook: logbook
        )

        let _: SaveLogbookResponse = try await api.post("/logbook?user_id=\(userId)", body: request)
    }

    // MARK: - Helpers

    func calculateNutritionTotals(_ items: [NutritionItem]) -> NutritionTotals {
        items.reduce(into: NutritionTotals.zero) { totals, item in
            totals.calories += item.calories * item.quantity
            totals.carbs += item.carbs * item.quantity
            totals.caffeine += item.caffeine * item.quantity
        }
    }

    func calculateHydrationTotal(_ items: [HydrationItem]) -> Int {
        items.reduce(0) { total, item in
            total + (item.volume * item.quantity)
        }
    }

    func formatTiming(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h\(String(format: "%02d", mins))"
    }
}
