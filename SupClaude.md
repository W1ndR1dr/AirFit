# SupClaude — Parallel Analysis + Execution Plan (Claude + Sub‑Agents)

This document is your operating manual to coordinate multiple Claude sub‑agents working in parallel. It sets explicit gates, responsibilities, sequencing, and branch/PR hygiene so we converge fast without collisions. Treat it as the source of truth for execution.

## North Star & Success Criteria
- Outcome: Ship a cohesive, iOS‑26‑ready app with clean boundaries, strict concurrency, and predictable behavior comparable to a fresh rewrite.
- Gates: Enforce `Docs/Quality/QUALITY_GATES.md` across implementation safety, performance, accessibility, animation polish, and observability.
- Proof: Green build/test, zero force ops, single SwiftData container, store‑only chat streaming, key flows validated on real devices, coverage maintained or improved.

## Mission & Guardrails
- Mission: Produce a clean, cohesive, iOS‑26‑ready app with excellent UX and robust infra.
- Guardrails:
  - Follow `Docs/Quality/QUALITY_GATES.md` and component checklists.
  - Keep PRs small, focused, and mergeable; include a short validation note and screenshots for UI.
  - Do not reintroduce NotificationCenter for chat streaming; use `ChatStreamingStore`.
  - Do not add new `ModelContainer(` calls or force‑ops in the app target.
  - Respect boundaries: Modules/UI must not directly import SwiftData or touch `ModelContainer`.

## Shared Context (include in every assignment)
- `Docs/Codex-Independent-Analysis/Ground-Truth.md`
- `Docs/Codex-Independent-Analysis/Architecture-Review.md`
- `Docs/Quality/QUALITY_GATES.md`
- `AirFit/Core/DI/DIBootstrapper.swift`
- `AirFit/Core/Protocols/ChatStreamingStore.swift`

## Operating Model
- Owner roles:
  - Tech Lead (orchestrator): planning, sequencing, gating decisions.
  - Build/CI Owner: scripts, lint, XcodeGen, test plans.
  - Architecture Owner: DI, boundaries, concurrency, SwiftData discipline.
  - AI/Chat Owner: streaming, parser fixtures, router determinism.
  - Health/Recovery Owner: HK flows, recovery analytics parity.
  - Design System Owner: surfaces, motion, accessibility.
  - Watch Owner: connectivity status + queue persistence.
  - Security Owner: secrets hygiene, keychain, log sanitization.

## Coordination Protocol
- Branch naming: `claude/<task-id>-<slug>` (e.g., `claude/T01-streaming-store-only`).
- PR template includes: Scope, Files changed, Validation (steps + screenshots), Gate checklist, Risks.
- Sync messages (examples):
  - “Claude-T01: store-only streaming verified on device (i16 Pro), TTFT 210ms.”
  - “Claude-T03: nutrition parser fixtures added; 1 warning remains on edge JSON.”
- Commits: present-tense conventional prefixes (`feat:`, `fix:`, `refactor:`, `chore:`).

## Phased Execution (Sequenced, parallelizable per phase)
1) Baseline & Guardrails
   - Run `Scripts/dev-audit.sh` to capture current build/lint status and store logs under `logs/`.
   - Integrate CI guard script (`Scripts/ci-guards.sh`) and expand with the upgrades below.
   - Artifact: Baseline report of warnings, test pass/fail, perf samples.
2) Inventory & Dependency Map
   - Generate symbol/dependency inventory; identify dead code, duplicate utilities, cross‑layer tangles.
   - Artifact: `Docs/Codebase-Status/Dependency-Map.md` + quarantine list.
3) Tighten Guardrails (incremental)
   - Re‑enable important SwiftLint rules gradually; add custom rules to enforce boundaries.
   - Extend CI guards to fail on boundary violations.
4) Dead Code Purge
   - Use Periphery + ripgrep; soft‑delete to `AirFit/Deprecated/` for 1–2 days; then remove.
