# AirFit Rebuild Plan

## Vision
AI fitness coach that builds and evolves custom instructions based on you + your HealthKit data. Runs on your own Raspberry Pi - no cloud API keys needed.

## Architecture

```
iPhone App (SwiftUI)
       |
       | HTTP
       v
Raspberry Pi Server (Python/FastAPI)
       |
       | subprocess
       v
CLI Tools (claude, gemini, ollama)
```

## Day 1: Chat That Works
- [ ] Python server (FastAPI) with `/chat` endpoint
- [ ] Server calls `claude -p "..."` via subprocess
- [ ] iOS app: minimal chat UI
- [ ] iOS app: sends messages to server, displays responses
- [ ] Test: you can have a conversation

## Day 2: HealthKit Context
- [ ] iOS: pull basic HealthKit data (steps, sleep, weight, workouts)
- [ ] iOS: include health context in chat requests
- [ ] Server: inject context into prompts
- [ ] Test: AI knows your health data

## Day 3: Nutrition Logging
- [ ] iOS: simple food input (text/voice)
- [ ] Server: parse food into macros via AI
- [ ] iOS: save to SwiftData + optionally HealthKit
- [ ] iOS: show today's nutrition summary
- [ ] Test: log a meal, see your macros

## Day 4: Custom Instructions (Onboarding)
- [ ] iOS: simple onboarding questions (goals, preferences, context)
- [ ] Server: generate custom instructions from answers
- [ ] Server: persist instructions per user
- [ ] All chats use custom instructions as system prompt

## Day 5: Auto-Evolving Instructions
- [ ] Server: analyze conversation patterns
- [ ] Server: periodically update custom instructions
- [ ] User can view/edit their instructions

## Later: Polish & Expansion
- [ ] Glass morphism UI
- [ ] Watch app
- [ ] Workout tracking
- [ ] Recovery insights
- [ ] Multiple user profiles

## What We're Keeping from Old Codebase
- SwiftData model patterns (reference only)
- HealthKit query patterns (reference only)
- UI component ideas (rebuild clean)

## What We're Throwing Away
- All current Swift code (fresh start)
- Complex DI system (overkill)
- 83KB CoachEngine monolith
- Over-engineered abstractions

## Tech Stack
- **iOS**: SwiftUI, SwiftData, HealthKit
- **Server**: Python 3.11+, FastAPI, subprocess
- **AI**: Claude CLI (primary), Gemini CLI (fallback), Ollama (offline)
- **Deployment**: Raspberry Pi with systemd service
