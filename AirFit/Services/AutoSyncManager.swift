import Foundation
import SwiftData
import BackgroundTasks

/// Notification posted when Hevy cache is updated.
extension Notification.Name {
    static let hevyCacheUpdated = Notification.Name("hevyCacheUpdated")
}

/// Manages automatic data synchronization on app launch and in background.
/// Syncs HealthKit data and nutrition entries to the server for AI analysis.
@MainActor
final class AutoSyncManager: ObservableObject {
    static let shared = AutoSyncManager()

    @Published private(set) var lastSyncTime: Date?
    @Published private(set) var isSyncing = false
    @Published private(set) var syncError: String?

    private let syncService = InsightsSyncService()
    private let healthKit = HealthKitManager()
    private let apiClient = APIClient()
    private let memorySyncService = MemorySyncService()
    private let hevyCacheManager = HevyCacheManager()
    private let hevyService = HevyService.shared
    private let personalitySynthesisService = PersonalitySynthesisService.shared
    private let insightTriggerService = InsightTriggerService.shared

    // Minimum time between syncs (15 minutes)
    private let minSyncInterval: TimeInterval = 15 * 60

    // Minimum time between workout-triggered syncs (2 minutes)
    private let minWorkoutSyncInterval: TimeInterval = 2 * 60
    private var lastWorkoutSyncTime: Date?

    // Reference to ModelContext for workout-triggered sync
    private weak var currentModelContext: ModelContext?

    // Track when app went to background (for smart workout detection)
    private var backgroundedAt: Date?

    // Workout window detection (15 min - 2 hours is typical workout)
    private let minWorkoutDuration: TimeInterval = 15 * 60   // 15 min
    private let maxWorkoutDuration: TimeInterval = 120 * 60  // 2 hours

    private init() {
        setupWorkoutObserver()
    }

    /// Set up observer for HealthKit workout notifications.
    /// When a workout is detected, immediately refreshes Hevy cache.
    private func setupWorkoutObserver() {
        NotificationCenter.default.addObserver(
            forName: .healthKitWorkoutDetected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let count = notification.userInfo?["workoutCount"] as? Int ?? 0
            Task { @MainActor [weak self] in
                await self?.handleWorkoutDetected(workoutCount: count)
            }
        }
    }

    /// Handle workout detection - immediately sync Hevy data.
    private func handleWorkoutDetected(workoutCount: Int) async {
        print("[AutoSync] Workout detected (\(workoutCount) new), triggering immediate Hevy sync...")

        // Throttle to avoid rapid-fire syncs
        if let lastSync = lastWorkoutSyncTime,
           Date().timeIntervalSince(lastSync) < minWorkoutSyncInterval {
            print("[AutoSync] Skipping workout sync - synced recently")
            return
        }

        lastWorkoutSyncTime = Date()

        // Use the stored model context
        guard let modelContext = currentModelContext else {
            print("[AutoSync] No model context available for workout sync")
            return
        }

        // Immediately refresh Hevy cache
        await syncHevyDeviceFirst(modelContext: modelContext, serverAvailable: false)

        // Record new workouts for insight triggering (event-driven, not clock-based)
        await insightTriggerService.recordNewWorkouts(workoutCount)

        // Check if insights should be generated based on new data
        let insightsGenerated = await insightTriggerService.triggerIfNeeded(modelContext: modelContext)
        if insightsGenerated > 0 {
            NotificationCenter.default.post(name: .insightsGenerated, object: nil)
        }

        // Post notification for UI updates
        NotificationCenter.default.post(name: .hevyCacheUpdated, object: nil)
    }

    // MARK: - Public API

    /// Perform initial sync on app launch.
    /// Requests HealthKit permissions if needed, then syncs data.
    func performLaunchSync(modelContext: ModelContext) async {
        print("[AutoSync] 🟡 performLaunchSync START")
        let startTime = Date()

        // Store context for workout-triggered syncs
        currentModelContext = modelContext

        // Start the workout observer for immediate Hevy sync
        print("[AutoSync] 🟡 Starting workout observer...")
        await healthKit.startWorkoutObserver()
        print("[AutoSync] 🟡 Workout observer started")

        // Seed demo data if none exists (for demos/testing)
        await seedDemoDataIfNeeded(modelContext: modelContext)

        // Don't sync if we synced recently
        if let lastSync = lastSyncTime,
           Date().timeIntervalSince(lastSync) < minSyncInterval {
            print("[AutoSync] Skipping - synced recently")
            return
        }

        print("[AutoSync] 🟡 Starting performSync...")
        await performSync(modelContext: modelContext)
        print("[AutoSync] ✅ performLaunchSync COMPLETE in \(Date().timeIntervalSince(startTime))s")
    }

