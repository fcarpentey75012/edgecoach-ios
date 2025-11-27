/**
 * Vue Profil - Paramètres utilisateur
 */

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingEditProfile = false
    @State private var showingZones = false
    @State private var showingEquipment = false
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ECSpacing.lg) {
                    // Profile Header
                    ProfileHeaderCard(user: authViewModel.user)

                    // Settings Sections
                    SettingsSection(title: "Entraînement") {
                        SettingsRow(
                            icon: "heart.circle",
                            iconColor: .ecError,
                            title: "Zones cardiaques",
                            subtitle: "FC max, seuils"
                        ) {
                            showingZones = true
                        }

                        SettingsRow(
                            icon: "bolt.circle",
                            iconColor: .ecWarning,
                            title: "Zones de puissance",
                            subtitle: "FTP, zones"
                        ) {
                            showingZones = true
                        }

                        SettingsRow(
                            icon: "figure.run.circle",
                            iconColor: .ecSuccess,
                            title: "Zones de vitesse",
                            subtitle: "VMA, allures"
                        ) {
                            showingZones = true
                        }
                    }

                    SettingsSection(title: "Équipement") {
                        SettingsRow(
                            icon: "bicycle.circle",
                            iconColor: .ecSportCyclisme,
                            title: "Vélos",
                            subtitle: "Gérer vos vélos"
                        ) {
                            showingEquipment = true
                        }

                        SettingsRow(
                            icon: "shoe.circle",
                            iconColor: .ecSportCourse,
                            title: "Chaussures",
                            subtitle: "Gérer vos chaussures"
                        ) {
                            showingEquipment = true
                        }
                    }

                    SettingsSection(title: "Compte") {
                        SettingsRow(
                            icon: "person.circle",
                            iconColor: .ecPrimary,
                            title: "Modifier le profil",
                            subtitle: "Nom, email, niveau"
                        ) {
                            showingEditProfile = true
                        }

                        SettingsRow(
                            icon: "bell.circle",
                            iconColor: .ecInfo,
                            title: "Notifications",
                            subtitle: "Rappels, alertes"
                        ) {
                            // Show notifications settings
                        }

                        SettingsRow(
                            icon: "link.circle",
                            iconColor: .ecSecondary500,
                            title: "Connexions",
                            subtitle: "Strava, Garmin, Wahoo"
                        ) {
                            // Show connections
                        }
                    }

                    SettingsSection(title: "À propos") {
                        SettingsRow(
                            icon: "info.circle",
                            iconColor: .ecGray500,
                            title: "Version",
                            subtitle: "1.0.0"
                        ) {
                            // No action
                        }

                        SettingsRow(
                            icon: "doc.text",
                            iconColor: .ecGray500,
                            title: "Conditions d'utilisation",
                            subtitle: nil
                        ) {
                            // Show terms
                        }

                        SettingsRow(
                            icon: "hand.raised",
                            iconColor: .ecGray500,
                            title: "Politique de confidentialité",
                            subtitle: nil
                        ) {
                            // Show privacy
                        }
                    }

                    // Logout Button
                    Button {
                        showingLogoutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Déconnexion")
                        }
                        .font(.ecBodyMedium)
                        .foregroundColor(.ecError)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ECSpacing.md)
                        .background(Color.ecError.opacity(0.1))
                        .cornerRadius(ECRadius.lg)
                    }
                    .padding(.horizontal)
                    .padding(.top, ECSpacing.md)
                }
                .padding(.vertical)
            }
            .background(Color.ecBackground)
            .navigationTitle("Profil")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingZones) {
                ZonesSettingsView()
            }
            .alert("Déconnexion", isPresented: $showingLogoutAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Déconnexion", role: .destructive) {
                    Task {
                        await authViewModel.logout()
                    }
                }
            } message: {
                Text("Êtes-vous sûr de vouloir vous déconnecter ?")
            }
        }
    }
}

// MARK: - Profile Header Card

struct ProfileHeaderCard: View {
    let user: User?

