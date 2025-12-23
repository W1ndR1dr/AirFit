# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AirFit is an AI fitness coach that combines an iOS app with a Python backend. The system uses CLI-based LLM tools (Claude CLI, Gemini CLI) instead of cloud APIs, designed to run on a Raspberry Pi.

## Design Philosophy: AI-Native

**"Skate where the puck is going."** This app is built for where AI is headed, not where it is today.

Core principles:
- **Models improve** - Don't over-engineer around current limitations. Simple prompts > complex parsing. Let the AI do heavy lifting.
- **Scaffolding is model-agnostic** - The server wraps CLI tools; swap models without code changes. No vendor lock-in.
- **Minimal rigid structure** - Avoid brittle JSON schemas and regex parsing. Trust natural language in, natural language out.
- **Context is king** - Feed rich context (health data, history, profile) and let the model reason. Don't pre-filter what might be relevant.
- **Evolving personalization** - The AI learns about the user through conversation, not forms. Profile builds organically.
- **Forward-compatible** - Build features assuming future models will be smarter, faster, cheaper. Don't optimize for today's constraints.

## Architecture

```
iOS App (SwiftUI/SwiftData) ──HTTP──> Python Server (FastAPI)
       │                                      │
       │                                      │ subprocess
       │                                      v
       │                            CLI Tools (claude, gemini, codex)
       │
       └── Widget Extension (Live Activities for macro tracking)
```

- **iOS App**: SwiftUI with Swift 6 strict concurrency, targeting iOS 26+ on iPhone 16 Pro only
- **Server**: FastAPI with async subprocess calls to LLM CLIs
- **Data**: SwiftData on iOS, JSON files in `server/data/` on server
- **Widget**: WidgetKit extension for Dynamic Island and Lock Screen

## Build Commands

### iOS App
```bash
# Generate Xcode project from project.yml (uses XcodeGen)
xcodegen generate

# Build from command line (physical device only - no simulator testing)
xcodebuild -project AirFit.xcodeproj -scheme AirFit -sdk iphoneos build
```

**Target Device:** iPhone 16 Pro running iOS 26+ (physical device only, no simulator)

### Remote Deploy (via Tailscale)
```bash
# Deploy to iPhone from anywhere (requires Tailscale on both devices)
./scripts/deploy-to-iphone.sh
```

This script builds AirFit and installs it on a connected iPhone over Tailscale VPN.
Useful when accessing this Mac remotely via Claude Code iOS app.

**Prerequisites:**
- iPhone paired via USB at least once for wireless debugging
- Both Mac and iPhone running Tailscale and connected to same Tailnet
- iPhone unlocked when deploying

### Python Server
```bash
cd server
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Run server (auto-reloads)
python server.py

# Server runs on http://0.0.0.0:8080
```

## AI Provider Modes

The app supports two distinct AI operation modes:

1. **Server Mode** (Raspberry Pi) - Server calls CLI tools (claude, gemini, codex) via subprocess
   - Session continuity via `--resume` flag
   - Provider fallback chain: claude → gemini → codex
   - MCP tools for deep data queries

2. **Gemini Direct Mode** - iOS calls Gemini API directly with user's API key
   - Supports streaming, function calling, image analysis
   - Context caching for reduced latency (1-hour TTL)
   - ThinkingLevel: low/medium/high for reasoning depth

## Tiered Context System

Context is injected based on relevance, not dumped wholesale (see `server/tiered_context.py`):

- **Tier 1 (Core, ~100-150 tokens)**: Always present - phase/goal, today's status, alerts, insight headlines
- **Tier 2 (Topic-triggered, ~200-400 tokens)**: Based on keyword detection - training, nutrition, recovery, progress, goals
- **Tier 3 (Deep queries)**: Tool-based on-demand - MCP for Claude CLI, function calling for Gemini

Topic detection uses fast keyword/regex matching, no LLM call required.

## Memory System

AI-native relationship memory (`server/memory.py`) simulating Anthropic's Memory Tool:

