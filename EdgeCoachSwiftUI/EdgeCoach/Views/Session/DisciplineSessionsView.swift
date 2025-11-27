/**
 * Vue liste des séances par discipline
 * Affiche les séances filtrées par sport pour une période donnée
 */

import SwiftUI

struct DisciplineSessionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel

    let discipline: Discipline
    let weekStart: Date

    @State private var sessions: [Activity] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var selectedSession: Activity?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(error)
                } else if sessions.isEmpty {
                    emptyView
                } else {
                    sessionsList
                }
            }
            .navigationTitle(discipline.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                        Text("Retour")
                    }
                    .foregroundColor(.ecPrimary)
                }
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(activity: session)
            }
        }
        .task {
            await loadSessions()
        }
    }

    // MARK: - Views

    private var loadingView: some View {
        VStack(spacing: ECSpacing.md) {
            ProgressView()
            Text("Chargement des séances...")
                .font(.ecBody)
                .foregroundColor(.ecGray500)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: ECSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.ecGray400)

            Text(message)
                .font(.ecBody)
                .foregroundColor(.ecGray500)
                .multilineTextAlignment(.center)

            Button("Réessayer") {
                Task { await loadSessions() }
            }
            .buttonStyle(.ecPrimary())
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: ECSpacing.md) {
            Image(systemName: discipline.icon)
                .font(.system(size: 48))
                .foregroundColor(.ecGray300)

            Text("Aucune séance de \(discipline.displayName.lowercased()) cette semaine")
                .font(.ecBody)
                .foregroundColor(.ecGray500)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var sessionsList: some View {
        VStack(spacing: 0) {
            // Summary Header
            summaryHeader

            // Sessions List
            ScrollView {
                LazyVStack(spacing: ECSpacing.md) {
                    ForEach(sessions, id: \.id) { session in
                        sessionCard(session)
                    }
                }
                .padding()
            }
            .background(Color.ecBackground)
            .refreshable {
                await loadSessions()
            }
        }
    }

    private var summaryHeader: some View {
        HStack {
            Text("\(sessions.count) séance\(sessions.count > 1 ? "s" : "") cette semaine")
                .font(.ecLabel)
                .foregroundColor(.ecGray600)

            Spacer()
        }
        .padding()
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.ecGray200)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private func sessionCard(_ session: Activity) -> some View {
        Button {
            selectedSession = session
        } label: {
            HStack(spacing: ECSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.sportColor(for: discipline).opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: discipline.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color.sportColor(for: discipline))
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.displayTitle)
                        .font(.ecLabel)
                        .foregroundColor(.ecSecondary800)
                        .lineLimit(1)

                    if let date = session.date {
                        Text(formatDate(date))
                            .font(.ecCaption)
                            .foregroundColor(.ecGray500)
                    }

                    // Stats
                    HStack(spacing: ECSpacing.sm) {
                        if let duration = session.formattedDuration {
                            statItem(icon: "clock", text: duration)
                        }

                        if let distance = session.formattedDistance {
                            statItem(icon: "location", text: distance)
                        }

                        if let calories = session.fileDatas?.calories {
                            statItem(icon: "flame", text: "\(calories) kcal")
                        }
                    }
                    .padding(.top, 2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.ecGray400)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(ECRadius.lg)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func statItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.ecGray500)

            Text(text)
                .font(.ecCaption)
                .foregroundColor(.ecGray600)
        }
    }

    // MARK: - Data Methods

    private func loadSessions() async {
        guard let userId = authViewModel.user?.id else {
            error = "Utilisateur non connecté"
            isLoading = false
            return
        }

        isLoading = true
        error = nil

        // Calculate week end date
        let calendar = Calendar.current
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            error = "Erreur de calcul de date"
            isLoading = false
            return
        }

        do {
            let allActivities = try await ActivitiesService.shared.getActivitiesForDateRange(
                userId: userId,
                startDate: weekStart,
                endDate: weekEnd
            )

            // Filter by discipline and sort by date
            sessions = allActivities
                .filter { $0.discipline == discipline }
                .sorted {
                    guard let d1 = $0.date, let d2 = $1.date else { return false }
                    return d1 > d2
                }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date).capitalized
    }
}

#Preview {
    DisciplineSessionsView(
        discipline: .cyclisme,
        weekStart: Date()
    )
    .environmentObject(AuthViewModel())
}
