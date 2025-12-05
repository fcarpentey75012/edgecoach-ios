/**
 * Vues détaillées pour les métriques de performance
 * VMA, FTP, CSS, Records, CP/W'
 */

import SwiftUI

// MARK: - VMA Detail View

struct VMADetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let vma: VMAMetric?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    if let vma = vma {
                        // Main value
                        VStack(spacing: ECSpacing.sm) {
                            Text(String(format: "%.1f", vma.value))
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.sportColor(for: .course))

                            Text("km/h")
                                .font(.ecH4)
                                .foregroundColor(themeManager.textSecondary)

                            ConfidenceBadge(confidence: vma.confidencePercent)
                                .padding(.top, ECSpacing.xs)
                        }
                        .padding(.vertical, ECSpacing.xl)

                        // Interpretation Section
                        VMAInterpretationSection(vma: vma)

                        // Position Section
                        VMAPositionSection(vma: vma)

                        // Training Zones
                        if let zones = vma.trainingZones, !zones.isEmpty {
                            TrainingZonesSection(
                                title: "Zones d'entra\u{00EE}nement",
                                zones: zones,
                                discipline: .course
                            )
                        }

                        // Contributors
                        if let contributors = vma.contributors, !contributors.isEmpty {
                            VMAContributorsSection(contributors: contributors)
                        }

                        // Metadata
                        if let metadata = vma.metadata {
                            VMAMetadataSection(metadata: metadata)
                        }

                        // Usage Section
                        VMAUsageSection()
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("VMA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .environmentObject(themeManager)
    }
}

struct VMAContributorsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let contributors: [VMAContributor]

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text("Sessions contributives")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            ForEach(contributors) { contributor in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contributor.sessionName ?? "Session")
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textPrimary)
                            .lineLimit(1)

                        if let date = contributor.sessionDate {
                            Text(formatDate(date))
                                .font(.ecSmall)
                                .foregroundColor(themeManager.textSecondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if let vmaCandidate = contributor.vmaCandidateKmh {
                            Text(String(format: "%.1f km/h", vmaCandidate))
                                .font(.ecLabelBold)
                                .foregroundColor(themeManager.sportColor(for: .course))
                        }

                        if let weight = contributor.weight {
                            Text(String(format: "Poids: %.1f%%", weight * 100))
                                .font(.ecSmall)
                                .foregroundColor(themeManager.textTertiary)
                        }
                    }
                }
                .padding(ECSpacing.sm)
                .background(themeManager.surfaceColor)
                .cornerRadius(ECRadius.md)
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

struct VMAMetadataSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let metadata: VMAMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text("Param\u{00E8}tres de calcul")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            VStack(spacing: ECSpacing.sm) {
                if let count = metadata.candidatesCount {
                    MetadataRow(label: "Sessions analys\u{00E9}es", value: "\(count)")
                }
                if let adjustment = metadata.hrAdjustmentKmh {
                    MetadataRow(label: "Ajustement FC", value: String(format: "+%.1f km/h", adjustment))
                }
                if let weighting = metadata.timeWeighting {
                    if let halfLife = weighting.halfLifeDays {
                        MetadataRow(label: "Demi-vie", value: String(format: "%.0f jours", halfLife))
                    }
                    if let maxAge = weighting.maxAgeDays {
                        MetadataRow(label: "\u{00C2}ge max", value: "\(maxAge) jours")
                    }
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - VMA Interpretation Section

struct VMAInterpretationSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let vma: VMAMetric

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(themeManager.warningColor)
                Text("Comment interpréter")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.md) {
                InterpretationRow(
                    icon: "speedometer",
                    title: "Vitesse Maximale Aérobie",
                    description: "La vitesse à laquelle vous atteignez votre consommation maximale d'oxygène (VO2max). C'est un indicateur clé de votre potentiel aérobie en course à pied.",
                    color: themeManager.sportColor(for: .course)
                )

                Divider()
                    .padding(.vertical, ECSpacing.xs)

                VStack(alignment: .leading, spacing: ECSpacing.sm) {
                    Text("En pratique")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)

                    let vmaValue = vma.value

                    // Calculate typical race paces
                    let pace5k = 60 / (vmaValue * 0.95) // ~95% VMA
                    let pace10k = 60 / (vmaValue * 0.90) // ~90% VMA
                    let paceHM = 60 / (vmaValue * 0.85) // ~85% VMA

                    Text("Avec une VMA de \(String(format: "%.1f", vmaValue)) km/h, vos allures cibles sont environ :")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)

                    HStack(spacing: ECSpacing.md) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("5K")
                                .font(.ecCaptionBold)
                                .foregroundColor(themeManager.textTertiary)
                            Text("\(formatPace(pace5k))/km")
                                .font(.ecLabelBold)
                                .foregroundColor(themeManager.sportColor(for: .course))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("10K")
                                .font(.ecCaptionBold)
                                .foregroundColor(themeManager.textTertiary)
                            Text("\(formatPace(pace10k))/km")
                                .font(.ecLabelBold)
                                .foregroundColor(themeManager.sportColor(for: .course))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Semi")
                                .font(.ecCaptionBold)
                                .foregroundColor(themeManager.textTertiary)
                            Text("\(formatPace(paceHM))/km")
                                .font(.ecLabelBold)
                                .foregroundColor(themeManager.sportColor(for: .course))
                        }
                    }
                    .padding(.top, ECSpacing.xs)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }

    private func formatPace(_ pace: Double) -> String {
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - VMA Position Section

struct VMAPositionSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let vma: VMAMetric

    // Reference values for VMA (in km/h) based on running level
    private let vmaReferences: [(level: String, minKmh: Double, maxKmh: Double, description: String)] = [
        ("Débutant", 10, 14, "Coureurs occasionnels"),
        ("Intermédiaire", 14, 17, "Coureurs réguliers"),
        ("Avancé", 17, 20, "Coureurs entraînés"),
        ("Elite", 20, 23, "Compétiteurs régionaux/nationaux"),
        ("Pro", 23, 27, "Niveau international")
    ]

    private var currentLevel: (level: String, description: String)? {
        let value = vma.value
        for ref in vmaReferences {
            if value >= ref.minKmh && value < ref.maxKmh {
                return (ref.level, ref.description)
            }
        }
        if value >= vmaReferences.last?.minKmh ?? 23 {
            return (vmaReferences.last?.level ?? "", vmaReferences.last?.description ?? "")
        }
        return (vmaReferences.first?.level ?? "", vmaReferences.first?.description ?? "")
    }

    private var positionPercent: Double {
        let minVal = vmaReferences.first?.minKmh ?? 10
        let maxVal = vmaReferences.last?.maxKmh ?? 27
        return min(1.0, max(0.0, (vma.value - minVal) / (maxVal - minVal)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(themeManager.accentColor)
                Text("Votre positionnement")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                HStack {
                    Text("VMA")
                        .font(.ecLabel)
                        .foregroundColor(themeManager.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f km/h", vma.value))
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.sportColor(for: .course))
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.red.opacity(0.3),
                                Color.orange.opacity(0.3),
                                Color.yellow.opacity(0.3),
                                Color.green.opacity(0.3),
                                Color.blue.opacity(0.3)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 12)
                        .cornerRadius(6)

                        Circle()
                            .fill(themeManager.sportColor(for: .course))
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(color: themeManager.sportColor(for: .course).opacity(0.5), radius: 4)
                            .offset(x: (geometry.size.width - 20) * positionPercent)
                    }
                }
                .frame(height: 20)

                HStack {
                    ForEach(vmaReferences.indices, id: \.self) { index in
                        Text(vmaReferences[index].level)
                            .font(.system(size: 9))
                            .foregroundColor(themeManager.textTertiary)
                        if index < vmaReferences.count - 1 { Spacer() }
                    }
                }

                if let level = currentLevel {
                    HStack(spacing: ECSpacing.xs) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(themeManager.sportColor(for: .course))
                        Text("Niveau: \(level.level)")
                            .font(.ecSmall)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.textPrimary)
                        Text("(\(level.description))")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.textSecondary)
                    }
                    .padding(.top, ECSpacing.xs)
                }
            }

            // Profile analysis based on VMA and confidence
            VMAProfileAnalysis(vma: vma)
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

struct VMAProfileAnalysis: View {
    @EnvironmentObject var themeManager: ThemeManager
    let vma: VMAMetric

    private var profileAnalysis: (title: String, description: String, icon: String, recommendation: String) {
        let vmaValue = vma.value
        let confidence = vma.confidence

        if vmaValue >= 20 && confidence >= 0.7 {
            return (
                "Coureur confirmé",
                "Excellente VMA avec une bonne fiabilité. Vous avez un potentiel aérobie élevé.",
                "star.circle.fill",
                "Travaillez la VMA courte (30/30) et longue (3-5min) pour progresser encore."
            )
        } else if vmaValue >= 17 && confidence >= 0.6 {
            return (
                "Bon niveau",
                "Bonne VMA. Vous avez une base solide pour progresser sur toutes les distances.",
                "figure.run.circle.fill",
                "Alternez travail au seuil et séances VMA pour équilibrer votre progression."
            )
        } else if vmaValue >= 14 {
            return (
                "En progression",
                "VMA intermédiaire avec du potentiel. Le volume et la régularité seront vos meilleurs alliés.",
                "arrow.up.circle.fill",
                "Augmentez progressivement le volume hebdomadaire et intégrez 1 séance qualité/semaine."
            )
        } else {
            return (
                "En développement",
                "Votre VMA est encore en construction. Privilégiez la régularité avant l'intensité.",
                "chart.bar.fill",
                "Courez régulièrement en endurance fondamentale (70% FCmax). La progression viendra naturellement."
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Divider()
                .padding(.vertical, ECSpacing.xs)

            HStack(spacing: ECSpacing.sm) {
                Image(systemName: profileAnalysis.icon)
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Votre profil : \(profileAnalysis.title)")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                    Text(profileAnalysis.description)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(alignment: .top, spacing: ECSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.warningColor)
                Text(profileAnalysis.recommendation)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textSecondary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(ECSpacing.sm)
            .background(themeManager.warningColor.opacity(0.1))
            .cornerRadius(ECRadius.sm)
        }
    }
}

// MARK: - VMA Usage Section

struct VMAUsageSection: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "figure.run")
                    .foregroundColor(themeManager.sportColor(for: .course))
                Text("Comment utiliser ces données")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.md) {
                UsageTipRow(
                    number: "1",
                    title: "Définir vos zones",
                    description: "La VMA permet de calculer vos zones d'entraînement : Z1 (60-70%), Z2 (70-80%), Z3 (80-90%), Z4 (90-100%), Z5 (100-110%).",
                    sportColor: themeManager.sportColor(for: .course)
                )

                UsageTipRow(
                    number: "2",
                    title: "Séances VMA",
                    description: "Travaillez à 100-105% VMA avec des intervalles courts (30/30, 200m) ou longs (3-5min à 95-100%).",
                    sportColor: themeManager.sportColor(for: .course)
                )

                UsageTipRow(
                    number: "3",
                    title: "Prédire vos chronos",
                    description: "5K ≈ 95% VMA, 10K ≈ 90% VMA, Semi ≈ 85% VMA, Marathon ≈ 80% VMA.",
                    sportColor: themeManager.sportColor(for: .course)
                )

                UsageTipRow(
                    number: "4",
                    title: "Suivre votre progression",
                    description: "Retestez votre VMA tous les 2-3 mois. Une amélioration de 0.5-1 km/h indique une vraie progression.",
                    sportColor: themeManager.sportColor(for: .course)
                )
            }

            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Rappel")
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textTertiary)
                Text("VMA = Vitesse à VO2max ≈ Effort maximal 4-8 min")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(themeManager.accentColor)
            }
            .padding(ECSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.accentColor.opacity(0.1))
            .cornerRadius(ECRadius.sm)
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - FTP Detail View

