/**
 * Composants Logbook pour SessionDetailView
 * - EffortRatingEditor: Notation de l'effort (1-10)
 * - NutritionEditor: Gestion nutrition (gels, barres, etc.)
 * - HydrationEditor: Gestion hydratation (eau, isotonic, etc.)
 * - EquipmentSelector: Sélection équipement
 */

import SwiftUI

// MARK: - Effort Rating Editor

struct EffortRatingEditor: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var value: Int?

    private let maxRating = 10

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            Text("Comment avez-vous ressenti cette séance ?")
                .font(.ecBody)
                .foregroundColor(themeManager.textSecondary)

            // Rating buttons
            HStack(spacing: ECSpacing.xs) {
                ForEach(1...maxRating, id: \.self) { rating in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            value = rating
                        }
                    } label: {
                        Text("\(rating)")
                            .font(.ecLabel)
                            .fontWeight(value == rating ? .bold : .regular)
                            .foregroundColor(value == rating ? .white : ratingColor(rating))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(value == rating ? ratingColor(rating) : ratingColor(rating).opacity(0.15))
                            )
                    }
                }
            }

            // Description
            if let val = value {
                HStack(spacing: ECSpacing.sm) {
                    Image(systemName: ratingIcon(val))
                        .foregroundColor(ratingColor(val))
                    Text(ratingDescription(val))
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut, value: value)
    }

    private func ratingColor(_ rating: Int) -> Color {
        switch rating {
        case 1...3:
            return .ecSuccess
        case 4...6:
            return .ecWarning
        case 7...8:
            return .orange
        case 9...10:
            return .ecError
        default:
            return .ecGray400
        }
    }

    private func ratingIcon(_ rating: Int) -> String {
        switch rating {
        case 1...3:
            return "face.smiling"
        case 4...6:
            return "face.dashed"
        case 7...8:
            return "face.dashed.fill"
        case 9...10:
            return "flame.fill"
        default:
            return "questionmark.circle"
        }
    }

    private func ratingDescription(_ rating: Int) -> String {
        switch rating {
        case 1:
            return "Très facile - Récupération"
        case 2:
            return "Facile - Peu d'effort"
        case 3:
            return "Léger - Confortable"
        case 4:
            return "Modéré - Gérable"
        case 5:
            return "Moyen - Effort soutenu"
        case 6:
            return "Difficile - Exigeant"
        case 7:
            return "Très difficile - Éprouvant"
        case 8:
            return "Intense - À la limite"
        case 9:
            return "Extrême - Maximum"
        case 10:
            return "Épuisant - All-out"
        default:
            return ""
        }
    }
}

// MARK: - Nutrition Item Model

struct NutritionItem: Identifiable, Codable, Equatable {
    let id: String
    var type: NutritionType
    var quantity: Int
    var timing: String?
    var calories: Int?
    var carbs: Int?

    init(id: String = UUID().uuidString, type: NutritionType, quantity: Int = 1, timing: String? = nil) {
        self.id = id
        self.type = type
        self.quantity = quantity
        self.timing = timing
        self.calories = type.caloriesPerUnit * quantity
        self.carbs = type.carbsPerUnit * quantity
    }
}

enum NutritionType: String, Codable, CaseIterable, Identifiable {
    case gel = "gel"
    case bar = "bar"
    case banana = "banana"
    case dates = "dates"
    case drink = "drink"
    case other = "other"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gel: return "Gel"
        case .bar: return "Barre"
        case .banana: return "Banane"
        case .dates: return "Dattes"
        case .drink: return "Boisson énergétique"
        case .other: return "Autre"
        }
    }

    var icon: String {
        switch self {
        case .gel: return "drop.triangle.fill"
        case .bar: return "rectangle.fill"
        case .banana: return "leaf.fill"
        case .dates: return "circle.fill"
        case .drink: return "cup.and.saucer.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var caloriesPerUnit: Int {
        switch self {
        case .gel: return 100
        case .bar: return 200
        case .banana: return 90
        case .dates: return 60
        case .drink: return 150
        case .other: return 0
        }
    }

    var carbsPerUnit: Int {
        switch self {
        case .gel: return 25
        case .bar: return 30
        case .banana: return 23
        case .dates: return 15
        case .drink: return 35
        case .other: return 0
        }
    }
}

