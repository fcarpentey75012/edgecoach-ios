/**
 * Écran de gestion de l'équipement
 * Interface modernisée avec cartes visuelles et filtres
 */

import SwiftUI

struct EquipmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager

    @State private var selectedSport: SportType = .cycling
    @State private var equipment: UserEquipment = .empty
    @State private var isLoading = true
    @State private var error: String?
    @State private var showingAddSheet = false
    @State private var itemToDelete: (item: EquipmentItem, sport: SportType, category: EquipmentCategory)?
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
                    onAdd: addEquipment
                )
                .environmentObject(themeManager)
            }
            .alert("Supprimer l'équipement", isPresented: $showingDeleteAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    if let toDelete = itemToDelete {
                        Task {
                            await deleteEquipment(item: toDelete.item, sport: toDelete.sport, category: toDelete.category)
                        }
                    }
                }
            } message: {
                if let toDelete = itemToDelete {
                    Text("Voulez-vous vraiment supprimer \"\(toDelete.item.name)\" ?")
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
                EquipmentSummaryCard(equipment: equipment, themeManager: themeManager)
                
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

                // Categories & Items
                equipmentCategories
            }
            .padding(.vertical)
        }
        .refreshable {
            await loadEquipment()
        }
    }

    private var equipmentCategories: some View {
        VStack(spacing: ECSpacing.xl) {
            ForEach(EquipmentCategory.categoriesFor(sport: selectedSport)) { category in
                categorySection(category)
            }
        }
    }

    private func categorySection(_ category: EquipmentCategory) -> some View {
        let allItems = EquipmentService.shared.getItems(from: equipment, sport: selectedSport, category: category)
        let filteredItems = showArchived ? allItems : allItems.filter { $0.isActive }

        // Hide empty sections only if we have absolutely no items (active or archived) to show
        if filteredItems.isEmpty && !showingAddSheet { // Little hack to keep layout stable
             // Optional: Show empty state specific to category if desired
             // For now, we just hide the section if empty to keep it clean
             if allItems.isEmpty {
                 return AnyView(EmptyView())
             }
        }

        return AnyView(
            VStack(alignment: .leading, spacing: ECSpacing.md) {
                // Section Header
                HStack {
                    Label(category.displayName, systemImage: category.icon)
                        .font(.ecH4)
                        .foregroundColor(themeManager.textPrimary)
                    Spacer()
                    Text("\(filteredItems.count)")
                        .font(.ecCaptionBold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeManager.elevatedColor)
                        .cornerRadius(12)
                        .foregroundColor(themeManager.textSecondary)
                }
                .padding(.horizontal)

                if filteredItems.isEmpty {
                    emptyCategoryView(category)
                } else {
                    LazyVStack(spacing: ECSpacing.sm) {
                        ForEach(filteredItems) { item in
                            EquipmentCard(
                                item: item,
                                category: category,
                                sportColor: themeManager.sportColor(for: selectedSport.discipline),
                                themeManager: themeManager,
                                onDelete: {
                                    itemToDelete = (item, selectedSport, category)
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        )
    }

    private func emptyCategoryView(_ category: EquipmentCategory) -> some View {
        HStack {
            Spacer()
            VStack(spacing: ECSpacing.sm) {
                Image(systemName: category.icon)
                    .font(.system(size: 30))
                    .foregroundColor(themeManager.textTertiary)
                    .opacity(0.5)
                Text("Aucun \(category.displayName.lowercased())")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textTertiary)
            }
            .padding(.vertical, ECSpacing.lg)
            Spacer()
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
            equipment = try await EquipmentService.shared.getEquipment(userId: userId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func addEquipment(sport: SportType, category: EquipmentCategory, name: String, brand: String?, model: String?, year: String?, notes: String?) async {
        guard let userId = authViewModel.user?.id else { return }

        do {
            _ = try await EquipmentService.shared.addEquipment(
                userId: userId,
                sport: sport,
                category: category,
                name: name,
                brand: brand,
                model: model,
                year: year,
                notes: notes
            )
            await loadEquipment()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func deleteEquipment(item: EquipmentItem, sport: SportType, category: EquipmentCategory) async {
        guard let userId = authViewModel.user?.id else { return }

        do {
            try await EquipmentService.shared.deleteEquipment(
                userId: userId,
                sport: sport,
                category: category,
                itemId: item.id
            )
            await loadEquipment()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Subviews

struct EquipmentSummaryCard: View {
    let equipment: UserEquipment
    let themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 0) {
            StatBox(label: "Vélos", count: equipment.cycling.bikes?.count ?? 0, icon: "bicycle", color: themeManager.sportColor(for: .cyclisme), themeManager: themeManager)
            Divider().frame(height: 30)
            StatBox(label: "Chaussures", count: (equipment.running.shoes?.count ?? 0) + (equipment.cycling.shoes?.count ?? 0), icon: "shoeprint.fill", color: themeManager.sportColor(for: .course), themeManager: themeManager)
            Divider().frame(height: 30)
            StatBox(label: "Total", count: EquipmentService.shared.getTotalCount(equipment), icon: "bag.fill", color: themeManager.accentColor, themeManager: themeManager)
        }
        .padding(.vertical, ECSpacing.md)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .padding(.horizontal)
        .shadow(color: themeManager.cardShadow, radius: themeManager.cardShadowRadius, x: 0, y: 2)
    }
}

struct StatBox: View {
    let label: String
    let count: Int
    let icon: String
    let color: Color
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18))
            Text("\(count)")
                .font(.ecH3)
                .foregroundColor(themeManager.textPrimary)
            Text(label)
                .font(.ecCaption)
                .foregroundColor(themeManager.textSecondary)
        }
        .frame(maxWidth: .infinity)
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
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

struct EquipmentCard: View {
    let item: EquipmentItem
    let category: EquipmentCategory
    let sportColor: Color
    let themeManager: ThemeManager
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: ECSpacing.md) {
            // Icon Box
            ZStack {
                RoundedRectangle(cornerRadius: ECRadius.md)
                    .fill(sportColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(sportColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.name)
                        .font(.ecLabelBold)
                        .foregroundColor(item.isActive ? themeManager.textPrimary : themeManager.textSecondary)
                    
                    if !item.isActive {
                        Text("Archivé")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.gray)
                            .cornerRadius(4)
                    }
                }
                
                Text([item.brand, item.model].filter { !$0.isEmpty }.joined(separator: " • "))
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
                
                if !item.year.isEmpty {
                    Text(item.year)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(themeManager.textTertiary.opacity(0.6))
                    .padding(8)
            }
        }
        .padding(ECSpacing.sm)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .shadow(color: themeManager.cardShadow, radius: 2, x: 0, y: 1)
        .opacity(item.isActive ? 1.0 : 0.7)
    }
}

// MARK: - Add Equipment Sheet (Refactored slightly for consistency)

struct AddEquipmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    let selectedSport: SportType
    let onAdd: (SportType, EquipmentCategory, String, String?, String?, String?, String?) async -> Void

    @State private var sport: SportType
    @State private var category: EquipmentCategory
    @State private var name = ""
    @State private var brand = ""
    @State private var model = ""
    @State private var year = ""
    @State private var notes = ""
    @State private var isAdding = false

    init(selectedSport: SportType, onAdd: @escaping (SportType, EquipmentCategory, String, String?, String?, String?, String?) async -> Void) {
        self.selectedSport = selectedSport
        self.onAdd = onAdd
        _sport = State(initialValue: selectedSport)
        _category = State(initialValue: EquipmentCategory.categoriesFor(sport: selectedSport).first ?? .accessories)
    }

    var body: some View {
        NavigationStack {
            Form {
                sportSection
                categorySection
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
                                category,
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
            .onChange(of: sport) { newSport in
                category = EquipmentCategory.categoriesFor(sport: newSport).first ?? .accessories
            }
        } header: {
            Text("Sport")
        }
        .listRowBackground(themeManager.cardColor)
    }

    private var categorySection: some View {
        Section {
            Picker("Catégorie", selection: $category) {
                ForEach(EquipmentCategory.categoriesFor(sport: sport)) { cat in
                    Label(cat.displayName, systemImage: cat.icon).tag(cat)
                }
            }
        } header: {
            Text("Type d'équipement")
        }
        .listRowBackground(themeManager.cardColor)
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
