# Handoff Packet — 0002 Macro Rings on Today View

Title: Replace Today dashboard placeholders with polished Macro Rings

Context:
- TodayDashboardView shows ring placeholders or relies on AI content for nutrition rings.
- We already have a polished `MacroRingsView` in `Modules/FoodTracking/Views/MacroRingsView.swift`.
- We want always-on, non-placeholder macro rings derived from local nutrition data.

Goals (Exit Criteria):
- Today view renders Macro Rings (no placeholders) regardless of AI content readiness.
- Uses real data from `DashboardViewModel.nutritionSummary` and targets; when loading, shows 0/of target (not skeletons).
- Clean animation and consistent styling with gradient system.

Constraints:
- iOS 18.4, Swift 6 strict concurrency, SwiftUI.
- Minimal diffs; reuse existing `MacroRingsView`.

Scope:
- Update `TodayDashboardView` to:
  - Add a `macroRingsSection()` that builds a `FoodNutritionSummary` from `nutritionSummary` and `nutritionTargets`.
  - Show Macro Rings near the top (after header), independently of AI content.
  - Remove ring placeholders/skeleton for macros.
- Leave other sections (quick actions, guidance) as-is.

Validation:
- Build succeeds.
- Launch app → Today tab: Macro Rings visible with 0/of target initially, then reflect entries when present.

Notes:
- Use `MacroRingsView(style: .full)` for a polished look.

Claude Prompt:
```
Implement Handoff 0002: Macro Rings on Today View.

Acceptance:
- Always show Macro Rings (no placeholders), sourced from DashboardViewModel’s nutrition summary.
- When VM not ready, show 0/of targets using NutritionTargets.default (not skeletons).
- Minimal diffs; reuse existing MacroRingsView.

Files:
- AirFit/Modules/Dashboard/Views/TodayDashboardView.swift
- AirFit/Modules/FoodTracking/Views/MacroRingsView.swift (already exists; do not modify)

Return:
- Patch diffs only for TodayDashboardView.swift.
- Short manual test steps.
```
