# Persona Refactor Implementation Checklist

## 🚀 Start of Every Session

```bash
# 1. Check what's already built
cd /Users/Brian/Coding\ Projects/AirFit
ls -la AirFit/Modules/Onboarding/Models/ConversationModels.swift 2>/dev/null || echo "❌ Phase 1 not started"
ls -la AirFit/Modules/AI/PersonaSynthesis/PersonaSynthesizer.swift 2>/dev/null || echo "❌ Phase 2 not started"

# 2. Check existing persona-related code
grep -r "PersonaMode\|PersonaProfile" AirFit/Modules/AI/ --include="*.swift" | head -5

# 3. Verify project builds
xcodegen generate
xcodebuild clean build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' | tail -20

# 4. Check test status
xcodebuild test -scheme "AirFit" -only-testing:AirFitTests/Onboarding 2>&1 | grep -E "(Test Suite|passed|failed)"
```

## 🎯 Implementation Order

### Phase 1 Tasks (Start Here)
- [ ] Check if `OnboardingModels.swift` exists
- [ ] Implement `ConversationFlow` state machine
- [ ] Create `InterviewQuestion` models
- [ ] Build conversation UI in `OnboardingFlowView`
- [ ] Add voice/text input handling

### Phase 2 Tasks
- [ ] Create `PersonaSynthesizer.swift`
- [ ] Implement multi-LLM providers
- [ ] Build persona generation (<5s target)
- [ ] Add 2000+ token personality system
- [ ] Create fallback mechanisms

### Phase 3 Tasks
- [ ] Integrate conversation → persona flow
- [ ] Add SwiftData persistence
- [ ] Create preview during generation
- [ ] Polish animations/transitions
- [ ] Comprehensive testing

### Phase 4 Tasks
- [ ] Final UI polish
- [ ] Performance optimization
- [ ] Coach evolution system
- [ ] Production readiness

## ⚡ Quick Wins Pattern

When implementing any feature:
1. **Make it work** - Basic functionality
2. **Make it feel right** - Smooth animations, natural flow
3. **Make it beautiful** - Polish until delightful
4. **Make it fast** - Optimize only after it's perfect

## 🚨 Common Pitfalls to Avoid

1. **Don't over-engineer** - Start simple, iterate
2. **Don't create new files unnecessarily** - Check if it exists first
3. **Don't skip animations** - Every transition matters
4. **Don't rush** - Ship when proud, not when "done"
5. **Don't add bureaucracy** - No complex git flows or time tracking

## 🎨 Vibe Check Reminders

Before committing any code:
- Does this feel delightful to use?
- Would I want this in MY app?
- Is the code beautiful and clean?
- Did I maintain the conversational vibe?

## 📝 Session End Checklist

Before context ends:
- [ ] Update current_status.md with progress
- [ ] Commit with descriptive message
- [ ] Note any blockers or decisions needed
- [ ] Run tests to ensure nothing broke