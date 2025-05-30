# Phase 3: Function Dispatcher Cleanup Refactor
## Prompt Chain for Sandboxed Codex Agents (No Xcode Access)

**Target Agent Environment:** Sandboxed Codex (No Xcode Available)  
**Execution Priority:** Phase 3 - Architectural cleanup after infrastructure foundation  
**Parent Document:** `Phase3_FunctionDispatcher_Refactor.md`

## Executive Summary

This phase eliminates unnecessary complexity in the 854-line `FunctionCallDispatcher` by replacing simple parsing functions with direct AI calls and cleaning up the mock service architecture. The core challenge is maintaining function calling ecosystem coherence while reducing complexity by 50%.

**Critical Success Factors:**
- **Hybrid AI Routing:** Intelligent decision between function calling vs direct AI
- **Function Chain Preservation:** Ensure AI retains ability to chain complex workflows  
- **Performance Improvement:** 3x faster execution for parsing tasks
- **Token Efficiency:** 90% reduction in function calling tokens for simple tasks
- **Code Reduction:** Target 854 → ~400 lines (50% reduction)

**Total Estimated Time:** 16-20 hours across 8 sequential tasks  
**Success Criteria:** Maintain 100% functionality while reducing complexity by 50%

---

## Task Execution Order & Parallelization

### 🔴 **SEQUENTIAL TASKS (Must run in order)**
1. **Task 3.1:** Codebase Analysis & Function Audit
2. **Task 3.2:** Implement Direct AI Methods in CoachEngine
3. **Task 3.3:** Create Intelligent Routing Logic
4. **Task 3.4:** Update CoachEngine with Hybrid Routing
5. **Task 3.5:** Remove Deprecated Functions from Dispatcher
6. **Task 3.6:** Clean Up Mock Services & Dependencies
7. **Task 3.8:** Final Integration & Audit

### 🟢 **PARALLELIZABLE TASKS (Can run after Task 3.6)**
- **Task 3.7a:** Unit Test Implementation
- **Task 3.7b:** Performance & Regression Testing

### **Critical Dependencies:**
- Tasks 3.1-3.6 must be completed sequentially due to architectural dependencies
- Task 3.7 can be split into parallel streams once core implementation is complete
- Task 3.8 requires all previous tasks to validate the complete refactor

---

## Task 3.1: Codebase Analysis & Function Audit
**Duration:** 3-4 hours  
**Dependencies:** None  
**Agent Focus:** Analysis and documentation

### Prompt

```markdown
You are a senior iOS engineer analyzing the AirFit function dispatcher system for a critical architectural refactor. Your task is to audit the 854-line FunctionCallDispatcher and identify exactly what can be simplified without breaking the function calling ecosystem.

## Primary Objective
Analyze the current FunctionCallDispatcher to identify functions suitable for migration to direct AI calls while preserving complex workflow capabilities.

## Key Files to Analyze
1. `AirFit/Modules/AI/Functions/FunctionCallDispatcher.swift` (854 lines - the main target)
2. `AirFit/Modules/AI/CoachEngine.swift` (function calling integration)
3. `AirFit/Modules/AI/Functions/` directory (all function implementations)
4. `AirFit/Modules/AI/Models/AIFunctionDefinition.swift` (function definitions)

## Analysis Requirements

### 1. Function Classification Audit
For each function in the dispatcher, document:
- **Function name and purpose**
- **Lines of code (implementation + helpers)**
- **Complexity level** (Simple Parsing / Complex Workflow / Mixed)
- **Dependencies** (what services it calls)
- **Token usage** (estimate based on function definition + arguments)
- **Migration feasibility** (High/Medium/Low for direct AI replacement)

### 2. Target Functions for Phase 3
Focus specifically on these two functions identified for migration:
- `parseAndLogComplexNutrition` - Should be ~120 lines of parsing logic
- `generateEducationalInsight` - Should be ~80 lines of content generation

For each target function, document:
- Current implementation approach and complexity
- All helper methods and dependencies
- Exact lines of code that would be removed
- Token overhead of current function calling approach
- How direct AI would simplify the implementation

### 3. Function Chaining Analysis
**CRITICAL:** Document how functions chain together in workflows:
- Which functions commonly get called in sequence
- How the AI currently chains function calls
- Which workflows would be broken by migrating specific functions
- How to preserve chaining capability with hybrid routing

### 4. Mock Service Analysis
Document the current mock service architecture:
- Which services have mock implementations
- Where mock services are injected in production
- Dependencies that can be cleaned up
- Impact of removing test code from production init

### 5. Intelligent Routing Strategy
Design the logic for deciding between function calling vs direct AI:
- Criteria for simple parsing (use direct AI)
- Criteria for complex workflows (use function calling)
- Context clues that indicate chaining is needed
- How to maintain ecosystem coherence

## Validation Commands
```bash
# Count lines in dispatcher
wc -l AirFit/Modules/AI/Functions/FunctionCallDispatcher.swift

