import Foundation
import os.log

private let storeLogger = Logger(subsystem: "com.airfit.app", category: "ModelStore")

/// Manages installed WhisperKit models on disk
actor ModelStore {
    static let shared = ModelStore()

    // MARK: - Storage Paths

    /// Base directory for model storage (Application Support/WhisperModels/)
    private var modelsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("WhisperModels", isDirectory: true)
    }

    /// Manifest file tracking installed models
    private var manifestURL: URL {
        modelsDirectory.appendingPathComponent("manifest.json")
    }

    /// Temporary directory for downloads
    var downloadCacheDirectory: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return caches.appendingPathComponent("WhisperDownloads", isDirectory: true)
    }

    // MARK: - State

    private var installedModels: [String: InstalledModel] = [:]
    private var isLoaded = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Load manifest from disk (call once at startup)
    func load() async throws {
        guard !isLoaded else { return }

        // Ensure directories exist
        try ensureDirectoriesExist()

        // Load manifest if exists
        if FileManager.default.fileExists(atPath: manifestURL.path) {
            let data = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode([String: InstalledModel].self, from: data)

            // Verify each model still exists on disk
            for (id, model) in manifest {
                if FileManager.default.fileExists(atPath: model.path) {
                    installedModels[id] = model
                }
            }
        }

        isLoaded = true
    }

    /// Check if a model is installed
    func isInstalled(_ model: ModelDescriptor) -> Bool {
        installedModels[model.id] != nil
    }

    /// Check if all required models are installed
    func hasRequiredModels(for recommendation: ModelRecommendation) -> Bool {
        hasRequiredModels(recommendation.requiredModels)
    }

    /// Check if a list of models are installed
    func hasRequiredModels(_ models: [ModelDescriptor]) -> Bool {
        storeLogger.info("💾 Checking \(models.count) required models")
        storeLogger.info("💾 Installed model IDs: \(Array(self.installedModels.keys))")
        for model in models {
            let installed = isInstalled(model)
            storeLogger.info("💾 \(model.id): \(installed ? "installed" : "NOT installed")")
        }
        return models.allSatisfy { isInstalled($0) }
    }

    /// Get the path to an installed model (verifies path still exists)
    func getPath(for model: ModelDescriptor) -> URL? {
        guard let installed = installedModels[model.id] else {
            storeLogger.warning("💾 Model \(model.id) not found in installed models")
            return nil
        }

        // Verify the path still exists (WhisperKit manages its own storage)
        let url = installed.url
        guard FileManager.default.fileExists(atPath: url.path) else {
            storeLogger.warning("💾 Model path no longer exists: \(url.path)")
            // Remove from manifest since it's gone
            installedModels.removeValue(forKey: model.id)
            Task { try? await saveManifest() }
            return nil
        }

        storeLogger.debug("💾 Found model \(model.id) at: \(url.path)")
        return url
    }

    /// Get all installed models
    func getInstalledModels() -> [InstalledModel] {
        Array(installedModels.values)
    }

    /// Get installed model by ID
    func getInstalledModel(_ id: String) -> InstalledModel? {
        installedModels[id]
    }

    /// Mark a model as installed (path should be from WhisperKit.download())
    func markInstalled(_ model: ModelDescriptor, at path: URL) async throws {
        storeLogger.info("💾 Marking \(model.id) as installed at: \(path.path)")

        // Verify the path exists
        guard FileManager.default.fileExists(atPath: path.path) else {
            storeLogger.error("💾 Path doesn't exist: \(path.path)")
            throw StoreError.installationFailed("Model path not found: \(path.path)")
        }

        let size = try calculateDirectorySize(path)
        storeLogger.info("💾 Model size: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")

        let installed = InstalledModel(
            descriptor: model,
            installedAt: Date(),
            path: path.path,
            actualSizeBytes: size
        )

        installedModels[model.id] = installed
        try await saveManifest()
        storeLogger.info("💾 Successfully marked \(model.id) as installed")
    }

    /// Delete an installed model
    func delete(_ model: ModelDescriptor) async throws {
        guard let installed = installedModels[model.id] else { return }

        // Remove from disk
        try FileManager.default.removeItem(at: installed.url)

        // Remove from manifest
        installedModels.removeValue(forKey: model.id)
        try await saveManifest()
    }

    /// Get total disk usage of installed models
    func totalDiskUsage() -> Int64 {
        installedModels.values.reduce(0) { $0 + $1.actualSizeBytes }
    }

    /// Formatted total disk usage
    func formattedDiskUsage() -> String {
        ByteCountFormatter.string(fromByteCount: totalDiskUsage(), countStyle: .file)
    }

    /// Get the installation path for a model (where it should be installed)
    func installPath(for model: ModelDescriptor) -> URL {
        modelsDirectory.appendingPathComponent(model.folderName, isDirectory: true)
    }

    /// Clean up temporary download files
    func cleanupDownloadCache() throws {
        if FileManager.default.fileExists(atPath: downloadCacheDirectory.path) {
            try FileManager.default.removeItem(at: downloadCacheDirectory)
        }
    }

    // MARK: - Private Methods

    private func ensureDirectoriesExist() throws {
        let fm = FileManager.default

        if !fm.fileExists(atPath: modelsDirectory.path) {
            try fm.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        }

        if !fm.fileExists(atPath: downloadCacheDirectory.path) {
            try fm.createDirectory(at: downloadCacheDirectory, withIntermediateDirectories: true)
        }
    }

    private func saveManifest() async throws {
        let data = try JSONEncoder().encode(installedModels)
        try data.write(to: manifestURL)
    }

    private func calculateDirectorySize(_ url: URL) throws -> Int64 {
        let fm = FileManager.default
        var totalSize: Int64 = 0

        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            totalSize += Int64(resourceValues.fileSize ?? 0)
        }

        return totalSize
    }
}

// MARK: - Errors

extension ModelStore {
    enum StoreError: LocalizedError {
        case modelNotFound(String)
        case installationFailed(String)
        case deletionFailed(String)

        var errorDescription: String? {
            switch self {
            case .modelNotFound(let id):
                return "Model not found: \(id)"
            case .installationFailed(let reason):
                return "Installation failed: \(reason)"
            case .deletionFailed(let reason):
                return "Deletion failed: \(reason)"
            }
        }
    }
}
