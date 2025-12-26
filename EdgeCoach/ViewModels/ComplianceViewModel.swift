/**
 * ComplianceViewModel - Gestion des alertes et propositions d'adaptation
 *
 * Ce ViewModel orchestre le flux de validation 2-étapes:
 * 1. Sélection d'une option parmi les proposées
 * 2. Confirmation finale avant application au plan
 *
 * Architecture:
 *   ComplianceViewModel
 *        │
 *        ├── pendingProposals: [ProposalView]    → Alertes en attente
 *        ├── activeAlert: ComplianceAlert?       → Alerte en cours
 *        ├── selectedProposal: ProposalView?     → Proposal sélectionnée pour détail
 *        │
 *        ├── selectOption()   → Étape 1 (choix)
 *        └── confirmSelection() → Étape 2 (application)
 */

import SwiftUI
import Combine

@MainActor
class ComplianceViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Propositions en attente de validation
    @Published var pendingProposals: [ProposalView] = []

    /// Alerte active (niveau actuel de compliance)
    @Published var activeAlert: ComplianceAlert?

    /// Tendances de compliance
    @Published var complianceTrend: ComplianceTrend?

    /// Historique des propositions passées
    @Published var proposalHistory: [ProposalView] = []

    // MARK: - Selection Flow State

    /// Proposition actuellement sélectionnée pour affichage détaillé
    @Published var selectedProposal: ProposalView?

    /// Option choisie dans la proposition (étape 1)
    @Published var selectedOptionId: String?

    /// Commentaire utilisateur (optionnel)
    @Published var userComment: String = ""

    /// Date d'application (défaut: aujourd'hui)
    @Published var applyFromDate: Date = Date()

    // MARK: - UI State

    @Published var isLoading: Bool = false
    @Published var isSelecting: Bool = false
    @Published var isConfirming: Bool = false
    @Published var error: String?

    /// Affiche la sheet de détail d'une proposition
    @Published var showProposalDetail: Bool = false

    /// Affiche la sheet de confirmation (étape 2)
    @Published var showConfirmationSheet: Bool = false

    /// Affiche le résultat après confirmation
    @Published var showResultSheet: Bool = false

    /// Résultat de la dernière opération
    @Published var lastResult: OperationResult?

    // MARK: - Badge State

    /// Nombre de propositions urgentes (< 12h)
    var urgentProposalsCount: Int {
        pendingProposals.filter { $0.isUrgent }.count
    }

    /// Indique si une attention est requise
    var requiresAttention: Bool {
        !pendingProposals.isEmpty || (activeAlert?.hasAlert ?? false)
    }

    /// Badge count pour l'icône
    var badgeCount: Int {
        pendingProposals.count
    }

    // MARK: - Services

    private let complianceService = ComplianceService.shared

    // MARK: - Cache

    private var lastLoadedUserId: String?
    private var lastLoadTime: Date?
    private let cacheValidityDuration: TimeInterval = 60 // 60 secondes

    // MARK: - Result Model

    struct OperationResult {
        let success: Bool
        let message: String
        let isApplied: Bool

        static func selection(success: Bool, message: String) -> OperationResult {
            OperationResult(success: success, message: message, isApplied: false)
        }

        static func confirmation(success: Bool, message: String, applied: Bool) -> OperationResult {
            OperationResult(success: success, message: message, isApplied: applied)
        }
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Load Data

    /// Charge toutes les données compliance pour un utilisateur
    func loadData(userId: String, forceRefresh: Bool = false) async {
        // Vérifier le cache
        if !forceRefresh,
           lastLoadedUserId == userId,
           let lastLoad = lastLoadTime,
           Date().timeIntervalSince(lastLoad) < cacheValidityDuration,
           !pendingProposals.isEmpty || activeAlert != nil {
            return
        }

        isLoading = true
        error = nil

        await withTaskGroup(of: Void.self) { group in
            // Charger les propositions en attente
            group.addTask {
                await self.loadPendingProposals(userId: userId)
            }

            // Charger l'alerte active
            group.addTask {
                await self.loadActiveAlert(userId: userId)
            }

            // Charger les tendances
            group.addTask {
                await self.loadTrend(userId: userId)
            }
        }

        // Mettre à jour le cache
        lastLoadedUserId = userId
        lastLoadTime = Date()

        isLoading = false
    }

    /// Rafraîchit les données
    func refresh(userId: String) async {
        await loadData(userId: userId, forceRefresh: true)
    }

    // MARK: - Private Load Methods

    private func loadPendingProposals(userId: String) async {
        do {
            pendingProposals = try await complianceService.getPendingProposals(userId: userId)
        } catch {
            // Erreur silencieuse - les propositions restent vides
            #if DEBUG
            print("ComplianceVM: Failed to load pending proposals: \(error)")
            #endif
        }
    }

    private func loadActiveAlert(userId: String) async {
        do {
            activeAlert = try await complianceService.getActiveAlert(userId: userId)
        } catch {
            // Erreur silencieuse
            #if DEBUG
            print("ComplianceVM: Failed to load active alert: \(error)")
            #endif
        }
    }

    private func loadTrend(userId: String) async {
        do {
            complianceTrend = try await complianceService.getTrend(userId: userId, days: 30)
        } catch {
            // Erreur silencieuse
            #if DEBUG
            print("ComplianceVM: Failed to load trend: \(error)")
            #endif
        }
    }

    private func loadHistory(userId: String) async {
        do {
            proposalHistory = try await complianceService.getProposalsHistory(userId: userId, days: 30)
        } catch {
            // Erreur silencieuse
            #if DEBUG
            print("ComplianceVM: Failed to load history: \(error)")
            #endif
        }
    }

    // MARK: - Selection Flow (Step 1)

    /// Ouvre le détail d'une proposition
    func openProposal(_ proposal: ProposalView) {
        selectedProposal = proposal
        selectedOptionId = proposal.selectedOptionId
        userComment = ""
        showProposalDetail = true
    }

    /// Ferme le détail
    func closeProposalDetail() {
        showProposalDetail = false
        // Garder selectedProposal pour animation de fermeture
    }

    /// Sélectionne une option (Étape 1)
    func selectOption(userId: String, optionId: String) async {
        guard let proposal = selectedProposal else { return }

        isSelecting = true
        error = nil

        do {
            let result = try await complianceService.selectOption(
                userId: userId,
                proposalId: proposal.proposalId,
                optionId: optionId,
                userComment: userComment.isEmpty ? nil : userComment
            )

            if result.success {
                selectedOptionId = optionId

                // Si awaiting_confirmation, ouvrir la sheet de confirmation
                if result.isAwaitingConfirmation {
                    showProposalDetail = false
                    showConfirmationSheet = true
                }

                lastResult = .selection(success: true, message: result.message)
            } else {
                error = result.message
                lastResult = .selection(success: false, message: result.message)
            }

        } catch {
            self.error = "Erreur lors de la sélection: \(error.localizedDescription)"
            lastResult = .selection(success: false, message: self.error!)
        }

        isSelecting = false
    }

    // MARK: - Confirmation Flow (Step 2)

    /// Confirme la sélection (Étape 2 - applique les modifications)
    func confirmSelection(userId: String, confirmed: Bool) async {
        guard let proposal = selectedProposal else { return }

        isConfirming = true
        error = nil

        do {
            let result = try await complianceService.confirmSelection(
                userId: userId,
                proposalId: proposal.proposalId,
                confirmed: confirmed,
                applyFromDate: applyFromDate
            )

            if result.success {
                showConfirmationSheet = false

                lastResult = .confirmation(
                    success: true,
                    message: result.message,
                    applied: result.applied
                )

                showResultSheet = true

                // Recharger les propositions
                await loadPendingProposals(userId: userId)

                // Reset de l'état
                selectedProposal = nil
                selectedOptionId = nil
                userComment = ""

            } else {
                error = result.message
                lastResult = .confirmation(success: false, message: result.message, applied: false)
            }

        } catch {
            self.error = "Erreur lors de la confirmation: \(error.localizedDescription)"
            lastResult = .confirmation(success: false, message: self.error!, applied: false)
        }

        isConfirming = false
    }

    /// Annule la confirmation et retourne à la sélection
    func cancelConfirmation() {
        showConfirmationSheet = false
        showProposalDetail = true
    }

    // MARK: - Result Handling

    /// Ferme la sheet de résultat
    func dismissResult() {
        showResultSheet = false
        lastResult = nil
    }

    // MARK: - Helpers

    /// Retourne l'option sélectionnée pour la proposition courante
    var selectedOption: ProposalOption? {
        guard let optionId = selectedOptionId,
              let proposal = selectedProposal else { return nil }
        return proposal.options.first { $0.optionId == optionId }
    }

    /// Retourne la couleur associée au niveau d'alerte actif
    var alertColor: Color {
        guard let alert = activeAlert else { return .clear }
        switch alert.level {
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

    /// Indique si l'utilisateur a des alertes positives (opportunités)
    var hasPositiveAlert: Bool {
        activeAlert?.isPositive ?? false
    }

    /// Indique si l'utilisateur a des alertes négatives (fatigue)
    var hasNegativeAlert: Bool {
        guard let alert = activeAlert else { return false }
        return alert.hasAlert && !alert.isPositive
    }

    /// Première proposition urgente (pour affichage dans banner)
    var mostUrgentProposal: ProposalView? {
        pendingProposals
            .filter { $0.isUrgent }
            .sorted { $0.timeRemainingHours < $1.timeRemainingHours }
            .first ?? pendingProposals.first
    }

    /// Temps restant formaté pour la proposition la plus urgente
    var urgentTimeRemaining: String? {
        guard let proposal = mostUrgentProposal else { return nil }
        let hours = proposal.timeRemainingHours
        if hours < 1 {
            let minutes = Int(hours * 60)
            return "\(minutes) min"
        } else if hours < 24 {
            return "\(Int(hours))h"
        } else {
            let days = Int(hours / 24)
            return "\(days)j"
        }
    }
}
