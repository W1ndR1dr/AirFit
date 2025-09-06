# Testing Roadmap

This is the working checklist to reach robust coverage.

## Phase 1 — Foundations (Done/In Progress)
- [x] Split test plans: Unit / Integration / UI / Watch
- [x] Default to Unit plan in the AirFit scheme
- [x] Seed smoke tests: DI, AIService modes, SwiftData CRUD
- [x] Fix AIService state snapshots for reliable reads
- [ ] Add test fakes for Network and API keys
- [ ] Lint cleanup: trailing whitespace/newlines in Watch + selected Core files

## Phase 2 — Nutrition & Workouts
- [ ] NutritionCalculator edge cases (no weight, fallback paths)
- [ ] Macro target invariants and unit conversion checks
- [ ] StrengthProgressionService tests: record PRs, trend calculations
- [ ] Muscle volume aggregation (if service/API available)

## Phase 3 — Persona & Onboarding
- [ ] PersonaSynthesizer orchestration with AIService fake
- [ ] Persistence of persona drafts/finals via SwiftData
- [ ] Onboarding flow model validations

## Phase 4 — Integration & Diagnostics
- [ ] Add a debug diagnostics view (service health + DI resolution)
- [ ] Integration tests with in-memory SwiftData + fakes for a couple of flows
- [ ] Coverage gating in CI (xccov)

## Stretch
- [ ] Snapshot tests for key SwiftUI components (stringent styles)
- [ ] Test fixtures for realistic HealthKit aggregates

