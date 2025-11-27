/**
 * Service Equipment pour EdgeCoach iOS
 * Gestion de l'équipement sportif (vélos, chaussures, etc.)
 */

import Foundation

// MARK: - Equipment Models

struct EquipmentItem: Codable, Identifiable {
    let id: String
    var name: String
    var brand: String
    var model: String
    var year: String
    var notes: String
    var isActive: Bool
    var specifications: [String: String]

    enum CodingKeys: String, CodingKey {
        case id, name, brand, model, year, notes, specifications
        case isActive = "is_active"
    }

    init(id: String, name: String, brand: String = "", model: String = "", year: String = "", notes: String = "", isActive: Bool = true, specifications: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.brand = brand
        self.model = model
        self.year = year
        self.notes = notes
        self.isActive = isActive
        self.specifications = specifications
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        brand = try container.decodeIfPresent(String.self, forKey: .brand) ?? ""
        model = try container.decodeIfPresent(String.self, forKey: .model) ?? ""

        // Year can be Int or String
        if let yearInt = try? container.decode(Int.self, forKey: .year) {
            year = String(yearInt)
        } else if let yearString = try? container.decode(String.self, forKey: .year) {
            year = yearString
        } else {
            year = ""
        }

        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        specifications = try container.decodeIfPresent([String: String].self, forKey: .specifications) ?? [:]
    }
}

struct SportEquipment: Codable {
    var bikes: [EquipmentItem]?
    var shoes: [EquipmentItem]?
    var clothes: [EquipmentItem]?
    var suits: [EquipmentItem]?
    var goggles: [EquipmentItem]?
    var accessories: [EquipmentItem]?

    init(bikes: [EquipmentItem]? = nil, shoes: [EquipmentItem]? = nil, clothes: [EquipmentItem]? = nil, suits: [EquipmentItem]? = nil, goggles: [EquipmentItem]? = nil, accessories: [EquipmentItem]? = nil) {
        self.bikes = bikes
        self.shoes = shoes
        self.clothes = clothes
        self.suits = suits
        self.goggles = goggles
        self.accessories = accessories
    }

    var allItems: [EquipmentItem] {
        var items: [EquipmentItem] = []
        if let bikes = bikes { items.append(contentsOf: bikes) }
        if let shoes = shoes { items.append(contentsOf: shoes) }
        if let clothes = clothes { items.append(contentsOf: clothes) }
        if let suits = suits { items.append(contentsOf: suits) }
        if let goggles = goggles { items.append(contentsOf: goggles) }
        if let accessories = accessories { items.append(contentsOf: accessories) }
        return items
    }

    var count: Int { allItems.count }

    static var empty: SportEquipment { SportEquipment() }
}

struct UserEquipment: Codable {
    var cycling: SportEquipment
    var running: SportEquipment
    var swimming: SportEquipment
    var totalActiveItems: Int
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case cycling, running, swimming
        case totalActiveItems = "total_active_items"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static var empty: UserEquipment {
        UserEquipment(
            cycling: SportEquipment(bikes: [], shoes: [], accessories: []),
            running: SportEquipment(shoes: [], clothes: [], accessories: []),
            swimming: SportEquipment(suits: [], goggles: [], accessories: []),
            totalActiveItems: 0
        )
    }
}

// MARK: - Equipment Category

enum EquipmentCategory: String, CaseIterable, Identifiable {
    case bikes, shoes, clothes, suits, goggles, accessories

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bikes: return "Vélos"
        case .shoes: return "Chaussures"
        case .clothes: return "Vêtements"
        case .suits: return "Combinaisons"
        case .goggles: return "Lunettes"
        case .accessories: return "Accessoires"
        }
    }

    var icon: String {
        switch self {
        case .bikes: return "bicycle"
        case .shoes: return "shoeprint.fill"
        case .clothes: return "tshirt.fill"
        case .suits: return "figure.pool.swim"
        case .goggles: return "eyeglasses"
        case .accessories: return "gearshape.fill"
        }
    }

    static func categoriesFor(sport: SportType) -> [EquipmentCategory] {
        switch sport {
        case .cycling: return [.bikes, .shoes, .accessories]
        case .running: return [.shoes, .clothes, .accessories]
        case .swimming: return [.suits, .goggles, .accessories]
        }
    }
}

