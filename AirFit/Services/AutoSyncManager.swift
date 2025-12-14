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
        // Don't sync if we synced recently
        if let lastSync = lastSyncTime,
           Date().timeIntervalSince(lastSync) < minSyncInterval {
            print("[AutoSync] Skipping - synced recently")
            return
        }

        await performSync(modelContext: modelContext)
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