    // MARK: - Smart Workout Detection

    /// Call when app goes to background.
    func appDidEnterBackground() {
        backgroundedAt = Date()
        print("[AutoSync] App backgrounded at \(backgroundedAt!)")
    }

    /// Call when app becomes active. Detects potential workout logging.
    ///
    /// If user was away for 15min - 2hrs (typical workout), aggressively sync Hevy
    /// because they may have just logged a workout in the Hevy app.
    func appDidBecomeActive(modelContext: ModelContext) async {
        guard let backgroundedAt = backgroundedAt else {
            // First launch or no background tracking
            await performLaunchSync(modelContext: modelContext)
            return
        }

        let timeAway = Date().timeIntervalSince(backgroundedAt)
        self.backgroundedAt = nil  // Reset for next background

        // Check if time away matches typical workout duration
        if timeAway >= minWorkoutDuration && timeAway <= maxWorkoutDuration {
            // Potential workout window detected!
            print("[AutoSync] Potential workout detected - away for \(Int(timeAway / 60))min")

            // Force Hevy sync even if we synced recently
            currentModelContext = modelContext
            await syncHevyDeviceFirst(modelContext: modelContext, serverAvailable: false)

            // Record potential workout for insight triggering
            await insightTriggerService.recordNewWorkouts(1)

            // Check if insights should be generated
            let insightsGenerated = await insightTriggerService.triggerIfNeeded(modelContext: modelContext)
            if insightsGenerated > 0 {
                NotificationCenter.default.post(name: .insightsGenerated, object: nil)
            }

            NotificationCenter.default.post(name: .hevyCacheUpdated, object: nil)
        } else {
            // Normal foreground - use regular sync (respects throttle)
            await performLaunchSync(modelContext: modelContext)
        }
    }