5) Boundary Enforcement & DI Hardening
   - Enforce “UI/Modules do not import SwiftData or create containers”. Access data via repositories/services only.
   - Add DI resolution tests to ensure container integrity.
6) Tests & Fixtures
   - Golden fixtures for AI/Nutrition; router determinism; Health/Recovery data flows; add fakes/stubs.
7) Performance & Accessibility
   - Validate 60 fps target for Chat/Dashboard/Voice/Photo flows; ensure VoiceOver, Dynamic Type (+2), reduced motion.
8) Observability & Metrics
   - Wire TTFT, token cost, cache hit/miss, error rates into MonitoringService; export snapshot.
9) Watch Parity
   - Add `WatchStatusStore` and queue persistence for Workout transfer.
10) Docs & Handoff
   - ADRs for major decisions; PR Gate checklists; TestFlight readiness.

## Guardrail Upgrades (to implement in CI + Lint)
Extend `Scripts/ci-guards.sh` with additional checks:

```bash
# Guard: No NotificationCenter for chat streaming in AI/Chat modules
CHAT_NOTIFY=$(rg -n --no-heading -S \
  '(NotificationCenter\.default\.(post|addObserver))' \
  AirFit/Modules/AI AirFit/Modules/Chat || true)
if [ -n "$CHAT_NOTIFY" ]; then
  echo "$CHAT_NOTIFY"; fail "Chat streaming must use ChatStreamingStore; remove NotificationCenter coupling."
fi

# Guard: No SwiftData import in Modules’ Views/ViewModels
SWIFTDATA_UI=$(rg -n --no-heading -S 'import\s+SwiftData' \
  AirFit/Modules/**/Views AirFit/Modules/**/ViewModels || true)
if [ -n "$SWIFTDATA_UI" ]; then
  echo "$SWIFTDATA_UI"; fail "SwiftData import not allowed in UI/ViewModels; use repositories/services."
fi

# Guard: Require @MainActor on ViewModels
VM_NO_MAIN=$(rg -n --no-heading -S 'class\s+\w+ViewModel' AirFit/Modules/**/ViewModels \
  | rg -v '@MainActor' || true)
if [ -n "$VM_NO_MAIN" ]; then
  echo "$VM_NO_MAIN"; fail "ViewModels must be @MainActor."
fi

# Guard: Networking must go through NetworkClientProtocol
RAW_NETWORK=$(rg -n --no-heading -S 'URLSession\.|dataTask\(' AirFit \
  -g '!AirFit/Services/Network/**' -g '!AirFit/**/Tests/**' || true)
if [ -n "$RAW_NETWORK" ]; then
  echo "$RAW_NETWORK"; fail "Use NetworkClientProtocol; do not call URLSession directly."
fi
```

SwiftLint custom rules to add (staged rollout) in `AirFit/.swiftlint.yml`:

```yaml
custom_rules:
  no_swiftdata_in_ui:
    included: ["AirFit/Modules"]
    name: "No SwiftData in UI"
    regex: "(?s)import\s+SwiftData"
    message: "UI/ViewModels cannot import SwiftData; use repositories/services."
    severity: warning
  no_notificationcenter_chat:
    included: ["AirFit/Modules/AI", "AirFit/Modules/Chat"]
    name: "No NotificationCenter for chat"
    regex: "NotificationCenter\\.default\\.(post|addObserver)"
    message: "Use ChatStreamingStore for streaming."
    severity: warning
  no_force_ops:
    included: ["AirFit"]
    excluded: ["AirFit/**/Tests/**", "AirFit/**/Previews/**"]
    name: "No force ops"
    regex: "try!| as!| !\."
    message: "Replace force ops with safe handling."
    severity: error
```

## Task Matrix (Parallelizable)

### T01 — Store‑Only Streaming Verification & Cleanup
- Goal: Ensure chat streaming uses `ChatStreamingStore` exclusively; remove any legacy NotificationCenter coupling.
- Context Pack:
  - `AirFit/Modules/AI/Core/CoachOrchestrator.swift`
  - `AirFit/Modules/Chat/ViewModels/ChatViewModel.swift`
  - `AirFit/Core/Protocols/ChatStreamingStore.swift`