struct FTPDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let ftp: FTPMetric?
    let weightKg: Double? // Poids de l'utilisateur pour calculer W/kg

    init(ftp: FTPMetric?, weightKg: Double? = nil) {
        self.ftp = ftp
        self.weightKg = weightKg
    }

    private var wPerKg: Double? {
        guard let weight = weightKg, let ftp = ftp, weight > 0 else { return nil }
        return ftp.value / weight
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    if let ftp = ftp {
                        // Main value
                        VStack(spacing: ECSpacing.sm) {
                            Text(String(format: "%.0f", ftp.value))
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.sportColor(for: .cyclisme))

                            Text("Watts")
                                .font(.ecH4)
                                .foregroundColor(themeManager.textSecondary)

                            // W/kg badge if weight is available
                            if let wkg = wPerKg {
                                HStack(spacing: ECSpacing.xs) {
                                    Image(systemName: "scalemass")
                                        .font(.system(size: 14))
                                    Text(String(format: "%.2f W/kg", wkg))
                                        .font(.ecLabelBold)
                                }
                                .foregroundColor(themeManager.accentColor)
                                .padding(.horizontal, ECSpacing.md)
                                .padding(.vertical, ECSpacing.xs)
                                .background(themeManager.accentColor.opacity(0.1))
                                .cornerRadius(ECRadius.md)
                            }

                            ConfidenceBadge(confidence: ftp.confidencePercent)
                                .padding(.top, ECSpacing.xs)
                        }
                        .padding(.vertical, ECSpacing.xl)

                        // Interpretation Section
                        FTPInterpretationSection(ftp: ftp)

                        // Position Section
                        FTPPositionSection(ftp: ftp, wPerKg: wPerKg)

                        // Training Zones
                        if let zones = ftp.trainingZones, !zones.isEmpty {
                            TrainingZonesSection(
                                title: "Zones de puissance",
                                zones: zones,
                                discipline: .cyclisme
                            )
                        }

                        // Contributors
                        if let contributors = ftp.contributors, !contributors.isEmpty {
                            FTPContributorsSection(contributors: contributors)
                        }

                        // Metadata
                        if let metadata = ftp.metadata {
                            FTPMetadataSection(metadata: metadata)
                        }

                        // Usage Section
                        FTPUsageSection()
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("FTP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .environmentObject(themeManager)
    }
}

struct FTPContributorsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let contributors: [FTPContributor]

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text("Sessions contributives")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            ForEach(contributors) { contributor in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contributor.sessionName ?? "Session")
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: ECSpacing.sm) {
                            if let date = contributor.sessionDate {
                                Text(formatDate(date))
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textSecondary)
                            }
                            if let duration = contributor.durationMin {
                                Text("\u{2022} \(Int(duration)) min")
                                    .font(.ecSmall)
                                    .foregroundColor(themeManager.textSecondary)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if let power = contributor.power {
                            Text("\(Int(power)) W")
                                .font(.ecLabelBold)
                                .foregroundColor(themeManager.sportColor(for: .cyclisme))
                        }
                        if let ftpCalc = contributor.ftpCalculated {
                            Text("FTP: \(Int(ftpCalc)) W")
                                .font(.ecSmall)
                                .foregroundColor(themeManager.textTertiary)
                        }
                    }
                }
                .padding(ECSpacing.sm)
                .background(themeManager.surfaceColor)
                .cornerRadius(ECRadius.md)
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

struct FTPMetadataSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let metadata: FTPMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text("Analyse")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            VStack(spacing: ECSpacing.sm) {
                if let classic = metadata.classicFtp {
                    MetadataRow(label: "FTP classique", value: "\(Int(classic)) W")
                }
                if let gain = metadata.gainVsClassic, let gainPct = metadata.gainPercentage {
                    let sign = gain >= 0 ? "+" : ""
                    MetadataRow(
                        label: "vs classique",
                        value: "\(sign)\(Int(gain)) W (\(sign)\(String(format: "%.1f", gainPct))%)"
                    )
                }
                if let stdDev = metadata.relativeStdDev {
                    MetadataRow(label: "\u{00C9}cart-type relatif", value: String(format: "%.1f%%", stdDev * 100))
                }
                if let drift = metadata.driftApplied, drift {
                    MetadataRow(label: "D\u{00E9}rive appliqu\u{00E9}e", value: String(format: "%.0f%%", metadata.driftPercent ?? 0))
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - FTP Interpretation Section

struct FTPInterpretationSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let ftp: FTPMetric

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(themeManager.warningColor)
                Text("Comment interpréter")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.md) {
                InterpretationRow(
                    icon: "bolt.fill",
                    title: "Functional Threshold Power",
                    description: "La puissance maximale que vous pouvez maintenir pendant environ 1 heure. C'est votre seuil lactique fonctionnel en cyclisme.",
                    color: themeManager.sportColor(for: .cyclisme)
                )

                Divider()
                    .padding(.vertical, ECSpacing.xs)

                VStack(alignment: .leading, spacing: ECSpacing.sm) {
                    Text("En pratique")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)

                    let ftpValue = ftp.value

                    // Calculate typical training zones
                    let zone2 = ftpValue * 0.75 // Endurance
                    let zone3 = ftpValue * 0.90 // Tempo
                    let zone4 = ftpValue * 0.95 // Seuil
                    let zone5 = ftpValue * 1.05 // VO2max

                    Text("Avec une FTP de \(String(format: "%.0f", ftpValue)) W, vos zones de puissance sont :")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)

                    HStack(spacing: ECSpacing.sm) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Z2")
                                .font(.ecCaptionBold)
                                .foregroundColor(themeManager.textTertiary)
                            Text("\(Int(zone2))W")
                                .font(.ecLabelBold)
                                .foregroundColor(.green)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Z3")
                                .font(.ecCaptionBold)
                                .foregroundColor(themeManager.textTertiary)
                            Text("\(Int(zone3))W")
                                .font(.ecLabelBold)
                                .foregroundColor(.yellow)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Z4")
                                .font(.ecCaptionBold)
                                .foregroundColor(themeManager.textTertiary)
                            Text("\(Int(zone4))W")
                                .font(.ecLabelBold)
                                .foregroundColor(.orange)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Z5")
                                .font(.ecCaptionBold)
                                .foregroundColor(themeManager.textTertiary)
                            Text("\(Int(zone5))W")
                                .font(.ecLabelBold)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.top, ECSpacing.xs)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - FTP Position Section

struct FTPPositionSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let ftp: FTPMetric
    let wPerKg: Double? // W/kg optionnel

    // Reference values for FTP (in W/kg for fairness)
    private let ftpWkgReferences: [(level: String, minWkg: Double, maxWkg: Double, description: String)] = [
        ("Débutant", 1.5, 2.5, "Cyclistes occasionnels"),
        ("Intermédiaire", 2.5, 3.5, "Cyclistes réguliers"),
        ("Avancé", 3.5, 4.5, "Cyclistes entraînés"),
        ("Elite", 4.5, 5.5, "Compétiteurs"),
        ("Pro", 5.5, 7.0, "Niveau professionnel")
    ]

    // Fallback: absolute power references if no W/kg
    private let ftpAbsoluteReferences: [(level: String, minW: Double, maxW: Double, description: String)] = [
        ("Débutant", 100, 180, "Cyclistes occasionnels"),
        ("Intermédiaire", 180, 250, "Cyclistes réguliers"),
        ("Avancé", 250, 320, "Cyclistes entraînés"),
        ("Elite", 320, 400, "Compétiteurs"),
        ("Pro", 400, 550, "Niveau professionnel")
    ]

    private var useWkg: Bool {
        wPerKg != nil
    }

    private var currentLevel: (level: String, description: String)? {
        if let wkg = wPerKg {
            for ref in ftpWkgReferences {
                if wkg >= ref.minWkg && wkg < ref.maxWkg {
                    return (ref.level, ref.description)
                }
            }
            if wkg >= ftpWkgReferences.last?.minWkg ?? 5.5 {
                return (ftpWkgReferences.last?.level ?? "", ftpWkgReferences.last?.description ?? "")
            }
            return (ftpWkgReferences.first?.level ?? "", ftpWkgReferences.first?.description ?? "")
        } else {
            let value = ftp.value
            for ref in ftpAbsoluteReferences {
                if value >= ref.minW && value < ref.maxW {
                    return (ref.level, ref.description)
                }
            }
            if value >= ftpAbsoluteReferences.last?.minW ?? 400 {
                return (ftpAbsoluteReferences.last?.level ?? "", ftpAbsoluteReferences.last?.description ?? "")
            }
            return (ftpAbsoluteReferences.first?.level ?? "", ftpAbsoluteReferences.first?.description ?? "")
        }
    }

    private var positionPercent: Double {
        if let wkg = wPerKg {
            let minVal = ftpWkgReferences.first?.minWkg ?? 1.5
            let maxVal = ftpWkgReferences.last?.maxWkg ?? 7.0
            return min(1.0, max(0.0, (wkg - minVal) / (maxVal - minVal)))
        } else {
            let minVal = ftpAbsoluteReferences.first?.minW ?? 100
            let maxVal = ftpAbsoluteReferences.last?.maxW ?? 550
            return min(1.0, max(0.0, (ftp.value - minVal) / (maxVal - minVal)))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(themeManager.accentColor)
                Text("Votre positionnement")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                HStack {
                    Text(useWkg ? "FTP (W/kg)" : "FTP")
                        .font(.ecLabel)
                        .foregroundColor(themeManager.textSecondary)
                    Spacer()
                    if let wkg = wPerKg {
                        Text(String(format: "%.2f W/kg", wkg))
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.sportColor(for: .cyclisme))
                    } else {
                        Text(String(format: "%.0f W", ftp.value))
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.sportColor(for: .cyclisme))
                    }
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.red.opacity(0.3),
                                Color.orange.opacity(0.3),
                                Color.yellow.opacity(0.3),
                                Color.green.opacity(0.3),
                                Color.blue.opacity(0.3)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 12)
                        .cornerRadius(6)

                        Circle()
                            .fill(themeManager.sportColor(for: .cyclisme))
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(color: themeManager.sportColor(for: .cyclisme).opacity(0.5), radius: 4)
                            .offset(x: (geometry.size.width - 20) * positionPercent)
                    }
                }
                .frame(height: 20)

                HStack {
                    let refs = useWkg ? ftpWkgReferences.map { $0.level } : ftpAbsoluteReferences.map { $0.level }
                    ForEach(refs.indices, id: \.self) { index in
                        Text(refs[index])
                            .font(.system(size: 9))
                            .foregroundColor(themeManager.textTertiary)
                        if index < refs.count - 1 { Spacer() }
                    }
                }

                if let level = currentLevel {
                    HStack(spacing: ECSpacing.xs) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(themeManager.sportColor(for: .cyclisme))
                        Text("Niveau: \(level.level)")
                            .font(.ecSmall)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.textPrimary)
                        Text("(\(level.description))")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.textSecondary)
                    }
                    .padding(.top, ECSpacing.xs)
                }
            }

            // Profile analysis
            FTPProfileAnalysis(ftp: ftp, wPerKg: wPerKg)
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

struct FTPProfileAnalysis: View {
    @EnvironmentObject var themeManager: ThemeManager
    let ftp: FTPMetric
    let wPerKg: Double?