// MARK: - Nutrition Editor

struct NutritionEditor: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var items: [NutritionItem]
    @State private var showingAddSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            // Summary
            if !items.isEmpty {
                HStack(spacing: ECSpacing.lg) {
                    NutritionStat(
                        icon: "flame.fill",
                        value: "\(totalCalories)",
                        unit: "kcal",
                        color: .ecWarning
                    )

                    NutritionStat(
                        icon: "leaf.fill",
                        value: "\(totalCarbs)",
                        unit: "g glucides",
                        color: .ecSuccess
                    )
                }
                .padding(ECSpacing.md)
                .background(themeManager.elevatedColor)
                .cornerRadius(ECRadius.md)
            }

            // Items list
            ForEach(items) { item in
                NutritionItemRow(item: item, themeManager: themeManager) {
                    withAnimation {
                        items.removeAll { $0.id == item.id }
                    }
                } onQuantityChange: { newQuantity in
                    if let index = items.firstIndex(where: { $0.id == item.id }) {
                        items[index].quantity = newQuantity
                    }
                }
            }

            // Add button
            Button {
                showingAddSheet = true
            } label: {
                HStack(spacing: ECSpacing.sm) {
                    Image(systemName: "plus.circle.fill")
                    Text("Ajouter nutrition")
                }
                .font(.ecLabel)
                .foregroundColor(.ecPrimary)
                .frame(maxWidth: .infinity)
                .padding(ECSpacing.md)
                .background(Color.ecPrimary.opacity(0.1))
                .cornerRadius(ECRadius.md)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NutritionAddSheet { newItem in
                withAnimation {
                    items.append(newItem)
                }
            }
            .presentationDetents([.medium])
        }
    }

    private var totalCalories: Int {
        items.reduce(0) { $0 + ($1.calories ?? 0) }
    }

    private var totalCarbs: Int {
        items.reduce(0) { $0 + ($1.carbs ?? 0) }
    }
}

struct NutritionStat: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack(spacing: ECSpacing.xs) {
            Image(systemName: icon)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)
                Text(unit)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textTertiary)
            }
        }
    }
}

struct NutritionItemRow: View {
    let item: NutritionItem
    let themeManager: ThemeManager
    let onDelete: () -> Void
    let onQuantityChange: (Int) -> Void

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            Image(systemName: item.type.icon)
                .font(.title3)
                .foregroundColor(.ecWarning)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.type.label)
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textPrimary)
                if let timing = item.timing {
                    Text(timing)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textTertiary)
                }
            }

            Spacer()

            // Quantity stepper
            HStack(spacing: ECSpacing.xs) {
                Button {
                    if item.quantity > 1 {
                        onQuantityChange(item.quantity - 1)
                    }
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundColor(themeManager.textTertiary)
                }

                Text("\(item.quantity)")
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textPrimary)
                    .frame(width: 24)

                Button {
                    onQuantityChange(item.quantity + 1)
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(themeManager.accentColor)
                }
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.ecError)
            }
        }
        .padding(ECSpacing.sm)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.sm)
        .shadow(color: themeManager.cardShadow, radius: 2, x: 0, y: 1)
    }
}

struct NutritionAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (NutritionItem) -> Void

    @State private var selectedType: NutritionType = .gel
    @State private var quantity = 1
    @State private var timing = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(NutritionType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.label)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Quantité") {
                    Stepper("\(quantity)", value: $quantity, in: 1...20)
                }

                Section("Timing (optionnel)") {
                    TextField("Ex: Après 1h, au km 30...", text: $timing)
                }
            }
            .navigationTitle("Ajouter nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        let item = NutritionItem(
                            type: selectedType,
                            quantity: quantity,
                            timing: timing.isEmpty ? nil : timing
                        )
                        onAdd(item)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Hydration Item Model

struct HydrationItem: Identifiable, Codable, Equatable {
    let id: String
    var type: HydrationType
    var volumeMl: Int

    init(id: String = UUID().uuidString, type: HydrationType, volumeMl: Int = 500) {
        self.id = id
        self.type = type
        self.volumeMl = volumeMl
    }
}

