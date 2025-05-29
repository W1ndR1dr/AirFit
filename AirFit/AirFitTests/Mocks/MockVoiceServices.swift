import Foundation
import AVFoundation
@testable import AirFit

// MARK: - Testable VoiceInputManager

@MainActor
@Observable
final class TestableVoiceInputManager: NSObject {
    // MARK: - Published State
    private(set) var isRecording = false
    private(set) var isTranscribing = false
    private(set) var waveformBuffer: [Float] = []
    private(set) var currentTranscription = ""

    // MARK: - Callbacks
    var onTranscription: ((String) -> Void)?
    var onPartialTranscription: ((String) -> Void)?
    var onWaveformUpdate: (([Float]) -> Void)?
    var onError: ((Error) -> Void)?

    // MARK: - Dependencies (Injectable for testing)
    private let modelManager: MockWhisperModelManager
    private let audioSession: MockAVAudioSession
    private var mockWhisper: MockWhisperKit?
    private var waveformTimer: Timer?
    private var recordingURL: URL?

    // MARK: - Initialization
    init(modelManager: MockWhisperModelManager, audioSession: MockAVAudioSession) {
        self.modelManager = modelManager
        self.audioSession = audioSession
        super.init()

        Task { [weak self] in
            await self?.initializeWhisper()
        }
    }

    // MARK: - Permission
    func requestPermission() async throws -> Bool {
        return await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }

    // MARK: - Recording Control
    func startRecording() async throws {
        guard try await requestPermission() else { return }
        try await prepareRecorder()
        isRecording = true
        startWaveformTimer()
    }

    func stopRecording() async -> String? {
        guard isRecording else { return nil }
        stopWaveformTimer()
        isRecording = false
        
        do {
            let text = try await transcribeAudio()
            currentTranscription = text
            onTranscription?(text)
            return text
        } catch {
            onError?(error)
            return nil
        }
    }

    // MARK: - Streaming Transcription
    func startStreamingTranscription() async throws {
        guard try await requestPermission() else { return }
        guard mockWhisper != nil else { throw VoiceInputError.whisperNotReady }
        isTranscribing = true
        startWaveformTimer()
        
        // Simulate streaming transcription
        Task {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            if let result = modelManager.getTranscriptionResult() {
                await MainActor.run {
                    currentTranscription = postProcessTranscription(result)
                    onPartialTranscription?(currentTranscription)
                }
            }
        }
    }

    func stopStreamingTranscription() async {
        guard isTranscribing else { return }
        stopWaveformTimer()
        isTranscribing = false
    }

    // MARK: - Private Setup
    private func initializeWhisper() async {
        if modelManager.getTranscriptionError() != nil {
            await MainActor.run {
                onError?(VoiceInputError.whisperInitializationFailed)
            }
            return
        }
        
        mockWhisper = MockWhisperKit()
        if let result = modelManager.getTranscriptionResult() {
            mockWhisper?.stubTranscriptionResult(result)
        }
    }

    private func prepareRecorder() async throws {
        guard mockWhisper != nil else { throw VoiceInputError.whisperNotReady }
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
        recordingURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_recording.wav")
    }

    // MARK: - Transcription
    private func transcribeAudio() async throws -> String {
        guard let whisper = mockWhisper else { throw VoiceInputError.whisperNotReady }
        
        if let error = modelManager.getTranscriptionError() {
            throw error
        }
        
        let result = try await whisper.transcribe(audioPath: "test_path")
        guard !result.isEmpty else { throw VoiceInputError.transcriptionFailed }
        let text = result.map { $0.text }.joined(separator: " ")
        return postProcessTranscription(text)
    }

    // MARK: - Waveform
    private func startWaveformTimer() {
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                // Simulate waveform data
                let level = Float.random(in: 0...1)
                self.waveformBuffer.append(level)
                if self.waveformBuffer.count > 50 {
                    self.waveformBuffer.removeFirst()
                }
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
}

// MARK: - Mock WhisperModelManager

@MainActor
final class MockWhisperModelManager: ObservableObject, @unchecked Sendable {
    // MARK: - Stubbed Values
    private var optimalModel = "base"
    private var transcriptionResult: String?
    private var transcriptionError: Error?
    private var whisperReady = true
    private var initializationError: Error?
    private var downloadProgress: [String: Double] = [:]
    private var isDownloading: [String: Bool] = [:]
    
