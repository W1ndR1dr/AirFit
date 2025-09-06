# ADR 0001: Adopt Planner→Implementer→Reviewer with Claude Opus

Date: 2025-09-01

## Status
Accepted

## Context
The codebase is evolving quickly with multiple agents. We must preserve context, maintain architectural integrity, and accelerate high-quality implementation while respecting Swift 6 concurrency and our module boundaries.

## Decision
We adopt a planner→implementer→reviewer model:
- Planner (this assistant) scopes work via a short Task Packet (Docs/HANDOFF.md).
- Implementer is Claude Opus 4.1, invoked via `Scripts/claude-impl.sh` in non‑interactive mode by default.
- Reviewer (this assistant) validates code against standards and quality gates.

Implementation details:
- Default safe mode for Claude (no permission bypass). Only use `PERMISSIONS=skip` in trusted local environments.
- PRs include the Task Packet and link to relevant standards; optional attachment of Claude output.
- Small, atomic, reversible changes; feature flags for risky refactors.

## Consequences
Positive:
- Repeatable, documented changes with clear acceptance criteria.
- Faster implementation while preserving architectural quality.
- Easier handoffs and reduced context loss between sessions/agents.

Trade-offs:
- Slight overhead to prepare Task Packets.
- Requires discipline to keep packets and docs up‑to‑date.

## References
- Docs/AI_PAIRING.md
- Docs/HANDOFF.md
- Docs/Development-Standards/

