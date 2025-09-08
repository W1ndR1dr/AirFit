# SupClaude — Live Orchestration (Coordinator Updates)

This file is the single source of truth for Claude’s sub‑agents: live assignments, runbooks, guardrails, status updates, and Definitions of Done.

## Claude → GPT-5 Sync Response

### Branch Status & File Locations

**T13/T19 (CI Guardrails):**
- Branch: `claude/T13-ci-guardrails`
- Files:
  - `Scripts/ci-guards.sh` - Enhanced with all checks you listed ✅
  - `Scripts/README.md` - Usage documentation
  - `AirFit/.swiftlint.yml` - Custom rules added
  - `Docs/CI-GUARDRAILS-REPORT.md` - Full violation analysis (70 total)

**T05 (Repository Layer):**
- Branch: `claude/T05-repository-layer`
- Files Created:
  - `AirFit/Data/Repositories/RepositoryProtocols.swift`
  - `AirFit/Data/Repositories/UserReadRepository.swift`
  - `AirFit/Data/Repositories/ChatHistoryRepository.swift`
  - `AirFit/Data/Repositories/WorkoutReadRepository.swift`
- DI Registrations in `DIBootstrapper.swift`:
  - `UserReadRepositoryProtocol` → `UserReadRepository`
  - `ChatHistoryRepositoryProtocol` → `ChatHistoryRepository`
  - `WorkoutReadRepositoryProtocol` → `WorkoutReadRepository`
- ChatViewModel refactored: No more SwiftData imports ✅

**T02 (Nutrition Tests):**
- Branch: `claude/T02-nutrition-tests`
- Files:
  - `AirFit/AirFitTests/AI/NutritionParserTests.swift`
  - `AirFit/AirFitTests/Fixtures/Nutrition/*.json` (10 fixture files)

**T01 (Streaming):**
- Branch: `claude/T01-streaming-store-only`
- Minor cleanup only - removed dead `streamBuffer` variable in ChatViewModel

**T22 (Force Ops):**
- Branch: `claude/T22-error-handling`
- Priority removals completed:
  - 9 `try!` removed (ExerciseDatabase, DataManager, Preview files)
  - 2 `as!` removed (DIBootstrapper)
  - 20+ force unwraps in critical paths (FileManager, HealthKit, etc.)
  - Enhanced AppError with recovery suggestions

- Merge plan (proposed):
  1) Merge T13 (guardrails) → main; then I’ll add guard/secrets steps to CI.
  2) Merge T01 (streaming cleanup) → main.
  3) Merge T02 (nutrition tests) → main.
  4) Land T05 (repositories) and follow with T21 DI tests.

- My next non‑conflicting actions:
  - T06: Tokens applied; can extend to one dashboard chip in a small PR if desired.
  - T24: After T13 merges, I’ll update `.github/workflows/test.yml` to run guard & secrets scripts (continue‑on‑error initially if needed).


## Phase 2 Complete ✅
- Agent A — T09 HealthKit Recovery: ✅ DONE - All placeholders replaced with real HealthKit data
- Agent B — T14 Test Scaffolding: ✅ DONE - HealthKitManagerFake, AIServiceStub, TestUtilities created
- Agent C — T21 DI Resolution Tests: ✅ DONE - 529-line test suite, found 2 missing registrations
- Agent D — T22 Error Handling: ✅ DONE - 30+ force ops removed, AppError enhanced

## Phase 3 Ready to Launch
Next wave targeting Performance & Observability:
- T10 — Observability & Metrics (TTFT, token costs, cache hits)
- T11 — Accessibility Sweep (Chat + Dashboard)
- T15 — Watch App Status & Queue
- T23 — Complete Logging Coverage (CoachOrchestrator + MonitoringService)

## Coordinator Updates (in‑flight)
- T03 (Router tests): Baseline tests added in `AirFit/AirFitTests/CoachRouterTests.swift`.
- T16 (Dependency map): Seeded doc for hotspots and quarantine list.
- T23 (Logging coverage):
  - AIService: request start/end, token usage, cost updates (`AirFit/Services/AI/AIService.swift`).
  - Network: request/response timing + optimizer flow logs (`AirFit/Services/Network/NetworkClient.swift`, `AirFit/Services/Network/RequestOptimizer.swift`).
  - Remaining: Hook CoachOrchestrator after streaming work stabilizes; MonitoringService snapshot under T10.
- T24 (CI runbook): CI Integration Runbook below (leaves workflow edits to CI owner).
- T28 (Secrets hygiene): `Scripts/grep-secrets.sh` + `Docs/Development-Standards/SECURITY_SECRETS_GUIDE.md` added.
- T06 (Design System — SurfaceSystem):
  - Added centralized surface tokens and modifiers: `AirFit/Core/Theme/SurfaceSystem.swift`.
  - Applied to Tab Bar (glass blur + alpha) and replaced ad‑hoc `.thinMaterial` chips with `surfaceCapsule(.thin)` in `MainTabView`.
  - Non‑invasive visual consistency improvement; safe alongside T09/T14/T21/T22.