// MARK: - Add Equipment Request

struct AddEquipmentRequest: Encodable {
    let sport: String
    let category: String
    let name: String
    var brand: String?
    var model: String?
    var year: Int?
    var notes: String?
    var specifications: [String: String]?
}

// MARK: - API Response

struct EquipmentAPIResponse: Decodable {
    let cycling: SportEquipment?
    let running: SportEquipment?
    let swimming: SportEquipment?
    let total_active_items: Int?
    let created_at: String?
    let updated_at: String?
}

struct AddEquipmentResponse: Decodable {
    let item: EquipmentItem
    let message: String
}

struct DeleteEquipmentResponse: Decodable {
    let message: String
}

// MARK: - Equipment Service

@MainActor
class EquipmentService {
    static let shared = EquipmentService()
    private let api = APIService.shared

    private init() {}

    // MARK: - Get Equipment

    func getEquipment(userId: String) async throws -> UserEquipment {
        let response: EquipmentAPIResponse = try await api.get("/users/\(userId)/equipment")
        return convertToUserEquipment(response)
    }

    func getEquipmentBySport(userId: String, sport: SportType) async throws -> SportEquipment {
        struct Response: Decodable {
            let equipment: SportEquipment
            let sport: String
        }
        let response: Response = try await api.get("/users/\(userId)/equipment/\(sport.rawValue)")
        return response.equipment
    }

    // MARK: - Add Equipment

    func addEquipment(userId: String, sport: SportType, category: EquipmentCategory, name: String, brand: String? = nil, model: String? = nil, year: String? = nil, notes: String? = nil) async throws -> EquipmentItem {
        let request = AddEquipmentRequest(
            sport: sport.rawValue,
            category: category.rawValue,
            name: name,
            brand: brand,
            model: model,
            year: year != nil ? Int(year!) : nil,
            notes: notes
        )

        let response: AddEquipmentResponse = try await api.post("/users/\(userId)/equipment", body: request)
        return response.item
    }

    // MARK: - Delete Equipment

    func deleteEquipment(userId: String, sport: SportType, category: EquipmentCategory, itemId: String) async throws {
        let _: DeleteEquipmentResponse = try await api.delete("/users/\(userId)/equipment/\(sport.rawValue)/\(category.rawValue)/\(itemId)")
    }

    // MARK: - Conversion

    private func convertToUserEquipment(_ response: EquipmentAPIResponse) -> UserEquipment {
        UserEquipment(
            cycling: response.cycling ?? SportEquipment(bikes: [], shoes: [], accessories: []),
            running: response.running ?? SportEquipment(shoes: [], clothes: [], accessories: []),
            swimming: response.swimming ?? SportEquipment(suits: [], goggles: [], accessories: []),
            totalActiveItems: response.total_active_items ?? 0,
            createdAt: response.created_at,
            updatedAt: response.updated_at
        )
    }

    // MARK: - Helpers

    func getItems(from equipment: UserEquipment, sport: SportType, category: EquipmentCategory) -> [EquipmentItem] {
        let sportEquipment: SportEquipment
        switch sport {
        case .cycling: sportEquipment = equipment.cycling
        case .running: sportEquipment = equipment.running
        case .swimming: sportEquipment = equipment.swimming
        }

        switch category {
        case .bikes: return sportEquipment.bikes ?? []
        case .shoes: return sportEquipment.shoes ?? []
        case .clothes: return sportEquipment.clothes ?? []
        case .suits: return sportEquipment.suits ?? []
        case .goggles: return sportEquipment.goggles ?? []
        case .accessories: return sportEquipment.accessories ?? []
        }
    }

    func getTotalCount(_ equipment: UserEquipment) -> Int {
        equipment.cycling.count + equipment.running.count + equipment.swimming.count
    }
}
