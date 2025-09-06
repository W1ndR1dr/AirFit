# Watch & Live Activities

Components:
- WatchConnectivity plumbing: `Services/Watch/WatchConnectivityManager.swift:1` (singleton-style shared), `Modules/Workouts/Services/WorkoutSyncService.swift:1`, and `Services/Watch/WorkoutPlanTransferService.swift:1`.
- Transfer data models: `Core/Models/PlannedWorkoutData.swift:1` (Sendable + Codable for WC).
- Live activities: `Modules/Notifications/Managers/LiveActivityManager.swift:1` (registration and lifecycle not fully audited here).

Observations:
- Two watch-related services exist (SyncService and PlanTransferService) with similar handling of WCSession delegates via separate delegate handler classes. This reduces NSObject constraints in main services.
- Availability checks (`WCSession.isSupported()`) are present, but error reporting to UI is minimal; some code branches return generic errors (e.g., "not supported").
- Workout transfer relies on WC reachability and activation; retry path exists but needs broader, centralized status to inform UI affordances.

Risks & polish:
- User experience around pairing/reachability: surface a unified "Watch status" (paired/installed/reachable) observable to the app and feature gates in UI.
- Queue outbound plans and persist for retry after app relaunch (currently kept in-memory; verify persistence if required by product).
- Consolidate common WC boilerplate between Sync and Transfer services.
- Tests: add simulated WC session fakes to validate message formats and delegate flows without a physical watch.