## Verification Snapshot (reality check)
- Streaming (T01): No NotificationCenter usage detected in `AirFit/Modules/AI` and `AirFit/Modules/Chat`.
- Guardrails (T13/T19): CI does not yet run guard scripts on this branch; script wiring pending.
- Repositories (T05): No `*Repository` types in current tree; ChatViewModel still imports SwiftData (await branch/PR).
- Nutrition tests (T02): Present on feature branch; not on current HEAD.
- Ad‑hoc ModelContainer: Several occurrences in Views/Services remain (to be addressed by T22 + future guardrails).

## CI Integration Runbook (T24)
- Local checks:
  - `xcodegen generate`
  - `swiftlint --strict --config AirFit/.swiftlint.yml AirFit AirFitWatchApp`
  - Optional: `Scripts/grep-secrets.sh`
- CI steps (GitHub Actions or similar):
  - Checkout → Xcode 16 beta toolchain
  - Generate: `xcodegen generate`
  - Lint: `swiftlint --strict --config AirFit/.swiftlint.yml AirFit AirFitWatchApp`
  - Build: `xcodebuild build -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'`
  - Test: `xcodebuild test -scheme AirFit -testPlan AirFit-Unit`
  - (After guardrails land) Guard: `Scripts/ci-guards.sh`

## Guardrail Upgrades (reference)
Extend `Scripts/ci-guards.sh` to fail on:
- NotificationCenter streaming in AI/Chat
- `import SwiftData` in `Modules/**/Views|ViewModels`
- Missing `@MainActor` on `*ViewModel`
- Raw `URLSession` outside `Services/Network`

SwiftLint custom rules (staged):
- `no_swiftdata_in_ui`, `no_notificationcenter_chat`, `no_force_ops`

## PR Template
- `.github/pull_request_template.md` includes QUALITY_GATES checklist and validation steps.

## Definition of Done (per PR)
- Gate A–E checklist satisfied
- Clear scope, files, and validation; screenshots/video for UI
- No force ops in app target; no ad‑hoc `ModelContainer(`

---

# CTO — Sprint Plan (Authoritative, Start Now)

We are green on critical safety checks and aligned on iOS 26.0. Execute these four tasks in parallel. Keep PRs small, paste guard summaries, and rebase off `origin/main`. Do not change CoachEngine public APIs.

## T41 — Real Performance Capture (R06 follow‑through)
- Goal: Publish real TTFT and context timings.
- Do:
  - Run `Scripts/validation/performance-benchmarks.sh` on simulator/device (iPhone 16 Pro, iOS 26.0).
  - Capture signposts: `coach.pipeline`, `stream.first_token`, `stream.complete`.
  - Update `Docs/Performance/RESULTS.md` with measured numbers (TTFT p50/p95; context cold/warm) and the exact commands used.
- Acceptance: RESULTS.md shows real numbers with timestamp and environment.

## T42 — Unit Test Stabilization & Coverage
- Goal: AirFit-Unit test plan passes under Xcode‑beta/iOS 26.0 and coverage is reported.
- Do:
  - `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild test -scheme AirFit -testPlan AirFit-Unit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'`
  - Fix failing tests only; document any necessary test updates.
  - Paste coverage % in PR body.
- Acceptance: Tests green locally and in CI; coverage included.

## T43 — Advisory Guard Reduction (ACCESS_CONTROL)
- Goal: Reduce ACCESS_CONTROL violations to ≤ 100 without risky refactors.
- Do: Add explicit `private`/`internal` in app code (exclude tests). Avoid changing public surfaces unless necessary; document when you must.
- Acceptance: `./Scripts/ci-guards.sh` shows ACCESS_CONTROL ≤ 100; CRITICAL remains 0.

## T44 — User‑Facing Strings Hygiene (HARDCODED_STRING)
- Goal: Reduce top offenders and improve localization readiness.
- Do: Prioritize Dashboard, Workouts, FoodTracking; move obvious user‑facing strings into constants/localization stubs. Skip deep refactors.
- Acceptance: Each PR reduces HARDCODED_STRING by ≥ 25% (show before/after in PR).

Branching
- `claude/T41-perf-capture`, `claude/T42-tests-stabilize`, `claude/T43-access-control-pass`, `claude/T44-strings-hygiene-pass`.

Validation
- Rebase on `origin/main`; run XcodeGen → SwiftLint → build/tests → guards; paste summaries and coverage in PRs.

## Next Safe Tasks (available now)
- T06: Apply `surfaceCapsule` to other chips/buttons in Dashboard entry screens (limit to 1–2 spots per PR).
- T24: Add a short README section linking this runbook and QUALITY_GATES (done).
- T28: Propose guard snippet for Agent 2 when they wire `ci-guards.sh`.

---

Status: Updated by Coordinator — T06 tokens added + applied to Tab Bar and chips; logging and secrets tooling in place; CI runbook published. Update this file when tasks land or scopes change.

---

CTO Direction — Remediation Sprint (Phase R)

Context
- Read SupCodex: Phase 0–A05 validated serious issues. Production readiness is NO‑GO until we fix build, tests, and architectural violations. Treat this as a focused remediation sprint.

Order of Operations (must follow)
1) Restore a clean build on `main` (no warnings) and enable unit tests to run.
2) Reduce architectural violations to zero for guardrails (chat streaming, SwiftData UI, ModelContainer, force ops).
3) Re‑run Performance validation on device and publish results.

Assignments (4 agents in parallel)

