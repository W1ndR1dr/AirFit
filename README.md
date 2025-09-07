# AirFit

AI-powered fitness & nutrition tracking app for iPhone 16 Pro, iOS 26 only. Built with SwiftUI, SwiftData (via repositories only), and multi‑LLM AI integration.

## Core Vision

AirFit is an AI-native fitness coach that lives on your phone. Talk to it like a real coach, and it handles everything else through LLM magic.

### Key Features

**🎙️ Voice-First Interface**
- Natural language food logging: "I just ate chicken and rice"
- Conversational workout tracking
- AI coach with consistent persona across all interactions

**📊 Dashboard**
- **AI-Driven Content**: Primary insights, guidance, and celebrations generated dynamically
- **Nutrition Rings**: Visual macro tracking (protein/carbs/fat) with calorie ring
- **Muscle Group Volume**: Rolling 7-day hard sets per muscle group with progress bars
- **No Cards**: Clean design with text directly on gradient background

**🤖 AI-Native Architecture**
- Multi-LLM support (Claude, GPT-4, Gemini)
- Dynamic goal adjustment based on progress
- Personalized coaching voice generated during onboarding
- Everything flows through the AI - no hardcoded responses

**💪 Smart Training**
- Tracks volume (sets × reps × weight) per muscle group
- 7-day rolling window for optimal recovery planning
- AI adjusts volume targets based on recovery and progress

**🍎 HealthKit Integration**
- Nutrition data syncs bidirectionally
- Sleep and recovery metrics
- Workout data integration

## Technical Architecture

### Core Stack
- **iOS 26.0** minimum deployment (device: iPhone 16 Pro)
- **SwiftUI** for all UI
- **SwiftData** for local persistence
- **HealthKit** for fitness data
- **Swift 6** concurrency (actors, async/await)

### AI Integration
- **LLM Providers**: Anthropic Claude, OpenAI GPT-4, Google Gemini
- **Multimodal**: Supports text, voice, and image inputs
- **Streaming**: Real-time AI responses
- **Circuit Breaker**: Automatic failover and recovery

### Data Flow

```
User Input (Voice/Text/Photo)
         ↓
    CoachEngine
         ↓
    LLM Processing
         ↓
Structured Data + Response
         ↓
    ┌────┴────┐
HealthKit   SwiftData
    └────┬────┘
         ↓
    Dashboard UI
```

## Project Structure

```
AirFit/
├── Core/               # DI, protocols, utilities
├── Data/               # SwiftData models
├── Modules/            # Feature modules
│   ├── AI/            # Coach engine, persona
│   ├── Chat/          # Conversational UI
│   ├── Dashboard/     # Main dashboard
│   ├── FoodTracking/  # Nutrition logging
│   ├── Workouts/      # Training tracking
│   └── Onboarding/    # AI persona creation
├── Services/          # Business logic
│   ├── AI/           # LLM providers
│   ├── Health/       # HealthKit integration
│   └── Persona/      # Coach personality
└── Docs/             # Documentation
```

## Getting Started

1. **Clone the repository**
   ```bash
   git clone [repo-url]
   cd AirFit
   ```

2. **Generate Xcode project**
   ```bash
   xcodegen generate
   ```

3. **Open in Xcode**
   ```bash
   open AirFit.xcodeproj
   ```

4. **Configure API Keys**
   - Run the app
   - Complete onboarding
   - Add your LLM API keys in settings

## Development

### Key Commands
```bash
# Generate project and lint
xcodegen generate && swiftlint --strict --config AirFit/.swiftlint.yml

# Build verification (must be 0 errors, 0 warnings)
# Note: CI runs iOS 26.0 simulator on iPhone 16 Pro
xcodebuild clean build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'
```

### Development Notes
- Use XcodeGen to manage the project (`xcodegen generate`).
- Keep slices small and document changes in `Docs/STATUS.md` so the next agent can pick up quickly.

### Documentation
- Handoff Guide (start here): `Docs/HANDOFF.md`
- CI Pipeline: `Docs/CI/PIPELINE.md`
- Environments: `Docs/Development-Standards/ENVIRONMENTS.md`
- Architecture Overview: `Docs/Development-Standards/ARCHITECTURE.md`
- Development Standards: `Docs/Development-Standards/`
- Release Readiness: `Docs/Release/TestFlight-Readiness.md`

## Current Status

- Active coordination files: `SupClaude.md` (instructions to Claude), `SupCodex.md` (status back to Codex)
- A verification pass (Phase 0) is in progress to validate CI, guards, and performance. Treat “100% complete” claims as unverified until Phase 0 publishes `Docs/Codebase-Status/STATUS_SNAPSHOT.md`.

## Contributing

Follow `Docs/STATUS.md` and `Docs/Development-Standards/` for guidance on architecture and coding standards.

## License

Proprietary - All rights reserved
