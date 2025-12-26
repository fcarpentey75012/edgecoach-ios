//
//  CoachingConfigSheet.swift
//  EdgeCoach
//
//  Sheet de configuration du coaching pour modification à la volée.
//  Permet de changer sport, niveau et style sans quitter le chat.
//

import SwiftUI

struct CoachingConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var config: CoachingConfig
    var onSave: (CoachingConfig) -> Void

    @State private var localConfig: CoachingConfig

    init(config: Binding<CoachingConfig>, onSave: @escaping (CoachingConfig) -> Void) {
        self._config = config
        self.onSave = onSave
        self._localConfig = State(initialValue: config.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Sport Section
                Section {
                    ForEach(SportSpecialization.allCases) { sport in
                        SportRow(
                            sport: sport,
                            isSelected: localConfig.sport == sport,
                            action: { localConfig.sport = sport }
                        )
                    }
                } header: {
                    Label("Spécialisation", systemImage: "figure.run")
                }

                // MARK: - Level Section
                Section {
                    ForEach(UserLevel.allCases) { level in
                        LevelRow(
                            level: level,
                            isSelected: localConfig.level == level,
                            action: { localConfig.level = level }
                        )
                    }
                } header: {
                    Label("Mon niveau", systemImage: "chart.bar.fill")
                }

                // MARK: - Style Section
                Section {
                    ForEach(CoachingStyle.allCases) { style in
                        StyleRow(
                            style: style,
                            isSelected: localConfig.style == style,
                            action: { localConfig.style = style }
                        )
                    }
                } header: {
                    Label("Style de coaching", systemImage: "person.fill")
                }
            }
            .navigationTitle("Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .buttonStyle(.premium)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Appliquer") {
                        onSave(localConfig)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .buttonStyle(.premium)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Sport Row

private struct SportRow: View {
    let sport: SportSpecialization
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SportSpecializationIconView(specialization: sport, size: 28)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(sport.displayName)
                        .font(.body)
                        .foregroundStyle(.primary)

                    Text(sport.emoji)
                        .font(.caption)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(sport.color)
                        .font(.title3)
                }
            }
        }
        .buttonStyle(.premium)
        .listRowBackground(
            isSelected ? sport.color.opacity(0.1) : Color.clear
        )
    }
}

// MARK: - Level Row

private struct LevelRow: View {
    let level: UserLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: level.icon)
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(.body)
                        .foregroundStyle(.primary)

                    Text(level.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                }
            }
        }
        .buttonStyle(.premium)
        .listRowBackground(
            isSelected ? Color.orange.opacity(0.1) : Color.clear
        )
    }
}

// MARK: - Style Row

private struct StyleRow: View {
    let style: CoachingStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: style.icon)
                    .font(.title2)
                    .foregroundStyle(style.color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(style.displayName)
                            .font(.body)
                            .foregroundStyle(.primary)

                        Text(style.emoji)
                            .font(.caption)
                    }

                    Text(style.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(style.color)
                        .font(.title3)
                }
            }
        }
        .buttonStyle(.premium)
        .listRowBackground(
            isSelected ? style.color.opacity(0.1) : Color.clear
        )
    }
}

// MARK: - Preview

#Preview {
    CoachingConfigSheet(
        config: .constant(.default)
    ) { config in
        print("Config saved: \(config)")
    }
}
