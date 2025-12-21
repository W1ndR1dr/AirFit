# Code Review Verification (Current Codebase)

This document verifies items from `AirFit/CODE_REVIEW.md` and
`AirFit/CODE_REVIEW_2025-12-20.md` against the current code.

## Profile On-Device Shift (Status: Partial)
- Device-first profile scaffolding exists: `AirFit/Models/LocalProfile.swift#L161`,
  `AirFit/Services/ProfileEvolutionService.swift#L4`, `AirFit/Views/ChatView.swift#L1020`.
- Gemini mode builds local context and memory: `AirFit/Services/ContextManager.swift#L120`.
- Server mode and UI still rely on server profile:
  `AirFit/Views/ProfileView.swift#L29`, `AirFit/Views/YouView.swift#L8`,
  `AirFit/Views/ChatView.swift#L793`, `server/server.py#L245`.
- iOS calls memory/profile sync endpoints that do not exist on the server:
  `/sync/memories` and `/profile/sync` are called from
  `AirFit/Services/MemorySyncService.swift#L301` but are not defined in
  `server/server.py`.

## Verified: Items Still Present From `AirFit/CODE_REVIEW.md`
- Data directory mismatch (env var vs hardcoded `server/data`):
  `server/config.py#L20`, `server/context_store.py#L31`,
  `server/exercise_store.py#L23`, `server/scheduler.py#L24`.
- API base URL cached at init (can go stale for long-lived clients):
  `AirFit/Services/APIClient.swift#L3`.
- Brittle LLM JSON parsing (code-fence splitting + `json.loads`):
  `server/insight_engine.py#L270`.
- Single-process assumptions only (thread locks, no cross-process locking):
  `server/context_store.py#L35`, `server/exercise_store.py#L28`.
- Memory file writes without locking:
  `server/memory.py#L180`.
- CORS open with credentials:
  `server/server.py#L55`.
- Provider naming mismatch ("ollama" vs codex):
  `server/insight_engine.py#L10`, `server/llm_router.py#L218`.
- AutoSyncManager remains `@MainActor` for multi-step syncs:
  `AirFit/Services/AutoSyncManager.swift#L12`.
- Full-file JSON rewrites for context store:
  `server/context_store.py#L220`.
- Client/server duplication for insight formatting:
  `AirFit/Services/LocalInsightEngine.swift#L4`.

## Verified: Items Still Present From `AirFit/CODE_REVIEW_2025-12-20.md`
- Missing server endpoints used by iOS memory/profile sync:
  `AirFit/Services/MemorySyncService.swift#L301`; no matching routes in
  `server/server.py`.
- Hevy tools treat workouts like dicts, but API returns `HevyWorkout` objects:
  `server/tools.py#L171` vs `server/hevy.py#L11`.
- Duplicate `/profile/import` endpoints:
  `server/server.py#L680` and `server/server.py#L930`.
- Demo data seeding auto-runs when local DB is small:
  `AirFit/Services/AutoSyncManager.swift#L111`.
- Gemini privacy defaults defined but never initialized (no call sites found):
  `AirFit/Services/ContextManager.swift#L29`.
- Multiple Hevy API calls per chat context build:
  `server/chat_context.py#L174` -> `server/hevy.py#L29` and `server/hevy.py#L349`.
