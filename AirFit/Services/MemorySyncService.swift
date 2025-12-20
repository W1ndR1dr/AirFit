import Foundation
import SwiftData

/// Unified memory management across Claude and Gemini providers.
///
/// Responsibilities:
/// - Store memory markers locally (SwiftData)
/// - Build memory context for prompt injection
/// - Sync to/from server when available
/// - Ensure personality continuity across provider switches
actor MemorySyncService {
    private let apiClient = APIClient()

    // MARK: - Memory Context Building

    /// Build memory context string for injection into AI prompts.
    ///
    /// Gathers recent memories from local storage and formats them
    /// for inclusion in the system prompt.
    @MainActor
    func buildMemoryContext(modelContext: ModelContext) -> String {
        var sections: [String] = []

        // Get callbacks (inside jokes, phrases)
        let callbackDescriptor = FetchDescriptor<LocalMemory>(
            predicate: #Predicate<LocalMemory> { $0.type == "callback" },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let callbacks = try? modelContext.fetch(callbackDescriptor), !callbacks.isEmpty {
            let callbackLines = callbacks.prefix(10).map { "• \($0.content)" }
            sections.append("## Inside Jokes & Callbacks\n" + callbackLines.joined(separator: "\n"))
        }

        // Get tone calibrations
        let toneDescriptor = FetchDescriptor<LocalMemory>(
            predicate: #Predicate<LocalMemory> { $0.type == "tone" },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let tones = try? modelContext.fetch(toneDescriptor), !tones.isEmpty {
            let toneLines = tones.prefix(5).map { "• \($0.content)" }
            sections.append("## Tone Calibration\n" + toneLines.joined(separator: "\n"))
        }

        // Get active threads (topics to follow up on)
        let threadDescriptor = FetchDescriptor<LocalMemory>(
            predicate: #Predicate<LocalMemory> { $0.type == "thread" },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let threads = try? modelContext.fetch(threadDescriptor), !threads.isEmpty {
            let threadLines = threads.prefix(5).map { "• \($0.content)" }
            sections.append("## Active Threads\n" + threadLines.joined(separator: "\n"))
        }

        // Get general remembers
        let rememberDescriptor = FetchDescriptor<LocalMemory>(
            predicate: #Predicate<LocalMemory> { $0.type == "remember" },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let remembers = try? modelContext.fetch(rememberDescriptor), !remembers.isEmpty {
            let rememberLines = remembers.prefix(10).map { "• \($0.content)" }
            sections.append("## Things to Remember\n" + rememberLines.joined(separator: "\n"))
        }

        guard !sections.isEmpty else { return "" }

        return "# Relationship Memory\n\n" + sections.joined(separator: "\n\n")
    }

    // MARK: - Memory Storage

    /// Store new memory markers extracted from an AI response.
    @MainActor
    func storeMarkers(_ markers: [MemoryMarker], conversationId: UUID? = nil, modelContext: ModelContext) {
        for marker in markers {
            let localMemory = LocalMemory(
                type: marker.type,
                content: marker.content,
                conversationId: conversationId
            )
            modelContext.insert(localMemory)
        }

        // Save immediately
        try? modelContext.save()

        print("[MemorySyncService] Stored \(markers.count) memory markers locally")
    }

    /// Check if we have enough unsynced markers to warrant a server sync.
    @MainActor
    func shouldSyncToServer(modelContext: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<LocalMemory>(
            predicate: #Predicate<LocalMemory> { $0.syncedToServer == false }
        )
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        return count >= 5  // Sync after 5+ markers accumulated
    }

    // MARK: - Server Sync

    /// Sync unsynced memories to server.
    ///
    /// Called when server becomes available or when enough markers accumulate.
    @MainActor
    func syncToServer(modelContext: ModelContext) async {
        guard await apiClient.checkHealth() else {
            print("[MemorySyncService] Server unavailable, skipping sync")
            return
        }

        // Get unsynced memories
        let descriptor = FetchDescriptor<LocalMemory>(
            predicate: #Predicate<LocalMemory> { $0.syncedToServer == false },
            sortBy: [SortDescriptor(\.createdAt)]
        )

        guard let unsyncedMemories = try? modelContext.fetch(descriptor), !unsyncedMemories.isEmpty else {
            return
        }

        // Group by type for efficient sync
        let grouped = Dictionary(grouping: unsyncedMemories) { $0.type }

        do {
            // Sync each type
            for (type, memories) in grouped {
                let contents = memories.map { $0.content }
                try await apiClient.syncMemories(type: type, contents: contents)
            }

            // Mark as synced
            for memory in unsyncedMemories {
                memory.syncedToServer = true
            }

            try modelContext.save()
            print("[MemorySyncService] Synced \(unsyncedMemories.count) memories to server")

        } catch {
            print("[MemorySyncService] Sync failed: \(error)")
        }
    }

    /// Pull latest profile and memories from server.
    ///
    /// Used when switching to Claude mode or on app launch.
    @MainActor
    func syncFromServer(modelContext: ModelContext) async {
        guard await apiClient.checkHealth() else {
            print("[MemorySyncService] Server unavailable, skipping pull")
            return
        }

        do {
            // Get profile from server
            let serverProfile = try await apiClient.getProfileForMemorySync()

            // Update or create local profile
            let localProfile = LocalProfile.getOrCreate(in: modelContext)

            // Merge server data (server wins for most fields)
            localProfile.name = serverProfile.name ?? localProfile.name
            localProfile.personalityNotes = serverProfile.personalityNotes ?? localProfile.personalityNotes
            localProfile.communicationStyle = serverProfile.communicationStyle ?? localProfile.communicationStyle
            localProfile.goalPhase = serverProfile.goalPhase ?? localProfile.goalPhase
            localProfile.proteinTarget = serverProfile.proteinTarget ?? localProfile.proteinTarget
            localProfile.calorieTargetTraining = serverProfile.calorieTargetTraining ?? localProfile.calorieTargetTraining
            localProfile.calorieTargetRest = serverProfile.calorieTargetRest ?? localProfile.calorieTargetRest
            localProfile.onboardingComplete = serverProfile.onboardingComplete
            localProfile.lastServerSync = Date()

            try modelContext.save()
            print("[MemorySyncService] Synced profile from server")

        } catch {
            print("[MemorySyncService] Failed to sync from server: \(error)")
        }
    }

    /// Push local profile to server as backup.
    ///
    /// Device is source of truth; server mirrors for Claude mode continuity.
    /// Called periodically or when significant profile changes accumulate.
    @MainActor
    func pushProfileToServer(modelContext: ModelContext) async {
        guard await apiClient.checkHealth() else {
            print("[MemorySyncService] Server unavailable, skipping profile push")
            return
        }

        let profile = LocalProfile.getOrCreate(in: modelContext)

        // Convert to server format
        let serverProfile = APIClient.ServerProfileExport(
            name: profile.name,
            age: profile.age,
            height: profile.heightString,
            occupation: profile.occupation,
            currentWeightLbs: profile.currentWeight,
            currentBodyFatPct: profile.bodyFatPct,
            targetWeightLbs: profile.targetWeight,
            targetBodyFatPct: profile.targetBodyFatPct,
            goals: profile.goals ?? [],
            currentPhase: profile.goalPhase,
            phaseContext: profile.phaseContext,
            lifeContext: profile.lifeContext ?? [],
            constraints: profile.constraints ?? [],
            preferences: profile.preferences ?? [],
            communicationStyle: profile.communicationStyle,
            personalityNotes: profile.personalityNotes,
            relationshipNotes: profile.relationshipNotes,
            trainingDaysPerWeek: profile.trainingDaysPerWeek,
            trainingStyle: profile.trainingStyle,
            favoriteActivities: profile.favoriteActivities ?? [],
            patterns: profile.patterns ?? [],
            nutritionGuidelines: profile.nutritionGuidelines ?? [],
            onboardingComplete: profile.onboardingComplete
        )

        do {
            try await apiClient.pushProfile(serverProfile)
            profile.lastServerSync = Date()
            try? modelContext.save()
            print("[MemorySyncService] Pushed profile to server")
        } catch {
            print("[MemorySyncService] Failed to push profile: \(error)")
        }
    }

    /// Check if profile should be synced to server.
    ///
    /// Returns true if:
    /// - Profile was updated since last sync
    /// - More than 1 hour since last sync
    @MainActor
    func shouldPushProfile(modelContext: ModelContext) -> Bool {
        let profile = LocalProfile.getOrCreate(in: modelContext)

        // No updates since last sync
        guard let lastUpdate = profile.lastLocalUpdate else { return false }
        guard let lastSync = profile.lastServerSync else { return true }

        // Profile updated after last sync
        if lastUpdate > lastSync { return true }

        // Been more than 1 hour since last sync
        let hoursSinceSync = Calendar.current.dateComponents([.hour], from: lastSync, to: Date()).hour ?? 0
        return hoursSinceSync >= 1
    }

    // MARK: - Profile Management

    /// Update local profile with new information.
    @MainActor
    func updateProfile(
        _ updates: (inout LocalProfile) -> Void,
        modelContext: ModelContext
    ) {
        var profile = LocalProfile.getOrCreate(in: modelContext)
        updates(&profile)
        profile.lastLocalUpdate = Date()
        try? modelContext.save()
    }

    /// Get the current local profile.
    @MainActor
    func getProfile(modelContext: ModelContext) -> LocalProfile {
        LocalProfile.getOrCreate(in: modelContext)
    }

    // MARK: - Full Context Building

    /// Build complete chat context from local data.
    ///
    /// Used in Gemini mode when server is not needed for AI calls.
    @MainActor
    func buildFullContext(modelContext: ModelContext) -> ChatContext {
        let profile = LocalProfile.getOrCreate(in: modelContext)
        let memoryContext = buildMemoryContext(modelContext: modelContext)

        // Build system prompt from profile + universal coaching
        var systemPrompt = ChatContext.universalCoachingPhilosophy

        let profileSection = profile.toSystemPromptSection()
        if !profileSection.isEmpty {
            systemPrompt = profileSection + "\n\n" + systemPrompt
        }

        return ChatContext(
            systemPrompt: systemPrompt,
            memoryContext: memoryContext,
            dataContext: "",  // Data context added separately by caller
            profileSummary: profile.summary,
            onboardingComplete: profile.onboardingComplete
        )
    }
}

