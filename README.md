# AirFit

AI-powered fitness & nutrition tracking app for iOS 18.0+ using SwiftUI, SwiftData, and multi-LLM AI integration. Features Whisper transcription as an optional input method for text fields.

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
- **iOS 18.0+** minimum deployment
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
xcodebuild clean build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'
```

### Development Notes
- Use XcodeGen to manage the project (`xcodegen generate`).
- Keep slices small and document changes in `Docs/STATUS.md` so the next agent can pick up quickly.

### Documentation
- Development Standards: `Docs/Development-Standards/`
- Architecture: `Docs/Development-Standards/ARCHITECTURE.md`
- UI Standards: `Docs/Development-Standards/UI_STANDARDS.md`
- AI Standards: `Docs/Development-Standards/AI_STANDARDS.md`
- Personal App Playbook: `Docs/PERSONAL_PLAYBOOK.md`
 - Handoffs: `Docs/HANDOFF.md` template and `Docs/HANDOFFS/*`

## Current Status

The app architecture is complete with:
- ✅ World-class DI system with lazy resolution
- ✅ Swift 6 concurrency compliance
- ✅ Complete UI design system (GlassCard, gradients)
- ✅ Multi-LLM integration with streaming
- ✅ AI-powered nutrition parsing
- ✅ Persona synthesis during onboarding

Next features:
- 🚧 Macro rings display (convert bars to rings)
- 🚧 Muscle group volume tracking
- 🚧 Dynamic goal adjustment via AI
- 🚧 HealthKit nutrition sync

## Contributing

Follow `Docs/STATUS.md` and `Docs/Development-Standards/` for guidance on architecture and coding standards.

## License

Proprietary - All rights reserved
