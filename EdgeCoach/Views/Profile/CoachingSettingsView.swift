//
//  CoachingSettingsView.swift
//  EdgeCoach
//
//  Vue de configuration du coaching dans les paramètres.
//  Permet de personnaliser le sport, niveau et style de coaching.
//

import SwiftUI

struct CoachingSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var config: CoachingConfig
    private let configService = CoachingConfigService.shared

    init() {
        _config = State(initialValue: CoachingConfigService.shared.config)
    }

    var body: some View {
        Form {
            // MARK: - Résumé actuel
            Section {
                HStack(spacing: ECSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(config.sport.color.opacity(0.15))
                            .frame(width: 56, height: 56)

                        SportSpecializationIconView(specialization: config.sport, size: 28)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Configuration actuelle")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)

                        Text(config.displayString)
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)
                    }
                }
                .padding(.vertical, ECSpacing.xs)
            }

            // MARK: - Sport
            Section {
                ForEach(SportSpecialization.allCases) { sport in
                    Button {
                        config.sport = sport
                        configService.updateSport(sport)
                    } label: {
                        HStack(spacing: ECSpacing.md) {
                            SportSpecializationIconView(specialization: sport, size: 28)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(sport.displayName)
                                    .font(.ecLabel)
                                    .foregroundColor(themeManager.textPrimary)

                                Text(sport.emoji)
                                    .font(.ecCaption)
                            }

                            Spacer()

                            if config.sport == sport {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(sport.color)
                            }
                        }
                    }
                    .buttonStyle(.premium)
                }
            } header: {
                Label("Spécialisation sportive", systemImage: "figure.run")
            } footer: {
                Text("Le coach adaptera ses conseils et sa terminologie à votre sport.")
            }

            // MARK: - Level
            Section {
                ForEach(UserLevel.allCases) { level in
                    Button {
                        config.level = level
                        configService.updateLevel(level)
                    } label: {
                        HStack(spacing: ECSpacing.md) {
                            Image(systemName: level.icon)
                                .font(.title2)
                                .foregroundColor(.orange)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(level.displayName)
                                        .font(.ecLabel)
                                        .foregroundColor(themeManager.textPrimary)

                                    Text(level.emoji)
                                        .font(.ecCaption)
                                }

                                Text(level.description)
                                    .font(.ecCaption)
                                    .foregroundColor(themeManager.textSecondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            if config.level == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .buttonStyle(.premium)
                }
            } header: {
                Label("Votre niveau", systemImage: "chart.bar.fill")
            } footer: {
                Text("Le coach adaptera son discours et ses explications à votre expérience.")
            }

            // MARK: - Style
            Section {
                ForEach(CoachingStyle.allCases) { style in
                    Button {
                        config.style = style
                        configService.updateStyle(style)
                    } label: {
                        HStack(spacing: ECSpacing.md) {
                            Image(systemName: style.icon)
                                .font(.title2)
                                .foregroundColor(style.color)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(style.displayName)
                                        .font(.ecLabel)
                                        .foregroundColor(themeManager.textPrimary)

                                    Text(style.emoji)
                                        .font(.ecCaption)
                                }

                                Text(style.description)
                                    .font(.ecCaption)
                                    .foregroundColor(themeManager.textSecondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            if config.style == style {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(style.color)
                            }
                        }
                    }
                    .buttonStyle(.premium)
                }
            } header: {
                Label("Style de coaching", systemImage: "person.fill")
            } footer: {
                Text("Choisissez la personnalité de votre coach virtuel.")
            }

            // MARK: - Reset
            Section {
                Button(role: .destructive) {
                    config = .default
                    configService.resetToDefault()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Réinitialiser par défaut")
                    }
                }
            }
        }
        .navigationTitle("Configuration Coach")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Sport Specialization Icon View

/// Vue d'icône pour une spécialisation sportive
struct SportSpecializationIconView: View {
    let specialization: SportSpecialization
    let size: CGFloat

    var body: some View {
        Image(systemName: specialization.icon)
            .font(.system(size: size * 0.7))
            .foregroundColor(specialization.color)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CoachingSettingsView()
            .environmentObject(ThemeManager.shared)
    }
}
