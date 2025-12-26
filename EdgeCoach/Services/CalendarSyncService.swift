/**
 * CalendarSyncService
 * Synchronisation des séances planifiées avec le calendrier iOS (EventKit)
 * Synchronisation unidirectionnelle : App → Calendrier iOS
 */

import Foundation
import EventKit
import UIKit

// MARK: - Calendar Sync Error

enum CalendarSyncError: LocalizedError {
    case accessDenied
    case accessRestricted
    case calendarNotFound
    case eventCreationFailed
    case eventUpdateFailed
    case eventDeletionFailed
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "L'accès au calendrier a été refusé. Activez-le dans Réglages > EdgeCoach."
        case .accessRestricted:
            return "L'accès au calendrier est restreint sur cet appareil."
        case .calendarNotFound:
            return "Impossible de trouver ou créer le calendrier EdgeCoach."
        case .eventCreationFailed:
            return "Échec de la création de l'événement."
        case .eventUpdateFailed:
            return "Échec de la mise à jour de l'événement."
        case .eventDeletionFailed:
            return "Échec de la suppression de l'événement."
        case .unknown(let error):
            return "Erreur inattendue : \(error.localizedDescription)"
        }
    }
}

// MARK: - Calendar Sync Status

enum CalendarSyncStatus {
    case notRequested
    case authorized
    case denied
    case restricted
}

// MARK: - Calendar Sync Service

@MainActor
class CalendarSyncService: ObservableObject {
    static let shared = CalendarSyncService()

    private let eventStore = EKEventStore()
    private let calendarName = "EdgeCoach"
    private let mappingKey = "CalendarSyncMapping"
    private let enabledKey = "CalendarSyncEnabled"
    private let calendarIdentifierKey = "EdgeCoachCalendarIdentifier"