# Find target functions
grep -n "parseAndLogComplexNutrition\|generateEducationalInsight" AirFit/Modules/AI/Functions/FunctionCallDispatcher.swift

# Analyze function definitions
find AirFit/Modules/AI/Functions -name "*.swift" -exec grep -l "FunctionDefinition" {} \;

# Check mock service usage
grep -r "Mock.*Service" AirFit/Modules/AI/ | grep -v Tests
```

## Deliverables
1. **Complete Function Audit:** Spreadsheet/table of all functions with migration feasibility
2. **Target Function Analysis:** Detailed breakdown of the 2 functions to migrate
3. **Chaining Workflow Map:** Documentation of how functions chain together
4. **Intelligent Routing Design:** Logic for hybrid function/direct AI decisions
5. **Migration Risk Assessment:** Potential issues and mitigation strategies

The analysis must provide clear justification for why specific functions can be safely migrated while preserving the function calling ecosystem for complex workflows.
```

---

## Task 3.2: Implement Direct AI Methods in CoachEngine
**Duration:** 4-5 hours  
**Dependencies:** Task 3.1 complete  
**Agent Focus:** Core direct AI implementation

### Prompt

```markdown
You are implementing direct AI methods in CoachEngine to replace the two target functions identified in Task 3.1: `parseAndLogComplexNutrition` and `generateEducationalInsight`.

## Primary Objective
Create optimized direct AI methods that provide equivalent functionality to the dispatcher functions but with 3x better performance and 90% token reduction.

## Implementation Requirements

### 1. Direct Nutrition Parsing Method
Create in `AirFit/Modules/AI/CoachEngine.swift`:

```swift
public func parseAndLogNutritionDirect(
    foodText: String,
    context: String,
    for user: User,
    conversationId: UUID
) async throws -> NutritionParseResult
```

**Requirements:**
- Use optimized prompts targeting ~200 tokens (vs ~800 in function calling)
- Include comprehensive JSON parsing with validation
- Implement intelligent fallback for parsing failures
- Target <2 seconds response time (vs 6+ seconds with dispatcher)
- Log performance metrics comparing to old function approach
- Handle multiple food items and complex descriptions

### 2. Direct Educational Content Method
Create in `AirFit/Modules/AI/CoachEngine.swift`:

```swift
public func generateEducationalContentDirect(
    topic: String,
    userContext: String,
    for user: User
) async throws -> EducationalContent
```

**Requirements:**
- Use context-aware prompts for personalized content
- Target ~150 tokens input (vs ~500 in function calling)
- Generate 200-400 word educational content
- Include user's fitness level and goals in personalization
- Maintain content quality equivalent to function-generated content

### 3. Error Handling & Validation
Implement comprehensive error handling:
- Custom error types for direct AI failures
- Validation of AI responses for completeness
- Fallback strategies when direct AI fails
- Detailed logging for debugging and monitoring

### 4. Performance Optimization
Optimize for speed and efficiency:
- Use appropriate temperature settings (0.1 for parsing, 0.7 for content)
- Implement response caching where appropriate
- Monitor token usage and response times
- Compare performance metrics with dispatcher approach

## Required Data Models
Create supporting models in `AirFit/Modules/AI/Models/`:

```swift
struct NutritionParseResult: Sendable {
    let items: [ParsedNutritionItem]
    let totalCalories: Double
    let confidence: Double
    let parseMethod: ParseMethod
}

struct EducationalContent: Sendable {
    let topic: String
    let content: String
    let personalizationLevel: Double
    let generatedAt: Date
}

enum ParseMethod: String, Sendable {
    case directAI = "direct_ai"
    case functionDispatcher = "function_dispatcher"
}
```

## Validation Commands
```bash
# Validate Swift syntax
swift -frontend -parse AirFit/Modules/AI/CoachEngine.swift

