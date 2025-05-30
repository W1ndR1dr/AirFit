# **🔥 AIRFIT MODULE 8.5 CRITICAL REFACTORING PROMPT CHAIN**
## **Architectural Reconstruction & Compilation Error Resolution**

Based on the comprehensive diagnostic audit revealing **47 critical compilation errors** and **23 architectural inconsistencies**, this prompt chain provides systematic reconstruction of Module 8's foundation to achieve production-ready, Carmack-level quality.

---

## **🚨 CRITICAL STATUS ASSESSMENT**

### **Current State: PRODUCTION-BLOCKING** ❌
- **Quality Assessment**: 30% (Significant architectural debt)
- **Compilation Status**: 47 critical errors preventing build
- **Architecture Status**: Fragmented type system, broken protocols
- **Priority**: P0 - Must fix before any further development

### **Root Cause Analysis** 🔍
1. **Type System Fragmentation**: Core types defined in docs but not implemented
2. **Protocol Mismatch**: Service protocols don't match implementations
3. **Model Inconsistency**: Property names and types misaligned across codebase
4. **Swift 6 Partial**: Concurrency requirements partially implemented

### **Refactoring Scope** 📊
- **47 Compilation Errors**: Catalogued and prioritized by impact
- **23 Architectural Issues**: Service layer gaps, data flow inconsistencies
- **5 Critical Types**: Missing or broken core type definitions
- **8+ Missing Methods**: Service protocol implementations incomplete

---

## **🔥 PRE-REFACTORING VERIFICATION CHECKLIST**

### **Environment Status** ✅
- [x] **Swift 6.0+**: Strict concurrency enabled
- [x] **iOS 18.0+**: Deployment target configured  
- [x] **Xcode 16.0+**: Required for iOS 18 SDK
- [x] **SwiftData**: Models exist but relationships broken
- [x] **Module Dependencies**: Modules 1-7, 13 completed
- [x] **Diagnostic Complete**: All 47 errors catalogued in Module8.5.md

### **Critical Issues Identified** ❌
- [x] **FoodDatabaseItem**: Referenced 23 times, defined 0 times
- [x] **FoodNutritionSummary**: Requires 11 parameters, initialized with 0
- [x] **VisionAnalysisResult**: Duplicate definitions causing redeclaration
- [x] **CoachEngine**: Doesn't conform to FoodCoachEngineProtocol
- [x] **NutritionService**: Missing 8 critical methods
- [x] **ParsedFoodItem**: Property mismatches (fiber vs fiberGrams)

### **Dependencies Ready** ✅
- [x] **Module 13**: VoiceInputManager foundation available
- [x] **Module 5**: CoachEngine exists but needs protocol conformance
- [x] **SwiftData Models**: FoodEntry, FoodItem exist but need fixes
- [x] **Project Structure**: All directories and base files present

---

## **🎯 REFACTORING STRATEGY OVERVIEW**

**Estimated Effort**: 16-20 hours of focused development  
**Implementation Approach**: Systematic, phase-by-phase reconstruction  
**Quality Target**: Zero compilation errors, production-ready architecture  

### **Phase Breakdown**
1. **Foundation Repair** (4-5h): Core type definitions and protocol fixes
2. **Service Reconstruction** (5-6h): Complete protocol implementations
3. **ViewModel Stabilization** (3-4h): Fix all compilation errors
4. **Swift 6 Compliance** (2-3h): Concurrency enforcement
5. **Integration & Testing** (2-3h): Build verification and validation

---

# **Module 8.5 Refactoring Task Prompts**

## **Phase 1: Foundation Repair (Sequential Execution Required)**

### **Task 8.5.1: Create Missing Core Types**
**Prompt:** "Create the missing FoodDatabaseItem type and supporting models that are referenced 23 times throughout the codebase but never defined. Implement complete type definitions with proper Sendable conformance and Swift 6 compatibility."

**Files to Create:**
- `AirFit/Modules/FoodTracking/Models/FoodDatabaseModels.swift`

**Critical Requirements:**
```swift
struct FoodDatabaseItem: Identifiable, Sendable {
    let id: String
    let name: String
    let brand: String?
    let caloriesPerServing: Double
    let proteinPerServing: Double
    let carbsPerServing: Double
    let fatPerServing: Double
    let servingSize: Double
    let servingUnit: String
    let defaultQuantity: Double
    let defaultUnit: String
    
    var servingDescription: String {
        "\(servingSize.formatted()) \(servingUnit)"
    }
}
```