    var body: some View {
        VStack(spacing: ECSpacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.ecPrimary100)
                    .frame(width: 80, height: 80)

                Text(initials)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.ecPrimary)
            }

            // Name
            Text(fullName)
                .font(.ecH3)
                .foregroundColor(.ecSecondary800)

            // Email
            if let email = user?.email {
                Text(email)
                    .font(.ecBody)
                    .foregroundColor(.ecGray500)
            }

            // Experience Level
            if let level = user?.experienceLevel {
                HStack(spacing: ECSpacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.ecSmall)
                        .foregroundColor(.ecWarning)
                    Text(level.displayName)
                        .font(.ecCaption)
                        .foregroundColor(.ecSecondary700)
                }
                .padding(.horizontal, ECSpacing.md)
                .padding(.vertical, ECSpacing.xs)
                .background(Color.ecWarning.opacity(0.1))
                .cornerRadius(ECRadius.full)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ECSpacing.lg)
        .background(Color.ecSurface)
        .cornerRadius(ECRadius.lg)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var initials: String {
        let first = user?.firstName?.prefix(1) ?? ""
        let last = user?.lastName?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }

    private var fullName: String {
        let first = user?.firstName ?? ""
        let last = user?.lastName ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text(title)
                .font(.ecCaptionBold)
                .foregroundColor(.ecGray500)
                .textCase(.uppercase)
                .padding(.horizontal, ECSpacing.lg)

            VStack(spacing: 0) {
                content
            }
            .background(Color.ecSurface)
            .cornerRadius(ECRadius.lg)
            .padding(.horizontal)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ECSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.ecBody)
                        .foregroundColor(.ecSecondary800)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.ecSmall)
                            .foregroundColor(.ecGray500)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.ecCaption)
                    .foregroundColor(.ecGray400)
            }
            .padding(.horizontal, ECSpacing.md)
            .padding(.vertical, ECSpacing.md)
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var experienceLevel: ExperienceLevel = .intermediaire

    var body: some View {
        NavigationStack {
            Form {
                Section("Informations personnelles") {
                    TextField("Prénom", text: $firstName)
                    TextField("Nom", text: $lastName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section("Niveau") {
                    Picker("Niveau d'expérience", selection: $experienceLevel) {
                        ForEach(ExperienceLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                }
            }
            .navigationTitle("Modifier le profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        // Save profile
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            firstName = authViewModel.user?.firstName ?? ""
            lastName = authViewModel.user?.lastName ?? ""
            email = authViewModel.user?.email ?? ""
            experienceLevel = authViewModel.user?.experienceLevel ?? .intermediaire
        }
    }
}

// MARK: - Zones Settings View

struct ZonesSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Zones cardiaques") {
                    ZoneRow(zone: 1, name: "Récupération", range: "< 130 bpm", color: .ecZone1)
                    ZoneRow(zone: 2, name: "Endurance", range: "130-150 bpm", color: .ecZone2)
                    ZoneRow(zone: 3, name: "Tempo", range: "150-165 bpm", color: .ecZone3)
                    ZoneRow(zone: 4, name: "Seuil", range: "165-175 bpm", color: .ecZone4)
                    ZoneRow(zone: 5, name: "VO2max", range: "> 175 bpm", color: .ecZone5)
                }

                Section("Paramètres") {
                    HStack {
                        Text("FC max")
                        Spacer()
                        Text("185 bpm")
                            .foregroundColor(.ecGray500)
                    }

                    HStack {
                        Text("FC repos")
                        Spacer()
                        Text("52 bpm")
                            .foregroundColor(.ecGray500)
                    }
                }
            }
            .navigationTitle("Zones d'entraînement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ZoneRow: View {
    let zone: Int
    let name: String
    let range: String
    let color: Color

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            Text("Z\(zone)")
                .font(.ecCaptionBold)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .cornerRadius(6)

            Text(name)
                .font(.ecBody)
                .foregroundColor(.ecSecondary800)

            Spacer()

            Text(range)
                .font(.ecCaption)
                .foregroundColor(.ecGray500)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
