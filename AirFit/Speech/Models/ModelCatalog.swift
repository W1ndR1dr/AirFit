import Foundation

/// Provides the catalog of available WhisperKit models
struct ModelCatalog: Sendable {

    // MARK: - Baked-in Models

    /// All available models for download, ordered by quality (highest first)
    static let allModels: [ModelDescriptor] = [
        finalLargeV3Turbo,
        finalDistilLargeV3,
        realtimeSmallEN
    ]

    /// OpenAI Whisper Large v3 Turbo - Maximum accuracy with intelligent compression
    /// Best for iPhone 15 Pro and newer (8GB+ RAM)
    static let finalLargeV3Turbo = ModelDescriptor(
        id: "large-v3-turbo",
        displayName: "Pro",
        subtitle: "Whisper Large v3 Turbo",
        description: "Highest accuracy transcription powered by OpenAI's flagship model with intelligent compression. Achieves ~2.4% word error rate. Recommended for iPhone 15 Pro and newer with 8GB+ RAM.",
        folderName: "openai_whisper-large-v3-v20240930_turbo_632MB",
        whisperKitModel: "openai_whisper-large-v3-v20240930_turbo_632MB",
        sizeBytes: 645_668_913,
        sha256: nil,
        purpose: .final,
        minRAMGB: 8,
        languages: nil  // Multilingual
    )

    /// Distil-Whisper Large v3 - 6x faster with near-identical accuracy
    /// Optimized for efficiency and thermal management
    static let finalDistilLargeV3 = ModelDescriptor(
        id: "distil-large-v3",
        displayName: "Standard",
        subtitle: "Distil-Whisper Large v3",
        description: "Excellent accuracy with 6x faster processing than the full model. Distilled from Whisper Large v3 by Hugging Face, retaining 99% of accuracy while running cooler. Great for extended use.",
        folderName: "distil-whisper_distil-large-v3_turbo_600MB",
        whisperKitModel: "distil-whisper_distil-large-v3_turbo_600MB",
        sizeBytes: 607_114_331,
        sha256: nil,
        purpose: .final,
        minRAMGB: 6,
        languages: nil  // Multilingual
    )

    /// Whisper Small (English) - Lightweight and fast
    /// Ideal for quick voice notes or older devices
    static let realtimeSmallEN = ModelDescriptor(
        id: "small-en",
        displayName: "Lite",
        subtitle: "Whisper Small (English)",
        description: "Lightweight model optimized for speed. English-only with ~3% word error rate. Perfect for quick voice notes, older devices, or when conserving battery. Uses minimal memory.",
        folderName: "openai_whisper-small.en_217MB",
        whisperKitModel: "openai_whisper-small.en_217MB",
        sizeBytes: 217_878_408,
        sha256: nil,
        purpose: .realtime,
        minRAMGB: 4,
        languages: ["en"]  // English only
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

    /// Get all quality models
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
