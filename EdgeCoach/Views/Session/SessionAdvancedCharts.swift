import SwiftUI
import Charts

// MARK: - Graphiques Avancés

struct AdvancedChartsView: View {
    let activity: Activity
    @State private var selectedTime: Double? // Synchronisation du curseur entre tous les graphes
    @State private var detailedActivity: Activity?
    @State private var isLoading = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Utiliser l'activité détaillée si disponible, sinon l'originale
    private var displayActivity: Activity {
        detailedActivity ?? activity
    }
    
    var body: some View {
        VStack(spacing: ECSpacing.lg) {
            if isLoading {
                ProgressView("Chargement des données détaillées...")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .themedCard()
            } else {
                // Contenu des graphiques utilisant displayActivity
                chartsContent
            }
        }
        .task {
            await loadDetailedDataIfNeeded()
        }
    }
    
    private var chartsContent: some View {
        VStack(spacing: ECSpacing.lg) {
            // 1. Graphiques Cardio (Tous sports)
            if displayActivity.fileDatas?.hrAvg != nil || (displayActivity.fileDatas?.records?.first?.heartRate != nil) {
                let points = ChartDataService.shared.extractData(from: displayActivity, type: .heartRate)
                if !points.isEmpty {
                    InteractiveChartContainer(
                        title: "Fréquence cardiaque",
                        icon: "heart.fill",
                        iconColor: .red,
                        selectedTime: $selectedTime,
                        dataPoints: points
                    ) {
                        Chart(points) { point in
                            LineMark(
                                x: .value("Temps", point.elapsedSeconds),
                                y: .value("BPM", point.value)
                            )
                            .foregroundStyle(.red)
                            .interpolationMethod(.catmullRom)
                            
                            // Zone Filling
                            AreaMark(
                                x: .value("Temps", point.elapsedSeconds),
                                y: .value("BPM", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red.opacity(0.3), .red.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            
                            if let selected = selectedTime {
                                RuleMark(x: .value("Temps", selected))
                                    .foregroundStyle(Color.gray.opacity(0.5))
                            }
                        }
                        .chartYAxis { AxisMarks(position: .leading) }
                        .frame(height: 200)
                    }
                }
            }
            
            // 2. Graphiques Spécifiques Cyclisme
            if displayActivity.discipline == .cyclisme {
                // Puissance (priorité file_datas via preferredAvgPower)
                if displayActivity.preferredAvgPower != nil || (displayActivity.fileDatas?.records?.first?.power != nil) {
                    let points = ChartDataService.shared.extractData(from: displayActivity, type: .power)
                    if !points.isEmpty {
                        InteractiveChartContainer(
                            title: "Puissance",
                            icon: "bolt.fill",
                            iconColor: .yellow,
                            selectedTime: $selectedTime,
                            dataPoints: points
                        ) {
                            Chart(points) { point in
                                LineMark(
                                    x: .value("Temps", point.elapsedSeconds),
                                    y: .value("Watts", point.value)
                                )
                                .foregroundStyle(.yellow)
                                
                                if let selected = selectedTime {
                                    RuleMark(x: .value("Temps", selected))
                                        .foregroundStyle(Color.gray.opacity(0.5))
                                }
                            }
                            .chartYAxis { AxisMarks(position: .leading) }
                            .frame(height: 200)
                        }
                    }
                }
                
                // Courbe de Puissance (CP Curve)
                let pdCurve = ChartDataService.shared.calculatePowerCurve(from: displayActivity)
                if !pdCurve.isEmpty {
                    VStack(alignment: .leading) {
                        Label("Courbe de Puissance", systemImage: "chart.xyaxis.line")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        Chart(pdCurve) { point in
                            LineMark(
                                x: .value("Durée", point.formattedDuration),
                                y: .value("Watts", point.watts)
                            )
                            .symbol(Circle())
                            .foregroundStyle(.orange)
                        }
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                            }
                        }
                        .frame(height: 200)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
                // Balance G/D & Smoothness (si dispo)
                if displayActivity.fileDatas?.records?.first(where: { $0.leftRightBalance != nil }) != nil {
                    CyclingDynamicsView(activity: displayActivity, selectedTime: $selectedTime)
                }
            }
            
            // 3. Graphiques Spécifiques Running
            if displayActivity.discipline == .course {
                // Vitesse vs Cadence
                if displayActivity.fileDatas?.avgSpeed != nil {
                    CadenceSpeedChartView(activity: displayActivity, selectedTime: $selectedTime)
                }
            }
            
            // 4. Vitesse & Altitude (Tous sports sauf natation en piscine parfois)
            if displayActivity.discipline != .natation {
                let speedPoints = ChartDataService.shared.extractData(from: displayActivity, type: .speed)
                if !speedPoints.isEmpty {
                    InteractiveChartContainer(
                        title: "Vitesse",
                        icon: "speedometer",
                        iconColor: .blue,
                        selectedTime: $selectedTime,
                        dataPoints: speedPoints
                    ) {
                        Chart(speedPoints) { point in
                            LineMark(
                                x: .value("Temps", point.elapsedSeconds),
                                y: .value("Vitesse", point.value) // Déjà en km/h normalement
                            )
                            .foregroundStyle(.blue)
                            
                            if let selected = selectedTime {
                                RuleMark(x: .value("Temps", selected))
                                    .foregroundStyle(Color.gray.opacity(0.5))
                            }
                        }
                        .frame(height: 150)
                    }
                }
            }
        }
    }
    
    private func loadDetailedDataIfNeeded() async {
        // Si on a déjà les records, pas besoin de charger
        if activity.fileDatas?.records != nil && !(activity.fileDatas?.records?.isEmpty ?? true) {
            return
        }
        
        // Si on a déjà chargé l'activité détaillée
        if detailedActivity?.fileDatas?.records != nil {
            return
        }
        
        guard let userId = authViewModel.user?.id,
              let date = activity.date else {
            return
        }
        
        isLoading = true
        
        do {
            let (_, fileData) = try await ActivitiesService.shared.getActivityGPSData(
                userId: userId,
                activityDate: date,
                forceReload: false
            )
            
            if let fileData = fileData {
                // Créer une copie de l'activité avec les nouvelles données
                // Comme Activity est immuable, on doit utiliser l'initialiseur complet
                // Astuce: Recréer une instance avec les mêmes champs + le nouveau fileData
                // NOTE: Idéalement il faudrait une méthode 'copy' ou 'with' dans le modèle
                
                // Pour l'instant, on reconstruit manuellement (c'est verbeux mais sûr)
                // Mais attendez, Activity a beaucoup de champs. C'est risqué de tout recopier manuellement ici.
                // Mieux : Modifier Activity.swift pour ajouter une méthode 'with(fileData:)'
                
                // Hack temporaire : On injecte via une méthode Helper si possible, ou on modifie Activity.swift
                // Je vais modifier Activity.swift juste après pour ajouter cette méthode helper.
                
                // En attendant la modif de Activity.swift, je vais supposer que la méthode existe
                // ou alors je fais une copie "sale" via JSON encode/decode si vraiment bloqué
                // Mais la meilleure pratique est d'ajouter la méthode 'with'
                
                self.detailedActivity = activity.with(fileDatas: fileData)
            }
        } catch {
            print("Erreur chargement détails graphiques: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Running Advanced Chart

struct CadenceSpeedChartView: View {
    let activity: Activity
    @Binding var selectedTime: Double?
    
    var body: some View {
        let speedPoints = ChartDataService.shared.extractData(from: activity, type: .speed)
        let cadencePoints = ChartDataService.shared.extractData(from: activity, type: .cadence)
        
        // On utilise speedPoints comme référence pour le conteneur interactif
        InteractiveChartContainer(
            title: "Vitesse & Cadence",
            icon: "figure.run",
            iconColor: .green,
            selectedTime: $selectedTime,
            dataPoints: speedPoints
        ) {
            Chart {
                ForEach(speedPoints) { point in
                    LineMark(
                        x: .value("Temps", point.elapsedSeconds),
                        y: .value("Vitesse", point.value)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                }
                
                ForEach(cadencePoints) { point in
                    LineMark(
                        x: .value("Temps", point.elapsedSeconds),
                        y: .value("Cadence", point.value / 2) // Echelle ajustée pour visibilité ? Ou Axe Y secondaire (SwiftUI 5.0 ne supporte pas bien le double axe Y natif facile)
                        // Astuce: Normaliser ou afficher séparément si les échelles sont trop différentes (ex: 12km/h vs 180ppm)
                        // Ici on va juste afficher la cadence sur un graph séparé collé pour mieux voir
                    )
                    .foregroundStyle(.green.opacity(0.5))
                }
                
                if let selected = selectedTime {
                    RuleMark(x: .value("Temps", selected))
                        .foregroundStyle(Color.gray.opacity(0.5))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) // Vitesse
            }
            // Note: Le double axe Y est complexe en SwiftUI pur avant iOS 17+.
            // Pour iOS 16, mieux vaut faire 2 graphs superposés ou normalisés.
            .frame(height: 200)
        }
    }
}

// MARK: - Cycling Dynamics View

struct CyclingDynamicsView: View {
    let activity: Activity
    @Binding var selectedTime: Double?
    
    var body: some View {
        VStack(spacing: ECSpacing.md) {
            // Balance G/D
            let balancePoints = ChartDataService.shared.extractData(from: activity, type: .leftRightBalance)
            if !balancePoints.isEmpty {
                InteractiveChartContainer(
                    title: "Équilibre G/D",
                    icon: "arrow.left.and.right.circle",
                    iconColor: .purple,
                    selectedTime: $selectedTime,
                    dataPoints: balancePoints
                ) {
                    Chart(balancePoints) { point in
                        PointMark(
                            x: .value("Temps", point.elapsedSeconds),
                            y: .value("Balance G", point.value)
                        )
                        .foregroundStyle(by: .value("Côté", point.value > 50 ? "Droite" : "Gauche"))
                        
                        if let selected = selectedTime {
                            RuleMark(x: .value("Temps", selected))
                                .foregroundStyle(Color.gray.opacity(0.5))
                        }
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 150)
                }
            }
            
            // Smoothness & Torque Effectiveness (Affichés ensemble ou séparés)
            let smoothnessPoints = ChartDataService.shared.extractData(from: activity, type: .pedalSmoothness)
            let torquePoints = ChartDataService.shared.extractData(from: activity, type: .torqueEffectiveness)
            
            if !smoothnessPoints.isEmpty || !torquePoints.isEmpty {
                InteractiveChartContainer(
                    title: "Efficacité & Fluidité",
                    icon: "gearshape.2.fill",
                    iconColor: .orange,
                    selectedTime: $selectedTime,
                    dataPoints: !torquePoints.isEmpty ? torquePoints : smoothnessPoints
                ) {
                    Chart {
                        ForEach(torquePoints) { point in
                            LineMark(
                                x: .value("Temps", point.elapsedSeconds),
                                y: .value("Efficacité", point.value)
                            )
                            .foregroundStyle(.orange)
                        }
                        
                        ForEach(smoothnessPoints) { point in
                            LineMark(
                                x: .value("Temps", point.elapsedSeconds),
                                y: .value("Fluidité", point.value)
                            )
                            .foregroundStyle(.purple)
                        }
                        
                        if let selected = selectedTime {
                            RuleMark(x: .value("Temps", selected))
                                .foregroundStyle(Color.gray.opacity(0.5))
                        }
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 150)
                }
            }
        }
    }
}
