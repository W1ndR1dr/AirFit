
# Handoff Packet — 0013 UI/UX Polish I (Today + Chat)

Title: Refine Today header, tighten Chat composer and streaming reveal, unify spacing/typography.

Context:
- Visual quality is close but not cohesive. We want a clean, high‑end look that matches our gradient system and spacing tokens.
- Keep diffs focused and visible; no broad rewrites.

Goals (Exit Criteria):
- Today header feels like a “hero card”: better legibility, tighter spacing, subtle motion, and no crowding at top.
- Chat header and composer feel lighter: improved contrast, subtle micro‑interactions, and consistent iconography.
- Spacing/typography: use `AppSpacing` and `AppFonts` consistently in touched areas.

Constraints:
- SwiftUI only; keep changes local to Today and Chat (no new dependencies).
- Do not modify business logic.

Scope & Guidance (surgical):
- Today (`AirFit/Modules/Dashboard/Views/TodayDashboardView.swift`):
  - In `dynamicHeaderImmediate()`:
    - Wrap existing VStack with `GlassCard` (already), but adjust spacing: 6pt vertical stack spacing, 8pt vertical padding inside card.
    - Title: `AppFonts.title`, primary color.
    - Subtitle: `AppFonts.subheadline`, secondary color, max 2 lines, lineSpacing 2.
    - Add a subtle divider under the header card: a 1pt horizontal line using gradient accent with low opacity.
- Chat (`AirFit/Modules/Chat/Views/ChatView.swift`):
  - Header strip: keep copy “AI Coach” + “Your Personal Fitness Guide”; reduce material blur to `.thinMaterial`; apply smaller vertical padding; ensure it doesn’t visually compete with messages.
  - Typing indicator: left padding + small fade/scale transition when appearing.
- Composer (`AirFit/Modules/Chat/Views/MessageComposer.swift`):
  - Button circle for send/mic:
    - Use `.ultraThinMaterial` fill as is, but stroke with gradient accent at 0.3 opacity, 1pt.
    - Icon gradient when sendable; secondary when mic.
  - Container background: keep 24pt corner radius; slightly reduce shadow y offset; ensure AppSpacing usage.
  - TextField placeholder: “Message your coach…” remains; ensure 16pt size.

Deliverables:
- Minimal diffs to: TodayDashboardView.swift, ChatView.swift, MessageComposer.swift
- Keep tokens consistent: `AppSpacing`, `AppFonts`, `gradientManager`.

Validation:
- Build passes.
- Visual: Today header cleaner; Chat header/composer lighter; typing indicator transitions smoothly.

Notes:
- No changes to ring visuals or secondary sections in Today.
- No persona name fetch in Chat header (avoid new DI calls here).
