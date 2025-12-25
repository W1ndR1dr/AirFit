import Foundation

/// Describes a WhisperKit CoreML model available for download
struct ModelDescriptor: Codable, Identifiable, Sendable, Hashable {
    /// Unique identifier (e.g., "small-en-realtime")
    let id: String

    /// User-facing display name
    let displayName: String

    /// Folder name on HuggingFace (e.g., "openai_whisper-small.en_217MB")
    let folderName: String

    /// Model name to pass to WhisperKit (folder name or glob)
    let whisperKitModel: String

    /// Approximate size in bytes
    let sizeBytes: Int64

    /// SHA256 hash for verification (optional)
    let sha256: String?

    /// Model purpose in the transcription lineup
    let purpose: ModelPurpose

    /// Minimum RAM in GB required to run this model
    let minRAMGB: Int

    // MARK: - Computed Properties

    /// Size formatted for display (e.g., "632 MB")
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    /// HuggingFace tree URL for the model folder
    var huggingFaceTreeURL: URL {
        URL(string: "https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/\(folderName)")!
    }

    /// HuggingFace API URL to list files in this model folder (recursive)
    var huggingFaceAPIURL: URL {
        URL(string: "https://huggingface.co/api/models/argmaxinc/whisperkit-coreml/tree/main/\(folderName)?recursive=true")!
    }

    /// Base URL for downloading individual files
    var huggingFaceDownloadBase: URL {
        URL(string: "https://huggingface.co/argmaxinc/whisperkit-coreml/resolve/main/\(folderName)/")!
    }
}

// MARK: - Model Purpose

extension ModelDescriptor {
    /// The role of a model in the transcription lineup
    enum ModelPurpose: String, Codable, Sendable {
        /// Fast model for real-time partial results
        case realtime

        /// High-quality model for final transcription pass
        case final

        var displayName: String {
            switch self {
            case .realtime: return "Fast"
            case .final: return "Quality"
            }
        }

        var description: String {
            switch self {
            case .realtime:
                return "Lowest latency, lightest model"
            case .final:
                return "Higher accuracy and punctuation"
            }
        }

        var icon: String {
            switch self {
            case .realtime: return "bolt.fill"
            case .final: return "sparkles"
            }
        }
    }
}

// MARK: - Install State

/// Tracks the installation state of a model
struct InstalledModel: Codable, Sendable {
    let descriptor: ModelDescriptor
    let installedAt: Date
    let path: String
    let actualSizeBytes: Int64

    var url: URL {
        URL(fileURLWithPath: path)
    }
}

// MARK: - Download Progress

/// Progress update for model downloads
struct ModelDownloadProgress: Sendable {
    let modelId: String
    let bytesDownloaded: Int64
    let totalBytes: Int64
    let currentFile: String?

    var progress: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(bytesDownloaded) / Double(totalBytes)
    }

    var formattedProgress: String {
        let downloaded = ByteCountFormatter.string(fromByteCount: bytesDownloaded, countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        return "\(downloaded) / \(total)"
    }
}