    private var profileAnalysis: (title: String, description: String, icon: String, recommendation: String) {
        let confidence = ftp.confidence
        let wkg = wPerKg ?? (ftp.value / 70) // Estimation si pas de poids

        if wkg >= 4.5 && confidence >= 0.7 {
            return (
                "Cycliste confirmé",
                "Excellente FTP avec une bonne fiabilité. Vous avez un haut niveau de puissance au seuil.",
                "star.circle.fill",
                "Travaillez sweet spot et VO2max pour continuer à progresser."
            )
        } else if wkg >= 3.5 && confidence >= 0.6 {
            return (
                "Bon niveau",
                "Bonne FTP. Vous avez une base solide pour la compétition amateur.",
                "figure.outdoor.cycle",
                "Augmentez le volume au sweet spot (88-94% FTP) et intégrez des blocs VO2max."
            )
        } else if wkg >= 2.5 {
            return (
                "En progression",
                "FTP intermédiaire avec du potentiel. La constance sera votre alliée.",
                "arrow.up.circle.fill",
                "Privilégiez le volume en Z2 avec 1-2 séances qualité par semaine."
            )
        } else {
            return (
                "En développement",
                "Votre FTP est en construction. Focus sur la régularité et le plaisir de rouler.",
                "chart.bar.fill",
                "Roulez régulièrement en endurance. Chaque sortie compte pour progresser."
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Divider()
                .padding(.vertical, ECSpacing.xs)

            HStack(spacing: ECSpacing.sm) {
                Image(systemName: profileAnalysis.icon)
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Votre profil : \(profileAnalysis.title)")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                    Text(profileAnalysis.description)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(alignment: .top, spacing: ECSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.warningColor)
                Text(profileAnalysis.recommendation)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textSecondary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(ECSpacing.sm)
            .background(themeManager.warningColor.opacity(0.1))
            .cornerRadius(ECRadius.sm)
        }
    }
}

// MARK: - FTP Usage Section

struct FTPUsageSection: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "figure.outdoor.cycle")
                    .foregroundColor(themeManager.sportColor(for: .cyclisme))
                Text("Comment utiliser ces données")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.md) {
                UsageTipRow(
                    number: "1",
                    title: "Définir vos zones",
                    description: "Z1 (<55%), Z2 (55-75%), Z3 (75-90%), Z4 (90-105%), Z5 (105-120%), Z6/Z7 (>120%).",
                    sportColor: themeManager.sportColor(for: .cyclisme)
                )

                UsageTipRow(
                    number: "2",
                    title: "Sweet Spot",
                    description: "Travaillez à 88-94% de votre FTP pour un excellent rapport effort/bénéfice. Idéal pour progresser rapidement.",
                    sportColor: themeManager.sportColor(for: .cyclisme)
                )

                UsageTipRow(
                    number: "3",
                    title: "Gérer vos sorties",
                    description: "CLM = 95-100% FTP, Montées longues = 90-95% FTP, Entraînement = adaptez selon l'objectif.",
                    sportColor: themeManager.sportColor(for: .cyclisme)
                )

                UsageTipRow(
                    number: "4",
                    title: "Suivre votre progression",
                    description: "Retestez votre FTP toutes les 4-6 semaines. Un gain de 5-10W indique une vraie progression.",
                    sportColor: themeManager.sportColor(for: .cyclisme)
                )
            }

            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Rappel")
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textTertiary)
                Text("FTP = Puissance max tenable ~1h ≈ Seuil lactique")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(themeManager.accentColor)
            }
            .padding(ECSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.accentColor.opacity(0.1))
            .cornerRadius(ECRadius.sm)
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - FTP Hybrid Detail View

struct FTPHybridDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let ftpHybrid: FTPHybridMetric?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    if let data = ftpHybrid {
                        // Main value
                        VStack(spacing: ECSpacing.sm) {
                            Text(String(format: "%.0f", data.value))
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.sportColor(for: .cyclisme))

                            Text("Watts")
                                .font(.ecH4)
                                .foregroundColor(themeManager.textSecondary)

                            // W/kg badge
                            if let wPerKg = data.wPerKg {
                                HStack(spacing: ECSpacing.xs) {
                                    Image(systemName: "scalemass")
                                        .font(.system(size: 14))
                                    Text(String(format: "%.2f W/kg", wPerKg.value))
                                        .font(.ecLabelBold)
                                }
                                .foregroundColor(themeManager.accentColor)
                                .padding(.horizontal, ECSpacing.md)
                                .padding(.vertical, ECSpacing.xs)
                                .background(themeManager.accentColor.opacity(0.1))
                                .cornerRadius(ECRadius.md)
                                .padding(.top, ECSpacing.xs)
                            }
                        }
                        .padding(.vertical, ECSpacing.xl)

                        // Interpretation Section
                        FTPHybridInterpretationSection(ftpHybrid: data)

                        // Position Section
                        FTPHybridPositionSection(ftpHybrid: data)

                        // Window details
                        if let details = data.details, !details.isEmpty {
                            FTPHybridWindowsSection(details: details)
                        }

                        // Meta info
                        if let meta = data.meta {
                            FTPHybridMetaSection(meta: meta)
                        }

                        // Usage Section
                        FTPHybridUsageSection()
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("FTP Hybrid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .environmentObject(themeManager)
    }
}

struct FTPHybridWindowsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let details: [FTPHybridDetail]

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text("Estimation par fenêtre")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            VStack(spacing: ECSpacing.sm) {
                // Header
                HStack {
                    Text("Durée")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                        .frame(width: 60, alignment: .leading)
                    Text("NP")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                        .frame(width: 60, alignment: .center)
                    Text("FTP Est.")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                        .frame(width: 70, alignment: .center)
                    Spacer()
                    Text("FC%")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                        .frame(width: 50, alignment: .trailing)
                }
                .padding(.horizontal, ECSpacing.sm)

                ForEach(details) { detail in
                    HStack {
                        Text(detail.formattedDuration)
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textPrimary)
                            .frame(width: 60, alignment: .leading)

                        if let np = detail.np {
                            Text("\(Int(np))")
                                .font(.ecLabel)
                                .foregroundColor(themeManager.textSecondary)
                                .frame(width: 60, alignment: .center)
                        }

                        if let ftpEst = detail.ftpEst {
                            Text("\(Int(ftpEst)) W")
                                .font(.ecLabelBold)
                                .foregroundColor(themeManager.sportColor(for: .cyclisme))
                                .frame(width: 70, alignment: .center)
                        }

                        Spacer()

                        if let hrPct = detail.hrPct {
                            Text(String(format: "%.1f%%", hrPct))
                                .font(.ecSmall)
                                .foregroundColor(hrPct > 90 ? themeManager.errorColor : (hrPct > 85 ? themeManager.warningColor : themeManager.successColor))
                                .frame(width: 50, alignment: .trailing)
                        }
                    }
                    .padding(ECSpacing.sm)
                    .background(themeManager.surfaceColor)
                    .cornerRadius(ECRadius.md)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

struct FTPHybridMetaSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let meta: FTPHybridMeta

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text("Paramètres")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            VStack(spacing: ECSpacing.sm) {
                if let method = meta.method {
                    MetadataRow(label: "Méthode", value: method.replacingOccurrences(of: "_", with: " ").capitalized)
                }

                if let params = meta.params {
                    if let minHr = params.minHrmaxPct {
                        MetadataRow(label: "FC min requise", value: String(format: "%.0f%%", minHr))
                    }
                    if let targetHr = params.targetHrmaxPct {
                        MetadataRow(label: "FC cible", value: String(format: "%.0f%%", targetHr))
                    }
                    if let cap = params.hrCorrectionCap {
                        MetadataRow(label: "Correction max", value: String(format: "+%.0f%%", (cap - 1) * 100))
                    }
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - FTP Hybrid Interpretation Section

struct FTPHybridInterpretationSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let ftpHybrid: FTPHybridMetric

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(themeManager.warningColor)
                Text("Comment interpréter")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.md) {
                InterpretationRow(
                    icon: "bolt.fill",
                    title: "FTP Hybrid",
                    description: "Une estimation avancée de votre FTP qui combine plusieurs fenêtres de puissance (20, 30, 45, 60 min) pondérées par leur fiabilité et la fréquence cardiaque associée.",
                    color: themeManager.sportColor(for: .cyclisme)
                )

                InterpretationRow(
                    icon: "waveform.path.ecg",
                    title: "Correction FC",
                    description: "L'algorithme ajuste les estimations en fonction de la FC : si votre FC était basse lors d'un effort, la FTP estimée est corrigée à la hausse (vous aviez plus de marge).",
                    color: themeManager.accentColor
                )

                Divider()
                    .padding(.vertical, ECSpacing.xs)

                VStack(alignment: .leading, spacing: ECSpacing.sm) {
                    Text("Avantages vs FTP classique")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)

                    HStack(alignment: .top, spacing: ECSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.successColor)
                        Text("Plus précis car basé sur plusieurs durées d'effort")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    HStack(alignment: .top, spacing: ECSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.successColor)
                        Text("Corrige les biais liés à la fatigue ou au sous-engagement")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    HStack(alignment: .top, spacing: ECSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.successColor)
                        Text("Pas besoin de test dédié : calcul automatique sur vos sorties")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - FTP Hybrid Position Section

struct FTPHybridPositionSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let ftpHybrid: FTPHybridMetric

    // Reference values for FTP (in W/kg for fairness)
    private let ftpWkgReferences: [(level: String, minWkg: Double, maxWkg: Double, description: String)] = [
        ("Débutant", 1.5, 2.5, "Cyclistes occasionnels"),
        ("Intermédiaire", 2.5, 3.5, "Cyclistes réguliers"),
        ("Avancé", 3.5, 4.5, "Cyclistes entraînés"),
        ("Elite", 4.5, 5.5, "Compétiteurs"),
        ("Pro", 5.5, 7.0, "Niveau professionnel")
    ]

    // Fallback: absolute power references if no W/kg
    private let ftpAbsoluteReferences: [(level: String, minW: Double, maxW: Double, description: String)] = [
        ("Débutant", 100, 180, "Cyclistes occasionnels"),
        ("Intermédiaire", 180, 250, "Cyclistes réguliers"),
        ("Avancé", 250, 320, "Cyclistes entraînés"),
        ("Elite", 320, 400, "Compétiteurs"),
        ("Pro", 400, 550, "Niveau professionnel")
    ]

    private var wPerKgValue: Double? {
        ftpHybrid.wPerKg?.value
    }

    private var useWkg: Bool {
        wPerKgValue != nil
    }

    private var currentLevel: (level: String, description: String)? {
        if let wkg = wPerKgValue {
            for ref in ftpWkgReferences {
                if wkg >= ref.minWkg && wkg < ref.maxWkg {
                    return (ref.level, ref.description)
                }
            }
            if wkg >= ftpWkgReferences.last?.minWkg ?? 5.5 {
                return (ftpWkgReferences.last?.level ?? "", ftpWkgReferences.last?.description ?? "")
            }
            return (ftpWkgReferences.first?.level ?? "", ftpWkgReferences.first?.description ?? "")
        } else {
            let value = ftpHybrid.value
            for ref in ftpAbsoluteReferences {
                if value >= ref.minW && value < ref.maxW {
                    return (ref.level, ref.description)
                }
            }
            if value >= ftpAbsoluteReferences.last?.minW ?? 400 {
                return (ftpAbsoluteReferences.last?.level ?? "", ftpAbsoluteReferences.last?.description ?? "")
            }
            return (ftpAbsoluteReferences.first?.level ?? "", ftpAbsoluteReferences.first?.description ?? "")
        }
    }

    private var positionPercent: Double {
        if let wkg = wPerKgValue {
            let minVal = ftpWkgReferences.first?.minWkg ?? 1.5
            let maxVal = ftpWkgReferences.last?.maxWkg ?? 7.0
            return min(1.0, max(0.0, (wkg - minVal) / (maxVal - minVal)))
        } else {
            let minVal = ftpAbsoluteReferences.first?.minW ?? 100
            let maxVal = ftpAbsoluteReferences.last?.maxW ?? 550
            return min(1.0, max(0.0, (ftpHybrid.value - minVal) / (maxVal - minVal)))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(themeManager.accentColor)
                Text("Votre positionnement")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                HStack {
                    Text(useWkg ? "FTP Hybrid (W/kg)" : "FTP Hybrid")
                        .font(.ecLabel)
                        .foregroundColor(themeManager.textSecondary)
                    Spacer()
                    if let wkg = wPerKgValue {
                        Text(String(format: "%.2f W/kg", wkg))
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.sportColor(for: .cyclisme))
                    } else {
                        Text(String(format: "%.0f W", ftpHybrid.value))
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.sportColor(for: .cyclisme))
                    }
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.red.opacity(0.3),
                                Color.orange.opacity(0.3),
                                Color.yellow.opacity(0.3),
                                Color.green.opacity(0.3),
                                Color.blue.opacity(0.3)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 12)
                        .cornerRadius(6)

                        Circle()
                            .fill(themeManager.sportColor(for: .cyclisme))
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(color: themeManager.sportColor(for: .cyclisme).opacity(0.5), radius: 4)
                            .offset(x: (geometry.size.width - 20) * positionPercent)
                    }
                }
                .frame(height: 20)

                HStack {
                    let refs = useWkg ? ftpWkgReferences.map { $0.level } : ftpAbsoluteReferences.map { $0.level }
                    ForEach(refs.indices, id: \.self) { index in
                        Text(refs[index])
                            .font(.system(size: 9))
                            .foregroundColor(themeManager.textTertiary)
                        if index < refs.count - 1 { Spacer() }
                    }
                }

                if let level = currentLevel {
                    HStack(spacing: ECSpacing.xs) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(themeManager.sportColor(for: .cyclisme))
                        Text("Niveau: \(level.level)")
                            .font(.ecSmall)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.textPrimary)
                        Text("(\(level.description))")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.textSecondary)
                    }
                    .padding(.top, ECSpacing.xs)
                }
            }

            // Profile analysis
            FTPHybridProfileAnalysis(ftpHybrid: ftpHybrid)
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

