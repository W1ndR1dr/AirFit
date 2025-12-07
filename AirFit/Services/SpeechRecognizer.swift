import Speech
import AVFoundation

@MainActor
@Observable
final class SpeechRecognizer {
    var transcript: String = ""
    var isRecording: Bool = false
    var isAuthorized: Bool = false
    var errorMessage: String?

    // Audio components - managed separately to avoid threading issues
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    // Prevent concurrent stop operations
    private var isStopping = false

    func requestAuthorization() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            errorMessage = "Speech recognition not authorized"
            return false
        }

        let audioStatus = await AVAudioApplication.requestRecordPermission()
        guard audioStatus else {
            errorMessage = "Microphone access not authorized"
            return false
        }

        isAuthorized = true
        return true
    }

    func startRecording() {
        // Prevent starting if already recording or in the middle of stopping
        guard !isRecording, !isStopping else { return }

        guard isAuthorized else {
            errorMessage = "Not authorized"
            return
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition unavailable"
            return
        }

        // Reset state
        transcript = ""
        errorMessage = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session error: \(error.localizedDescription)"
            return
        }

        // Create audio engine first
        let engine = AVAudioEngine()
        audioEngine = engine

        // Create recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        recognitionRequest = request

        // Start recognition task
        // IMPORTANT: Callback runs on arbitrary thread - do NOT capture self directly
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            // Extract values before hopping to main actor
            let transcribedText = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let hasError = error != nil

            // Hop to main actor to update state
            Task { @MainActor in
                guard let self = self else { return }

                if let text = transcribedText {
                    self.transcript = text
                }

                if isFinal || hasError {
                    self.stopRecordingInternal()
                }
            }
        }

        // Setup audio tap
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Install tap - callback runs on audio thread
        // Only append buffer, no self access needed
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        // Start the engine
        do {
            engine.prepare()
            try engine.start()
            isRecording = true
        } catch {
            errorMessage = "Audio engine error: \(error.localizedDescription)"
            cleanupAudio()
        }
    }

    func stopRecording() -> String {
        let finalTranscript = transcript
        stopRecordingInternal()
        return finalTranscript
    }

    private func stopRecordingInternal() {
        // Prevent concurrent stops
        guard !isStopping else { return }
        isStopping = true

        // End recognition first (before stopping audio)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        // Clean up audio
        cleanupAudio()

        // Clear references
        recognitionRequest = nil
        recognitionTask = nil

        // Reset flags
        isStopping = false
        isRecording = false
    }

    private func cleanupAudio() {
        // Stop engine and remove tap
        if let engine = audioEngine {
            if engine.isRunning {
                engine.stop()
            }
            engine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