enum HydrationType: String, Codable, CaseIterable, Identifiable {
    case water = "water"
    case isotonic = "isotonic"
    case electrolyte = "electrolyte"
    case recovery = "recovery"
    case other = "other"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .water: return "Eau"
        case .isotonic: return "Isotonique"
        case .electrolyte: return "Électrolytes"
        case .recovery: return "Récupération"
        case .other: return "Autre"
        }
    }

    var icon: String {
        switch self {
        case .water: return "drop.fill"
        case .isotonic: return "bolt.fill"
        case .electrolyte: return "sparkles"
        case .recovery: return "heart.fill"
        case .other: return "cup.and.saucer.fill"
        }
    }

    var color: Color {
        switch self {
        case .water: return .ecInfo
        case .isotonic: return .ecWarning
        case .electrolyte: return .ecSuccess
        case .recovery: return .ecError
        case .other: return .ecGray500
        }
    }
}

// MARK: - Hydration Editor

struct HydrationEditor: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var items: [HydrationItem]
    @State private var showingAddSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            // Total summary
            if !items.isEmpty {
                HStack(spacing: ECSpacing.sm) {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.ecInfo)
                    Text("Total: ")
                        .font(.ecBody)
                        .foregroundColor(themeManager.textSecondary)
                    Text(formattedTotal)
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                }
                .padding(ECSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.ecInfo.opacity(0.1))
                .cornerRadius(ECRadius.md)
            }

            // Items list
            ForEach(items) { item in
                HydrationItemRow(item: item, themeManager: themeManager) {
                    withAnimation {
                        items.removeAll { $0.id == item.id }
                    }
                } onVolumeChange: { newVolume in
                    if let index = items.firstIndex(where: { $0.id == item.id }) {
                        items[index].volumeMl = newVolume
                    }
                }
            }

            // Add button
            Button {
                showingAddSheet = true
            } label: {
                HStack(spacing: ECSpacing.sm) {
                    Image(systemName: "plus.circle.fill")
                    Text("Ajouter hydratation")
                }
                .font(.ecLabel)
                .foregroundColor(.ecInfo)
                .frame(maxWidth: .infinity)
                .padding(ECSpacing.md)
                .background(Color.ecInfo.opacity(0.1))
                .cornerRadius(ECRadius.md)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            HydrationAddSheet { newItem in
                withAnimation {
                    items.append(newItem)
                }
            }
            .presentationDetents([.medium])
        }
    }

    private var totalMl: Int {
        items.reduce(0) { $0 + $1.volumeMl }
    }

    private var formattedTotal: String {
        if totalMl >= 1000 {
            let liters = Double(totalMl) / 1000.0
            return String(format: "%.1f L", liters)
        }
        return "\(totalMl) ml"
    }
}

struct HydrationItemRow: View {
    let item: HydrationItem
    let themeManager: ThemeManager
    let onDelete: () -> Void
    let onVolumeChange: (Int) -> Void

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            Image(systemName: item.type.icon)
                .font(.title3)
                .foregroundColor(item.type.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.type.label)
                    .font(.ecLabel)
                    .foregroundColor(themeManager.textPrimary)
                Text(formattedVolume)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textTertiary)
            }

            Spacer()

            // Volume stepper
            HStack(spacing: ECSpacing.xs) {
                Button {
                    if item.volumeMl > 100 {
                        onVolumeChange(item.volumeMl - 100)
                    }
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundColor(themeManager.textTertiary)
                }

                Text(formattedVolume)
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textPrimary)
                    .frame(width: 50)

                Button {
                    onVolumeChange(item.volumeMl + 100)
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.ecInfo)
                }
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.ecError)
            }
        }
        .padding(ECSpacing.sm)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.sm)
        .shadow(color: themeManager.cardShadow, radius: 2, x: 0, y: 1)
    }

    private var formattedVolume: String {
        if item.volumeMl >= 1000 {
            let liters = Double(item.volumeMl) / 1000.0
            return String(format: "%.1fL", liters)
        }
        return "\(item.volumeMl)ml"
    }
}