    // MARK: - Published Properties (matching real WhisperModelManager)
    @Published var availableModels: [WhisperModel] = []
    @Published var downloadedModels: Set<String> = ["base", "tiny"]
    @Published var activeModel: String = "base"
    
    // MARK: - Model Configuration
    struct WhisperModel: Identifiable {
        let id: String
        let displayName: String
        let size: String
        let sizeBytes: Int
        let accuracy: String
        let speed: String
        let languages: String
        let requiredMemory: UInt64
        let huggingFaceRepo: String
    }
    
    init() {
        availableModels = [
            WhisperModel(
                id: "tiny",
                displayName: "Tiny (39 MB)",
                size: "39 MB",
                sizeBytes: 39_000_000,
                accuracy: "Good",
                speed: "Fastest",
                languages: "English + 98 more",
                requiredMemory: 200_000_000,
                huggingFaceRepo: "mlx-community/whisper-tiny-mlx"
            ),
            WhisperModel(
                id: "base",
                displayName: "Base (74 MB)",
                size: "74 MB",
                sizeBytes: 74_000_000,
                accuracy: "Better",
                speed: "Very Fast",
                languages: "English + 98 more",
                requiredMemory: 500_000_000,
                huggingFaceRepo: "mlx-community/whisper-base-mlx"
            )
        ]
    }
    
    // MARK: - Public Methods (matching real interface)
    func selectOptimalModel() -> String {
        return optimalModel
    }
    
    func downloadModel(_ modelId: String) async throws {
        if let error = initializationError {
            throw error
        }
        
        isDownloading[modelId] = true
        downloadProgress[modelId] = 0.0
        
        // Simulate download progress
        for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
            downloadProgress[modelId] = progress
            try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        
        downloadedModels.insert(modelId)
        isDownloading[modelId] = false
    }
    
    func deleteModel(_ modelId: String) throws {
        downloadedModels.remove(modelId)
        if activeModel == modelId {
            activeModel = downloadedModels.first ?? "base"
        }
    }
    
    func modelPath(for modelId: String) -> URL? {
        guard downloadedModels.contains(modelId) else { return nil }
        return FileManager.default.temporaryDirectory.appendingPathComponent(modelId)
    }
    
    // MARK: - Test Stubbing Methods
    func stubOptimalModel(_ model: String) {
        optimalModel = model
    }
    
    func stubTranscription(_ text: String) {
        transcriptionResult = text
        transcriptionError = nil
    }
    
    func stubTranscriptionError(_ error: Error) {
        transcriptionError = error
        transcriptionResult = nil
    }
    
    func stubWhisperReady(_ ready: Bool) {
        whisperReady = ready
    }
    
    func stubInitializationError(_ error: Error) {
        initializationError = error
    }
    
    func getTranscriptionResult() -> String? {
        if transcriptionError != nil {
            // In real implementation, this would throw
            return nil
        }
        return transcriptionResult
    }
    
    func getTranscriptionError() -> Error? {
        return transcriptionError
    }
    
    func isWhisperReady() -> Bool {
        return whisperReady
    }
    
    func simulatePartialTranscription(_ text: String) {
        // This would be used to trigger partial transcription callbacks
        // Implementation depends on how VoiceInputManager handles streaming
    }
}

// MARK: - Mock AVAudioSession

final class MockAVAudioSession: @unchecked Sendable {
    private let queue = DispatchQueue(label: "MockAVAudioSession", attributes: .concurrent)
    
    private var _recordPermissionResponse = true
    private var _categorySetError: Error?
    private var _activationError: Error?
    private var _isActive = false
    private var _category: AVAudioSession.Category = .playAndRecord
    
    var recordPermissionResponse: Bool {
        get { queue.sync { _recordPermissionResponse } }
        set { queue.async(flags: .barrier) { self._recordPermissionResponse = newValue } }
    }
    
    var categorySetError: Error? {
        get { queue.sync { _categorySetError } }
        set { queue.async(flags: .barrier) { self._categorySetError = newValue } }
    }
    
