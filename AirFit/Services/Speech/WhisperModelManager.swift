import AVFoundation
import Combine
import Foundation
@preconcurrency import WhisperKit

/// Manages WhisperKit model lifecycle including downloading, loading, and transcription
@MainActor
final class WhisperModelManager: ObservableObject {
    // MARK: - Types

    enum ModelError: LocalizedError {
        case modelNotFound
        case insufficientStorage
        case downloadFailed(reason: String)
        case loadingFailed(reason: String)
        case transcriptionFailed(reason: String)
        case invalidAudioFormat
        case modelNotLoaded

        var errorDescription: String? {
            switch self {
            case .modelNotFound:
                return "Whisper model not found. Please download it first."
            case .insufficientStorage:
                return "Insufficient storage space for model download."
            case .downloadFailed(let reason):
                return "Model download failed: \(reason)"
            case .loadingFailed(let reason):
                return "Failed to load model: \(reason)"
            case .transcriptionFailed(let reason):
                return "Transcription failed: \(reason)"
            case .invalidAudioFormat:
                return "Invalid audio format for transcription."
            case .modelNotLoaded:
                return "Model not loaded. Please wait for initialization."
            }
        }
    }

    enum ModelSize: String, CaseIterable {
        case tiny = "tiny"
        case base = "base"
        case small = "small"
        case medium = "medium"
        case large = "large-v3-turbo"

        var displayName: String {
            switch self {
            case .tiny: return "Tiny (39MB)"
            case .base: return "Base (74MB)"
            case .small: return "Small (244MB)"
            case .medium: return "Medium (769MB)"
            case .large: return "Large Turbo (400MB)"
            }
        }

        var whisperKitModelName: String {
            // WhisperKit will automatically select the Q4 quantized version
            return rawValue
        }

        var approximateSize: Int64 {
            switch self {
            case .tiny: return 39_000_000
            case .base: return 74_000_000
            case .small: return 244_000_000
            case .medium: return 769_000_000
            case .large: return 400_000_000 // Q4 quantized
            }
        }
    }

    enum ModelState: Equatable {
        case notDownloaded
        case downloading(progress: Double)
        case downloaded
        case loading
        case ready
        case error(Error)

        static func == (lhs: ModelState, rhs: ModelState) -> Bool {
            switch (lhs, rhs) {
            case (.notDownloaded, .notDownloaded),
                 (.downloaded, .downloaded),
                 (.loading, .loading),
                 (.ready, .ready):
                return true
            case let (.downloading(p1), .downloading(p2)):
                return p1 == p2
            case (.error, .error):
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Properties

    @Published private(set) var modelState: ModelState = .notDownloaded
    @Published private(set) var currentModelSize: ModelSize = .large
    @Published private(set) var downloadProgress: Double = 0.0

    private var whisperKit: WhisperKit?
    private var downloadTask: Task<Void, Error>?

    // MARK: - Initialization
    init() {
        AppLogger.info("WhisperModelManager initialized", category: .services)
    }

    // MARK: - Model Management

    /// Check if a model is downloaded
    func isModelDownloaded(_ modelSize: ModelSize) async -> Bool {
        // WhisperKit handles model management internally
        // Check if model exists in recommended folder
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        let modelFolder = documentsUrl.appendingPathComponent("WhisperModels")
        let modelPath = modelFolder.appendingPathComponent(modelSize.whisperKitModelName)
        return FileManager.default.fileExists(atPath: modelPath.path)
    }

    /// Download a specific model size
    func downloadModel(_ modelSize: ModelSize) async throws {
        currentModelSize = modelSize
        modelState = .downloading(progress: 0.0)
        
        // Cancel any existing download
        downloadTask?.cancel()
        
        // Create new download task
        downloadTask = Task {
            do {
                // WhisperKit will handle the download automatically
                AppLogger.info("Downloading WhisperKit model: \(modelSize.whisperKitModelName)", category: .services)

                modelState = .loading

                // Initialize WhisperKit with the specified model
                // This will trigger download if needed
                whisperKit = try await WhisperKit(
                    model: modelSize.whisperKitModelName,
                    modelFolder: nil,
                    computeOptions: ModelComputeOptions(audioEncoderCompute: .cpuAndGPU),
                    download: true
                )

                modelState = .ready
                downloadProgress = 1.0

                AppLogger.info("WhisperKit model ready: \(modelSize.whisperKitModelName)", category: .services)

            } catch {
                if Task.isCancelled {
                    modelState = .notDownloaded
                    AppLogger.info("Model download cancelled", category: .services)
                } else {
                    modelState = .error(error)
                    throw ModelError.downloadFailed(reason: error.localizedDescription)
                }
            }
        }
        
        try await downloadTask?.value
    }

    /// Load a previously downloaded model
    func loadModel(_ modelSize: ModelSize) async throws {
        currentModelSize = modelSize
        modelState = .loading

        do {
            // Initialize WhisperKit with the specified model
            whisperKit = try await WhisperKit(
                model: modelSize.whisperKitModelName,
                modelFolder: nil,
                computeOptions: ModelComputeOptions(audioEncoderCompute: .cpuAndGPU),
                download: false
            )

            modelState = .ready
            AppLogger.info("WhisperKit model loaded: \(modelSize.whisperKitModelName)", category: .services)

        } catch {
            modelState = .error(error)
            throw ModelError.loadingFailed(reason: error.localizedDescription)
        }
    }

    /// Delete a downloaded model
    func deleteModel(_ modelSize: ModelSize) async throws {
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "WhisperModelManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        let modelFolder = documentsUrl.appendingPathComponent("WhisperModels")
        let modelPath = modelFolder.appendingPathComponent(modelSize.whisperKitModelName)

        if FileManager.default.fileExists(atPath: modelPath.path) {
            try FileManager.default.removeItem(at: modelPath)
            AppLogger.info("Deleted model: \(modelSize.whisperKitModelName)", category: .services)
        }

        // If this was the current model, reset state
        if modelSize == currentModelSize {
            whisperKit = nil
            modelState = .notDownloaded
        }
    }

    /// Get available storage space
    func getAvailableStorage() -> Int64 {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return 0
        }

        do {
            let resourceValues = try documentDirectory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            return resourceValues.volumeAvailableCapacityForImportantUsage ?? 0
        } catch {
            AppLogger.error("Failed to get available storage", error: error, category: .services)
            return 0
        }
    }

    /// Cancel ongoing download
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        modelState = .notDownloaded
        downloadProgress = 0.0
        AppLogger.info("Download cancelled", category: .services)
    }
    