**Acceptance Criteria:**
- [ ] FoodDatabaseItem fully defined with all required properties
- [ ] Sendable conformance for Swift 6 compatibility
- [ ] Computed properties for UI display
- [ ] Consistent with existing usage patterns in 23 reference locations
- [ ] Added to project.yml under AirFit target sources

**Dependencies:** None - foundational type
**Estimated Time:** 45 minutes

---

### **Task 8.5.2: Fix FoodNutritionSummary Initialization**
**Prompt:** "Fix the FoodNutritionSummary struct that currently requires 11 parameters but is being initialized with zero parameters throughout the codebase. Add default initializer while maintaining the full parameter constructor for explicit initialization."

**File to Update:** `AirFit/Modules/FoodTracking/Models/FoodTrackingModels.swift`

**Critical Fix:**
```swift
struct FoodNutritionSummary: Sendable {
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var fiber: Double = 0
    var sugar: Double = 0
    var sodium: Double = 0
    
    // Goals for comparison
    var calorieGoal: Double = 2000
    var proteinGoal: Double = 150
    var carbGoal: Double = 250
    var fatGoal: Double = 65
    
    init() {} // Default initializer - CRITICAL FIX
    
    init(calories: Double, protein: Double, carbs: Double, fat: Double, 
         fiber: Double, sugar: Double, sodium: Double,
         calorieGoal: Double, proteinGoal: Double, carbGoal: Double, fatGoal: Double) {
        // Full parameter constructor
    }
}
```

**Acceptance Criteria:**
- [ ] Default initializer `init()` added
- [ ] All existing full-parameter constructor preserved
- [ ] Zero compilation errors for `FoodNutritionSummary()` calls
- [ ] Sendable conformance maintained
- [ ] All ViewModel property initializations work

**Dependencies:** Task 8.5.1 completion
**Estimated Time:** 30 minutes

---

### **Task 8.5.3: Resolve VisionAnalysisResult Duplication**
**Prompt:** "Fix the duplicate VisionAnalysisResult definitions causing redeclaration errors. Remove the duplicate from PhotoInputView.swift and ensure single definition in FoodTrackingModels.swift with proper Sendable conformance."

**Files to Update:**
- `AirFit/Modules/FoodTracking/Views/PhotoInputView.swift` (remove duplicate)
- `AirFit/Modules/FoodTracking/Models/FoodTrackingModels.swift` (keep single definition)

**Critical Fix:**
```swift
// Keep ONLY in FoodTrackingModels.swift
struct VisionAnalysisResult: Sendable {
    let recognizedText: [String]
    let confidence: Float
}
```

**Acceptance Criteria:**
- [ ] Only one VisionAnalysisResult definition exists
- [ ] Proper Sendable conformance
- [ ] All references compile correctly
- [ ] PhotoInputView.swift duplicate removed
- [ ] Zero redeclaration errors

**Dependencies:** Task 8.5.2 completion
**Estimated Time:** 20 minutes

---

### **Task 8.5.4: Fix ParsedFoodItem Property Alignment**
**Prompt:** "Fix the ParsedFoodItem struct property mismatches where the ViewModel expects properties like 'fiber', 'sugar', 'sodium', 'barcode' but the struct defines 'fiberGrams', 'sugarGrams', 'sodiumMilligrams'. Align all property names consistently."

**File to Update:** `AirFit/Modules/FoodTracking/Models/FoodTrackingModels.swift`

**Critical Fix:**
```swift
struct ParsedFoodItem: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let brand: String?
    let quantity: Double
    let unit: String
    let calories: Double
    let proteinGrams: Double
    let carbGrams: Double
    let fatGrams: Double
    let fiberGrams: Double?
    let sugarGrams: Double?
    let sodiumMilligrams: Double?
    let barcode: String?
    let databaseId: String?
    let confidence: Float
    
    // Computed properties for backward compatibility
    var fiber: Double? { fiberGrams }
    var sugar: Double? { sugarGrams }
    var sodium: Double? { sodiumMilligrams }
}
```

**Acceptance Criteria:**
- [ ] All property names align with ViewModel usage
- [ ] Backward compatibility maintained with computed properties
- [ ] Sendable conformance preserved
- [ ] All ViewModel property access compiles
- [ ] Consistent naming convention throughout

**Dependencies:** Task 8.5.3 completion
**Estimated Time:** 40 minutes

---

