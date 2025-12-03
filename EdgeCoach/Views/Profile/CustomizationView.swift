/**
 * CustomizationView - Vue de personnalisation générique
 * Permet d'accéder aux différentes options de personnalisation de l'app
 */

import SwiftUI

struct CustomizationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingDashboardSettings = false
    @State private var showingSessionSettings = false
    @State private var showingAnalysesSettings = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Dashboard
                    CustomizationRow(
                        icon: "square.grid.2x2",
                        iconColor: themeManager.infoColor,
                        title: "Dashboard",
                        subtitle: "Widgets, ordre d'affichage"
                    ) {
                        showingDashboardSettings = true
                    }

                    // Affichage des sessions
                    CustomizationRow(
                        icon: "figure.run",
                        iconColor: themeManager.sportColor(for: .course),
                        title: "Affichage des sessions",
                        subtitle: "Métriques, graphiques, unités"
                    ) {
                        showingSessionSettings = true
                    }

                    // Analyses rapides
                    CustomizationRow(
                        icon: "sparkles.rectangle.stack",
                        iconColor: themeManager.successColor,
                        title: "Analyses rapides",
                        subtitle: "4 analyses de session"
                    ) {
                        showingAnalysesSettings = true
                    }
                } header: {
                    Text("Éléments personnalisables")
                        .foregroundColor(themeManager.textSecondary)
                } footer: {
                    Text("Personnalisez l'affichage et le comportement de ces éléments selon vos préférences.")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textTertiary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor)
            .navigationTitle("Personnalisation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
            .sheet(isPresented: $showingDashboardSettings) {
                WidgetEditorView()
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingSessionSettings) {
                SessionDisplaySettingsView()
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingAnalysesSettings) {
                CustomAnalysesSettingsView()
                    .environmentObject(themeManager)
                    .environmentObject(authViewModel)
            }
        }
    }
}

// MARK: - Customization Row

struct CustomizationRow: View {
    @EnvironmentObject var themeManager: ThemeManager

    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ECSpacing.md) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.ecBody)
                        .foregroundColor(themeManager.textPrimary)

                    Text(subtitle)
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textTertiary)
            }
            .padding(.vertical, ECSpacing.xs)
        }
        .buttonStyle(.plain)
        .listRowBackground(themeManager.cardColor)
    }
}

// MARK: - Preview

#Preview {
    CustomizationView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(AuthViewModel())
}