struct FTPHybridProfileAnalysis: View {
    @EnvironmentObject var themeManager: ThemeManager
    let ftpHybrid: FTPHybridMetric

    private var profileAnalysis: (title: String, description: String, icon: String, recommendation: String) {
        let wkg = ftpHybrid.wPerKg?.value ?? (ftpHybrid.value / 70) // Estimation si pas de poids

        if wkg >= 4.5 {
            return (
                "Cycliste confirmé",
                "Excellente FTP Hybrid. Votre puissance au seuil est au niveau compétiteur.",
                "star.circle.fill",
                "Optimisez avec du travail spécifique : VO2max pour la puissance, sweet spot pour l'endurance."
            )
        } else if wkg >= 3.5 {
            return (
                "Bon niveau",
                "Bonne FTP Hybrid. Vous avez une base solide pour progresser vers le haut niveau.",
                "figure.outdoor.cycle",
                "Augmentez le volume au sweet spot et intégrez des blocs VO2max ciblés."
            )
        } else if wkg >= 2.5 {
            return (
                "En progression",
                "FTP Hybrid intermédiaire. La marge de progression est importante !",
                "arrow.up.circle.fill",
                "Privilégiez la régularité : 3-4 sorties/semaine avec 1-2 séances qualité."
            )
        } else {
            return (
                "En développement",
                "Votre FTP Hybrid est en construction. Chaque sortie compte !",
                "chart.bar.fill",
                "Focus sur le plaisir et la régularité. Les watts viendront naturellement."
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Divider()
                .padding(.vertical, ECSpacing.xs)

            HStack(spacing: ECSpacing.sm) {
                Image(systemName: profileAnalysis.icon)
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Votre profil : \(profileAnalysis.title)")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                    Text(profileAnalysis.description)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(alignment: .top, spacing: ECSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.warningColor)
                Text(profileAnalysis.recommendation)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textSecondary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(ECSpacing.sm)
            .background(themeManager.warningColor.opacity(0.1))
            .cornerRadius(ECRadius.sm)
        }
    }
}

// MARK: - FTP Hybrid Usage Section

struct FTPHybridUsageSection: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "figure.outdoor.cycle")
                    .foregroundColor(themeManager.sportColor(for: .cyclisme))
                Text("Comment utiliser ces données")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.md) {
                UsageTipRow(
                    number: "1",
                    title: "Référence fiable",
                    description: "La FTP Hybrid est généralement plus précise que la FTP classique. Utilisez-la pour définir vos zones de puissance.",
                    sportColor: themeManager.sportColor(for: .cyclisme)
                )

                UsageTipRow(
                    number: "2",
                    title: "Comparer les fenêtres",
                    description: "Regardez les FTP estimées par fenêtre : si 20min >> 60min, vous avez un profil plus anaérobie. L'inverse indique un profil endurant.",
                    sportColor: themeManager.sportColor(for: .cyclisme)
                )

                UsageTipRow(
                    number: "3",
                    title: "Surveiller la FC",
                    description: "Les FC% indiquent l'intensité relative. >90% = effort très intense. <85% = marge disponible.",
                    sportColor: themeManager.sportColor(for: .cyclisme)
                )

                UsageTipRow(
                    number: "4",
                    title: "Progression automatique",
                    description: "Pas besoin de test formel. Roulez régulièrement avec des efforts soutenus et la FTP Hybrid se mettra à jour.",
                    sportColor: themeManager.sportColor(for: .cyclisme)
                )
            }

            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Rappel")
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textTertiary)
                Text("FTP Hybrid = Moyenne pondérée multi-fenêtres + correction FC")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(themeManager.accentColor)
            }
            .padding(ECSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.accentColor.opacity(0.1))
            .cornerRadius(ECRadius.sm)
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - CSS Detail View

struct CSSDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let css: CSSMetric?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    if let css = css {
                        // Main value
                        VStack(spacing: ECSpacing.sm) {
                            Text(css.formattedValue)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.sportColor(for: .natation))

                            ConfidenceBadge(confidence: css.confidencePercent)
                                .padding(.top, ECSpacing.xs)
                        }
                        .padding(.vertical, ECSpacing.xl)

                        // Interpretation Section
                        CSSInterpretationSection(css: css)

                        // Athlete Position Section
                        CSSPositionSection(css: css)

                        // Training Zones
                        if let zones = css.trainingZones, !zones.isEmpty {
                            TrainingZonesSection(
                                title: "Zones de natation",
                                zones: zones,
                                discipline: .natation
                            )
                        }

                        // Metadata
                        if let metadata = css.metadata {
                            CSSMetadataSection(metadata: metadata)
                        }

                        // How to use section
                        CSSUsageSection()
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("CSS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .environmentObject(themeManager)
    }
}

struct CSSMetadataSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let metadata: CSSMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text("Informations")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            VStack(spacing: ECSpacing.sm) {
                if let speed = metadata.cssMs {
                    MetadataRow(label: "Vitesse CSS", value: String(format: "%.2f m/s", speed))
                }
                if let efforts = metadata.effortsAnalyzed {
                    MetadataRow(label: "Efforts analysés", value: "\(efforts)")
                }
            }

            // CSS Methods section
            if let methods = metadata.cssMethods {
                Divider()
                    .padding(.vertical, ECSpacing.xs)

                HStack {
                    Text("Méthodes de calcul")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)

                    Spacer()

                    // Badge méthode principale
                    if let primary = methods.primaryMethod {
                        Text(methodDisplayName(primary))
                            .font(.ecSmall)
                            .foregroundColor(.white)
                            .padding(.horizontal, ECSpacing.sm)
                            .padding(.vertical, 2)
                            .background(themeManager.accentColor)
                            .cornerRadius(ECRadius.sm)
                    }
                }

                VStack(spacing: ECSpacing.sm) {
                    // Best Efforts method (nouvelle méthode prioritaire)
                    if let bestEfforts = methods.bestEfforts, bestEfforts.value != nil {
                        CSSMethodCard(
                            title: "Meilleurs efforts",
                            subtitle: bestEfforts.nEfforts != nil ? "\(bestEfforts.nEfforts!) efforts • Durée moy: \(bestEfforts.formattedAvgDuration)" : nil,
                            value: bestEfforts.value,
                            confidence: bestEfforts.confidencePercent,
                            isActive: methods.primaryMethod == "best_efforts",
                            additionalInfo: bestEfforts.speedCv != nil ? "CV: \(String(format: "%.1f%%", bestEfforts.speedCv! * 100))" : nil
                        )
                    }

                    // Time trials method
                    if let timeTrials = methods.timeTrials, timeTrials.value != nil {
                        CSSMethodCard(
                            title: "Tests de temps",
                            subtitle: nil,
                            value: timeTrials.value,
                            confidence: timeTrials.confidencePercent,
                            isActive: methods.primaryMethod == "time_trials",
                            additionalInfo: nil
                        )
                    } else if methods.timeTrials == nil && methods.primaryMethod != nil {
                        CSSMethodUnavailable(title: "Tests de temps", reason: "Pas assez d'efforts de qualité")
                    }

                    // Regression method
                    if let regression = methods.regression, regression.value != nil {
                        CSSMethodCard(
                            title: "Régression linéaire",
                            subtitle: regression.rSquared != nil ? "R² = \(String(format: "%.2f", regression.rSquared!))" : nil,
                            value: regression.value,
                            confidence: regression.confidencePercent,
                            isActive: methods.primaryMethod == "regression",
                            additionalInfo: nil
                        )
                    } else if methods.regression == nil && methods.primaryMethod != nil {
                        CSSMethodUnavailable(title: "Régression", reason: "Minimum 3 points requis")
                    }
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }

    private func methodDisplayName(_ method: String) -> String {
        switch method {
        case "best_efforts": return "Meilleurs efforts"
        case "time_trials": return "Tests de temps"
        case "regression": return "Régression"
        default: return method
        }
    }
}

struct CSSMethodCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let subtitle: String?
    let value: Double?
    let confidence: Int
    let isActive: Bool
    let additionalInfo: String?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: ECSpacing.xs) {
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.successColor)
                    }
                    Text(title)
                        .font(.ecLabel)
                        .foregroundColor(isActive ? themeManager.textPrimary : themeManager.textSecondary)
                }

                HStack(spacing: ECSpacing.sm) {
                    if let val = value {
                        Text(String(format: "%.2f m/s", val))
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }
                    if let sub = subtitle {
                        Text("• \(sub)")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textTertiary)
                    }
                    if let info = additionalInfo {
                        Text("• \(info)")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textTertiary)
                    }
                }
            }

            Spacer()

            Text("\(confidence)%")
                .font(.ecLabelBold)
                .foregroundColor(confidence >= 80 ? themeManager.successColor : (confidence >= 50 ? themeManager.warningColor : themeManager.textTertiary))
        }
        .padding(ECSpacing.sm)
        .background(isActive ? themeManager.accentColor.opacity(0.1) : themeManager.surfaceColor)
        .cornerRadius(ECRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.md)
                .stroke(isActive ? themeManager.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

struct CSSMethodUnavailable: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let reason: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: ECSpacing.xs) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.textTertiary)
                    Text(title)
                        .font(.ecLabel)
                        .foregroundColor(themeManager.textTertiary)
                }
                Text(reason)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textTertiary)
                    .italic()
            }

            Spacer()

            Text("N/A")
                .font(.ecSmall)
                .foregroundColor(themeManager.textTertiary)
        }
        .padding(ECSpacing.sm)
        .background(themeManager.surfaceColor.opacity(0.5))
        .cornerRadius(ECRadius.md)
    }
}

// MARK: - Best Distances Detail View

struct BestDistancesDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let records: [(key: String, value: BestDistanceRecord)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    ForEach(records, id: \.key) { key, record in
                        RecordDetailCard(distance: key, record: record)
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Records Personnels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .environmentObject(themeManager)
    }
}

struct RecordDetailCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let distance: String
    let record: BestDistanceRecord

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            // Header
            HStack {
                Text(distance.uppercased())
                    .font(.ecH3)
                    .foregroundColor(themeManager.textPrimary)

                Spacer()

                if let date = record.date {
                    Text(formatDate(date))
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                }
            }

            // Main time
            Text(record.formattedTime)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.sportColor(for: .course))

            // Details
            HStack(spacing: ECSpacing.lg) {
                if let pace = record.pace {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Allure")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                        Text("\(pace) /km")
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)
                    }
                }

                if let hr = record.hr {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FC moy")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                        Text("\(Int(hr)) bpm")
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)
                    }
                }

                Spacer()
            }

            // Session name
            if let sessionName = record.sessionName {
                HStack {
                    Image(systemName: "figure.run")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textTertiary)
                    Text(sessionName)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textTertiary)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        formatter.dateFormat = "dd MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

// MARK: - CP/W' Detail View

struct CPWprimeDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let cpWprime: CPWprimeMetric?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    if let data = cpWprime {
                        // Main values
                        HStack(spacing: ECSpacing.xl) {
                            // CP
                            if let cp = data.cp {
                                VStack(spacing: ECSpacing.xs) {
                                    Text("Critical Power")
                                        .font(.ecLabel)
                                        .foregroundColor(themeManager.textSecondary)
                                    Text(String(format: "%.0f", cp.value))
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.sportColor(for: .cyclisme))
                                    Text("Watts")
                                        .font(.ecLabel)
                                        .foregroundColor(themeManager.textSecondary)
                                }
                            }

                            // W'
                            if let wPrime = data.wPrime {
                                VStack(spacing: ECSpacing.xs) {
                                    Text("W' (R\u{00E9}serve)")
                                        .font(.ecLabel)
                                        .foregroundColor(themeManager.textSecondary)
                                    Text(String(format: "%.1f", wPrime.value))
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.warningColor)
                                    Text("kJ")
                                        .font(.ecLabel)
                                        .foregroundColor(themeManager.textSecondary)
                                }
                            }
                        }
                        .padding(.vertical, ECSpacing.xl)

                        // Interpretation Section
                        CPWprimeInterpretationSection(cp: data.cp, wPrime: data.wPrime)

                        // Athlete Position Section
                        CPWprimePositionSection(cp: data.cp, wPrime: data.wPrime)

                        // Fit stats
                        if let fitStats = data.fitStats {
                            FitStatsSection(fitStats: fitStats)
                        }

                        // Predictions
                        if let predictions = data.predictions, !predictions.isEmpty {
                            PredictionsSection(predictions: predictions, cp: data.cp?.value ?? 0)
                        }

                        // How to use section
                        CPWprimeUsageSection()
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("CP / W'")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .environmentObject(themeManager)
    }
}