### **Task 8.5.5: Fix TimeoutError and Supporting Types**
**Prompt:** "Fix the TimeoutError struct that's missing required parameters and create any other missing supporting types like NutritionContext, MealPhotoAnalysisResult that are referenced but not defined."

**Files to Update/Create:**
- `AirFit/Modules/FoodTracking/Models/FoodTrackingModels.swift`

**Critical Fixes:**
```swift
struct TimeoutError: Error, LocalizedError, Sendable {
    let operation: String
    let timeoutDuration: TimeInterval
    
    var errorDescription: String? {
        "Operation '\(operation)' timed out after \(timeoutDuration) seconds"
    }
}

struct NutritionContext: Sendable {
    let userPreferences: NutritionPreferences?
    let recentMeals: [FoodItem]
    let timeOfDay: Date
}

struct MealPhotoAnalysisResult: Sendable {
    let items: [ParsedFoodItem]
    let confidence: Float
    let processingTime: TimeInterval
}
```

**Acceptance Criteria:**
- [ ] TimeoutError has required parameters
- [ ] All missing supporting types defined
- [ ] Proper error handling with LocalizedError
- [ ] Sendable conformance for all types
- [ ] Zero "cannot find type" errors

**Dependencies:** Task 8.5.4 completion
**Estimated Time:** 35 minutes

---

## **Phase 2: Service Layer Reconstruction (Sequential Execution Required)**

### **Task 8.5.6: Complete NutritionServiceProtocol**
**Prompt:** "Expand the NutritionServiceProtocol to include all 8 missing methods that the ViewModel expects but aren't defined in the protocol. Update the protocol and implement all methods in NutritionService."

**Files to Update:**
- `AirFit/Modules/FoodTracking/Services/NutritionServiceProtocol.swift`
- `AirFit/Modules/FoodTracking/Services/NutritionService.swift`

**Critical Protocol Expansion:**
```swift
protocol NutritionServiceProtocol: Sendable {
    // Existing methods
    func saveFoodEntry(_ entry: FoodEntry) async throws
    func getFoodEntries(for date: Date) async throws -> [FoodEntry]
    func deleteFoodEntry(_ entry: FoodEntry) async throws
    
    // Missing methods that ViewModel expects
    func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry]
    func calculateNutritionSummary(from entries: [FoodEntry]) -> FoodNutritionSummary
    func getWaterIntake(for user: User, date: Date) async throws -> Double
    func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem]
    func logWaterIntake(for user: User, amountML: Double, date: Date) async throws
    func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry]
    func getTargets(from profile: OnboardingProfile) -> NutritionTargets
}
```

**Acceptance Criteria:**
- [ ] All 8 missing methods added to protocol
- [ ] Complete implementation in NutritionService
- [ ] Proper async/throws patterns
- [ ] Sendable conformance maintained
- [ ] All ViewModel service calls compile

**Dependencies:** Phase 1 completion
**Estimated Time:** 90 minutes

---

### **Task 8.5.7: Complete FoodDatabaseServiceProtocol**
**Prompt:** "Add the missing methods to FoodDatabaseServiceProtocol that are referenced in the ViewModel but not defined in the protocol. Implement searchCommonFood, lookupBarcode, and other missing methods."

**Files to Update:**
- `AirFit/Modules/FoodTracking/Services/FoodDatabaseServiceProtocol.swift`
- `AirFit/Modules/FoodTracking/Services/FoodDatabaseService.swift`

**Critical Protocol Expansion:**
```swift
protocol FoodDatabaseServiceProtocol: Sendable {
    func searchFoods(query: String) async throws -> [FoodSearchResult]
    func getFoodDetails(id: String) async throws -> FoodSearchResult?
    
    // Missing methods
    func searchFoods(query: String, limit: Int) async throws -> [FoodDatabaseItem]
    func searchCommonFood(_ name: String) async throws -> FoodDatabaseItem?
    func lookupBarcode(_ barcode: String) async throws -> FoodDatabaseItem?
    func analyzePhotoForFoods(_ image: UIImage) async throws -> [FoodDatabaseItem]
}
```

**Acceptance Criteria:**
- [ ] All missing methods added to protocol
- [ ] Complete implementation in FoodDatabaseService
- [ ] Proper return types matching ViewModel expectations
- [ ] Mock data for development/testing
- [ ] All ViewModel database calls compile

**Dependencies:** Task 8.5.6 completion
**Estimated Time:** 75 minutes