    @Published private(set) var syncStatus: CalendarSyncStatus = .notRequested
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: enabledKey)
        }
    }

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        updateSyncStatus()
    }

    // MARK: - Authorization

    /// Met à jour le statut de synchronisation basé sur les permissions actuelles
    private func updateSyncStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            syncStatus = .notRequested
        case .restricted:
            syncStatus = .restricted
        case .denied:
            syncStatus = .denied
        case .fullAccess, .writeOnly:
            syncStatus = .authorized
        @unknown default:
            syncStatus = .notRequested
        }
    }

    /// Demande l'accès au calendrier
    func requestAccess() async -> Bool {
        do {
            // iOS 17+ : demander l'accès en écriture seule (moins intrusif)
            if #available(iOS 17.0, *) {
                let granted = try await eventStore.requestWriteOnlyAccessToEvents()
                syncStatus = granted ? .authorized : .denied
                return granted
            } else {
                // iOS 16 et moins : accès complet
                let granted = try await eventStore.requestAccess(to: .event)
                syncStatus = granted ? .authorized : .denied
                return granted
            }
        } catch {
            print("❌ CalendarSync: Erreur demande d'accès - \(error)")
            syncStatus = .denied
            return false
        }
    }

    /// Vérifie si l'accès est autorisé
    var hasAccess: Bool {
        syncStatus == .authorized
    }

    // MARK: - Calendar Management

    /// Récupère ou crée le calendrier EdgeCoach, avec fallback sur le calendrier par défaut
    private func getOrCreateCalendar() throws -> EKCalendar {
        // 1. Vérifier si on a déjà un identifiant stocké et valide
        if let savedId = UserDefaults.standard.string(forKey: calendarIdentifierKey),
           let calendar = eventStore.calendar(withIdentifier: savedId) {
            return calendar
        }

        // 2. Chercher un calendrier existant avec le bon nom
        if let existingCalendar = eventStore.calendars(for: .event).first(where: { $0.title == calendarName }) {
            UserDefaults.standard.set(existingCalendar.calendarIdentifier, forKey: calendarIdentifierKey)
            print("✅ CalendarSync: Calendrier '\(calendarName)' existant trouvé")
            return existingCalendar
        }

        // 3. Essayer de créer un nouveau calendrier (source locale uniquement)
        if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            do {
                let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
                newCalendar.title = calendarName
                newCalendar.source = localSource
                newCalendar.cgColor = UIColor.systemBlue.cgColor

                try eventStore.saveCalendar(newCalendar, commit: true)
                UserDefaults.standard.set(newCalendar.calendarIdentifier, forKey: calendarIdentifierKey)

                print("✅ CalendarSync: Calendrier '\(calendarName)' créé (local)")
                return newCalendar
            } catch {
                print("⚠️ CalendarSync: Impossible de créer un calendrier local - \(error.localizedDescription)")
            }
        }

        // 4. Fallback : utiliser le calendrier par défaut de l'utilisateur
        if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
            UserDefaults.standard.set(defaultCalendar.calendarIdentifier, forKey: calendarIdentifierKey)
            print("✅ CalendarSync: Utilisation du calendrier par défaut '\(defaultCalendar.title)'")
            return defaultCalendar
        }

        // 5. Dernier recours : prendre le premier calendrier modifiable
        if let anyCalendar = eventStore.calendars(for: .event).first(where: { $0.allowsContentModifications }) {
            UserDefaults.standard.set(anyCalendar.calendarIdentifier, forKey: calendarIdentifierKey)
            print("✅ CalendarSync: Utilisation du calendrier '\(anyCalendar.title)'")
            return anyCalendar
        }

        throw CalendarSyncError.calendarNotFound
    }

    // MARK: - Mapping Storage

    /// Récupère le mapping canonicalId → eventIdentifier
    private func getMapping() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: mappingKey) as? [String: String] ?? [:]
    }

    /// Sauvegarde le mapping
    private func saveMapping(_ mapping: [String: String]) {
        UserDefaults.standard.set(mapping, forKey: mappingKey)
    }

    // MARK: - Sync Operations

    /// Synchronise toutes les sessions d'un cycle avec le calendrier iOS
    func syncCycle(_ cyclePlan: CyclePlanData) async throws {
        guard isEnabled else {
            print("📅 CalendarSync: Synchronisation désactivée")
            return
        }

        if !hasAccess {
            let granted = await requestAccess()
            guard granted else {
                throw CalendarSyncError.accessDenied
            }
        }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let calendar = try getOrCreateCalendar()
            var mapping = getMapping()
            let sessions = cyclePlan.allSessions

            // Identifiants des sessions actuelles
            let currentSessionIds = Set(sessions.map { $0.canonicalId })

            // Supprimer les événements des sessions qui ne sont plus dans le cycle
            for (canonicalId, eventId) in mapping {
                if !currentSessionIds.contains(canonicalId) {
                    if let event = eventStore.event(withIdentifier: eventId) {
                        try? eventStore.remove(event, span: .thisEvent, commit: false)
                        mapping.removeValue(forKey: canonicalId)
                        print("🗑️ CalendarSync: Événement supprimé pour session \(canonicalId)")
                    }
                }
            }

            // Créer ou mettre à jour les événements pour chaque session
            for session in sessions {
                if let existingEventId = mapping[session.canonicalId],
                   let existingEvent = eventStore.event(withIdentifier: existingEventId) {
                    // Mettre à jour l'événement existant
                    updateEvent(existingEvent, with: session)
                    try eventStore.save(existingEvent, span: .thisEvent, commit: false)
                    print("🔄 CalendarSync: Événement mis à jour - \(session.sessionName)")
                } else {
                    // Créer un nouvel événement
                    let event = createEvent(for: session, in: calendar)
                    try eventStore.save(event, span: .thisEvent, commit: false)
                    mapping[session.canonicalId] = event.eventIdentifier
                    print("➕ CalendarSync: Événement créé - \(session.sessionName)")
                }
            }

            // Commit toutes les modifications
            try eventStore.commit()
            saveMapping(mapping)
            lastSyncDate = Date()

            print("✅ CalendarSync: Synchronisation terminée - \(sessions.count) sessions")

        } catch {
            print("❌ CalendarSync: Erreur de synchronisation - \(error)")
            throw CalendarSyncError.unknown(error)
        }
    }

    /// Synchronise une seule session (après déplacement par exemple)
    func syncSession(_ session: CycleSession) async throws {
        guard isEnabled && hasAccess else { return }

        do {
            let calendar = try getOrCreateCalendar()
            var mapping = getMapping()

            if let existingEventId = mapping[session.canonicalId],
               let existingEvent = eventStore.event(withIdentifier: existingEventId) {
                updateEvent(existingEvent, with: session)
                try eventStore.save(existingEvent, span: .thisEvent, commit: true)
            } else {
                let event = createEvent(for: session, in: calendar)
                try eventStore.save(event, span: .thisEvent, commit: true)
                mapping[session.canonicalId] = event.eventIdentifier
                saveMapping(mapping)
            }

            print("✅ CalendarSync: Session synchronisée - \(session.sessionName)")

        } catch {
            print("❌ CalendarSync: Erreur sync session - \(error)")
            throw CalendarSyncError.unknown(error)
        }
    }

    /// Supprime tous les événements EdgeCoach du calendrier
    func clearAllEvents() async throws {
        guard hasAccess else { return }

        do {
            guard let calendar = try? getOrCreateCalendar() else { return }

            // Récupérer tous les événements du calendrier EdgeCoach
            let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
            let endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
            let predicate = eventStore.predicateForEvents(
                withStart: startDate,
                end: endDate,
                calendars: [calendar]
            )

            let events = eventStore.events(matching: predicate)
            for event in events {
                try eventStore.remove(event, span: .thisEvent, commit: false)
            }

            try eventStore.commit()
            saveMapping([:])

            print("🗑️ CalendarSync: Tous les événements supprimés")

        } catch {
            throw CalendarSyncError.eventDeletionFailed
        }
    }

    // MARK: - Event Creation

    /// Crée un événement iOS à partir d'une CycleSession
    private func createEvent(for session: CycleSession, in calendar: EKCalendar) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        updateEvent(event, with: session)
        event.calendar = calendar
        return event
    }

    /// Met à jour un événement avec les données d'une session
    private func updateEvent(_ event: EKEvent, with session: CycleSession) {
        // Titre avec emoji sport
        let sportEmoji = session.discipline.emoji
        event.title = "\(sportEmoji) \(session.sessionName)"

        // Date et durée
        if let startDate = session.dateValue {
            // Par défaut, séance à 7h du matin (modifiable par l'utilisateur dans Calendrier iOS)
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: startDate)
            components.hour = 7
            components.minute = 0

            if let eventStart = calendar.date(from: components) {
                event.startDate = eventStart
                event.endDate = calendar.date(byAdding: .minute, value: session.effectiveDuration, to: eventStart)
            }
        }

        // Notes avec détails de la séance
        var notes = [String]()

        if let intensity = session.intensity {
            notes.append("Intensité : \(intensity)")
        }

        if let distance = session.formattedDistance {
            notes.append("Distance : \(distance)")
        }

        notes.append("Durée : \(session.formattedDuration)")

        if let tss = session.formattedTss {
            notes.append("TSS estimé : \(tss)")
        }

        if let description = session.description, !description.isEmpty {
            notes.append("\n\(description)")
        }

        if let workout = session.workoutDescription, !workout.isEmpty {
            notes.append("\n📋 Séance :\n\(workout)")
        }

        if let coach = session.coachDescription, !coach.isEmpty {
            notes.append("\n💬 Coach :\n\(coach)")
        }

        notes.append("\n— Synchronisé depuis EdgeCoach")

        event.notes = notes.joined(separator: "\n")

        // Alarme 1h avant
        event.alarms = [EKAlarm(relativeOffset: -3600)]
    }
}

// MARK: - Discipline Extension

private extension Discipline {
    var emoji: String {
        switch self {
        case .cyclisme: return "🚴"
        case .course: return "🏃"
        case .natation: return "🏊"
        case .autre: return "💪"
        }
    }
}
