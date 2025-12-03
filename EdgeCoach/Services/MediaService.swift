/**
 * Service Media
 * Gère l'upload de fichiers et la transcription audio
 */

import Foundation
import UIKit
import UniformTypeIdentifiers

// MARK: - Media Service Error

enum MediaServiceError: Error, LocalizedError {
    case invalidFile
    case fileTooLarge(maxSize: Int)
    case uploadFailed(String)
    case transcriptionFailed(String)
    case networkError(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidFile:
            return "Fichier invalide ou non supporté"
        case .fileTooLarge(let maxSize):
            let mb = maxSize / (1024 * 1024)
            return "Fichier trop volumineux. Maximum: \(mb) MB"
        case .uploadFailed(let message):
            return "Échec de l'upload: \(message)"
        case .transcriptionFailed(let message):
            return "Échec de la transcription: \(message)"
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        }
    }
}

// MARK: - Media Service

@MainActor
class MediaService {
    static let shared = MediaService()

    private let api = APIService.shared
    private let maxFileSize = 20 * 1024 * 1024  // 20 MB
    private let maxAudioSize = 25 * 1024 * 1024 // 25 MB

    private let allowedImageTypes: Set<String> = ["jpg", "jpeg", "png", "gif", "webp", "heic"]
    private let allowedDocumentTypes: Set<String> = ["pdf", "txt", "md"]
    private let allowedAudioTypes: Set<String> = ["m4a", "mp3", "wav", "webm", "ogg", "flac"]

    private init() {}

    // MARK: - Upload File

