/**
 * Service d'enregistrement audio
 * Gère l'enregistrement vocal avec visualisation des niveaux
 */

import Foundation
import AVFoundation
import Combine

// MARK: - Recording State

enum RecordingState: Equatable {
    case idle
    case preparing
    case recording
    case paused
    case finished(URL)
    case error(String)

    var isRecording: Bool {
        self == .recording
    }
}

// MARK: - Audio Recorder Service

@MainActor
class AudioRecorderService: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var state: RecordingState = .idle
    @Published var duration: TimeInterval = 0
    @Published var audioLevel: Float = 0  // 0 to 1, pour la visualisation

    // MARK: - Private Properties

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var durationTimer: Timer?
    private var recordingURL: URL?

    private let fileManager = FileManager.default

    // Configuration audio
    private let audioSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        AVEncoderBitRateKey: 128000
    ]

    // MARK: - Singleton

    static let shared = AudioRecorderService()

    override private init() {
        super.init()
    }

    // MARK: - Public Methods

    /// Démarre l'enregistrement
    func startRecording() async {
        // Vérifier les permissions
        guard await requestPermission() else {
            state = .error("Permission microphone refusée")
            return
        }

        state = .preparing

        do {
            // Configurer la session audio
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            // Créer le fichier d'enregistrement
            let fileName = "voice_\(UUID().uuidString).m4a"
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioURL = documentsPath.appendingPathComponent(fileName)
            recordingURL = audioURL

            // Créer le recorder
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: audioSettings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()

            // Démarrer
            if audioRecorder?.record() == true {
                state = .recording
                duration = 0
                startTimers()

                #if DEBUG
                print("🎤 Recording started: \(audioURL)")
                #endif
            } else {
                state = .error("Impossible de démarrer l'enregistrement")
            }

        } catch {
            state = .error("Erreur: \(error.localizedDescription)")
            #if DEBUG
            print("❌ Recording error: \(error)")
            #endif
        }
    }

    /// Arrête l'enregistrement et retourne l'URL du fichier
    func stopRecording() -> URL? {
        guard state.isRecording || state == .paused else { return nil }

        stopTimers()
        audioRecorder?.stop()

        let url = recordingURL

        // Désactiver la session audio
        try? AVAudioSession.sharedInstance().setActive(false)

        if let url = url {
            state = .finished(url)
            #if DEBUG
            print("🎤 Recording stopped: \(url)")
            #endif
        } else {
            state = .idle
        }

        return url
    }

    /// Annule l'enregistrement en cours
    func cancelRecording() {
        stopTimers()
        audioRecorder?.stop()

        // Supprimer le fichier
        if let url = recordingURL {
            try? fileManager.removeItem(at: url)
        }

        recordingURL = nil
        state = .idle
        duration = 0
        audioLevel = 0

        try? AVAudioSession.sharedInstance().setActive(false)

        #if DEBUG
        print("🎤 Recording cancelled")
        #endif
    }

    /// Met en pause l'enregistrement
    func pauseRecording() {
        guard state.isRecording else { return }

        audioRecorder?.pause()
        stopTimers()
        state = .paused
    }

    /// Reprend l'enregistrement après pause
    func resumeRecording() {
        guard state == .paused else { return }

        audioRecorder?.record()
        startTimers()
        state = .recording
    }

    /// Remet à zéro pour un nouvel enregistrement
    func reset() {
        cancelRecording()
        state = .idle
        duration = 0
        audioLevel = 0
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        let status = AVAudioSession.sharedInstance().recordPermission

        switch status {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }

    var hasPermission: Bool {
        AVAudioSession.sharedInstance().recordPermission == .granted
    }

    // MARK: - Timers

    private func startTimers() {
        // Timer pour la durée
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.state.isRecording {
                    self.duration = self.audioRecorder?.currentTime ?? 0
                }
            }
        }

        // Timer pour les niveaux audio (visualisation)
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let recorder = self.audioRecorder else { return }
                if self.state.isRecording {
                    recorder.updateMeters()
                    let level = recorder.averagePower(forChannel: 0)
                    // Convertir de dB (-160 à 0) en 0-1
                    let normalizedLevel = max(0, (level + 50) / 50)
                    self.audioLevel = min(1, normalizedLevel)
                }
            }
        }
    }

    private func stopTimers() {
        durationTimer?.invalidate()
        durationTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }

    // MARK: - Utility

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Supprime un fichier audio
    func deleteAudioFile(at url: URL) {
        try? fileManager.removeItem(at: url)
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorderService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                self.state = .error("Enregistrement interrompu")
            }
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.state = .error("Erreur d'encodage: \(error?.localizedDescription ?? "inconnue")")
        }
    }
}

// MARK: - Audio Player for Playback

@MainActor
class AudioPlayerService: NSObject, ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    static let shared = AudioPlayerService()

    override private init() {
        super.init()
    }

    func play(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            duration = audioPlayer?.duration ?? 0
            audioPlayer?.play()
            isPlaying = true

            // Timer pour la progression
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.currentTime = self?.audioPlayer?.currentTime ?? 0
                }
            }
        } catch {
            #if DEBUG
            print("❌ Playback error: \(error)")
            #endif
        }
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        timer?.invalidate()
    }

    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        currentTime = 0
        timer?.invalidate()
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }

    var formattedCurrentTime: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension AudioPlayerService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentTime = 0
            self.timer?.invalidate()
        }
    }
}
