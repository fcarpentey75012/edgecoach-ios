/**
 * Modèle pour les pièces jointes de messages
 * Support: images, PDF, documents
 */

import Foundation
import SwiftUI

// MARK: - Attachment Type

enum AttachmentType: String, Codable {
    case image
    case document
    case audio
    case unknown

    var icon: String {
        switch self {
        case .image: return "photo"
        case .document: return "doc.text"
        case .audio: return "waveform"
        case .unknown: return "paperclip"
        }
    }

    var color: Color {
        switch self {
        case .image: return .blue
        case .document: return .orange
        case .audio: return .purple
        case .unknown: return .gray
        }
    }
}

// MARK: - Message Attachment

struct MessageAttachment: Codable, Identifiable, Equatable {
    let id: String
    let type: AttachmentType
    let fileName: String
    let fileURL: String
    let thumbnailURL: String?
    let fileSize: Int64?
    let mimeType: String?
    let extractedText: String?  // Pour les PDF

    // État local (non encodé)
    var isUploading: Bool = false
    var uploadProgress: Double = 0
    var localURL: URL?  // URL locale avant upload

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case fileName
        case fileURL
        case thumbnailURL
        case fileSize
        case mimeType
        case extractedText
    }

    init(
        id: String = UUID().uuidString,
        type: AttachmentType,
        fileName: String,
        fileURL: String = "",
        thumbnailURL: String? = nil,
        fileSize: Int64? = nil,
        mimeType: String? = nil,
        extractedText: String? = nil,
        isUploading: Bool = false,
        localURL: URL? = nil
    ) {
        self.id = id
        self.type = type
        self.fileName = fileName
        self.fileURL = fileURL
        self.thumbnailURL = thumbnailURL
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.extractedText = extractedText
        self.isUploading = isUploading
        self.localURL = localURL
    }

    // MARK: - Computed Properties

    var displaySize: String {
        guard let size = fileSize else { return "" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    var isImage: Bool {
        type == .image
    }

    var isPDF: Bool {
        mimeType == "application/pdf" || fileName.lowercased().hasSuffix(".pdf")
    }

    var remoteURL: URL? {
        URL(string: fileURL)
    }

    var thumbnailRemoteURL: URL? {
        guard let thumb = thumbnailURL else { return nil }
        return URL(string: thumb)
    }
}

// MARK: - Voice Message

struct VoiceMessage: Codable, Equatable {
    let id: String
    let duration: TimeInterval
    let localURL: URL?
    let remoteURL: String?
    let transcription: String?
    let isTranscribing: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case duration
        case remoteURL
        case transcription
    }

    init(
        id: String = UUID().uuidString,
        duration: TimeInterval,
        localURL: URL? = nil,
        remoteURL: String? = nil,
        transcription: String? = nil,
        isTranscribing: Bool = false
    ) {
        self.id = id
        self.duration = duration
        self.localURL = localURL
        self.remoteURL = remoteURL
        self.transcription = transcription
        self.isTranscribing = isTranscribing
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        remoteURL = try container.decodeIfPresent(String.self, forKey: .remoteURL)
        transcription = try container.decodeIfPresent(String.self, forKey: .transcription)
        localURL = nil
        isTranscribing = false
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Upload Response

struct UploadResponse: Decodable {
    let success: Bool
    let file: UploadedFile?
    let error: String?

    struct UploadedFile: Decodable {
        let id: String
        let type: String
        let fileName: String
        let fileURL: String
        let thumbnailURL: String?
        let fileSize: Int64?
        let mimeType: String?
        let extractedText: String?
    }
}

// MARK: - Transcription Response

struct TranscriptionResponse: Decodable {
    let success: Bool
    let text: String?
    let duration: Double?
    let language: String?
    let error: String?
}
