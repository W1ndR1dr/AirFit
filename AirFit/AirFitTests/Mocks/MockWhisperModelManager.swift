import Foundation
@testable import AirFit

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