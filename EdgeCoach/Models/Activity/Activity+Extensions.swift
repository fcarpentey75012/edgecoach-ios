// MARK: - Activity Extension - Découplage Nolio -> fileDatas

import Foundation

/**
 * Extension pour le découplage progressif du modèle Nolio.
 * Ces computed properties privilégient les données file_datas (enrichies depuis FIT/TCX)
 * avec fallback sur les champs Nolio de premier niveau.
 *
 * Objectif: Permettre de changer de source de données sans modifier les vues.
 */
extension Activity {

    // MARK: - Duration (file_datas uniquement - découplé de Nolio)

    /// Durée depuis file_datas uniquement (movingTime = temps effectif sans pauses)
    var preferredDuration: Int? {
        guard let movingTime = fileDatas?.movingTime, movingTime > 0 else { return nil }
        return Int(movingTime)
    }

    /// Durée préférée formatée
    var preferredFormattedDuration: String {
        guard let dur = preferredDuration else { return "--:--" }
        let hours = dur / 3600
        let minutes = (dur % 3600) / 60
        let secs = dur % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    // MARK: - Distance (file_datas uniquement - découplé de Nolio)

    /// Distance depuis file_datas uniquement (km)
    var preferredDistance: Double? {
        guard let dist = fileDatas?.distance, dist > 0 else { return nil }
        return dist
    }

    // MARK: - Elevation (file_datas uniquement - découplé de Nolio)

    /// Dénivelé positif depuis file_datas uniquement
    var preferredElevationGain: Double? {
        guard let ascent = fileDatas?.ascent, ascent > 0 else { return nil }
        return ascent
    }

    /// Dénivelé négatif depuis file_datas uniquement
    var preferredElevationLoss: Double? {
        guard let descent = fileDatas?.descent, descent > 0 else { return nil }
        return descent
    }

    // MARK: - Power (file_datas uniquement - découplé de Nolio)

    /// Puissance moyenne depuis file_datas uniquement
    var preferredAvgPower: Double? {
        guard let power = fileDatas?.avgPower, power > 0 else { return nil }
        return power
    }

    /// Puissance max depuis file_datas uniquement
    var preferredMaxPower: Double? {
        guard let power = fileDatas?.maxPower, power > 0 else { return nil }
        return power
    }

    /// Puissance normalisée depuis file_datas uniquement
    var preferredNP: Double? {
        guard let power = fileDatas?.normalizedPower, power > 0 else { return nil }
        return power
    }

    // MARK: - TSS / Load (file_datas uniquement - découplé de Nolio)

    /// TSS depuis file_datas uniquement
    var preferredTSS: Double? {
        guard let tss = fileDatas?.trainingStressScore, tss > 0 else { return nil }
        return tss
    }

    /// TSS en Int pour affichage
    var preferredTSSInt: Int? {
        guard let tss = preferredTSS else { return nil }
        return Int(tss)
    }

    // MARK: - Energy (file_datas uniquement - découplé de Nolio)

    /// Kilojoules depuis file_datas uniquement
    var preferredKilojoules: Double? {
        guard let kj = fileDatas?.kilojoules, kj > 0 else { return nil }
        return kj
    }

    /// TRIMP depuis file_datas uniquement
    var preferredTrimp: Double? {
        guard let t = fileDatas?.trimp, t > 0 else { return nil }
        return t
    }

    // MARK: - Heart Rate

    /// FC moyenne préférée: fileDatas.hrAvg avec fallback
    var preferredHrAvg: Double? {
        if let hrAvg = fileDatas?.hrAvg, hrAvg > 0 {
            return hrAvg
        }
        return nil
    }

    /// FC max préférée: fileDatas.hrMax avec fallback
    var preferredHrMax: Double? {
        if let hrMax = fileDatas?.hrMax, hrMax > 0 {
            return hrMax
        }
        return nil
    }

    /// FC min préférée
    var preferredHrMin: Double? {
        fileDatas?.hrMin
    }

    // MARK: - Speed

    /// Vitesse moyenne préférée (déjà calculée avec priorité dans ActivityFileData)
    var preferredAvgSpeed: Double? {
        fileDatas?.avgSpeed
    }

    /// Vitesse max préférée
    var preferredMaxSpeed: Double? {
        fileDatas?.maxSpeed
    }

    // MARK: - Altitude

    /// Altitude moyenne préférée
    var preferredAltitudeAvg: Double? {
        fileDatas?.altitudeAvg
    }

    /// Altitude max préférée
    var preferredAltitudeMax: Double? {
        fileDatas?.altitudeMax
    }

    /// Altitude min préférée
    var preferredAltitudeMin: Double? {
        fileDatas?.altitudeMin
    }

    // MARK: - Cadence

    /// Cadence moyenne préférée
    var preferredCadenceAvg: Double? {
        fileDatas?.cadenceAvg
    }

    /// Cadence max préférée
    var preferredCadenceMax: Double? {
        fileDatas?.cadenceMax
    }

    // MARK: - Calories

    /// Calories préférées: fileDatas.calories
    var preferredCalories: Double? {
        fileDatas?.calories
    }

    // MARK: - Helper pour VAM (Vélo)

    /// VAM calculée depuis données préférées (m/h)
    var preferredVAM: Double? {
        guard let gain = preferredElevationGain,
              let dur = preferredDuration,
              gain > 100 && dur > 0 else {
            return nil
        }
        return (gain / Double(dur)) * 3600
    }

    // MARK: - Checks for data availability

    /// Vérifie si des données file_datas existent
    var hasFileData: Bool {
        fileDatas != nil
    }

    /// Vérifie si des données d'élévation sont disponibles (depuis file_datas ou Nolio)
    var hasPreferredElevationData: Bool {
        preferredElevationGain != nil || preferredElevationLoss != nil
    }

    /// Vérifie si des données HR sont disponibles
    var hasPreferredHRData: Bool {
        preferredHrAvg != nil || preferredHrMax != nil
    }

    // MARK: - Compatibilité (champs supprimés - retournent nil)
    // Ces données utilisateur ne sont plus dans Activity, elles doivent venir du profil

    /// FTP (Functional Threshold Power) - supprimé, utiliser UserProfile
    var ftp: Double? { nil }

    /// Poids de l'athlète - supprimé, utiliser UserProfile
    var weight: Double? { nil }

    /// FC max de l'utilisateur - supprimé, utiliser UserProfile
    var maxHrUser: Double? { nil }

    /// Zones de puissance/FC calculées - supprimé
    var zones: [ActivityZone]? { nil }

    // MARK: - Helper Methods

    /// Crée une copie de l'activité avec de nouvelles données de fichier
    func with(fileDatas newFileDatas: ActivityFileData?) -> Activity {
        Activity(
            id: id,
            userId: userId,
            dateStart: dateStart,
            sport: sport,
            name: name,
            description: description,
            fileDatas: newFileDatas
        )
    }
}

// MARK: - Computed Properties (moved from main file)

extension Activity {
    /// Date parsée
    var date: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        if let date = formatter.date(from: dateStart) {
            return date
        }
        // Essayer format YYYY-MM-DD
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd"
        return simpleFormatter.date(from: dateStart)
    }

