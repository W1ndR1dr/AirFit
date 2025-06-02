# Persona Refactor - Codebase Context

## 🔍 Key Existing Files to Check

### Before Creating New Files, Always Check These:

```bash
# Onboarding Module - May have existing components
ls -la AirFit/Modules/Onboarding/Views/*.swift
ls -la AirFit/Modules/Onboarding/ViewModels/*.swift
ls -la AirFit/Modules/Onboarding/Models/*.swift

# AI Module - Has existing PersonaEngine
cat AirFit/Modules/AI/PersonaEngine.swift | head -50  # Check if it's old 4-persona system

# Chat Module - Conversation infrastructure exists
ls -la AirFit/Modules/Chat/ViewModels/ChatViewModel.swift
ls -la AirFit/Data/Models/ChatSession.swift
ls -la AirFit/Data/Models/ChatMessage.swift

# Existing AI Models
cat AirFit/Core/Models/AI/AIModels.swift
```

## 🏗️ Architecture Patterns to Follow

### ViewModels
```swift
@MainActor @Observable
final class OnboardingViewModel {
    // Always use @Observable, not ObservableObject
    // Always mark @MainActor
}
```

### Services
```swift
actor PersonaSynthesisService: PersonaSynthesisProtocol {
    // Use actors for thread-safe services
    // Always define protocols for testability
}
```

### Data Models
```swift
@Model
final class PersonaProfile {
    // SwiftData models use @Model
    // Include proper relationships
}
```

## 🔗 Key Dependencies

### Onboarding depends on:
- `Core/` - Extensions, constants, utilities
- `Data/` - SwiftData models
- `Services/AI/` - AI service protocols
- `Modules/AI/` - Persona generation

### AI Module structure:
```
Modules/AI/
├── PersonaEngine.swift (exists - check before modifying)
├── ConversationManager.swift (exists)
├── ContextAnalyzer.swift (exists)
└── PersonaSynthesis/ (create this)
    ├── PersonaSynthesizer.swift
    └── LLMProviders/
```

## 🎯 Integration Points

### Voice Input
- Already exists: `Core/Services/VoiceInputManager.swift`
- Already exists: `Core/Services/WhisperModelManager.swift`
- Use these, don't create new voice handling

### Chat Infrastructure
- Reuse: `ChatMessage`, `ChatSession` models
- Extend: `ChatViewModel` for onboarding conversation
- Don't duplicate chat UI components

### HealthKit
- Already authorized in existing onboarding
- Don't re-request permissions
- Use `Services/Health/HealthKitManager.swift`

## ⚠️ Watch Out For

1. **XcodeGen Requirement**
   - MUST add every new file to `project.yml`
   - Run `xcodegen generate` after adding files
   - Verify with: `grep "YourFile" AirFit.xcodeproj/project.pbxproj`

2. **SwiftLint Compliance**
   - Run `swiftlint --strict` before committing
   - Fix all violations immediately

3. **Test Naming**
   - Tests go in `AirFitTests/Onboarding/` etc.
   - Match production file structure

4. **Import Statements**
   ```swift
   import SwiftUI  // UI files
   import SwiftData  // Data models
   import Foundation  // Services
   // NO UIKit imports in new code
   ```

## 🚀 Quick Implementation Path

1. **Read existing PersonaEngine.swift** to understand current state
2. **Extend ChatViewModel** for conversation flow (don't create new)
3. **Create ConversationModels.swift** for new models
4. **Reuse existing UI components** where possible
5. **Add to project.yml** immediately after creating files

## 📋 File Creation Template

When creating any new file:
```bash
# 1. Create file
touch AirFit/Modules/Onboarding/Models/ConversationModels.swift

# 2. Immediately add to project.yml
echo "    - AirFit/Modules/Onboarding/Models/ConversationModels.swift" >> project.yml

# 3. Generate project
xcodegen generate

# 4. Verify inclusion
grep "ConversationModels.swift" AirFit.xcodeproj/project.pbxproj
```