import Foundation

/// Provides device-specific model recommendations
/// Simplified: Only ONE model needed (no realtime preview, just final transcription)
struct ModelRecommendation: Sendable {

    /// The detected device information
    let deviceInfo: DeviceCapabilities.DeviceInfo

    /// The auto-selected model for transcription (based on RAM)
    let finalModel: ModelDescriptor

    /// Balanced alternative (lower heat, lower power)
    let batteryModeModel: ModelDescriptor

    /// Fast alternative (lightest model)
    let fastModel: ModelDescriptor

    /// Whether this device can run the highest quality models
    let canRunHighQuality: Bool

    // MARK: - Computed Properties

    /// Only ONE model required now (simpler!)
    var requiredModels: [ModelDescriptor] {
        [finalModel]
    }

    /// Alias for backward compatibility
    var realtimeModel: ModelDescriptor {
        finalModel  // We use the same model for everything now
    }

    /// Total size of required models
    var requiredSize: Int64 {
        requiredModels.reduce(0) { $0 + $1.sizeBytes }
    }

    /// Formatted total size
    var formattedRequiredSize: String {
        ByteCountFormatter.string(fromByteCount: requiredSize, countStyle: .file)
    }

    /// Quality level description
    var qualityDescription: String {
        finalModel.displayName
    }

    /// User-friendly explanation of why this model was chosen
    var optimizationExplanation: String {
        switch finalModel.id {
        case ModelCatalog.finalLargeV3Turbo.id:
            return "Your \(deviceInfo.marketingName) has \(deviceInfo.ramGB)GB RAM—perfect for our highest-accuracy Pro model."
        case ModelCatalog.finalDistilLargeV3.id:
            return "Standard mode balances accuracy and efficiency for your \(deviceInfo.marketingName)."
        default:
            return "Lite mode selected for fast, reliable transcription on your device."
        }
    }

    /// Short tagline for the device
    var deviceTagline: String {
        "Auto-selected for \(deviceInfo.marketingName)"
    }

    /// Technical details for power users (shown in tooltip)
    var technicalDetails: String {
        """
        Device: \(deviceInfo.identifier)
        RAM: \(deviceInfo.ramGB) GB
        Auto Mode: \(finalModel.displayName)

        Model: \(finalModel.displayName) (\(finalModel.formattedSize))
        """
    }

    // MARK: - Factory

    /// Generate recommendation for the current device
    static func forCurrentDevice() async -> ModelRecommendation {
        let deviceInfo = await DeviceCapabilities.shared.detect()
        return forDevice(deviceInfo)
    }

    /// Generate recommendation for a specific device
    static func forDevice(_ deviceInfo: DeviceCapabilities.DeviceInfo) -> ModelRecommendation {
        let fastModel = ModelCatalog.realtimeSmallEN
        let balancedModel = deviceInfo.ramGB >= 6 ? ModelCatalog.finalDistilLargeV3 : fastModel

        // 8GB+ devices get large-v3-turbo, 6GB devices get distil, older devices get small
        let final: ModelDescriptor
        let canRunHighQuality: Bool

        if deviceInfo.ramGB >= 8 {
            // iPhone 16 Pro, 15 Pro, etc. - use large-v3-turbo
            final = ModelCatalog.finalLargeV3Turbo
            canRunHighQuality = true
        } else if deviceInfo.ramGB >= 6 {
            // iPhone 15 Plus, etc. - use distil by default
            final = ModelCatalog.finalDistilLargeV3
            canRunHighQuality = false
        } else {
            // Older devices - use small for stability
            final = fastModel
            canRunHighQuality = false
        }

        return ModelRecommendation(
            deviceInfo: deviceInfo,
            finalModel: final,
            batteryModeModel: balancedModel,
            fastModel: fastModel,
            canRunHighQuality: canRunHighQuality
        )
    }
}

// MARK: - Quality Mode

extension ModelRecommendation {
    /// User-selectable quality mode
    enum QualityMode: String, Codable, Sendable, CaseIterable {
        /// Auto-select the best model for the device
        case auto

        /// Maximum accuracy (large-v3-turbo if available)
        case highQuality

        /// Balanced accuracy and power (distil-large-v3)
        case batterySaver

        /// Fastest, lightest option (small.en)
        case fast

        var displayName: String {
            switch self {
            case .auto: return "Auto"
            case .highQuality: return "Pro"
            case .batterySaver: return "Standard"
            case .fast: return "Lite"
            }
        }

        var subtitle: String {
            switch self {
            case .auto: return "Recommended"
            case .highQuality: return "Whisper Large v3 Turbo"
            case .batterySaver: return "Distil-Whisper Large v3"
            case .fast: return "Whisper Small"
            }
        }

        var description: String {
            switch self {
            case .auto:
                return "Automatically selects the best model based on your device's memory and processor"
            case .highQuality:
                return "Maximum transcription accuracy. May use more battery during extended use."
            case .batterySaver:
                return "Near-identical accuracy with 6x faster processing. Optimized for efficiency."
            case .fast:
                return "Fastest processing with smallest download. English only."
            }
        }

        var iconName: String {
            switch self {
            case .auto: return "sparkles"
            case .highQuality: return "star.fill"
            case .batterySaver: return "leaf.fill"
            case .fast: return "bolt.fill"
            }
        }

        /// Detailed tooltip for info buttons
        var tooltip: String {
            switch self {
            case .auto:
                return "Your device is analyzed to pick the optimal model. High-RAM devices (8GB+) get Pro, mid-range (6GB) get Standard, and older devices get Lite."
            case .highQuality:
                return "OpenAI Whisper Large v3 Turbo with intelligent compression. ~2.4% word error rate. Requires 8GB+ RAM. Best transcription quality available."
            case .batterySaver:
                return "Distil-Whisper Large v3 by Hugging Face. 6x faster than Pro with 99% of the accuracy. Runs cooler for extended recording sessions."
            case .fast:
                return "Whisper Small optimized for English. ~3% word error rate. Only 217 MB download. Ideal for quick voice notes or limited storage."
            }
        }
    }

    /// Get the final model for a given quality mode
    func model(for mode: QualityMode) -> ModelDescriptor {
        switch mode {
        case .auto:
            return finalModel
        case .highQuality:
            return canRunHighQuality ? finalModel : batteryModeModel
        case .batterySaver:
            return batteryModeModel
        case .fast:
            return fastModel
        }
    }

    /// Get all models needed for a given quality mode (just ONE now!)
    func modelsRequired(for mode: QualityMode) -> [ModelDescriptor] {
        [model(for: mode)]
    }
}
