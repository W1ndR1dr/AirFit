import Foundation
import SwiftData
import BackgroundTasks

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

    // Minimum time between syncs (15 minutes)
    private let minSyncInterval: TimeInterval = 15 * 60

    private init() {}

    // MARK: - Public API

    /// Perform initial sync on app launch.
    /// Requests HealthKit permissions if needed, then syncs data.
    func performLaunchSync(modelContext: ModelContext) async {
        // Seed demo data if none exists (for demos/testing)
        await seedDemoDataIfNeeded(modelContext: modelContext)

        // Don't sync if we synced recently
        if let lastSync = lastSyncTime,
           Date().timeIntervalSince(lastSync) < minSyncInterval {
            print("[AutoSync] Skipping - synced recently")
            return
        }

        await performSync(modelContext: modelContext)
    }

    // MARK: - Demo Data Seeding

    /// Seeds 7 days of plausible nutrition data if none exists.
    /// Only runs if the database has fewer than 3 entries.
    private func seedDemoDataIfNeeded(modelContext: ModelContext) async {
        // Check if we already have data
        let descriptor = FetchDescriptor<NutritionEntry>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0

        guard existingCount < 3 else {
            print("[AutoSync] Skipping seed - \(existingCount) entries exist")
            return
        }

        print("[AutoSync] Seeding demo nutrition data...")

        // Generate 7 days of realistic nutrition data
        let calendar = Calendar.current
        let today = Date()

        // Define realistic meals with variations
        let breakfasts: [(String, Int, Int, Int, Int)] = [
            ("Greek yogurt with berries and granola", 380, 28, 52, 8),
            ("3 eggs scrambled with cheese and toast", 520, 32, 28, 32),
            ("Oatmeal with banana and peanut butter", 450, 15, 68, 14),
            ("Protein smoothie with banana and oats", 420, 35, 48, 10),
            ("Avocado toast with 2 poached eggs", 480, 24, 32, 28),
        ]

        let lunches: [(String, Int, Int, Int, Int)] = [
            ("Grilled chicken salad with quinoa", 580, 45, 42, 18),
            ("Turkey and avocado wrap", 620, 38, 52, 26),
            ("Salmon poke bowl", 650, 42, 58, 22),
            ("Chicken burrito bowl", 720, 48, 68, 24),
            ("Steak salad with sweet potato", 680, 52, 45, 28),
        ]

        let dinners: [(String, Int, Int, Int, Int)] = [
            ("Grilled salmon with rice and vegetables", 680, 48, 52, 24),
            ("Chicken stir fry with brown rice", 620, 45, 58, 18),
            ("Lean beef tacos with beans", 750, 52, 62, 28),
            ("Baked cod with roasted vegetables", 520, 42, 38, 14),
            ("Turkey meatballs with pasta", 720, 48, 72, 22),
        ]

        let snacks: [(String, Int, Int, Int, Int)] = [
            ("Protein bar", 220, 20, 24, 8),
            ("Apple with almond butter", 280, 8, 28, 16),
            ("Cottage cheese with fruit", 180, 22, 18, 4),
            ("Mixed nuts", 200, 6, 8, 18),
            ("Protein shake", 160, 25, 8, 3),
        ]

        // Training days pattern (Mon, Tue, Thu, Fri, Sat = training)
        let trainingDays = [2, 3, 5, 6, 7] // weekday numbers

        for daysAgo in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            let isTrainingDay = trainingDays.contains(weekday)

            // Randomly pick meals for variety
            let breakfastIdx = (daysAgo + 1) % breakfasts.count
            let lunchIdx = (daysAgo + 2) % lunches.count
            let dinnerIdx = (daysAgo + 3) % dinners.count
            let snackIdx = daysAgo % snacks.count

            let breakfast = breakfasts[breakfastIdx]
            let lunch = lunches[lunchIdx]
            let dinner = dinners[dinnerIdx]
            let snack = snacks[snackIdx]

            // Training days get extra snack and slightly higher totals
            let meals: [(String, Int, Int, Int, Int, Int)] = isTrainingDay ? [
                (breakfast.0, breakfast.1, breakfast.2, breakfast.3, breakfast.4, 8),
                (lunch.0, lunch.1, lunch.2, lunch.3, lunch.4, 12),
                (snack.0, snack.1, snack.2, snack.3, snack.4, 15),
                (dinner.0, dinner.1, dinner.2, dinner.3, dinner.4, 19),
                (snacks[(snackIdx + 1) % snacks.count].0, snacks[(snackIdx + 1) % snacks.count].1, snacks[(snackIdx + 1) % snacks.count].2, snacks[(snackIdx + 1) % snacks.count].3, snacks[(snackIdx + 1) % snacks.count].4, 21),
            ] : [
                (breakfast.0, breakfast.1, breakfast.2, breakfast.3, breakfast.4, 8),
                (lunch.0, lunch.1, lunch.2, lunch.3, lunch.4, 12),
                (dinner.0, dinner.1, dinner.2, dinner.3, dinner.4, 18),
            ]

            // Add some variance to hit/miss targets
            let variance = Double.random(in: 0.85...1.10)

            for (name, cal, protein, carbs, fat, hour) in meals {
                // Apply variance
                let adjustedCal = Int(Double(cal) * variance)
                let adjustedProtein = Int(Double(protein) * variance)
                let adjustedCarbs = Int(Double(carbs) * variance)
                let adjustedFat = Int(Double(fat) * variance)

                // Create timestamp at specific hour
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
        print("[AutoSync] Seeded demo nutrition data for 7 days")
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

        do {
            // 1. Request HealthKit permissions (no-op if already granted)
            _ = await healthKit.requestAuthorization()

            // 2. Sync the last 7 days of data to server
            try await syncService.syncRecentDays(7, modelContext: modelContext)

            // 3. Trigger Hevy sync on server (if API key is configured)
            await syncHevy()

            lastSyncTime = Date()
            print("[AutoSync] Sync completed successfully")

        } catch {
            syncError = error.localizedDescription
            print("[AutoSync] Sync failed: \(error)")
        }

        isSyncing = false
    }

    private func syncHevy() async {
        do {
            // Call the server's Hevy sync endpoint
            _ = try await syncHevyToServer()
        } catch {
            // Hevy sync is optional - don't fail the whole sync
            print("[AutoSync] Hevy sync skipped: \(error)")
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
