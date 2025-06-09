import Foundation
import SwiftData

// Simple error for analytics tracking
struct ProgressAnalyticsError: Error {
    let message: String
    var localizedDescription: String { message }
}

@MainActor
final class OnboardingProgressManager: ObservableObject, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "onboarding-progress-manager"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }
    
    // MARK: - Properties
    @Published private(set) var currentProgress: PersistedProgress?
    @Published private(set) var isLoading = false
    
    private let modelContext: ModelContext
    private let userDefaults: UserDefaults
    private let analytics: ConversationAnalytics
    
    // Keys for UserDefaults (fast access)
    private let progressKey = "onboarding.progress"
    private let lastUpdateKey = "onboarding.lastUpdate"
    private let versionKey = "onboarding.version"
    
    // Current schema version
    private let currentVersion = 1
    
    // MARK: - Initialization
    init(
        modelContext: ModelContext,
        userDefaults: UserDefaults = .standard,
        analytics: ConversationAnalytics = ConversationAnalytics()
    ) {
        self.modelContext = modelContext
        self.userDefaults = userDefaults
        self.analytics = analytics
        
        Task {
            await loadProgress()
        }
    }
    
    // MARK: - Public Methods
    
    func saveProgress(_ progress: OnboardingProgress, sessionId: UUID, userId: UUID) async {
        let persisted = PersistedProgress(
            sessionId: sessionId,
            userId: userId,
            state: progress,
            lastUpdate: Date(),
            version: currentVersion
        )
        
        currentProgress = persisted
        
        // Save to UserDefaults for fast access
        saveToUserDefaults(persisted)
        
        // Save to SwiftData for persistence
        await saveToDatabase(persisted)
        
        // Track progress update
        await analytics.track(.sessionResumed(
            userId: userId,
            nodeId: "progress_saved"
        ))
    }
    
    func loadProgress() async {
        isLoading = true
        defer { isLoading = false }
        
        // Try UserDefaults first (fast)
        if let cached = loadFromUserDefaults() {
            currentProgress = cached
            
            // Validate against database
            if let dbProgress = await loadFromDatabase(userId: cached.userId) {
                if dbProgress.lastUpdate > cached.lastUpdate {
                    currentProgress = dbProgress
                    saveToUserDefaults(dbProgress)
                }
            }
        } else {
            // Load from database
            if let userId = await getCurrentUserId() {
                currentProgress = await loadFromDatabase(userId: userId)
            }
        }
    }
    
    func clearProgress(sessionId: UUID, userId: UUID) async {
        // Clear UserDefaults
        userDefaults.removeObject(forKey: progressKey)
        userDefaults.removeObject(forKey: lastUpdateKey)
        
        // Mark session as cleared in database
        await markSessionCleared(sessionId)
        
        currentProgress = nil
        
        // Track session cleared
        await analytics.track(.sessionAbandoned(
            userId: userId,
            lastNodeId: "cleared",
            completionPercentage: 0.0
        ))
    }
    
    func hasIncompleteSession(userId: UUID) async -> Bool {
        let cutoffDate = Date().addingTimeInterval(-86400) // 24 hours
        
        let descriptor = FetchDescriptor<OnboardingProgressRecord>(
            predicate: #Predicate { record in
                record.userId == userId &&
                !record.isCompleted &&
                !record.isCleared &&
                record.lastUpdate > cutoffDate
            }
        )
        
        do {
            let records = try modelContext.fetch(descriptor)
            return !records.isEmpty
        } catch {
            AppLogger.error("Failed to check incomplete sessions", error: error, category: .onboarding)
            return false
        }
    }
    
    func migrateIfNeeded() async {
        guard let progress = currentProgress else { return }
        
        if progress.version < currentVersion {
            let migrated = await migrateProgress(progress)
            if let migrated = migrated {
                await saveProgress(migrated.state, sessionId: migrated.sessionId, userId: migrated.userId)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func saveToUserDefaults(_ progress: PersistedProgress) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(progress)
            userDefaults.set(data, forKey: progressKey)
            userDefaults.set(progress.lastUpdate, forKey: lastUpdateKey)
            userDefaults.set(progress.version, forKey: versionKey)
        } catch {
            AppLogger.error("Failed to save progress to UserDefaults", error: error, category: .onboarding)
        }
    }
    
    private func loadFromUserDefaults() -> PersistedProgress? {
        guard let data = userDefaults.data(forKey: progressKey) else { return nil }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(PersistedProgress.self, from: data)
        } catch {
            AppLogger.error("Failed to load progress from UserDefaults", error: error, category: .onboarding)
            return nil
        }
    }
    
    private func saveToDatabase(_ progress: PersistedProgress) async {
        do {
            // Check if record exists
            let descriptor = FetchDescriptor<OnboardingProgressRecord>(
                predicate: #Predicate { record in
                    record.sessionId == progress.sessionId
                }
            )
            
            let existing = try modelContext.fetch(descriptor).first
            
            if let record = existing {
                // Update existing
                record.update(from: progress)
            } else {
                // Create new
                let record = OnboardingProgressRecord(from: progress)
                modelContext.insert(record)
            }
            
            try modelContext.save()
        } catch {
            AppLogger.error("Failed to save progress to database", error: error, category: .onboarding)
        }
    }
    
    private func loadFromDatabase(userId: UUID) async -> PersistedProgress? {
        do {
            let descriptor = FetchDescriptor<OnboardingProgressRecord>(
                predicate: #Predicate { record in
                    record.userId == userId &&
                    !record.isCompleted &&
                    !record.isCleared
                },
                sortBy: [SortDescriptor(\.lastUpdate, order: .reverse)]
            )
            
            let records = try modelContext.fetch(descriptor)
            guard let latest = records.first else { return nil }
            
            return latest.toPersistedProgress()
        } catch {
            AppLogger.error("Failed to load progress from database", error: error, category: .onboarding)
            return nil
        }
    }
    
    private func markSessionCleared(_ sessionId: UUID) async {
        do {
            let descriptor = FetchDescriptor<OnboardingProgressRecord>(
                predicate: #Predicate { record in
                    record.sessionId == sessionId
                }
            )
            
            if let record = try modelContext.fetch(descriptor).first {
                record.isCleared = true
                record.clearedAt = Date()
                try modelContext.save()
            }
        } catch {
            AppLogger.error("Failed to mark session as cleared", error: error, category: .onboarding)
        }
    }
    
    private func getCurrentUserId() async -> UUID? {
        // Get current user from user service
        // Placeholder implementation
        return UUID()
    }
    
    private func migrateProgress(_ progress: PersistedProgress) async -> PersistedProgress? {
        // Handle version migrations
        var migrated = progress
        
        // Example migration from v0 to v1
        if progress.version == 0 {
            // Perform migration steps
            migrated.version = 1
        }
        
        // Track migration event
        await analytics.track(.sessionResumed(
            userId: progress.userId,
            nodeId: "migrated_v\(currentVersion)"
        ))
        
        return migrated
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        _isConfigured = false
        currentProgress = nil
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: _isConfigured ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: _isConfigured ? nil : "Service not configured",
            metadata: [
                "hasCurrentProgress": currentProgress != nil ? "true" : "false",
                "cacheEnabled": "true"
            ]
        )
    }
}

