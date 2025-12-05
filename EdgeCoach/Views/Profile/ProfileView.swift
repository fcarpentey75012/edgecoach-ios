/**
 * Vue Profil - Paramètres utilisateur
 * Utilise ThemeManager pour les couleurs dynamiques
 */

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingEditProfile = false
    @State private var showingZones = false
    @State private var showingEquipment = false
    @State private var showingAppearance = false
    @State private var showingCustomization = false
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
                            iconColor: themeManager.errorColor,
                            title: "Zones cardiaques",
                            subtitle: "FC max, seuils"
                        ) {
                            showingZones = true
                        }

                        SettingsRow(
                            icon: "bolt.circle",
                            iconColor: themeManager.warningColor,
                            title: "Zones de puissance",
                            subtitle: "FTP, zones"
                        ) {
                            showingZones = true
                        }

                        SettingsRow(
                            icon: "figure.run.circle",
                            iconColor: themeManager.successColor,
                            title: "Zones de vitesse",
                            subtitle: "VMA, allures"
                        ) {
                            showingZones = true
                        }
                    }

                    SettingsSection(title: "Équipement") {
                        SettingsRow(
                            icon: "figure.outdoor.cycle",
                            iconColor: themeManager.accentColor,
                            title: "Matériel",
                            subtitle: "Vélos, chaussures, accessoires"
                        ) {
                            showingEquipment = true
                        }
                    }

                    // MARK: - Apparence Section
                    SettingsSection(title: "Apparence") {
                        SettingsRow(
                            icon: "paintbrush.fill",
                            iconColor: themeManager.accentColor,
                            title: "Thème et couleurs",
                            subtitle: themeManager.themeMode.displayName
                        ) {
                            showingAppearance = true
                        }

                        SettingsRow(
                            icon: "slider.horizontal.3",
                            iconColor: themeManager.infoColor,
                            title: "Personnalisation",
                            subtitle: "Dashboard, analyses rapides"
                        ) {
                            showingCustomization = true
                        }
                    }

                    SettingsSection(title: "Compte") {
                        SettingsRow(
                            icon: "person.circle",
                            iconColor: themeManager.accentColor,
                            title: "Modifier le profil",
                            subtitle: "Nom, email, niveau"
                        ) {
                            showingEditProfile = true
                        }

                        SettingsRow(
                            icon: "bell.circle",
                            iconColor: themeManager.infoColor,
                            title: "Notifications",
                            subtitle: "Rappels, alertes"
                        ) {
                            // Show notifications settings
                        }

                        SettingsRow(
                            icon: "link.circle",
                            iconColor: themeManager.textSecondary,
                            title: "Connexions",
                            subtitle: "Strava, Garmin, Wahoo"
                        ) {
                            // Show connections
                        }
                    }

                    SettingsSection(title: "À propos") {
                        SettingsRow(
                            icon: "info.circle",
                            iconColor: themeManager.textSecondary,
                            title: "Version",
                            subtitle: "1.0.0"
                        ) {
                            // No action
                        }

                        SettingsRow(
                            icon: "doc.text",
                            iconColor: themeManager.textSecondary,
                            title: "Conditions d'utilisation",
                            subtitle: nil
                        ) {
                            // Show terms
                        }

                        SettingsRow(
                            icon: "hand.raised",
                            iconColor: themeManager.textSecondary,
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
                        .foregroundColor(themeManager.errorColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ECSpacing.md)
                        .background(themeManager.errorColor.opacity(0.1))
                        .cornerRadius(ECRadius.lg)
                    }
                    .padding(.horizontal)
                    .padding(.top, ECSpacing.md)
                }
                .padding(.vertical)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Profil")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingZones) {
                ZonesSettingsView()
                    .environmentObject(themeManager)
            }
            .alert("Déconnexion", isPresented: $showingLogoutAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Déconnexion", role: .destructive) {
                    authViewModel.logout()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir vous déconnecter ?")
            }
            .sheet(isPresented: $showingAppearance) {
                AppearanceSettingsView()
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingCustomization) {
                CustomizationView()
                    .environmentObject(themeManager)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showingEquipment) {
                EquipmentView()
                    .environmentObject(themeManager)
                    .environmentObject(authViewModel)
            }
        }
    }
}

// MARK: - Profile Header Card

struct ProfileHeaderCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let user: User?

    var body: some View {
        VStack(spacing: ECSpacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Text(initials)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(themeManager.accentColor)
            }

            // Name
            Text(fullName)
                .font(.ecH3)
                .foregroundColor(themeManager.textPrimary)

            // Email
            if let email = user?.email {
                Text(email)
                    .font(.ecBody)
                    .foregroundColor(themeManager.textSecondary)
            }

            // Experience Level
            if let level = user?.experienceLevel {
                HStack(spacing: ECSpacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.ecSmall)
                        .foregroundColor(themeManager.warningColor)
                    Text(level.displayName)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textPrimary)
                }
                .padding(.horizontal, ECSpacing.md)
                .padding(.vertical, ECSpacing.xs)
                .background(themeManager.warningColor.opacity(0.1))
                .cornerRadius(ECRadius.full)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ECSpacing.lg)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .shadow(color: themeManager.cardShadow, radius: 4, x: 0, y: 2)
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
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            Text(title)
                .font(.ecCaptionBold)
                .foregroundColor(themeManager.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, ECSpacing.lg)

            VStack(spacing: 0) {
                content
            }
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    @EnvironmentObject var themeManager: ThemeManager
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
                        .foregroundColor(themeManager.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.ecSmall)
                            .foregroundColor(themeManager.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textTertiary)
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
    @EnvironmentObject var themeManager: ThemeManager

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
                    .foregroundColor(themeManager.accentColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        // Save profile
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
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
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            List {
                Section("Zones cardiaques") {
                    ZoneRow(zone: 1, name: "Récupération", range: "< 130 bpm")
                    ZoneRow(zone: 2, name: "Endurance", range: "130-150 bpm")
                    ZoneRow(zone: 3, name: "Tempo", range: "150-165 bpm")
                    ZoneRow(zone: 4, name: "Seuil", range: "165-175 bpm")
                    ZoneRow(zone: 5, name: "VO2max", range: "> 175 bpm")
                }

                Section("Paramètres") {
                    HStack {
                        Text("FC max")
                        Spacer()
                        Text("185 bpm")
                            .foregroundColor(themeManager.textSecondary)
                    }

                    HStack {
                        Text("FC repos")
                        Spacer()
                        Text("52 bpm")
                            .foregroundColor(themeManager.textSecondary)
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
                    .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
}

struct ZoneRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let zone: Int
    let name: String
    let range: String

    var body: some View {
        HStack(spacing: ECSpacing.md) {
            Text("Z\(zone)")
                .font(.ecCaptionBold)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(themeManager.zoneColor(for: zone))
                .cornerRadius(6)

            Text(name)
                .font(.ecBody)
                .foregroundColor(themeManager.textPrimary)

            Spacer()

            Text(range)
                .font(.ecCaption)
                .foregroundColor(themeManager.textSecondary)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager.shared)
}
