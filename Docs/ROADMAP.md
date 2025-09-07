# AirFit Takeover Roadmap (Personal Mode)

Owner: You (solo)
Defaults: iOS 26.0 sim, Swift 6 strict, SwiftLint strict

## Decision
- See ADR 0002 — Rehab instead of rewrite. Use feature toggles and Claude‑driven slices to converge quickly.

## P0 — Minimal Bootable App (1–2 sessions)
- App launches cleanly to a stable root nav.
- Onboarding completes with local config saved (no external calls required).
- Settings allows entering API keys (stored securely) and toggling features.
- Dashboard loads with placeholder data (no crashes, no blocking spinners).
- Build + lint pass locally.

Deliverable: working app you can poke around without errors.

## P1 — Core Feature Path (2–4 sessions)
- Food logging v1: free‑text entry → local parse stub → write to store.
- AI chat v1: single provider (Claude) with streaming + basic function calls.
- HealthKit permissions + read basic metrics (sleep, workouts) with safe fallbacks.
- Dashboard shows real data from store/HealthKit where available.
- Macro Rings on Today: implemented using MacroRingsView (no placeholders).

## Reference
- Bare‑Metal Checklist: `Docs/BARE_METAL_CHECKLIST.md`

Deliverable: daily‑drivable app — log food, see dashboard, chat with coach.

## P2 — Performance + Polish (ongoing)
- Cold launch budget set and met; dashboard scroll is smooth.
- Crash‑free; errors show friendly messages.
- Add missing tests for critical logic (parsers/services) only.

## Backlog (Prioritized)
- Macro Rings polish
- Muscle group volume tracking
- HealthKit nutrition sync (bi‑directional)
- Watch app parity (optional; after iOS path is happy)
- Persona consistency improvements

## Working Style
- Small, reversible PRs.
- Claude does implementation for multi‑file work; you review.
- Update docs with each change (KEEP THIS SHORT).