struct HydrationAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (HydrationItem) -> Void

    @State private var selectedType: HydrationType = .water
    @State private var volume = 500

    private let volumePresets = [250, 330, 500, 750, 1000]

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(HydrationType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.label)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Volume") {
                    // Presets
                    HStack(spacing: ECSpacing.sm) {
                        ForEach(volumePresets, id: \.self) { preset in
                            Button {
                                volume = preset
                            } label: {
                                Text(preset >= 1000 ? "\(preset/1000)L" : "\(preset)ml")
                                    .font(.ecCaption)
                                    .foregroundColor(volume == preset ? .white : .ecPrimary)
                                    .padding(.horizontal, ECSpacing.sm)
                                    .padding(.vertical, ECSpacing.xs)
                                    .background(volume == preset ? Color.ecPrimary : Color.ecPrimary.opacity(0.1))
                                    .cornerRadius(ECRadius.full)
                            }
                        }
                    }

                    Stepper("\(volume) ml", value: $volume, in: 100...3000, step: 50)
                }
            }
            .navigationTitle("Ajouter hydratation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        let item = HydrationItem(type: selectedType, volumeMl: volume)
                        onAdd(item)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Equipment Selector

struct EquipmentSelector: View {
    @EnvironmentObject var themeManager: ThemeManager
    let userId: String
    let discipline: Discipline
    @Binding var selectedEquipment: [String]

    @State private var availableEquipment: [EquipmentItem] = []
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            if isLoading {
                HStack {
                    ProgressView()
                    Text("Chargement...")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            } else if availableEquipment.isEmpty {
                VStack(spacing: ECSpacing.sm) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundColor(themeManager.textTertiary)
                    Text("Aucun équipement configuré")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                    Text("Ajoutez du matériel dans votre profil")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ECSpacing.lg)
            } else {
                ForEach(availableEquipment) { item in
                    EquipmentSelectRow(
                        item: item,
                        isSelected: selectedEquipment.contains(item.id),
                        themeManager: themeManager
                    ) {
                        withAnimation {
                            if selectedEquipment.contains(item.id) {
                                selectedEquipment.removeAll { $0 == item.id }
                            } else {
                                selectedEquipment.append(item.id)
                            }
                        }
                    }
                }
            }
        }
        .task {
            await loadEquipment()
        }
    }

    private func loadEquipment() async {
        isLoading = true
        do {
            // Récupérer tout l'équipement de l'utilisateur
            let userEquipment = try await EquipmentService.shared.getEquipment(userId: userId)

            // Filtrer par sport selon la discipline de l'activité
            let sportEquipment: SportEquipment
            switch discipline {
            case .cyclisme:
                sportEquipment = userEquipment.cycling
            case .course:
                sportEquipment = userEquipment.running
            case .natation:
                sportEquipment = userEquipment.swimming
            case .autre:
                // Pour "autre", on peut proposer tout l'équipement ou rien
                sportEquipment = SportEquipment()
            }

            availableEquipment = sportEquipment.allItems.filter { $0.isActive }

            #if DEBUG
            print("✅ Loaded \(availableEquipment.count) equipment items for \(discipline.displayName)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to load equipment: \(error)")
            #endif
        }
        isLoading = false
    }
}

struct EquipmentSelectRow: View {
    let item: EquipmentItem
    let isSelected: Bool
    let themeManager: ThemeManager
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: ECSpacing.md) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.textTertiary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.ecLabel)
                        .foregroundColor(themeManager.textPrimary)
                    if !item.brand.isEmpty {
                        Text(item.brand)
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textTertiary)
                    }
                }

                Spacer()

                if !item.model.isEmpty {
                    Text(item.model)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }
            .padding(ECSpacing.sm)
            .background(isSelected ? themeManager.accentColor.opacity(0.05) : themeManager.cardColor)
            .cornerRadius(ECRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.sm)
                    .stroke(isSelected ? themeManager.accentColor : themeManager.borderColor, lineWidth: 1)
            )
        }
    }
}

// MARK: - Previews

#Preview("Effort Rating") {
    EffortRatingEditor(value: .constant(7))
        .padding()
        .environmentObject(ThemeManager.shared)
}

#Preview("Nutrition Editor") {
    NutritionEditor(items: .constant([
        NutritionItem(type: .gel, quantity: 2),
        NutritionItem(type: .bar, quantity: 1)
    ]))
    .padding()
    .environmentObject(ThemeManager.shared)
}

#Preview("Hydration Editor") {
    HydrationEditor(items: .constant([
        HydrationItem(type: .water, volumeMl: 750),
        HydrationItem(type: .isotonic, volumeMl: 500)
    ]))
    .padding()
    .environmentObject(ThemeManager.shared)
}
