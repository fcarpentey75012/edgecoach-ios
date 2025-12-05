/**
 * Système de couleurs EdgeCoach
 * Palette de couleurs pour l'application avec support du mode Fitness
 */

import SwiftUI

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Static Colors (Legacy Support)

extension Color {
    // MARK: - Primary Colors
    static let ecPrimary = Color(hex: "#3B82F6")         // Blue 500
    static let ecPrimary50 = Color(hex: "#EFF6FF")
    static let ecPrimary100 = Color(hex: "#DBEAFE")
    static let ecPrimary200 = Color(hex: "#BFDBFE")
    static let ecPrimary500 = Color(hex: "#3B82F6")
    static let ecPrimary600 = Color(hex: "#2563EB")
    static let ecPrimary700 = Color(hex: "#1D4ED8")

    // MARK: - Secondary Colors (Slate)
    static let ecSecondary = Color(hex: "#475569")       // Slate 600
    static let ecSecondary50 = Color(hex: "#F8FAFC")
    static let ecSecondary100 = Color(hex: "#F1F5F9")
    static let ecSecondary200 = Color(hex: "#E2E8F0")
    static let ecSecondary500 = Color(hex: "#64748B")    // Slate 500
    static let ecSecondary700 = Color(hex: "#334155")
    static let ecSecondary800 = Color(hex: "#1E293B")
    static let ecSecondary900 = Color(hex: "#0F172A")

    // MARK: - Background & Surface
    static let ecBackground = Color(hex: "#F8FAFC")      // Slate 50
    static let ecSurface = Color.white
    static let ecCard = Color.white

    // MARK: - Sports Colors
    static let ecSwimming = Color(hex: "#0891B2")        // Bleu ardoise (moins flashy)
    static let ecCycling = Color(hex: "#D97706")         // Ambre doux (moins flashy)
    static let ecRunning = Color(hex: "#059669")         // Vert sauge (moins flashy)
    static let ecTriathlon = Color(hex: "#8B5CF6")       // Violet 500
    static let ecOther = Color(hex: "#6B7280")           // Gray 500

    // Sport colors aliases (French naming)
    static let ecSportCyclisme = ecCycling
    static let ecSportCourse = ecRunning
    static let ecSportNatation = ecSwimming
    static let ecSportAutre = ecOther

    // MARK: - Status Colors
    static let ecSuccess = Color(hex: "#22C55E")         // Green 500
    static let ecWarning = Color(hex: "#F59E0B")         // Amber 500
    static let ecError = Color(hex: "#EF4444")           // Red 500
    static let ecInfo = Color(hex: "#3B82F6")            // Blue 500

    // MARK: - Neutral/Gray
    static let ecGray50 = Color(hex: "#F9FAFB")
    static let ecGray100 = Color(hex: "#F3F4F6")
    static let ecGray200 = Color(hex: "#E5E7EB")
    static let ecGray300 = Color(hex: "#D1D5DB")
    static let ecGray400 = Color(hex: "#9CA3AF")
    static let ecGray500 = Color(hex: "#6B7280")
    static let ecGray600 = Color(hex: "#4B5563")
    static let ecGray700 = Color(hex: "#374151")
    static let ecGray800 = Color(hex: "#1F2937")
    static let ecGray900 = Color(hex: "#111827")

    // MARK: - Zone Colors (Heart Rate / Power)
    static let ecZone1 = Color(hex: "#94A3B8")           // Gray - Recovery
    static let ecZone2 = Color(hex: "#22C55E")           // Green - Endurance
    static let ecZone3 = Color(hex: "#84CC16")           // Lime - Tempo
    static let ecZone4 = Color(hex: "#EAB308")           // Yellow - Threshold
    static let ecZone5 = Color(hex: "#F97316")           // Orange - VO2max
    static let ecZone6 = Color(hex: "#EF4444")           // Red - Anaerobic
    static let ecZone7 = Color(hex: "#DC2626")           // Dark Red - Neuromuscular

    // MARK: - Fitness Mode Colors (Neon/OLED)
    static let ecFitnessBackground = Color(hex: "#000000")
    static let ecFitnessSurface = Color(hex: "#1C1C1E")
    static let ecFitnessCard = Color(hex: "#2C2C2E")
    static let ecFitnessElevated = Color(hex: "#3A3A3C")
    static let ecFitnessTextPrimary = Color.white
    static let ecFitnessTextSecondary = Color(hex: "#A1A1AA")
    static let ecFitnessTextTertiary = Color(hex: "#71717A")
    static let ecFitnessSeparator = Color(hex: "#3A3A3C")
    static let ecFitnessBorder = Color(hex: "#48484A")

    // Neon Sport Colors (for Fitness mode)
    static let ecNeonCycling = Color(hex: "#FBBF24")
    static let ecNeonRunning = Color(hex: "#4ADE80")
    static let ecNeonSwimming = Color(hex: "#22D3EE")
    static let ecNeonOther = Color(hex: "#A1A1AA")

    // MARK: - Helper Functions
    
    static func zoneColor(for zone: Int) -> Color {
        switch zone {
        case 1: return .ecZone1
        case 2: return .ecZone2
        case 3: return .ecZone3
        case 4: return .ecZone4
        case 5: return .ecZone5
        case 6: return .ecZone6
        case 7: return .ecZone7
        default: return .ecGray400
        }
    }

    static func sportColor(for discipline: Discipline) -> Color {
        switch discipline {
        case .cyclisme: return .ecCycling
        case .course: return .ecRunning
        case .natation: return .ecSwimming
        case .autre: return .ecOther
        }
    }
    
    static func neonSportColor(for discipline: Discipline) -> Color {
        switch discipline {
        case .cyclisme: return .ecNeonCycling
        case .course: return .ecNeonRunning
        case .natation: return .ecNeonSwimming
        case .autre: return .ecNeonOther
        }
    }
}
