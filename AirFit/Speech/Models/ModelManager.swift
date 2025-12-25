import Foundation
import SwiftUI
import Network
@preconcurrency import WhisperKit
import os.log

private let logger = Logger(subsystem: "com.airfit.app", category: "ModelManager")

/// Result of a download attempt when WiFi-only mode is enabled
enum DownloadAttemptResult {
    /// Download started successfully
    case started
    /// User is on cellular and WiFi-only is enabled - needs confirmation
    case needsCellularConfirmation
}

/// Coordinates model management: catalog, downloads, storage, and recommendations
/// Uses WhisperKit's built-in download mechanism for proper CoreML model handling
@Observable
@MainActor
final class ModelManager {
    static let shared = ModelManager()

    // MARK: - Published State

    /// Current download progress by model ID (0.0 - 1.0)
    private(set) var downloadProgress: [String: Double] = [:]

    /// Whether device is currently on WiFi (vs cellular)
    private(set) var isOnWiFi: Bool = true

    /// Detailed progress for active downloads
    private(set) var downloadDetails: [String: ModelDownloadProgress] = [:]

    /// Whether any download is in progress
    private(set) var isDownloading: Bool = false

    /// Current error message (if any)
    private(set) var errorMessage: String?

    /// Cached device recommendation
    private(set) var recommendation: ModelRecommendation?

    /// List of installed models
    private(set) var installedModels: [InstalledModel] = []

    /// Whether the store has been loaded
    private(set) var isLoaded: Bool = false

    // MARK: - Private Properties

    private var activeDownloadTasks: [String: Task<Void, Never>] = [:]
    private let qualityModeKey = "speechQualityMode"
    private let legacyBatteryModeKey = "speechBatteryMode"
    private let networkMonitor = NWPathMonitor()

    // MARK: - Initialization

