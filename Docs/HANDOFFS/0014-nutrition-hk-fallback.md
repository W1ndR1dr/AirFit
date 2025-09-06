# Handoff Packet — 0014 Nutrition Summary: HealthKit Fallback

Title: Use HealthKit nutrition totals when no local entries exist (Today rings)

Context:
- Today’s Macro Rings use `DashboardNutritionService.getTodaysSummary` based on local `FoodEntry` records.
- If the user logs meals via Apple Health (outside the app), rings can show 0 though HK has data.
- We already have `HealthKitManager.getNutritionData(for:)` that returns daily totals (kcal, protein, carbs, fat, fiber).

Goals (Exit Criteria):
- When there are zero local `FoodEntry` rows for today for the current user, fetch HK totals for today and populate `NutritionSummary` from HK.
- When there are one or more local entries, do NOT include HK values (avoid double counting; our entries may already be synced to HK).
- No persistence of HK totals into SwiftData; read-only fallback.
- No UI changes; Today Dashboard rings should reflect HK totals when applicable.

Constraints:
- iOS 18+, Swift 6 strict concurrency.
- Minimal diffs; keep logic inside `DashboardNutritionService` and DI bootstrap only.

Scope:
- AirFit/Modules/Dashboard/Services/DashboardNutritionService.swift
  - Inject optional `HealthKitManaging` (store as `healthKitManager: HealthKitManaging?`).
  - In `getTodaysSummary(for:)`: if `entries.isEmpty`, fetch HK totals via `healthKitManager?.getNutritionData(for: Date())`; build `NutritionSummary` from those values with the same dynamic targets, and `mealCount: 0`.
- AirFit/Core/DI/DIBootstrapper.swift
  - In `registerDataServices` or where `DashboardNutritionService` is registered, resolve `HealthKitManaging` and pass to the constructor.

Validation:
- Build succeeds and lints clean.
- Manually test: With no local entries today but HK nutrition present, Today rings show non-zero values; with local entries present, rings reflect only local data.

Risks & Rollback:
- Risk: Double counting if we accidentally combine HK + local. Mitigated by fallback only when `entries.isEmpty`.
- Rollback: Revert the service changes if any issues arise.

Return:
- One `apply_patch` block with diffs only for the two files above.
- Short manual test steps.