- Deliverables:
  - Confirm producers/consumers are store‑only; remove dead notification names if unused.
  - Device test results (TTFT, smoothness).
- Exit Criteria:
  - No references to `.chatStreamStarted/.Delta/.Finished` observers or posts.
  - Meets Chat Stream checklist.

### T02 — Nutrition Parser: Golden Fixtures + Robustness Pass
- Goal: Add tests + fixtures for JSON nutrition parsing and validation; cover normal, ambiguous, and malformed inputs.
- Context Pack:
  - `AirFit/Modules/AI/Core/AIParser.swift`
  - `AirFit/Modules/AI/Strategies/NutritionStrategy.swift`
- Deliverables:
  - Tests (AirFitTests) for `parseFoodItemsJSON`, `validateFoodItems`, and fallbacks.
  - Fixture JSON files under `AirFitTests/Fixtures/Nutrition/`.
- Exit Criteria:
  - Tests pass; at least 8 scenarios covered; no regressions.

### T03 — Router Heuristics Sanity & Tests
- Goal: Sanity‑check `CoachRouter` outputs and add minimal tests for routing choices.
- Context Pack:
  - `AirFit/Modules/AI/Core/CoachRouter.swift`
  - `AirFit/Modules/AI/Core/CoachOrchestrator.swift`
- Deliverables: 4–6 tests asserting route decisions across common inputs.
- Exit Criteria: Tests pass; router remains deterministic with current config.

### T04 — CameraControlService Adapter (iOS 26)
- Goal: Introduce a capability‑gated `CameraControlServiceProtocol` and integrate into `PhotoInputView` without breaking AVFoundation fallback.
- Context Pack:
  - `AirFit/Modules/FoodTracking/Views/PhotoInputView.swift`
  - `AirFit/Services/Speech/VoiceInputManager.swift` (pattern reference)
- Deliverables:
  - `CameraControlServiceProtocol` + `DefaultCameraControlService` (capability checks; no‑op on unsupported devices).
  - Optional toggles to enable advanced controls.
- Exit Criteria: Photo capture works as before; advanced controls appear only when supported.

### T05 — Repository Layer (SwiftData Read Paths)
- Goal: Introduce read‑only repositories and refactor hot paths to use them (no SwiftData in view models/services).
- Context Pack:
  - `AirFit/Services/Context/ContextAssembler.swift`
  - `AirFit/Modules/Chat/ViewModels/ChatViewModel.swift`
  - `AirFit/Data/Managers/DataManager.swift`
- Deliverables:
  - `UserReadRepository`, `ChatHistoryRepository`, `WorkoutReadRepository` (protocol + impl).
  - Swap 2–3 hot reads to repositories.
- Exit Criteria: Build passes; no new `ModelContainer(` calls introduced.

### T06 — Design System: Liquid Glass Surfaces
- Goal: Centralize glass/blur/tint/shadow into a `SurfaceSystem` with tokens; replace ad‑hoc material usage on 2–3 high‑impact screens.
- Context Pack:
  - `AirFit/Core/Theme/*`, `AirFit/Core/Views/*` (if present)
  - `AirFit/Application/MainTabView.swift`
- Deliverables: `SurfaceSystem` tokens + modifiers; applied to TabBar and one dashboard entry point.
- Exit Criteria: Visual parity or improvement; passes Glass Tab Bar checklist.

### T07 — Motion Tokens & TextLoadingView Refinement
- Goal: Improve TextLoadingView timing/easing and unify motion tokens.
- Context Pack:
  - `AirFit/Modules/.../TextLoadingView.swift` (where defined)
  - `AirFit/Core/Theme/MotionToken.swift` (or equivalent)
- Deliverables: Eased dot animation; shared motion tokens; reduced motion behavior.
- Exit Criteria: Meets component checklist; on‑device verification video.

