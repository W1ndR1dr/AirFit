import Foundation
@preconcurrency import WhisperKit

@MainActor
protocol WhisperModelManagerProtocol: AnyObject {
    var availableModels: [WhisperModelManager.WhisperModel] { get }
    var downloadedModels: Set<String> { get }
    var activeModel: String { get set }
    
    func selectOptimalModel() -> String
    func downloadModel(_ modelId: String) async throws
    func deleteModel(_ modelId: String) throws
    func modelPath(for modelId: String) -> URL?
    func isModelDownloaded(_ modelId: String) -> Bool
    func getModelConfiguration(_ modelId: String) -> WhisperModelManager.WhisperModel?
    func freeUpSpace() async throws
    func ensureModelSpace(for modelId: String) async throws -> Bool
    func updateDownloadedModels()
}

@MainActor
final class WhisperModelManager: ObservableObject, WhisperModelManagerProtocol, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "whisper-model-manager"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }

    // MARK: - Model Configuration
    struct WhisperModel: Identifiable, Sendable {
        let id: String
        let displayName: String
        let size: String
        let sizeBytes: Int
        let accuracy: String
        let speed: String
        let languages: String
        let requiredMemory: UInt64
        let huggingFaceRepo: String
    }

    enum ModelError: LocalizedError, Sendable {
        case modelNotFound
        case insufficientStorage
        case downloadFailed(String)

        var errorDescription: String? {
            switch self {
            case .modelNotFound:
                return "Model not found"
            case .insufficientStorage:
                return "Not enough storage space for model"
            case .downloadFailed(let reason):
                return "Download failed: \(reason)"
            }
        }
    }

    static let modelConfigurations: [WhisperModel] = [
        WhisperModel(
            id: "tiny",
            displayName: "Tiny (39 MB)",
            size: "39 MB",
            sizeBytes: 39_000_000,
            accuracy: "Good",
            speed: "Fastest",
            languages: "English + 98 more",
            requiredMemory: 200_000_000,
            huggingFaceRepo: "mlx-community/whisper-tiny-mlx"
        ),
        WhisperModel(
            id: "base",
            displayName: "Base (74 MB)",
            size: "74 MB",
            sizeBytes: 74_000_000,
            accuracy: "Better",
            speed: "Very Fast",
            languages: "English + 98 more",
            requiredMemory: 500_000_000,
            huggingFaceRepo: "mlx-community/whisper-base-mlx"
        ),
        WhisperModel(
            id: "small",
            displayName: "Small",
            size: "244 MB",
            sizeBytes: 244_000_000,
            accuracy: "Good",
            speed: "Moderate",
            languages: "Multi",
            requiredMemory: 3_000_000_000,
            huggingFaceRepo: "mlx-community/whisper-small-mlx"
        ),
        WhisperModel(
            id: "medium",
            displayName: "Medium",
            size: "769 MB",
            sizeBytes: 769_000_000,
            accuracy: "Very Good",
            speed: "Slower",
            languages: "Multi",
            requiredMemory: 4_000_000_000,
            huggingFaceRepo: "mlx-community/whisper-medium-mlx"
        ),
        WhisperModel(
            id: "large-v3",
            displayName: "Large v3",
            size: "1.55 GB",
            sizeBytes: 1_550_000_000,
            accuracy: "Best",
            speed: "Slowest",
            languages: "Multi",
            requiredMemory: 6_000_000_000,
            huggingFaceRepo: "mlx-community/whisper-large-v3-mlx"
        )
    ]

    // MARK: - State
    private let modelStorageURL: URL
    @Published var availableModels: [WhisperModel] = []
    @Published var downloadedModels: Set<String> = []
    @Published var isDownloading: [String: Bool] = [:]
    @Published var downloadProgress: [String: Double] = [:]
    @Published var activeModel: String = "base"
    private var currentDownloadTask: Task<Void, Never>?

    // MARK: - Initialization
    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        modelStorageURL = support.appendingPathComponent("WhisperModels")
        try? FileManager.default.createDirectory(at: modelStorageURL, withIntermediateDirectories: true)
        loadModelInfo()
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        downloadedModels.removeAll()
        activeModel = "base"
        isDownloading.removeAll()
        downloadProgress.removeAll()
        currentDownloadTask?.cancel()
        currentDownloadTask = nil
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        updateDownloadedModels()
        let hasModels = !downloadedModels.isEmpty
        let activeModelExists = modelPath(for: activeModel) != nil
        
        return ServiceHealth(
            status: hasModels && activeModelExists ? .healthy : .degraded,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: hasModels ? nil : "No models downloaded",
            metadata: [
                "downloadedModels": "\(downloadedModels.count)",
                "activeModel": activeModel,
                "availableModels": "\(availableModels.count)"
            ]
        )
    }

    // MARK: - Model Management
    private func loadModelInfo() {
        let deviceMemory = ProcessInfo.processInfo.physicalMemory
        availableModels = Self.modelConfigurations.filter { $0.requiredMemory <= deviceMemory }
        updateDownloadedModels()
        if downloadedModels.contains("base") {
            activeModel = "base"
        } else if let first = downloadedModels.first {
            activeModel = first
        }
    }

    func updateDownloadedModels() {
        downloadedModels.removeAll()
        for model in availableModels {
            let path = modelStorageURL.appendingPathComponent(model.id)
            let config = path.appendingPathComponent("config.json")
            let weights = path.appendingPathComponent("weights.npz")
            if FileManager.default.fileExists(atPath: config.path) &&
                FileManager.default.fileExists(atPath: weights.path) {
                downloadedModels.insert(model.id)
            }
        }
    }

    // MARK: - Download Management
    func downloadModel(_ modelId: String) async throws {
        guard let model = availableModels.first(where: { $0.id == modelId }) else {
            throw AppError.from(ModelError.modelNotFound)
        }
        guard hasEnoughStorage(for: model) else {
            throw AppError.from(ModelError.insufficientStorage)
        }

        isDownloading[modelId] = true
        downloadProgress[modelId] = 0.0

        do {
            let modelPath = modelStorageURL.appendingPathComponent(modelId)
            _ = try await WhisperKit(
                WhisperKitConfig(
                    model: modelId,
                    modelRepo: model.huggingFaceRepo,
                    modelFolder: modelId,
                    verbose: false,
                    logLevel: .error,
                    download: true
                )
            )

            if let cache = locateWhisperKitCache(for: modelId) {
                try FileManager.default.moveItem(at: cache, to: modelPath)
            }

            downloadedModels.insert(modelId)
            downloadProgress[modelId] = 1.0
        } catch {
            downloadProgress[modelId] = 0.0
            isDownloading[modelId] = false
            throw AppError.from(ModelError.downloadFailed(error.localizedDescription))
        }

        isDownloading[modelId] = false
    }

    func deleteModel(_ modelId: String) throws {
        let path = modelStorageURL.appendingPathComponent(modelId)
        if FileManager.default.fileExists(atPath: path.path) {
            try FileManager.default.removeItem(at: path)
            downloadedModels.remove(modelId)
            if activeModel == modelId {
                activeModel = downloadedModels.first ?? "base"
            }
        }
    }

    // MARK: - Storage
    private func hasEnoughStorage(for model: WhisperModel) -> Bool {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let free = attributes[.systemFreeSize] as? NSNumber {
                return free.int64Value > Int64(model.sizeBytes * 2)
            }
        } catch {
            AppLogger.error("Failed to check storage", error: error, category: .storage)
        }
        return false
    }

    private func locateWhisperKitCache(for modelId: String) -> URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("WhisperKit/\(modelId)")
    }

    // MARK: - Model Selection
    func selectOptimalModel() -> String {
        let deviceMemory = ProcessInfo.processInfo.physicalMemory
        let sorted = downloadedModels.sorted { a, b in
            let sizeA = Self.modelConfigurations.first { $0.id == a }?.sizeBytes ?? 0
            let sizeB = Self.modelConfigurations.first { $0.id == b }?.sizeBytes ?? 0
            return sizeA > sizeB
        }
        for id in sorted {
            if let cfg = Self.modelConfigurations.first(where: { $0.id == id }),
               cfg.requiredMemory <= deviceMemory {
                return id
            }
        }
        if deviceMemory >= 8_000_000_000 {
            return "large-v3"
        } else if deviceMemory >= 6_000_000_000 {
            return "medium"
        } else if deviceMemory >= 4_000_000_000 {
            return "base"
        } else {
            return "tiny"
        }
    }

    // MARK: - Accessors
    func modelPath(for modelId: String) -> URL? {
        let path = modelStorageURL.appendingPathComponent(modelId)
        return FileManager.default.fileExists(atPath: path.path) ? path : nil
    }

    // MARK: - Cache Management
    func clearUnusedModels() throws {
        let unused = downloadedModels.filter { $0 != activeModel }
        for id in unused {
            try deleteModel(id)
        }
        // Remove temporary WhisperKit cache directory
        if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("WhisperKit"),
           FileManager.default.fileExists(atPath: cacheDir.path) {
            try? FileManager.default.removeItem(at: cacheDir)
        }
    }
    
    // MARK: - Protocol Requirements
    func isModelDownloaded(_ modelId: String) -> Bool {
        return downloadedModels.contains(modelId)
    }
    
    func getModelConfiguration(_ modelId: String) -> WhisperModel? {
        return availableModels.first { $0.id == modelId }
    }
    
    func freeUpSpace() async throws {
        // Clear unused models to free up space
        try clearUnusedModels()
    }
    
    func ensureModelSpace(for modelId: String) async throws -> Bool {
        guard let model = getModelConfiguration(modelId) else {
            return false
        }
        
        // Check if we have enough space
        if hasEnoughStorage(for: model) {
            return true
        }
        
        // Try to free up space
        try await freeUpSpace()
        
        // Check again
        return hasEnoughStorage(for: model)
    }
}
