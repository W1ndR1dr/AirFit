import Foundation
import SwiftData

/// High-performance cache for onboarding flow - resumes in <100ms
actor OnboardingCache: ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "onboarding-cache"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool { true } // Cache is always ready
    private let diskCache: URL
    private var memoryCache: [UUID: CachedSession] = [:]

    struct CachedSession: Codable {
        let userId: UUID
        let conversationData: ConversationData
        let partialInsights: PersonalityInsights?
        let currentStep: String
        let responses: [String: Data]
        let timestamp: Date

        var isValid: Bool {
            // Sessions expire after 24 hours
            Date().timeIntervalSince(timestamp) < 86_400
        }
    }

    init() {
        guard let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("Could not access caches directory")
        }
        self.diskCache = cacheDir.appendingPathComponent("OnboardingCache")
        try? FileManager.default.createDirectory(at: diskCache, withIntermediateDirectories: true)
        // Active sessions are loaded in configure() method
    }

    // MARK: - Public API

    /// Save session state (async but returns immediately)
    func saveSession(
        userId: UUID,
        conversationData: ConversationData,
        insights: PersonalityInsights?,
        currentStep: String,
        responses: [ConversationResponse]
    ) {
        // Convert responses to cacheable format
        let responseData = responses.reduce(into: [String: Data]()) { dict, response in
            dict[response.nodeId] = response.responseData
        }

        let cached = CachedSession(
            userId: userId,
            conversationData: conversationData,
            partialInsights: insights,
            currentStep: currentStep,
            responses: responseData,
            timestamp: Date()
        )

        // Save to memory immediately
        memoryCache[userId] = cached

        // Save to disk async (fire and forget)
        Task.detached { [diskCache] in
            let url = diskCache.appendingPathComponent("\(userId).json")
            if let data = try? JSONEncoder().encode(cached) {
                try? data.write(to: url)
            }
        }
    }

    /// Restore session (instant from memory, <100ms from disk)
    func restoreSession(userId: UUID) async -> CachedSession? {
        // Check memory first
        if let cached = memoryCache[userId], cached.isValid {
            return cached
        }

        // Check disk
        let url = diskCache.appendingPathComponent("\(userId).json")
        guard let data = try? Data(contentsOf: url),
              let cached = try? JSONDecoder().decode(CachedSession.self, from: data),
              cached.isValid else {
            return nil
        }

        // Promote to memory
        memoryCache[userId] = cached
        return cached
    }

    /// Clear session after completion
    func clearSession(userId: UUID) {
        memoryCache.removeValue(forKey: userId)

        // Remove from disk async
        Task.detached { [diskCache] in
            let url = diskCache.appendingPathComponent("\(userId).json")
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Get all active sessions (for recovery UI)
    func getActiveSessions() async -> [UUID: Date] {
        var sessions: [UUID: Date] = [:]

        // From memory
        for (userId, cached) in memoryCache where cached.isValid {
            sessions[userId] = cached.timestamp
        }

        // From disk
        if let files = try? FileManager.default.contentsOfDirectory(at: diskCache, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "json" {
                if let data = try? Data(contentsOf: file),
                   let cached = try? JSONDecoder().decode(CachedSession.self, from: data),
                   cached.isValid,
                   let userId = UUID(uuidString: file.deletingPathExtension().lastPathComponent) {
                    sessions[userId] = cached.timestamp
                }
            }
        }

        return sessions
    }

    // MARK: - Private

    private func loadActiveSessions() async {
        guard let files = try? FileManager.default.contentsOfDirectory(at: diskCache, includingPropertiesForKeys: nil) else {
            return
        }

        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file),
               let cached = try? JSONDecoder().decode(CachedSession.self, from: data),
               cached.isValid,
               let userId = UUID(uuidString: file.deletingPathExtension().lastPathComponent) {
                memoryCache[userId] = cached
            }
        }
    }

    // MARK: - ServiceProtocol Methods

    func configure() async throws {
        guard !_isConfigured else { return }
        await loadActiveSessions()
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }

    func reset() async {
        memoryCache.removeAll()
        if let files = try? FileManager.default.contentsOfDirectory(at: diskCache, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }

    func healthCheck() async -> ServiceHealth {
        let cacheCount = memoryCache.count
        let diskFiles = (try? FileManager.default.contentsOfDirectory(at: diskCache, includingPropertiesForKeys: nil))?.count ?? 0

        return ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: [
                "memoryCacheCount": "\(cacheCount)",
                "diskCacheFiles": "\(diskFiles)"
            ]
        )
    }
}
