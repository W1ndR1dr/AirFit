# AirFit Code Review

## Context and Philosophy
This repo is clearly optimized for an AI-native, local-first fitness coach: device owns granular data, server computes insights, and LLM calls run via local CLI tools. I reviewed `CLAUDE.md`, `USER_GUIDE.md`, `server/ARCHITECTURE.md`, and core server/iOS services to align with that philosophy.

## What's Excellent and Well-Structured
- **Strong, explicit architecture choices**: Device-primary data ownership is clearly documented and consistently referenced in code (`server/ARCHITECTURE.md`, `server/context_store.py`).
- **Separation of concerns**: iOS app, widget, and server are cleanly split; services are grouped by responsibility (`AirFit/Services/`, `server/` modules).
- **Concurrency discipline on iOS**: Swift actors and strict concurrency are used consistently; service isolation is strong (`AirFit/Services/*`).
- **Tiered context + tool model**: The tiered context system and tool execution strategy are a good balance of performance and detail (`server/tiered_context.py`, `server/tools.py`, `AirFit/Services/AIRouter.swift`).
- **Background orchestration**: Insight generation and sync are off the hot path (`server/scheduler.py`, `AirFit/Services/AutoSyncManager.swift`).
- **Product clarity**: `USER_GUIDE.md` and the UI architecture show a coherent product vision that aligns with the AI-native thesis.

## Gaps, Risks, and Things That Don't Make Sense
1. **Data directory mismatch (confusing + error-prone)**  
   `server/config.py` defines `AIRFIT_DATA_DIR` but storage modules hardcode `server/data` (`server/context_store.py`, `server/exercise_store.py`, `server/scheduler.py`). This means the env var is effectively ignored and contradicts the architecture docs. Pick one source of truth and use it everywhere.
2. **API base URL caching can go stale**  
   `APIClient` captures `ServerConfiguration.configuredBaseURL` at init (`AirFit/Services/APIClient.swift`). Long-lived instances (e.g., `AutoSyncManager`, `AIRouter`) will not pick up server URL changes, leading to hard-to-debug behavior.
3. **Brittle LLM JSON parsing**  
   `server/insight_engine.py` splits on code fences and then `json.loads` directly. A minor output variation can break insight generation; this is likely in the wild. Consider reusing `server/json_utils.py` and validating required keys.
4. **Single-process assumptions in server state**  
   JSON files with in-process locks are safe only for a single server process. Running multiple Uvicorn workers (or multiple instances) risks data corruption and lost writes. This should be called out explicitly or enforced.
5. **Memory file writes lack locking**  
   `server/memory.py` appends to markdown files without locks. A concurrent request can interleave writes and corrupt files, especially with async tasks.
6. **CORS is wide open**  
   `server/server.py` allows `allow_origins=["*"]` with credentials. Fine on a private LAN, but risky if exposed via Tailscale or port-forwarding. Consider an API key or origin allowlist.
7. **Inconsistent provider messaging**  
   `server/llm_router.py` and `server/insight_engine.py` reference "ollama" while config and docs say "codex". This is small but confusing for operators.

## Performance and Efficiency Opportunities
- **Avoid main-actor heavy work**: `AutoSyncManager` is `@MainActor` and does multi-step sync/seeding. Consider moving heavier work off main and only updating `@Published` state on main.
- **Reduce full-file writes**: Context and insight stores rewrite full JSON files. It is fine now, but a transition to SQLite (or at least a compact write strategy) would improve durability and performance on SD cards.
- **Duplicate logic risk**: `AirFit/Services/LocalInsightEngine.swift` mirrors server formatting logic. Add shared tests or a version marker so the client and server stay in sync.

## Suggested Improvements (Prioritized)
1. **Unify data directory configuration** across server modules and docs (high ROI, reduces confusion).
2. **Make APIClient resolve base URL per request** or inject it at call time to avoid stale URLs.
3. **Harden LLM response parsing** using `json_utils` plus schema validation, and log raw failures.
4. **Document single-process server assumption** or add file locking / lightweight DB to support multiple workers.
5. **Add a minimal test layer** for parsing, context formatting, and insight generation boundaries.

## Closing Take
The architecture is cohesive and opinionated in a good way. The AI-native philosophy is not just in docs; it’s reflected in the data ownership model, tiered context system, and the CLI-based LLM integration. The biggest risks are around configuration consistency and operational robustness (LLM parsing, single-process state). Fixing those would materially increase reliability without changing the core product direction.
