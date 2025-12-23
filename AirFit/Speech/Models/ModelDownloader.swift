import Foundation
import Network
import os.log

private let downloadLogger = Logger(subsystem: "com.airfit.app", category: "ModelDownloader")

/// Downloads WhisperKit models from HuggingFace
actor ModelDownloader {

    // MARK: - Types

    enum DownloadError: LocalizedError {
        case notOnWiFi
        case fileListFailed(String)
        case downloadFailed(String)
        case cancelled
        case installationFailed(String)

        var errorDescription: String? {
            switch self {
            case .notOnWiFi:
                return "Wi-Fi required for model downloads"
            case .fileListFailed(let reason):
                return "Failed to get file list: \(reason)"
            case .downloadFailed(let reason):
                return "Download failed: \(reason)"
            case .cancelled:
                return "Download cancelled"
            case .installationFailed(let reason):
                return "Installation failed: \(reason)"
            }
        }
    }

    // MARK: - Properties

    private let session: URLSession
    private var activeDownloads: [String: Task<Void, Error>] = [:]
    private let networkMonitor = NWPathMonitor()
    private var isOnWiFi = false

    // MARK: - Initialization

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 3600 // 1 hour for large models
        self.session = URLSession(configuration: config)

        // Start network monitoring
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { await self?.updateNetworkStatus(path) }
        }
        networkMonitor.start(queue: DispatchQueue.global(qos: .utility))
    }

    deinit {
        networkMonitor.cancel()
    }

    // MARK: - Public API

    /// Download a model from HuggingFace
    /// Returns an AsyncStream of progress updates
    func download(
        _ model: ModelDescriptor,
        wifiOnly: Bool,
        progressHandler: @Sendable @escaping (ModelDownloadProgress) -> Void
    ) async throws {
        // Check Wi-Fi if required
        if wifiOnly && !isOnWiFi {
            throw DownloadError.notOnWiFi
        }

        // Cancel any existing download for this model
        activeDownloads[model.id]?.cancel()

        // Create download task
        let task = Task {
            try await performDownload(model, progressHandler: progressHandler)
        }

        activeDownloads[model.id] = task

        do {
            try await task.value
            activeDownloads.removeValue(forKey: model.id)
        } catch {
            activeDownloads.removeValue(forKey: model.id)
            throw error
        }
    }

    /// Cancel a model download
    func cancel(_ modelId: String) {
        activeDownloads[modelId]?.cancel()
        activeDownloads.removeValue(forKey: modelId)
    }

    /// Cancel all downloads
    func cancelAll() {
        for (_, task) in activeDownloads {
            task.cancel()
        }
        activeDownloads.removeAll()
    }

    /// Check if currently on Wi-Fi
    func checkWiFiStatus() -> Bool {
        isOnWiFi
    }

    // MARK: - Private Methods

    private func updateNetworkStatus(_ path: NWPath) {
        isOnWiFi = path.usesInterfaceType(.wifi)
    }

    private func performDownload(
        _ model: ModelDescriptor,
        progressHandler: @Sendable @escaping (ModelDownloadProgress) -> Void
    ) async throws {
        let store = ModelStore.shared

        downloadLogger.info("⬇️ Starting download for \(model.id)")
        downloadLogger.info("⬇️ API URL: \(model.huggingFaceAPIURL.absoluteString)")

        // 1. Get file list from HuggingFace API
        let files = try await fetchFileList(for: model)
        downloadLogger.info("⬇️ Found \(files.count) files to download")
        let totalSize = files.reduce(0) { $0 + ($1.size ?? 0) }
        downloadLogger.info("⬇️ Total size: \(totalSize) bytes")

        // 2. Create temp directory for download
        let tempDir = await store.downloadCacheDirectory.appendingPathComponent(model.folderName, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // 3. Download each file
        var downloadedBytes: Int64 = 0

        for file in files where file.isFile {
            try Task.checkCancellation()

            let fileURL = file.downloadURL
            let relativePath = file.relativePath(strippingFolder: model.folderName)
            let destPath = tempDir.appendingPathComponent(relativePath)

            downloadLogger.info("⬇️ Downloading: \(file.path) → \(relativePath)")

            // Create parent directories if needed
            try FileManager.default.createDirectory(
                at: destPath.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            // Download file
            let (localURL, _) = try await session.download(from: fileURL)

            // Move to destination
            if FileManager.default.fileExists(atPath: destPath.path) {
                try FileManager.default.removeItem(at: destPath)
            }
            try FileManager.default.moveItem(at: localURL, to: destPath)

            // Update progress
            downloadedBytes += file.size ?? 0
            let progress = ModelDownloadProgress(
                modelId: model.id,
                bytesDownloaded: downloadedBytes,
                totalBytes: totalSize,
                currentFile: file.path
            )
            progressHandler(progress)
        }

        // 4. Move to final location
        try Task.checkCancellation()

        let finalPath = await store.installPath(for: model)

        // Remove existing if present
        if FileManager.default.fileExists(atPath: finalPath.path) {
            try FileManager.default.removeItem(at: finalPath)
        }

        // Atomic move
        try FileManager.default.moveItem(at: tempDir, to: finalPath)

        // 5. Mark as installed
        try await store.markInstalled(model, at: finalPath)

        // 6. Clean up temp directory
        try? await store.cleanupDownloadCache()
    }

    private func fetchFileList(for model: ModelDescriptor) async throws -> [HuggingFaceFileInfo] {
        let request = URLRequest(url: model.huggingFaceAPIURL)
        downloadLogger.info("⬇️ Fetching file list from: \(model.huggingFaceAPIURL.absoluteString)")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                downloadLogger.error("⬇️ No HTTP response")
                throw DownloadError.fileListFailed("No HTTP response")
            }

            downloadLogger.info("⬇️ HTTP status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8) ?? "no body"
                downloadLogger.error("⬇️ HTTP error \(httpResponse.statusCode): \(body)")
                throw DownloadError.fileListFailed("HTTP \(httpResponse.statusCode)")
            }

            let files = try JSONDecoder().decode([HuggingFaceFileInfo].self, from: data)
            downloadLogger.info("⬇️ Decoded \(files.count) files")
            return files
        } catch let error as DownloadError {
            throw error
        } catch {
            downloadLogger.error("⬇️ Network error: \(error.localizedDescription)")
            throw DownloadError.fileListFailed(error.localizedDescription)
        }
    }
}

// MARK: - AsyncStream Version

extension ModelDownloader {
    /// Download with AsyncStream for progress (alternative API)
    func downloadWithStream(_ model: ModelDescriptor, wifiOnly: Bool) -> AsyncThrowingStream<ModelDownloadProgress, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await download(model, wifiOnly: wifiOnly) { progress in
                        continuation.yield(progress)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