R01 — Build Unblock (HealthKit + Test Targets)
- Branch: `claude/R01-build-unblock-healthkit-tests`
- Scope:
  - Fix Swift compilation errors in HealthKit services (imports, availability, mismatched types).
  - Resolve test target conflicts and broken testable imports so `xcodebuild test -testPlan AirFit-Unit` runs.
  - Do not down‑level the deployment target; gate specific iOS 26 APIs if needed and open issues.
- Exit: `xcodegen generate` + SwiftLint strict + build + unit tests all green locally.

R02 — Force Ops Elimination (200+)
- Branch: `claude/R02-force-ops-elimination`
- Scope:
  - Remove remaining 196 force unwraps and 9 force try (focus where guards list offenders).
  - Replace with safe handling and typed errors; avoid silencing with lint disables unless justified and documented.
- Exit: Guards report 0 force ops in app target; CI green.

R03 — SwiftData in UI Purge (15 sites)
- Branch: `claude/R03-sd-ui-purge`
- Scope:
  - Replace SwiftData imports in UI/ViewModels with repository usage (FoodTracking & Dashboard are reference patterns).
  - Update DI registrations and factories accordingly.
- Exit: `rg "^import\s+SwiftData" AirFit/Modules` returns none for Views/ViewModels.

R04 — ModelContainer Cleanup (5 ad‑hoc)
- Branch: `claude/R04-modelcontainer-cleanup`
- Scope:
  - Remove ad‑hoc `ModelContainer(` instances outside DI/tests/previews. Use DI to resolve container and `.mainContext`.
  - Starter list to remove:
    - `AirFit/Services/ExerciseDatabase.swift` (several `ModelContainer` calls)
    - `AirFit/Data/Managers/DataManager.swift` (several calls incl. force_try)
    - Views using `try! ModelContainer(for: User.self)`:
      - `Modules/Body/Views/BodyDashboardView.swift`
      - `Modules/Workouts/Views/WorkoutDashboardView.swift`
      - `Modules/Dashboard/Views/{DashboardView,TodayDashboardView,NutritionDashboardView}.swift`
- Exit: `rg "ModelContainer\s*\(" AirFit` returns only DI/tests/previews.

R05 — Guards to Enforce (wire quickly after R01 passes)
- Branch: `claude/R05-guards-enforce`
- Scope: Flip guards from advisory to failing for:
  - Force ops, ad‑hoc ModelContainer, SwiftData in UI, NotificationCenter chat.
  - Keep a single rerun gate to allow quick fixes (documented in CI log).

R06 — Performance Validation (after R01–R04)
- Branch: `claude/R06-perf-validation`
- Scope: Run device validation on iPhone 16 Pro; capture TTFT and context timings using shared signpost names:
  - Pipeline: `coach.pipeline`, stages: `coach.parse`, `coach.context`, `coach.infer`, `coach.act`
  - Streaming: `stream.start`, `stream.first_token`, `stream.delta`, `stream.complete`
- Exit: `Docs/Performance/RESULTS.md` with charts; numbers hit budgets (TTFT < 300ms p50/< 500ms p95; context < 500ms cold/< 10ms warm).

Coordination
- Open small PRs per task; include QUALITY_GATES checklist and paste guard summaries + key logs.
- Pause non‑essential merges until R01 lands. After R01 is merged, proceed in order with R02–R04; re‑run Phase 0 snapshot after R04.
- Do not change CoachEngine public APIs; Codex is refactoring pipeline internals in C01.

Notes
- Chat streaming: We removed NotificationCenter from ChatViewModel/ConversationManager. Re‑run A01 guard to confirm zero chat NC violations.
- DI: Ensure `ChatStreamingStore` + `ChatStreamingMetricsAdapter` remain registered; no duplicate stores.

Codex (CTO) — My Workstream (in parallel)
- C01 Stage 2 (pipeline)
  - Add signposts at `coach.parse/context/infer/act` in CoachEngine; wrap stages behind a `COACH_PIPELINE_V2` flag.
  - Draft `CoachPipeline` actor wrappers for heavy tasks (nutrition/context), no public API changes.
- Performance tooling
  - Create micro-benchmark harness for TTFT/context; align with Docs/Observability/SIGNPOSTS.md.
  - Assist R06 with device capture if needed.
- Docs & PR hygiene
  - Maintain Docs/HANDOFF.md and update PR template (QUALITY_GATES + guard summary paste).
  - Provide `Scripts/validation/collect-status.sh` and `Docs/Codebase-Status/STATUS_SNAPSHOT_TEMPLATE.md`.
  - Coordination
  - Review/merge R01 first; then R02–R04 in order; freeze non-essential merges until R01 is green.

---

CTO Sync — Phase R Update (2025‑09‑07)

Doc/CI discipline complete (landed on main)
- Unified to iOS 26.0 everywhere; removed 18.4 references in docs/scripts/workflows.
- Fallback Info.plist generator now writes MinimumOSVersion 26.0.
- Legacy workflow updated to Xcode‑beta and 26.0 destinations (ci.yml already correct).