### T08 — App Intents for Navigation
- Goal: Define AppIntents for “Log Meal”, “Start Workout”, “Show Recovery/Progress” and route through `NavigationState`.
- Context Pack:
  - `AirFit/Application/NavigationState.swift`
  - Any intent scaffolding (if present)
- Deliverables: New intents with intent‑to‑NavigationState mapping + basic tests.
- Exit Criteria: Invoking intents switches tabs and injects a prompt when applicable.

### T09 — HealthKit Recovery Data Parity
- Goal: Replace any placeholder structs in Recovery views with real data flows; confirm analytics derived correctly.
- Context Pack:
  - `AirFit/Modules/Dashboard/Views/RecoveryDetailView.swift`
- Deliverables: Remove TODO placeholders; ensure trend computations displayed.
- Exit Criteria: Real metrics show; no placeholder leaks.

### T10 — Observability & Metrics Hooks
- Goal: Wire key metrics to `MonitoringService` (TTFT, token cost, cache hit/miss, error rate).
- Context Pack:
  - `AirFit/Services/Monitoring/MonitoringService.swift`
  - `AirFit/Services/AI/AIService.swift`
  - `AirFit/Modules/AI/Core/CoachOrchestrator.swift`
- Deliverables: Unified calls to track streaming performance and AI cost; simple dashboard dump.
- Exit Criteria: Snapshot export reflects live metrics after a chat session.

### T11 — Accessibility Sweep: Chat + Dashboard
- Goal: VoiceOver labels/order, Dynamic Type (+2), contrast AA, reduced motion on streaming/loader.
- Context Pack:
  - `AirFit/Modules/Chat/Views/ChatView.swift`
  - `AirFit/Modules/Dashboard/Views/*`
- Deliverables: AX attributes, reduced motion substitutions, typography scaling checks.
- Exit Criteria: Meets QUALITY_GATES Gate C + component checklists.

### T12 — Security & Secrets
- Goal: Verify no API keys in code; validate Keychain path and error surfaces; sanitize logs.
- Context Pack:
  - `AirFit/Services/Security/APIKeyManager.swift`
  - `AirFit/Core/Utilities/KeychainWrapper.swift`
  - Grep for `sk-`, `api_key`, `Bearer` literals
- Deliverables: Report + PRs removing any violations; improved error UX for missing/invalid keys.
- Exit Criteria: No hardcoded secrets; clean, helpful UX.

### T13 — CI Guardrail Integration
- Goal: Integrate `Scripts/ci-guards.sh` into CI; fail on force ops and ad‑hoc ModelContainers.
- Context Pack:
  - `Scripts/ci-guards.sh`
  - CI config (provided by you)
- Deliverables: Working CI step + docs in README/Docs/Release/TestFlight-Readiness.md.
- Exit Criteria: CI fails on violations; passes on clean branches.

### T14 — Test Scaffolding Restoration
- Goal: Provide missing fakes/stubs so existing tests compile and new tests can land.
- Context Pack:
  - `AirFit/AirFitTests/*`
  - References to `HealthKitManagerFake`, `AIServiceStub`
- Deliverables: Minimal `HealthKitManagerFake`, `AIServiceStub`; update imports and tests.
- Exit Criteria: `xcodebuild test` runs specified unit plan; green.

### T15 — Watch App Status & Queue
- Goal: Add a `WatchStatusStore` (paired/installed/reachable) and persist queued `PlannedWorkoutData` for later transfer.
- Context Pack:
  - `AirFit/Services/Watch/WorkoutPlanTransferService.swift`
  - `AirFit/Services/Watch/WatchConnectivityManager.swift`
- Deliverables: Store + queue persistence; simple UI hooks.
- Exit Criteria: Plans transfer once watch becomes reachable; status visible.

### T16 — Code Inventory & Risk Map
- Goal: Produce dependency map and dead‑code list; identify cross‑layer tangles.
- Deliverables: `Docs/Codebase-Status/Dependency-Map.md`, quarantine list.
- Exit Criteria: Owners assigned to resolve tangles/dead code.