    /// Check if current time is within typical workout hours (6am - 9pm)
    private var isWithinWorkoutHours: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 6 && hour <= 21
    }

    // MARK: - Demo Data Seeding

    /// Seeds 14 days of realistic nutrition data if none exists.
    /// Includes training days, rest days, and one cheat day for realism.
    /// Only runs if Developer Mode is enabled AND database has fewer than 3 entries.
    private func seedDemoDataIfNeeded(modelContext: ModelContext) async {
        // DEVELOPER MODE GATE: Only seed demo data when explicitly enabled
        guard UserDefaults.standard.bool(forKey: "developerModeEnabled") else {
            return
        }

        // Check if we already have data
        let descriptor = FetchDescriptor<NutritionEntry>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0

        guard existingCount < 3 else {
            print("[AutoSync] Skipping seed - \(existingCount) entries exist")
            return
        }

        print("[AutoSync] Seeding demo nutrition data (14 days)...")

        let calendar = Calendar.current
        let today = Date()

        // Define realistic meals with variations
        // Format: (name, calories, protein, carbs, fat)
        let breakfasts: [(String, Int, Int, Int, Int)] = [
            ("Greek yogurt with berries and granola", 380, 28, 52, 8),
            ("3 eggs scrambled with cheese and toast", 520, 32, 28, 32),
            ("Oatmeal with banana and peanut butter", 450, 15, 68, 14),
            ("Protein smoothie with banana and oats", 420, 35, 48, 10),
            ("Avocado toast with 2 poached eggs", 480, 24, 32, 28),
            ("Cottage cheese with fruit and honey", 340, 26, 38, 6),
            ("Egg white omelette with vegetables", 320, 28, 12, 14),
        ]

        let lunches: [(String, Int, Int, Int, Int)] = [
            ("Grilled chicken salad with quinoa", 580, 45, 42, 18),
            ("Turkey and avocado wrap", 620, 38, 52, 26),
            ("Salmon poke bowl", 650, 42, 58, 22),
            ("Chicken burrito bowl", 720, 48, 68, 24),
            ("Steak salad with sweet potato", 680, 52, 45, 28),
            ("Tuna sandwich with side salad", 540, 38, 48, 16),
            ("Grilled shrimp with brown rice", 520, 36, 52, 12),
        ]

        let dinners: [(String, Int, Int, Int, Int)] = [
            ("Grilled salmon with rice and vegetables", 680, 48, 52, 24),
            ("Chicken stir fry with brown rice", 620, 45, 58, 18),
            ("Lean beef tacos with beans", 750, 52, 62, 28),
            ("Baked cod with roasted vegetables", 520, 42, 38, 14),
            ("Turkey meatballs with pasta", 720, 48, 72, 22),
            ("Grilled chicken breast with sweet potato", 580, 52, 48, 12),
            ("Pork tenderloin with quinoa", 640, 46, 42, 22),
        ]

        let snacks: [(String, Int, Int, Int, Int)] = [
            ("Protein bar", 220, 20, 24, 8),
            ("Apple with almond butter", 280, 8, 28, 16),
            ("Cottage cheese with fruit", 180, 22, 18, 4),
            ("Mixed nuts", 200, 6, 8, 18),
            ("Protein shake", 160, 25, 8, 3),
            ("Hard boiled eggs (2)", 140, 12, 1, 10),
            ("Rice cakes with peanut butter", 190, 6, 24, 8),
        ]

        // Cheat day meals - higher calories, more indulgent
        let cheatMeals: [(String, Int, Int, Int, Int)] = [
            ("Pancakes with syrup and bacon", 780, 18, 98, 36),
            ("Cheeseburger with fries", 1150, 42, 88, 62),
            ("Pizza (3 slices)", 840, 32, 78, 42),
            ("Ice cream sundae", 480, 8, 62, 22),
            ("Nachos with cheese and guac", 620, 16, 52, 38),
        ]

        // Training days: Mon(2), Tue(3), Thu(5), Fri(6), Sat(7) - 5 days/week
        let trainingWeekdays = [2, 3, 5, 6, 7]

        // Calorie targets based on day type
        let trainingDayTarget = 2600  // Higher for workout days
        let restDayTarget = 2200      // Moderate for rest days

        // Pick a cheat day (8 days ago - a Saturday)
        let cheatDayOffset = 8

        for daysAgo in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            let isTrainingDay = trainingWeekdays.contains(weekday)
            let isCheatDay = daysAgo == cheatDayOffset

            // Vary meal selection based on day
            let dayHash = daysAgo * 7 + weekday
            let breakfastIdx = dayHash % breakfasts.count
            let lunchIdx = (dayHash + 3) % lunches.count
            let dinnerIdx = (dayHash + 5) % dinners.count
            let snackIdx = (dayHash + 2) % snacks.count

            var dayMeals: [(String, Int, Int, Int, Int, Int)] = []
            var targetCalories: Int

            if isCheatDay {
                // Cheat day: indulgent - no target scaling (just let it be high)
                targetCalories = 3200  // High but we won't scale these
                dayMeals = [
                    (cheatMeals[0].0, cheatMeals[0].1, cheatMeals[0].2, cheatMeals[0].3, cheatMeals[0].4, 10), // Late brunch
                    (cheatMeals[1].0, cheatMeals[1].1, cheatMeals[1].2, cheatMeals[1].3, cheatMeals[1].4, 14), // Burger
                    (cheatMeals[2].0, cheatMeals[2].1, cheatMeals[2].2, cheatMeals[2].3, cheatMeals[2].4, 19), // Pizza
                    (cheatMeals[3].0, cheatMeals[3].1, cheatMeals[3].2, cheatMeals[3].3, cheatMeals[3].4, 21), // Dessert
                ]
            } else if isTrainingDay {
                // Training day: more food, extra snacks, higher protein - target 2600 cal
                targetCalories = trainingDayTarget
                let breakfast = breakfasts[breakfastIdx]
                let lunch = lunches[lunchIdx]
                let dinner = dinners[dinnerIdx]
                let snack1 = snacks[snackIdx]
                let snack2 = snacks[(snackIdx + 2) % snacks.count]

                dayMeals = [
                    (breakfast.0, breakfast.1, breakfast.2, breakfast.3, breakfast.4, 7),
                    (snack1.0, snack1.1, snack1.2, snack1.3, snack1.4, 10),
                    (lunch.0, lunch.1, lunch.2, lunch.3, lunch.4, 12),
                    (snack2.0, snack2.1, snack2.2, snack2.3, snack2.4, 16),
                    (dinner.0, dinner.1, dinner.2, dinner.3, dinner.4, 19),
                    ("Protein shake", 160, 25, 8, 3, 21), // Post-workout recovery
                ]
            } else {
                // Rest day: moderate intake, fewer snacks - target 2200 cal
                targetCalories = restDayTarget
                let breakfast = breakfasts[breakfastIdx]
                let lunch = lunches[lunchIdx]
                let dinner = dinners[dinnerIdx]
                let snack = snacks[snackIdx]

                dayMeals = [
                    (breakfast.0, breakfast.1, breakfast.2, breakfast.3, breakfast.4, 8),
                    (lunch.0, lunch.1, lunch.2, lunch.3, lunch.4, 12),
                    (snack.0, snack.1, snack.2, snack.3, snack.4, 15),
                    (dinner.0, dinner.1, dinner.2, dinner.3, dinner.4, 18),
                ]
            }

            // Calculate raw total from selected meals
            let rawTotal = dayMeals.reduce(0) { $0 + $1.1 }

            // Scale factor to hit target (only for non-cheat days)
            let baseScale = isCheatDay ? 1.0 : (Double(targetCalories) / Double(max(1, rawTotal)))

            // Apply daily variance on top of the target-based scaling
            // This creates realistic patterns: some days under, some over target
            let varianceFactors: [Double] = [1.0, 0.92, 1.08, 0.95, 1.05, 0.88, 1.02, 1.0, 0.90, 1.10, 0.97, 1.03, 0.94, 1.06]
            let dayVariance = varianceFactors[daysAgo % varianceFactors.count]
            let combinedScale = baseScale * dayVariance

            for (name, cal, protein, carbs, fat, hour) in dayMeals {
                // Apply combined scaling (target + variance)
                let adjustedCal = Int(Double(cal) * combinedScale)
                let adjustedProtein = Int(Double(protein) * combinedScale)
                let adjustedCarbs = Int(Double(carbs) * combinedScale)
                let adjustedFat = Int(Double(fat) * combinedScale)

                // Create timestamp at specific hour with random minutes
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = hour
                components.minute = Int.random(in: 0...59)
                let timestamp = calendar.date(from: components) ?? date

                let entry = NutritionEntry(
                    name: name,
                    calories: adjustedCal,
                    protein: adjustedProtein,
                    carbs: adjustedCarbs,
                    fat: adjustedFat,
                    confidence: "demo",
                    timestamp: timestamp
                )
                modelContext.insert(entry)
            }
        }

        // Save
        try? modelContext.save()
        print("[AutoSync] Seeded demo nutrition data for 14 days (incl. cheat day)")
    }

    /// Force a sync regardless of timing.
    func forceSync(modelContext: ModelContext) async {
        await performSync(modelContext: modelContext)
    }

    // MARK: - Private

    private func performSync(modelContext: ModelContext) async {
        guard !isSyncing else { return }

        isSyncing = true
        syncError = nil

        // Check current AI mode
        let aiMode = UserDefaults.standard.string(forKey: "aiProvider") ?? "claude"
        let isGeminiDirectMode = aiMode == "gemini"

        // Check server health in ALL modes (memory backup works regardless of chat provider)
        // This is a non-blocking check - if server is offline, we proceed with local-only
        let serverAvailable = await apiClient.checkHealth()

        do {
            // 1. Request HealthKit permissions (no-op if already granted)
            _ = await healthKit.requestAuthorization()

            // 2. Hevy sync (device-first always, fallback to server only if available)
            await syncHevyDeviceFirst(modelContext: modelContext, serverAvailable: serverAvailable)

            // Server-dependent syncs
            // Note: Memory sync is allowed in ALL modes (it's a backup, not dependency)
            // Only daily snapshot sync is skipped in Gemini mode (server doesn't need it)
            if serverAvailable {
                // Memory sync for ALL modes (backup memories to server)
                await memorySyncService.syncToServer(modelContext: modelContext)
                await memorySyncService.syncFromServer(modelContext: modelContext)
                print("[AutoSync] Memory sync completed")

                // Daily snapshot sync only for Claude mode (server needs this for insights)
                if !isGeminiDirectMode {
                    try await syncService.syncRecentDays(7, modelContext: modelContext)
                    print("[AutoSync] Daily snapshot sync completed")
                }
            } else if isGeminiDirectMode {
                print("[AutoSync] Gemini Direct mode - server unavailable, using local data only")
            } else {
                print("[AutoSync] Server unavailable - using local data only")
            }

            // 5. Persona synthesis (runs on every sync if needed)
            // This regenerates the LLM-synthesized coaching persona when:
            // - No persona exists yet (and onboarding is complete)
            // - Weekly refresh (>7 days old)
            // - Profile was updated
            // - Memory threshold reached (10+ new memories)
            await regeneratePersonaIfNeeded(modelContext: modelContext)

            // 6. Insight generation (event-driven, not clock-based)
            // Triggers when enough new data has accumulated or significant events occurred
            let insightsGenerated = await insightTriggerService.triggerIfNeeded(modelContext: modelContext)
            if insightsGenerated > 0 {
                print("[AutoSync] Generated \(insightsGenerated) new insights")
                NotificationCenter.default.post(name: .insightsGenerated, object: nil)
            }

            lastSyncTime = Date()
            print("[AutoSync] Sync completed successfully")

        } catch {
            syncError = error.localizedDescription
            print("[AutoSync] Sync failed: \(error)")
        }

        isSyncing = false
    }

    /// Regenerate the coaching persona if conditions are met.
    ///
    /// The persona is LLM-synthesized prose that captures the coaching approach.
    /// It incorporates profile, calibration, memories, and patterns into
    /// natural language that matures with the relationship.
    private func regeneratePersonaIfNeeded(modelContext: ModelContext) async {
        guard await personalitySynthesisService.shouldRegenerate(modelContext: modelContext) else {
            return
        }

        print("[AutoSync] Regenerating coaching persona...")

        let success = await personalitySynthesisService.synthesizeAndSave(modelContext: modelContext)

        if success {
            print("[AutoSync] Coaching persona regenerated successfully")
        } else {
            print("[AutoSync] Coaching persona regeneration failed (will retry next sync)")
        }
    }

    /// Sync Hevy data (device-first, server fallback).
    private func syncHevyDeviceFirst(modelContext: ModelContext, serverAvailable: Bool) async {
        // Try device-first if API key is configured locally
        if await hevyService.isConfigured() {
            do {
                try await hevyCacheManager.refreshFromDevice(modelContext: modelContext)
                print("[AutoSync] Hevy cache refreshed (from device)")
                return
            } catch {
                print("[AutoSync] Device Hevy sync failed: \(error)")
                // Fall through to server sync
            }
        }

        // Fallback to server
        if serverAvailable {
            do {
                _ = try await syncHevyToServer()
                try await hevyCacheManager.refreshFromServer(modelContext: modelContext)
                print("[AutoSync] Hevy cache refreshed (from server)")
            } catch {
                // Hevy sync is optional - don't fail the whole sync
                print("[AutoSync] Server Hevy sync skipped: \(error)")
            }
        } else {
            print("[AutoSync] Hevy sync skipped - no local key and server unavailable")
        }
    }

    // MARK: - Background Tasks

    /// Register background tasks for periodic sync.
    /// Call this from AppDelegate.
    static func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.airfit.app.sync",
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                print("[AutoSync] Invalid task type received")
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor in
                await handleBackgroundSync(task: refreshTask)
            }
        }
    }

    /// Schedule the next background sync.
    static func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: "com.airfit.app.sync")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour

        do {
            try BGTaskScheduler.shared.submit(request)
            print("[AutoSync] Background sync scheduled")
        } catch {
            print("[AutoSync] Failed to schedule background sync: \(error)")
        }
    }

    private static func handleBackgroundSync(task: BGAppRefreshTask) async {
        // Schedule the next sync
        scheduleBackgroundSync()

        // Note: Background sync would need access to ModelContext
        // This is a simplified version - full implementation would
        // use a background ModelContainer

        task.setTaskCompleted(success: true)
    }
}

// MARK: - Hevy Sync Helper

private func syncHevyToServer() async throws -> Bool {
    #if targetEnvironment(simulator)
    let baseURL = URL(string: "http://localhost:8080")!
    #else
    let baseURL = URL(string: "http://192.168.86.50:8080")!
    #endif

    let url = baseURL.appendingPathComponent("hevy/sync")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 30

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }

    struct SyncResponse: Codable {
        let status: String
    }

    let result = try JSONDecoder().decode(SyncResponse.self, from: data)
    return result.status == "success"
}