    /// Calculate storage used by downloaded models
    func calculateStorageUsed() -> Int64 {
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return 0
        }
        let modelFolder = documentsUrl.appendingPathComponent("WhisperModels")
        
        guard FileManager.default.fileExists(atPath: modelFolder.path) else {
            return 0
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: modelFolder,
                includingPropertiesForKeys: [.fileSizeKey],
                options: .skipsHiddenFiles
            )
            
            return try files.reduce(0) { total, file in
                let resourceValues = try file.resourceValues(forKeys: [URLResourceKey.fileSizeKey])
                let fileSize = resourceValues.fileSize ?? 0
                return total + Int64(fileSize)
            }
        } catch {
            AppLogger.error("Failed to calculate storage used", error: error, category: .services)
            return 0
        }
    }
    
    // MARK: - Transcription

    /// Transcribe audio buffer
    func transcribe(_ audioBuffer: AVAudioPCMBuffer) async throws -> String {
        guard let whisperKit = whisperKit else {
            throw ModelError.modelNotLoaded
        }

        guard case .ready = modelState else {
            throw ModelError.modelNotLoaded
        }

        // Convert buffer to temporary file for WhisperKit
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).wav")

        try writeBufferToFile(audioBuffer, url: tempURL)

        defer {
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)
        }

        // Transcribe with WhisperKit
        let results = try await whisperKit.transcribe(
            audioPath: tempURL.path,
            decodeOptions: DecodingOptions(
                language: "en",
                temperature: 0,
                sampleLength: 60, // 60 seconds max
                usePrefillPrompt: true,
                skipSpecialTokens: true
            )
        )

        // Get the transcription text
        let transcription = results.map { $0.text }.joined(separator: " ")

        return transcription
    }

    /// Transcribe audio file
    func transcribe(audioPath: String) async throws -> String {
        guard let whisperKit = whisperKit else {
            throw ModelError.modelNotLoaded
        }

        guard case .ready = modelState else {
            throw ModelError.modelNotLoaded
        }

        // Transcribe with WhisperKit
        let results = try await whisperKit.transcribe(
            audioPath: audioPath,
            decodeOptions: DecodingOptions(
                language: "en",
                temperature: 0,
                sampleLength: 60, // 60 seconds max
                usePrefillPrompt: true,
                skipSpecialTokens: true
            )
        )

        // Get the transcription text
        let transcription = results.map { $0.text }.joined(separator: " ")

        return transcription
    }

    // MARK: - Utilities

    private func writeBufferToFile(_ buffer: AVAudioPCMBuffer, url: URL) throws {
        let audioFile = try AVAudioFile(
            forWriting: url,
            settings: buffer.format.settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )

        try audioFile.write(from: buffer)
    }
}