### T17 — Unused Code Purge (Periphery Pass)
- Goal: Remove unreferenced code safely.
- Deliverables: Soft‑delete to `AirFit/Deprecated/` then removal PRs.
- Exit Criteria: No app references; green build.

### T18 — SwiftLint Tightening + Custom Rules
- Goal: Re‑enable key rules and add custom boundary rules.
- Deliverables: Updated `AirFit/.swiftlint.yml`; staged rollout plan.
- Exit Criteria: CI green with new rules; low noise.

### T19 — Boundary Guard Script
- Goal: Extend `ci-guards.sh` with checks listed in Guardrail Upgrades.
- Deliverables: Updated script + README notes.
- Exit Criteria: Fails on violations; passes on clean branches.

### T20 — Repository Layer for Data Access
- Goal: Replace SwiftData access in UI/services with repositories.
- Deliverables: Protocols + impl; swap 2–3 hot paths now.
- Exit Criteria: No new `ModelContainer(` calls; UI/VMs don’t import SwiftData.

### T21 — DI Graph & Resolution Tests
- Goal: Ensure DI container resolves all core services.
- Deliverables: `AirFit/AirFitTests/DIResolutionTests.swift` covering core + new services.
- Exit Criteria: Tests green.

### T22 — Error Handling Harmonization
- Goal: Consolidate on `AppError`; remove `try!`, `as!`.
- Deliverables: Refactor PRs with user‑friendly error surfaces.
- Exit Criteria: No force ops; clear, recoverable errors in UX.

### T23 — Logging Categories & Coverage
- Goal: AppLogger categories for critical paths; sampling verified.
- Deliverables: Logging added to AI, network, Health, chat streaming.
- Exit Criteria: Logs are actionable; noise controlled.

### T24 — CI Pipeline Polishing
- Goal: Pretty logs, test plan coverage, strict lint on PRs.
- Deliverables: CI steps updated; documentation added to `Docs/Release/TestFlight-Readiness.md`.
- Exit Criteria: Fast, readable CI with guardrails enforced.

### T25 — File & Naming Hygiene
- Goal: One primary type per file; filename matches type.
- Deliverables: Mechanical moves only; `git mv` to preserve history.
- Exit Criteria: Reduced confusion without behavior change.

### T26 — Utilities Consolidation
- Goal: Single source for helpers in `AirFit/Utilities/`.
- Deliverables: Merge duplicates; deprecate shadows.
- Exit Criteria: No duplicate utilities; updated imports.

### T27 — Network Rationalization
- Goal: Single `NetworkClientProtocol` usage; `RequestOptimizer` in hot paths.
- Deliverables: Replace raw `URLSession` usage; add tests where critical.
- Exit Criteria: Requests funnel through Network layer; perf steady or better.

### T28 — Environment Config Hygiene
- Goal: Validate `ServiceConfiguration.detectEnvironment()`; ensure no secrets in repo; logs sanitized.
- Deliverables: PRs removing violations; better empty‑key UX.
- Exit Criteria: Clean `git grep` for secrets; staging toggles work.

### T29 — Watch Connectivity Queue/Status
- Goal: Reachability + persistence; queued transfers dispatch when reachable.
- Deliverables: `WatchStatusStore`; persistence wiring; UI badge if appropriate.
- Exit Criteria: Confirmed transfers after reachability change.

### T30 — Final Gate Sweep
- Goal: Certify QUALITY_GATES A–E on device.
- Deliverables: Report with device screenshots/short clips; checklist results.
- Exit Criteria: All gates pass; TestFlight checklist green.

## Area Workstreams (Owners + Headline Moves)
- AI/Chat: Store‑only streaming, parser fixtures, router tests, metrics hooks in `CoachOrchestrator`.
- Data/SwiftData: Single container at DI; repositories for read/write; no SwiftData in UI/VMs.
- Services: `@MainActor` where UI‑touched; networking via `NetworkClientProtocol` only.
- Health/Recovery: Real metric flows; replace placeholders; add `HealthKitManagerFake`.
- Design System: `SurfaceSystem` tokens; motion tokens; reduced‑motion variants.
- Watch: `WatchStatusStore` + persistent queue; visible status hooks.
- Security: Keychain path, secrets scrub; helpful error UX.

