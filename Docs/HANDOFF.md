# AirFit — Engineering Handoff Guide (Bulletproof)

Audience: New Codex/Claude agents joining mid‑stream. This is the single source of truth for how to build, test, validate, and contribute without breaking architecture.

## 1) TL;DR
- Platform: iPhone 16 Pro only, iOS 26 only
- Guardrails:
  - No NotificationCenter for chat streaming; use `ChatStreamingStore`
  - No SwiftData in UI/ViewModels; repositories/services only
  - Single DI‑owned `ModelContainer`; no new `ModelContainer()`
  - All ViewModels `@MainActor`; no `try!`, `as!`, or force unwraps
- CI pipeline: `.github/workflows/ci.yml` — XcodeGen → SwiftLint → build → unit tests → quality guards → artifacts
- Coordination: `SupClaude.md` (instructions to Claude), `SupCodex.md` (report back to Codex)

## 2) One‑Time Setup
```bash
git clone <repo-url>
cd AirFit
xcodegen generate
open AirFit.xcodeproj
```

## 3) Build & Test Locally
```bash
swiftlint --strict --config AirFit/.swiftlint.yml
xcodebuild clean build -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'
xcodebuild test -scheme AirFit -testPlan AirFit-Unit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'
```

## 4) Quality Guards
```bash
./Scripts/ci-guards.sh                 # Architectural boundaries & hygiene
Scripts/validation/performance-benchmarks.sh  # Optional perf
```
Artifacts are uploaded in CI. If running locally, capture logs and include in PRs.

## 5) Project Structure (Authoritative)
- `AirFit/Core/` — DI, protocols, utilities, observability
- `AirFit/Data/` — SwiftData models and repositories
- `AirFit/Modules/` — Feature modules (AI, Chat, Dashboard, FoodTracking, Workouts, Onboarding)
- `AirFit/Services/` — Business logic (AI, Health, Network, Persona)
- `Docs/` — Architecture, CI, development standards, status reports

Entry points:
- DI: `AirFit/Core/DI/DIBootstrapper.swift`
- Chat streaming: `AirFit/Core/Protocols/ChatStreamingStore.swift`
- AI service: `AirFit/Services/AI/AIService.swift`
- Coach: `AirFit/Modules/AI/CoachEngine.swift`
- Context: `AirFit/Services/Context/ContextAssembler.swift`

## 6) Observability & Performance
- OSLog categories: ai, context, streaming (see `AirFit/Core/Observability/Signposts.swift`)
- Streaming adapter: `AirFit/Core/Observability/ChatStreamingMetricsAdapter.swift`
- Targets: TTFT < 300ms p50 / < 500ms p95; context < 500ms cold, < 10ms warm

## 7) Branch & PR Workflow
- Branch naming: `claude/<task>` or `codex/<task>`
- Keep PRs small with a clear scope and QUALITY_GATES checklist
- Run local CI steps and paste guard summaries in PR body

## 8) Active Work & Ownership
- `SupClaude.md` — directives to Claude (current tasks, guardrails, merge order)
- `SupCodex.md` — Claude’s status report back to Codex (may be optimistic; Phase 0 re‑verifies)
- Codex owns C01 (CoachEngine performance) — avoid touching CoachEngine pipeline unless requested

## 9) Common Pitfalls (Read Carefully)
- Avoid introducing `ModelContainer()` in features; always resolve via DI
- Do not add SwiftData imports in `Modules/**/Views|ViewModels` — route via repositories
- Do not reintroduce NotificationCenter for streaming — extend ChatStreamingStore instead
- Keep ViewModels `@MainActor`; prefer Sendable models and actors

## 10) Useful Docs
- CI Pipeline: `Docs/CI/PIPELINE.md`
- Environments: `Docs/Development-Standards/ENVIRONMENTS.md`
- Architecture Overview: `Docs/Development-Standards/ARCHITECTURE.md`
- Release Readiness: `Docs/Release/TestFlight-Readiness.md`
- Status Snapshots: `Docs/Codebase-Status/`

## 11) Handoff Checklist (Attach to PRs)
- [ ] CI green (build + unit tests)
- [ ] SwiftLint strict passes
- [ ] `ci-guards.sh` shows zero (or reduced) violations; paste summary
- [ ] No SwiftData in UI/ViewModels
- [ ] No new `ModelContainer()`
- [ ] No force ops in app target
- [ ] Observability signposts intact (no spam)

## 12) Contact Points
- Coordination: open a note in `SupClaude.md` before merging cross‑cutting changes
- Performance budgets: see Signposts/targets above; negotiate in PR if variance is justified

