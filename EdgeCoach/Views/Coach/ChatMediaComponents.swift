/**
 * Composants UI pour le Chat avec support Média
 * - VoiceRecordButton : Bouton d'enregistrement vocal
 * - AttachmentPickerButton : Bouton de sélection de fichiers
 * - VoiceMessageBubble : Affichage des messages vocaux
 * - AttachmentPreview : Prévisualisation des pièces jointes
 */

import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - Voice Record Button

struct VoiceRecordButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var recorder: AudioRecorderService
    let onRecordingComplete: (URL) -> Void
    let onCancel: () -> Void

    @State private var isPressed = false
    @State private var showDeleteConfirm = false

    var body: some View {
        if recorder.state.isRecording || recorder.state == .paused {
            // Mode enregistrement en cours
            recordingView
        } else {
            // Bouton microphone normal
            micButton
        }
    }

    private var micButton: some View {
        Button {
            Task {
                await recorder.startRecording()
            }
        } label: {
            Image(systemName: "mic.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(themeManager.textSecondary)
                .frame(width: 44, height: 44)
        }
    }

    private var recordingView: some View {
        HStack(spacing: ECSpacing.md) {
            // Bouton annuler
            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(themeManager.errorColor)
            }
            .confirmationDialog(
                "Annuler l'enregistrement ?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Annuler l'enregistrement", role: .destructive) {
                    recorder.cancelRecording()
                    onCancel()
                }
                Button("Continuer", role: .cancel) {}
            }

            // Visualisation audio
            AudioLevelView(level: recorder.audioLevel, color: themeManager.errorColor)
                .frame(height: 32)

            // Durée
            Text(recorder.formattedDuration)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(themeManager.textPrimary)

            Spacer()

            // Bouton envoyer
            Button {
                if let url = recorder.stopRecording() {
                    onRecordingComplete(url)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(themeManager.accentColor)
                        .frame(width: 44, height: 44)

                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, ECSpacing.md)
        .padding(.vertical, ECSpacing.sm)
        .background(themeManager.surfaceColor)
        .cornerRadius(ECRadius.lg)
    }
}

// MARK: - Audio Level Visualizer

struct AudioLevelView: View {
    let level: Float
    let color: Color
    let barCount: Int = 20

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    let barLevel = Float(index) / Float(barCount)
                    let isActive = level > barLevel

                    RoundedRectangle(cornerRadius: 1)
                        .fill(isActive ? color : color.opacity(0.2))
                        .frame(width: 3)
                        .scaleEffect(y: isActive ? CGFloat(0.3 + level * 0.7) : 0.3, anchor: .center)
                        .animation(.easeOut(duration: 0.1), value: level)
                }
            }
        }
    }
}

// MARK: - Attachment Picker Button

struct AttachmentPickerButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedImages: [UIImage]
    @Binding var selectedFiles: [URL]
    @Binding var showingPicker: Bool

    @State private var showingOptions = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingDocumentPicker = false

    var body: some View {
        Button {
            showingOptions = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(themeManager.textSecondary)
        }
        .confirmationDialog("Ajouter un fichier", isPresented: $showingOptions, titleVisibility: .hidden) {
            Button {
                showingImagePicker = true
            } label: {
                Label("Photothèque", systemImage: "photo.on.rectangle")
            }

            Button {
                showingCamera = true
            } label: {
                Label("Prendre une photo", systemImage: "camera")
            }

            Button {
                showingDocumentPicker = true
            } label: {
                Label("Document", systemImage: "doc")
            }

            Button("Annuler", role: .cancel) {}
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImages: $selectedImages)
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker(selectedImage: Binding(
                get: { nil },
                set: { if let img = $0 { selectedImages.append(img) } }
            ))
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(selectedURLs: $selectedFiles)
        }
    }
}

// MARK: - Image Picker (PhotosUI)

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 5

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                        if let uiImage = image as? UIImage {
                            DispatchQueue.main.async {
                                self?.parent.selectedImages.append(uiImage)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Camera Picker

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

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
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedURLs: [URL]
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .plainText])
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.selectedURLs.append(contentsOf: urls)
            parent.dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - Attachment Preview Row

struct AttachmentPreviewRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let images: [UIImage]
    let files: [URL]
    let onRemoveImage: (Int) -> Void
    let onRemoveFile: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ECSpacing.sm) {
                // Images
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    ImagePreviewChip(image: image) {
                        onRemoveImage(index)
                    }
                }

                // Fichiers
                ForEach(Array(files.enumerated()), id: \.offset) { index, url in
                    FilePreviewChip(url: url) {
                        onRemoveFile(index)
                    }
                }
            }
            .padding(.horizontal, ECSpacing.md)
        }
        .frame(height: images.isEmpty && files.isEmpty ? 0 : 80)
        .animation(.easeInOut(duration: 0.2), value: images.count + files.count)
    }
}

struct ImagePreviewChip: View {
    @EnvironmentObject var themeManager: ThemeManager
    let image: UIImage
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: ECRadius.md))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .offset(x: 5, y: -5)
        }
    }
}

struct FilePreviewChip: View {
    @EnvironmentObject var themeManager: ThemeManager
    let url: URL
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                Image(systemName: fileIcon)
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.accentColor)

                Text(url.lastPathComponent)
                    .font(.ecSmall)
                    .foregroundColor(themeManager.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: 60)
            }
            .frame(width: 70, height: 70)
            .background(themeManager.surfaceColor)
            .cornerRadius(ECRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: ECRadius.md)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(themeManager.textSecondary)
            }
            .offset(x: 5, y: -5)
        }
    }

    private var fileIcon: String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.fill"
        case "txt", "md": return "doc.text"
        default: return "doc"
        }
    }
}

