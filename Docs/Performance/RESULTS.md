# AirFit Performance Validation Results

Date: 2025-09-07
Branch: main
Device: iPhone 16 Pro (iOS 26.0)

## Executive Summary

- R02 safety pass complete on main (0 CRITICAL guard violations)
- R06 framework validated; signposts are integrated; awaiting full device run for real TTFT/context numbers

## Build & Test Status (CI)

| Metric | Status |
|--------|--------|
| XcodeGen | ✅ |
| Build (iOS 26.0, Xcode‑beta) | ✅ in CI |
| Tests | ℹ️ As configured |
| Guardrails (critical) | ✅ 0 |

## Performance Metrics (to capture on device)

| Metric | Target | Status |
|--------|--------|--------|
| Time to First Token (TTFT) | < 300ms p50 / < 500ms p95 | Pending |
| Context Assembly | < 500ms cold / < 10ms warm | Pending |
| App Launch | < 1.0s | Pending |

## Signposts in Code

- Pipeline: `coach.parse`, `coach.context`, `coach.infer`, `coach.act`
- Streaming: `stream.start`, `stream.first_token`, `stream.delta`, `stream.complete`

Locations:
- `AirFit/Core/Observability/Signposts.swift`
- `AirFit/Modules/AI/CoachEngine.swift` (pipeline V2 signposted blocks)
- `AirFit/Services/AI/AIService.swift` (TTFT)

## How to Run (device/simulator)

```
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcodebuild build -scheme AirFit \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'

# Capture signposts (example)
xcrun xctrace record --template "Time Profiler" \
  --device "iPhone 16 Pro" --output perf.trace --time-limit 60s

# Export signposts
xcrun xctrace export --input perf.trace --xpath '//signpost'
```

## Artifacts

- `performance_validation.log` (root)
- `performance_results_*.json` (root)

