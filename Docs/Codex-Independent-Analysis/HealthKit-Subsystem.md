# HealthKit Subsystem Deep-Dive

Components:
- `Services/Health/HealthKitManager.swift` (@MainActor): authorization, background delivery, observers, aggregate metrics, nutrition sums; internal helpers.
- `Services/Health/HealthKitSleepAnalyzer.swift` (actor): sleep session interpretation.
- `Services/Context/ContextAssembler.swift` (@MainActor): parallel fetch of activity/heart/body/sleep, in-memory TTL cache, progress reporting, partial-result behavior; joins subjective/app context.
- `Modules/...` dashboards and recovery leverage these services.

Strengths:
- Concurrency: careful division between main-isolated components and actor subsystems.
- Caching & perf: background delivery enabled for critical types; assembling work overlaps HealthKit queries; TTL cache avoids redundant queries.
- API design: pragmatic return of partial data even on failures; progress reporting for user feedback.

Concerns:
- Multiple ad-hoc `ModelContainer` creations inside `ContextAssembler` for trend calc/subjective data. This should reuse the app-level container/context.
- TODOs in HealthKitManager around mapping (workout types) and more nutrition metrics.
- Observer lifecycle stored in `observers[token]`—ensure tokens are invalidated on app lifecycle events.

Recommendations:
- Accept a `ModelContext` or a lightweight read-only repository via DI to eliminate container creation in `ContextAssembler`.
- Add integration tests using HealthKit fakes for aggregate queries and daily biometrics; pin day-by-day edge cases (DST, timezones, partial days).
- Wrap observer registration in a small `ObservationController` to unify start/stop and prevent leaks.