    var activationError: Error? {
        get { queue.sync { _activationError } }
        set { queue.async(flags: .barrier) { self._activationError = newValue } }
    }
    
    var isActive: Bool {
        get { queue.sync { _isActive } }
        set { queue.async(flags: .barrier) { self._isActive = newValue } }
    }
    
    var category: AVAudioSession.Category {
        get { queue.sync { _category } }
        set { queue.async(flags: .barrier) { self._category = newValue } }
    }
    
    func requestRecordPermission(_ response: @escaping @Sendable (Bool) -> Void) {
        let permission = recordPermissionResponse
        DispatchQueue.main.async {
            response(permission)
        }
    }
    
    func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws {
        if let error = categorySetError {
            throw error
        }
        self.category = category
    }
    
    func setActive(_ active: Bool) throws {
        if let error = activationError {
            throw error
        }
        isActive = active
    }
    
    // MARK: - Test Stubbing
    func stubCategorySetError(_ error: Error?) {
        categorySetError = error
    }
    
    func stubActivationError(_ error: Error?) {
        activationError = error
    }
}

// MARK: - Mock AVAudioRecorder

final class MockAVAudioRecorder: @unchecked Sendable {
    private let queue = DispatchQueue(label: "MockAVAudioRecorder", attributes: .concurrent)
    
    private var _isRecording = false
    private var _isMeteringEnabled = false
    private var _recordingError: Error?
    private var _averagePowerValue: Float = -20.0
    
    private let url: URL
    private let settings: [String: Any]
    
    var isRecording: Bool {
        get { queue.sync { _isRecording } }
        set { queue.async(flags: .barrier) { self._isRecording = newValue } }
    }
    
    var isMeteringEnabled: Bool {
        get { queue.sync { _isMeteringEnabled } }
        set { queue.async(flags: .barrier) { self._isMeteringEnabled = newValue } }
    }
    
    var recordingError: Error? {
        get { queue.sync { _recordingError } }
        set { queue.async(flags: .barrier) { self._recordingError = newValue } }
    }
    
    var averagePowerValue: Float {
        get { queue.sync { _averagePowerValue } }
        set { queue.async(flags: .barrier) { self._averagePowerValue = newValue } }
    }
    
    init(url: URL, settings: [String: Any]) throws {
        self.url = url
        self.settings = settings
        
        if let error = recordingError {
            throw error
        }
    }
    
    func record() -> Bool {
        guard recordingError == nil else { return false }
        isRecording = true
        return true
    }
    
    func stop() {
        isRecording = false
        // Create a dummy audio file for testing
        try? "dummy audio data".write(to: url, atomically: true, encoding: .utf8)
    }
    
    func updateMeters() {
        // Simulate meter updates
    }
    
    func averagePower(forChannel channelNumber: Int) -> Float {
        return averagePowerValue
    }
    
    // MARK: - Test Stubbing
    func stubRecordingError(_ error: Error?) {
        recordingError = error
    }
    
    func stubAveragePower(_ power: Float) {
        averagePowerValue = power
    }
}

// MARK: - Mock WhisperKit

final class MockWhisperKit: @unchecked Sendable {
    private let queue = DispatchQueue(label: "MockWhisperKit", attributes: .concurrent)
    
    private var _transcriptionResult: [TranscriptionResult] = []
    private var _transcriptionError: Error?
    private var _isReady = true
    
    var transcriptionResult: [TranscriptionResult] {
        get { queue.sync { _transcriptionResult } }
        set { queue.async(flags: .barrier) { self._transcriptionResult = newValue } }
    }
    
    var transcriptionError: Error? {
        get { queue.sync { _transcriptionError } }
        set { queue.async(flags: .barrier) { self._transcriptionError = newValue } }
    }
    
    var isReady: Bool {
        get { queue.sync { _isReady } }
        set { queue.async(flags: .barrier) { self._isReady = newValue } }
    }
    
    struct TranscriptionResult: Sendable {
        let text: String
        let segments: [TranscriptionSegment]
        
        init(text: String) {
            self.text = text
            self.segments = [TranscriptionSegment(text: text)]
        }
    }
    
    struct TranscriptionSegment: Sendable {
        let text: String
        let start: Double
        let end: Double
        
