import Foundation

/// Provides device-specific model recommendations
/// Single-pass: one model per transcription
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
            return "Auto picked the highest-accuracy model based on your RAM and thermal headroom."
        case ModelCatalog.finalDistilLargeV3.id:
            return "Auto picked a balanced model for accuracy with lower heat."
        default:
            return "Auto picked the lightest model for stability and battery."
        }
    }

    /// Short tagline for the device
    var deviceTagline: String {
        "Auto-selected \(finalModel.displayName) for \(deviceInfo.marketingName)"
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
            case .auto: return "Auto (Recommended)"
            case .highQuality: return "Best Quality"
            case .batterySaver: return "Balanced"
            case .fast: return "Fast"
            }
        }

        var description: String {
            switch self {
            case .auto:
                return "Best balance for your hardware"
            case .highQuality:
                return "Highest accuracy, more heat and memory"
            case .batterySaver:
                return "Great accuracy with cooler operation"
            case .fast:
                return "Lowest latency, lightest model"
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