// MARK: - Models

struct PersistedProgress: Codable {
    let sessionId: UUID
    let userId: UUID
    let state: OnboardingProgress
    let lastUpdate: Date
    var version: Int
}

@Model
final class OnboardingProgressRecord {
    var sessionId: UUID
    var userId: UUID
    var progressData: Data
    var lastUpdate: Date
    var version: Int
    var isCompleted: Bool
    var isCleared: Bool
    var clearedAt: Date?
    var createdAt: Date
    
    init(from persisted: PersistedProgress) {
        self.sessionId = persisted.sessionId
        self.userId = persisted.userId
        self.lastUpdate = persisted.lastUpdate
        self.version = persisted.version
        self.isCompleted = persisted.state.synthesisComplete
        self.isCleared = false
        self.createdAt = Date()
        
        // Encode progress state
        do {
            let encoder = JSONEncoder()
            self.progressData = try encoder.encode(persisted.state)
        } catch {
            self.progressData = Data()
            AppLogger.error("Failed to encode progress state", error: error, category: .onboarding)
        }
    }
    
    func update(from persisted: PersistedProgress) {
        self.lastUpdate = persisted.lastUpdate
        self.version = persisted.version
        self.isCompleted = persisted.state.synthesisComplete
        
        do {
            let encoder = JSONEncoder()
            self.progressData = try encoder.encode(persisted.state)
        } catch {
            AppLogger.error("Failed to encode progress state", error: error, category: .onboarding)
        }
    }
    
