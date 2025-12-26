/**
 * ProposalValidationSheet - Interface de validation 2-étapes
 *
 * Flow UX:
 * ┌─────────────────────────────────────────────┐
 * │ ÉTAPE 1: Sélection d'option                 │
 * │                                             │
 * │ [Contexte de l'alerte]                      │
 * │                                             │
 * │ Options proposées:                          │
 * │ ┌─────────────────────────────────────────┐ │
 * │ │ Option A: Réduire volume (-20%)         │ │
 * │ │ Risque: Faible | 3 jours affectés       │ │
 * │ └─────────────────────────────────────────┘ │
 * │ ┌─────────────────────────────────────────┐ │
 * │ │ Option B: Ajouter repos                 │ │
 * │ │ Risque: Moyen | 1 jour affecté          │ │
 * │ └─────────────────────────────────────────┘ │
 * │                                             │
 * │ [Commentaire optionnel]                     │
 * │                                             │
 * │         [Sélectionner cette option]         │
 * └─────────────────────────────────────────────┘
 *
 * ┌─────────────────────────────────────────────┐
 * │ ÉTAPE 2: Confirmation                       │
 * │                                             │
 * │ Vous avez choisi:                           │
 * │ "Réduire le volume de 20%"                  │
 * │                                             │
 * │ Cette modification affectera 3 séances      │
 * │ à partir du: [Date Picker]                  │
 * │                                             │
 * │   [Annuler]         [Confirmer]             │
 * └─────────────────────────────────────────────┘
 */

import SwiftUI

// MARK: - Proposal Detail Sheet (Step 1)