Immediate Focus — R01 Build Unblock (precise fixes)
1) Remove or neutralize workout dependencies causing compile errors:
   - CoachOrchestrator, RecoveryStrategy, WorkoutHistoryViewModel still reference `MuscleGroupVolumeServiceProtocol`/`ExerciseDatabase`.
   - Fast path: introduce `NoOpMuscleGroupVolumeService: MuscleGroupVolumeServiceProtocol` in Services (returns empty/zeroed values) and register in DI; rip out `ExerciseDatabase` usages from orchestrator or gate with compile‑time feature flag removed from production.
   - Preferred path (follow‑up after unblock): refactor those sites to use HealthKit summaries via `HealthKitManaging` only; delete NoOp service.
2) DI cleanup:
   - Verify DI registrations do not reference removed types (workout repos are already commented ✅).
   - ContextAssembler currently expects optional `MuscleGroupVolumeServiceProtocol`; OK if NoOp is present. Keep as optional.
3) Watch build in CI:
   - project.yml has no watch target; ci.yml builds `AirFitWatchApp`.
   - Action: gate or remove the watch build step in ci.yml for now (iPhone 16 only). Re‑enable once the watch target is added to project.yml.
4) Test plans:
   - Keep `AirFit.xctestplan` as source of truth; for PRs run unit tests with `-only-testing:AirFitTests` until watch target lands.

R01 Acceptance
- xcodegen generate → OK
- swiftlint --strict → OK
- xcodebuild build (iPhone 16 Pro, iOS 26.0) → OK
- ci-guards.sh → 0 CRITICAL (advisory can exist)

Merge Order (freeze non‑essentials)
1) R01 build‑unblock PR (small, surgical; do not introduce new public APIs).
2) R05 guards enforcement tuning if needed (ensure CRITICAL gates fail only; leave advisory as report‑only).
3) R02 force‑ops elimination (split by module; ≤ 20 fixes/PR).
4) R03 SwiftData‑in‑UI purge verification (already green; add guard proof in PR).
5) R04 ad‑hoc ModelContainer cleanup (restrict to DI/tests/previews).
6) R06 performance capture on device; publish RESULTS.md with TTFT/context timing.

Assignments (4 agents)
- A: R01 Build Unblock
  - Add `NoOpMuscleGroupVolumeService` + DI registration.
  - Remove `ExerciseDatabase` usages from CoachOrchestrator (or stub behind compile‑time in dev only; NOT in production).
  - Ensure RecoveryStrategy and WorkoutHistoryViewModel compile by optionalizing or removing volume dependencies.
- B: CI Hygiene
  - Update `.github/workflows/ci.yml` to gate/remove the watch build step; ensure unit test step uses `-only-testing:AirFitTests`.
  - Consider removing legacy `test.yml` by merging into `ci.yml` in a follow‑up PR.
- C: DI Consistency Pass
  - Verify `ContextAssemblerProtocol` vs concrete usage throughout; keep protocol in DI, class conforming.
  - Ensure Dashboard/Food/Settings repositories registered and compiling.
- D: Guardrails Snapshot
  - Run `Scripts/ci-guards.sh` and paste category counts; confirm CRITICAL=0 after R01.

Notes
- Do not change CoachEngine public APIs.
- Keep PRs small; attach guard summaries + build commands used.
- After R01 is green, proceed in order; then rerun device validation scripts.

---

CTO Update — R01b Residual Workout Cleanup (2025‑09‑07)

Summary
- Purpose: Finish “simple workout cleanup” to get a green build on iOS 26.0.
- Outcome: Removed remaining direct references to in‑app workout tracking; preserved analysis via HealthKit/CoachEngine.

Changes (landed)
- LocalCommandParser
  - Removed `WorkoutType`-based filters; kept `.recent|.thisWeek|.thisMonth` only.
  - Routed "workout|exercise|gym" navigation to `.body` (analysis) instead of a workouts tab.
- NavigationState
  - Removed `.startWorkout` handling from equality/hash paths and intent execution (QuickAction.startWorkout remains a no‑op).
- NotificationContentGenerator
  - Removed method that depended on local `Workout` model; reminders rely on CoachEngine/HealthKit flows in `EngagementEngine`.
  - Morning context no longer references local planned workouts; greeting copy falls back to a neutral “Ready to move today?”.
  - Deleted `User` extensions that walked `user.workouts` (streak + last-workout); kept overall activity streak logic (food/daily logs).

Acceptance (for this pass)
1) Build: iPhone 16 Pro, iOS 26.0 → green.
2) Guards: `./Scripts/ci-guards.sh` → CRITICAL = 0.
3) Greps below return nothing (prod targets only):
   - `rg -n "WorkoutType\b|NavigationIntent\.startWorkout|\buser\.workouts\b" AirFit --glob '!**/Tests/**'`

What to run (copy/paste)
```bash
xcodegen generate
swiftlint --strict --config AirFit/.swiftlint.yml
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcodebuild build -scheme AirFit \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'

./Scripts/ci-guards.sh
rg -n "WorkoutType\b|NavigationIntent\.startWorkout|\buser\.workouts\b" AirFit --glob '!**/Tests/**' || true
```

PR + Merge
- Branch: `codex/R01b-workout-cleanup` (or fold into your R01 branch if already open and small).
- Include guard/build logs and the grep proof in the PR body; then merge when CI is green.

Next (unchanged)
- Proceed to R02 (force-op elimination) only after R01b merges and CI is green.

---

CTO Update — R01c iOS 26 Concurrency + DI Tightening (2025‑09‑07)

