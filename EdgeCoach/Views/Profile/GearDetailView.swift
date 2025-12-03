import SwiftUI
import PhotosUI

struct GearDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    let gear: Gear
    let onDelete: () async -> Void

    // Photo state
    @State private var gearImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoOptions = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: ECSpacing.xl) {
                // Photo Section
                photoSection

                // État
                statusSection

                // Détails
                detailsSection

                // Notes
                if let notes = gear.notes, !notes.isEmpty {
                    notesSection(notes)
                }

                Spacer()

                // Actions
                deleteButton
            }
        }
        .background(themeManager.backgroundColor)
        .navigationTitle("Détails")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadImage()
        }
        .confirmationDialog("Ajouter une photo", isPresented: $showingPhotoOptions) {
            Button("Prendre une photo") {
                showingCamera = true
            }
            Button("Choisir dans la galerie") {
                showingImagePicker = true
            }
            if gearImage != nil {
                Button("Supprimer la photo", role: .destructive) {
                    deletePhoto()
                }
            }
            Button("Annuler", role: .cancel) {}
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(image: $gearImage, onCapture: saveImage)
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    gearImage = uiImage
                    saveImage()
                }
            }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(spacing: ECSpacing.md) {
            Button {
                showingPhotoOptions = true
            } label: {
                ZStack {
                    if let image = gearImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: ECRadius.lg))
                    } else {
                        RoundedRectangle(cornerRadius: ECRadius.lg)
                            .fill(themeManager.sportColorLight(for: gear.primarySport.discipline))
                            .frame(width: 150, height: 150)
                            .overlay(
                                Image(systemName: gear.type.icon)
                                    .font(.system(size: 50))
                                    .foregroundColor(themeManager.sportColor(for: gear.primarySport.discipline))
                            )
                    }

                    // Badge camera
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(themeManager.accentColor)
                                    .frame(width: 36, height: 36)
                                Image(systemName: gearImage == nil ? "camera.fill" : "pencil")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 8, y: 8)
                        }
                    }
                    .frame(width: 150, height: 150)
                }
            }
            .buttonStyle(.plain)

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
    }

    // MARK: - Status Section

    private var statusSection: some View {
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
                VStack(alignment: .trailing) {
                    Text("Utilisation")
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                    Text("-- km")
                        .font(.ecBodyBold)
                        .foregroundColor(themeManager.textPrimary)
                }
            }
            .padding()
            .background(themeManager.cardColor)
            .cornerRadius(ECRadius.md)
        }
        .padding(.horizontal)
    }

    // MARK: - Details Section

    private var detailsSection: some View {
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
    }

    // MARK: - Notes Section

    private func notesSection(_ notes: String) -> some View {
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

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button(role: .destructive) {
            Task {
                // Supprimer aussi l'image
                ImageStorageService.shared.deleteImage(for: gear)
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

    // MARK: - Image Methods

    private func loadImage() {
        gearImage = ImageStorageService.shared.loadImage(for: gear)
    }

    private func saveImage() {
        guard let image = gearImage else { return }
        _ = ImageStorageService.shared.saveImage(image, for: gear)
    }

    private func deletePhoto() {
        ImageStorageService.shared.deleteImage(for: gear)
        gearImage = nil
    }
}

// MARK: - Detail Row

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

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    var onCapture: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onCapture()
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