    private init() {
        startNetworkMonitoring()
    }

    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnWiFi = path.usesInterfaceType(.wifi)
            }
        }
        networkMonitor.start(queue: DispatchQueue.global(qos: .utility))
    }

    // MARK: - Public API

    /// Load the model store and device recommendation
    func load() async {
        guard !isLoaded else { return }

        do {
            try await ModelStore.shared.load()
            recommendation = await ModelRecommendation.forCurrentDevice()
            await refreshInstalledModels()
            isLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Refresh the list of installed models
    func refreshInstalledModels() async {
        installedModels = await ModelStore.shared.getInstalledModels()
    }

    /// Check if all required models are installed
    func hasRequiredModels() async -> Bool {
        guard let rec = recommendation else {
            logger.info("📦 No recommendation, loading...")
            await load()
            guard let rec = recommendation else {
                logger.warning("📦 Still no recommendation after load, returning false")
                return false
            }
            let required = rec.modelsRequired(for: currentQualityMode())
            let hasModels = await ModelStore.shared.hasRequiredModels(required)
            logger.info("📦 hasRequiredModels after load: \(hasModels)")
            logger.info("📦 Required models: \(required.map { $0.id })")
            return hasModels
        }
        let required = rec.modelsRequired(for: currentQualityMode())
        let hasModels = await ModelStore.shared.hasRequiredModels(required)
        logger.info("📦 hasRequiredModels: \(hasModels)")
        logger.info("📦 Required models: \(required.map { $0.id })")
        return hasModels
    }

    /// Check if a specific model is installed
    func isInstalled(_ model: ModelDescriptor) async -> Bool {
        await ModelStore.shared.isInstalled(model)
    }

    /// Get the path to an installed model
    func getModelPath(_ model: ModelDescriptor) async -> URL? {
        await ModelStore.shared.getPath(for: model)
    }

    /// Attempt to download a model, checking network status first
    /// Returns `.needsCellularConfirmation` if on cellular and wifiOnly is true
    /// Use `downloadModel(_:)` directly to bypass WiFi check (e.g., after user confirmation)
    func attemptDownload(_ model: ModelDescriptor, wifiOnly: Bool) -> DownloadAttemptResult {
        if wifiOnly && !isOnWiFi {
            return .needsCellularConfirmation
        }
        Task {
            await downloadModel(model)
        }
        return .started
    }

    /// Download a model using WhisperKit's built-in download mechanism
    /// This ensures proper CoreML model compilation and folder structure
    /// Note: This bypasses WiFi check - use `attemptDownload` for WiFi-aware downloads
    func downloadModel(_ model: ModelDescriptor) async {
        logger.info("📥 Starting WhisperKit download for \(model.id) (variant: \(model.whisperKitModel))")
        isDownloading = true
        downloadProgress[model.id] = 0
        errorMessage = nil

        // Cancel any existing download for this model
        activeDownloadTasks[model.id]?.cancel()

        let task = Task { @MainActor in
            do {
                // Use WhisperKit's built-in download - handles CoreML compilation properly
                // Capture model properties before closure to satisfy Sendable
                let modelId = model.id
                let sizeBytes = model.sizeBytes

                let modelPath = try await WhisperKit.download(
                    variant: model.whisperKitModel,
                    progressCallback: { @Sendable progress in
                        let fractionComplete = progress.fractionCompleted
                        Task { @MainActor in
                            ModelManager.shared.downloadProgress[modelId] = fractionComplete
                            ModelManager.shared.downloadDetails[modelId] = ModelDownloadProgress(
                                modelId: modelId,
                                bytesDownloaded: Int64(fractionComplete * Double(sizeBytes)),
                                totalBytes: sizeBytes,
                                currentFile: nil
                            )
                        }
                    }
                )

                // Mark as installed in our store
                logger.info("📥 WhisperKit download complete for \(model.id)")
                logger.info("📥 Model path: \(modelPath.path)")

                try await ModelStore.shared.markInstalled(model, at: modelPath)

                downloadProgress.removeValue(forKey: model.id)
                downloadDetails.removeValue(forKey: model.id)
                await refreshInstalledModels()

            } catch {
                logger.error("📥 WhisperKit download FAILED for \(model.id): \(error.localizedDescription)")
                downloadProgress.removeValue(forKey: model.id)
                downloadDetails.removeValue(forKey: model.id)
                errorMessage = error.localizedDescription
            }
        }

        activeDownloadTasks[model.id] = task

        // Wait for the download to complete
        _ = await task.result

        activeDownloadTasks.removeValue(forKey: model.id)
        isDownloading = !downloadProgress.isEmpty
    }

    /// Attempt to download all recommended models, checking network status first
    /// Returns `.needsCellularConfirmation` if on cellular and wifiOnly is true
    func attemptDownloadRecommendedModels(wifiOnly: Bool) -> DownloadAttemptResult {
        if wifiOnly && !isOnWiFi {
            return .needsCellularConfirmation
        }
        Task {
            await downloadRecommendedModels()
        }
        return .started
    }

    /// Download all recommended models
    /// Note: This bypasses WiFi check - use `attemptDownloadRecommendedModels` for WiFi-aware downloads
    func downloadRecommendedModels() async {
        guard let rec = recommendation else { return }
        let required = rec.modelsRequired(for: currentQualityMode())
        for model in required {
            let installed = await isInstalled(model)
            if !installed {
                await downloadModel(model)
            }
        }
    }

    /// Cancel a model download
    func cancelDownload(_ modelId: String) async {
        activeDownloadTasks[modelId]?.cancel()
        activeDownloadTasks.removeValue(forKey: modelId)
        downloadProgress.removeValue(forKey: modelId)
        downloadDetails.removeValue(forKey: modelId)
        isDownloading = !downloadProgress.isEmpty
    }

    /// Cancel all downloads
    func cancelAllDownloads() async {
        for (_, task) in activeDownloadTasks {
            task.cancel()
        }
        activeDownloadTasks.removeAll()
        downloadProgress.removeAll()
        downloadDetails.removeAll()
        isDownloading = false
    }

    /// Delete an installed model
    func deleteModel(_ model: ModelDescriptor) async {
        do {
            try await ModelStore.shared.delete(model)
            await refreshInstalledModels()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Delete all installed models
    func deleteAllModels() async {
        // Cancel any in-progress downloads first
        await cancelAllDownloads()

        // Delete each installed model
        for installed in installedModels {
            do {
                try await ModelStore.shared.delete(installed.descriptor)
            } catch {
                logger.error("Failed to delete model \(installed.descriptor.id): \(error.localizedDescription)")
            }
        }
        await refreshInstalledModels()
    }

    /// Check if any models are installed
    var hasInstalledModels: Bool {
        !installedModels.isEmpty
    }

    /// Get total disk usage
    func totalDiskUsage() async -> Int64 {
        await ModelStore.shared.totalDiskUsage()
    }

    /// Formatted disk usage
    func formattedDiskUsage() async -> String {
        await ModelStore.shared.formattedDiskUsage()
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    /// Current user-selected quality mode (with legacy fallback)
    func currentQualityMode() -> ModelRecommendation.QualityMode {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: qualityModeKey),
           let mode = ModelRecommendation.QualityMode(rawValue: raw) {
            return mode
        }
        return defaults.bool(forKey: legacyBatteryModeKey) ? .batterySaver : .auto
    }

    /// Selected model descriptor for the current quality mode
    func selectedModelDescriptor() -> ModelDescriptor? {
        guard let rec = recommendation else { return nil }
        return rec.model(for: currentQualityMode())
    }

    /// Required models for the current quality mode
    func requiredModels() -> [ModelDescriptor] {
        guard let rec = recommendation else { return [] }
        return rec.modelsRequired(for: currentQualityMode())
    }
}

// MARK: - Model Access for Transcription

extension ModelManager {
    /// Get the realtime model path (for live transcription)
    func getRealtimeModelPath() async -> URL? {
        guard let rec = recommendation else { return nil }
        return await getModelPath(rec.realtimeModel)
    }

    /// Get the final model path (for polished transcription)
    func getFinalModelPath(batteryMode: Bool = false) async -> URL? {
        guard let rec = recommendation else { return nil }
        let model = batteryMode ? rec.batteryModeModel : rec.finalModel
        return await getModelPath(model)
    }

    /// Get paths for both models if available
    func getModelPaths(batteryMode: Bool = false) async -> (realtime: URL?, final: URL?) {
        let realtime = await getRealtimeModelPath()
        let final = await getFinalModelPath(batteryMode: batteryMode)
        return (realtime, final)
    }
}

// MARK: - Convenience Properties

extension ModelManager {
    /// All available models from catalog
    var allModels: [ModelDescriptor] {
        ModelCatalog.allModels
    }

    /// Device info string
    var deviceDescription: String {
        recommendation?.deviceInfo.description ?? "Unknown Device"
    }

    /// Whether device supports high quality mode
    var canRunHighQuality: Bool {
        recommendation?.canRunHighQuality ?? false
    }
}