---

### **Task 8.5.8: Fix CoachEngine Protocol Conformance**
**Prompt:** "Make CoachEngine conform to FoodCoachEngineProtocol by adding the missing analyzeMealPhoto method and ensuring proper Sendable conformance. Update the protocol to be Sendable and implement all required methods."

**Files to Update:**
- `AirFit/Modules/FoodTracking/ViewModels/FoodTrackingViewModel.swift` (protocol definition)
- `AirFit/Services/AI/CoachEngine.swift` (add conformance)

**Critical Protocol Fix:**
```swift
protocol FoodCoachEngineProtocol: Sendable {
    func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue]
    func executeFunction(_ functionCall: AIFunctionCall, for user: User) async throws -> FunctionExecutionResult
    func analyzeMealPhoto(image: UIImage, context: NutritionContext?) async throws -> MealPhotoAnalysisResult
}

extension CoachEngine: FoodCoachEngineProtocol {
    func analyzeMealPhoto(image: UIImage, context: NutritionContext?) async throws -> MealPhotoAnalysisResult {
        // Implementation using existing AI infrastructure
    }
}
```

**Acceptance Criteria:**
- [ ] FoodCoachEngineProtocol marked as Sendable
- [ ] CoachEngine conforms to protocol
- [ ] analyzeMealPhoto method implemented
- [ ] No protocol conformance errors
- [ ] All ViewModel coachEngine calls compile

**Dependencies:** Task 8.5.7 completion
**Estimated Time:** 60 minutes

---

## **Phase 3: ViewModel Stabilization (Sequential Execution Required)**

### **Task 8.5.9: Fix ViewModel Property Initializations**
**Prompt:** "Fix all ViewModel property initialization errors by updating property declarations to use the new default initializers and correct types. Resolve all 'missing arguments' and 'cannot find type' errors."

**File to Update:** `AirFit/Modules/FoodTracking/ViewModels/FoodTrackingViewModel.swift`

**Critical Fixes:**
```swift
// Fix property initializations
private(set) var todaysNutrition = FoodNutritionSummary() // Now has default init
private(set) var searchResults: [FoodDatabaseItem] = [] // Type now exists

// Fix User initialization
let user = User(
    id: UUID(),
    createdAt: Date(),
    lastActiveAt: Date(),
    email: "test@example.com",
    name: "Test User",
    preferredUnits: "metric" // String, not enum
)
```

**Acceptance Criteria:**
- [ ] All property initializations compile
- [ ] Correct types used for all properties
- [ ] Default initializers work properly
- [ ] No 'missing arguments' errors
- [ ] No 'cannot find type' errors

**Dependencies:** Phase 2 completion
**Estimated Time:** 45 minutes

---

### **Task 8.5.10: Fix Service Method Calls**
**Prompt:** "Update all service method calls in the ViewModel to match the corrected protocol signatures. Fix parameter mismatches, add missing parameters, and ensure proper async/await patterns."

**File to Update:** `AirFit/Modules/FoodTracking/ViewModels/FoodTrackingViewModel.swift`

**Critical Fixes:**
```swift
// Fix service calls to match protocol signatures
todaysFoodEntries = try await nutritionService?.getFoodEntries(for: user, date: currentDate) ?? []

// Fix nutrition summary calculation
todaysNutrition = nutritionService?.calculateNutritionSummary(from: todaysFoodEntries) ?? FoodNutritionSummary()

// Fix water intake call
waterIntakeML = try await nutritionService?.getWaterIntake(for: user, date: currentDate) ?? 0
```

**Acceptance Criteria:**
- [ ] All service calls match protocol signatures
- [ ] Proper parameter passing
- [ ] Correct async/await usage
- [ ] No 'extra argument' or 'missing argument' errors
- [ ] Proper error handling maintained

**Dependencies:** Task 8.5.9 completion
**Estimated Time:** 60 minutes

---

### **Task 8.5.11: Fix Error Types and Handling**
**Prompt:** "Add the missing FoodTrackingError cases that are referenced in the ViewModel but not defined. Implement proper error handling with user-friendly messages and Swift 6 compliance."

**File to Update:** `AirFit/Modules/FoodTracking/Models/FoodTrackingModels.swift`

