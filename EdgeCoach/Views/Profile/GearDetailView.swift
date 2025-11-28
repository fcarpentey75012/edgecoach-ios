import SwiftUI

struct GearDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    let gear: Gear
    // Callback pour signaler une modification ou suppression
    let onDelete: () async -> Void
    
    // State pour l'édition (à implémenter plus tard si besoin, pour l'instant affichage)
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: ECSpacing.xl) {
                // Header avec Icône géante
                VStack(spacing: ECSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(themeManager.sportColorLight(for: gear.primarySport.discipline))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: gear.type.icon)
                            .font(.system(size: 40))
                            .foregroundColor(themeManager.sportColor(for: gear.primarySport.discipline))
                    }
                    
                    VStack(spacing: 4) {
                        Text(gear.displayName)
                            .font(.ecH2)
                            .foregroundColor(themeManager.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text(gear.type.rawValue)
                            .font(.ecBody)
                            .foregroundColor(themeManager.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(themeManager.elevatedColor)
                            .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ECSpacing.lg)
                
                // Stats / Jauge d'usure (Simulation visuelle pour l'instant)
                // Si on avait le kilométrage, on l'afficherait ici
                VStack(alignment: .leading, spacing: ECSpacing.md) {
                    Text("État")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Statut")
                                .font(.ecCaption)
                                .foregroundColor(themeManager.textSecondary)
                            Text(gear.status == .active ? "Actif" : "Archivé")
                                .font(.ecBodyBold)
                                .foregroundColor(gear.status == .active ? themeManager.successColor : .gray)
                        }
                        Spacer()
                        // Placeholder pour futur kilométrage
                        VStack(alignment: .trailing) {
                            Text("Utilisation")
                                .font(.ecCaption)
                                .foregroundColor(themeManager.textSecondary)
                            Text("-- km") // À connecter quand l'API le permettra
                                .font(.ecBodyBold)
                                .foregroundColor(themeManager.textPrimary)
                        }
                    }
                    .padding()
                    .background(themeManager.cardColor)
                    .cornerRadius(ECRadius.md)
                }
                .padding(.horizontal)
                
                // Informations Détaillées
                VStack(alignment: .leading, spacing: ECSpacing.md) {
                    Text("Détails")
                        .font(.ecLabelBold)
                        .foregroundColor(themeManager.textPrimary)
                    
                    VStack(spacing: 0) {
                        DetailRow(label: "Marque", value: gear.brand.isEmpty ? "-" : gear.brand, themeManager: themeManager)
                        Divider()
                        DetailRow(label: "Modèle", value: gear.model.isEmpty ? "-" : gear.model, themeManager: themeManager)
                        Divider()
                        DetailRow(label: "Année", value: gear.year ?? "-", themeManager: themeManager)
                        Divider()
                        DetailRow(label: "Sport", value: gear.primarySport.label, themeManager: themeManager)
                    }
                    .background(themeManager.cardColor)
                    .cornerRadius(ECRadius.md)
                }
                .padding(.horizontal)
                
                // Notes
                if let notes = gear.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: ECSpacing.md) {
                        Text("Notes")
                            .font(.ecLabelBold)
                            .foregroundColor(themeManager.textPrimary)
                        
                        Text(notes)
                            .font(.ecBody)
                            .foregroundColor(themeManager.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(themeManager.cardColor)
                            .cornerRadius(ECRadius.md)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Actions
                Button(role: .destructive) {
                    Task {
                        await onDelete()
                        dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Supprimer cet équipement")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.errorColor.opacity(0.1))
                    .foregroundColor(themeManager.errorColor)
                    .cornerRadius(ECRadius.md)
                }
                .padding()
            }
        }
        .background(themeManager.backgroundColor)
        .navigationTitle("Détails")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(label)
                .font(.ecBody)
                .foregroundColor(themeManager.textSecondary)
            Spacer()
            Text(value)
                .font(.ecBodyBold)
                .foregroundColor(themeManager.textPrimary)
        }
        .padding()
    }
}