    func toPersistedProgress() -> PersistedProgress? {
        do {
            let decoder = JSONDecoder()
            let state = try decoder.decode(OnboardingProgress.self, from: progressData)
            
            return PersistedProgress(
                sessionId: sessionId,
                userId: userId,
                state: state,
                lastUpdate: lastUpdate,
                version: version
            )
        } catch {
            AppLogger.error("Failed to decode progress state", error: error, category: .onboarding)
            return nil
        }
    }
}

// MARK: - OnboardingProgress Codable

extension OnboardingProgress: Codable {
    enum CodingKeys: String, CodingKey {
        case conversationStarted
        case nodesCompleted
        case totalNodes
        case completionPercentage
        case synthesisStarted
        case extractionComplete
        case synthesisComplete
        case adjustmentCount
        case startTime
        case completionTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        conversationStarted = try container.decode(Bool.self, forKey: .conversationStarted)
        nodesCompleted = try container.decode(Int.self, forKey: .nodesCompleted)
        totalNodes = try container.decode(Int.self, forKey: .totalNodes)
        completionPercentage = try container.decode(Double.self, forKey: .completionPercentage)
        synthesisStarted = try container.decode(Bool.self, forKey: .synthesisStarted)
        extractionComplete = try container.decode(Bool.self, forKey: .extractionComplete)
        synthesisComplete = try container.decode(Bool.self, forKey: .synthesisComplete)
        adjustmentCount = try container.decode(Int.self, forKey: .adjustmentCount)
        startTime = try container.decode(Date.self, forKey: .startTime)
        completionTime = try container.decodeIfPresent(Date.self, forKey: .completionTime)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(conversationStarted, forKey: .conversationStarted)
        try container.encode(nodesCompleted, forKey: .nodesCompleted)
        try container.encode(totalNodes, forKey: .totalNodes)
        try container.encode(completionPercentage, forKey: .completionPercentage)
        try container.encode(synthesisStarted, forKey: .synthesisStarted)
        try container.encode(extractionComplete, forKey: .extractionComplete)
        try container.encode(synthesisComplete, forKey: .synthesisComplete)
        try container.encode(adjustmentCount, forKey: .adjustmentCount)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(completionTime, forKey: .completionTime)
    }
}

// MARK: - Analytics Extensions

extension ConversationAnalytics {
    enum ProgressEvent: String {
        case progressSaved = "progress_saved"
        case progressCleared = "progress_cleared"
        case progressMigrated = "progress_migrated"
    }
    
    func trackEvent(_ event: ProgressEvent, properties: [String: Any] = [:]) {
        // Convert to appropriate analytics event
        // For now, track as an error with the event name
        Task {
            // TODO: Implement proper analytics error tracking
            // await track(.errorOccurred(nodeId: nil, error: ProgressAnalyticsError(message: event.rawValue)))
            AppLogger.info("ProgressEvent: \(event.rawValue)", category: .app)
        }
    }
}