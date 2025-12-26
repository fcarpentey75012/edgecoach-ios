/**
 * Écran de gestion de l'équipement
 * Interface modernisée avec cartes visuelles et filtres
 * Utilise le modèle unifié 'Gear'
 */

import SwiftUI

struct EquipmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager

    @State private var selectedSport: SportType = .cycling
    // Liste plate d'équipements (Gear)
    @State private var allGear: [Gear] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showingAddSheet = false
    @State private var gearToDelete: Gear?
    @State private var showingDeleteAlert = false
    
    // Filter state
    @State private var showArchived = false

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                mainContent
            }
            .navigationTitle("Matériel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    closeButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEquipmentSheet(
                    selectedSport: selectedSport,
                    onAdd: addGear
                )
                .environmentObject(themeManager)
            }
            .alert("Supprimer l'équipement", isPresented: $showingDeleteAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    if let toDelete = gearToDelete {
                        Task {
                            await deleteGear(toDelete)
                        }
                    }
                }
            } message: {
                if let toDelete = gearToDelete {
                    Text("Voulez-vous vraiment supprimer \"\(toDelete.name)\" ?")
                }
            }
        }
        .task {
            await loadEquipment()
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if isLoading {
            loadingView
        } else if let error = error {
            errorView(error)
        } else {
            contentView
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .foregroundColor(themeManager.textSecondary)
        }
    }

    private var addButton: some View {
        Button {
            showingAddSheet = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundColor(themeManager.accentColor)
        }
    }

    // MARK: - Views

    private var loadingView: some View {
        VStack(spacing: ECSpacing.md) {
            ProgressView()
            Text("Chargement de l'équipement...")
                .font(.ecBody)
                .foregroundColor(themeManager.textSecondary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: ECSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(themeManager.errorColor)

            Text("Oups !")
                .font(.ecH4)
                .foregroundColor(themeManager.errorColor)

            Text(message)
                .font(.ecBody)
                .foregroundColor(themeManager.textSecondary)
                .multilineTextAlignment(.center)

            Button("Réessayer") {
                Task { await loadEquipment() }
            }
            .buttonStyle(.ecPrimary())
        }
        .padding()
    }

    private var contentView: some View {
        ScrollView {
            VStack(spacing: ECSpacing.lg) {
                // Header Stats
                EquipmentSummaryCard(totalCount: EquipmentService.shared.getCount(from: allGear), themeManager: themeManager)
                
                // Sport Selector
                SportSelectorView(selectedSport: $selectedSport, themeManager: themeManager)

                // Archive Toggle
                HStack {
                    Spacer()
                    Toggle("Afficher archivés", isOn: $showArchived)
                        .toggleStyle(SwitchToggleStyle(tint: themeManager.accentColor))
                        .labelsHidden()
                    Text("Afficher archivés")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }
                .padding(.horizontal)

                // Gear Sections by Type
                gearSections
            }
            .padding(.vertical)
        }
        .refreshable {
            await loadEquipment()
        }
    }
    
    // Filtrer l'équipement par sport séléctionné, puis grouper par GearType
    private var gearSections: some View {
        let filteredGear = allGear.filter { gear in
            gear.primarySport == selectedSport && (showArchived || gear.status == .active)
        }
        
        // Grouper par type
        let groupedGear = Dictionary(grouping: filteredGear, by: { $0.type })
        
        // On veut afficher les sections dans un ordre logique, pas aléatoire
        let sortedTypes = GearType.allCases.filter { groupedGear[$0] != nil }
        
        return VStack(spacing: ECSpacing.xl) {
            if filteredGear.isEmpty {
                EmptyStateView(themeManager: themeManager)
            } else {
                ForEach(sortedTypes) { type in
                    if let items = groupedGear[type] {
                        sectionForType(type, items: items)
                    }
                }
            }
        }
    }

    private func sectionForType(_ type: GearType, items: [Gear]) -> some View {
        VStack(alignment: .leading, spacing: ECSpacing.md) {
            // Section Header
            HStack {
                Label(type.rawValue, systemImage: type.icon)
                    .font(.ecH4)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
                Text("\(items.count)")
                    .font(.ecCaptionBold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.elevatedColor)
                    .cornerRadius(12)
                    .foregroundColor(themeManager.textSecondary)
            }
            .padding(.horizontal)

            LazyVStack(spacing: ECSpacing.sm) {
                ForEach(items) { item in
                    NavigationLink {
                        GearDetailView(
                            gear: item,
                            onDelete: {
                                await deleteGear(item)
                            }
                        )
                        .environmentObject(themeManager)
                    } label: {
                        GearCard(
                            gear: item,
                            sportColor: themeManager.sportColor(for: selectedSport.discipline),
                            themeManager: themeManager
                        )
                    }
                    .buttonStyle(.premium) // Important pour ne pas avoir l'effet bleu par défaut
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Data Methods

    private func loadEquipment() async {
        guard let userId = authViewModel.user?.id else {
            error = "Utilisateur non connecté"
            isLoading = false
            return
        }

        isLoading = true
        error = nil

        do {
            // On charge tout d'un coup, le filtrage est fait localement
            allGear = try await EquipmentService.shared.getAllGear(userId: userId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func addGear(sport: SportType, type: GearType, name: String, brand: String?, model: String?, year: String?, notes: String?) async {
        guard let userId = authViewModel.user?.id else { return }

        let newGear = Gear(
            id: "", // L'ID sera généré par le backend
            name: name,
            brand: brand ?? "",
            model: model ?? "",
            type: type,
            primarySport: sport,
            year: year,
            notes: notes,
            status: .active
        )
        
        do {
            _ = try await EquipmentService.shared.addGear(userId: userId, gear: newGear)
            await loadEquipment()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func deleteGear(_ gear: Gear) async {
        guard let userId = authViewModel.user?.id else { return }

        do {
            try await EquipmentService.shared.deleteGear(userId: userId, gear: gear)
            await loadEquipment()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Subviews

struct EmptyStateView: View {
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: ECSpacing.md) {
            Image(systemName: "bag")
                .font(.system(size: 40))
                .foregroundColor(themeManager.textTertiary)
            Text("Aucun équipement")
                .font(.ecBody)
                .foregroundColor(themeManager.textSecondary)
        }
        .padding(.vertical, ECSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

struct EquipmentSummaryCard: View {
    let totalCount: Int
    let themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Image(systemName: "bag.fill")
                    .foregroundColor(themeManager.accentColor)
                    .font(.system(size: 24))
                Text("Total")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
            }
            .padding(.horizontal, ECSpacing.lg)
            
            Divider().frame(height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(totalCount)")
                    .font(.ecH2)
                    .foregroundColor(themeManager.textPrimary)
                Text("équipements actifs")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textTertiary)
            }
            .padding(.horizontal, ECSpacing.lg)
            
            Spacer()
        }
        .padding(.vertical, ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .padding(.horizontal)
        .shadow(color: themeManager.cardShadow, radius: themeManager.cardShadowRadius, x: 0, y: 2)
    }
}

struct SportSelectorView: View {
    @Binding var selectedSport: SportType
    let themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: ECSpacing.md) {
            ForEach(SportType.allCases) { sport in
                SportSelectionPill(
                    sport: sport,
                    isSelected: selectedSport == sport,
                    themeManager: themeManager,
                    onTap: { selectedSport = sport }
                )
            }
        }
        .padding(.horizontal)
    }
}

struct SportSelectionPill: View {
    let sport: SportType
    let isSelected: Bool
    let themeManager: ThemeManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? themeManager.sportColor(for: sport.discipline) : themeManager.elevatedColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: sport.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : themeManager.textSecondary)
                }
                
                Text(sport.label)
                    .font(.ecCaption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? themeManager.textPrimary : themeManager.textSecondary)
            }
        }
        .buttonStyle(.premium)
        .frame(maxWidth: .infinity)
    }
}

struct GearCard: View {
    let gear: Gear
    let sportColor: Color
    let themeManager: ThemeManager

    @State private var gearImage: UIImage?

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Image ou Icon Box
            ZStack {
                if let image = gearImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: ECRadius.md))
                } else {
                    RoundedRectangle(cornerRadius: ECRadius.md)
                        .fill(sportColor.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: gear.type.icon)
                                .font(.title2)
                                .foregroundColor(sportColor)
                        )
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(gear.displayName)
                        .font(.ecLabelBold)
                        .foregroundColor(gear.status == .active ? themeManager.textPrimary : themeManager.textSecondary)
                        .lineLimit(1)

                    if gear.status != .active {
                        Text("Archivé")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.gray)
                            .cornerRadius(4)
                    }
                }

                Text(gear.fullDescription)
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Chevron pour indiquer que c'est cliquable
            Image(systemName: "chevron.right")
                .foregroundColor(themeManager.textTertiary.opacity(0.6))
        }
        .padding(ECSpacing.sm)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .shadow(color: themeManager.cardShadow, radius: 2, x: 0, y: 1)
        .opacity(gear.status == .active ? 1.0 : 0.7)
        .onAppear {
            gearImage = ImageStorageService.shared.loadImage(for: gear)
        }
    }
}