struct FitStatsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let fitStats: FitStats

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text("Qualit\u{00E9} du mod\u{00E8}le")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            HStack(spacing: ECSpacing.xl) {
                if let r2 = fitStats.r2 {
                    VStack(spacing: 4) {
                        Text("R\u{00B2}")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                        Text(String(format: "%.3f", r2))
                            .font(.ecH4)
                            .foregroundColor(r2 > 0.9 ? themeManager.successColor : themeManager.warningColor)
                    }
                }

                if let rmse = fitStats.rmse {
                    VStack(spacing: 4) {
                        Text("RMSE")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                        Text(String(format: "%.1f W", rmse))
                            .font(.ecH4)
                            .foregroundColor(themeManager.textPrimary)
                    }
                }

                if let n = fitStats.n {
                    VStack(spacing: 4) {
                        Text("Points")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                        Text("\(n)")
                            .font(.ecH4)
                            .foregroundColor(themeManager.textPrimary)
                    }
                }

                Spacer()
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

struct PredictionsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let predictions: [String: DurationPrediction]
    let cp: Double

    var sortedPredictions: [(key: String, duration: Double, power: Double)] {
        predictions.compactMap { key, value -> (String, Double, Double)? in
            guard let duration = value.durationMin else { return nil }
            // Parse key like "102pct_cp" -> 102
            let pctString = key.replacingOccurrences(of: "pct_cp", with: "")
            guard let pct = Double(pctString) else { return nil }
            let power = cp * pct / 100
            return (key, duration, power)
        }
        .sorted { $0.1 > $1.1 } // Sort by duration descending
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text("Pr\u{00E9}dictions de tenue")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            VStack(spacing: ECSpacing.sm) {
                ForEach(sortedPredictions, id: \.key) { item in
                    HStack {
                        Text("\(Int(item.2)) W")
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.sportColor(for: .cyclisme))
                            .frame(width: 70, alignment: .leading)

                        Text(formatDuration(item.1))
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textPrimary)

                        Spacer()

                        let pct = item.key.replacingOccurrences(of: "pct_cp", with: "")
                        Text("\(pct)% CP")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textTertiary)
                    }
                    .padding(ECSpacing.sm)
                    .background(themeManager.surfaceColor)
                    .cornerRadius(ECRadius.md)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }

    private func formatDuration(_ minutes: Double) -> String {
        if minutes >= 60 {
            let hours = Int(minutes / 60)
            let mins = Int(minutes.truncatingRemainder(dividingBy: 60))
            return "\(hours)h\(String(format: "%02d", mins))"
        } else {
            let mins = Int(minutes)
            let secs = Int((minutes - Double(mins)) * 60)
            return "\(mins):\(String(format: "%02d", secs))"
        }
    }
}

// MARK: - CS/D' Detail View (Running)

struct CSDprimeDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let csDprime: CSDprimeMetric?
    let csZones: CSZones?
    let csZonesPace: CSZonesPace?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    if let data = csDprime {
                        // Main values
                        HStack(spacing: ECSpacing.xl) {
                            // CS
                            if let cs = data.cs {
                                VStack(spacing: ECSpacing.xs) {
                                    Text("Critical Speed")
                                        .font(.ecLabel)
                                        .foregroundColor(themeManager.textSecondary)
                                    Text(cs.paceMinKm)
                                        .font(.system(size: 40, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.sportColor(for: .course))
                                    Text("/km")
                                        .font(.ecLabel)
                                        .foregroundColor(themeManager.textSecondary)
                                    Text(String(format: "%.1f km/h", cs.valueKmh))
                                        .font(.ecSmall)
                                        .foregroundColor(themeManager.textTertiary)
                                }
                            }

                            // D'
                            if let dPrime = data.dPrime {
                                VStack(spacing: ECSpacing.xs) {
                                    Text("D' (Réserve)")
                                        .font(.ecLabel)
                                        .foregroundColor(themeManager.textSecondary)
                                    Text(String(format: "%.0f", dPrime.value))
                                        .font(.system(size: 40, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.warningColor)
                                    Text("mètres")
                                        .font(.ecLabel)
                                        .foregroundColor(themeManager.textSecondary)
                                }
                            }
                        }
                        .padding(.vertical, ECSpacing.xl)

                        // Interpretation Section
                        CSDprimeInterpretationSection(cs: data.cs, dPrime: data.dPrime)

                        // Athlete Position Section
                        CSDprimePositionSection(cs: data.cs, dPrime: data.dPrime)

                        // Fit stats
                        if let fitStats = data.fitStats {
                            CSFitStatsSection(fitStats: fitStats)
                        }

                        // CS Zones
                        if let zones = csZones, let zonesPace = csZonesPace {
                            CSZonesSection(csZones: zones, csZonesPace: zonesPace)
                        }

                        // Predictions
                        if let predictions = data.predictions, !predictions.isEmpty, let cs = data.cs {
                            CSPredictionsSection(predictions: predictions, cs: cs.value)
                        }

                        // How to use section
                        CSDprimeUsageSection()
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("CS / D'")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .environmentObject(themeManager)
    }
}

// MARK: - CS/D' Interpretation Section

struct CSDprimeInterpretationSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let cs: CSValue?
    let dPrime: DPrimeValue?

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(themeManager.warningColor)
                Text("Comment interpréter")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.md) {
                // CS Interpretation
                InterpretationRow(
                    icon: "speedometer",
                    title: "Critical Speed (CS)",
                    description: "L'allure maximale que vous pouvez maintenir sur une durée prolongée (30-60 min). C'est votre \"seuil\" en course à pied.",
                    color: themeManager.sportColor(for: .course)
                )

                // D' Interpretation
                InterpretationRow(
                    icon: "battery.100",
                    title: "D' (D Prime)",
                    description: "Votre réserve anaérobie exprimée en mètres. C'est la distance totale que vous pouvez parcourir au-dessus de votre CS avant épuisement.",
                    color: themeManager.warningColor
                )

                Divider()
                    .padding(.vertical, ECSpacing.xs)

                // Practical interpretation
                if let cs = cs, let dPrime = dPrime {
                    VStack(alignment: .leading, spacing: ECSpacing.sm) {
                        Text("En pratique")
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)

                        let csKmh = cs.valueKmh
                        let dPrimeM = dPrime.value

                        // Example at 105% CS
                        let speed105 = csKmh * 1.05
                        let excessSpeed = (speed105 - csKmh) / 3.6 // m/s
                        let time105 = excessSpeed > 0 ? dPrimeM / excessSpeed / 60 : 0

                        Text("À 105% de votre CS (\(String(format: "%.1f", speed105)) km/h), vous pouvez tenir environ \(String(format: "%.0f", time105)) minutes avant d'épuiser votre D'.")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)

                        // Example at 110% CS
                        let speed110 = csKmh * 1.10
                        let excessSpeed110 = (speed110 - csKmh) / 3.6
                        let time110 = excessSpeed110 > 0 ? dPrimeM / excessSpeed110 / 60 : 0

                        Text("À 110% de votre CS (\(String(format: "%.1f", speed110)) km/h), cette durée tombe à environ \(String(format: "%.0f", time110)) minutes.")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - CS/D' Athlete Position Section

struct CSDprimePositionSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let cs: CSValue?
    let dPrime: DPrimeValue?

    // Reference values for CS (in m/s) based on running level
    // Sources: Scientific literature on Critical Speed
    private let csReferences: [(level: String, minMs: Double, maxMs: Double, description: String)] = [
        ("Débutant", 2.5, 3.2, "Joggeurs occasionnels"),
        ("Intermédiaire", 3.2, 3.8, "Coureurs réguliers"),
        ("Avancé", 3.8, 4.3, "Coureurs compétitifs"),
        ("Elite", 4.3, 5.0, "Coureurs de haut niveau"),
        ("Pro", 5.0, 6.5, "Athlètes professionnels")
    ]

    // Reference values for D' (in meters) based on running profile
    private let dPrimeReferences: [(level: String, minM: Double, maxM: Double, description: String)] = [
        ("Endurant", 100, 180, "Profil longue distance"),
        ("Équilibré", 180, 280, "Polyvalent"),
        ("Puissant", 280, 400, "Profil vitesse/demi-fond"),
        ("Explosif", 400, 600, "Profil sprint/800m")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(themeManager.accentColor)
                Text("Votre positionnement")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.lg) {
                // CS Position
                if let cs = cs {
                    CSPositionGauge(
                        title: "Critical Speed",
                        value: cs.value,
                        valueFormatted: "\(cs.paceMinKm) /km",
                        references: csReferences,
                        color: themeManager.sportColor(for: .course)
                    )
                }

                // D' Position
                if let dPrime = dPrime {
                    DPrimePositionGauge(
                        title: "D' (Réserve anaérobie)",
                        value: dPrime.value,
                        valueFormatted: "\(Int(dPrime.value)) m",
                        references: dPrimeReferences,
                        color: themeManager.warningColor
                    )
                }

                // Profile Analysis
                if let cs = cs, let dPrime = dPrime {
                    AthleteProfileAnalysis(cs: cs, dPrime: dPrime)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

struct CSPositionGauge: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let value: Double // in m/s
    let valueFormatted: String
    let references: [(level: String, minMs: Double, maxMs: Double, description: String)]
    let color: Color

    private var currentLevel: (level: String, description: String)? {
        for ref in references {
            if value >= ref.minMs && value < ref.maxMs {
                return (ref.level, ref.description)
            }
        }
        if value >= references.last?.minMs ?? 0 {
            return (references.last?.level ?? "", references.last?.description ?? "")
        }
        return (references.first?.level ?? "", references.first?.description ?? "")
    }

    private var positionPercent: Double {
        let minVal = references.first?.minMs ?? 2.5
        let maxVal = references.last?.maxMs ?? 6.5
        return min(1.0, max(0.0, (value - minVal) / (maxVal - minVal)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            HStack {
                Text(title)
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)
                Spacer()
                Text(valueFormatted)
                    .font(.ecLabelBold)
                    .foregroundColor(color)
            }

            // Gauge bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.red.opacity(0.3),
                            Color.orange.opacity(0.3),
                            Color.yellow.opacity(0.3),
                            Color.green.opacity(0.3),
                            Color.blue.opacity(0.3)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 12)
                    .cornerRadius(6)

                    // Position indicator
                    Circle()
                        .fill(color)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: color.opacity(0.5), radius: 4)
                        .offset(x: (geometry.size.width - 20) * positionPercent)
                }
            }
            .frame(height: 20)

            // Level labels
            HStack {
                ForEach(references.indices, id: \.self) { index in
                    Text(references[index].level)
                        .font(.system(size: 9))
                        .foregroundColor(themeManager.textTertiary)
                    if index < references.count - 1 {
                        Spacer()
                    }
                }
            }

            // Current level badge
            if let level = currentLevel {
                HStack(spacing: ECSpacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(color)
                    Text("Niveau: \(level.level)")
                        .font(.ecSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textPrimary)
                    Text("(\(level.description))")
                        .font(.system(size: 11))
                        .foregroundColor(themeManager.textSecondary)
                }
                .padding(.top, ECSpacing.xs)
            }
        }
    }
}

struct DPrimePositionGauge: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let value: Double // in meters
    let valueFormatted: String
    let references: [(level: String, minM: Double, maxM: Double, description: String)]
    let color: Color

    private var currentProfile: (level: String, description: String)? {
        for ref in references {
            if value >= ref.minM && value < ref.maxM {
                return (ref.level, ref.description)
            }
        }
        if value >= references.last?.minM ?? 0 {
            return (references.last?.level ?? "", references.last?.description ?? "")
        }
        return (references.first?.level ?? "", references.first?.description ?? "")
    }

    private var positionPercent: Double {
        let minVal = references.first?.minM ?? 100
        let maxVal = references.last?.maxM ?? 600
        return min(1.0, max(0.0, (value - minVal) / (maxVal - minVal)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            HStack {
                Text(title)
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)
                Spacer()
                Text(valueFormatted)
                    .font(.ecLabelBold)
                    .foregroundColor(color)
            }

            // Gauge bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background gradient (different colors for D' - endurance to power)
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.green.opacity(0.3),
                            Color.orange.opacity(0.3),
                            Color.red.opacity(0.3)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 12)
                    .cornerRadius(6)

                    // Position indicator
                    Circle()
                        .fill(color)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: color.opacity(0.5), radius: 4)
                        .offset(x: (geometry.size.width - 20) * positionPercent)
                }
            }
            .frame(height: 20)

            // Profile labels
            HStack {
                ForEach(references.indices, id: \.self) { index in
                    Text(references[index].level)
                        .font(.system(size: 9))
                        .foregroundColor(themeManager.textTertiary)
                    if index < references.count - 1 {
                        Spacer()
                    }
                }
            }

            // Current profile badge
            if let profile = currentProfile {
                HStack(spacing: ECSpacing.xs) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                        .foregroundColor(color)
                    Text("Profil: \(profile.level)")
                        .font(.ecSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textPrimary)
                    Text("(\(profile.description))")
                        .font(.system(size: 11))
                        .foregroundColor(themeManager.textSecondary)
                }
                .padding(.top, ECSpacing.xs)
            }
        }
    }
}

