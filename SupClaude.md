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
  - Checkout → Xcode 26 beta toolchain
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