**Critical Error Type Expansion:**
```swift
enum FoodTrackingError: Error, LocalizedError {
    case saveFailed
    case networkError
    case voiceRecognitionFailed
    case aiProcessingFailed(suggestion: String)
    case aiProcessingTimeout
    case noFoodsDetected
    case photoAnalysisFailed
    
    var errorDescription: String? {
        switch self {
        case .saveFailed: return "Failed to save food entry"
        case .networkError: return "Network connection error"
        case .voiceRecognitionFailed: return "Voice recognition failed"
        case .aiProcessingFailed(let suggestion): return "AI processing failed. \(suggestion)"
        case .aiProcessingTimeout: return "AI processing timed out"
        case .noFoodsDetected: return "No food items detected"
        case .photoAnalysisFailed: return "Photo analysis failed"
        }
    }
}
```

**Acceptance Criteria:**
- [ ] All missing error cases defined
- [ ] LocalizedError conformance
- [ ] User-friendly error messages
- [ ] No 'type has no member' errors
- [ ] Proper error propagation

**Dependencies:** Task 8.5.10 completion
**Estimated Time:** 30 minutes

---

## **Phase 4: Swift 6 Compliance (Sequential Execution Required)**

### **Task 8.5.12: Add Sendable Conformance**
**Prompt:** "Add Sendable conformance to all protocols and types that cross actor boundaries. Fix all 'non-sendable type' errors by ensuring proper Sendable conformance throughout the codebase."

**Files to Update:**
- All protocol files
- All model files
- ViewModel files

**Critical Sendable Fixes:**
```swift
protocol FoodCoachEngineProtocol: Sendable { ... }
protocol NutritionServiceProtocol: Sendable { ... }
protocol FoodDatabaseServiceProtocol: Sendable { ... }

// Ensure all models are Sendable
struct ParsedFoodItem: Identifiable, Sendable { ... }
struct FoodNutritionSummary: Sendable { ... }
struct VisionAnalysisResult: Sendable { ... }
```

**Acceptance Criteria:**
- [ ] All protocols marked as Sendable
- [ ] All models conform to Sendable
- [ ] No 'non-sendable type' errors
- [ ] Proper actor isolation maintained
- [ ] Swift 6 concurrency compliance

**Dependencies:** Phase 3 completion
**Estimated Time:** 45 minutes

---

### **Task 8.5.13: Fix Actor Isolation**
**Prompt:** "Fix all actor isolation issues in the ViewModel by ensuring proper async/await patterns for cross-actor calls. Use withCheckedContinuation where needed for complex async operations."

**File to Update:** `AirFit/Modules/FoodTracking/ViewModels/FoodTrackingViewModel.swift`

**Critical Actor Isolation Fixes:**
```swift
// Fix coachEngine calls with proper isolation
private func processAIResult() async {
    let result = try await withTimeout(seconds: 8.0) { [self] in
        try await self.coachEngine.executeFunction(functionCall, for: self.user)
    }
}
```

**Acceptance Criteria:**
- [ ] All cross-actor calls properly isolated
- [ ] No actor isolation warnings
- [ ] Proper async/await patterns
- [ ] withCheckedContinuation used where appropriate
- [ ] MainActor isolation maintained for UI updates

**Dependencies:** Task 8.5.12 completion
**Estimated Time:** 40 minutes

---

## **Phase 5: Integration & Testing (Sequential Execution Required)**

### **Task 8.5.14: Update Project Configuration**
**Prompt:** "Update project.yml to include all new files created during refactoring. Ensure proper target assignment and verify XcodeGen file inclusion for all new models and services."

**File to Update:** `project.yml`

**Critical Configuration Updates:**
```yaml
# Add to AirFit target sources
- AirFit/Modules/FoodTracking/Models/FoodDatabaseModels.swift
- AirFit/Modules/FoodTracking/Models/FoodTrackingModels.swift (updated)
- AirFit/Modules/FoodTracking/Services/NutritionServiceProtocol.swift (updated)
- AirFit/Modules/FoodTracking/Services/FoodDatabaseServiceProtocol.swift (updated)
```

**Acceptance Criteria:**
- [ ] All new files added to project.yml
- [ ] Proper target assignment (AirFit, AirFitTests, AirFitUITests)
- [ ] XcodeGen file inclusion verified
- [ ] No missing file references
- [ ] Project regeneration successful

**Dependencies:** Phase 4 completion
**Estimated Time:** 25 minutes

---

### **Task 8.5.15: Create Comprehensive Preview Services**
**Prompt:** "Create complete preview service implementations that conform to all updated protocols. Ensure all SwiftUI previews work with proper mock data and no compilation errors."