struct AthleteProfileAnalysis: View {
    @EnvironmentObject var themeManager: ThemeManager
    let cs: CSValue
    let dPrime: DPrimeValue

    // Ratio D'/CS helps determine the athlete's profile
    // Higher ratio = more anaerobic power relative to aerobic base
    private var dPrimeCSRatio: Double {
        guard cs.value > 0 else { return 0 }
        return dPrime.value / (cs.value * 60) // D' in meters per minute of CS
    }

    private var profileAnalysis: (title: String, description: String, icon: String, recommendation: String) {
        let csKmh = cs.valueKmh
        let dPrimeM = dPrime.value

        // Profile based on combination of CS and D'
        if csKmh >= 15 && dPrimeM >= 280 {
            return (
                "Complet",
                "Excellente base aérobie combinée à une forte capacité anaérobie. Profil polyvalent adapté du 5K au semi.",
                "star.circle.fill",
                "Variez les formats de course pour exploiter votre polyvalence."
            )
        } else if csKmh >= 15 && dPrimeM < 280 {
            return (
                "Endurant pur",
                "Excellente capacité aérobie avec un D' modéré. Profil idéal pour les longues distances (semi/marathon).",
                "figure.run.circle.fill",
                "Travaillez les intervalles courts pour développer votre D'."
            )
        } else if csKmh < 15 && dPrimeM >= 280 {
            return (
                "Puissance brute",
                "Fort potentiel anaérobie avec une base aérobie à développer. Bon pour le demi-fond court.",
                "bolt.circle.fill",
                "Augmentez le volume d'entraînement au seuil pour améliorer votre CS."
            )
        } else if csKmh >= 13 && dPrimeM >= 180 {
            return (
                "Bon équilibre",
                "Bonne base générale avec un équilibre CS/D' intéressant. Potentiel de progression sur tous les formats.",
                "chart.bar.fill",
                "Continuez à travailler les deux composantes en parallèle."
            )
        } else {
            return (
                "En développement",
                "Votre profil est encore en construction. Concentrez-vous sur le développement de votre base aérobie.",
                "arrow.up.circle.fill",
                "Priorité au volume d'entraînement facile et au travail au seuil."
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Divider()
                .padding(.vertical, ECSpacing.xs)

            HStack(spacing: ECSpacing.sm) {
                Image(systemName: profileAnalysis.icon)
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Votre profil : \(profileAnalysis.title)")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                    Text(profileAnalysis.description)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Recommendation
            HStack(alignment: .top, spacing: ECSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.warningColor)
                Text(profileAnalysis.recommendation)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textSecondary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(ECSpacing.sm)
            .background(themeManager.warningColor.opacity(0.1))
            .cornerRadius(ECRadius.sm)
        }
    }
}

struct InterpretationRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: ECSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Text(description)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - CS/D' Usage Section

struct CSDprimeUsageSection: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "figure.run")
                    .foregroundColor(themeManager.sportColor(for: .course))
                Text("Comment utiliser ces données")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.md) {
                UsageTipRow(
                    number: "1",
                    title: "Planifier vos courses",
                    description: "La CS correspond à votre allure semi-marathon/marathon selon votre niveau. Utilisez-la comme référence pour vos objectifs de course."
                )

                UsageTipRow(
                    number: "2",
                    title: "Gérer vos intervalles",
                    description: "Le D' vous indique combien de \"réserve\" vous avez pour les accélérations. Un D' élevé permet des sprints plus longs au-dessus du seuil."
                )

                UsageTipRow(
                    number: "3",
                    title: "Stratégie de course",
                    description: "En compétition, surveillez votre D'. Si vous partez trop vite (>CS), vous consommez votre D' rapidement. Gardez-en pour le final !"
                )

                UsageTipRow(
                    number: "4",
                    title: "Entraînement ciblé",
                    description: "Pour améliorer votre CS : travail au seuil, tempo runs. Pour améliorer votre D' : intervalles courts et intenses, côtes."
                )
            }

            // Formula reminder
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Formule")
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textTertiary)
                Text("Temps de tenue = D' ÷ (Vitesse - CS)")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(themeManager.accentColor)
            }
            .padding(ECSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.accentColor.opacity(0.1))
            .cornerRadius(ECRadius.sm)
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

struct UsageTipRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let number: String
    let title: String
    let description: String
    var sportColor: Color?

    var body: some View {
        HStack(alignment: .top, spacing: ECSpacing.sm) {
            Text(number)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(sportColor ?? themeManager.sportColor(for: .course))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Text(description)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - CP/W' Interpretation Section (Cycling)

struct CPWprimeInterpretationSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let cp: CPValue?
    let wPrime: WPrimeValue?

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(themeManager.warningColor)
                Text("Comment interpréter")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.md) {
                // CP Interpretation
                InterpretationRow(
                    icon: "bolt.fill",
                    title: "Critical Power (CP)",
                    description: "La puissance maximale que vous pouvez maintenir sur une durée prolongée (45-60 min). C'est votre \"seuil fonctionnel\" en cyclisme.",
                    color: themeManager.sportColor(for: .cyclisme)
                )

                // W' Interpretation
                InterpretationRow(
                    icon: "battery.100",
                    title: "W' (W Prime)",
                    description: "Votre réserve anaérobie exprimée en kilojoules. C'est l'énergie totale disponible au-dessus de votre CP avant épuisement.",
                    color: themeManager.warningColor
                )

                Divider()
                    .padding(.vertical, ECSpacing.xs)

                // Practical interpretation
                if let cp = cp, let wPrime = wPrime {
                    VStack(alignment: .leading, spacing: ECSpacing.sm) {
                        Text("En pratique")
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)

                        let cpWatts = cp.value
                        let wPrimeKJ = wPrime.value * 1000 // Convert kJ to J for calculation

                        // Example at 110% CP
                        let power110 = cpWatts * 1.10
                        let excessPower = power110 - cpWatts
                        let time110 = excessPower > 0 ? wPrimeKJ / excessPower / 60 : 0

                        Text("À 110% de votre CP (\(String(format: "%.0f", power110)) W), vous pouvez tenir environ \(String(format: "%.0f", time110)) minutes avant d'épuiser votre W'.")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)

                        // Example at 120% CP
                        let power120 = cpWatts * 1.20
                        let excessPower120 = power120 - cpWatts
                        let time120 = excessPower120 > 0 ? wPrimeKJ / excessPower120 / 60 : 0

                        Text("À 120% de votre CP (\(String(format: "%.0f", power120)) W), cette durée tombe à environ \(String(format: "%.0f", time120)) minutes.")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - CP/W' Position Section (Cycling)

struct CPWprimePositionSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let cp: CPValue?
    let wPrime: WPrimeValue?

    // Reference values for CP (in Watts) based on cycling level
    // Note: These are absolute values, W/kg would be more accurate but requires weight
    private let cpReferences: [(level: String, minW: Double, maxW: Double, description: String)] = [
        ("Débutant", 100, 180, "Cyclistes occasionnels"),
        ("Intermédiaire", 180, 250, "Cyclistes réguliers"),
        ("Avancé", 250, 320, "Cyclistes entraînés"),
        ("Elite", 320, 400, "Compétiteurs régionaux"),
        ("Pro", 400, 550, "Niveau professionnel")
    ]

    // Reference values for W' (in kJ) based on cycling profile
    private let wPrimeReferences: [(level: String, minKJ: Double, maxKJ: Double, description: String)] = [
        ("Endurant", 10, 18, "Profil longue distance"),
        ("Équilibré", 18, 25, "Polyvalent"),
        ("Puissant", 25, 35, "Profil puncheur"),
        ("Explosif", 35, 50, "Profil sprinteur")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(themeManager.accentColor)
                Text("Votre positionnement")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.lg) {
                // CP Position
                if let cp = cp {
                    CPPositionGauge(
                        title: "Critical Power",
                        value: cp.value,
                        valueFormatted: "\(Int(cp.value)) W",
                        references: cpReferences,
                        color: themeManager.sportColor(for: .cyclisme)
                    )
                }

                // W' Position
                if let wPrime = wPrime {
                    WPrimePositionGauge(
                        title: "W' (Réserve anaérobie)",
                        value: wPrime.value,
                        valueFormatted: String(format: "%.1f kJ", wPrime.value),
                        references: wPrimeReferences,
                        color: themeManager.warningColor
                    )
                }

                // Profile Analysis
                if let cp = cp, let wPrime = wPrime {
                    CyclingProfileAnalysis(cp: cp, wPrime: wPrime)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

struct CPPositionGauge: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let value: Double // in Watts
    let valueFormatted: String
    let references: [(level: String, minW: Double, maxW: Double, description: String)]
    let color: Color

    private var currentLevel: (level: String, description: String)? {
        for ref in references {
            if value >= ref.minW && value < ref.maxW {
                return (ref.level, ref.description)
            }
        }
        if value >= references.last?.minW ?? 0 {
            return (references.last?.level ?? "", references.last?.description ?? "")
        }
        return (references.first?.level ?? "", references.first?.description ?? "")
    }

    private var positionPercent: Double {
        let minVal = references.first?.minW ?? 100
        let maxVal = references.last?.maxW ?? 550
        return min(1.0, max(0.0, (value - minVal) / (maxVal - minVal)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            HStack {
                Text(title)
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)
                Spacer()
                Text(valueFormatted)
                    .font(.ecLabelBold)
                    .foregroundColor(color)
            }

            // Gauge bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.red.opacity(0.3),
                            Color.orange.opacity(0.3),
                            Color.yellow.opacity(0.3),
                            Color.green.opacity(0.3),
                            Color.blue.opacity(0.3)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 12)
                    .cornerRadius(6)

                    Circle()
                        .fill(color)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(color: color.opacity(0.5), radius: 4)
                        .offset(x: (geometry.size.width - 20) * positionPercent)
                }
            }
            .frame(height: 20)

            HStack {
                ForEach(references.indices, id: \.self) { index in
                    Text(references[index].level)
                        .font(.system(size: 9))
                        .foregroundColor(themeManager.textTertiary)
                    if index < references.count - 1 { Spacer() }
                }
            }

            if let level = currentLevel {
                HStack(spacing: ECSpacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(color)
                    Text("Niveau: \(level.level)")
                        .font(.ecSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textPrimary)
                    Text("(\(level.description))")
                        .font(.system(size: 11))
                        .foregroundColor(themeManager.textSecondary)
                }
                .padding(.top, ECSpacing.xs)
            }
        }
    }
}

