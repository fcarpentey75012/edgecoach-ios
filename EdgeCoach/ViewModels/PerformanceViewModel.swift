/**
 * ViewModel pour la vue Performance
 * Charge les données du Performance Report (métriques temps réel)
 */

import SwiftUI
import Combine

@MainActor
class PerformanceViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var performanceReport: PerformanceReport?
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Services

    private let api = APIService.shared
    private var currentUserId: String?

    // MARK: - Load Data

    func loadData(userId: String) async {
        currentUserId = userId
        isLoading = true
        error = nil

        #if DEBUG
        print("📊 [PerformanceViewModel] Loading performance report for userId=\(userId)")
        #endif

        do {
            let report: PerformanceReport = try await api.get("/users/\(userId)/performance-report")
            performanceReport = report

            #if DEBUG
            print("📊 [PerformanceViewModel] Loaded report dated \(report.date)")
            if let vma = report.metrics.vma {
                print("  - VMA: \(vma.value) km/h (confidence: \(vma.confidencePercent)%)")
            }
            if let ftp = report.metrics.ftp {
                print("  - FTP: \(ftp.value) W (confidence: \(ftp.confidencePercent)%)")
            }
            if let css = report.metrics.css {
                print("  - CSS: \(css.formattedValue) (confidence: \(css.confidencePercent)%)")
            }
            #endif

        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ [PerformanceViewModel] Error: \(error)")
            #endif
        }

        isLoading = false
    }

    // MARK: - Refresh

    func refresh(userId: String) async {
        await loadData(userId: userId)
    }

    // MARK: - Computed Properties

    /// VMA disponible ?
    var hasVMA: Bool {
        performanceReport?.metrics.vma != nil
    }

    /// FTP disponible ?
    var hasFTP: Bool {
        performanceReport?.metrics.ftp != nil
    }

    /// CSS disponible ?
    var hasCSS: Bool {
        performanceReport?.metrics.css != nil
    }

    /// Records disponibles ?
    var hasBestDistances: Bool {
        guard let records = performanceReport?.metrics.bestDistances else { return false }
        return !records.isEmpty
    }

    /// CP/W' disponible ?
    var hasCPWprime: Bool {
        performanceReport?.metrics.cpWprime != nil
    }

    /// FTP Hybrid disponible ?
    var hasFTPHybrid: Bool {
        performanceReport?.metrics.ftpHybrid != nil
    }

    /// CS/D' disponible ?
    var hasCSDprime: Bool {
        performanceReport?.metrics.csDprime != nil
    }

    /// Technique disponible ?
    var hasTechnique: Bool {
        performanceReport?.meta?.technique != nil
    }

    /// Technique Running disponible ?
    var hasRunningTechnique: Bool {
        performanceReport?.meta?.technique?.running != nil
    }

    /// Technique Cycling disponible ?
    var hasCyclingTechnique: Bool {
        performanceReport?.meta?.technique?.cycling != nil
    }

    /// Technique Swimming disponible ?
    var hasSwimmingTechnique: Bool {
        performanceReport?.meta?.technique?.swimming != nil
    }

    /// Technique Multi-sport disponible ?
    var hasMultiSportTechnique: Bool {
        performanceReport?.meta?.technique?.multiSport != nil
    }

    /// Zones VMA disponibles ?
    var hasVMAZones: Bool {
        performanceReport?.metrics.vmaZones != nil
    }

    /// Zones FTP disponibles ?
    var hasFTPZones: Bool {
        performanceReport?.metrics.ftpZones != nil
    }

    /// Zones CSS disponibles ?
    var hasCSSZones: Bool {
        performanceReport?.metrics.cssZones != nil
    }

    /// Records triés par distance
    var sortedBestDistances: [(key: String, value: BestDistanceRecord)] {
        guard let records = performanceReport?.metrics.bestDistances else { return [] }
        return records.sorted { first, second in
            // Extraire le nombre de la clé (ex: "1km" -> 1, "5km" -> 5)
            let num1 = Double(first.key.replacingOccurrences(of: "km", with: "")) ?? 0
            let num2 = Double(second.key.replacingOccurrences(of: "km", with: "")) ?? 0
            return num1 < num2
        }
    }
}
