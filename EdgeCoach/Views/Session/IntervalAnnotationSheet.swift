/**
 * IntervalAnnotationSheet - Interface d'annotation des intervalles
 *
 * Sheet modale permettant d'annoter un intervalle/lap avec :
 * - Type d'exercice
 * - Zone d'intensité
 * - Équipement (multi-sélection)
 * - Commentaire
 * - Ressenti
 * - Données spécifiques par sport
 */

import SwiftUI

// MARK: - Interval Annotation Sheet

struct IntervalAnnotationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    let lap: ActivityLap
    let lapIndex: Int
    let discipline: Discipline
    let existingAnnotation: IntervalAnnotation?
    let onSave: (IntervalAnnotation) -> Void

    // State
    @State private var selectedEquipment: Set<String> = []
    @State private var comment: String = ""
    @State private var selectedFeeling: IntervalFeeling?

    // Sport-specific state
    @State private var selectedSwimStyle: SwimStyle?
    @State private var targetPower: String = ""
    @State private var targetCadence: String = ""
    @State private var selectedPosition: CyclingPosition?
    @State private var targetPace: String = ""
    @State private var selectedTerrain: TerrainType?

    init(
        lap: ActivityLap,
        lapIndex: Int,
        discipline: Discipline,
        existingAnnotation: IntervalAnnotation? = nil,
        onSave: @escaping (IntervalAnnotation) -> Void
    ) {
        self.lap = lap
        self.lapIndex = lapIndex
        self.discipline = discipline
        self.existingAnnotation = existingAnnotation
        self.onSave = onSave

        // Initialize state from existing annotation
        if let existing = existingAnnotation {
            _selectedEquipment = State(initialValue: Set(existing.equipment))
            _comment = State(initialValue: existing.comment ?? "")
            _selectedFeeling = State(initialValue: existing.feeling)
            _selectedSwimStyle = State(initialValue: existing.swimStyle)
            _targetPower = State(initialValue: existing.targetPower.map { String($0) } ?? "")
            _targetCadence = State(initialValue: existing.targetCadence.map { String($0) } ?? "")
            _selectedPosition = State(initialValue: existing.position)
            _targetPace = State(initialValue: existing.targetPace ?? "")
            _selectedTerrain = State(initialValue: existing.terrain)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    // Lap Info Header
                    lapInfoHeader

                    // Équipement (spécifique par discipline)
                    if !discipline.intervalEquipmentOptions.isEmpty {
                        equipmentSection
                    }

                    // Données spécifiques par sport
                    sportSpecificSection

                    // Ressenti
                    feelingSection

                    // Commentaire
                    commentSection
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Annoter l'intervalle \(lapIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                        .foregroundColor(.blue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveAnnotation()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
            }
        }
        .environmentObject(themeManager)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Lap Info Header

    private var lapInfoHeader: some View {
        HStack(spacing: ECSpacing.md) {
            // Numéro du lap
            Text("\(lapIndex + 1)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(lap.formattedDuration)
                    .font(.ecH3)
                    .foregroundColor(Color(UIColor.label))

                HStack(spacing: ECSpacing.sm) {
                    Text(lap.formattedDistance)
                        .font(.ecBody)
                        .foregroundColor(Color(UIColor.secondaryLabel))

                    if let pace = discipline == .natation ? lap.formattedPacePer100m : lap.formattedPacePerKm {
                        Text("•")
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                        Text(pace)
                            .font(.ecBody)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }

                    if let hr = lap.avgHeartRate {
                        Text("•")
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("\(Int(hr))")
                                .font(.ecBody)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(ECRadius.md)
    }

    // MARK: - Equipment Section

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            sectionHeader("Équipement", icon: "wrench.and.screwdriver")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: ECSpacing.sm) {
                ForEach(discipline.intervalEquipmentOptions, id: \.id) { equipment in
                    SelectableChip(
                        label: equipment.label,
                        icon: equipment.icon,
                        isSelected: selectedEquipment.contains(equipment.id)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedEquipment.contains(equipment.id) {
                                selectedEquipment.remove(equipment.id)
                            } else {
                                selectedEquipment.insert(equipment.id)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sport Specific Section

    @ViewBuilder
    private var sportSpecificSection: some View {
        switch discipline {
        case .natation:
            swimStyleSection
        case .cyclisme:
            cyclingSection
        case .course:
            runningSection
        case .autre:
            EmptyView()
        }
    }

    private var swimStyleSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            sectionHeader("Style de nage", icon: "figure.pool.swim")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: ECSpacing.sm) {
                ForEach(SwimStyle.allCases) { style in
                    SelectableChip(
                        label: style.label,
                        icon: style.icon,
                        isSelected: selectedSwimStyle == style
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedSwimStyle = selectedSwimStyle == style ? nil : style
                        }
                    }
                }
            }
        }
    }

    private var cyclingSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            // Puissance cible
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                sectionHeader("Puissance cible", icon: "bolt")
                HStack {
                    TextField("Ex: 250", text: $targetPower)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    Text("W")
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }

            // Cadence cible
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                sectionHeader("Cadence cible", icon: "metronome")
                HStack {
                    TextField("Ex: 90", text: $targetCadence)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    Text("rpm")
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }

            // Position
            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                sectionHeader("Position", icon: "figure.outdoor.cycle")
                HStack(spacing: ECSpacing.sm) {
                    ForEach(CyclingPosition.allCases) { position in
                        SelectableChip(
                            label: position.label,
                            icon: nil,
                            isSelected: selectedPosition == position
                        ) {
                            withAnimation {
                                selectedPosition = selectedPosition == position ? nil : position
                            }
                        }
                    }
                }
            }
        }
    }

    private var runningSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            // Allure cible
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                sectionHeader("Allure cible", icon: "speedometer")
                HStack {
                    TextField("Ex: 4:30", text: $targetPace)
                        .textFieldStyle(.roundedBorder)
                    Text("/km")
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }

            // Cadence cible
            VStack(alignment: .leading, spacing: ECSpacing.xs) {
                sectionHeader("Cadence cible", icon: "metronome")
                HStack {
                    TextField("Ex: 180", text: $targetCadence)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    Text("ppm")
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }

            // Terrain
            VStack(alignment: .leading, spacing: ECSpacing.sm) {
                sectionHeader("Terrain", icon: "map")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: ECSpacing.sm) {
                    ForEach(TerrainType.runningTerrains) { terrain in
                        SelectableChip(
                            label: terrain.label,
                            icon: terrain.icon,
                            isSelected: selectedTerrain == terrain
                        ) {
                            withAnimation {
                                selectedTerrain = selectedTerrain == terrain ? nil : terrain
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Feeling Section

    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            sectionHeader("Ressenti", icon: "face.smiling")

            HStack(spacing: ECSpacing.md) {
                ForEach(IntervalFeeling.allCases) { feeling in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFeeling = selectedFeeling == feeling ? nil : feeling
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: feeling.icon)
                                .font(.title2)
                            Text(feeling.label)
                                .font(.ecCaption)
                        }
                        .foregroundColor(selectedFeeling == feeling ? .white : feelingColor(feeling))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ECSpacing.md)
                        .background(
                            selectedFeeling == feeling
                                ? feelingColor(feeling)
                                : feelingColor(feeling).opacity(0.15)
                        )
                        .cornerRadius(ECRadius.md)
                    }
                    .buttonStyle(.premium)
                }
            }
        }
    }

    // MARK: - Comment Section

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            sectionHeader("Commentaire", icon: "text.bubble")

            TextEditor(text: $comment)
                .frame(minHeight: 80)
                .padding(ECSpacing.sm)
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(ECRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: ECRadius.md)
                        .stroke(Color(UIColor.separator), lineWidth: 1)
                )

            Text("\(comment.count)/200")
                .font(.ecSmall)
                .foregroundColor(comment.count > 200 ? .ecError : Color(UIColor.tertiaryLabel))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: ECSpacing.xs) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.ecLabelBold)
                .foregroundColor(Color(UIColor.label))
        }
    }

    private func feelingColor(_ feeling: IntervalFeeling) -> Color {
        switch feeling {
        case .good: return .ecSuccess
        case .neutral: return .ecWarning
        case .hard: return .ecError
        }
    }

    // MARK: - Save

    private func saveAnnotation() {
        let annotation = IntervalAnnotation(
            id: existingAnnotation?.id ?? UUID().uuidString,
            lapIndex: lapIndex,
            equipment: Array(selectedEquipment),
            comment: comment.isEmpty ? nil : String(comment.prefix(200)),
            feeling: selectedFeeling,
            swimStyle: selectedSwimStyle,
            targetPower: Int(targetPower),
            targetCadence: Int(targetCadence),
            position: selectedPosition,
            targetPace: targetPace.isEmpty ? nil : targetPace,
            terrain: selectedTerrain
        )

        onSave(annotation)
        dismiss()
    }
}