struct WPrimePositionGauge: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let value: Double // in kJ
    let valueFormatted: String
    let references: [(level: String, minKJ: Double, maxKJ: Double, description: String)]
    let color: Color

    private var currentProfile: (level: String, description: String)? {
        for ref in references {
            if value >= ref.minKJ && value < ref.maxKJ {
                return (ref.level, ref.description)
            }
        }
        if value >= references.last?.minKJ ?? 0 {
            return (references.last?.level ?? "", references.last?.description ?? "")
        }
        return (references.first?.level ?? "", references.first?.description ?? "")
    }

    private var positionPercent: Double {
        let minVal = references.first?.minKJ ?? 10
        let maxVal = references.last?.maxKJ ?? 50
        return min(1.0, max(0.0, (value - minVal) / (maxVal - minVal)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            HStack {
                Text(title)
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textSecondary)
                Spacer()
                Text(valueFormatted)
                    .font(.ecLabelBold)
                    .foregroundColor(color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.green.opacity(0.3),
                            Color.orange.opacity(0.3),
                            Color.red.opacity(0.3)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 12)
                    .cornerRadius(6)

                    Circle()
                        .fill(color)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(color: color.opacity(0.5), radius: 4)
                        .offset(x: (geometry.size.width - 20) * positionPercent)
                }
            }
            .frame(height: 20)

            HStack {
                ForEach(references.indices, id: \.self) { index in
                    Text(references[index].level)
                        .font(.system(size: 9))
                        .foregroundColor(themeManager.textTertiary)
                    if index < references.count - 1 { Spacer() }
                }
            }

            if let profile = currentProfile {
                HStack(spacing: ECSpacing.xs) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                        .foregroundColor(color)
                    Text("Profil: \(profile.level)")
                        .font(.ecSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textPrimary)
                    Text("(\(profile.description))")
                        .font(.system(size: 11))
                        .foregroundColor(themeManager.textSecondary)
                }
                .padding(.top, ECSpacing.xs)
            }
        }
    }
}

struct CyclingProfileAnalysis: View {
    @EnvironmentObject var themeManager: ThemeManager
    let cp: CPValue
    let wPrime: WPrimeValue

    private var profileAnalysis: (title: String, description: String, icon: String, recommendation: String) {
        let cpW = cp.value
        let wPrimeKJ = wPrime.value

        if cpW >= 300 && wPrimeKJ >= 25 {
            return (
                "Complet",
                "Excellente puissance de seuil combinée à une forte capacité anaérobie. Profil polyvalent pour CLM, grimpeur-puncheur.",
                "star.circle.fill",
                "Variez les terrains pour exploiter votre polyvalence."
            )
        } else if cpW >= 300 && wPrimeKJ < 25 {
            return (
                "Rouleur/Grimpeur",
                "Excellente puissance de seuil avec un W' modéré. Idéal pour les efforts prolongés : CLM, cols.",
                "figure.outdoor.cycle",
                "Travaillez les sprints et efforts courts pour développer votre W'."
            )
        } else if cpW < 300 && wPrimeKJ >= 25 {
            return (
                "Puncheur/Sprinteur",
                "Fort potentiel anaérobie avec une base aérobie à développer. Bon pour les critériums et arrivées massives.",
                "bolt.circle.fill",
                "Augmentez le volume d'entraînement au sweet spot pour améliorer votre CP."
            )
        } else if cpW >= 220 && wPrimeKJ >= 18 {
            return (
                "Bon équilibre",
                "Bonne base générale avec un équilibre CP/W' intéressant. Potentiel de progression sur tous les formats.",
                "chart.bar.fill",
                "Continuez à travailler les deux composantes en parallèle."
            )
        } else {
            return (
                "En développement",
                "Votre profil est encore en construction. Concentrez-vous sur le développement de votre base aérobie.",
                "arrow.up.circle.fill",
                "Priorité au volume d'entraînement et au travail au sweet spot (88-94% FTP)."
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Divider()
                .padding(.vertical, ECSpacing.xs)

            HStack(spacing: ECSpacing.sm) {
                Image(systemName: profileAnalysis.icon)
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Votre profil : \(profileAnalysis.title)")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                    Text(profileAnalysis.description)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(alignment: .top, spacing: ECSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.warningColor)
                Text(profileAnalysis.recommendation)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textSecondary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(ECSpacing.sm)
            .background(themeManager.warningColor.opacity(0.1))
            .cornerRadius(ECRadius.sm)
        }
    }
}

// MARK: - CP/W' Usage Section (Cycling)

struct CPWprimeUsageSection: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "figure.outdoor.cycle")
                    .foregroundColor(themeManager.sportColor(for: .cyclisme))
                Text("Comment utiliser ces données")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.md) {
                UsageTipRow(
                    number: "1",
                    title: "Gestion de l'effort",
                    description: "Le CP est votre limite pour les efforts soutenus. Au-dessus, vous puisez dans votre W' limité.",
                    sportColor: themeManager.sportColor(for: .cyclisme)
                )

                UsageTipRow(
                    number: "2",
                    title: "Stratégie en course",
                    description: "Surveillez votre W' dans les bosses. Une fois épuisé, vous ne pourrez plus suivre les attaques.",
                    sportColor: themeManager.sportColor(for: .cyclisme)
                )

                UsageTipRow(
                    number: "3",
                    title: "Récupération du W'",
                    description: "Sous votre CP, votre W' se recharge. Plus vous êtes en dessous, plus vite il se recharge.",
                    sportColor: themeManager.sportColor(for: .cyclisme)
                )

                UsageTipRow(
                    number: "4",
                    title: "Entraînement ciblé",
                    description: "Pour améliorer votre CP : sweet spot, tempo. Pour améliorer votre W' : intervalles VO2max, sprints.",
                    sportColor: themeManager.sportColor(for: .cyclisme)
                )
            }

            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Formule")
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textTertiary)
                Text("Temps de tenue = W' ÷ (Puissance - CP)")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(themeManager.accentColor)
            }
            .padding(ECSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.accentColor.opacity(0.1))
            .cornerRadius(ECRadius.sm)
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - CSS Interpretation Section (Swimming)

struct CSSInterpretationSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let css: CSSMetric

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(themeManager.warningColor)
                Text("Comment interpréter")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.md) {
                InterpretationRow(
                    icon: "figure.pool.swim",
                    title: "Critical Swim Speed (CSS)",
                    description: "L'allure de nage maximale que vous pouvez maintenir sur une longue durée sans accumulation de lactate. C'est votre \"seuil\" en natation.",
                    color: themeManager.sportColor(for: .natation)
                )

                Divider()
                    .padding(.vertical, ECSpacing.xs)

                VStack(alignment: .leading, spacing: ECSpacing.sm) {
                    Text("En pratique")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)

                    // CSS in seconds per 100m
                    let cssPer100m = css.value

                    // 400m prediction
                    let time400 = cssPer100m * 4
                    let min400 = Int(time400) / 60
                    let sec400 = Int(time400) % 60

                    Text("Votre allure CSS de \(css.formattedValue) correspond à un 400m en environ \(min400):\(String(format: "%02d", sec400)).")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)

                    // 1500m prediction
                    let time1500 = cssPer100m * 15
                    let min1500 = Int(time1500) / 60
                    let sec1500 = Int(time1500) % 60

                    Text("Pour un 1500m, visez environ \(min1500):\(String(format: "%02d", sec1500)) en maintenant votre CSS.")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - CSS Position Section (Swimming)

struct CSSPositionSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let css: CSSMetric

    // Reference values for CSS (in seconds per 100m)
    // Lower is faster/better
    private let cssReferences: [(level: String, maxSec: Double, minSec: Double, description: String)] = [
        ("Débutant", 180, 130, "Nageurs occasionnels"),
        ("Intermédiaire", 130, 105, "Nageurs réguliers"),
        ("Avancé", 105, 85, "Nageurs entraînés"),
        ("Elite", 85, 70, "Compétiteurs"),
        ("Pro", 70, 55, "Niveau international")
    ]

    private var currentLevel: (level: String, description: String)? {
        let value = css.value
        for ref in cssReferences {
            if value <= ref.maxSec && value > ref.minSec {
                return (ref.level, ref.description)
            }
        }
        if value <= cssReferences.last?.minSec ?? 55 {
            return (cssReferences.last?.level ?? "", cssReferences.last?.description ?? "")
        }
        return (cssReferences.first?.level ?? "", cssReferences.first?.description ?? "")
    }

    // For CSS, lower is better, so we invert the position
    private var positionPercent: Double {
        let maxVal = cssReferences.first?.maxSec ?? 180
        let minVal = cssReferences.last?.minSec ?? 55
        return min(1.0, max(0.0, (maxVal - css.value) / (maxVal - minVal)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(themeManager.accentColor)
                Text("Votre positionnement")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.lg) {
                // CSS Position
                VStack(alignment: .leading, spacing: ECSpacing.sm) {
                    HStack {
                        Text("Critical Swim Speed")
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textSecondary)
                        Spacer()
                        Text(css.formattedValue)
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.sportColor(for: .natation))
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(0.3),
                                    Color.orange.opacity(0.3),
                                    Color.yellow.opacity(0.3),
                                    Color.green.opacity(0.3),
                                    Color.blue.opacity(0.3)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(height: 12)
                            .cornerRadius(6)

                            Circle()
                                .fill(themeManager.sportColor(for: .natation))
                                .frame(width: 20, height: 20)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(color: themeManager.sportColor(for: .natation).opacity(0.5), radius: 4)
                                .offset(x: (geometry.size.width - 20) * positionPercent)
                        }
                    }
                    .frame(height: 20)

                    HStack {
                        ForEach(cssReferences.indices, id: \.self) { index in
                            Text(cssReferences[index].level)
                                .font(.system(size: 9))
                                .foregroundColor(themeManager.textTertiary)
                            if index < cssReferences.count - 1 { Spacer() }
                        }
                    }

                    if let level = currentLevel {
                        HStack(spacing: ECSpacing.xs) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(themeManager.sportColor(for: .natation))
                            Text("Niveau: \(level.level)")
                                .font(.ecSmall)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.textPrimary)
                            Text("(\(level.description))")
                                .font(.system(size: 11))
                                .foregroundColor(themeManager.textSecondary)
                        }
                        .padding(.top, ECSpacing.xs)
                    }
                }

                // Swimming Profile Analysis
                SwimmingProfileAnalysis(css: css)
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

struct SwimmingProfileAnalysis: View {
    @EnvironmentObject var themeManager: ThemeManager
    let css: CSSMetric

    private var profileAnalysis: (title: String, description: String, icon: String, recommendation: String) {
        let cssPer100m = css.value
        let confidence = css.confidence

        if cssPer100m <= 85 && confidence >= 0.7 {
            return (
                "Nageur confirmé",
                "Excellente allure de seuil. Vous avez une technique efficace et une bonne condition aérobie en natation.",
                "star.circle.fill",
                "Travaillez les allures spécifiques et la technique de virage pour optimiser vos chronos."
            )
        } else if cssPer100m <= 105 && confidence >= 0.6 {
            return (
                "Bon niveau",
                "Bonne base en natation. Votre CSS permet des séances de qualité sur des distances moyennes.",
                "figure.pool.swim",
                "Variez les intensités : endurance longue + séries au seuil pour progresser."
            )
        } else if cssPer100m <= 130 {
            return (
                "En progression",
                "Niveau intermédiaire avec du potentiel. La technique est probablement votre principal levier d'amélioration.",
                "arrow.up.circle.fill",
                "Concentrez-vous sur la technique (position, respiration, amplitude) avant l'intensité."
            )
        } else {
            return (
                "En développement",
                "Votre CSS est encore en construction. Priorité à la régularité et à l'apprentissage technique.",
                "chart.bar.fill",
                "Nagez régulièrement en endurance fondamentale. Travaillez les éducatifs techniques."
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Divider()
                .padding(.vertical, ECSpacing.xs)

            HStack(spacing: ECSpacing.sm) {
                Image(systemName: profileAnalysis.icon)
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Votre profil : \(profileAnalysis.title)")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                    Text(profileAnalysis.description)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(alignment: .top, spacing: ECSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.warningColor)
                Text(profileAnalysis.recommendation)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textSecondary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(ECSpacing.sm)
            .background(themeManager.warningColor.opacity(0.1))
            .cornerRadius(ECRadius.sm)
        }
    }
}

// MARK: - CSS Usage Section (Swimming)

struct CSSUsageSection: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Image(systemName: "figure.pool.swim")
                    .foregroundColor(themeManager.sportColor(for: .natation))
                Text("Comment utiliser ces données")
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
            }

            VStack(alignment: .leading, spacing: ECSpacing.md) {
                UsageTipRow(
                    number: "1",
                    title: "Séries au seuil",
                    description: "Nagez des séries de 100-400m à votre allure CSS avec des récupérations courtes (10-20s).",
                    sportColor: themeManager.sportColor(for: .natation)
                )

                UsageTipRow(
                    number: "2",
                    title: "Zones d'entraînement",
                    description: "CSS-5s pour le travail lactique, CSS+5s pour l'endurance au seuil, CSS+15s pour l'aérobie.",
                    sportColor: themeManager.sportColor(for: .natation)
                )

                UsageTipRow(
                    number: "3",
                    title: "Test de progression",
                    description: "Refaites le test CSS régulièrement (toutes les 4-6 semaines) pour suivre votre progression.",
                    sportColor: themeManager.sportColor(for: .natation)
                )

                UsageTipRow(
                    number: "4",
                    title: "Stratégie de course",
                    description: "En triathlon, visez CSS+5-10s sur le swim pour garder de l'énergie pour le vélo.",
                    sportColor: themeManager.sportColor(for: .natation)
                )
            }

            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                Text("Rappel")
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textTertiary)
                Text("CSS = Allure max maintenue sans accumulation de fatigue")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(themeManager.accentColor)
            }
            .padding(ECSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.accentColor.opacity(0.1))
            .cornerRadius(ECRadius.sm)
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

