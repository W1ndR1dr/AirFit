# Repository Guidelines & Multi-Agent Workflow

## Project Structure & Module Organization
- Source: `AirFit/` with layers `Application/`, `Core/`, `Data/`, `Modules/` (feature areas like `AI`, `Dashboard`, `Workouts`), and `Services/` (`Network`, `Health`, `Weather`).
- Watch: `AirFitWatchApp/` mirrors app concepts for watchOS.
- Assets & resources: `AirFit/Assets.xcassets`, `AirFit/Resources/`.
- Config: `project.yml` (XcodeGen), `AirFit/.swiftlint.yml`, `AirFit.xctestplan`.

## Build, Test, and Development Commands
- Generate Xcode project: `xcodegen generate` (run after editing `project.yml`).
- Build: `xcodebuild build -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'`.
- Test: `xcodebuild test -scheme AirFit -testPlan AirFit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'` (use `-only-testing` to scope).
- Lint: `swiftlint --strict` (match CI).
- Reset simulator (optional): `./reset-simulator.sh`.

## Coding Style & Naming Conventions
- Swift 6 with strict concurrency; prefer `Sendable`, `@MainActor`, and structured concurrency.
- Names: Types/Enums/Structs in PascalCase; functions/vars in camelCase; files match the primary type (e.g., `WorkoutService.swift`). Feature folders under `Modules/` use PascalCase.
- Follow rules in `AirFit/.swiftlint.yml`; fix warnings before PRs.

## Testing Guidelines
- Frameworks: XCTest + XCUITest via `AirFit.xctestplan` targeting `AirFitTests`, `AirFitUITests`, `AirFitWatchAppTests`.
- Naming: `<TypeName>Tests.swift`; mirror source structure where practical.
- Coverage: maintain or improve; re-run flaky UI tests or limit with `-only-testing`.

## Commit & Pull Request Guidelines
- Commits: clear, present-tense; conventional prefixes (`feat:`, `fix:`, `refactor:`, `chore:`).
- PRs: include summary, linked issues, affected modules, and screenshots for UI changes. Ensure CI is green (build, tests, SwiftLint) before review.

## Security & Configuration Tips
- Do not hardcode keys; prefer Keychain/Info.plist configuration or env vars.
- Environment selection uses `ServiceConfiguration.detectEnvironment()`; set `STAGING=1` for staging.
- Never commit secrets; verify `.gitignore` before pushing.

## Multi-Agent Coordination (Codex + Claude)
- Coordination files:
  - `SupClaude.md` — Codex instructions to Claude; lists tasks, guardrails, merge order
  - `SupCodex.md` — Claude’s status report back to Codex (treat claims as unverified until Phase 0 snapshot)
- Handoff guide (required): `Docs/HANDOFF.md`
- Branch naming: `claude/<task>` or `codex/<task>`; keep PRs small with QUALITY_GATES checklist
- CI pipeline: `.github/workflows/ci.yml`; match locally before opening PRs
- Guardrails (never violate):
  - No NotificationCenter for chat; use `ChatStreamingStore`
  - No SwiftData in UI/ViewModels; use repositories/services
  - Single DI-owned `ModelContainer`; no ad‑hoc new instances
  - All ViewModels `@MainActor`; no force ops (`try!`, `as!`, force unwrap)