// MARK: - Voice Message Bubble

struct VoiceMessageBubble: View {
    @EnvironmentObject var themeManager: ThemeManager
    let voiceMessage: VoiceMessage
    let isUser: Bool
    @StateObject private var player = AudioPlayerService.shared

    @State private var isPlaying = false

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.xs) {
            HStack(spacing: ECSpacing.sm) {
                // Play/Pause button
                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isUser ? .white : themeManager.accentColor)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(isUser ? Color.white.opacity(0.2) : themeManager.accentColor.opacity(0.15))
                        )
                }

                // Waveform + Progress
                VStack(alignment: .leading, spacing: 4) {
                    // Waveform visualization
                    WaveformView(isPlaying: isPlaying, color: isUser ? .white : themeManager.accentColor)
                        .frame(height: 24)

                    // Duration
                    Text(voiceMessage.formattedDuration)
                        .font(.ecSmall)
                        .foregroundColor(isUser ? .white.opacity(0.8) : themeManager.textSecondary)
                }
            }

            // Transcription si disponible
            if let transcription = voiceMessage.transcription, !transcription.isEmpty {
                Divider()
                    .background(isUser ? Color.white.opacity(0.3) : themeManager.borderColor)

                Text(transcription)
                    .font(.ecCaption)
                    .foregroundColor(isUser ? .white.opacity(0.9) : themeManager.textSecondary)
                    .italic()
            } else if voiceMessage.isTranscribing {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Transcription...")
                        .font(.ecSmall)
                        .foregroundColor(isUser ? .white.opacity(0.7) : themeManager.textTertiary)
                }
            }
        }
        .padding(ECSpacing.sm)
        .background(isUser ? themeManager.accentColor : themeManager.surfaceColor)
        .cornerRadius(ECRadius.lg)
    }

    private func togglePlayback() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            if let localURL = voiceMessage.localURL {
                player.play(url: localURL)
                isPlaying = true
            } else if let remoteURLString = voiceMessage.remoteURL,
                      let remoteURL = URL(string: remoteURLString) {
                player.play(url: remoteURL)
                isPlaying = true
            }
        }
    }
}

// MARK: - Waveform View

struct WaveformView: View {
    let isPlaying: Bool
    let color: Color
    let barCount: Int = 30

    @State private var animationPhase: Double = 0

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                let baseHeight = waveformHeight(for: index)
                let animatedHeight = isPlaying ? baseHeight * (0.5 + 0.5 * sin(animationPhase + Double(index) * 0.3)) : baseHeight

                RoundedRectangle(cornerRadius: 1)
                    .fill(color.opacity(0.7))
                    .frame(width: 2, height: CGFloat(animatedHeight) * 20 + 4)
            }
        }
        .onAppear {
            if isPlaying {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    animationPhase = .pi * 2
                }
            }
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    animationPhase = .pi * 2
                }
            } else {
                animationPhase = 0
            }
        }
    }

    private func waveformHeight(for index: Int) -> Double {
        // Forme de waveform statique
        let normalized = Double(index) / Double(barCount)
        return 0.3 + 0.7 * sin(normalized * .pi)
    }
}

// MARK: - Attachment Bubble (dans les messages)

struct AttachmentBubbleView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let attachment: MessageAttachment
    let isUser: Bool

    @State private var showingFullScreen = false

    var body: some View {
        Group {
            if attachment.type == .image {
                imageAttachmentView
            } else {
                documentAttachmentView
            }
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
            if attachment.type == .image {
                FullScreenImageView(attachment: attachment)
            }
        }
    }

    private var imageAttachmentView: some View {
        Button {
            showingFullScreen = true
        } label: {
            Group {
                if let localURL = attachment.localURL,
                   let uiImage = UIImage(contentsOfFile: localURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else if let thumbnailURL = attachment.thumbnailRemoteURL {
                    AsyncImage(url: thumbnailURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(themeManager.surfaceColor)
                            .overlay(
                                ProgressView()
                            )
                    }
                } else {
                    Rectangle()
                        .fill(themeManager.surfaceColor)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundColor(themeManager.textTertiary)
                        )
                }
            }
            .frame(width: 200, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: ECRadius.md))
        }
    }

    private var documentAttachmentView: some View {
        HStack(spacing: ECSpacing.sm) {
            Image(systemName: attachment.type.icon)
                .font(.system(size: 24))
                .foregroundColor(isUser ? .white : attachment.type.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.fileName)
                    .font(.ecLabel)
                    .foregroundColor(isUser ? .white : themeManager.textPrimary)
                    .lineLimit(1)

                if attachment.fileSize != nil {
                    Text(attachment.displaySize)
                        .font(.ecSmall)
                        .foregroundColor(isUser ? .white.opacity(0.7) : themeManager.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "arrow.down.circle")
                .font(.system(size: 20))
                .foregroundColor(isUser ? .white.opacity(0.7) : themeManager.textSecondary)
        }
        .padding(ECSpacing.sm)
        .frame(maxWidth: 250)
        .background(isUser ? Color.white.opacity(0.15) : themeManager.surfaceColor)
        .cornerRadius(ECRadius.md)
    }
}

// MARK: - Full Screen Image View

struct FullScreenImageView: View {
    @Environment(\.dismiss) private var dismiss
    let attachment: MessageAttachment

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let localURL = attachment.localURL,
                   let uiImage = UIImage(contentsOfFile: localURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    if scale < 1 {
                                        withAnimation {
                                            scale = 1
                                            lastScale = 1
                                        }
                                    }
                                }
                        )
                } else if let url = attachment.remoteURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                    } placeholder: {
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}
