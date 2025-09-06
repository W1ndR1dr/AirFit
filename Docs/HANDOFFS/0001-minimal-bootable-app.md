# Handoff Packet — 0001 Minimal Bootable App

Title: Establish a minimal, crash‑free boot path

Context:
- Codebase has good ideas but is inconsistent and may be non‑functional.
- We want a stable foundation to iterate quickly in personal mode.

Goals (Exit Criteria):
- App launches to a stable root view (no runtime errors).
- Onboarding completes with local config stored (no network required).
- Settings screen allows entering LLM keys and toggles (persisted securely).
- Dashboard renders with placeholder data without blocking.
- Build + SwiftLint (strict) pass locally.

Constraints:
- iOS 18.4 sim, Swift 6 strict concurrency, SwiftUI.
- Respect layering (Application/Core/Data/Modules/Services).
- Keep changes minimal; feature‑flag risky parts.

Scope:
- Application: `AirFit/Application/*` root, app state wiring.
- Onboarding: ensure single, simple flow (disable advanced steps behind toggles).
- Settings: key entry + simple toggles with persistence.
- Dashboard: placeholder content from local models or mocks.
- Exclude: AI calls, Watch app, complex networking (stub safely).

Plan (High‑Level):
- Create `FeatureToggles` (Core or Services) with sane defaults.
- Gate complex modules (AI, Notifications, Watch, advanced Onboarding) behind toggles.
- Simplify `AppState` and root navigation to Onboarding → Dashboard.
- Ensure `ServiceConfiguration.detectEnvironment()` works without env vars.
- Settings: ensure saving keys to Keychain and reading them on launch.

Validation:
- Commands:
  - `xcodegen generate`
  - `swiftlint --strict --config AirFit/.swiftlint.yml`
  - `xcodebuild build -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'`
- Manual: Launch app in simulator → complete onboarding → reach dashboard.

Risks & Rollback:
- If a module causes crashes, disable via toggle and leave TODO with path.
- Keep diffs minimal and reversible.

Notes:
- Prefer stubs/actors that return placeholder data over deleting code.

Claude Prompt (use with Scripts/claude-impl.sh):
```
Implement Handoff 0001: Minimal Bootable App.

Goals:
- Stable launch and navigation, onboarding stores config locally, settings persists keys, dashboard renders with placeholder data. No network/AI required.

Constraints:
- iOS 18.4, Swift 6 strict, SwiftUI.
- Respect layering and minimal diffs.

Scope & Plan:
- Add FeatureToggles and gate complex modules.
- Simplify AppState/root nav.
- Settings persists keys (Keychain) and toggles.
- Dashboard uses placeholder models if services unavailable.

Validation Commands:
- xcodegen generate
- swiftlint --strict --config AirFit/.swiftlint.yml
- xcodebuild build -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'

Please return:
- Diffs for changed files
- Summary of toggles and defaults
- Short manual test plan
```

