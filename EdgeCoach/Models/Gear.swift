import Foundation

// MARK: - Modern Gear Model

/// Type d'équipement unifié
enum GearType: String, Codable, CaseIterable, Identifiable {
    case bike = "Vélo"
    case shoes = "Chaussures"
    case textile = "Vêtements"
    case wetsuit = "Combinaison"
    case goggles = "Lunettes"
    case accessory = "Accessoire"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .bike: return "figure.outdoor.cycle"
        case .shoes: return "shoeprint.fill"
        case .textile: return "tshirt.fill"
        case .wetsuit: return "figure.pool.swim"
        case .goggles: return "eyeglasses"
        case .accessory: return "gearshape.fill"
        }
    }
    
    // Mapping depuis l'ancien 'EquipmentCategory'
    static func from(category: EquipmentCategory) -> GearType {
        switch category {
        case .bikes: return .bike
        case .shoes: return .shoes
        case .clothes: return .textile
        case .suits: return .wetsuit
        case .goggles: return .goggles
        case .accessories: return .accessory
        }
    }
    
    // Mapping vers l'ancien 'EquipmentCategory' (pour l'API)
    func toCategory() -> EquipmentCategory {
        switch self {
        case .bike: return .bikes
        case .shoes: return .shoes
        case .textile: return .clothes
        case .wetsuit: return .suits
        case .goggles: return .goggles
        case .accessory: return .accessories
        }
    }
}

enum GearStatus: String, Codable {
    case active
    case retired
}

/// Modèle d'équipement "aplatit" et enrichi
struct Gear: Identifiable, Codable {
    let id: String
    let name: String
    let brand: String
    let model: String
    let type: GearType
    let primarySport: SportType // Le sport principal auquel il est rattaché dans l'API

    // Métadonnées
    let year: String?
    let notes: String?
    let status: GearStatus

    // Propriété calculée pour l'affichage
    var displayName: String {
        if !brand.isEmpty && !model.isEmpty {
            return "\(brand) \(model)"
        }
        return name
    }

    var fullDescription: String {
        [brand, model, year].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " • ")
    }

    /// Chemin local de l'image (stockée dans Documents)
    var localImagePath: String {
        "gear_images/\(id).jpg"
    }
}