**Files to Update:**
- All view files with previews
- Create comprehensive preview services

**Critical Preview Services:**
```swift
final class PreviewNutritionService: NutritionServiceProtocol {
    // Implement ALL protocol methods with mock data
}

final class PreviewFoodDatabaseService: FoodDatabaseServiceProtocol {
    // Implement ALL protocol methods with mock data
}

final class PreviewCoachEngine: FoodCoachEngineProtocol {
    // Implement ALL protocol methods with mock responses
}
```

**Acceptance Criteria:**
- [ ] All preview services implement complete protocols
- [ ] All SwiftUI previews compile and render
- [ ] Mock data provides realistic preview experience
- [ ] No preview compilation errors
- [ ] Proper dependency injection in previews

**Dependencies:** Task 8.5.14 completion
**Estimated Time:** 50 minutes

---

### **Task 8.5.16: Comprehensive Build Verification**
**Prompt:** "Perform comprehensive build verification to ensure zero compilation errors, all tests pass, and the refactored architecture is production-ready. Document any remaining issues and create validation report."

**Verification Steps:**
1. Clean build test
2. Unit test execution
3. UI test execution
4. SwiftLint compliance check
5. Performance validation

**Critical Verification Commands:**
```bash
# Clean build test
xcodebuild clean build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'

# Unit test verification
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' -only-testing:AirFitTests/FoodTrackingTests

# SwiftLint compliance
swiftlint --strict
```

**Acceptance Criteria:**
- [ ] Zero compilation errors
- [ ] Zero warnings in strict mode
- [ ] All unit tests passing
- [ ] All UI tests passing
- [ ] SwiftLint compliance achieved
- [ ] Performance targets met
- [ ] Architecture quality validated

**Dependencies:** Task 8.5.15 completion
**Estimated Time:** 45 minutes

---

## **🎯 SUCCESS CRITERIA & VALIDATION**

### **Build Quality Metrics**
- [ ] **Zero Compilation Errors**: Complete elimination of all 47 identified errors
- [ ] **Zero Warnings**: Strict mode compliance with no warnings
- [ ] **Test Coverage**: All existing tests pass, new tests for refactored components
- [ ] **SwiftLint Compliance**: 100% adherence to coding standards

### **Architecture Quality Metrics**
- [ ] **Protocol Conformance**: Complete implementation of all service protocols
- [ ] **Type System Integrity**: Consistent type definitions across codebase
- [ ] **Swift 6 Compliance**: Full concurrency compliance with Sendable conformance
- [ ] **Error Handling**: Comprehensive error handling with user-friendly messages

### **Integration Quality Metrics**
- [ ] **View Compilation**: All SwiftUI views compile and render correctly
- [ ] **Navigation Flows**: End-to-end navigation works seamlessly
- [ ] **Data Persistence**: SwiftData operations function correctly
- [ ] **AI Integration**: CoachEngine integration responds appropriately

### **Performance Validation**
- [ ] **Voice Transcription**: <3s target maintained
- [ ] **AI Parsing**: <7s target maintained
- [ ] **Photo Analysis**: <10s target maintained
- [ ] **Database Queries**: <50ms target maintained

---

## **🚀 EXECUTION GUIDELINES**

### **Sequential Execution Required**
- **Phases must be completed in order** - each phase builds on the previous
- **Tasks within phases must be sequential** - dependencies are critical
- **Verification at each step** - compile and test after each major change
- **Rollback plan ready** - maintain clean git history for quick rollbacks

### **Quality Checkpoints**
- **After Phase 1**: All core types compile, no missing type errors
- **After Phase 2**: All service protocols complete, no missing method errors
- **After Phase 3**: ViewModel compiles completely, no property errors
- **After Phase 4**: Full Swift 6 compliance, no concurrency errors
- **After Phase 5**: Production-ready build, all tests passing

### **Risk Mitigation**
- **Incremental Builds**: Test compilation after each task
- **Mock Services**: Use comprehensive mocks to isolate integration issues
- **Dependency Tracking**: Ensure all dependencies are met before proceeding
- **Documentation**: Update documentation as changes are made

---

**This refactoring prompt chain represents a complete architectural reconstruction roadmap. The estimated 16-20 hours reflects the systematic approach needed to transform Module 8 from 30% quality to production-ready, Carmack-level implementation.**

**Execute phases sequentially. No shortcuts. No compromises. Production excellence is the only acceptable outcome. 🔥** 