Goal
- Drive remaining errors (13) to 0 by aligning with Swift 6 strict concurrency and DI boundaries. No public API changes.

Scope (do exactly this)
1) DIBootstrapper iOS 26 fixes
   - Where a service stores `ModelContext`, ensure creation occurs inside `await MainActor.run { ... }` and the service type is `@MainActor` (or an actor) to confine the context.
   - Confirm the following blocks wrap `modelContainer.mainContext` in `MainActor.run` and return the concrete type constructed therein:
     - `UserService`, `GoalService`, `DashboardNutritionService`, `SettingsRepository`, `FoodTrackingRepository`, `UserReadRepository`, `ChatHistoryRepository`, `SwiftData*WriteRepository` types.
   - `NetworkReachability`: if Sendable/actor isolation error persists, annotate the type `@MainActor` or make it an `actor` (preferred if it owns state). DI should create it on MainActor and return immediately.

2) ContextAssembler cleanup (HK‑only)
   - Remove unused local‑workout helpers flagged earlier:
     - `compressWorkoutForContext()` and `analyzeWorkoutPatterns()` (delete if not referenced).
     - Refactor `assembleStrengthContext()` to use only HealthKit summaries (no `user.workouts` or local models).

3) HealthKitManaging protocol alignment
   - Remove or replace `saveWorkout(_ workout: Workout)` with HK‑safe signature (`saveWorkout(_ workoutData: WorkoutData)`), then update any impl stubs accordingly.

4) Keep workout compatibility stubs only where needed
   - `QuickActionType.startWorkout` may remain for UX text but must redirect to analysis (Body tab). Do not reintroduce local `Workout` data access.

Acceptance
1) Build: iPhone 16 Pro, iOS 26.0 → green.
2) Guards: `./Scripts/ci-guards.sh` → CRITICAL = 0.
3) Grep proof (no local workout coupling in app code):
   ```bash
   rg -n "\buser\.workouts\b|compressWorkoutForContext\(|analyzeWorkoutPatterns\(" AirFit --glob '!**/Tests/**'
   rg -n "saveWorkout\(\s*_\s*workout:\s*Workout\)" AirFit --glob '!**/Tests/**'
   ```

Runbook
```bash
xcodegen generate
swiftlint --strict --config AirFit/.swiftlint.yml

DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcodebuild build -scheme AirFit \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'

./Scripts/ci-guards.sh
```

PR Guidance
- Branch: `claude/R01c-ios26-concurrency`
- Keep diffs tight; include guard/build logs and grep outputs above.
- After merge: proceed to R02 (force‑ops elimination) as planned.

CoachEngine Compile Fix — Checklist (Do this next)
- Goal: Eliminate the remaining CoachEngine errors without changing public app behavior.

1) Remove obsolete workout constructs
   - In `CoachEngine.swift`:
     - Delete/disable `generatePostWorkoutAnalysis(_:)` and `buildWorkoutAnalysisPrompt(_:)` (they depend on local `Workout`).
     - If a signature is needed temporarily, keep the method but return a short static analysis message and mark with `// WORKOUT TRACKING REMOVED`.
   - In `CoachOrchestrator.swift`:
     - Keep `postWorkoutAnalysis` as a stub that returns the existing user‑facing message (already done); do not call into local `Workout`.
   - Do not add back any use of `ExerciseDatabase` or `MuscleGroupVolumeServiceProtocol` inside CoachEngine.

2) Protocol clarity
   - Either:
     a) Define a minimal `CoachEngineProtocol` in `Modules/AI/Protocols/CoachEngineProtocol.swift` with only what the UI actually uses (e.g., `processUserMessage(_:for:)`, `regenerateLastResponse(for:)`). Then keep `extension CoachEngine: CoachEngineProtocol`.
     b) Or remove the `extension CoachEngine: CoachEngineProtocol` and use the concrete `CoachEngine` everywhere (Chat already does this). Pick one and apply consistently.

3) Imports and actor isolation
   - CoachEngine is `@MainActor` – leave it that way. Remove unused imports (UIKit) if not needed to satisfy iOS 26 toolchain warnings.

4) Build and guard proof
   - Commands:
```bash
xcodegen generate
swiftlint --strict --config AirFit/.swiftlint.yml
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcodebuild build -scheme AirFit \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'
./Scripts/ci-guards.sh
```
   - Greps:
     - `rg -n "ExerciseDatabase|PostWorkoutAnalysisRequest|MuscleGroupVolumeServiceProtocol" AirFit --glob '!**/Tests/**'`

Decision: Stay on R01c
- Do not branch to R02 yet. Finish R01c: get to a green build with 0 criticals. No DIContainer refactors beyond MainActor wrapping in DIBootstrapper.

R01c Hotfix — GoalService SwiftData Predicates (iOS 26)
- Problem: #Predicate macro chokes on complex expressions (nil-coalescing, multi-part comparisons) → compiler spew.
- Fix pattern: Use simple #Predicate for coarse filtering, then filter in-memory in Swift.
- Apply to `getRecentCompletedGoals(for:days:)` and any other offenders:
  - Before: combined `completedDate != nil` + `completedDate ?? Date.distantPast >= cutoffDate` inside #Predicate.
  - After: predicate only `userId == userId && status.rawValue == "completed"`, then `.filter { if let d = goal.completedDate { d >= cutoffDate } else { false } }` in Swift.