struct ProposalDetailSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: ComplianceViewModel
    @Environment(\.dismiss) private var dismiss
    let userId: String

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    // Header avec niveau d'alerte
                    alertHeader

                    // Contexte
                    contextSection

                    // Options
                    optionsSection

                    // Commentaire optionnel
                    commentSection

                    // Bouton de sélection
                    selectButton
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Proposition d'adaptation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        viewModel.closeProposalDetail()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Alert Header

    private var alertHeader: some View {
        HStack(spacing: ECSpacing.md) {
            Image(systemName: alertIcon)
                .font(.system(size: 32))
                .foregroundColor(alertColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(alertTitle)
                    .font(.ecH3)
                    .foregroundColor(themeManager.textPrimary)

                if let proposal = viewModel.selectedProposal {
                    HStack(spacing: 8) {
                        Label(proposal.stage.replacingOccurrences(of: "_", with: " ").capitalized,
                              systemImage: "arrow.triangle.2.circlepath")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)

                        if proposal.isUrgent {
                            Label("Urgent", systemImage: "clock.badge.exclamationmark")
                                .font(.ecCaption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            Spacer()

            // Time remaining
            if let proposal = viewModel.selectedProposal {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Expire dans")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.textTertiary)
                    Text(formatTimeRemaining(proposal.timeRemainingHours))
                        .font(.ecLabelBold)
                        .foregroundColor(proposal.isUrgent ? .red : themeManager.textSecondary)
                }
            }
        }
        .padding()
        .background(alertColor.opacity(0.1))
        .cornerRadius(ECRadius.lg)
    }

    // MARK: - Context Section

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Label("Contexte", systemImage: "info.circle")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            if let proposal = viewModel.selectedProposal {
                Text(proposal.context)
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.md)
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Label("Options proposées", systemImage: "list.bullet")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            if let proposal = viewModel.selectedProposal {
                ForEach(proposal.options) { option in
                    OptionCard(
                        option: option,
                        isSelected: viewModel.selectedOptionId == option.optionId,
                        onSelect: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedOptionId = option.optionId
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Comment Section

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Label("Commentaire (optionnel)", systemImage: "text.bubble")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            TextField("Ajouter un commentaire...", text: $viewModel.userComment, axis: .vertical)
                .textFieldStyle(.plain)
                .padding()
                .background(themeManager.elevatedColor)
                .cornerRadius(ECRadius.md)
                .lineLimit(3...6)
        }
    }

    // MARK: - Select Button

    private var selectButton: some View {
        Button {
            Task {
                if let optionId = viewModel.selectedOptionId {
                    await viewModel.selectOption(userId: userId, optionId: optionId)
                }
            }
        } label: {
            HStack {
                if viewModel.isSelecting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Sélectionner cette option")
                        .font(.ecButton)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.selectedOptionId != nil ? themeManager.accentColor : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(ECRadius.lg)
        }
        .disabled(viewModel.selectedOptionId == nil || viewModel.isSelecting)
        .buttonStyle(.premium)
    }

    // MARK: - Helpers

    private var alertIcon: String {
        viewModel.selectedProposal?.alertLevelEnum.icon ?? "exclamationmark.triangle"
    }

    private var alertColor: Color {
        guard let level = viewModel.selectedProposal?.alertLevelEnum else { return .orange }
        switch level {
        case .red: return .red
        case .orange: return .orange
        case .yellow, .warning: return .yellow
        case .positiveReadiness, .positiveBreakthrough, .positiveEfficiency: return .blue
        default: return .green
        }
    }

    private var alertTitle: String {
        guard let level = viewModel.selectedProposal?.alertLevelEnum else { return "Proposition" }
        return level.displayName
    }

    private func formatTimeRemaining(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60)) min"
        } else if hours < 24 {
            return "\(Int(hours))h"
        } else {
            return "\(Int(hours / 24))j \(Int(hours.truncatingRemainder(dividingBy: 24)))h"
        }
    }
}

// MARK: - Option Card

struct OptionCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let option: ProposalOption
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: ECSpacing.md) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.textTertiary)

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(option.formattedDescription)
                        .font(.ecLabel)
                        .foregroundColor(themeManager.textPrimary)
                        .multilineTextAlignment(.leading)

                    Text(option.rationale ?? "")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                        .multilineTextAlignment(.leading)

                    // Metadata row
                    HStack(spacing: ECSpacing.md) {
                        // Risk level
                        HStack(spacing: 4) {
                            Circle()
                                .fill(riskColor)
                                .frame(width: 8, height: 8)
                            Text("Risque: \(option.riskLevelEnum.displayName)")
                                .font(.ecSmall)
                                .foregroundColor(themeManager.textTertiary)
                        }

                        // Affected days
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text("\(option.affectedDays ?? 0) jour(s)")
                                .font(.ecSmall)
                        }
                        .foregroundColor(themeManager.textTertiary)

                        // Modulation factor
                        if let modFactor = option.modulationFactor, modFactor != 1.0 {
                            HStack(spacing: 4) {
                                Image(systemName: modFactor < 1.0 ? "arrow.down" : "arrow.up")
                                    .font(.system(size: 10))
                                Text("\(Int((1.0 - modFactor) * -100))%")
                                    .font(.ecSmall)
                            }
                            .foregroundColor(modFactor < 1.0 ? .orange : .green)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .background(isSelected ? themeManager.accentColor.opacity(0.1) : themeManager.cardColor)
            .cornerRadius(ECRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.md)
                    .stroke(isSelected ? themeManager.accentColor : themeManager.borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.premium)
    }

    private var riskColor: Color {
        switch option.riskLevelEnum {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}

// MARK: - Confirmation Sheet (Step 2)

struct ProposalConfirmationSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: ComplianceViewModel
    @Environment(\.dismiss) private var dismiss
    let userId: String

    var body: some View {
        NavigationView {
            VStack(spacing: ECSpacing.xl) {
                Spacer()

                // Summary
                confirmationSummary

                // Date picker
                datePickerSection

                Spacer()

                // Action buttons
                actionButtons

                // Error message
                if let error = viewModel.error {
                    Text(error)
                        .font(.ecCaption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .padding()
            .background(themeManager.backgroundColor)
            .navigationTitle("Confirmation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Retour") {
                        viewModel.cancelConfirmation()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Confirmation Summary

    private var confirmationSummary: some View {
        VStack(spacing: ECSpacing.lg) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 48))
                .foregroundColor(themeManager.accentColor)

            Text("Vous avez choisi:")
                .font(.ecLabel)
                .foregroundColor(themeManager.textSecondary)

            if let option = viewModel.selectedOption {
                Text(option.formattedDescription)
                    .font(.ecH3)
                    .foregroundColor(themeManager.textPrimary)
                    .multilineTextAlignment(.center)

                HStack(spacing: ECSpacing.lg) {
                    VStack {
                        Text("\(option.affectedDays ?? 0)")
                            .font(.ecH2)
                            .foregroundColor(themeManager.textPrimary)
                        Text("jour(s) affecté(s)")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }

                    if let modFactor = option.modulationFactor, modFactor != 1.0 {
                        VStack {
                            Text("\(Int((1.0 - modFactor) * -100))%")
                                .font(.ecH2)
                                .foregroundColor(modFactor < 1.0 ? .orange : .green)
                            Text("de charge")
                                .font(.ecCaption)
                                .foregroundColor(themeManager.textSecondary)
                        }
                    }
                }
                .padding()
                .background(themeManager.elevatedColor)
                .cornerRadius(ECRadius.md)
            }
        }
    }

    // MARK: - Date Picker Section

    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Label("Appliquer à partir de", systemImage: "calendar")
                .font(.ecLabelBold)
                .foregroundColor(themeManager.textPrimary)

            DatePicker(
                "",
                selection: $viewModel.applyFromDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.md)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: ECSpacing.md) {
            // Cancel button
            Button {
                Task {
                    await viewModel.confirmSelection(userId: userId, confirmed: false)
                    dismiss()
                }
            } label: {
                Text("Annuler")
                    .font(.ecButton)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.elevatedColor)
                    .foregroundColor(themeManager.textPrimary)
                    .cornerRadius(ECRadius.lg)
            }
            .buttonStyle(.premium)

            // Confirm button
            Button {
                Task {
                    await viewModel.confirmSelection(userId: userId, confirmed: true)
                    dismiss()
                }
            } label: {
                HStack {
                    if viewModel.isConfirming {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Confirmer")
                            .font(.ecButton)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeManager.accentColor)
                .foregroundColor(.white)
                .cornerRadius(ECRadius.lg)
            }
            .disabled(viewModel.isConfirming)
            .buttonStyle(.premium)
        }
    }
}

// MARK: - Result Sheet

struct ProposalResultSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: ComplianceViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: ECSpacing.xl) {
            Spacer()