    /// Upload un fichier vers le backend
    func uploadFile(
        data: Data,
        fileName: String,
        mimeType: String,
        onProgress: ((Double) -> Void)? = nil
    ) async throws -> MessageAttachment {
        // Vérifier la taille
        if data.count > maxFileSize {
            throw MediaServiceError.fileTooLarge(maxSize: maxFileSize)
        }

        // Vérifier le type
        let ext = fileName.split(separator: ".").last?.lowercased() ?? ""
        let fileType = determineFileType(extension: String(ext))

        if fileType == .unknown {
            throw MediaServiceError.invalidFile
        }

        // Construire l'URL
        let baseUrl = api.baseURL.replacingOccurrences(of: "/api", with: "")
        let urlString = "\(baseUrl)/api/chat/upload"

        guard let url = URL(string: urlString) else {
            throw MediaServiceError.uploadFailed("URL invalide")
        }

        // Créer la requête multipart
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = api.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Construire le body multipart
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        #if DEBUG
        print("📤 Uploading file: \(fileName) (\(data.count) bytes)")
        #endif

        // Envoyer la requête
        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MediaServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: responseData, encoding: .utf8) ?? "Erreur inconnue"
            throw MediaServiceError.uploadFailed(errorMessage)
        }

        // Décoder la réponse
        let decoder = JSONDecoder()
        let uploadResponse = try decoder.decode(UploadResponse.self, from: responseData)

        guard uploadResponse.success, let file = uploadResponse.file else {
            throw MediaServiceError.uploadFailed(uploadResponse.error ?? "Erreur inconnue")
        }

        #if DEBUG
        print("✅ File uploaded: \(file.id)")
        #endif

        // Convertir en MessageAttachment
        return MessageAttachment(
            id: file.id,
            type: AttachmentType(rawValue: file.type) ?? .unknown,
            fileName: file.fileName,
            fileURL: file.fileURL,
            thumbnailURL: file.thumbnailURL,
            fileSize: file.fileSize,
            mimeType: file.mimeType,
            extractedText: file.extractedText
        )
    }

    // MARK: - Upload Image

    /// Upload une image UIImage
    func uploadImage(_ image: UIImage, fileName: String = "image.jpg") async throws -> MessageAttachment {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw MediaServiceError.invalidFile
        }

        return try await uploadFile(
            data: data,
            fileName: fileName.hasSuffix(".jpg") ? fileName : "\(fileName).jpg",
            mimeType: "image/jpeg"
        )
    }

    // MARK: - Upload from URL

    /// Upload un fichier depuis une URL locale
    func uploadFromURL(_ url: URL) async throws -> MessageAttachment {
        let data = try Data(contentsOf: url)
        let fileName = url.lastPathComponent
        let mimeType = mimeType(for: url)

        return try await uploadFile(data: data, fileName: fileName, mimeType: mimeType)
    }

    // MARK: - Transcribe Audio

    /// Transcrit un fichier audio en texte via Whisper
    func transcribeAudio(
        fileURL: URL,
        language: String = "fr"
    ) async throws -> TranscriptionResponse {
        // Lire le fichier
        let data = try Data(contentsOf: fileURL)

        // Vérifier la taille
        if data.count > maxAudioSize {
            throw MediaServiceError.fileTooLarge(maxSize: maxAudioSize)
        }

        // Vérifier le type
        let ext = fileURL.pathExtension.lowercased()
        if !allowedAudioTypes.contains(ext) {
            throw MediaServiceError.invalidFile
        }

        // Construire l'URL
        let baseUrl = api.baseURL.replacingOccurrences(of: "/api", with: "")
        let urlString = "\(baseUrl)/api/chat/transcribe"

        guard let url = URL(string: urlString) else {
            throw MediaServiceError.transcriptionFailed("URL invalide")
        }

        // Créer la requête multipart
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60  // Timeout plus long pour la transcription

        if let token = api.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Construire le body multipart
        var body = Data()

        // Fichier audio
        let fileName = fileURL.lastPathComponent
        let mimeType = self.mimeType(for: fileURL)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)

        // Langue
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(language)\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        #if DEBUG
        print("🎤 Transcribing audio: \(fileName) (\(data.count) bytes)")
        #endif

        // Envoyer la requête
        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MediaServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: responseData, encoding: .utf8) ?? "Erreur inconnue"
            throw MediaServiceError.transcriptionFailed(errorMessage)
        }

        // Décoder la réponse
        let decoder = JSONDecoder()
        let transcriptionResponse = try decoder.decode(TranscriptionResponse.self, from: responseData)

        guard transcriptionResponse.success else {
            throw MediaServiceError.transcriptionFailed(transcriptionResponse.error ?? "Erreur inconnue")
        }

        #if DEBUG
        print("✅ Transcription: \(transcriptionResponse.text?.prefix(50) ?? "")...")
        #endif

        return transcriptionResponse
    }

    // MARK: - Delete File

    /// Supprime un fichier du serveur
    func deleteFile(fileId: String) async throws {
        let baseUrl = api.baseURL.replacingOccurrences(of: "/api", with: "")
        let urlString = "\(baseUrl)/api/chat/files/\(fileId)"

        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        if let token = api.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        _ = try await URLSession.shared.data(for: request)
    }

    // MARK: - Helpers

    private func determineFileType(extension ext: String) -> AttachmentType {
        if allowedImageTypes.contains(ext) {
            return .image
        } else if allowedDocumentTypes.contains(ext) {
            return .document
        } else if allowedAudioTypes.contains(ext) {
            return .audio
        }
        return .unknown
    }

    private func mimeType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()

        let mimeTypes: [String: String] = [
            // Images
            "jpg": "image/jpeg",
            "jpeg": "image/jpeg",
            "png": "image/png",
            "gif": "image/gif",
            "webp": "image/webp",
            "heic": "image/heic",
            // Documents
            "pdf": "application/pdf",
            "txt": "text/plain",
            "md": "text/markdown",
            // Audio
            "m4a": "audio/m4a",
            "mp3": "audio/mpeg",
            "wav": "audio/wav",
            "webm": "audio/webm",
            "ogg": "audio/ogg",
            "flac": "audio/flac"
        ]

        return mimeTypes[ext] ?? "application/octet-stream"
    }
}

// MARK: - Data Extension

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