// MARK: - APIClient Extensions for Memory Sync

extension APIClient {
    /// Sync memories to server.
    func syncMemories(type: String, contents: [String]) async throws {
        struct SyncRequest: Encodable {
            let type: String
            let contents: [String]
        }

        let baseURL = ServerConfiguration.configuredBaseURL
        let url = baseURL.appendingPathComponent("sync/memories")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(SyncRequest(type: type, contents: contents))
        request.timeoutInterval = 30

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }

    /// Server profile response (subset of fields we sync).
    struct ServerProfileResponse: Decodable {
        let name: String?
        let personalityNotes: String?
        let communicationStyle: String?
        let goalPhase: String?
        let proteinTarget: Int?
        let calorieTargetTraining: Int?
        let calorieTargetRest: Int?
        let onboardingComplete: Bool

        enum CodingKeys: String, CodingKey {
            case name
            case personalityNotes = "personality_notes"
            case communicationStyle = "communication_style"
            case goalPhase = "goal_phase"
            case proteinTarget = "protein_target"
            case calorieTargetTraining = "calorie_target_training"
            case calorieTargetRest = "calorie_target_rest"
            case onboardingComplete = "onboarding_complete"
        }
    }

    /// Get profile from server for memory sync.
    func getProfileForMemorySync() async throws -> ServerProfileResponse {
        let baseURL = ServerConfiguration.configuredBaseURL
        let url = baseURL.appendingPathComponent("profile")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(ServerProfileResponse.self, from: data)
    }