// MARK: - Selectable Chip Component

private struct SelectableChip: View {
    let label: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(label)
                    .font(.ecCaption)
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : Color(UIColor.label))
            .padding(.horizontal, ECSpacing.sm)
            .padding(.vertical, ECSpacing.xs)
            .background(
                isSelected
                    ? Color.blue
                    : Color(UIColor.tertiarySystemBackground)
            )
            .cornerRadius(ECRadius.full)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.full)
                    .stroke(
                        isSelected ? Color.blue : Color(UIColor.separator),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.premium)
    }
}

// MARK: - Preview

#Preview {
    IntervalAnnotationSheet(
        lap: ActivityLap.preview,
        lapIndex: 0,
        discipline: .natation,
        existingAnnotation: nil
    ) { annotation in
        print("Saved: \(annotation)")
    }
    .environmentObject(ThemeManager.shared)
}

// MARK: - Preview Helper

extension ActivityLap {
    static var preview: ActivityLap {
        // Create a mock lap for previews
        let decoder = JSONDecoder()
        let json = """
        {
            "distance": 100,
            "duration": 95,
            "avg_speed_kmh": 3.8,
            "avg_heart_rate": 145
        }
        """.data(using: .utf8)!

        return try! decoder.decode(ActivityLap.self, from: json)
    }
}
