/**
 * CustomAnalysesSettingsView - Personnalisation des analyses rapides
 * Permet de modifier les 4 analyses affichées dans l'interface de session
 */

import SwiftUI

struct CustomAnalysesSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var analyses: [CustomAnalysis] = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showResetConfirmation = false
    @State private var editingIndex: Int?

    private let service = CustomAnalysisService.shared

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else {
                    analysesListView
                }
            }
            .navigationTitle("Analyses rapides")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        Task { await saveAndDismiss() }
                    }
                    .disabled(isSaving)
                }
            }
            .alert("Réinitialiser", isPresented: $showResetConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Réinitialiser", role: .destructive) {
                    Task { await resetToDefaults() }
                }
            } message: {
                Text("Voulez-vous rétablir les analyses par défaut ?")
            }
            .sheet(item: $editingIndex) { index in
                AnalysisEditorSheet(
                    analysis: analyses[index],
                    onSave: { updatedAnalysis in
                        analyses[index] = updatedAnalysis
                    }
                )
                .environmentObject(themeManager)
            }
        }
        .task {
            await loadAnalyses()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Chargement...")
                .font(.ecCaption)
                .foregroundColor(themeManager.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.backgroundColor)
    }

    // MARK: - Analyses List

    private var analysesListView: some View {
        List {
            Section {
                ForEach(Array(analyses.enumerated()), id: \.element.id) { index, analysis in
                    AnalysisRow(
                        analysis: analysis,
                        index: index,
                        onEdit: {
                            editingIndex = index
                        }
                    )
                }
                .onMove { source, destination in
                    analyses.move(fromOffsets: source, toOffset: destination)
                }
            } header: {
                Text("Vos 4 analyses rapides")
            } footer: {
                Text("Ces analyses apparaissent dans le menu d'analyse des sessions. Appuyez sur une analyse pour la modifier.")
            }

            Section {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Rétablir les valeurs par défaut")
                    }
                }
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.ecCaption)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Actions

    private func loadAnalyses() async {
        guard let userId = authViewModel.user?.id else {
            analyses = CustomAnalysis.defaults
            isLoading = false
            return
        }

        do {
            analyses = try await service.getAnalyses(for: userId)
        } catch {
            analyses = CustomAnalysis.defaults
            errorMessage = "Erreur de chargement, utilisation des analyses par défaut"
        }
        isLoading = false
    }

    private func saveAndDismiss() async {
        guard let userId = authViewModel.user?.id else {
            dismiss()
            return
        }

        isSaving = true
        do {
            try await service.saveAnalyses(for: userId, analyses: analyses)
            dismiss()
        } catch {
            errorMessage = "Erreur lors de la sauvegarde"
        }
        isSaving = false
    }

    private func resetToDefaults() async {
        guard let userId = authViewModel.user?.id else {
            analyses = CustomAnalysis.defaults
            return
        }

        do {
            try await service.resetToDefaults(for: userId)
            analyses = CustomAnalysis.defaults
        } catch {
            errorMessage = "Erreur lors de la réinitialisation"
        }
    }
}

// MARK: - Analysis Row

struct AnalysisRow: View {
    @EnvironmentObject var themeManager: ThemeManager

    let analysis: CustomAnalysis
    let index: Int
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                // Numéro
                Text("\(index + 1)")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textTertiary)
                    .frame(width: 20)

                // Icône
                ZStack {
                    Circle()
                        .fill(themeManager.accentColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: analysis.icon)
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.accentColor)
                }

                // Texte
                VStack(alignment: .leading, spacing: 2) {
                    Text(analysis.title)
                        .font(.ecLabel)
                        .foregroundColor(themeManager.textPrimary)

                    Text(analysis.description)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.textTertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.premium)
    }
}

// MARK: - Analysis Editor Sheet

struct AnalysisEditorSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    let analysis: CustomAnalysis
    let onSave: (CustomAnalysis) -> Void

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedIcon: String = ""
    @State private var showIconPicker = false

    // Liste d'icônes suggérées
    private let suggestedIcons = [
        "chart.line.uptrend.xyaxis", "heart.fill", "bolt.fill", "lightbulb.fill",
        "speedometer", "figure.run", "figure.outdoor.cycle", "figure.pool.swim",
        "flame.fill", "timer", "waveform.path.ecg", "arrow.up.right",
        "chart.bar.fill", "gauge.high", "mountain.2.fill", "arrow.triangle.2.circlepath",
        "star.fill", "target", "trophy.fill", "medal.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Titre") {
                    TextField("Titre de l'analyse", text: $title)
                }

                Section("Description") {
                    TextField("Description courte", text: $description)
                }

                Section("Icône") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(suggestedIcons, id: \.self) { icon in
                            IconButton(
                                icon: icon,
                                isSelected: selectedIcon == icon
                            ) {
                                selectedIcon = icon
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Aperçu") {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(themeManager.accentColor.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: selectedIcon)
                                .font(.system(size: 18))
                                .foregroundColor(themeManager.accentColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title.isEmpty ? "Titre" : title)
                                .font(.ecLabel)
                                .foregroundColor(themeManager.textPrimary)

                            Text(description.isEmpty ? "Description" : description)
                                .font(.ecCaption)
                                .foregroundColor(themeManager.textSecondary)
                        }

                        Spacer()
                    }
                }
            }
            .navigationTitle("Modifier l'analyse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        let updated = CustomAnalysis(
                            id: analysis.id,
                            icon: selectedIcon,
                            title: title,
                            description: description
                        )
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(title.isEmpty || description.isEmpty || selectedIcon.isEmpty)
                }
            }
            .onAppear {
                title = analysis.title
                description = analysis.description
                selectedIcon = analysis.icon
            }
        }
    }
}

// MARK: - Icon Button

struct IconButton: View {
    @EnvironmentObject var themeManager: ThemeManager

    let icon: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                Circle()
                    .fill(isSelected ? themeManager.accentColor : themeManager.cardColor)
                    .frame(width: 44, height: 44)

                if isSelected {
                    Circle()
                        .stroke(themeManager.accentColor, lineWidth: 2)
                        .frame(width: 50, height: 50)
                }

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : themeManager.textSecondary)
            }
        }
        .buttonStyle(.premium)
    }
}

// MARK: - Int Extension for Identifiable

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

// MARK: - Preview

#Preview {
    CustomAnalysesSettingsView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(AuthViewModel())
}
