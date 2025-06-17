import Foundation
import AVFoundation

/// Stub VoiceInputManager - provides the same interface but returns mock data
/// This replaces the actual VoiceInputManager to remove WhisperKit dependency

@MainActor
@Observable
final class VoiceInputManager: NSObject, VoiceInputProtocol, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "voice-input-manager"
    nonisolated var isConfigured: Bool { true } // Always configured for demo
    
    // MARK: - VoiceInputProtocol Properties
    var state = VoiceInputState.idle
    var isRecording = false
    var isTranscribing = false
    var waveformBuffer: [Float] = []
    var currentTranscription = ""
    
    // MARK: - Callbacks
    var onTranscription: ((String) -> Void)?
    var onPartialTranscription: ((String) -> Void)?
    var onWaveformUpdate: (([Float]) -> Void)?
    var onError: ((Error) -> Void)?
    var onStateChange: ((VoiceInputState) -> Void)?
    
    // MARK: - Additional State
    var permissionStatus: AVAudioSession.RecordPermission = .granted
    var isModelReady = true
    var downloadProgress: Double = 1.0
    var errorMessage: String?
    
    // MARK: - Configuration
    // Note: modelManager removed for stub implementation
    private var audioEngine = AVAudioEngine()
    private var audioInputNode: AVAudioInputNode?
    private var isEngineRunning = false
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
    
    func configure() async throws {
        // Stub - always succeeds
        print("[VoiceInputManagerStub] Configured successfully")
    }
    
    func reset() async {
        // Stub implementation
        _ = await stopRecording()
        isRecording = false
        isTranscribing = false
        currentTranscription = ""
        waveformBuffer = []
        state = .idle
        errorMessage = nil
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: ["status": "Voice input stub running"]
        )
    }
    
    // MARK: - VoiceInputProtocol Methods
    
    func initialize() async {
        // Stub implementation - always succeeds
        state = .ready
        onStateChange?(.ready)
    }
    
    func requestPermission() async throws -> Bool {
        // Simulate permission request
        try? await Task.sleep(for: .milliseconds(500))
        permissionStatus = .granted
        return true
    }
    
    func startRecording() async throws {
        guard !isRecording else { return }
        
        // Check permissions
        if permissionStatus != .granted {
            let granted = try await requestPermission()
            guard granted else {
                throw VoiceInputError.notAuthorized
            }
        }
        
        isRecording = true
        state = .recording
        errorMessage = nil
        
        // Simulate recording with mock waveform data
        startMockWaveformSimulation()
    }
    
    func stopRecording() async -> String? {
        guard isRecording else { return nil }
        
        isRecording = false
        state = .transcribing
        
        // Simulate transcription
        simulateTranscription()
        
        // Return mock transcription
        return "Mock transcription result"
    }
    
    func startStreamingTranscription() async throws {
        // Stub implementation for streaming
        isTranscribing = true
        state = .transcribing
        onStateChange?(.transcribing)
        
        // Simulate streaming transcription
        let partialTexts = ["Hello", "Hello there", "Hello there, how", "Hello there, how are you?"]
        for text in partialTexts {
            currentTranscription = text
            onPartialTranscription?(text)
            try await Task.sleep(for: .milliseconds(300))
        }
        
        isTranscribing = false
        state = .ready
        onTranscription?(currentTranscription)
        onStateChange?(.ready)
    }
    
    func stopStreamingTranscription() async {
        isTranscribing = false
        state = .ready
        onStateChange?(.ready)
    }
    
    func cancelRecording() {
        isRecording = false
        state = .idle
        waveformBuffer = []
        currentTranscription = ""
        errorMessage = nil
    }
    
    func transcribeAudioFile(at url: URL) async throws -> String {
        // Simulate transcription delay
        try await Task.sleep(for: .milliseconds(1000))
        
        return "Mock transcription of audio file: \(url.lastPathComponent)"
    }
    
    func setModel(_ modelId: String) async throws {
        // Stub - always succeeds
        print("[VoiceInputManagerStub] Model set to: \(modelId)")
    }
    
    func downloadModelIfNeeded() async throws {
        // Stub - simulate download
        for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
            downloadProgress = progress
            try await Task.sleep(for: .milliseconds(100))
        }
        isModelReady = true
    }
    
    // MARK: - Private Methods
    private func startMockWaveformSimulation() {
        Task {
            while isRecording {
                // Generate mock waveform data
                let newData = (0..<10).map { _ in Float.random(in: 0...1) }
                await MainActor.run {
                    waveformBuffer.append(contentsOf: newData)
                    
                    // Keep only last 100 samples
                    if waveformBuffer.count > 100 {
                        waveformBuffer.removeFirst(waveformBuffer.count - 100)
                    }
                    
                    // Notify callbacks
                    onWaveformUpdate?(waveformBuffer)
                }
                
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }
    
    private func simulateTranscription() {
        Task {
            isTranscribing = true
            
            // Simulate transcription delay
            try? await Task.sleep(for: .milliseconds(1500))
            
            await MainActor.run {
                // Mock transcription results
                let mockResults = [
                    "I want to log my breakfast: two eggs, toast, and coffee",
                    "How many calories did I burn during my workout today?",
                    "Set a reminder for my evening workout at 6 PM",
                    "What's my weekly fitness progress looking like?",
                    "Add a 30-minute bike ride to today's activities",
                    "Show me my nutrition stats for this week"
                ]
                
                currentTranscription = mockResults.randomElement() ?? "Mock transcription result"
                isTranscribing = false
                state = .ready
                
                // Notify callbacks
                onTranscription?(currentTranscription)
                onStateChange?(.ready)
            }
        }
    }
}

// MARK: - Supporting Types
// VoiceInputError is defined in VoiceInputState.swift

/// Stub WhisperModelManager 
@MainActor
final class WhisperModelManager: ObservableObject {
    enum ModelError: Error, LocalizedError, Sendable {
        case modelNotFound
        case insufficientStorage
        case downloadFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .modelNotFound:
                return "Model not found"
            case .insufficientStorage:
                return "Not enough storage space for model"
            case .downloadFailed(let reason):
                return "Download failed: \(reason)"
            }
        }
    }
    
    var availableModels: [WhisperModel] = [
        WhisperModel(
            id: "tiny",
            displayName: "Tiny (40 MB)",
            name: "Tiny",
            size: "40 MB",
            sizeBytes: 40_000_000,
            accuracy: "Good",
            speed: "Fastest",
            languages: "English + 98 more",
            requiredMemory: 200_000_000,
            huggingFaceRepo: "mlx-community/whisper-tiny-mlx",
            description: "Fastest, basic accuracy"
        ),
        WhisperModel(
            id: "base",
            displayName: "Base (74 MB)",
            name: "Base",
            size: "74 MB",
            sizeBytes: 74_000_000,
            accuracy: "Better",
            speed: "Very Fast",
            languages: "English + 98 more",
            requiredMemory: 500_000_000,
            huggingFaceRepo: "mlx-community/whisper-base-mlx",
            description: "Good balance of speed and accuracy"
        ),
        WhisperModel(
            id: "small",
            displayName: "Small (244 MB)",
            name: "Small",
            size: "244 MB",
            sizeBytes: 244_000_000,
            accuracy: "Very Good",
            speed: "Moderate",
            languages: "Multi",
            requiredMemory: 3_000_000_000,
            huggingFaceRepo: "mlx-community/whisper-small-mlx",
            description: "Better accuracy, slower"
        )
    ]
    
    var downloadedModels: Set<String> = ["tiny"]
    var activeModel: String = "tiny"
    
    func selectOptimalModel() -> String {
        return "tiny" // Always return the smallest model for demo
    }
    
    func downloadModel(_ modelId: String) async throws {
        // Simulate download
        try await Task.sleep(for: .milliseconds(1000))
        downloadedModels.insert(modelId)
    }
    
    func deleteModel(_ modelId: String) throws {
        downloadedModels.remove(modelId)
    }
    
    func modelPath(for modelId: String) -> URL? {
        // Return a mock path
        return URL(fileURLWithPath: "/tmp/whisper_\(modelId)")
    }
    
    func isModelDownloaded(_ modelId: String) -> Bool {
        return downloadedModels.contains(modelId)
    }
    
    func getModelConfiguration(_ modelId: String) -> WhisperModel? {
        return availableModels.first { $0.id == modelId }
    }
    
    func freeUpSpace() async throws {
        // Stub implementation
    }
    
    func ensureModelSpace(for modelId: String) async throws -> Bool {
        return true // Always have space in demo
    }
    
    func updateDownloadedModels() {
        // Stub implementation
    }
    
    func clearUnusedModels() throws {
        // Stub implementation - simulate clearing unused models
        print("[WhisperModelManagerStub] Cleared unused models")
    }
    
    struct WhisperModel: Identifiable {
        let id: String
        let displayName: String
        let name: String
        let size: String
        let sizeBytes: Int
        let accuracy: String
        let speed: String
        let languages: String
        let requiredMemory: UInt64
        let huggingFaceRepo: String
        let description: String
    }
}