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
  - Checkout → Xcode 16 toolchain
  - Generate: `xcodegen generate`
  - Lint: `swiftlint --strict --config AirFit/.swiftlint.yml AirFit AirFitWatchApp`
  - Build: `xcodebuild build -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'`
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

## Next Safe Tasks (available now)
- T06: Apply `surfaceCapsule` to other chips/buttons in Dashboard entry screens (limit to 1–2 spots per PR).
- T24: Add a short README section linking this runbook and QUALITY_GATES (done).
- T28: Propose guard snippet for Agent 2 when they wire `ci-guards.sh`.

---

Status: Updated by Coordinator — T06 tokens added + applied to Tab Bar and chips; logging and secrets tooling in place; CI runbook published. Update this file when tasks land or scopes change.

---

New Claude Instance — Kickoff Briefing (Read Me First)
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