- Claude marks memorable moments with `<memory:type>content</memory:type>` markers
- Types: `remember`, `callback` (inside jokes), `tone`, `thread` (follow-ups)
- Stored as markdown in `server/data/memories/`
- Weekly consolidation via LLM to prevent bloat

## Key Files

### Server
- `server/server.py` - FastAPI app, all endpoints, context injection for chat
- `server/llm_router.py` - Calls CLI tools via subprocess with session continuity
- `server/tiered_context.py` - Topic detection and tiered context building
- `server/memory.py` - AI-native relationship memory system
- `server/sessions.py` - Session management for multi-turn conversations
- `server/config.py` - Environment-based configuration
- `server/profile.py` - User profile management and personality generation
- `server/context_store.py` - Time-series storage for all metrics (nutrition, health, workouts)
- `server/insight_engine.py` - AI-powered pattern analysis from stored data
- `server/scheduler.py` - Background tasks for insight generation and Hevy sync
- `server/hevy.py` - Hevy workout API integration
- `server/tools.py` - MCP tool implementations for deep queries
- `server/mcp_server.py` - MCP server for Claude CLI integration

### iOS
- `AirFit/App/AirFitApp.swift` - App entry point with TabView
- `AirFit/Services/APIClient.swift` - HTTP client (actor-based), defines all API request/response types
- `AirFit/Services/GeminiService.swift` - Direct Gemini API client with function calling
- `AirFit/Services/AIRouter.swift` - Routes between server mode and Gemini direct mode
- `AirFit/Services/ContextManager.swift` - Builds local context for Gemini mode
- `AirFit/Services/HealthKitManager.swift` - HealthKit queries (actor-based)
- `AirFit/Services/LiveActivityManager.swift` - Dynamic Island Live Activity management
- `AirFit/Services/AutoSyncManager.swift` - Background sync of nutrition/health data
- `AirFit/Models/NutritionActivityAttributes.swift` - Live Activity data model
- `AirFit/Views/` - SwiftUI views for each tab

### Widget Extension
- `AirFitWidget/NutritionLiveActivity.swift` - Dynamic Island and Lock Screen UI
- `AirFitWidget/NutritionActivityAttributes.swift` - Shared attributes for Live Activity

## Data Flow

### Chat Context Injection
The `/chat` endpoint injects rich context before every message:
1. Pre-computed AI insights from background analysis
2. Weekly summary
3. Hevy workout data (30 days, PRs, volume trends)
4. Nutrition trends (7-day averages, compliance)
5. Health trends (weight, sleep, recovery - 14 days)
6. HealthKit data from iOS (today)
7. Nutrition entries from iOS (today + recent)

### Context Store (`server/data/context_store.json`)
Time-series storage with daily snapshots containing:
- `NutritionSnapshot`: calories, protein, carbs, fat, entry_count
- `HealthSnapshot`: steps, active_calories, weight, body_fat, sleep, HRV
- `WorkoutSnapshot`: workout_count, duration, volume, exercises

## Data Architecture: Device-Primary, Server-Compute

**Critical rule**: iOS device owns granular data, server stores only aggregates.

| Data Type | Owner | Stored On | Recovery Strategy |
|-----------|-------|-----------|-------------------|
| Nutrition entries (meals) | Device | SwiftData | Irreplaceable - backup device |
| Daily aggregates | Server | context_store.json | Device re-syncs |
| HealthKit metrics | Apple | HealthKit → Server | Device re-syncs |
| Hevy workouts | Server | context_store.json | Re-fetch from Hevy API |
| Profile & Insights | Server | JSON files | Regenerate from data |

Why: Pi has 32GB SD card. Daily aggregates = ~2KB/day = sustainable. Granular meals would bloat storage and duplicate device data.

See `server/ARCHITECTURE.md` for full details.

## Coding Style

### Swift
- 4-space indentation
- `UpperCamelCase` for types, `lowerCamelCase` for variables
- Service classes are `actor`s with Swift 6 strict concurrency
- One type per file, feature-aligned directories