            if let result = viewModel.lastResult {
                // Icon
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(result.success ? .green : .red)

                // Title
                Text(result.success ? "Modification appliquée" : "Erreur")
                    .font(.ecH2)
                    .foregroundColor(themeManager.textPrimary)

                // Message
                Text(result.message)
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
                    .multilineTextAlignment(.center)

                if result.isApplied {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("Votre plan a été mis à jour")
                            .font(.ecCaption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(ECRadius.md)
                }
            }

            Spacer()

            // Close button
            Button {
                viewModel.dismissResult()
                dismiss()
            } label: {
                Text("Fermer")
                    .font(.ecButton)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(ECRadius.lg)
            }
            .buttonStyle(.premium)
        }
        .padding()
        .background(themeManager.backgroundColor)
    }
}

// MARK: - Preview

#Preview("Option Card") {
    VStack(spacing: 16) {
        // Selected option
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 6) {
                Text("Réduire le volume de 20%")
                    .font(.system(size: 14, weight: .medium))

                Text("Permet de récupérer tout en maintenant la forme")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Text("Risque: Faible")
                            .font(.system(size: 10))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "calendar").font(.system(size: 10))
                        Text("3 jour(s)")
                            .font(.system(size: 10))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down").font(.system(size: 10))
                        Text("-20%")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.orange)
                }
                .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue, lineWidth: 2)
        )

        // Unselected option
        HStack(spacing: 12) {
            Image(systemName: "circle")
                .font(.system(size: 24))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Ajouter un jour de repos")
                    .font(.system(size: 14, weight: .medium))

                Text("Récupération complète avant la prochaine séance")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle().fill(Color.yellow).frame(width: 8, height: 8)
                        Text("Risque: Modéré")
                            .font(.system(size: 10))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "calendar").font(.system(size: 10))
                        Text("1 jour(s)")
                            .font(.system(size: 10))
                    }
                }
                .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
