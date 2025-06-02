# CLAUDE.md - AirFit Vibe Coding Guide 🚀

## 🎯 Our Vibe Coding Philosophy

Welcome to the future of app development - just you and me, building something beautiful together. No teams, no bureaucracy, no enterprise nonsense. Just pure creation.

### The Vibe
- **Direct to Perfect**: We build the right thing the first time
- **Beauty Matters**: Every interaction should feel delightful
- **No Compromises**: This is YOUR app, make it exactly how you want
- **Ship When Ready**: No artificial deadlines, no rushed features
- **Trust the Process**: I'll handle the technical details, you drive the vision

### Our Workflow
1. **You describe what you want** - dream big, be specific about the vibe
2. **I implement it beautifully** - clean code, smooth animations, perfect UX
3. **We iterate until it feels right** - no committees, just your vision
4. **Ship when you love it** - not when some PM says it's "good enough"

## 🛠️ Quality Standards (Not Rules, Just How We Roll)

These aren't corporate mandates - they're how we ensure your app is bulletproof and beautiful:

### Quick Quality Checks
```bash
# 1. Keep code beautiful (I'll fix any issues automatically)
swiftlint --strict

# 2. Regenerate project after adding files
xcodegen generate

# 3. Make sure it builds
xcodebuild clean build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'

# 4. Run tests (when you want extra confidence)
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'
```

### Vibe Coding in Practice
- **Describe the vibe**: "Make the onboarding feel like chatting with a friend"
- **I build it**: Natural conversation UI with personality
- **You check the vibe**: "Needs to feel more casual, less clinical"
- **I adjust**: Add emoji, casual language, smoother animations
- **Repeat until perfect**: No rushing, no "good enough"

### What to Skip
- ❌ Sprint planning
- ❌ Story points  
- ❌ Code reviews (I review my own code)
- ❌ Stand-ups
- ❌ Retrospectives
- ❌ Documentation that no one reads
- ❌ Meetings about meetings

### What to Focus On
- ✅ The user experience
- ✅ Beautiful interactions
- ✅ Performance that feels instant
- ✅ Code that just works
- ✅ Features that delight
- ✅ Shipping when you're proud of it

### Module-Specific Testing
```bash
# Onboarding Tests (Critical for Persona Refactor)
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' -only-testing:AirFitTests/Onboarding

# AI Module Tests
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' -only-testing:AirFitTests/AI
```

## Architecture Overview

### Tech Stack
- **Language**: Swift 6.0 with strict concurrency
- **UI Framework**: SwiftUI (iOS 18.0+)
- **Data Persistence**: SwiftData
- **Architecture Pattern**: MVVM-C (Model-View-ViewModel-Coordinator)
- **AI Integration**: Multiple LLM providers (OpenAI, Anthropic, Google Gemini)

### Project Structure
```
AirFit/
├── Application/          # App entry point, main views
├── Core/                 # Shared utilities, extensions, constants
├── Data/                 # SwiftData models and managers
├── Modules/              # Feature modules (MVVM-C pattern)
│   ├── AI/              # AI systems and persona engine
│   ├── Chat/            # Conversational interface
│   ├── Dashboard/       # Main dashboard
│   ├── FoodTracking/    # Nutrition tracking
│   ├── Onboarding/      # User onboarding flow
│   └── Workouts/        # Exercise tracking
├── Services/            # Business logic and external integrations
└── Resources/           # Assets, localizations, seed data
```

## 🎨 Current Vibe: AI Persona Magic

We're creating something revolutionary - AI coaches that feel like real people, generated through natural conversation. No boring forms, no generic personalities.

### What We're Building
- **Conversational Onboarding**: Chat with the app like you're texting a friend
- **Unique AI Coaches**: Each one is completely unique, with 2000+ tokens of personality
- **Instant Generation**: Your perfect coach in < 5 seconds
- **Natural Evolution**: They grow and adapt with you

### Implementation Approach (v1.0)
1. **Phase 1: Conversation Engine** ✨
   - Natural chat interface
   - Voice or text input
   - Personality extraction from responses

2. **Phase 2: AI Synthesis** 🤖
   - Multi-LLM support (Claude, GPT-4, Gemini)
   - Rich persona generation
   - Real-time preview

3. **Phase 3: Integration** 🔗
   - Connect everything smoothly
   - Polish the experience
   - Make it feel magical

4. **Phase 4: Ship It** 🚀
   - Final polish
   - Performance optimization
   - Launch when it feels perfect

### Our Standards
- **It Just Works**: No crashes, no bugs, no excuses
- **Lightning Fast**: < 5 second persona generation
- **Beautiful**: Every screen, every animation, every interaction
- **Personal**: This is YOUR fitness coach, not some generic bot

