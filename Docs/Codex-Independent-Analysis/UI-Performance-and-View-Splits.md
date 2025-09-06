# UI Performance & View Splits

Large views to split:
- `Modules/Settings/Views/SettingsListView.swift:1` (~2266 loc)
- `Modules/AI/CoachEngine.swift:1` (~2112 loc) — not a view but monolithic engine; similar approach: orchestrator + strategies + helpers.
- `Modules/Workouts/Views/*`: Dashboard/Detail/Statistics/Builder 800–1100 loc.
- `Modules/Body/Views/BodyDashboardView.swift:1` (~1023 loc)
- `Modules/FoodTracking/Views/*` multiple files 700–1100 loc.

Patterns to apply:
- Extract subviews for logical sections (cards, lists, charts) with minimal bindings.
- Move heavy formatting/parsing/business to ViewModels or Services; Views should only compose.
- Use `@Query`/`FetchDescriptor` carefully: fetch in ViewModel when it’s non-trivial; pass results to Views.
- Avoid repeated `.task` fetching on navigation/tab switches; cache in ViewModel with explicit refresh triggers.
- Reuse shared components in `Core/Views` where possible; keep them small and generic.

Performance notes:
- `externalStorage` on large strings (chat content) is good; keep images/attachments off memory when possible.
- Limit gradient/heavy animations (FAB pulse) to moderate durations; respect `reduceMotion`.
- Ensure health dashboards amortize expensive computations (trends) and reuse cached snapshots from `ContextAssembler`.

