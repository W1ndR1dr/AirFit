# Personal App Playbook (Solo / Friends & Family)

Optimized for a single developer using AirFit privately. Keep process light; keep code fast, readable, and reliable.

## Ground Rules
- Bias for action. Small, reversible changes over big-bang refactors.
- No corporate overhead: no compliance docs, no accessibility work unless you want it.
- Protect privacy and keys: never commit secrets; keep keys in Settings/Keychain.

## Minimal Workflow
- Branching: commit to `main` directly or short-lived feature branches.
- Planning: fill a tiny Task Packet (`Docs/HANDOFF.md`) for work that spans multiple files.
- Pairing: use Claude for implementation when helpful, via `Scripts/claude-impl.sh`.
- Validation: run `xcodegen generate`, `swiftlint --strict`, and a build.
- Release: archive locally in Xcode; TestFlight optional.

## Commands
```bash
# Quick sanity
Scripts/dev-audit.sh

# Implement with Claude (non-interactive)
Scripts/claude-impl.sh --print "Implement <task> per Docs/HANDOFF.md"
```

## Claude Setup (once)
- Install: `brew install --cask claude-code`
- Verify: `claude -v` (should print version) or `claude doctor`
- If PATH lookup fails in the wrapper: set `CLAUDE_BIN=/opt/homebrew/bin/claude` (or your path)

## Quality Bar (Lean)
- Build: 0 errors; warnings OK only if intentional and temporary.
- Lint: keep `swiftlint --strict` mostly green; silence noisy rules if they block you.
- Tests: write tests only for critical logic you don’t want to break (parsers, models, services). UI tests optional.
- Performance: avoid jank; profile occasionally with Instruments for hotspots (launch, dashboard scroll, AI processing).

## What We’re Not Doing
- No accessibility mandate; add if/when you personally need it.
- No coverage thresholds or codecov.
- No heavy CI; keep GitHub Actions if useful, but it’s optional.

## When to Use Claude vs Manual
- Use Claude for: multi-file refactors, boilerplate generation, or when you’re tired.
- Do it manually for: tiny fixes, UI tweaks, and anything you enjoy crafting.

## Quick Priorities (Initial)
1) Baseline: build clean, resolve top SwiftLint pain points.
2) Performance: measure cold launch + dashboard scroll; fix top 1–2 issues.
3) Features: macro rings, muscle volume tracking, HealthKit nutrition sync.
4) AI polish: consistent persona outputs; robust function calling.
