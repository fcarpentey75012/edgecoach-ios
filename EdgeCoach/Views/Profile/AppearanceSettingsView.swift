/**
 * AppearanceSettingsView - Interface de personnalisation de l'apparence
 * Permet de changer le thème, la couleur d'accent et le style d'icônes
 */

import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var iconManager = IconManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Theme Mode Section
                Section {
                    ForEach(ThemeMode.allCases) { mode in
                        ThemeModeRow(
                            mode: mode,
                            isSelected: themeManager.themeMode == mode
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                themeManager.themeMode = mode
                            }
                        }
                    }
                } header: {
                    Text("Apparence")
                } footer: {
                    Text("Le mode Fitness utilise un fond noir profond avec des couleurs néon pour une meilleure lisibilité.")
                }
                
                // MARK: - Accent Color Section
                Section {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(AccentColorOption.allCases) { colorOption in
                            AccentColorButton(
                                colorOption: colorOption,
                                isSelected: themeManager.accentColorOption == colorOption
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    themeManager.accentColorOption = colorOption
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Couleur d'accent")
                }
                
                // MARK: - Icon Style Section
                Section {
                    ForEach(IconStyle.allCases) { style in
                        IconStyleRow(
                            style: style,
                            isSelected: iconManager.iconStyle == style
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                iconManager.iconStyle = style
                            }
                        }
                    }
                } header: {
                    Text("Style d'icônes")
                } footer: {
                    Text("En mode automatique, les icônes pleines sont utilisées avec le thème Fitness.")
                }
                
                // MARK: - Preview Section
                Section("Aperçu") {
                    PreviewCard()
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Apparence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Theme Mode Row

struct ThemeModeRow: View {
    let mode: ThemeMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: mode.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.displayName)
                        .foregroundColor(.primary)
                    
                    if mode == .fitness {
                        Text("Style Apple Fitness")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .fontWeight(.semibold)
                }
            }
        }
        .buttonStyle(.premium)
    }
}

// MARK: - Accent Color Button

struct AccentColorButton: View {
    let colorOption: AccentColorOption
    let isSelected: Bool
    let onSelect: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    private var displayColor: Color {
        themeManager.isFitnessMode ? colorOption.neonColor : colorOption.color
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(displayColor)
                        .frame(width: 44, height: 44)
                    
                    if isSelected {
                        Circle()
                            .stroke(Color.primary, lineWidth: 3)
                            .frame(width: 52, height: 52)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Text(colorOption.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.premium)
    }
}

// MARK: - Icon Style Row

struct IconStyleRow: View {
    let style: IconStyle
    let isSelected: Bool
    let onSelect: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    private var exampleIcons: [String] {
        let baseIcons = ["house", "calendar", "chart.bar", "person"]
        switch style {
        case .regular:
            return baseIcons
        case .filled:
            return baseIcons.map { $0 + ".fill" }
        case .auto:
            return themeManager.isFitnessMode 
                ? baseIcons.map { $0 + ".fill" }
                : baseIcons
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(exampleIcons, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(isSelected ? .accentColor : .secondary)
                    }
                }
                .frame(width: 100)
                
                Text(style.displayName)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .fontWeight(.semibold)
                }
            }
        }
        .buttonStyle(.premium)
    }
}

// MARK: - Preview Card

struct PreviewCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Header simulé
            HStack {
                Image(systemName: themeManager.isFitnessMode ? "calendar.fill" : "calendar")
                    .foregroundColor(themeManager.accentColor)
                Text("Résumé de la semaine")
                    .font(.headline)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
            }
            
            // Stats simulées
            HStack(spacing: 0) {
                PreviewStatItem(value: "5h30", label: "Volume", color: themeManager.accentColor)
                Divider().frame(height: 40)
                PreviewStatItem(value: "125 km", label: "Distance", color: themeManager.accentColor)
                Divider().frame(height: 40)
                PreviewStatItem(value: "4", label: "Séances", color: themeManager.accentColor)
            }
            .padding(.vertical, 8)
            .background(themeManager.accentColorLight)
            .cornerRadius(8)
            
            // Sport cards simulées
            HStack(spacing: 8) {
                PreviewSportBadge(icon: "figure.outdoor.cycle", color: themeManager.sportColor(for: .cyclisme))
                PreviewSportBadge(icon: "figure.run", color: themeManager.sportColor(for: .course))
                PreviewSportBadge(icon: "figure.pool.swim", color: themeManager.sportColor(for: .natation))
            }
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.borderColor, lineWidth: themeManager.cardBorderWidth)
        )
    }
}

struct PreviewStatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PreviewSportBadge: View {
    let icon: String
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 44, height: 44)
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview

#Preview {
    AppearanceSettingsView()
        .environmentObject(ThemeManager.shared)
}
