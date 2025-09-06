# ADR 0002: Rehab vs Rewrite

Date: 2025-09-01

## Status
Accepted

## Context
The codebase is conceptually strong but inconsistently executed and partially non‑functional. We need a personal‑mode app with world‑class quality. The choice is either a full rewrite or a structured rehab.

Signals observed:
- Build succeeds locally (iOS 18.4). Established layering (`Application/Core/Data/Modules/Services`).
- DI, Swift 6 concurrency patterns, and modular features already exist (Chat, Dashboard, FoodTracking, Onboarding, Health).
- Excess complexity in onboarding and AI paths; areas of dead code and placeholders.
- Watch app present; not required for P0.

## Decision
Rehabilitate the existing codebase instead of rewriting from scratch.

## Rationale
- Strong architectural skeleton is present and compilable.
- Feature modules are independently salvageable behind toggles.
- Rehab preserves history and reduces time to a bootable app.
- Risks (state, AI, onboarding complexity) can be contained via feature toggles and progressive hardening.

## Approach (Bare‑Metal Rehab)
1) Minimal Bootable App (done): stable launch, simplified onboarding, Today tab default, AI optional.
2) Non‑placeholder Today: Macro Rings via real data (done).
3) Claude‑driven slices for multi‑file changes; planner/reviewer validates.
4) Progressive hardening per module (Chat, Food, Health) with clear acceptance per slice.
5) Defer Watch until iOS path is solid.

## Triggers to Reconsider Rewrite
- Widespread cross‑layer entanglement that resists isolation.
- Persistent crashes after targeted hardening of AppState, DI, and onboarding.
- Inability to meet basic performance budgets (launch, scroll) after localized refactors.

## Consequences
Positive: faster path to a usable app; preserves working pieces; less churn.
Trade‑offs: requires disciplined cleanup and strong toggles; some legacy patterns remain temporarily.

## Follow‑ups
- Track slices in `Docs/ROADMAP.md` and `Docs/HANDOFFS/*`.
- Keep toggles in `FeatureToggles` to gate heavy features until ready.