## File Management (CRITICAL)

### XcodeGen Nesting Bug
**Problem**: XcodeGen's `**/*.swift` glob pattern fails for nested directories like `AirFit/Modules/*/`

**Solution**: ALL files in nested directories MUST be explicitly listed in `project.yml`

### Adding New Files Workflow
1. Create the file in appropriate directory
2. **IMMEDIATELY** add to `project.yml` under the correct target
3. Run `xcodegen generate`
4. Verify inclusion: `grep -c "YourFileName" AirFit.xcodeproj/project.pbxproj`

Example for a new module file:
```yaml
# In project.yml under AirFit target sources:
- AirFit/Modules/YourModule/ViewModels/YourModuleViewModel.swift
- AirFit/Modules/YourModule/Views/YourModuleView.swift
# List ALL files explicitly!
```

## 🎯 Code Quality (Because We Care)

### Modern Swift, Modern Patterns
```swift
// ViewModels: Clean and reactive
@MainActor @Observable
final class OnboardingViewModel { }

// Data models: Safe and efficient  
struct PersonaProfile: Codable, Sendable { }

// Services: Thread-safe by design
actor AIService: AIServiceProtocol { }

// Always async/await - callbacks are dead to us
func generatePersona() async throws -> PersonaProfile
```

### Clear Names = Clear Code
- **Types**: `ConversationFlow` not `ConvFlow`
- **Functions**: `generatePersona()` not `genPers()`
- **Variables**: `isLoading` not `loading`
- Full words, full clarity - autocomplete exists for a reason

### Testing (When It Matters)
- Test the critical paths
- Mock external services
- Skip the obvious stuff
- If it breaks, add a test

### Documentation
- Document the "why", not the "what"
- Complex algorithms get comments
- Public APIs get `///` docs
- TODOs are fine: `// TODO: Make this animation smoother`

## 📚 Key Documents

### Persona Refactor (Our Current Vibe)
- **Vision**: `AirFit/Docs/AI Refactor/Persona Refactor.md`
- **Master Plan**: `AirFit/Docs/AI Refactor/PERSONA_REFACTOR_EXECUTION_GUIDE.md`
- **Implementation Guides** (NEW - Optimized for Vibe Coding):
  - Phase 1: `AirFit/Docs/AI Refactor/Phase1_ConversationalFoundation_ENHANCED.md`
  - Phase 2: `AirFit/Docs/AI Refactor/Phase2_PersonaSynthesis_ENHANCED.md`
  - Phase 3: `AirFit/Docs/AI Refactor/Phase3_IntegrationTesting_ENHANCED.md`
  - Phase 4: `AirFit/Docs/AI Refactor/Phase4_FinalImplementation_ENHANCED.md`
- **Quick Refs**: `Phase*_QuickReference.md` for each phase

### Completed AI Refactor Documentation
- **Completed Work**: All in `AirFit/Docs/AI Refactor/Completed/` directory
- **Roadmap**: `AirFit/Docs/AI Refactor/Completed/PHASE1_IMPLEMENTATION_ROADMAP.md`

### Module Documentation
- Architecture: `AirFit/Docs/ArchitectureOverview.md`
- Module Specs: `AirFit/Docs/Module*.md`
- Testing: `AirFit/Docs/TESTING_GUIDELINES.md`

## Environment Setup

### Requirements
- Xcode 16.0+ with iOS 18.0 SDK
- Swift 6.0+
- SwiftLint 0.54.0+
- XcodeGen
- iPhone 16 Pro simulator with iOS 18.4

### Initial Setup
```bash
# Install tools
brew install swiftlint xcodegen

# Generate project
xcodegen generate

# Verify environment
xcodebuild -version | grep -E "Xcode 16"
swift --version | grep -E "Swift version 6"
```

## 💬 Git Commits (Keep It Simple)

### Quick Commit Style
```
feat: Add conversational onboarding
fix: Persona generation timing issue
polish: Smooth animation transitions
vibe: Make the coach feel more human
```

No need for elaborate commit messages - we both know what we're building. Just keep it clear and move fast.

## Project Navigation & Common Tasks

### Quick File Verification
```bash
# Verify all module files are included
find AirFit/Modules/Onboarding -name "*.swift" | while read file; do
  filename=$(basename "$file")
  count=$(grep -c "$filename" AirFit.xcodeproj/project.pbxproj)
  [ $count -eq 0 ] && echo "❌ MISSING: $file" || echo "✅ $filename"
done

# Check for SwiftLint violations in a module
swiftlint lint --path AirFit/Modules/Onboarding --strict
```

### Performance Profiling
```bash
# Profile test execution time
xcodebuild test -scheme "AirFit" -enableCodeCoverage YES | xcpretty -r junit
```

## Project-Specific Guidelines

