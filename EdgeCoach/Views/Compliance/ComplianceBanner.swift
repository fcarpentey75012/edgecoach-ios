/**
 * ComplianceBanner - Bannière d'alerte compliance pour le Dashboard
 *
 * Affiche une notification compacte lorsque:
 * - Une proposition d'adaptation est en attente
 * - Une alerte de fatigue/surcharge est détectée
 * - Une opportunité positive est identifiée
 *
 * Design:
 * ┌─────────────────────────────────────────────┐
 * │ [Icon] Message d'alerte            [Action] │
 * │        Sous-titre contextuel       [Badge]  │
 * └─────────────────────────────────────────────┘
 */

import SwiftUI

// MARK: - Compliance Banner

struct ComplianceBanner: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: ComplianceViewModel
    let onTap: () -> Void

    var body: some View {
        if let proposal = viewModel.mostUrgentProposal {
            proposalBanner(proposal)
        } else if let alert = viewModel.activeAlert, alert.hasAlert {
            alertBanner(alert)
        }
    }

    // MARK: - Proposal Banner

    @ViewBuilder
    private func proposalBanner(_ proposal: ProposalView) -> some View {
        Button(action: {
            viewModel.openProposal(proposal)
            onTap()
        }) {
            HStack(spacing: ECSpacing.md) {
                // Icon avec badge
                ZStack(alignment: .topTrailing) {
                    Image(systemName: alertIcon(for: proposal.alertLevelEnum))
                        .font(.system(size: 24))
                        .foregroundColor(alertColor(for: proposal.alertLevelEnum))

                    // Badge urgent
                    if proposal.isUrgent {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .offset(x: 4, y: -4)
                    }
                }
                .frame(width: 36)

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(bannerTitle(for: proposal))
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)

                        if viewModel.pendingProposals.count > 1 {
                            Text("+\(viewModel.pendingProposals.count - 1)")
                                .font(.ecSmall)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(alertColor(for: proposal.alertLevelEnum))
                                .cornerRadius(8)
                        }
                    }

                    Text(proposal.context)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Time remaining + chevron
                VStack(alignment: .trailing, spacing: 2) {
                    if let time = viewModel.urgentTimeRemaining {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(time)
                                .font(.ecSmall)
                        }
                        .foregroundColor(proposal.isUrgent ? .red : themeManager.textTertiary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.textTertiary)
                }
            }
            .padding(ECSpacing.md)
            .background(bannerBackground(for: proposal.alertLevelEnum))
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(alertColor(for: proposal.alertLevelEnum).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.premium)
    }

    // MARK: - Alert Banner (no proposal)

    @ViewBuilder
    private func alertBanner(_ alert: ComplianceAlert) -> some View {
        HStack(spacing: ECSpacing.md) {
            Image(systemName: alert.level.icon)
                .font(.system(size: 24))
                .foregroundColor(alertColor(for: alert.level))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(alert.level.displayName)
                    .font(.ecLabelBold)
                    .foregroundColor(themeManager.textPrimary)

                if let message = alert.message ?? alert.reason {
                    Text(message)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Indicateur visuel
            Circle()
                .fill(alertColor(for: alert.level))
                .frame(width: 12, height: 12)
        }
        .padding(ECSpacing.md)
        .background(bannerBackground(for: alert.level))
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(alertColor(for: alert.level).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func bannerTitle(for proposal: ProposalView) -> String {
        if proposal.isAwaitingConfirmation {
            return "Confirmation requise"
        }
        switch proposal.alertLevelEnum {
        case .red:
            return "Action requise"
        case .orange:
            return "Alerte modérée"
        case .yellow:
            return "Attention"
        case .positiveReadiness, .positiveBreakthrough, .positiveEfficiency:
            return "Opportunité"
        default:
            return "Proposition"
        }
    }

    private func alertIcon(for level: AlertLevel) -> String {
        level.icon
    }

    private func alertColor(for level: AlertLevel) -> Color {
        switch level {
        case .none, .green:
            return .green
        case .yellow, .warning:
            return .yellow
        case .orange:
            return .orange
        case .red:
            return .red
        case .positiveReadiness, .positiveBreakthrough, .positiveEfficiency:
            return .blue
        }
    }

    private func bannerBackground(for level: AlertLevel) -> Color {
        alertColor(for: level).opacity(0.1)
    }
}

// MARK: - Compact Badge (for TabView or Navigation)

struct ComplianceBadge: View {
    let count: Int
    let isUrgent: Bool

    var body: some View {
        if count > 0 {
            ZStack {
                Circle()
                    .fill(isUrgent ? Color.red : Color.orange)
                    .frame(width: 18, height: 18)

                Text("\(min(count, 9))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Mini Alert Indicator (for Dashboard header)

struct ComplianceIndicator: View {
    @EnvironmentObject var themeManager: ThemeManager
    let alert: ComplianceAlert?
    let proposalCount: Int

    var body: some View {
        HStack(spacing: 6) {
            if let alert = alert, alert.hasAlert {
                Image(systemName: alert.level.icon)
                    .font(.system(size: 14))
                    .foregroundColor(indicatorColor)
            }

            if proposalCount > 0 {
                Text("\(proposalCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(indicatorColor)
                    .clipShape(Circle())
            }
        }
    }

    private var indicatorColor: Color {
        guard let alert = alert else { return .orange }
        switch alert.level {
        case .red: return .red
        case .orange: return .orange
        case .yellow, .warning: return .yellow
        case .positiveReadiness, .positiveBreakthrough, .positiveEfficiency: return .blue
        default: return .green
        }
    }
}

// MARK: - Preview

#Preview("Proposal Banner") {
    VStack(spacing: 16) {
        // Simuler un ViewModel avec données
        Text("Compliance Banners")
            .font(.headline)

        // Banner statique pour preview
        HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)

                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .offset(x: 4, y: -4)
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Alerte modérée")
                        .font(.system(size: 14, weight: .semibold))

                    Text("+2")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .cornerRadius(8)
                }

                Text("Fatigue détectée sur les 3 dernières séances")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("8h")
                        .font(.system(size: 10))
                }
                .foregroundColor(.red)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .padding()

        // Badges
        HStack(spacing: 20) {
            ComplianceBadge(count: 3, isUrgent: true)
            ComplianceBadge(count: 1, isUrgent: false)
            ComplianceBadge(count: 0, isUrgent: false)
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
