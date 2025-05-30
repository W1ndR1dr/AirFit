# AGENTS.md - Module 8: Food Tracking

## Module-Specific Instructions for Codex Agents

### **Critical Dependencies**
- **MUST USE**: Module 13's VoiceInputManager via FoodVoiceAdapter pattern
- **NO NEW**: WhisperKit implementations - use existing infrastructure
- **REQUIRED**: FoodEntry and FoodItem SwiftData models from Data layer

### **File Structure Requirements**
```
AirFit/Modules/FoodTracking/
├── Services/
│   ├── FoodVoiceAdapter.swift          # Adapter for Module 13 voice
│   ├── FoodVoiceServiceProtocol.swift  # Protocol abstraction
│   ├── NutritionService.swift          # Nutrition calculations
│   └── FoodDatabaseService.swift       # Food database integration
├── ViewModels/
│   └── FoodTrackingViewModel.swift     # @MainActor @Observable
├── Views/
│   ├── FoodLoggingView.swift           # Main interface
│   ├── VoiceInputView.swift            # Voice recording UI
│   ├── FoodConfirmationView.swift      # AI parsing confirmation
│   ├── PhotoInputView.swift            # Photo capture and meal recognition
│   ├── MacroRingsView.swift            # Swift Charts visualization
│   ├── WaterTrackingView.swift         # Water intake
│   └── NutritionSearchView.swift       # Food search
├── Coordinators/
│   └── FoodTrackingCoordinator.swift   # Navigation management
└── Tests/
    ├── FoodTrackingViewModelTests.swift
    ├── FoodVoiceAdapterTests.swift
    └── NutritionServiceTests.swift
```

### **Code Patterns to Follow**

#### **Voice Integration Pattern**
```swift
// ✅ CORRECT: Use adapter pattern
private let foodVoiceAdapter: FoodVoiceAdapter

// ❌ WRONG: Direct WhisperKit usage
private let whisperKitService: WhisperKitService
```

#### **ViewModel Pattern**
```swift
@MainActor
@Observable
final class FoodTrackingViewModel {
    private(set) var isLoading = false
    private let foodVoiceAdapter: FoodVoiceAdapter
    
    init(foodVoiceAdapter: FoodVoiceAdapter) {
        self.foodVoiceAdapter = foodVoiceAdapter
    }
}
```

#### **Service Protocol Pattern**
```swift
protocol NutritionServiceProtocol: Sendable {
    func calculateNutrition(from items: [FoodItem]) -> NutritionSummary
}
```

### **Testing Requirements**
- **Unit Tests**: All business logic must have 80%+ coverage
- **Mock Services**: Use protocol-based dependency injection
- **SwiftData Tests**: Use in-memory ModelContainer
- **Voice Tests**: Mock FoodVoiceAdapter, not VoiceInputManager

### **Performance Standards**
- Voice transcription: <2s latency
- AI food parsing: <5s response time
- UI animations: 60fps
- Memory usage: <100MB typical

### **Project.yml Updates**
When creating new files, ALWAYS add them to project.yml:

```yaml
# Add to AirFit target sources:
- AirFit/Modules/FoodTracking/Services/FoodVoiceAdapter.swift
- AirFit/Modules/FoodTracking/ViewModels/FoodTrackingViewModel.swift
- AirFit/Modules/FoodTracking/Views/FoodLoggingView.swift

# Add to AirFitTests target sources:
- AirFit/AirFitTests/FoodTracking/FoodTrackingViewModelTests.swift
```

### **Validation Commands**
Run these commands to verify your implementation:

```bash
# Swift 6 concurrency check
swift -frontend -typecheck YourFile.swift -target arm64-apple-ios18.0 -strict-concurrency=complete

# File structure verification
find AirFit/Modules/FoodTracking -name "*.swift" -type f

# Project inclusion check
grep -c "YourFileName" project.yml
```

### **Common Pitfalls to Avoid**
- ❌ Creating new WhisperKit implementations
- ❌ Direct VoiceInputManager usage (use adapter)
- ❌ Missing @MainActor on ViewModels
- ❌ Forgetting to update project.yml
- ❌ Not following protocol-oriented design
- ❌ Missing /// documentation on public APIs

### **Success Criteria**
- ✅ All files compile with Swift 6 strict concurrency
- ✅ Adapter pattern correctly wraps Module 13 voice
- ✅ ViewModels are @MainActor @Observable
- ✅ Services use protocol-based dependency injection
- ✅ All new files added to project.yml
- ✅ Code includes comprehensive documentation 