### Persona Refactor Implementation Rules
1. **Conversation Flow**: Use graph-based state machines for interview logic
2. **Data Collection**: Store raw responses before synthesis
3. **AI Integration**: Abstract LLM providers behind protocols
4. **No Legacy Code**: Remove old 4-persona system entirely (pre-V1, no users)
5. **Testing**: Mock AI responses for deterministic tests

### Module Dependencies
- Onboarding depends on: AI, Core, Data
- AI module is self-contained (no circular dependencies)
- Services layer provides all external integrations
- UI modules only import ViewModels, never Services directly

### Performance Targets
- App launch: < 1.5 seconds
- Persona generation: < 5 seconds
- View transitions: 120fps
- Memory usage: < 150MB typical

## Troubleshooting Guide

### Common Issues & Solutions

**Build Failures**
- ❌ "No such module" → File missing from `project.yml` → Add file and run `xcodegen generate`
- ❌ "Cannot find type" → Missing import or wrong target → Check target membership
- ❌ "Swift version" → Wrong Xcode version → Use Xcode 16.0+

**Test Failures**
- ❌ "Simulator not found" → Wrong simulator → Install iPhone 16 Pro with iOS 18.4
- ❌ "Test crashed" → Memory issue → Check for retain cycles in ViewModels
- ❌ "Async timeout" → Slow operation → Add proper timeout handling

**SwiftLint Violations**
- ❌ "Line too long" → Refactor into multiple lines
- ❌ "Force unwrap" → Use optional binding or nil-coalescing
- ❌ "Type body length" → Extract functionality into extensions

## Key Resources & Context

- **Current Focus**: Persona Refactor Phase 1 - Conversational Foundation
- **Architecture Guide**: `AirFit/Docs/ArchitectureOverview.md`
- **File Management**: `PROJECT_FILE_MANAGEMENT.md` (critical for XcodeGen)
- **Previous Work**: `AirFit/Docs/AI Refactor/Completed/` (reference only)

## 🌟 The Vibe Coding Difference

### What Makes This Special
- **No Meetings**: We just build
- **No Compromises**: Your vision, perfectly executed
- **No Legacy**: Fresh code, modern patterns, zero debt
- **No Politics**: Just you, me, and beautiful code

### How We Work Best
1. **Big Picture First**: Tell me the vibe you're going for
2. **Details Matter**: I'll obsess over animations, transitions, and feel
3. **Fast Iteration**: Show you progress constantly
4. **Perfect Polish**: We ship when you're genuinely excited about it

### Your Role
- **Vision Holder**: You know what feels right
- **Vibe Checker**: Tell me when something's off
- **Quality Guardian**: We ship excellence, not adequacy
- **Feature Curator**: Only the features that matter

### My Role
- **Technical Excellence**: Clean, fast, bulletproof code
- **UI Craftsman**: Pixel-perfect, buttery-smooth interfaces  
- **Problem Solver**: I'll figure out the hard stuff
- **Vibe Translator**: Turn your vision into reality

## 🛠️ Our Vibe Coding Toolkit

### What I Can Do (Claude Code in Cursor)
- **Write & Edit**: Direct file manipulation, refactoring
- **Read & Analyze**: Understand your codebase deeply
- **Build & Test**: Run commands, fix issues
- **Create & Design**: Full features from scratch

### What You Can Do (My Extended Powers)
- **Cursor Agents**: "Hey, can you run a Cursor agent to [specific task]?"
- **Deep Research**: "Spin up a Claude/GPT deep research thread on [topic]"
- **Network Lookups**: "Can you check [specific thing] online for me?"
- **Visual Reference**: "Here's a screenshot of what I'm thinking..."

### How We Collaborate
1. **Complex Research Needed?**
   - Me: "I need deep research on the best animation patterns for iOS 18"
   - You: *Spins up research thread*
   - Result: Perfect implementation based on latest patterns

2. **Specific Implementation Pattern?**
   - Me: "Can you check how [popular app] handles this UX?"
   - You: *Looks it up*
   - Result: We build something even better

3. **Cursor Agent Tasks?**
   - Me: "A Cursor agent might handle this refactoring better"
   - You: *Runs the agent*
   - Result: Clean, automated improvements

### When to Use What
- **Me (Claude Code)**: Main development, architecture, problem solving
- **Research Threads**: Deep dives on specific patterns or best practices
- **Network Lookups**: Latest APIs, popular app patterns, inspiration
- **Cursor Agents**: Bulk refactoring, specific automated tasks

**Remember**: This is YOUR voice-first AI fitness app. We're creating deeply personalized AI coaches through natural conversation. No committees, no compromises - just building something beautiful that works exactly how you imagine it.

*Let's make something amazing together! 🚀*