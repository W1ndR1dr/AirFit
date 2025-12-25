import Foundation
@preconcurrency import WhisperKit
import os.log

private let adapterLogger = Logger(subsystem: "com.airfit.app", category: "WhisperKitAdapter")

/// Wraps WhisperKit API for transcription
/// Isolates WhisperKit dependency for easier testing and swapping
actor WhisperKitAdapter {

    // MARK: - Types

    struct TranscriptionResult: Sendable {
        let text: String
        let segments: [Segment]
        let language: String
        let processingTime: TimeInterval

        struct Segment: Sendable {
            let text: String
            let start: TimeInterval
            let end: TimeInterval
        }
    }

    enum AdapterError: LocalizedError {
        case modelNotLoaded
        case transcriptionFailed(String)
        case loadingFailed(String)

        var errorDescription: String? {
            switch self {
            case .modelNotLoaded:
                return "Model not loaded"
            case .transcriptionFailed(let reason):
                return "Transcription failed: \(reason)"
            case .loadingFailed(let reason):
                return "Failed to load model: \(reason)"
            }
        }
    }

    // MARK: - Properties

    private var whisperKit: WhisperKit?
    private var currentModelPath: URL?
    private var isLoading = false

    // MARK: - Model Loading

    /// Load a WhisperKit model by variant name (folder name or glob)
    /// WhisperKit handles downloading and caching automatically
    func loadModel(variant: String) async throws {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        unloadModel()

        do {
            adapterLogger.info("🔄 Initializing WhisperKit with model: \(variant)")

            // Use WhisperKit's built-in model management - simpler and more reliable
            // It will download the model if needed and cache it
            let config = WhisperKitConfig(
                model: variant,
                verbose: true,
                logLevel: .debug
            )

            whisperKit = try await WhisperKit(config)
            adapterLogger.info("✅ WhisperKit ready with model: \(variant)")
        } catch {
            adapterLogger.error("❌ WhisperKit init failed: \(error.localizedDescription)")
            throw AdapterError.loadingFailed(error.localizedDescription)
        }
    }

    /// Load a WhisperKit model from a specific path (for pre-downloaded models)
    func loadModel(at path: URL) async throws {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        unloadModel()

        guard FileManager.default.fileExists(atPath: path.path) else {
            throw AdapterError.loadingFailed("Model not found at: \(path.path)")
        }

        do {
            adapterLogger.info("🔄 Loading WhisperKit from: \(path.path)")

            let config = WhisperKitConfig(
                modelFolder: path.path,
                verbose: true,
                logLevel: .debug
            )

            whisperKit = try await WhisperKit(config)
            currentModelPath = path
            adapterLogger.info("✅ WhisperKit model loaded")
        } catch {
            adapterLogger.error("❌ WhisperKit init failed: \(error.localizedDescription)")
            throw AdapterError.loadingFailed(error.localizedDescription)
        }
    }

    /// Unload the current model
    func unloadModel() {
        whisperKit = nil
        currentModelPath = nil
    }

    /// Check if a model is loaded
    func isModelLoaded() -> Bool {
        whisperKit != nil
    }

    /// Get the current model path
    func getModelPath() -> URL? {
        currentModelPath
    }

    // MARK: - Transcription

    /// Transcribe audio samples (16kHz mono Float32)
    func transcribe(
        audioArray: [Float],
        language: String = "en",
        temperature: Float = 0.0
    ) async throws -> TranscriptionResult {
        guard let whisper = whisperKit else {
            throw AdapterError.modelNotLoaded
        }

        let startTime = Date()

        do {
            // Configure decoding options for English-only, stable output
            let options = DecodingOptions(
                language: language,
                temperature: temperature,
                temperatureFallbackCount: 3,
                sampleLength: 224,
                usePrefillPrompt: false,
                usePrefillCache: true,
                skipSpecialTokens: true,
                withoutTimestamps: false,
                clipTimestamps: []
            )

            let results = try await whisper.transcribe(
                audioArray: audioArray,
                decodeOptions: options
            )

            let processingTime = Date().timeIntervalSince(startTime)

            // Combine results
            let text = results.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

            let segments = results.flatMap { result in
                result.segments.map { segment in
                    TranscriptionResult.Segment(
                        text: segment.text,
                        start: TimeInterval(segment.start),
                        end: TimeInterval(segment.end)
                    )
                }
            }

            return TranscriptionResult(
                text: text,
                segments: segments,
                language: language,
                processingTime: processingTime
            )
        } catch {
            throw AdapterError.transcriptionFailed(error.localizedDescription)
        }
    }

    /// Transcribe with callback for streaming results
    func transcribeStreaming(
        audioArray: [Float],
        language: String = "en",
        temperature: Float = 0.0,
        callback: @Sendable @escaping (String) -> Void
    ) async throws -> TranscriptionResult {
        guard let whisper = whisperKit else {
            throw AdapterError.modelNotLoaded
        }

        let startTime = Date()

        do {
            let options = DecodingOptions(
                language: language,
                temperature: temperature,
                temperatureFallbackCount: 3,
                sampleLength: 224,
                usePrefillPrompt: false,
                usePrefillCache: true,
                skipSpecialTokens: true,
                withoutTimestamps: false,
                clipTimestamps: []
            )

            let results = try await whisper.transcribe(
                audioArray: audioArray,
                decodeOptions: options
            ) { progress in
                // Extract current text from progress
                let currentText = progress.text
                if !currentText.isEmpty {
                    callback(currentText)
                }
                return true // Continue transcription
            }

            let processingTime = Date().timeIntervalSince(startTime)

            let text = results.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

            let segments = results.flatMap { result in
                result.segments.map { segment in
                    TranscriptionResult.Segment(
                        text: segment.text,
                        start: TimeInterval(segment.start),
                        end: TimeInterval(segment.end)
                    )
                }
            }

            return TranscriptionResult(
                text: text,
                segments: segments,
                language: language,
                processingTime: processingTime
            )
        } catch {
            throw AdapterError.transcriptionFailed(error.localizedDescription)
        }
    }
}

// MARK: - Convenience

extension WhisperKitAdapter {
    /// Quick transcription for short audio clips
    func quickTranscribe(_ audioArray: [Float]) async throws -> String {
        let result = try await transcribe(audioArray: audioArray)
        return result.text
    }
}
