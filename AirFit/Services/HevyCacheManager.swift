import Foundation
import SwiftData

/// Manages local caching of Hevy workout data.
///
/// Supports both device-first (HevyService) and server-routed (APIClient) sync.
/// Device-first is preferred when Hevy API key is stored locally.
///
/// ## Usage Pattern
/// ```swift
/// // Prefer device-first sync (no server needed)
/// if await hevyService.isConfigured() {
///     try await hevyCacheManager.refreshFromDevice(modelContext: context)
/// } else if await apiClient.checkHealth() {
///     try await hevyCacheManager.refreshFromServer(modelContext: context)
/// }
///
/// // Always use cached data for display
/// let workouts = await hevyCacheManager.getRecentWorkouts(modelContext: context)
/// ```
actor HevyCacheManager {
    private let apiClient = APIClient()
    private let hevyService = HevyService.shared

    // MARK: - Cache Refresh

    /// Refresh all Hevy caches from server.
    ///
    /// Fetches set tracker, lift progress, and recent workouts,
    /// then stores them in SwiftData for offline access.
    ///
    /// - Parameter modelContext: SwiftData context for persistence
    /// - Throws: If server unavailable or API fails
    @MainActor
    func refreshFromServer(modelContext: ModelContext) async throws {
        print("[HevyCacheManager] Starting cache refresh...")

        // Fetch all data in parallel
        async let setTrackerResult = apiClient.getSetTracker()
        async let liftProgressResult = apiClient.getLiftProgress()
        async let workoutsResult = apiClient.getRecentWorkouts()

        do {
            let (setTracker, liftProgress, workouts) = try await (
                setTrackerResult,
                liftProgressResult,
                workoutsResult
            )

            // Store set tracker
            await storeSetTracker(setTracker, modelContext: modelContext)

            // Store lift progress
            await storeLiftProgress(liftProgress, modelContext: modelContext)

            // Store workouts
            await storeWorkouts(workouts, modelContext: modelContext)

            // Update metadata
            await updateMetadata(
                windowDays: setTracker.window_days,
                lastSync: setTracker.last_sync,
                modelContext: modelContext
            )

            print("[HevyCacheManager] Cache refresh complete (from server)")

        } catch {
            print("[HevyCacheManager] Server refresh failed: \(error)")
            throw error
        }
    }

    /// Refresh all Hevy caches directly from Hevy API (device-first).
    ///
    /// Uses HevyService to call Hevy API directly with locally stored API key.
    /// Fetches full workout data including all sets for rich AI context.
    /// No server dependency required.
    ///
    /// - Parameter modelContext: SwiftData context for persistence
    /// - Throws: If Hevy API unavailable or key not configured
    @MainActor
    func refreshFromDevice(modelContext: ModelContext) async throws {
        print("[HevyCacheManager] Starting device-first cache refresh...")

        guard await hevyService.isConfigured() else {
            throw HevyError.noAPIKey
        }

        let metadata = getOrCreateMetadata(modelContext: modelContext)

        // Check if we can do incremental sync
        if let newestDate = metadata.newestWorkoutDate {
            // Try incremental sync first
            do {
                let newWorkouts = try await hevyService.getWorkoutsSince(newestDate)
                if !newWorkouts.isEmpty {
                    print("[HevyCacheManager] Incremental sync: \(newWorkouts.count) new workout(s)")
                    await appendWorkoutsFromDevice(newWorkouts, modelContext: modelContext)

                    // Update metadata with newest workout date
                    if let newest = newWorkouts.first {
                        metadata.newestWorkoutDate = newest.date
                    }
                    metadata.lastRefresh = Date()
                    metadata.cachedWorkoutCount += newWorkouts.count
                    try? modelContext.save()

                    // Also refresh set tracker and lift progress
                    await refreshVolumeAndPRs(modelContext: modelContext)

                    print("[HevyCacheManager] Incremental refresh complete")
                    return
                }
            } catch {
                print("[HevyCacheManager] Incremental sync failed, falling back to full refresh: \(error)")
            }
        }

        // Full refresh - fetch all data
        async let fullWorkouts = hevyService.getFullWorkouts(days: 30)
        async let liftProgress = hevyService.getLiftProgress(days: 90)
        async let setTracker = hevyService.getSetTracker(windowDays: 7)

        do {
            let (workouts, lifts, tracker) = try await (
                fullWorkouts,
                liftProgress,
                setTracker
            )

            // Store full workouts with all set data
            await storeFullWorkoutsFromDevice(workouts, modelContext: modelContext)

            // Store lift progress
            await storeLiftProgressFromDevice(lifts, modelContext: modelContext)

            // Store set tracker
            await storeSetTrackerFromDevice(tracker, modelContext: modelContext)

            // Update metadata
            metadata.windowDays = tracker.windowDays
            metadata.lastSyncTimestamp = ISO8601DateFormatter().string(from: Date())
            metadata.lastRefresh = Date()
            metadata.newestWorkoutDate = workouts.first?.date
            metadata.cachedWorkoutCount = workouts.count
            try? modelContext.save()

            print("[HevyCacheManager] Full cache refresh complete (\(workouts.count) workouts)")

        } catch {
            print("[HevyCacheManager] Device refresh failed: \(error)")
            throw error
        }
    }

    /// Refresh only volume tracking and PRs (lighter update).
    @MainActor
    private func refreshVolumeAndPRs(modelContext: ModelContext) async {
        do {
            async let liftProgress = hevyService.getLiftProgress(days: 90)
            async let setTracker = hevyService.getSetTracker(windowDays: 7)

            let (lifts, tracker) = try await (liftProgress, setTracker)

            await storeLiftProgressFromDevice(lifts, modelContext: modelContext)
            await storeSetTrackerFromDevice(tracker, modelContext: modelContext)
        } catch {
            print("[HevyCacheManager] Volume/PR refresh failed: \(error)")
        }
    }

    /// Refresh only if cache is stale (prefers device-first).
    ///
    /// Tries HevyService first (device-first), falls back to server.
    /// Silently succeeds if cache is fresh or refresh fails.
    @MainActor
    func refreshIfStale(
        modelContext: ModelContext,
        thresholdMinutes: Int = 60
    ) async {
        let metadata = getOrCreateMetadata(modelContext: modelContext)
        guard metadata.isStale(thresholdMinutes: thresholdMinutes) else {
            return
        }

        // Prefer device-first (HevyService)
        if await hevyService.isConfigured() {
            do {
                try await refreshFromDevice(modelContext: modelContext)
                return
            } catch {
                print("[HevyCacheManager] Device refresh failed, trying server: \(error)")
            }
        }

        // Fallback to server
        guard await apiClient.checkHealth() else {
            print("[HevyCacheManager] Server unavailable, using stale cache")
            return
        }

        try? await refreshFromServer(modelContext: modelContext)
    }

    /// Refresh if stale with shorter threshold for active chatting.
    ///
    /// Uses 5-minute threshold when user is actively chatting with coach
    /// to ensure fresh workout context.
    @MainActor
    func refreshForChat(modelContext: ModelContext) async {
        let metadata = getOrCreateMetadata(modelContext: modelContext)

        // Use shorter threshold for chat (5 minutes)
        guard metadata.isStaleForChat(thresholdMinutes: 5) else {
            return
        }

        print("[HevyCacheManager] Refreshing for chat (5-min threshold)...")
        await refreshIfStale(modelContext: modelContext, thresholdMinutes: 5)
    }

    // MARK: - Data Storage

    @MainActor
    private func storeSetTracker(_ response: APIClient.SetTrackerResponse, modelContext: ModelContext) async {
        // Delete existing entries
        let existing = FetchDescriptor<CachedSetTracker>()
        if let oldEntries = try? modelContext.fetch(existing) {
            for entry in oldEntries {
                modelContext.delete(entry)
            }
        }

        // Insert new entries
        for (muscleGroup, data) in response.muscle_groups {
            let cached = CachedSetTracker(muscleGroup: muscleGroup, from: data)
            modelContext.insert(cached)
        }

        try? modelContext.save()
        print("[HevyCacheManager] Stored \(response.muscle_groups.count) muscle groups")
    }

    @MainActor
    private func storeLiftProgress(_ response: APIClient.LiftProgressResponse, modelContext: ModelContext) async {
        // Delete existing entries
        let existing = FetchDescriptor<CachedLiftProgress>()
        if let oldEntries = try? modelContext.fetch(existing) {
            for entry in oldEntries {
                modelContext.delete(entry)
            }
        }

        // Insert new entries
        for lift in response.lifts {
            let cached = CachedLiftProgress(from: lift)
            modelContext.insert(cached)
        }

        try? modelContext.save()
        print("[HevyCacheManager] Stored \(response.lifts.count) lifts")
    }

    @MainActor
    private func storeWorkouts(_ workouts: [APIClient.WorkoutSummary], modelContext: ModelContext) async {
        // Delete existing entries
        let existing = FetchDescriptor<CachedWorkout>()
        if let oldEntries = try? modelContext.fetch(existing) {
            for entry in oldEntries {
                modelContext.delete(entry)
            }
        }

        // Insert new entries
        for workout in workouts {
            let cached = CachedWorkout(from: workout)
            modelContext.insert(cached)
        }

        try? modelContext.save()
        print("[HevyCacheManager] Stored \(workouts.count) workouts")
    }

    // MARK: - Device Storage (from HevyService)

    @MainActor
    private func storeWorkoutsFromDevice(_ workouts: [HevyService.WorkoutSummary], modelContext: ModelContext) async {
        // Delete existing entries
        let existing = FetchDescriptor<CachedWorkout>()
        if let oldEntries = try? modelContext.fetch(existing) {
            for entry in oldEntries {
                modelContext.delete(entry)
            }
        }

        // Insert new entries
        for workout in workouts {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]

            let cached = CachedWorkout(
                id: workout.id,
                title: workout.title,
                workoutDate: workout.date,
                daysAgo: workout.daysAgo,
                durationMinutes: workout.durationMinutes,
                totalVolumeLbs: workout.totalVolumeLbs,
                exercises: workout.exercises
            )
            modelContext.insert(cached)
        }

        try? modelContext.save()
        print("[HevyCacheManager] Stored \(workouts.count) workouts (from device)")
    }

    @MainActor
    private func storeLiftProgressFromDevice(_ lifts: [HevyService.LiftProgress], modelContext: ModelContext) async {
        // Delete existing entries
        let existing = FetchDescriptor<CachedLiftProgress>()
        if let oldEntries = try? modelContext.fetch(existing) {
            for entry in oldEntries {
                modelContext.delete(entry)
            }
        }

        // Insert new entries
        for lift in lifts {
            let history = lift.history.map { point in
                CachedLiftProgress.HistoryPoint(date: point.date, weightLbs: point.weightLbs)
            }

            let cached = CachedLiftProgress(
                exerciseName: lift.name,
                currentPRWeightLbs: lift.currentPRWeightLbs,
                currentPRReps: lift.currentPRReps,
                currentPRDate: lift.currentPRDate,
                workoutCount: lift.workoutCount,
                history: history
            )
            modelContext.insert(cached)
        }

        try? modelContext.save()
        print("[HevyCacheManager] Stored \(lifts.count) lifts (from device)")
    }

    @MainActor
    private func storeSetTrackerFromDevice(_ tracker: HevyService.SetTrackerData, modelContext: ModelContext) async {
        // Delete existing entries
        let existing = FetchDescriptor<CachedSetTracker>()
        if let oldEntries = try? modelContext.fetch(existing) {
            for entry in oldEntries {
                modelContext.delete(entry)
            }
        }

        // Insert new entries
        for (muscleGroup, data) in tracker.muscleGroups {
            let cached = CachedSetTracker(
                muscleGroup: muscleGroup,
                currentSets: data.current,
                optimalMin: data.min,
                optimalMax: data.max,
                status: data.status
            )
            modelContext.insert(cached)
        }

        try? modelContext.save()
        print("[HevyCacheManager] Stored \(tracker.muscleGroups.count) muscle groups (from device)")
    }

    /// Store full workouts with all set data (replaces existing cache).
    @MainActor
    private func storeFullWorkoutsFromDevice(_ workouts: [HevyService.FullWorkoutData], modelContext: ModelContext) async {
        // Delete existing entries
        let existing = FetchDescriptor<CachedWorkout>()
        if let oldEntries = try? modelContext.fetch(existing) {
            for entry in oldEntries {
                modelContext.delete(entry)
            }
        }

        // Insert new entries with full exercise/set data
        for workout in workouts {
            let fullExercises = workout.exercises.map { exercise in
                CachedExercise(
                    name: exercise.name,
                    sets: exercise.sets.map { set in
                        CachedSet(
                            reps: set.reps,
                            weightLbs: set.weightLbs,
                            type: set.type,
                            rpe: set.rpe
                        )
                    },
                    notes: exercise.notes
                )
            }

            let cached = CachedWorkout(
                id: workout.id,
                title: workout.title,
                workoutDate: workout.date,
                daysAgo: Calendar.current.dateComponents([.day], from: workout.date, to: Date()).day ?? 0,
                durationMinutes: workout.durationMinutes,
                totalVolumeLbs: workout.totalVolumeLbs,
                exercises: workout.exercises.map(\.name),
                fullExercises: fullExercises,
                description: workout.description
            )
            modelContext.insert(cached)
        }

        try? modelContext.save()
        print("[HevyCacheManager] Stored \(workouts.count) full workouts (from device)")
    }

    /// Append new workouts to existing cache (incremental sync).
    @MainActor
    private func appendWorkoutsFromDevice(_ workouts: [HevyService.FullWorkoutData], modelContext: ModelContext) async {
        // Get existing workout IDs to avoid duplicates
        let existingDescriptor = FetchDescriptor<CachedWorkout>()
        let existingWorkouts = (try? modelContext.fetch(existingDescriptor)) ?? []
        let existingIds = Set(existingWorkouts.map(\.id))

        var newCount = 0
        for workout in workouts where !existingIds.contains(workout.id) {
            let fullExercises = workout.exercises.map { exercise in
                CachedExercise(
                    name: exercise.name,
                    sets: exercise.sets.map { set in
                        CachedSet(
                            reps: set.reps,
                            weightLbs: set.weightLbs,
                            type: set.type,
                            rpe: set.rpe
                        )
                    },
                    notes: exercise.notes
                )
            }

            let cached = CachedWorkout(
                id: workout.id,
                title: workout.title,
                workoutDate: workout.date,
                daysAgo: Calendar.current.dateComponents([.day], from: workout.date, to: Date()).day ?? 0,
                durationMinutes: workout.durationMinutes,
                totalVolumeLbs: workout.totalVolumeLbs,
                exercises: workout.exercises.map(\.name),
                fullExercises: fullExercises,
                description: workout.description
            )
            modelContext.insert(cached)
            newCount += 1
        }

        try? modelContext.save()
        print("[HevyCacheManager] Appended \(newCount) new workouts (incremental)")
    }

    @MainActor
    private func updateMetadata(
        windowDays: Int,
        lastSync: String?,
        modelContext: ModelContext
    ) async {
        let metadata = getOrCreateMetadata(modelContext: modelContext)
        metadata.lastRefresh = Date()
        metadata.windowDays = windowDays
        metadata.lastSyncTimestamp = lastSync
        try? modelContext.save()
    }

    @MainActor
    private func getOrCreateMetadata(modelContext: ModelContext) -> HevyCacheMetadata {
        let descriptor = FetchDescriptor<HevyCacheMetadata>()
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let metadata = HevyCacheMetadata()
        modelContext.insert(metadata)
        return metadata
    }

    // MARK: - Data Retrieval

    /// Get cached recent workouts.
    @MainActor
    func getRecentWorkouts(modelContext: ModelContext, limit: Int = 7) -> [CachedWorkout] {
        var descriptor = FetchDescriptor<CachedWorkout>(
            sortBy: [CachedWorkout.recentFirst]
        )
        descriptor.fetchLimit = limit

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Get cached lift progress (for PR tracking).
    @MainActor
    func getLiftProgress(modelContext: ModelContext, topN: Int = 6) -> [CachedLiftProgress] {
        var descriptor = FetchDescriptor<CachedLiftProgress>(
            sortBy: [CachedLiftProgress.byWorkoutCount]
        )
        descriptor.fetchLimit = topN

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Get cached set tracker (for volume zones).
    @MainActor
    func getSetTracker(modelContext: ModelContext) -> [CachedSetTracker] {
        let descriptor = FetchDescriptor<CachedSetTracker>(
            sortBy: [CachedSetTracker.alphabetical]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Get muscle groups that are below target volume.
    @MainActor
    func getMuscleGroupsBelowTarget(modelContext: ModelContext) -> [CachedSetTracker] {
        let descriptor = FetchDescriptor<CachedSetTracker>(
            predicate: CachedSetTracker.belowTarget,
            sortBy: [CachedSetTracker.alphabetical]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Cache Status

    /// Check if cache is stale (needs refresh).
    @MainActor
    func isCacheStale(modelContext: ModelContext, thresholdMinutes: Int = 60) -> Bool {
        let metadata = getOrCreateMetadata(modelContext: modelContext)
        return metadata.isStale(thresholdMinutes: thresholdMinutes)
    }

    /// Check if cache has any data.
    @MainActor
    func hasCache(modelContext: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<CachedWorkout>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    /// Get human-readable cache age.
    @MainActor
    func cacheAgeDescription(modelContext: ModelContext) -> String {
        let metadata = getOrCreateMetadata(modelContext: modelContext)
        return metadata.ageDescription
    }

    /// Get cache metadata.
    @MainActor
    func getCacheMetadata(modelContext: ModelContext) -> HevyCacheMetadata {
        getOrCreateMetadata(modelContext: modelContext)
    }

    // MARK: - Clear Cache

    /// Clear all cached Hevy data.
    @MainActor
    func clearCache(modelContext: ModelContext) {
        // Clear workouts
        let workouts = FetchDescriptor<CachedWorkout>()
        if let entries = try? modelContext.fetch(workouts) {
            for entry in entries { modelContext.delete(entry) }
        }

        // Clear lift progress
        let lifts = FetchDescriptor<CachedLiftProgress>()
        if let entries = try? modelContext.fetch(lifts) {
            for entry in entries { modelContext.delete(entry) }
        }

        // Clear set tracker
        let sets = FetchDescriptor<CachedSetTracker>()
        if let entries = try? modelContext.fetch(sets) {
            for entry in entries { modelContext.delete(entry) }
        }

        // Clear metadata
        let meta = FetchDescriptor<HevyCacheMetadata>()
        if let entries = try? modelContext.fetch(meta) {
            for entry in entries { modelContext.delete(entry) }
        }

        try? modelContext.save()
        print("[HevyCacheManager] Cache cleared")
    }

    // MARK: - Context Building (for AI prompts)

    /// Build workout context string for AI prompts.
    ///
    /// Formats cached data compactly for injection into chat context.
    /// Uses full exercise/set data when available for richer context.
    @MainActor
    func buildWorkoutContext(modelContext: ModelContext) -> String {
        var sections: [String] = []

        // Recent workouts - use detailed context when available
        let workouts = getRecentWorkouts(modelContext: modelContext, limit: 7)
        if !workouts.isEmpty {
            var workoutLines: [String] = ["Recent workouts:"]
            for workout in workouts {
                // Use rich detailed context if we have full exercise data
                if !workout.fullExercises.isEmpty {
                    workoutLines.append(workout.detailedContext)
                } else {
                    // Fallback to basic summary
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMM d"
                    let dateStr = dateFormatter.string(from: workout.workoutDate)
                    let exercises = workout.exercises.prefix(4).joined(separator: ", ")
                    workoutLines.append("  \(dateStr): \(workout.title) (\(workout.durationMinutes)min, \(Int(workout.totalVolumeLbs))lbs) - \(exercises)")
                }
            }
            sections.append(workoutLines.joined(separator: "\n"))
        }

        // Lift progress (PRs)
        let lifts = getLiftProgress(modelContext: modelContext, topN: 5)
        if !lifts.isEmpty {
            var prLines: [String] = ["Current PRs:"]
            for lift in lifts {
                prLines.append("  \(lift.exerciseName): \(Int(lift.currentPRWeightLbs))lbs × \(lift.currentPRReps) (\(lift.workoutCount) sessions)")
            }
            sections.append(prLines.joined(separator: "\n"))
        }

        // Volume zones
        let setTracker = getSetTracker(modelContext: modelContext)
        if !setTracker.isEmpty {
            let belowTarget = setTracker.filter { !$0.isInZone }
            if !belowTarget.isEmpty {
                var volumeLines: [String] = ["Volume gaps (below target):"]
                for muscle in belowTarget.prefix(5) {
                    volumeLines.append("  \(muscle.muscleGroup): \(muscle.currentSets)/\(muscle.optimalMin)-\(muscle.optimalMax) sets")
                }
                sections.append(volumeLines.joined(separator: "\n"))
            }
        }

        guard !sections.isEmpty else { return "" }
        return "--- TRAINING DATA (cached) ---\n" + sections.joined(separator: "\n\n")
    }
}