    /// Profile export format for pushing to server.
    struct ServerProfileExport: Encodable {
        let name: String?
        let age: Int?
        let height: String?
        let occupation: String?
        let currentWeightLbs: Double?
        let currentBodyFatPct: Double?
        let targetWeightLbs: Double?
        let targetBodyFatPct: Double?
        let goals: [String]
        let currentPhase: String?
        let phaseContext: String?
        let lifeContext: [String]
        let constraints: [String]
        let preferences: [String]
        let communicationStyle: String?
        let personalityNotes: String?
        let relationshipNotes: String?
        let trainingDaysPerWeek: Int?
        let trainingStyle: String?
        let favoriteActivities: [String]
        let patterns: [String]
        let nutritionGuidelines: [String]
        let onboardingComplete: Bool

        enum CodingKeys: String, CodingKey {
            case name, age, height, occupation, goals, constraints, preferences, patterns
            case currentWeightLbs = "current_weight_lbs"
            case currentBodyFatPct = "current_body_fat_pct"
            case targetWeightLbs = "target_weight_lbs"
            case targetBodyFatPct = "target_body_fat_pct"
            case currentPhase = "current_phase"
            case phaseContext = "phase_context"
            case lifeContext = "life_context"
            case communicationStyle = "communication_style"
            case personalityNotes = "personality_notes"
            case relationshipNotes = "relationship_notes"
            case trainingDaysPerWeek = "training_days_per_week"
            case trainingStyle = "training_style"
            case favoriteActivities = "favorite_activities"
            case nutritionGuidelines = "nutrition_guidelines"
            case onboardingComplete = "onboarding_complete"
        }
    }

    /// Push local profile to server.
    func pushProfile(_ profile: ServerProfileExport) async throws {
        let baseURL = ServerConfiguration.configuredBaseURL
        let url = baseURL.appendingPathComponent("profile/sync")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(profile)
        request.timeoutInterval = 30

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
}
