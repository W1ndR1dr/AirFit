# AirFit Code Review Supplement (Provider Parity + Context Curation) - 2025-12-20

## Purpose
This supplement proposes (1) a concrete fix plan for provider parity and profile sync endpoints, and (2) a context-curation strategy that preserves the "old friend" vibe while keeping deep data available on demand.

---

## 1) Provider Parity + Profile Sync Endpoints (Concrete Plan)

### Desired Behavior
- The device owns the profile and relationship memory; the server is a backup and Claude execution layer.
- Both Claude and Gemini conversations update the same local profile and memory.
- Hot-swapping providers preserves tone, preferences, and relationship continuity.

### Plan A (Recommended): Device-First Extraction for All Providers
1. **Always run local extraction on AI responses.**
   - Apply `MemoryMarkerProcessor` and `ProfileEvolutionService` to Claude responses as well as Gemini.
   - Files involved: `AirFit/Views/ChatView.swift`, `AirFit/Utilities/MemoryMarkerProcessor.swift`, `AirFit/Services/ProfileEvolutionService.swift`.
2. **Make server sync endpoints real and consistent.**
   - Implement `POST /sync/memories` to accept memory markers from device.
   - Implement `POST /profile/sync` to accept device profile snapshots as backup.
   - Files involved: `server/server.py`, `server/memory.py`, `server/profile.py`, `AirFit/Services/MemorySyncService.swift`.
3. **Fix the duplicate `/profile/import` route and version the profile import path.**
   - Keep one canonical import handler.
   - Files involved: `server/server.py`.
4. **Align schemas (device <-> server).**
   - Convert local string fields to list form on sync or change local types.
   - Files involved: `AirFit/Models/LocalProfile.swift`, `server/profile.py`.
5. **Conflict resolution: device wins unless server is newer.**
   - Add or reuse `updated_at` timestamps and only overwrite local fields when server has newer data.
   - Files involved: `AirFit/Services/MemorySyncService.swift`, `server/profile.py`.

### Endpoint Contracts (Proposed)
- `POST /sync/memories`
  - Request:
    ```json
    {
      "type": "callback|tone|thread|remember",
      "contents": ["string", "string"]
    }
    ```
  - Response:
    ```json
    { "status": "ok", "stored": 2 }
    ```
  - Server behavior: append to `server/memory.py` store, de-duplicate by type+content+date.

- `POST /profile/sync`
  - Request: full profile snapshot in the same shape used by `APIClient.ServerProfileExport`.
  - Response:
    ```json
    { "status": "ok", "server_updated_at": "ISO8601" }
    ```
  - Server behavior: store as backup, do not overwrite device unless explicitly pulled.

- `GET /profile/export`
  - Use existing endpoint for full profile fetch, not the summary-only `/profile`.
  - iOS sync should read this for a complete server backup restore.

### Schema Alignment (Must-Fix Mismatches)
- `training_style`: device is `String?`, server is `list[str]`.
- `relationship_notes`: device is `String?`, server is `list[str]`.
- `training_days_per_week`: device is `Int?`, server is `str`.
- Suggested approach: normalize to list/string at the sync boundary to avoid breaking storage.

### Validation Checklist
- Claude conversation -> local profile fields update (`LocalProfile`) and memory markers store locally.
- Gemini conversation -> same local updates as today.
- Device backup to server succeeds (200 OK) for `/sync/memories` and `/profile/sync`.
- Switching providers preserves the persona and tone.

---

## 2) Context Curation Strategy (Preserve the Vibe)

### Vibe Principles (From Provided Prompt)
- Old friend, bro energy, and human warmth.
- Evidence-based depth only when useful.
- No unsolicited meal/workout recommendations.
- Data is awareness, not agenda.

### Strategy Overview: Tiered Context + On-Demand Tools
Use small, relevant context by default and fetch deep data only when needed. This aligns with "old friend" behavior and reduces data dumps.

### Context Tiers
1. **Tier 0 (Always)**
   - Persona + warmth + relationship memory (brief).
   - No data blocks.
2. **Tier 1 (Intent-Gated)**
   - Short "status" summary only when the user asks about progress or logs a meal/workout.
3. **Tier 2 (Topic-Specific)**
   - Only include data blocks for the active topic (training/nutrition/recovery).
4. **Tier 3 (Tool-Based)**
   - Tools query detailed data on demand (workout history, nutrition details, trends).

### Server Path (Claude Mode)
1. **Add intent gating in `server/chat_context.py`.**
   - Only include workouts when message intent indicates training.
   - Only include nutrition when user logs food or asks nutrition questions.
   - Files involved: `server/chat_context.py`, `server/server.py`.
2. **Move deep data into tools.**
   - Keep `query_workouts`, `query_nutrition`, etc. as the deep data path.
   - Ensure tools work with `HevyWorkout` objects. Files: `server/tools.py`, `server/hevy.py`.
3. **System prompt guardrails for vibe.**
   - Add explicit rules: "Only show set/macro trackers when user logs a meal/workout" and "do not summarize metrics unprompted."
   - Files involved: `server/profile.py` (system prompt).

### iOS Path (Gemini Mode)
1. **Mirror intent gating in `ContextManager`.**
   - Build `dataContext` based on intent, not always-on sections.
   - Files involved: `AirFit/Services/ContextManager.swift`, `AirFit/Services/AIRouter.swift`.
2. **Avoid duplicate data injection.**
   - Local context already includes health/nutrition; do not append them again in `ChatView`.
   - Files involved: `AirFit/Views/ChatView.swift`.
3. **Respect privacy toggles for insights.**
   - If a user disables nutrition/workout/health, do not include derived insights from those domains.
   - Files involved: `AirFit/Services/ContextManager.swift`.

### User-Facing Controls (Optional but Powerful)
- Add a "verbosity" or "data use" slider:
  - Low: friend-first, no numbers unless asked.
  - Medium: mention key stats when relevant.
  - High: proactive data-based coaching.
- Store this in `LocalProfile` and incorporate into persona synthesis.

### Validation Checklist
- General chat ("what's up") does not include data summaries.
- Meal log triggers macro tracker in the next response only.
- Workout log triggers set tracker only when relevant.
- Data questions ("how am I doing") surface relevant metrics.

---

## Summary
Provider parity requires one shared local extraction pipeline and real sync endpoints. Context curation requires intent gating, tool-first depth, and explicit vibe rules that prevent data dumps. Together, these changes preserve the "old friend" persona while keeping the app a powerful LLM harness.