# Check for proper async/await usage
grep -E "async.*throws|await.*try" AirFit/Modules/AI/CoachEngine.swift

# Verify error handling
grep -E "do.*catch|throw.*Error" AirFit/Modules/AI/CoachEngine.swift || echo "⚠️ Missing error handling"

# Check logging implementation
grep "AppLogger" AirFit/Modules/AI/CoachEngine.swift || echo "⚠️ Missing performance logging"
```

## Deliverables
1. **Complete direct AI methods** with full implementation
2. **Supporting data models** for results and content
3. **Comprehensive error handling** with custom error types
4. **Performance logging** with detailed metrics
5. **JSON parsing utilities** for AI response validation

The implementation must demonstrate clear performance advantages while maintaining equivalent functionality to the dispatcher-based approach.
```

---

## Task 3.3: Create Intelligent Routing Logic
**Duration:** 2-3 hours  
**Dependencies:** Task 3.2 complete  
**Agent Focus:** Decision logic for hybrid routing

### Prompt

```markdown
You are implementing intelligent routing logic that decides whether to use function calling or direct AI based on user input and context. This is critical for maintaining function calling ecosystem coherence while gaining performance benefits.

## Primary Objective
Create sophisticated routing logic that preserves complex workflow capabilities while optimizing simple tasks for direct AI execution.

## Implementation Requirements

### 1. Context Analysis Engine
Create in `AirFit/Modules/AI/Routing/ContextAnalyzer.swift`:

```swift
struct ContextAnalyzer {
    
    /// Analyze user input and context to determine optimal processing method
    static func determineOptimalRoute(
        userInput: String,
        conversationHistory: [AIChatMessage],
        userState: UserContextSnapshot
    ) -> ProcessingRoute
    
    /// Check if input suggests a complex workflow requiring function chaining
    static func detectsComplexWorkflow(_ input: String, history: [AIChatMessage]) -> Bool
    
    /// Check if input is simple parsing suitable for direct AI
    static func detectsSimpleParsing(_ input: String) -> Bool
}

enum ProcessingRoute: String, Sendable {
    case functionCalling = "function_calling"
    case directAI = "direct_ai"
    case hybrid = "hybrid"
    
    var shouldUseFunctions: Bool {
        self == .functionCalling || self == .hybrid
    }
}
```

### 2. Routing Decision Logic
Implement sophisticated heuristics:

**Use Function Calling When:**
- User mentions planning, analysis, or multi-step processes
- Conversation history shows recent function usage (chaining context)
- Input contains workflow keywords ("plan my", "analyze my", "adjust based on")
- User requests complex goal setting or plan modifications

**Use Direct AI When:**
- Input is short (<100 characters) and action-oriented
- Contains simple parsing keywords ("ate", "had", "log", "track")
- No context suggesting workflow chaining
- Educational content requests with clear topic

**Hybrid Approach When:**
- Input could trigger follow-up function calls
- Context is ambiguous but leans toward simple task

### 3. Function Chain Preservation
Implement logic to maintain chaining capabilities:

```swift
struct ChainContext {
    let recentFunctions: [String]
    let chainProbability: Double
    let workflowActive: Bool
    
    /// Determine if current context suggests ongoing function chain
    func suggestsChaining() -> Bool {
        return recentFunctions.count > 0 && 
               chainProbability > 0.7 &&
               workflowActive
    }
}
```

### 4. Performance Monitoring
Add routing analytics:
- Track routing decisions and outcomes
- Monitor performance differences between routes
- Identify routing mistakes for refinement
- Log token usage and response times by route

## Validation Commands
```bash
# Verify routing logic compiles
swift -frontend -parse AirFit/Modules/AI/Routing/ContextAnalyzer.swift

# Check for comprehensive logic coverage
grep -E "detectsComplexWorkflow|detectsSimpleParsing" AirFit/Modules/AI/Routing/ContextAnalyzer.swift

# Validate decision tree completeness
grep -E "ProcessingRoute\." AirFit/Modules/AI/Routing/ContextAnalyzer.swift | wc -l
```

## Deliverables
1. **ContextAnalyzer implementation** with sophisticated routing logic
2. **ProcessingRoute enum** with clear decision criteria
3. **ChainContext tracking** for workflow preservation
4. **Routing analytics** for performance monitoring
5. **Decision tree documentation** explaining routing logic

The routing logic must be sophisticated enough to preserve function calling benefits while optimizing simple tasks for direct AI execution.
``` 