### Python
- 4-space indentation, `snake_case` functions
- Module-level FastAPI endpoints in `server/server.py`

## Commit Conventions

Follow conventional commits: `feat:`, `fix:`, `chore:`, `refactor:` with optional scopes.

```bash
feat(Insights): Add weekly trend analysis
fix(Chat): Handle empty response from CLI
refactor(HealthKit): Simplify query logic
```

**Branching**: Work on `main` for changes touching ≤4 files. Create a feature branch for 5+ files or risky refactors.

## Testing

No automated test suite. Validate manually:
1. Run server, check `/status` and `/scheduler/status`
2. Test on physical iOS device (iOS 26+)
3. For UI changes, sanity-check key flows (onboarding, chat, nutrition, insights)

**If tests are added**, prioritize by risk: API contracts (iOS↔Server shapes) > provider parity (all modes produce compatible output) > fallback chains > session continuity.

## Development Notes

### iOS Concurrency
All service classes use Swift actors for thread safety. The codebase uses Swift 6 strict concurrency (`SWIFT_STRICT_CONCURRENCY: complete`).

### Server-Side LLM Calls
The server calls LLMs via CLI subprocess, not API. The router tries providers in order (claude → gemini → codex) and supports session continuity via `--resume` flag.

### Network Configuration
- Physical device connects to hardcoded IP in `APIClient.swift` (currently `192.168.86.50`)

### Profile System
User profiles evolve through conversation. The server extracts goals, preferences, and patterns from chat, then generates a personality prompt for personalized responses.

### Tool/Function Calling

Deep queries use tools to fetch detailed data on-demand:

**Available tools** (defined in `server/tools.py`, mirrored in `GeminiService.swift`):
- `query_workouts` - Exercise history, volume, PRs from Hevy
- `query_nutrition` - Macro trends, compliance, meal entries
- `query_body_comp` - Weight/body fat trends with EMA smoothing
- `query_recovery` - Sleep, HRV, fatigue patterns
- `query_insights` - AI-generated correlations and anomalies

In Server Mode: MCP server exposes tools to Claude CLI
In Gemini Mode: Function declarations sent with each request, executed via `/tools/execute` endpoint

### Debugging Endpoints
- `GET /status` - Server status, available providers, session info
- `GET /scheduler/status` - Background scheduler status
- `GET /insights/snapshots?days=30` - Raw daily snapshots
- `GET /insights/data-preview?days=90` - Preview data sent to AI
- `POST /profile/seed` - Seed profile with test data

### Environment Variables
```bash
AIRFIT_HOST=0.0.0.0
AIRFIT_PORT=8080
HEVY_API_KEY=...  # Optional, for workout sync
CLI_TIMEOUT=120   # LLM CLI timeout in seconds
AIRFIT_PROVIDERS=claude,gemini,codex  # Provider priority order
```

## Common Patterns

### Adding a New Tool
1. Add implementation in `server/tools.py`
2. Add schema in `server/tools.py` TOOL_SCHEMAS
3. Mirror in `GeminiService.swift` airfitTools property
4. Update tiered context topic detection if needed (`tiered_context.py`)

### Adding Context to Chat
- Tier 1 (always): Add to `build_core_context()` in `tiered_context.py`
- Tier 2 (topic-triggered): Add topic keywords + `_build_*_context()` function
- Tier 3 (on-demand): Create new tool

### iOS Service Pattern
All services are actors. Use `@MainActor` for UI-bound work, otherwise plain actors:
```swift
actor MyService {
    static let shared = MyService()
    // Methods are automatically isolated
}
```

### Testing Gemini Mode Locally
Set API key via Settings → Advanced → Gemini API Key. The key is stored in Keychain, not UserDefaults.

### MCP Configuration
The `.mcp.json` file configures a local MCP server for Claude Code, providing direct access to AirFit tools when working in this repo.

### Code Review Mode
For review-only tasks (no code changes):
- Document findings in `docs/` as Markdown
- Read `CLAUDE.md`, `USER_GUIDE.md`, and `server/ARCHITECTURE.md` first for context