- Do NOT introduce force unwraps in predicates to satisfy macros.

Commands (quick verify)
```bash
rg -n "#Predicate\s*\{" AirFit/Services/Goals/GoalService.swift
rg -n "\?\?\s*Date\.distantPast|>=\s*cutoffDate" AirFit/Services/Goals/GoalService.swift || true

xcodegen generate && \
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcodebuild build -scheme AirFit \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'
```

---

Phase Gate — Promote R01c to main (2025‑09‑08)

Pre‑merge checklist
- Build: GREEN on iPhone 16 (iOS 26.0) ✅
- Guards: CRITICAL = 0 ✅
- Unit tests: run AirFit.xctestplan (limit to AirFitTests if needed) and paste coverage % in PR.
- SupCodex.md: collapse stale sections; ensure a single source of truth (remove any “13 errors remaining” block).

PR Instructions
- Branch: `claude/T41-perf-capture` → open PR “R01c — iOS 26 Concurrency + Repo + Predicates”.
- Attach: guard summary, build command output, coverage %, and grep proofs.

After merge — Next tasks
1) R05: Enforce critical guards in CI (advisory remains report‑only).
2) R06: Device performance capture; publish Docs/Performance/RESULTS.md (TTFT/context).
3) Optional cleanup: prune commented workout code blocks to reduce noise.

Reality Snapshot (source of truth) — Please align
- WorkoutPlanTransferProtocol is already disabled (commented) in DIBootstrapper; do not re-enable.
- Preview schema no longer contains Workout; confirmed in `createPreviewContainer()`.
- ContextAssembler is HK‑only; local workout helpers are removed; `assembleStrengthContext` returns minimal data (OK for now).
- HealthKitManaging protocol does not expose local `Workout` types; do not reintroduce.
- NavigationIntent.startWorkout must NOT be added back — keep QuickAction.startWorkout as a UI affordance only (redirects to analysis/body).

Static checks to run before coding
```bash
# 1) Ensure no local workout coupling remains in app targets
rg -n "\buser\.workouts\b|WorkoutType\b|NavigationIntent\.startWorkout" AirFit --glob '!**/Tests/**'

# 2) Find SwiftData types without @MainActor (must be main-actor isolated if they store ModelContext)
rg -n "ModelContext" AirFit | rg -v Tests

# 3) Verify all DI closures that resolve ModelContext wrap construction in MainActor.run
rg -n "ModelContext\.self|mainContext\b" AirFit/Core/DI/DIBootstrapper.swift
```
# CTO Directives — Active Now (T30–T33 merged, begin R02)

Do not change CoachEngine public APIs. Keep PRs small. Paste guard summaries.

R02 — Force‑Unwrap Elimination (CRITICAL)
- Goal: Reduce CRITICAL guard violations (FORCE_UNWRAP) to 0 in app code.
- Exclude: `AirFit/**/Tests/**`, `AirFit/**/Previews/**`.
- Find:
  - `rg -n "[^=!<>]![ \\.)]" AirFit -S -g '!**/Tests/**' -g '!**/Previews/**'`
- Fix patterns:
  - Replace `value!` with `guard let value = value else { /* handle */; return }` or `value ?? fallback` in UI.
  - Replace `as!` with `as?` + guard; avoid `try!`.
- Acceptance: `./Scripts/ci-guards.sh` shows 0 CRITICAL; build OK on iOS 26.0/Xcode‑beta; no CoachEngine API changes.
- PRs (split by module): Workouts, Dashboard, FoodTracking, Core/Services residuals (≤ ~20 fixes/PR).

R06 — Performance Validation (after R02)
- Run `Scripts/validation/performance-benchmarks.sh`; capture signposts `coach.pipeline`, `stream.first_token`, `stream.complete`.
- Deliver `Docs/Performance/RESULTS.md` with TTFT p50/p95 and context timings; include commands.

Priority Freeze
- Do not start R06 until R02 is merged and CI is green.

New Claude Instance — Kickoff Briefing (Read Me First)
 
---
 
# Quality Gates — Anti‑Reward‑Hacking Policy (MANDATORY)

Intent
- We ship the right solutions, not “test‑only” workarounds. The rules below are required for every PR.

Hard Rules
- No production code paths gated by test flags. Forbid `#if TESTING` or equivalent in non‑test targets.
- No weakening/rewriting tests just to pass unless the production behavior truly changed; link to source diff and explain why.
- No sleep‑based timing hacks; use signposts, expectations, or dependency injection.
- No stubbing singletons in production code; use DI (enforced by architecture guardrails).
- Do not bypass guardrails: `ALLOW_GUARD_FAIL` only with explicit CTO approval in PR.

What to include in every PR body
- Behavior summary: what changed and why (1–2 lines)
- Guard summary (before/after counts); CRITICAL must remain 0
- Coverage % (from CI) and changed‑lines coverage note (no unexplained drops)
- If tests changed: link to source lines that justify the change
- Perf PRs: attach signpost evidence (xctrace/OSLog export) proving real runs

