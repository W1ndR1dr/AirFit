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

## Key Files

### Server
- `server/server.py` - FastAPI app, all endpoints, context injection for chat
- `server/llm_router.py` - Calls CLI tools via subprocess with session continuity
- `server/sessions.py` - Session management for multi-turn conversations
- `server/config.py` - Environment-based configuration
- `server/profile.py` - User profile management and personality generation
- `server/context_store.py` - Time-series storage for all metrics (nutrition, health, workouts)
- `server/insight_engine.py` - AI-powered pattern analysis from stored data
- `server/scheduler.py` - Background tasks for insight generation and Hevy sync
- `server/hevy.py` - Hevy workout API integration
- `server/nutrition.py` - Food parsing via AI

### iOS
- `AirFit/App/AirFitApp.swift` - App entry point with TabView
- `AirFit/Services/APIClient.swift` - HTTP client (actor-based), defines all API request/response types
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

## Development Notes

### iOS Concurrency
All service classes use Swift actors for thread safety. The codebase uses Swift 6 strict concurrency (`SWIFT_STRICT_CONCURRENCY: complete`).

### Server-Side LLM Calls
The server calls LLMs via CLI subprocess, not API. The router tries providers in order (claude → gemini → codex) and supports session continuity via `--resume` flag.

### Network Configuration
- Physical device connects to hardcoded IP in `APIClient.swift` (currently `192.168.86.50`)

### Profile System
User profiles evolve through conversation. The server extracts goals, preferences, and patterns from chat, then generates a personality prompt for personalized responses.

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
