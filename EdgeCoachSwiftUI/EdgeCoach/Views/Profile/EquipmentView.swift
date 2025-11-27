/**
 * Écran de gestion de l'équipement
 * CRUD complet pour vélos, chaussures, accessoires par sport
 */

import SwiftUI

struct EquipmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var selectedSport: SportType = .cycling
    @State private var equipment: UserEquipment = .empty
    @State private var isLoading = true
    @State private var error: String?
    @State private var showingAddSheet = false
    @State private var itemToDelete: (item: EquipmentItem, sport: SportType, category: EquipmentCategory)?
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Équipement")
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
                .foregroundColor(.ecSecondary)
        }
    }

    private var addButton: some View {
        Button {
            showingAddSheet = true
        } label: {
            Image(systemName: "plus")
                .foregroundColor(.ecPrimary)
        }
    }

    // MARK: - Views

    private var loadingView: some View {
        VStack(spacing: ECSpacing.md) {
            ProgressView()
            Text("Chargement de l'équipement...")
                .font(.ecBody)
                .foregroundColor(.ecGray500)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: ECSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.ecError)

            Text("Erreur")
                .font(.ecH4)
                .foregroundColor(.ecError)

            Text(message)
                .font(.ecBody)
                .foregroundColor(.ecGray500)
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
                totalCountBadge
                sportSelector
                equipmentCategories
            }
            .padding()
        }
        .background(Color.ecBackground)
        .refreshable {
            await loadEquipment()
        }
    }

    private var totalCountBadge: some View {
        HStack {
            Image(systemName: "bag.fill")
                .foregroundColor(.ecPrimary)

            Text("\(EquipmentService.shared.getTotalCount(equipment)) équipements au total")
                .font(.ecLabel)
                .foregroundColor(.ecSecondary)

            Spacer()
        }
        .padding()
        .background(Color.ecPrimary.opacity(0.1))
        .cornerRadius(ECRadius.md)
    }

    private var sportSelector: some View {
        HStack(spacing: ECSpacing.sm) {
            sportButton(for: .cycling)
            sportButton(for: .running)
            sportButton(for: .swimming)
        }
    }

    private func sportButton(for sport: SportType) -> some View {
        let count = getCountForSport(sport)
        let isSelected = selectedSport == sport

        return Button {
            selectedSport = sport
        } label: {
            VStack(spacing: ECSpacing.xs) {
                Image(systemName: sport.icon)
                    .font(.system(size: 24))

                Text(sport.label)
                    .font(.ecCaption)
                    .fontWeight(.semibold)

                Text("\(count)")
                    .font(.ecCaptionBold)
                    .foregroundColor(isSelected ? .white : sport.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? sport.color : sport.color.opacity(0.2))
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ECSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ECRadius.md)
                    .fill(isSelected ? sport.color.opacity(0.1) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.md)
                    .stroke(isSelected ? sport.color : Color.clear, lineWidth: 2)
            )
            .foregroundColor(isSelected ? sport.color : .ecGray500)
        }
    }

    private var equipmentCategories: some View {
        VStack(spacing: ECSpacing.md) {
            ForEach(EquipmentCategory.categoriesFor(sport: selectedSport)) { category in
                categorySection(category)
            }
        }
    }

    private func categorySection(_ category: EquipmentCategory) -> some View {
        let items = EquipmentService.shared.getItems(from: equipment, sport: selectedSport, category: category)

        return VStack(alignment: .leading, spacing: ECSpacing.sm) {
            categoryHeader(category, itemCount: items.count)

            if items.isEmpty {
                emptyItemsView(category)
            } else {
                ForEach(items) { item in
                    equipmentItemCard(item, category: category)
                }
            }
        }
    }

    private func categoryHeader(_ category: EquipmentCategory, itemCount: Int) -> some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(selectedSport.color)

            Text(category.displayName)
                .font(.ecLabel)
                .fontWeight(.semibold)
                .foregroundColor(.ecSecondary)

            Spacer()

            Text("\(itemCount)")
                .font(.ecCaption)
                .foregroundColor(.ecGray500)
        }
        .padding(.horizontal, ECSpacing.sm)
    }

    private func emptyItemsView(_ category: EquipmentCategory) -> some View {
        HStack {
            Spacer()
            VStack(spacing: ECSpacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.ecGray300)

                Text("Aucun équipement")
                    .font(.ecCaption)
                    .foregroundColor(.ecGray400)

                Button {
                    showingAddSheet = true
                } label: {
                    Text("Ajouter")
                        .font(.ecCaptionBold)
                        .foregroundColor(.ecPrimary)
                }
            }
            .padding(.vertical, ECSpacing.lg)
            Spacer()
        }
        .background(Color.white)
        .cornerRadius(ECRadius.md)
    }

    private func equipmentItemCard(_ item: EquipmentItem, category: EquipmentCategory) -> some View {
        HStack(spacing: ECSpacing.md) {
            itemIcon(category)
            itemInfo(item)
            Spacer()
            if item.isActive {
                activeBadge
            }
            deleteButton(item, category: category)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(ECRadius.md)
    }

    private func itemIcon(_ category: EquipmentCategory) -> some View {
        Image(systemName: category.icon)
            .font(.system(size: 20))
            .foregroundColor(selectedSport.color)
            .frame(width: 40, height: 40)
            .background(selectedSport.color.opacity(0.1))
            .cornerRadius(ECRadius.sm)
    }

    private func itemInfo(_ item: EquipmentItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.name)
                .font(.ecLabel)
                .foregroundColor(.ecSecondary)

            if !item.brand.isEmpty || !item.model.isEmpty {
                Text([item.brand, item.model].filter { !$0.isEmpty }.joined(separator: " "))
                    .font(.ecCaption)
                    .foregroundColor(.ecGray500)
            }

            if !item.year.isEmpty {
                Text(item.year)
                    .font(.ecCaption)
                    .foregroundColor(.ecGray400)
            }
        }
    }

    private var activeBadge: some View {
        Text("Actif")
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.ecSuccess)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.ecSuccess.opacity(0.1))
            .cornerRadius(4)
    }

    private func deleteButton(_ item: EquipmentItem, category: EquipmentCategory) -> some View {
        Button {
            itemToDelete = (item, selectedSport, category)
            showingDeleteAlert = true
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 16))
                .foregroundColor(.ecError)
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

    private func getCountForSport(_ sport: SportType) -> Int {
        switch sport {
        case .cycling: return equipment.cycling.count
        case .running: return equipment.running.count
        case .swimming: return equipment.swimming.count
        }
    }
}

// MARK: - Add Equipment Sheet

struct AddEquipmentSheet: View {
    @Environment(\.dismiss) private var dismiss

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
            .navigationTitle("Ajouter un équipement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
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
                }
            }
        }
    }

    private var sportSection: some View {
        Section("Sport") {
            Picker("Sport", selection: $sport) {
                ForEach(SportType.allCases) { s in
                    Label(s.label, systemImage: s.icon).tag(s)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: sport) { newSport in
                category = EquipmentCategory.categoriesFor(sport: newSport).first ?? .accessories
            }
        }
    }

    private var categorySection: some View {
        Section("Catégorie") {
            Picker("Catégorie", selection: $category) {
                ForEach(EquipmentCategory.categoriesFor(sport: sport)) { cat in
                    Label(cat.displayName, systemImage: cat.icon).tag(cat)
                }
            }
        }
    }

    private var infoSection: some View {
        Section("Informations") {
            TextField("Nom *", text: $name)
            TextField("Marque", text: $brand)
            TextField("Modèle", text: $model)
            TextField("Année", text: $year)
                .keyboardType(.numberPad)
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: $notes)
                .frame(minHeight: 80)
        }
    }
}

#Preview {
    EquipmentView()
        .environmentObject(AuthViewModel())
}
