/**
 * Service Equipment pour EdgeCoach iOS
 * Gestion de l'équipement sportif (vélos, chaussures, etc.)
 * Agit comme une façade : Convertit l'API Legacy (UserEquipment imbriqué) en Modèle Moderne (Gear plat)
 */

import Foundation

// MARK: - Equipment Models (Legacy API Structures)
// Ces structures ne servent plus qu'au parsing JSON interne

struct EquipmentItem: Codable, Identifiable {
    let id: String
    var name: String
    var brand: String?
    var model: String?
    var year: YearValue?
    var notes: String?
    var isActive: Bool
    var specifications: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id, name, brand, model, year, notes, specifications
        case isActive = "is_active"
    }

    // Conversion vers le nouveau modèle Gear
    func toGear(type: GearType, sport: SportType) -> Gear {
        return Gear(
            id: id,
            name: name,
            brand: brand ?? "",
            model: model ?? "",
            type: type,
            primarySport: sport,
            year: year?.stringValue,
            notes: notes,
            status: isActive ? .active : .retired
        )
    }
}

// MARK: - Year Value (gère Int ou String depuis l'API)

/// Wrapper pour gérer le champ 'year' qui peut être Int ou String dans l'API
enum YearValue: Codable {
    case int(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(
                YearValue.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Int or String for year")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }

    var stringValue: String {
        switch self {
        case .int(let value): return String(value)
        case .string(let value): return value
        }
    }
}

struct SportEquipment: Codable {
    var bikes: [EquipmentItem]?
    var shoes: [EquipmentItem]?
    var clothes: [EquipmentItem]?
    var suits: [EquipmentItem]?
    var goggles: [EquipmentItem]?
    var accessories: [EquipmentItem]?

    /// Retourne tous les équipements combinés
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
}

struct UserEquipment: Codable {
    var cycling: SportEquipment
    var running: SportEquipment
    var swimming: SportEquipment
    var totalActiveItems: Int
    
    enum CodingKeys: String, CodingKey {
        case cycling, running, swimming
        case totalActiveItems = "total_active_items"
    }
    
    static var empty: UserEquipment {
        UserEquipment(
            cycling: SportEquipment(),
            running: SportEquipment(),
            swimming: SportEquipment(),
            totalActiveItems: 0
        )
    }
}

// MARK: - Equipment Category (Legacy Mapping)

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

// MARK: - API Requests & Responses

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

    // MARK: - Public API (Modern Gear)

    /// Récupère tout l'équipement sous forme de liste plate de 'Gear'
    func getAllGear(userId: String) async throws -> [Gear] {
        let response: EquipmentAPIResponse = try await api.get("/users/\(userId)/equipment")
        let userEquipment = convertToUserEquipment(response)
        return flattenEquipment(userEquipment)
    }
    
    /// Récupère l'équipement filtré pour un sport spécifique
    func getGear(userId: String, for sport: SportType) async throws -> [Gear] {
        let allGear = try await getAllGear(userId: userId)
        return allGear.filter { $0.primarySport == sport }
    }

    // MARK: - Mutations

    func addGear(userId: String, gear: Gear) async throws -> Gear {
        // Conversion inverse : Gear -> API Request
        let category = gear.type.toCategory()
        
        let request = AddEquipmentRequest(
            sport: gear.primarySport.rawValue,
            category: category.rawValue,
            name: gear.name,
            brand: gear.brand.isEmpty ? nil : gear.brand,
            model: gear.model.isEmpty ? nil : gear.model,
            year: Int(gear.year ?? ""),
            notes: gear.notes
        )

        let response: AddEquipmentResponse = try await api.post("/users/\(userId)/equipment", body: request)
        
        // Retourne l'objet créé converti en Gear
        return response.item.toGear(type: gear.type, sport: gear.primarySport)
    }

    func deleteGear(userId: String, gear: Gear) async throws {
        let category = gear.type.toCategory()
        let _: DeleteEquipmentResponse = try await api.delete(
            "/users/\(userId)/equipment/\(gear.primarySport.rawValue)/\(category.rawValue)/\(gear.id)"
        )
    }
    
    // MARK: - Helpers (Internal Logic)
    
    /// Transforme la structure imbriquée en liste plate
    private func flattenEquipment(_ equipment: UserEquipment) -> [Gear] {
        var allGear: [Gear] = []
        
        // Cycling
        if let items = equipment.cycling.bikes { allGear.append(contentsOf: items.map { $0.toGear(type: .bike, sport: .cycling) }) }
        if let items = equipment.cycling.shoes { allGear.append(contentsOf: items.map { $0.toGear(type: .shoes, sport: .cycling) }) }
        if let items = equipment.cycling.accessories { allGear.append(contentsOf: items.map { $0.toGear(type: .accessory, sport: .cycling) }) }
        
        // Running
        if let items = equipment.running.shoes { allGear.append(contentsOf: items.map { $0.toGear(type: .shoes, sport: .running) }) }
        if let items = equipment.running.clothes { allGear.append(contentsOf: items.map { $0.toGear(type: .textile, sport: .running) }) }
        if let items = equipment.running.accessories { allGear.append(contentsOf: items.map { $0.toGear(type: .accessory, sport: .running) }) }
        
        // Swimming
        if let items = equipment.swimming.suits { allGear.append(contentsOf: items.map { $0.toGear(type: .wetsuit, sport: .swimming) }) }
        if let items = equipment.swimming.goggles { allGear.append(contentsOf: items.map { $0.toGear(type: .goggles, sport: .swimming) }) }
        if let items = equipment.swimming.accessories { allGear.append(contentsOf: items.map { $0.toGear(type: .accessory, sport: .swimming) }) }
        
        return allGear
    }

    private func convertToUserEquipment(_ response: EquipmentAPIResponse) -> UserEquipment {
        UserEquipment(
            cycling: response.cycling ?? SportEquipment(),
            running: response.running ?? SportEquipment(),
            swimming: response.swimming ?? SportEquipment(),
            totalActiveItems: response.total_active_items ?? 0
        )
    }
    
    // Helper pour l'UI (Totaux)
    func getCount(from gearList: [Gear]) -> Int {
        gearList.filter { $0.status == .active }.count
    }

    // MARK: - Legacy API (pour compatibilité avec SessionDetailView)

    /// Récupère l'équipement sous forme de UserEquipment (structure imbriquée)
    func getEquipment(userId: String) async throws -> UserEquipment {
        let response: EquipmentAPIResponse = try await api.get("/users/\(userId)/equipment")
        return convertToUserEquipment(response)
    }

    /// Récupère les items d'une catégorie spécifique
    func getItems(from equipment: UserEquipment, sport: SportType, category: EquipmentCategory) -> [EquipmentItem] {
        let sportEquipment: SportEquipment
        switch sport {
        case .cycling: sportEquipment = equipment.cycling
        case .running: sportEquipment = equipment.running
        case .swimming: sportEquipment = equipment.swimming
        default: return []
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
}
