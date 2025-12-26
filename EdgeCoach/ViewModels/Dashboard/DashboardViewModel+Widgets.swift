// MARK: - Dashboard ViewModel + Widgets

import Foundation

extension DashboardViewModel {
    
    // MARK: - Widget Preferences Save

    func debouncedSavePreferences() {
        // Annuler la tâche précédente si elle existe
        savePreferencesTask?.cancel()

        // Créer une nouvelle tâche avec délai
        savePreferencesTask = Task {
            do {
                try await Task.sleep(nanoseconds: saveDebounceDelay)
                // Vérifier que la tâche n'a pas été annulée
                if !Task.isCancelled {
                    savePreferencesImmediately()
                }
            } catch {
                // Task was cancelled, ignore
            }
        }
    }

    func savePreferencesImmediately() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "dashboard_preferences")
        }
    }

    func debouncedSaveWidgetPreferences() {
        saveWidgetPreferencesTask?.cancel()
        saveWidgetPreferencesTask = Task {
            do {
                try await Task.sleep(nanoseconds: saveDebounceDelay)
                if !Task.isCancelled {
                    saveWidgetPreferencesImmediately()
                }
            } catch {
                // Task cancelled
            }
        }
    }

    func saveWidgetPreferencesImmediately() {
        if let encoded = try? JSONEncoder().encode(widgetPreferences) {
            UserDefaults.standard.set(encoded, forKey: "dashboard_widgets_preferences")
        }
    }

    // MARK: - Widget Helpers

    func isWidgetEnabled(_ type: DashboardWidgetType) -> Bool {
        widgetPreferences.widgets.first { $0.type == type }?.isEnabled ?? false
    }

    func enabledWidgetTypes() -> [DashboardWidgetType] {
        widgetPreferences.enabledWidgets.map { $0.type }
    }
}
