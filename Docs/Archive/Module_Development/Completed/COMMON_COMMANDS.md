# Persona Refactor - Common Commands Reference

## 🚀 Quick Start (Copy/Paste These)

### Session Start Commands
```bash
# Navigate to project
cd /Users/Brian/Coding\ Projects/AirFit

# Check current implementation status
ls -la AirFit/Modules/Onboarding/Models/ConversationModels.swift 2>/dev/null || echo "❌ Phase 1 not started"
ls -la AirFit/Modules/AI/PersonaSynthesis/PersonaSynthesizer.swift 2>/dev/null || echo "❌ Phase 2 not started"

# Generate and build
xcodegen generate && xcodebuild clean build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' | tail -20
```

### File Creation Pattern
```bash
# Create new file (example)
mkdir -p AirFit/Modules/Onboarding/Models
touch AirFit/Modules/Onboarding/Models/ConversationModels.swift

# Add to project.yml (CRITICAL!)
# Add under AirFit target sources section:
# - AirFit/Modules/Onboarding/Models/ConversationModels.swift

# Regenerate
xcodegen generate

# Verify
grep "ConversationModels" AirFit.xcodeproj/project.pbxproj || echo "❌ NOT ADDED TO PROJECT"
```

### Testing Commands
```bash
# Test specific module
xcodebuild test -scheme "AirFit" -only-testing:AirFitTests/Onboarding

# Test specific class
swift test --filter OnboardingViewModelTests

# Run with verbose output
xcodebuild test -scheme "AirFit" -only-testing:AirFitTests/Onboarding -quiet | grep -E "(Test Suite|passed|failed)"

# Quick SwiftLint check
swiftlint lint --path AirFit/Modules/Onboarding --strict
```

### Git Commands (Vibe Style)
```bash
# Quick status
git status -s

# Stage all changes
git add -A

# Commit with vibe
git commit -m "feat: Add conversational onboarding flow"
git commit -m "polish: Smooth conversation transitions"
git commit -m "vibe: Make persona generation feel magical"

# Check recent work
git log --oneline -10
```

### Debugging Commands
```bash
# Find where something is defined
grep -r "PersonaMode" AirFit/ --include="*.swift" | head -10

# Check if file exists anywhere
find AirFit -name "*Conversation*.swift" -type f

# See what's in a module
ls -la AirFit/Modules/Onboarding/**/*.swift

# Check imports in a file
grep "^import" AirFit/Modules/AI/PersonaEngine.swift

# Find todos
grep -r "TODO\|FIXME" AirFit/Modules/ --include="*.swift"
```

### Build Fix Commands
```bash
# Clean everything
rm -rf ~/Library/Developer/Xcode/DerivedData/AirFit-*
xcodegen generate
xcodebuild clean

# Fix "no such module" errors
xcodegen generate

# Verify all files in project
find AirFit -name "*.swift" | while read f; do 
  grep -q "$(basename $f)" AirFit.xcodeproj/project.pbxproj || echo "Missing: $f"
done
```

### Performance Checks
```bash
# Time the build
time xcodebuild build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' -quiet

# Check code size
find AirFit/Modules/Onboarding -name "*.swift" -exec wc -l {} + | sort -n

# Memory usage in tests
xcodebuild test -scheme "AirFit" -only-testing:AirFitTests/Onboarding -enableAddressSanitizer YES
```

## 🎯 Phase-Specific Commands

### Phase 1: Conversation Foundation
```bash
# Create conversation models
mkdir -p AirFit/Modules/Onboarding/Models
touch AirFit/Modules/Onboarding/Models/ConversationModels.swift

# Test conversation flow
swift test --filter ConversationFlowTests
```

### Phase 2: Persona Synthesis
```bash
# Create AI synthesis structure
mkdir -p AirFit/Modules/AI/PersonaSynthesis/LLMProviders
touch AirFit/Modules/AI/PersonaSynthesis/PersonaSynthesizer.swift

# Test synthesis performance
swift test --filter PersonaSynthesisTests --enable-code-coverage
```

### Phase 3: Integration
```bash
# Run integration tests
xcodebuild test -scheme "AirFit" -only-testing:AirFitTests/Integration

# Check SwiftData migrations
sqlite3 ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/Documents/AirFit.sqlite ".schema"
```

### Phase 4: Polish
```bash
# Profile in Instruments
xcodebuild build -scheme "AirFit" -configuration Release -derivedDataPath ./build
open ./build/Build/Products/Release-iphonesimulator/AirFit.app

# Check bundle size
du -sh ./build/Build/Products/Release-iphonesimulator/AirFit.app
```

## 💡 Pro Tips

1. **Always run `xcodegen generate` after adding files**
2. **Use `| tail -20` to see just the end of long outputs**
3. **Add `-quiet` to reduce build noise**
4. **Use `git add -p` for selective staging**
5. **Run SwiftLint before committing**

## 🚨 If Things Break

```bash
# Nuclear option - clean everything
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf .build
xcodegen generate
xcodebuild clean build -scheme "AirFit"

# Can't find simulator?
xcrun simctl list devices | grep "iPhone 16 Pro"

# Module not found?
grep "ModuleName" project.yml  # Check it's listed
xcodegen generate             # Regenerate project
```