// MARK: - Add Equipment Sheet (Updated for Gear)

struct AddEquipmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    let selectedSport: SportType
    let onAdd: (SportType, GearType, String, String?, String?, String?, String?) async -> Void

    @State private var sport: SportType
    @State private var type: GearType
    @State private var name = ""
    @State private var brand = ""
    @State private var model = ""
    @State private var year = ""
    @State private var notes = ""
    @State private var isAdding = false

    init(selectedSport: SportType, onAdd: @escaping (SportType, GearType, String, String?, String?, String?, String?) async -> Void) {
        self.selectedSport = selectedSport
        self.onAdd = onAdd
        _sport = State(initialValue: selectedSport)
        // Initialiser avec le premier type dispo pour le sport (logique métier)
        // Ici on prend un défaut générique, mais l'UI le changera
        _type = State(initialValue: .accessory)
    }

    var body: some View {
        NavigationStack {
            Form {
                sportSection
                typeSection
                infoSection
                notesSection
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor)
            .navigationTitle("Nouveau Matériel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        Task {
                            isAdding = true
                            await onAdd(
                                sport,
                                type,
                                name,
                                brand.isEmpty ? nil : brand,
                                model.isEmpty ? nil : model,
                                year.isEmpty ? nil : year,
                                notes.isEmpty ? nil : notes
                            )
                            isAdding = false
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || isAdding)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }

    private var sportSection: some View {
        Section {
            Picker("Sport", selection: $sport) {
                ForEach(SportType.allCases) { s in
                    Label(s.label, systemImage: s.icon).tag(s)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Sport")
        }
        .listRowBackground(themeManager.cardColor)
    }

    private var typeSection: some View {
        Section {
            Picker("Catégorie", selection: $type) {
                // On filtre les types pertinents pour le sport sélectionné (Logique UI)
                ForEach(availableTypes(for: sport)) { t in
                    Label(t.rawValue, systemImage: t.icon).tag(t)
                }
            }
        } header: {
            Text("Type d'équipement")
        }
        .listRowBackground(themeManager.cardColor)
    }
    
    // Logique UI pour filtrer les types affichés dans le picker
    private func availableTypes(for sport: SportType) -> [GearType] {
        let categories = EquipmentCategory.categoriesFor(sport: sport)
        return categories.map { GearType.from(category: $0) }
    }

    private var infoSection: some View {
        Section {
            TextField("Nom (ex: Hoka Clifton 9)", text: $name)
                .foregroundColor(themeManager.textPrimary)
            TextField("Marque", text: $brand)
                .foregroundColor(themeManager.textPrimary)
            TextField("Modèle", text: $model)
                .foregroundColor(themeManager.textPrimary)
            TextField("Année", text: $year)
                .keyboardType(.numberPad)
                .foregroundColor(themeManager.textPrimary)
        } header: {
            Text("Détails")
        }
        .listRowBackground(themeManager.cardColor)
    }

    private var notesSection: some View {
        Section {
            TextEditor(text: $notes)
                .frame(minHeight: 80)
                .foregroundColor(themeManager.textPrimary)
        } header: {
            Text("Notes (ex: Kilométrage initial)")
        }
        .listRowBackground(themeManager.cardColor)
    }
}

#Preview {
    EquipmentView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager.shared)
}
