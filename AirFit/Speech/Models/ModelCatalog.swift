import Foundation

/// Provides the catalog of available WhisperKit models
struct ModelCatalog: Sendable {

    // MARK: - Baked-in Models

    /// All available models for download
    static let allModels: [ModelDescriptor] = [
        realtimeSmallEN,
        finalLargeV3Turbo,
        finalDistilLargeV3
    ]

    /// Small English model for fast, lightweight transcription
    /// Note: whisperKitModel uses full folder names to avoid ambiguous matches
    static let realtimeSmallEN = ModelDescriptor(
        id: "small-en-realtime",
        displayName: "Fast",
        folderName: "openai_whisper-small.en_217MB",
        whisperKitModel: "openai_whisper-small.en_217MB",
        sizeBytes: 217_878_408,
        sha256: nil,
        purpose: .realtime,
        minRAMGB: 4
    )

    /// Large v3 Turbo for maximum accuracy final pass
    /// Note: whisperKitModel uses full folder names to avoid ambiguous matches
    static let finalLargeV3Turbo = ModelDescriptor(
        id: "large-v3-turbo",
        displayName: "Best Quality",
        folderName: "openai_whisper-large-v3-v20240930_turbo_632MB",
        whisperKitModel: "openai_whisper-large-v3-v20240930_turbo_632MB",
        sizeBytes: 645_668_913,
        sha256: nil,
        purpose: .final,
        minRAMGB: 8
    )

    /// Distil Large v3 Turbo for balanced performance
    /// Note: whisperKitModel uses full folder names to avoid ambiguous matches
    static let finalDistilLargeV3 = ModelDescriptor(
        id: "distil-large-v3",
        displayName: "Balanced",
        folderName: "distil-whisper_distil-large-v3_turbo_600MB",
        whisperKitModel: "distil-whisper_distil-large-v3_turbo_600MB",
        sizeBytes: 607_114_331,
        sha256: nil,
        purpose: .final,
        minRAMGB: 6
    )

    // MARK: - Lookup

    /// Find a model by ID
    static func model(withId id: String) -> ModelDescriptor? {
        allModels.first { $0.id == id }
    }

    /// Get all realtime models
    static var realtimeModels: [ModelDescriptor] {
        allModels.filter { $0.purpose == .realtime }
    }

    /// Get all final pass models
    static var finalModels: [ModelDescriptor] {
        allModels.filter { $0.purpose == .final }
    }

    // MARK: - Size Calculations

    /// Total size of all models
    static var totalSize: Int64 {
        allModels.reduce(0) { $0 + $1.sizeBytes }
    }

    /// Total size formatted
    static var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

// MARK: - HuggingFace API Response

/// Response from HuggingFace tree API listing files in a model folder
struct HuggingFaceFileInfo: Codable, Sendable {
    let path: String
    let size: Int64?
    let type: String  // "file" or "directory"

    var isFile: Bool {
        type == "file"
    }

    /// Download URL for this file
    /// Note: path already includes folder name from recursive API (e.g., "openai_whisper-small.en_217MB/file.json")
    var downloadURL: URL {
        URL(string: "https://huggingface.co/argmaxinc/whisperkit-coreml/resolve/main/\(path)")!
    }

    /// Get the relative path within the model folder (strips the folder prefix)
    func relativePath(strippingFolder folder: String) -> String {
        if path.hasPrefix(folder + "/") {
            return String(path.dropFirst(folder.count + 1))
        }
        return path
    }
}
