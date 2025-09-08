# AirFit — Engineering Handoff Guide (Bulletproof)

Audience: New Codex/Claude agents joining mid‑stream. This is the single source of truth for how to build, test, validate, and contribute without breaking architecture.

## 1) TL;DR (Authoritative)
- Platform: iPhone 16 Pro only; iOS 26.0 only; Xcode 16 (beta) required
- Product scope: No live workout tracking or builder. Analysis only (HealthKit + external apps like Apple Workouts / HEVY)
- Guardrails (enforced in CI):
  - No NotificationCenter for chat; use `ChatStreamingStore` (typed events + metrics)
  - No SwiftData in UI/ViewModels; route via repositories/services
  - Single DI‑owned `ModelContainer`; do not instantiate ad‑hoc
  - All ViewModels `@MainActor`; no `try!`, `as!`, or force unwraps (CRITICAL=0)
- CI pipeline: `.github/workflows/ci.yml` — XcodeGen → SwiftLint (strict) → build (iOS 26.0) → unit tests → guards (fail on CRITICAL) → artifacts
- Coordination: `SupClaude.md` (CTO directives), `SupCodex.md` (team status)

## 2) One‑Time Setup
```bash
git clone <repo-url>
cd AirFit
xcodegen generate
open AirFit.xcodeproj
```

## 3) Build & Test Locally (iOS 26.0)
```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  swiftlint --strict --config AirFit/.swiftlint.yml

DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcodebuild clean build -scheme AirFit \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'

DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcodebuild test -scheme AirFit -testPlan AirFit-Unit \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'
```

## 4) Quality Guards (enforced)
```bash
./Scripts/ci-guards.sh                 # Architectural boundaries & hygiene
Scripts/validation/performance-benchmarks.sh  # Optional perf
```
Notes
- CRITICAL categories (force unwrap/try, ad‑hoc ModelContainer, SwiftData in UI, NotificationCenter in Chat/AI) fail CI.
- `ALLOW_GUARD_FAIL=1` may be set only with CTO approval (document in PR).
- Artifacts upload automatically in CI; attach summaries locally in PRs.

## 5) Project Structure (Authoritative)
- `AirFit/Core/` — DI, protocols, utilities, observability
- `AirFit/Data/` — SwiftData models and repositories
- `AirFit/Modules/` — Feature modules (AI, Chat, Dashboard, FoodTracking, Onboarding)
  - Note: Workout tracking UI is removed. Any residual files are legacy and should not be re‑enabled.
- `AirFit/Services/` — Business logic (AI, Health, Network, Persona)
- `Docs/` — Architecture, CI, development standards, status reports

Entry points (start here):
- DI: `AirFit/Core/DI/DIBootstrapper.swift`
- Chat streaming: `AirFit/Core/Protocols/ChatStreamingStore.swift`
- AI service: `AirFit/Services/AI/AIService.swift`
- Coach: `AirFit/Modules/AI/CoachEngine.swift`
- Context: `AirFit/Services/Context/ContextAssembler.swift`
- HealthKit: `AirFit/Services/Health/HealthKitManager.swift` (`HealthKitManaging` protocol)

## 6) Observability & Performance
- OSLog categories: ai, context, streaming (see `AirFit/Core/Observability/Signposts.swift`)
- Streaming adapter: `AirFit/Core/Observability/ChatStreamingMetricsAdapter.swift`
- Targets: TTFT < 300ms p50 / < 500ms p95; context < 500ms cold, < 10ms warm
 - Performance results: `Docs/Performance/RESULTS.md`
 - Capture (example):
   ```bash
   xcrun xctrace record --template "Time Profiler" \
     --device "iPhone 16 Pro" --output perf.trace --time-limit 60s
   xcrun xctrace export --input perf.trace --xpath '//signpost'
   ```

## 7) Branch & PR Workflow
- Branch naming: `claude/<task>` or `codex/<task>`
- Keep PRs small with a clear scope and QUALITY_GATES checklist
- Run local CI steps and paste guard summaries in PR body

## 8) Active Work & Ownership (Current)
- `SupClaude.md` — CTO directives (tasks, guardrails, merge order, anti‑reward‑hacking policy)
- `SupCodex.md` — Team status (validate claims; trust only after guard/test verification)
- Directional constraints:
  - No live workout tracking (analysis only). Use HealthKit summaries via `HealthKitManager` in `ContextAssembler`.
  - Do not re‑enable Workout repositories/services or `WorkoutSyncService`.
  - Do not alter CoachEngine public APIs without explicit approval.

## 9) Common Pitfalls (Read Carefully)
- Avoid introducing `ModelContainer()` in features; always resolve via DI
- Do not add SwiftData imports in `Modules/**/Views|ViewModels` — route via repositories
- Do not reintroduce NotificationCenter for streaming — extend ChatStreamingStore instead
- Keep ViewModels `@MainActor`; prefer Sendable models and actors
 - Do not reintroduce local workout tracking models/flows; analysis must come from HealthKit/external sources

## 10) Useful Docs & Locations
- CI Pipeline: `Docs/CI/PIPELINE.md`
- Environments: `Docs/Development-Standards/ENVIRONMENTS.md`
- Architecture Overview: `Docs/Development-Standards/ARCHITECTURE.md`
- Release Readiness: `Docs/Release/TestFlight-Readiness.md`
- Status Snapshots: `Docs/Codebase-Status/`
- Performance Results: `Docs/Performance/RESULTS.md`

## 11) Handoff Checklist (Attach to PRs)
- [ ] CI green (build + unit tests)
- [ ] SwiftLint strict passes
- [ ] `ci-guards.sh` shows zero (or reduced) violations; paste summary
- [ ] No SwiftData in UI/ViewModels
- [ ] No new `ModelContainer()`
- [ ] No force ops in app target
- [ ] Observability signposts intact (no spam)
 - [ ] No workout tracking code added; analysis flows via HealthKit only
 - [ ] For perf PRs: attach signpost evidence (xctrace/OSLog export)

## 12) Contact Points & Policy
- Coordination: open a note in `SupClaude.md` before merging cross‑cutting changes
- Performance budgets: see Signposts/targets above; negotiate in PR if variance is justified

Anti‑Reward‑Hacking (MANDATORY)
- No production code paths gated by test flags
- No weakening tests unless behavior truly changed (link to source diff + rationale)
- No timing hacks (sleep); use expectations/signposts/DI
- Do not bypass guardrails without CTO approval (`ALLOW_GUARD_FAIL=1`)
