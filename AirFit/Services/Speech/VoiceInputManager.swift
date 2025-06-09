import Foundation
import AVFoundation
@preconcurrency import WhisperKit

/// # VoiceInputManager
/// 
/// ## Purpose
/// Manages voice input, transcription, and real-time speech-to-text conversion using
/// WhisperKit for on-device processing. Provides streaming and batch transcription.
///
/// ## Dependencies
/// - `WhisperModelManagerProtocol`: Manages WhisperKit model selection and downloads
/// - `WhisperKit`: On-device speech recognition engine
/// - `AVAudioEngine`: Audio capture and processing
///
/// ## Key Responsibilities
/// - Request and manage microphone permissions
/// - Record audio with real-time waveform visualization
/// - Transcribe audio using WhisperKit models
/// - Stream partial transcriptions during recording
/// - Post-process transcriptions for fitness terminology
/// - Manage model downloads with progress tracking
/// - Handle audio session lifecycle
///
/// ## Usage
/// ```swift
/// let voiceInput = await container.resolve(VoiceInputProtocol.self)
/// 
/// // Start recording
/// try await voiceInput.startRecording()
/// 
/// // Stop and get transcription
/// let text = await voiceInput.stopRecording()
/// 
/// // Stream transcription
/// try await voiceInput.startStreamingTranscription()
/// voiceInput.onPartialTranscription = { partial in
///     // Update UI with partial text
/// }
/// ```
///
/// ## Important Notes
/// - @MainActor isolated for UI updates
/// - Automatically handles WhisperKit model downloads
/// - Optimizes for fitness-specific terminology
/// - Provides real-time waveform data for visualization
@MainActor
@Observable
final class VoiceInputManager: NSObject, VoiceInputProtocol, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "voice-input-manager"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }
    
    // MARK: - Published State
    private(set) var state: VoiceInputState = .idle
    private(set) var isRecording = false
    private(set) var isTranscribing = false
    private(set) var waveformBuffer: [Float] = []
    private(set) var currentTranscription = ""

    // MARK: - Callbacks
    var onTranscription: ((String) -> Void)?
    var onPartialTranscription: ((String) -> Void)?
    var onWaveformUpdate: (([Float]) -> Void)?
    var onError: ((Error) -> Void)?
    var onStateChange: ((VoiceInputState) -> Void)?

    // MARK: - Private Properties
    private var audioEngine = AVAudioEngine()
    private var audioRecorder: AVAudioRecorder?
    private var waveformTimer: Timer?
    private var audioBuffer: [Float] = []
    private var recordingURL: URL?
    private var whisper: WhisperKit?
    let modelManager: WhisperModelManagerProtocol
    private var downloadObserver: NSObjectProtocol?

    private var inputNode: AVAudioInputNode { audioEngine.inputNode }

    // MARK: - Initialization
    init(modelManager: WhisperModelManagerProtocol) {
        self.modelManager = modelManager
        super.init()
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        await initializeWhisper()
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        if isRecording {
            _ = await stopRecording()
        }
        whisper = nil
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        let hasWhisper = whisper != nil
        let hasModel = modelManager.activeModel != ""
        
        return ServiceHealth(
            status: hasWhisper && hasModel ? .healthy : .degraded,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: hasWhisper ? nil : "Whisper not initialized",
            metadata: [
                "activeModel": modelManager.activeModel,
                "isRecording": "\(isRecording)"
            ]
        )
    }
    
    // MARK: - Public Methods
    func initialize() async {
        await initializeWhisper()
    }

    // MARK: - Permission
    func requestPermission() async throws -> Bool {
        let granted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
        if !granted { throw AppError.from(VoiceInputError.notAuthorized) }
        return granted
    }

    // MARK: - Recording Control
    func startRecording() async throws {
        guard state == .ready else {
            throw AppError.from(VoiceInputError.whisperNotReady)
        }
        guard try await requestPermission() else { return }
        updateState(.recording)
        try await prepareRecorder()
        audioRecorder?.record()
        isRecording = true
        startWaveformTimer()
    }

    func stopRecording() async -> String? {
        guard let recorder = audioRecorder, recorder.isRecording else { return nil }
        recorder.stop()
        stopWaveformTimer()
        isRecording = false
        updateState(.transcribing)
        
        guard let url = recordingURL else { 
            updateState(.ready)
            return nil 
        }
        
        do {
            let text = try await transcribeAudio(at: url)
            try? FileManager.default.removeItem(at: url)
            currentTranscription = text
            onTranscription?(text)
            updateState(.ready)
            return text
        } catch {
            AppLogger.error("Transcription failed", error: error, category: .ai)
            updateState(.error(.transcriptionFailed))
            onError?(error)
            return nil
        }
    }

    // MARK: - Streaming Transcription
    func startStreamingTranscription() async throws {
        guard state == .ready else {
            throw AppError.from(VoiceInputError.whisperNotReady)
        }
        guard try await requestPermission() else { return }
        guard whisper != nil else { throw AppError.from(VoiceInputError.whisperNotReady) }
        
        updateState(.transcribing)
        
        if audioEngine.isRunning { audioEngine.stop() }
        audioBuffer.removeAll()
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16_000, channels: 1, interleaved: false)!
        inputNode.installTap(onBus: 0, bufferSize: 8_192, format: format) { [weak self] buffer, _ in
            Task { @MainActor in
                await self?.processStreamingBuffer(buffer)
            }
        }
        audioEngine.prepare()
        try audioEngine.start()
        isTranscribing = true
        startWaveformTimer()
    }

    func stopStreamingTranscription() async {
        guard audioEngine.isRunning else { return }
        inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        stopWaveformTimer()
        audioBuffer.removeAll()
        isTranscribing = false
        updateState(.ready)
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    // MARK: - Private Setup
    private func initializeWhisper() async {
        let modelID = modelManager.selectOptimalModel()
        let modelName = modelManager.availableModels.first { $0.id == modelID }?.displayName ?? modelID
        
        // Check if model already downloaded
        if modelManager.downloadedModels.contains(modelID) {
            updateState(.preparingModel)
            do {
                whisper = try await WhisperKit(
                    WhisperKitConfig(
                        model: modelID,
                        modelRepo: "mlx-community/whisper-\(modelID)-mlx",
                        modelFolder: modelID,
                        verbose: false,
                        logLevel: .error,
                        prewarm: true,
                        load: true,
                        download: false
                    )
                )
                updateState(.ready)
            } catch {
                AppLogger.error("Failed to initialize Whisper", error: error, category: .ai)
                updateState(.error(.whisperInitializationFailed))
                onError?(VoiceInputError.whisperInitializationFailed)
            }
        } else {
            // Need to download model - set up progress tracking
            updateState(.downloadingModel(progress: 0.0, modelName: modelName))
            
            // Start observing download progress
            setupDownloadProgressObserver(for: modelID)
            
            do {
                whisper = try await WhisperKit(
                    WhisperKitConfig(
                        model: modelID,
                        modelRepo: "mlx-community/whisper-\(modelID)-mlx",
                        modelFolder: modelID,
                        verbose: false,
                        logLevel: .error,
                        prewarm: true,
                        load: true,
                        download: true
                    )
                )
                
                // Download completed
                cleanupDownloadObserver()
                modelManager.updateDownloadedModels()
                updateState(.ready)
            } catch {
                AppLogger.error("Failed to download/initialize Whisper", error: error, category: .ai)
                cleanupDownloadObserver()
                updateState(.error(.modelDownloadFailed(error.localizedDescription)))
                onError?(VoiceInputError.modelDownloadFailed(error.localizedDescription))
            }
        }
    }

    private func prepareRecorder() async throws {
        guard whisper != nil else { throw AppError.from(VoiceInputError.whisperNotReady) }
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
        recordingURL = FileManager.default.temporaryDirectory.appendingPathComponent("recording_\(Date().timeIntervalSince1970).wav")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
        audioRecorder?.isMeteringEnabled = true
    }

    // MARK: - Transcription
    private func transcribeAudio(at url: URL) async throws -> String {
        guard let whisper else { throw VoiceInputError.whisperNotReady }
        let result = try await whisper.transcribe(
            audioPath: url.path,
            decodeOptions: DecodingOptions(
                verbose: false,
                task: .transcribe,
                language: "en",
                temperature: 0.0,
                temperatureIncrementOnFallback: 0.2,
                temperatureFallbackCount: 5,
                sampleLength: 224,
                topK: 5,
                usePrefillPrompt: true,
                usePrefillCache: true,
                skipSpecialTokens: true,
                withoutTimestamps: true,
                wordTimestamps: false,
                clipTimestamps: [0],
                suppressBlank: true,
                supressTokens: nil,
                compressionRatioThreshold: 2.4,
                logProbThreshold: -1.0,
                noSpeechThreshold: 0.6
            )
        )
        guard !result.isEmpty else { throw AppError.from(VoiceInputError.transcriptionFailed) }
        let text = result.map { $0.text }.joined(separator: " ")
        return postProcessTranscription(text)
    }

    private func processAudioChunk(_ audioData: [Float]) async {
        guard let whisper else { return }
        do {
            let result = try await whisper.transcribe(
                audioArray: audioData,
                decodeOptions: DecodingOptions(language: "en", temperature: 0.0, withoutTimestamps: true)
            )
            guard let firstResult = result.first else { return }
            let text = firstResult.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            let processed = postProcessTranscription(text)
            await MainActor.run {
                currentTranscription = processed
                onPartialTranscription?(processed)
            }
        } catch {
            AppLogger.debug("Streaming chunk error: \(error)", category: .ai)
        }
    }

    private func processStreamingBuffer(_ buffer: AVAudioPCMBuffer) async {
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData.pointee
        let frames = Int(buffer.frameLength)
        let data = Array(UnsafeBufferPointer(start: channelDataValue, count: frames))
        audioBuffer.append(contentsOf: data)
        if audioBuffer.count >= 16_000 {
            let chunk = Array(audioBuffer.prefix(16_000))
            audioBuffer.removeFirst(16_000)
            Task { await processAudioChunk(chunk) }
        }
        await analyzeAudioBuffer(buffer)
    }

    // MARK: - Waveform
    private func startWaveformTimer() {
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.onWaveformUpdate?(self.waveformBuffer)
            }
        }
    }

    private func stopWaveformTimer() {
        waveformTimer?.invalidate()
        waveformTimer = nil
        waveformBuffer.removeAll()
        onWaveformUpdate?([])
    }

    private func updateAudioLevels() {
        guard let recorder = audioRecorder else { return }
        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)
        let normalized = pow(10, level / 20)
        waveformBuffer.append(normalized)
        if waveformBuffer.count > 50 { waveformBuffer.removeFirst() }
    }

    private func analyzeAudioBuffer(_ buffer: AVAudioPCMBuffer) async {
        guard let channelData = buffer.floatChannelData else { return }
        let data = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelData.pointee[$0] }
        let rms = sqrt(data.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let normalized = min(rms * 10, 1.0)
        await MainActor.run {
            waveformBuffer.append(normalized)
            if waveformBuffer.count > 50 { waveformBuffer.removeFirst() }
        }
    }

    // MARK: - Fitness-Specific Post-Processing
    private func postProcessTranscription(_ text: String) -> String {
        var processed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Fitness-specific corrections
        let corrections: [String: String] = [
            "sets": "sets", "reps": "reps", "cardio": "cardio",
            "hiit": "HIIT", "amrap": "AMRAP", "emom": "EMOM",
            "pr": "PR", "one rm": "1RM", "tabata": "Tabata"
        ]

        for (pattern, replacement) in corrections {
            processed = processed.replacingOccurrences(
                of: pattern, with: replacement, options: [.caseInsensitive]
            )
        }

        return processed
    }
    
    // MARK: - State Management
    private func updateState(_ newState: VoiceInputState) {
        state = newState
        onStateChange?(newState)
    }
    
    // MARK: - Download Progress Tracking
    private func setupDownloadProgressObserver(for modelID: String) {
        // Monitor WhisperKit's download directory for progress
        // This is a simplified approach - in production you'd want more sophisticated progress tracking
        downloadObserver = NotificationCenter.default.addObserver(
            forName: .init("WhisperKitDownloadProgress"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let progress = notification.userInfo?["progress"] as? Double {
                Task { @MainActor in
                    if case .downloadingModel(_, let modelName) = self?.state {
                        self?.updateState(.downloadingModel(progress: progress, modelName: modelName))
                    }
                }
            }
        }
        
        // Simulate progress updates for demo
        // In production, you'd integrate with actual download progress
        Task { [weak self] in
            guard let self else { return }
            var progress = 0.0
            while progress < 1.0 && downloadObserver != nil {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                progress += 0.1
                if case .downloadingModel(_, let modelName) = state {
                    updateState(.downloadingModel(progress: min(progress, 0.95), modelName: modelName))
                }
            }
        }
    }
    
    private func cleanupDownloadObserver() {
        if let observer = downloadObserver {
            NotificationCenter.default.removeObserver(observer)
            downloadObserver = nil
        }
    }
}