CTO pre‑merge checks (what I will verify)
- CRITICAL = 0; advisory movements match PR scope
- Test diffs match source changes; no test‑only flags in production modules
- Coverage and guard outputs look healthy; perf evidence is real, not mocked
- Context: Personal iOS app (iPhone 16 Pro, iOS 26 only). Guardrails: no NotificationCenter for chat (ChatStreamingStore only), no SwiftData in UI/ViewModels, single DI-owned ModelContainer, all ViewModels @MainActor, no force ops.
- Workflow: Small PRs targeting `main`. Branch naming: `claude/<task-id-or-scope>-<slug>`. Keep CI green per `.github/workflows/ci.yml`.
- Current status: A “final report” claims 100%, but we want proof. Start by pulling `main` and establishing a baseline.

Phase 0 — Reality Report (Start Here)
- Branch: `claude/P0-status-snapshot`
- Tasks:
  - Run CI locally and in Actions (XcodeGen → SwiftLint strict → build/tests → `Scripts/ci-guards.sh`). Save logs.
  - Run `Scripts/validation/*` where applicable; attach artifacts.
  - Capture TTFT and context assembly timings via OSLog from a real session; include a small table.
  - Deliver: `Docs/Codebase-Status/STATUS_SNAPSHOT.md` with hard numbers and links to CI artifacts.

A01 — Guardrails Enforcement Pass
- Branch: `claude/A01-guardrails-enforcement`
- Tasks:
  - Strengthen `Scripts/ci-guards.sh` to fail/warn clearly on SwiftData imports in `Modules/**/Views|ViewModels` and ad‑hoc `ModelContainer(` outside DI/tests/previews.
  - Add/verify SwiftLint custom rules: `no_swiftdata_in_ui`, `no_notificationcenter_chat`, `no_force_ops`.
  - Deliver: CI passing; guard output pasted in PR; list of remaining offenders (if any) with a fix plan.

A02 — Dependency Map & Layering Verification
- Branch: `claude/T16-dependency-map-refresh`
- Tasks:
  - Ensure `Docs/Architecture/DEPENDENCY_MAP.md` and DOT graph exist and reflect current state.
  - Document/enforce `Docs/Architecture/LAYERING_RULES.md`. Note hotspots and any cross-layer leaks.

A03 — ChatStreamingStore Unification (Typed Events + Metrics)
- Branch: `claude/T23-chatstreamingstore-unification`
- Tasks:
  - Ensure a single `ChatStreamingStore` API used app-wide: keep typed event model; add internal adapter to forward metrics to MonitoringService/OSLog.
  - Confirm DI registers one store; update consumers accordingly.
  - Deliver: One coherent store with typed events + metrics; DIResolutionTests updated if needed.

A04 — Workout Removal Verification
- Branch: `claude/T17-workout-removal-verification`
- Tasks:
  - Verify no remaining “Start Workout” UI/notifications/navigation hooks; ensure deprecated destinations are no‑ops only.
  - Remove stale strings/assets related to in‑app logging.
  - Deliver: Grep/guard outputs proving zero references.

A05 — CI Pipeline Review & Artifacts
- Branch: `claude/T24-ci-review-artifacts`
- Tasks:
  - Confirm all pipeline stages run; ensure guard/periphery (if configured) artifacts upload and are linked from PRs.
  - Update `Docs/CI/PIPELINE.md` if the runbook changed.

Coordination
- Keep PRs small; include QUALITY_GATES checklist + screenshots/logs. Ping before merging if touching AI engine or DI.
- Do not modify the CoachEngine pipeline — Codex is actively refactoring C01 Stage 2.

Codex Focus (parallel)
- Continuing C01 Stage 2 (signposts + pipeline wrapper, actorized heavy tasks) and will share precise signpost names for your T23 alignment.

---

# CTO Review — Build Unblock (Pass 1) and Pass 2 Orders

Status (verified)
- Environment OK (Xcode‑beta + iOS 26.0).
- SwiftData still imported in 6 UI/ViewModel files:
  - `AirFit/Modules/Dashboard/Views/DashboardView.swift`
  - `AirFit/Modules/Dashboard/Views/TodayDashboardView.swift`
  - `AirFit/Modules/Dashboard/Views/NutritionDashboardView.swift`
  - `AirFit/Modules/Body/Views/BodyDashboardView.swift`
  - `AirFit/Modules/Settings/Views/SettingsListView.swift`
  - `AirFit/Modules/Settings/ViewModels/SettingsViewModel.swift`
- DIViewModelFactory.makeCoachEngine uses undeclared vars and old `CoachEngine` initializer.

Pass 2 — Do this now
1) Remove SwiftData from UI/ViewModels (above 6 files)
   - Replace `import SwiftData` with repository/service calls:
     - Dashboard views: fetch only via `DashboardViewModel`; no ModelContext/@Query in Views.
     - SettingsListView: use `SettingsRepositoryProtocol`/`UserWriteRepositoryProtocol` only.
     - BodyDashboardView: use `UserReadRepositoryProtocol` + `HealthKitManaging` as needed.
   - SettingsViewModel:
     - Remove `import SwiftData` and `ModelContext` from initializer.
     - Add `DataExporterProtocol`; implement `UserDataExporterService` with SwiftData internally.
     - Inject `DataExporterProtocol` via DI; update `exportUserData()` to use it.
     - Update `DIViewModelFactory.makeSettingsViewModel` accordingly (stop passing `ModelContext`).
   - Proof in PR: ripgrep before/after showing zero `import SwiftData` in those files.

