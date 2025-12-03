/**
 * Service de stockage d'images local
 * Gère le stockage des photos d'équipement dans le système de fichiers
 */

import SwiftUI
import UIKit

@MainActor
class ImageStorageService {
    static let shared = ImageStorageService()

    private let fileManager = FileManager.default

    private init() {
        // Créer le dossier gear_images s'il n'existe pas
        createGearImagesDirectoryIfNeeded()
    }

    // MARK: - Directory Management

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var gearImagesDirectory: URL {
        documentsDirectory.appendingPathComponent("gear_images", isDirectory: true)
    }

    private func createGearImagesDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: gearImagesDirectory.path) {
            try? fileManager.createDirectory(at: gearImagesDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Image Operations

    /// Sauvegarde une image pour un équipement
    func saveImage(_ image: UIImage, for gear: Gear) -> Bool {
        return saveImage(image, forGearId: gear.id)
    }

    /// Sauvegarde une image avec l'ID de l'équipement
    func saveImage(_ image: UIImage, forGearId gearId: String) -> Bool {
        guard !gearId.isEmpty else { return false }

        // Redimensionner l'image pour économiser de l'espace (max 800px)
        let resizedImage = resizeImage(image, maxDimension: 800)

        guard let data = resizedImage.jpegData(compressionQuality: 0.8) else {
            return false
        }

        let fileURL = gearImagesDirectory.appendingPathComponent("\(gearId).jpg")

        do {
            try data.write(to: fileURL)
            return true
        } catch {
            print("ImageStorageService: Erreur sauvegarde image - \(error)")
            return false
        }
    }

    /// Charge l'image d'un équipement
    func loadImage(for gear: Gear) -> UIImage? {
        return loadImage(forGearId: gear.id)
    }

    /// Charge une image avec l'ID de l'équipement
    func loadImage(forGearId gearId: String) -> UIImage? {
        guard !gearId.isEmpty else { return nil }

        let fileURL = gearImagesDirectory.appendingPathComponent("\(gearId).jpg")

        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }

        return image
    }

    /// Vérifie si un équipement a une image
    func hasImage(for gear: Gear) -> Bool {
        return hasImage(forGearId: gear.id)
    }

    /// Vérifie si un équipement a une image (par ID)
    func hasImage(forGearId gearId: String) -> Bool {
        guard !gearId.isEmpty else { return false }
        let fileURL = gearImagesDirectory.appendingPathComponent("\(gearId).jpg")
        return fileManager.fileExists(atPath: fileURL.path)
    }

    /// Supprime l'image d'un équipement
    func deleteImage(for gear: Gear) {
        deleteImage(forGearId: gear.id)
    }

    /// Supprime une image par ID
    func deleteImage(forGearId gearId: String) {
        guard !gearId.isEmpty else { return }
        let fileURL = gearImagesDirectory.appendingPathComponent("\(gearId).jpg")
        try? fileManager.removeItem(at: fileURL)
    }

    // MARK: - Helpers

    /// Redimensionne une image pour respecter une dimension maximale
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // Si l'image est déjà assez petite, on la retourne telle quelle
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }
}

// MARK: - SwiftUI Image Extension

extension Gear {
    /// Charge l'image SwiftUI de l'équipement (si elle existe)
    @MainActor
    func loadSwiftUIImage() -> Image? {
        guard let uiImage = ImageStorageService.shared.loadImage(for: self) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
}
