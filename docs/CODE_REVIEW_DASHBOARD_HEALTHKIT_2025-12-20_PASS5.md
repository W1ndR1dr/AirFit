# AirFit Dashboard + HealthKit Review (Pass 5) - 2025-12-20

## Scope
- Focused on the new HealthKit-driven dashboard updates in `AirFit/Views/` and `AirFit/Services/HealthKitManager.swift`.
- Reviewed new readiness/sleep/heart UI components and HealthKit data flows.

## Findings (ordered by severity)

### High
- **Potential crash when sleep stage data is missing (totalSleep == 0).** Several UI paths divide by `breakdown.totalSleep` and then cast to `Int`, which traps on `NaN`. This can happen when HealthKit only reports “in bed/awake” without stage data. Evidence: `AirFit/Views/Dashboard/SleepQualityCard.swift:119`, `AirFit/Views/Dashboard/SleepQualityCard.swift:201`, `AirFit/Views/MetricRow.swift:389`.

### Medium
- **Readiness baseline gating counts samples, not unique days.** `getBaselineProgress()` uses `count` of HRV/RHR samples rather than distinct days, so baseline can appear “ready” after ~7 days if multiple samples per day exist, violating the 14‑day minimum. Evidence: `AirFit/Services/ReadinessEngine.swift:164`.
- **Sleep charts can mislabel days when nights are missing.** Both `SleepQualityCard` and `SleepBreakdownView` assume contiguous data; if HealthKit returns fewer than 7 nights, labels and bars shift to the wrong days. Evidence: `AirFit/Views/Dashboard/SleepQualityCard.swift:226`, `AirFit/Views/Dashboard/SleepQualityCard.swift:322`, `AirFit/Views/MetricRow.swift:414`.
- **Dashboard sleep history does heavy HealthKit work for simple hours.** `loadSleepHistory()` calls `getDailySnapshot()` (which does multiple baseline/sleep queries) for each day even though only `sleepHours` are used. This adds unnecessary background work on dashboard load. Evidence: `AirFit/Views/DashboardView.swift:132`, `AirFit/Services/HealthKitManager.swift:380`.

### Low
- **New HealthKit cards are defined but not wired into the dashboard.** `HeartMetricsCard`, `SleepQualityCard`, `HRVTrendChart`, and `HRRecoveryChart` exist with previews but are not referenced in any view tree, so the HealthKit expansion may not be visible. Evidence: `AirFit/Views/Dashboard/HeartMetricsCard.swift:10`, `AirFit/Views/Dashboard/SleepQualityCard.swift:11`, `AirFit/Views/Dashboard/HRVTrendChart.swift:10`, `AirFit/Views/Dashboard/HRRecoveryChart.swift:10`.

## Testing Gaps
- No automated tests; recommended manual checks:
  - HealthKit sleep stages missing (in‑bed only) → ensure dashboard doesn’t crash and shows graceful fallback.
  - 7‑night sleep view with missing nights → verify date labels align with actual nights.
  - Readiness baseline: confirm it doesn’t unlock early with frequent HRV/RHR samples.
  - Dashboard load time with HealthKit disabled vs enabled.

## Notes
- This pass focuses strictly on HealthKit/dashboard changes; other worktree changes were not reviewed.