    /// Durée formatée (ex: "1:30" ou "45min")
    /// Utilise uniquement fileDatas.movingTime (temps en mouvement sans pauses)
    var formattedDuration: String? {
        guard let movingTime = fileDatas?.movingTime, movingTime > 0 else {
            // Fallback sur duration de fileDatas
            guard let dur = fileDatas?.duration, dur > 0 else { return nil }
            let seconds = Int(dur)
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            if hours > 0 {
                return String(format: "%d:%02d", hours, minutes)
            } else {
                return "\(minutes)min"
            }
        }

        let seconds = Int(movingTime)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return "\(minutes)min"
        }
    }

    /// Distance formatée (ex: "45.5 km" ou "1500 m")
    /// Utilise uniquement fileDatas.distance
    var formattedDistance: String? {
        guard let dist = fileDatas?.distance, dist > 0 else { return nil }
        if discipline == .natation {
            return String(format: "%.0f m", dist * 1000)
        }
        if dist < 1 {
            return String(format: "%.0f m", dist * 1000)
        }
        return dist.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f km", dist)
            : String(format: "%.1f km", dist)
    }

    /// Vitesse moyenne formatée
    var formattedAvgSpeed: String? {
        guard let fileDatas = fileDatas, let avgSpeed = fileDatas.avgSpeed else { return nil }
        return String(format: "%.1f km/h", avgSpeed)
    }

    /// Vitesse max formatée
    var formattedMaxSpeed: String? {
        guard let fileDatas = fileDatas, let maxSpeed = fileDatas.maxSpeed else { return nil }
        return String(format: "%.1f km/h", maxSpeed)
    }

    /// Puissance moyenne formatée (file_datas uniquement - découplé de Nolio)
    var formattedAvgPower: String? {
        guard let watts = preferredAvgPower else { return nil }
        return "\(Int(watts))W"
    }

    /// TSS (Training Stress Score) (file_datas uniquement - découplé de Nolio)
    var tss: Int? {
        guard let tssValue = preferredTSS else { return nil }
        return Int(tssValue)
    }

    /// Titre affiché
    var displayTitle: String {
        name ?? plannedName ?? discipline.displayName
    }

    /// Notes combinées
    var notes: String? {
        description ?? plannedDescription
    }

    /// Points GPS depuis file_datas
    /// Gère la conversion du format Garmin FIT (semicircles) vers degrés décimaux
    var gpsPoints: [GPSPoint]? {
        fileDatas?.records?.compactMap { record in
            guard let lat = record.positionLat, let lng = record.positionLong else { return nil }

            // Constante pour conversion semicircles -> degrés
            // semicircles = degrés * (2^31 / 180)
            let semicircleToDegrees = 180.0 / pow(2.0, 31.0)

            // Détection du format: si les valeurs sont > 180 ou < -180, c'est en semicircles
            let latitude: Double
            let longitude: Double

            if abs(lat) > 180 || abs(lng) > 180 {
                // Format Garmin FIT semicircles
                latitude = lat * semicircleToDegrees
                longitude = lng * semicircleToDegrees
            } else {
                // Format standard degrés décimaux
                latitude = lat
                longitude = lng
            }

            // Validation des coordonnées
            guard latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180 else {
                return nil
            }

            return GPSPoint(latitude: latitude, longitude: longitude, altitude: record.altitude, timestamp: nil)
        }
    }
}
