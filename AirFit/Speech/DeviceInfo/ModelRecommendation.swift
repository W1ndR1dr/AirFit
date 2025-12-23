import Foundation

/// Provides device-specific model recommendations
/// Simplified: Only ONE model needed (no realtime preview, just final transcription)
struct ModelRecommendation: Sendable {

    /// The detected device information
    let deviceInfo: DeviceCapabilities.DeviceInfo

    /// The quality model for transcription (based on RAM)
    let finalModel: ModelDescriptor

    /// Battery-saver alternative
    let batteryModeModel: ModelDescriptor

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
        canRunHighQuality ? "High Quality" : "Balanced"
    }

    /// User-friendly explanation of why this model was chosen
    var optimizationExplanation: String {
        if canRunHighQuality {
            return "Your \(deviceInfo.marketingName) has plenty of power for the best voice recognition quality."
        } else {
            return "Optimized for smooth performance on your \(deviceInfo.marketingName)."
        }
    }

    /// Short tagline for the device
    var deviceTagline: String {
        "Optimized for \(deviceInfo.marketingName)"
    }

    /// Technical details for power users (shown in tooltip)
    var technicalDetails: String {
        """
        Device: \(deviceInfo.identifier)
        RAM: \(deviceInfo.ramGB) GB
        Mode: \(canRunHighQuality ? "High Quality" : "Balanced")

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
        let batterySaver = ModelCatalog.finalDistilLargeV3

        // 8GB+ devices get large-v3-turbo, 6GB devices get distil
        let final: ModelDescriptor
        let canRunHighQuality: Bool

        if deviceInfo.ramGB >= 8 {
            // iPhone 16 Pro, 15 Pro, etc. - use large-v3-turbo
            final = ModelCatalog.finalLargeV3Turbo
            canRunHighQuality = true
        } else {
            // iPhone 15 Plus, etc. - use distil by default
            final = ModelCatalog.finalDistilLargeV3
            canRunHighQuality = false
        }

        return ModelRecommendation(
            deviceInfo: deviceInfo,
            finalModel: final,
            batteryModeModel: batterySaver,
            canRunHighQuality: canRunHighQuality
        )
    }
}

// MARK: - Quality Mode

extension ModelRecommendation {
    /// User-selectable quality mode
    enum QualityMode: String, Codable, Sendable, CaseIterable {
        /// Maximum accuracy (large-v3-turbo if available)
        case highQuality

        /// Battery/heat optimized (distil-large-v3)
        case batterySaver

        var displayName: String {
            switch self {
            case .highQuality: return "High Quality"
            case .batterySaver: return "Battery Saver"
            }
        }

        var description: String {
            switch self {
            case .highQuality:
                return "Best transcription accuracy, may generate more heat"
            case .batterySaver:
                return "Slightly less accurate, cooler operation"
            }
        }

        var iconName: String {
            switch self {
            case .highQuality: return "star.fill"
            case .batterySaver: return "leaf.fill"
            }
        }
    }

    /// Get the final model for a given quality mode
    func finalModel(for mode: QualityMode) -> ModelDescriptor {
        switch mode {
        case .highQuality:
            return canRunHighQuality ? finalModel : batteryModeModel
        case .batterySaver:
            return batteryModeModel
        }
    }

    /// Get all models needed for a given quality mode (just ONE now!)
    func modelsRequired(for mode: QualityMode) -> [ModelDescriptor] {
        [finalModel(for: mode)]
    }
}
