# AirFit Quality Gates (World‑Class Bar)

This sets hard gates we must pass before shipping or calling a feature “done”. It balances measurable performance, accessibility, polish, and implementation safety.

## Gate A — Implementation Safety (Infra)
- DI: All critical services resolve in tests (no named‑binding drift)
  - Test: `AirFit/AirFitTests/DIResolutionTests.swift` passes and covers core + new services
- Force ops: No `try!`, `as!`, or IUOs in app target (previews excluded)
  - CI guard: grep check blocks regressions
- SwiftData: Single app‑owned `ModelContainer`; no ad‑hoc containers in services/views
  - CI guard: grep check for `ModelContainer(` outside allowed files
- Streaming: Chat streaming decoupled via `ChatStreamingStore` (no NotificationCenter coupling)
  - Criteria: Producers/consumers exclusively use the store; notifications removed

## Gate B — Performance (Real Device)
- 60 fps target: 95% frames under 16.7 ms on iPhone 13/15 class devices
  - Scenarios: Chat streaming, Dashboard scroll, Photo flow, Voice input
- Launch: App to first interactive screen < 800 ms (warm) / < 1.8 s (cold)
- Memory: No sustained spikes > 300 MB during typical flows
- Battery: No abnormal background CPU (< 3% over 5 minutes idle)

## Gate C — Accessibility & Reduced Motion
- VoiceOver: Navigable, labeled, meaningful order on all primary screens
- Dynamic Type: Comfortable up to 2 levels above Large
- Contrast: Meets WCAG AA for text
- Reduce Motion: No complex animations when enabled; substitute fades

## Gate D — Interaction & Animation Polish
- Animation: Apple‑level easing; no jank, no double transitions
  - Defaults: `MotionToken.standardSpring` or cubic‑bezier tuned per component
- Typography: Clear hierarchy at a glance; consistent size/weight/spacing
- Consistency: Controls and affordances behave the same across modules

## Gate E — Observability & Error UX
- Logs: AppLogger category coverage for critical paths
- User‑visible errors: Helpful, recoverable messages; no dead‑ends
- Cost/usage: AI token usage tracked (mark estimates explicitly for streaming)

## Process
- Every PR touching UI or infra includes a “Gate Checklist” (see checklists below)
- Run device checks on at least one newer (iPhone 15/16 class) and one older (iPhone 12/SE) device
- Screenshots or short clips for animation‑heavy changes

---

# Component Checklists
- Chat Stream: `Docs/Quality/components/ChatStream.md`
- Glass Tab Bar: `Docs/Quality/components/GlassTabBar.md`
- TextLoadingView: `Docs/Quality/components/TextLoadingView.md`
- Voice Input affordances: `Docs/Quality/components/VoiceInput.md`

