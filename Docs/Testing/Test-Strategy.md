# AirFit Testing Strategy

Goal: reliable, fast feedback and broad, meaningful coverage across Core, Services, and Modules while keeping UI tests minimal and stable.

## Layers
- Unit: pure logic and actors; no I/O. Runs by default via `AirFit-Unit.xctestplan`.
- Integration: DI + SwiftData in-memory, fakes for external services; a few end-to-end flows.
- UI: very small smoke set only (launch + 1–2 flows).
- Watch: isolated; run via `AirFit-Watch.xctestplan`.

## Isolation
- No network. Use fakes: `HealthKitManagerFake`, `NetworkClientFake`, `APIKeyManagementFake`, `LLMProviderFake`.
- Persistence uses in-memory `ModelContainer` via helpers.
- Deterministic async: small delays only in streaming tests.

## Coverage Targets
- 80%+ for Core, Services, Modules; pragmatic for UI.
- Gate coverage in CI for changed files or whole-project floor.

## Plans & Schemes
- Default plan: `AirFit-Unit.xctestplan` (fast, parallelizable).
- Additional: `AirFit-Integration.xctestplan`, `AirFit-UI.xctestplan`, `AirFit-Watch.xctestplan`.

## Current Seed Suite
- DI resolution smoke (resolves key services).
- AIService modes: demo/test/offline behavior + streaming.
- Nutrition: BMR invariants + dynamic targets sanity.
- SwiftData CRUD: create/fetch roundtrip for `User`.

## Next Additions
- NutritionCalculator invariants for edge cases (no weight, extreme values).
- Workout: muscle volume aggregation + PR progression.
- Persona: synthesis orchestration + persistence.
- Diagnostics: add a debug view surfacing service health.

## Commands
```
xcodegen generate
swiftlint --strict
xcodebuild build -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'
xcodebuild test -scheme AirFit -testPlan AirFit-Unit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'
```

## Notes
- Watch tests currently compile separately; keep `AirFit-Unit` green at all times.
- Lint violations exist in Watch and some Core files; plan to fix incrementally or scope lint paths in CI until cleaned.