        init(text: String, start: Double = 0.0, end: Double = 1.0) {
            self.text = text
            self.start = start
            self.end = end
        }
    }
    
    func transcribe(audioPath: String, decodeOptions: MockDecodeOptions? = nil) async throws -> [TranscriptionResult] {
        if let error = transcriptionError {
            throw error
        }
        
        // Simulate processing time
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        return transcriptionResult
    }
    
    func transcribe(audioArray: [Float], decodeOptions: MockDecodeOptions? = nil) async throws -> [TranscriptionResult] {
        if let error = transcriptionError {
            throw error
        }
        
        // Simulate real-time processing
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        return transcriptionResult
    }
    
    // MARK: - Test Stubbing
    func stubTranscriptionResult(_ text: String) {
        transcriptionResult = [TranscriptionResult(text: text)]
        transcriptionError = nil
    }
    
    func stubTranscriptionError(_ error: Error) {
        transcriptionError = error
        transcriptionResult = []
    }
    
    func stubReady(_ ready: Bool) {
        isReady = ready
    }
}

// MARK: - Mock Decode Options

struct MockDecodeOptions: Sendable {
    let verbose: Bool
    let task: TranscriptionTask
    let language: String?
    let temperature: Float
    let temperatureIncrementOnFallback: Float
    let temperatureFallbackCount: Int
    let sampleLength: Int
    let topK: Int
    let usePrefillPrompt: Bool
    let usePrefillCache: Bool
    let skipSpecialTokens: Bool
    let withoutTimestamps: Bool
    let wordTimestamps: Bool
    let clipTimestamps: [Double]
    let suppressBlank: Bool
    let supressTokens: [Int]?
    let compressionRatioThreshold: Float
    let logProbThreshold: Float
    let noSpeechThreshold: Float
    
    init(
        verbose: Bool = false,
        task: TranscriptionTask = .transcribe,
        language: String? = "en",
        temperature: Float = 0.0,
        temperatureIncrementOnFallback: Float = 0.2,
        temperatureFallbackCount: Int = 5,
        sampleLength: Int = 224,
        topK: Int = 5,
        usePrefillPrompt: Bool = true,
        usePrefillCache: Bool = true,
        skipSpecialTokens: Bool = true,
        withoutTimestamps: Bool = true,
        wordTimestamps: Bool = false,
        clipTimestamps: [Double] = [0],
        suppressBlank: Bool = true,
        supressTokens: [Int]? = nil,
        compressionRatioThreshold: Float = 2.4,
        logProbThreshold: Float = -1.0,
        noSpeechThreshold: Float = 0.6
    ) {
        self.verbose = verbose
        self.task = task
        self.language = language
        self.temperature = temperature
        self.temperatureIncrementOnFallback = temperatureIncrementOnFallback
        self.temperatureFallbackCount = temperatureFallbackCount
        self.sampleLength = sampleLength
        self.topK = topK
        self.usePrefillPrompt = usePrefillPrompt
        self.usePrefillCache = usePrefillCache
        self.skipSpecialTokens = skipSpecialTokens
        self.withoutTimestamps = withoutTimestamps
        self.wordTimestamps = wordTimestamps
        self.clipTimestamps = clipTimestamps
        self.suppressBlank = suppressBlank
        self.supressTokens = supressTokens
        self.compressionRatioThreshold = compressionRatioThreshold
        self.logProbThreshold = logProbThreshold
        self.noSpeechThreshold = noSpeechThreshold
    }
}

enum TranscriptionTask: Sendable {
    case transcribe
    case translate
}

// MARK: - Performance Testing Utilities

final class VoicePerformanceMetrics: @unchecked Sendable {
    static func measureTranscriptionLatency<T>(
        operation: () async throws -> T
    ) async rethrows -> (result: T, latency: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        let latency = endTime - startTime
        return (result, latency)
    }
    
    static func measureMemoryUsage<T>(
        operation: () throws -> T
    ) rethrows -> (result: T, memoryDelta: Int64) {
        let startMemory = getMemoryUsage()
        let result = try operation()
        let endMemory = getMemoryUsage()
        let delta = endMemory - startMemory
        return (result, delta)
    }
    
    private static func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
} 