## Safety Protocol for Refactors
- Small PRs: one concern each, green build; screenshots for UI.
- File moves use `git mv` to preserve history.
- Soft delete: quarantine before removal.
- Don’t mix mechanical cleanups with behavior changes.

## Immediate Actions + Commands
- Generate project: `xcodegen generate`
- Lint baseline: `swiftlint --strict --config AirFit/.swiftlint.yml AirFit AirFitWatchApp`
- Smoke build: `xcodebuild build -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'`
- Dev audit: `Scripts/dev-audit.sh`
- Run CI guards locally: `Scripts/ci-guards.sh`

## PR Template (copy into each PR)
```
Title: <Txx — short description>

Scope
- What changed and why (concise). Link to task.

Files Changed
- Key paths and types.

Validation
- Steps to verify. Include screenshots/video for UI. Device + OS.

Gate Checklist
- [ ] Gate A (Safety): DI resolves; no force ops; single container
- [ ] Gate B (Perf): on‑device spot check (fps/TTFT/memory)
- [ ] Gate C (AX): VO labels/order; Dynamic Type; contrast; reduced motion
- [ ] Gate D (Polish): animation easing; consistency
- [ ] Gate E (Observability): logs + metrics useful

Risks
- Known tradeoffs; rollout notes.
```

## Handoff & Review
- Each task produces a PR with: scope, validation steps, screenshots/video (if UI), gate checklist results, and risk notes.
- Daily merge window with quick triage; conflicts resolved by Feature Owners:
  - Streaming/Chat: GPT‑5 owner
  - Health/Recovery: Claude‑HK owner
  - Design System: Claude‑Design owner
  - Infra/CI: GPT‑5 owner

## Success Criteria
- All QUALITY_GATES pass on device.
- Streaming, Chat, Food, Workouts, Recovery validated as vertical slices.
- No force ops or ad‑hoc containers in app target.
- TestFlight Readiness checklist satisfied.

---

## Live Assignments & Next Steps (Kickoff)

Active agents (in progress):
- Agent 1 — T01 Store‑only streaming (AI/Chat): Ensure exclusive `ChatStreamingStore`, remove NotificationCenter coupling, add TTFT metrics.
- Agent 2 — T13/T19 CI guardrails: Integrate `Scripts/ci-guards.sh` in CI; extend with boundary checks listed under Guardrail Upgrades.
- Agent 3 — T05 Repository layer: Introduce read‑only repositories and swap 2–3 hot reads; no SwiftData in ViewModels/Services.
- Agent 4 — T02 Nutrition fixtures: Golden fixtures and robustness tests for nutrition parsing.

New agents spinning up now:
- Agent 5 — T03 Router Heuristics Tests
  - Branch: `claude/T03-router-tests`
  - Scope: Add deterministic tests for `CoachRouter` covering forced route, simple parsing (DirectAI), and complex workflow (FunctionCalling).
  - Deliverable: `AirFit/AirFitTests/CoachRouterTests.swift` (added).
  - Validation: `-only-testing:AirFitTests/CoachRouterTests` (or run full unit plan locally).
  - DoD: Tests green; no production code churn.

- Agent 6 — T16 Dependency Map
  - Branch: `claude/T16-dependency-map`
  - Scope: Generate symbol/dependency inventory and produce `Docs/Codebase-Status/Dependency-Map.md`; identify dead code and cross‑layer tangles.
  - Deliverables: Doc with module → services → data access mapping, quarantine list for suspected dead code.
  - Validation: At least top 20 hotspots listed with owners; aligns with guardrails.

Reporting cadence (all agents):
- Post concise updates in PRs and team channel:
  - “Claude-Txx: scope, files, quick validation, residual risks.”
- Include Gate checklist per PR template in this doc.
