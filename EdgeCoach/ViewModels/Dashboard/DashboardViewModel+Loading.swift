// MARK: - Dashboard ViewModel + Data Loading

import Foundation

extension DashboardViewModel {
    
    // MARK: - Load Data

    func loadData(userId: String, forceRefresh: Bool = false) async {
        // Vérifier si le cache est encore valide
        if !forceRefresh,
           lastLoadedUserId == userId,
           let lastLoad = lastLoadTime,
           Date().timeIntervalSince(lastLoad) < cacheValidityDuration,
           weeklySummaryData != nil {
            // Cache valide, pas besoin de recharger
            return
        }

        isLoading = true
        error = nil

        await withTaskGroup(of: Void.self) { group in
            // Load weekly summary
            group.addTask {
                await self.loadWeeklySummary(userId: userId)
            }

            // Load recent activities
            group.addTask {
                await self.loadRecentActivities(userId: userId)
            }

            // Load planned sessions
            group.addTask {
                await self.loadPlannedSessions(userId: userId)
            }

            // Load performance report (for performance cards)
            group.addTask {
                await self.loadPerformanceReport(userId: userId)
            }

            // Load training load
            // group.addTask {
            //     await self.loadTrainingLoad(userId: userId)
            // }

            // Load macro plan
            group.addTask {
                await self.loadMacroPlan(userId: userId)
            }

            // Load PMC status
            group.addTask {
                await self.loadPMCStatus(userId: userId)
            }
        }

        // Mettre à jour les valeurs cachées après le chargement
        updateCachedSportFlags()

        // Marquer le cache comme valide
        lastLoadedUserId = userId
        lastLoadTime = Date()

        isLoading = false
    }

    // MARK: - Refresh

    func refresh(userId: String) async {
        isRefreshing = true
        await loadData(userId: userId, forceRefresh: true) // Force refresh bypass le cache
        isRefreshing = false
    }

    // MARK: - Load Weekly Summary

    func loadWeeklySummary(userId: String) async {
        do {
            weeklySummaryData = try await dashboardService.getWeeklySummary(userId: userId)
            #if DEBUG
            if let data = weeklySummaryData {
                print("[Dashboard] WeeklySummary chargé: weekProgress.targetDuration=\(data.weekProgress.targetDuration), achievedDuration=\(data.weekProgress.achievedDuration)")
            }
            #endif
        } catch {
            print("[Dashboard] Erreur loadWeeklySummary: \(error)")
            self.error = "Erreur chargement: \(error.localizedDescription)"
            weeklySummaryData = nil
        }
    }

    // MARK: - Load Recent Activities

    func loadRecentActivities(userId: String) async {
        do {
            // Charger les activités des 90 derniers jours
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -90, to: endDate) ?? endDate

            recentActivities = try await activitiesService.getHistory(
                userId: userId,
                startDate: startDate,
                endDate: endDate,
                limit: 5
            )
        } catch {
            print("Erreur chargement activités: \(error.localizedDescription)")
            self.error = "Impossible de charger les activités récentes."
        }
    }

    // MARK: - Load Planned Sessions

    func loadPlannedSessions(userId: String) async {
        do {
            let allSessions = try await plansService.getLastPlan(userId: userId)
            // Filtrer pour ne garder que les séances futures (à partir d'aujourd'hui)
            let today = Calendar.current.startOfDay(for: Date())
            plannedSessions = allSessions
                .filter { session in
                    guard let sessionDate = session.dateValue else { return false }
                    return sessionDate >= today
                }
                .sorted { s1, s2 in
                    guard let d1 = s1.dateValue, let d2 = s2.dateValue else { return false }
                    return d1 < d2
                }
                .prefix(5)
                .map { $0 }
        } catch {
            print("Erreur chargement séances: \(error.localizedDescription)")
            // Ne pas bloquer l'UI globale pour ça, mais logger
            if self.error == nil {
                self.error = "Impossible de charger le planning."
            }
        }
    }
    
    // MARK: - Load Performance Report

    func loadPerformanceReport(userId: String) async {
        do {
            performanceReport = try await api.get("/users/\(userId)/performance-report")
            #if DEBUG
            if let report = performanceReport {
                let hasCS = report.metrics.csDprime != nil
                let hasCP = report.metrics.cpWprime != nil
                let hasCSS = report.metrics.css != nil
                print("[Dashboard] PerformanceReport chargé: csDprime=\(hasCS), cpWprime=\(hasCP), css=\(hasCSS)")
            } else {
                print("[Dashboard] PerformanceReport est nil après chargement")
            }
            #endif
        } catch {
            print("[Dashboard] Erreur loadPerformanceReport: \(error)")
            // Erreur non critique pour le dashboard principal
        }
    }

    // MARK: - Load Macro Plan

    func loadMacroPlan(userId: String) async {
        #if DEBUG
        print("🔄 [MacroPlan] Chargement du plan pour userId: \(userId)")
        #endif

        do {
            macroPlan = try await MacroPlanService.shared.getLastMacroPlan(userId: userId)

            #if DEBUG
            if let plan = macroPlan {
                print("✅ [MacroPlan] Plan chargé avec succès:")
                print("   - ID: \(plan.id)")
                print("   - Nom: \(plan.name ?? "Sans nom")")
                print("   - Objectifs: \(plan.objectives?.count ?? 0)")
                print("   - Visual bars: \(plan.visualBars?.count ?? 0)")
            } else {
                print("ℹ️ [MacroPlan] Aucun plan actif pour cet utilisateur")
            }
            #endif
        } catch {
            #if DEBUG
            print("❌ [MacroPlan] Erreur chargement:")
            print("   - Description: \(error.localizedDescription)")
            print("   - Erreur complète: \(error)")
            #endif
        }
    }

    // MARK: - Load PMC Status

    func loadPMCStatus(userId: String) async {
        isPMCLoading = true
        #if DEBUG
        print("🔄 [PMC] Chargement PMC pour userId: \(userId)")
        #endif

        do {
            pmcStatus = try await pmcService.getStatus(userId: userId)
            #if DEBUG
            if let pmc = pmcStatus {
                print("✅ [PMC] Chargé avec succès:")
                print("   - CTL: \(pmc.ctl), ATL: \(pmc.atl), TSB: \(pmc.tsb)")
                print("   - Statut: \(pmc.formLabel) \(pmc.formEmoji)")
                print("   - Alertes: \(pmc.alertsCount)")
                if let ramp = pmc.rampRate {
                    print("   - Ramp Rate: \(ramp)")
                }
            }
            #endif
        } catch {
            #if DEBUG
            print("❌ [PMC] Erreur chargement:")
            print("   - Description: \(error.localizedDescription)")
            print("   - Erreur complète: \(error)")
            #endif
            pmcStatus = nil
            // PMC est un widget important, on signale l'erreur si c'est la seule
            if self.error == nil {
                self.error = "Erreur chargement état de forme (PMC)"
            }
        }
        isPMCLoading = false
    }
}