struct CSFitStatsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let fitStats: FitStats

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text("Qualité du modèle")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            HStack(spacing: ECSpacing.xl) {
                if let r2 = fitStats.r2 {
                    VStack(spacing: 4) {
                        Text("R²")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                        Text(String(format: "%.3f", r2))
                            .font(.ecH4)
                            .foregroundColor(r2 > 0.85 ? themeManager.successColor : themeManager.warningColor)
                    }
                }

                if let rmse = fitStats.rmse {
                    VStack(spacing: 4) {
                        Text("RMSE")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                        Text(String(format: "%.2f m/s", rmse))
                            .font(.ecH4)
                            .foregroundColor(themeManager.textPrimary)
                    }
                }

                Spacer()
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

struct CSZonesSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let csZones: CSZones
    let csZonesPace: CSZonesPace

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text("Zones d'entraînement")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            VStack(spacing: ECSpacing.sm) {
                let speedZones = csZones.zonesArray
                let paceZones = csZonesPace.zonesArray

                ForEach(Array(speedZones.enumerated()), id: \.offset) { index, zone in
                    HStack(spacing: ECSpacing.sm) {
                        // Zone badge
                        Text(zone.name)
                            .font(.ecCaptionBold)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(themeManager.zoneColor(for: index + 1))
                            .cornerRadius(ECRadius.sm)

                        // Speed range
                        Text("\(zone.range) km/h")
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Pace range
                        if index < paceZones.count {
                            Text(paceZones[index].range)
                                .font(.ecSmall)
                                .foregroundColor(themeManager.textSecondary)
                        }
                    }
                    .padding(ECSpacing.sm)
                    .background(themeManager.surfaceColor)
                    .cornerRadius(ECRadius.md)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

struct CSPredictionsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let predictions: [String: DurationPrediction]
    let cs: Double // en m/s

    var sortedPredictions: [(key: String, duration: Double, speed: Double, pace: String)] {
        predictions.compactMap { key, value -> (String, Double, Double, String)? in
            guard let duration = value.durationMin else { return nil }
            // Parse key like "102pct_cs" -> 102
            let pctString = key.replacingOccurrences(of: "pct_cs", with: "")
            guard let pct = Double(pctString) else { return nil }
            let speed = cs * pct / 100 * 3.6 // Convert to km/h
            // Calculate pace
            let minPerKm = 60 / speed
            let minutes = Int(minPerKm)
            let seconds = Int((minPerKm - Double(minutes)) * 60)
            let pace = String(format: "%d:%02d", minutes, seconds)
            return (key, duration, speed, pace)
        }
        .sorted { $0.1 > $1.1 } // Sort by duration descending
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text("Prédictions de tenue")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            VStack(spacing: ECSpacing.sm) {
                ForEach(sortedPredictions, id: \.key) { item in
                    HStack {
                        Text("\(item.pace) /km")
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.sportColor(for: .course))
                            .frame(width: 80, alignment: .leading)

                        Text(formatDuration(item.1))
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textPrimary)

                        Spacer()

                        let pct = item.key.replacingOccurrences(of: "pct_cs", with: "")
                        Text("\(pct)% CS")
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textTertiary)
                    }
                    .padding(ECSpacing.sm)
                    .background(themeManager.surfaceColor)
                    .cornerRadius(ECRadius.md)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }

    private func formatDuration(_ minutes: Double) -> String {
        if minutes >= 60 {
            let hours = Int(minutes / 60)
            let mins = Int(minutes.truncatingRemainder(dividingBy: 60))
            return "\(hours)h\(String(format: "%02d", mins))"
        } else {
            let mins = Int(minutes)
            let secs = Int((minutes - Double(mins)) * 60)
            return "\(mins):\(String(format: "%02d", secs))"
        }
    }
}

// MARK: - Shared Components

struct TrainingZonesSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let zones: [TrainingZone]
    let discipline: Discipline

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text(title)
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            VStack(spacing: ECSpacing.sm) {
                ForEach(Array(zones.enumerated()), id: \.offset) { index, zone in
                    HStack(spacing: ECSpacing.sm) {
                        // Zone badge
                        Text(zone.shortName)
                            .font(.ecCaptionBold)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(themeManager.zoneColor(for: index + 1))
                            .cornerRadius(ECRadius.sm)

                        // Zone name
                        Text(zone.zoneDescription)
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Range
                        Text(zone.formattedRange)
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }
                    .padding(ECSpacing.sm)
                    .background(themeManager.surfaceColor)
                    .cornerRadius(ECRadius.md)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

struct MetadataRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.ecLabel)
                .foregroundColor(themeManager.textSecondary)
            Spacer()
            Text(value)
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)
        }
    }
}

// MARK: - Running Technique Detail View

struct RunningTechniqueDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let technique: RunningTechnique?
    let vmaZones: GenericZones?
    let paceZones: GenericZones?
    let hrZones: GenericZones?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    if let tech = technique {
                        // Metrics Section
                        RunningMetricsSection(technique: tech)

                        // VMA Zones
                        if let zones = vmaZones, let paces = paceZones {
                            GenericZonesSection(
                                title: "Zones VMA",
                                zones: zones,
                                secondaryZones: paces,
                                discipline: .course
                            )
                        }

                        // HR Zones
                        if let hrZ = hrZones {
                            GenericZonesSection(
                                title: "Zones FC",
                                zones: hrZ,
                                secondaryZones: nil,
                                discipline: .course
                            )
                        }
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Technique Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .environmentObject(themeManager)
    }
}

struct RunningMetricsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let technique: RunningTechnique

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text("Métriques")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: ECSpacing.md) {
                if let cadence = technique.cadenceSpm {
                    TechMetricCard(label: "Cadence", value: String(format: "%.0f", cadence), unit: "spm", icon: "metronome")
                }
                if let stride = technique.strideLengthM {
                    TechMetricCard(label: "Foulée", value: String(format: "%.2f", stride), unit: "m", icon: "ruler")
                }
                if let efficiency = technique.efficiencyIndex {
                    TechMetricCard(label: "Efficacité", value: String(format: "%.3f", efficiency), unit: "", icon: "bolt")
                }
                if let paHr = technique.paHrMedianPct {
                    TechMetricCard(label: "Pa:Hr", value: String(format: "%.1f", paHr), unit: "%", icon: "heart")
                }
                if let effectiveness = technique.runningEffectiveness {
                    TechMetricCard(label: "Effectiveness", value: String(format: "%.2f", effectiveness), unit: "", icon: "figure.run")
                }
                if let cv = technique.cvActive {
                    TechMetricCard(label: "CV Active", value: String(format: "%.1f", cv * 100), unit: "%", icon: "chart.line.uptrend.xyaxis")
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Cycling Technique Detail View

struct CyclingTechniqueDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let technique: CyclingTechnique?
    let ftpZones: GenericZones?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    if let tech = technique {
                        // Metrics Section
                        CyclingMetricsSection(technique: tech)

                        // FTP Zones
                        if let zones = ftpZones {
                            GenericZonesSection(
                                title: "Zones FTP",
                                zones: zones,
                                secondaryZones: nil,
                                discipline: .cyclisme
                            )
                        }
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Technique Vélo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .environmentObject(themeManager)
    }
}

struct CyclingMetricsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let technique: CyclingTechnique

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text("Métriques")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: ECSpacing.md) {
                if let cadence = technique.cadenceRpm {
                    TechMetricCard(label: "Cadence", value: String(format: "%.0f", cadence), unit: "rpm", icon: "circle.dotted")
                }
                if let vi = technique.variabilityIndex {
                    TechMetricCard(label: "VI", value: String(format: "%.2f", vi), unit: "", icon: "waveform.path")
                }
                if let ef = technique.efficiencyFactor {
                    TechMetricCard(label: "EF", value: String(format: "%.2f", ef), unit: "", icon: "bolt")
                }
                if let pwHr = technique.pwHrMedianPct {
                    TechMetricCard(label: "Pw:Hr", value: String(format: "%.1f", pwHr), unit: "%", icon: "heart")
                }
                if let pma = technique.pmaBestW {
                    TechMetricCard(label: "PMA", value: String(format: "%.0f", pma), unit: "W", icon: "flame")
                }
                if let te = technique.torqueEffectivenessPct {
                    TechMetricCard(label: "Couple Eff.", value: String(format: "%.0f", te), unit: "%", icon: "arrow.triangle.2.circlepath")
                }
                if let ps = technique.pedalSmoothnessPct {
                    TechMetricCard(label: "Fluidité", value: String(format: "%.0f", ps), unit: "%", icon: "circle.circle")
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Swimming Technique Detail View

struct SwimmingTechniqueDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let technique: SwimmingTechnique?
    let cssZones: GenericZones?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    if let tech = technique {
                        // Metrics Section
                        SwimmingMetricsSection(technique: tech)

                        // CSS Zones
                        if let zones = cssZones {
                            GenericZonesSection(
                                title: "Zones CSS",
                                zones: zones,
                                secondaryZones: nil,
                                discipline: .natation
                            )
                        }
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Technique Natation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .environmentObject(themeManager)
    }
}

struct SwimmingMetricsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let technique: SwimmingTechnique

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text("Métriques")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: ECSpacing.md) {
                if let swolf = technique.swolf {
                    TechMetricCard(label: "SWOLF", value: String(format: "%.0f", swolf), unit: "", icon: "drop")
                }
                if let strokeRate = technique.strokeRateCpm {
                    TechMetricCard(label: "Fréquence", value: String(format: "%.1f", strokeRate), unit: "c/min", icon: "metronome")
                }
                if let efficiency = technique.efficiencyIndex {
                    TechMetricCard(label: "Efficacité", value: String(format: "%.3f", efficiency), unit: "", icon: "bolt")
                }
                if let dps = technique.distancePerStrokeM {
                    TechMetricCard(label: "Dist/Cycle", value: String(format: "%.2f", dps), unit: "m", icon: "ruler")
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Generic Zones Section

struct GenericZonesSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let zones: GenericZones
    let secondaryZones: GenericZones?
    let discipline: Discipline

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            HStack {
                Text(title)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                if let unit = zones.unit {
                    Text("(\(unit))")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                }
            }

            VStack(spacing: ECSpacing.sm) {
                let primaryZones = zones.zonesArray
                let secondaryArr = secondaryZones?.zonesArray ?? []

                ForEach(Array(primaryZones.enumerated()), id: \.offset) { index, zone in
                    HStack(spacing: ECSpacing.sm) {
                        // Zone badge
                        Text(zone.name)
                            .font(.ecCaptionBold)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(themeManager.zoneColor(for: index + 1))
                            .cornerRadius(ECRadius.sm)

                        // Primary range
                        Text(zone.range)
                            .font(.ecLabel)
                            .foregroundColor(themeManager.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Secondary range (pace, etc)
                        if index < secondaryArr.count {
                            Text(secondaryArr[index].range)
                                .font(.ecSmall)
                                .foregroundColor(themeManager.textSecondary)
                        }
                    }
                    .padding(ECSpacing.sm)
                    .background(themeManager.surfaceColor)
                    .cornerRadius(ECRadius.md)
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Tech Metric Card

struct TechMetricCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let label: String
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.xs) {
            HStack(spacing: ECSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.textTertiary)
                Text(label)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textSecondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.textPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ECSpacing.sm)
        .background(themeManager.surfaceColor)
        .cornerRadius(ECRadius.md)
    }
}

// MARK: - Previews

#Preview("VMA Detail") {
    VMADetailView(vma: nil)
        .environmentObject(ThemeManager.shared)
}

#Preview("FTP Detail") {
    FTPDetailView(ftp: nil)
        .environmentObject(ThemeManager.shared)
}

#Preview("CSS Detail") {
    CSSDetailView(css: nil)
        .environmentObject(ThemeManager.shared)
}