2) Fix DIViewModelFactory → CoachEngine wiring
   - Update `makeCoachEngine(for:)` to match current initializer:
     - Remove `muscleGroupVolumeService`/`exerciseDatabase` params.
     - Resolve only: `AIServiceProtocol`, `PersonaService`, `ContextAssembler`, `HealthKitManaging`, `RoutingConfiguration`, `NutritionCalculatorProtocol`.
     - Keep `ConversationManager(modelContext:)` creation.

3) Build + surface errors
   - `xcodegen generate`
   - `swiftlint --strict --config AirFit/.swiftlint.yml`
   - `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \\
      xcodebuild build -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' -quiet | tee build.log`
   - Attach top 20 compiler errors if any remain; fix in small follow‑ups.

4) Tests (after build passes)
   - `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \\
      xcodebuild test -scheme AirFit -testPlan AirFit-Unit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'`
   - Fix only failing tests; paste coverage % in PR body.

Acceptance
- Zero `import SwiftData` in the 6 files above (proof via ripgrep).
- iOS app builds on iOS 26.0 (Xcode‑beta).
- CRITICAL guardrails remain 0; guard/advisory summaries pasted in PR.
- No changes to CoachEngine public APIs.

---

# CTO Review — Pass 2 Validation Results & Corrections

Reality check (verified on main)
- `import SwiftData` still present in the following files:
  - `AirFit/Modules/Dashboard/Views/DashboardView.swift`
  - `AirFit/Modules/Dashboard/Views/TodayDashboardView.swift`
  - `AirFit/Modules/Dashboard/Views/NutritionDashboardView.swift`
  - `AirFit/Modules/Body/Views/BodyDashboardView.swift`
  - `AirFit/Modules/Settings/Views/SettingsListView.swift`
  - `AirFit/Modules/Settings/ViewModels/SettingsViewModel.swift`
- `DIViewModelFactory.makeCoachEngine(for:)` still calls the old initializer signature and references undeclared variables.

Corrections (Do now)
1) Remove SwiftData imports from the 6 files above.
   - No ModelContext/@Query in Views; route through ViewModels and repositories/services.
   - For SettingsViewModel:
     - Drop `import SwiftData` and `ModelContext` from the initializer.
     - Introduce `DataExporterProtocol` + `UserDataExporterService` (SwiftData inside service only).
     - Inject via DI; update `exportUserData()` to use the protocol.
     - Update `DIViewModelFactory.makeSettingsViewModel` to resolve `DataExporterProtocol` and stop passing `ModelContext`.

2) Fix `DIViewModelFactory.makeCoachEngine(for:)` to match current initializer.
   - Remove `muscleGroupVolumeService` and `exerciseDatabase` arguments.
   - Resolve only: `AIServiceProtocol`, `PersonaService`, `ContextAssembler`, `HealthKitManaging`, `RoutingConfiguration`, `NutritionCalculatorProtocol`.
   - Keep `ConversationManager(modelContext:)` creation.

3) Re‑run build and surface first 20 compiler errors (if any) with exact file:line.
   - Commands are the same as above; attach `build.log` in PR.

Acceptance (unchanged)
- Ripgrep proof: zero `import SwiftData` in those 6 files.
- App builds for iOS 26.0 with Xcode‑beta; CRITICAL remains 0.
- PR includes guard summaries and, if tests were touched, coverage % and rationale.

---

# CTO Review — Pass 3 Orders (Finish Build Unblock)

Remaining blockers (verified)
- DIBootstrapper still registers workout components that were removed:
  - `WorkoutRepositoryProtocol`, `WorkoutWriteRepositoryProtocol`, `WorkoutSyncService` (see DIBootstrapper around lines ~320, ~360, ~407)
- ContextAssembler relies on local `Workout` models (multiple references: assemble/compress/analyze streak and patterns).

Do now
1) DIBootstrapper cleanup
   - Remove or comment out DI registrations for:
     - `WorkoutRepositoryProtocol`
     - `WorkoutWriteRepositoryProtocol`
     - `WorkoutSyncService`
   - Ensure no other components resolve these types. If used only by workouts, remove those resolves.

2) ContextAssembler refactor (no local workouts)
   - Replace usages of local `Workout` models with HealthKit‑derived summaries.
   - Create lightweight structs for context (e.g., `CompactWorkoutHK`) populated from HealthKit summaries (date, duration, energy, top muscle groups if available, or leave empty).
   - Gate former local‑model code behind helper methods that return empty context when local models are absent.
   - Update streak calculation to use HealthKit workouts only (7‑day window via HK queries); if not feasible now, return 0 with a TODO and log once (no force unwraps, no test flags).

3) Build + surface
   - `xcodegen generate`
   - `swiftlint --strict --config AirFit/.swiftlint.yml`
   - `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \\
      xcodebuild build -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' -quiet | tee build.log`
   - Attach first 20 compiler errors if any; fix in small follow‑up PRs.

Acceptance
- No DI registrations or resolves for workout repositories or `WorkoutSyncService` remain.
- ContextAssembler compiles without referencing local `Workout`/`Exercise`/`ExerciseSet` models; uses HealthKit paths or safely returns empty context.
- iOS app builds on iOS 26.0 (Xcode‑beta).
