import Foundation

/// Service responsable de la préparation et de l'optimisation des données pour les graphiques
class ChartDataService {
    static let shared = ChartDataService()
    
    private init() {}
    
    /// Structure de données optimisée pour un point de graphique
    struct DataPoint: Identifiable, Equatable {
        let id = UUID()
        let timestamp: Date
        let distance: Double // Distance cumulée en mètres
        let elapsedSeconds: Double
        let value: Double
    }
    
    /// Type de métrique à extraire
    enum MetricType {
        case heartRate
        case power
        case speed
        case elevation
        case cadence
        case leftRightBalance
        case torqueEffectiveness
        case pedalSmoothness
    }
    
    /// Extrait et échantillonne les données d'une activité pour un graphique
    /// - Parameters:
    ///   - activity: L'activité source
    ///   - type: Le type de métrique
    ///   - targetPointCount: Nombre de points visés (défaut 300 pour un écran mobile)
    func extractData(from activity: Activity, type: MetricType, targetPointCount: Int = 300) -> [DataPoint] {
        guard let records = activity.fileDatas?.records, !records.isEmpty else {
            return []
        }

        // 1. Extraction brute
        var rawPoints: [(Double, Double, Double)] = [] // (Seconds, Distance, Value)

        let startTime = records.first?.timestamp ?? 0
        var accumulatedDistance = 0.0

        for record in records {
            // Gestion du temps
            let currentTimestamp = record.timestamp ?? 0
            let elapsed = max(0, currentTimestamp - startTime)
            
            // Gestion de la distance (si dispo dans record, sinon on ignore pour l'axe X distance)
            if let dist = record.distance {
                accumulatedDistance = dist
            }
            
            // Extraction de la valeur selon le type
            var value: Double?
            
            switch type {
            case .heartRate:
                value = record.heartRate
            case .power:
                value = record.power
            case .speed:
                // Conversion m/s -> km/h si nécessaire (souvent stocké en m/s dans FIT, mais km/h dans notre modèle décodé parfois)
                // Dans ActivityRecord, speed est stocké tel quel. Assumons km/h si > 100 ? Non, ActivityRecord stocke ce qui arrive.
                // Généralement API renvoie km/h. Si < 10, c'est peut-être m/s pour du vélo.
                // On garde la valeur brute, le formatage se fera à l'affichage.
                // ActivityRecord.speed est un Double optionnel.
                value = record.speed
            case .elevation:
                value = record.altitude
            case .cadence:
                value = record.cadence
            case .leftRightBalance:
                value = record.leftRightBalance
            case .torqueEffectiveness:
                value = record.torqueEffectiveness
            case .pedalSmoothness:
                value = record.pedalSmoothness
            }
            
            if let v = value {
                rawPoints.append((elapsed, accumulatedDistance, v))
            }
        }

        // 2. Downsampling (Algorithme Largest-Triangle-Three-Buckets ou simple moyennage)
        // Pour la performance et la simplicité ici -> Moyennage par fenêtre (Average Binning)
        
        guard rawPoints.count > targetPointCount else {
            // Pas besoin de downsampling
            return rawPoints.map {
                DataPoint(timestamp: Date(timeIntervalSince1970: startTime + $0.0), distance: $0.1, elapsedSeconds: $0.0, value: $0.2)
            }
        }
        
        var sampledPoints: [DataPoint] = []
        let binSize = Int(ceil(Double(rawPoints.count) / Double(targetPointCount)))
        
        for i in stride(from: 0, to: rawPoints.count, by: binSize) {
            let end = min(i + binSize, rawPoints.count)
            let bin = rawPoints[i..<end]
            
            guard !bin.isEmpty else { continue }
            
            // Moyenne des valeurs du bin
            let avgElapsed = bin.map { $0.0 }.reduce(0, +) / Double(bin.count)
            let avgDistance = bin.map { $0.1 }.reduce(0, +) / Double(bin.count)
            let avgValue = bin.map { $0.2 }.reduce(0, +) / Double(bin.count)
            
            sampledPoints.append(DataPoint(
                timestamp: Date(timeIntervalSince1970: startTime + avgElapsed),
                distance: avgDistance,
                elapsedSeconds: avgElapsed,
                value: avgValue
            ))
        }
        
        return sampledPoints
    }
    
    // MARK: - Power Duration Curve
    
    struct PowerCurvePoint: Identifiable {
        let id = UUID()
        let duration: Double // en secondes
        let watts: Double
        
        var formattedDuration: String {
            if duration < 60 { return "\(Int(duration))s" }
            if duration < 3600 { return "\(Int(duration)/60)m" }
            return "\(Int(duration)/3600)h"
        }
    }
    
    /// Calcule la courbe de puissance (Record de puissance sur différentes durées)
    func calculatePowerCurve(from activity: Activity) -> [PowerCurvePoint] {
        guard let records = activity.fileDatas?.records, !records.isEmpty else { return [] }
        
        // Extraire les puissances (remplacer les nils par 0)
        let powers = records.map { $0.power ?? 0 }
        
        // Durées standards à tester
        let durations: [Double] = [1, 5, 10, 30, 60, 120, 300, 600, 1200, 1800, 3600, 7200]
        var curve: [PowerCurvePoint] = []
        
        for duration in durations {
            let windowSize = Int(duration) // Supposant 1 point = 1 seconde (à affiner si sampling différent)
            guard windowSize <= powers.count else { break }
            
            var maxPower: Double = 0
            
            // Fenêtre glissante
            // Optimisation: calculer la somme initiale, puis glisser
            var currentSum = powers[0..<windowSize].reduce(0, +)
            maxPower = currentSum / Double(windowSize)
            
            for i in 1...(powers.count - windowSize) {
                currentSum = currentSum - powers[i-1] + powers[i+windowSize-1]
                let avg = currentSum / Double(windowSize)
                if avg > maxPower {
                    maxPower = avg
                }
            }
            
            if maxPower > 0 {
                curve.append(PowerCurvePoint(duration: duration, watts: maxPower))
            }
        }
        
        return curve
    }
}
