# Immediate Action Plan: AirFit Architecture Cleanup

## 🚨 Do TODAY (4-6 hours)

### 1. Prevent ConversationSession Crashes (30 min)
```swift
// In /AirFit/Data/Models/ConversationSession.swift
// Add these properties:
var completionPercentage: Double = 0.0
var extractedInsights: Data?
var responseType: String = ""
var processingTime: TimeInterval = 0.0
var currentNodeId: String? // Change from String to String?
```

### 2. Fix Force Cast in DependencyContainer (1 hour)
```swift
// Line 45 - Replace:
LLMOrchestrator(apiKeyManager: keyManager as! APIKeyManagementProtocol)

// With:
guard let apiKeyManagement = keyManager as? APIKeyManagementProtocol else {
    throw ServiceError.configurationError("Invalid API key manager type")
}
let orchestrator = await MainActor.run {
    LLMOrchestrator(apiKeyManager: apiKeyManagement)
}
```

### 3. Create Offline AI Service (1 hour)
Create `/AirFit/Services/AI/OfflineAIService.swift` to replace mock in production.

### 4. Remove SimpleMockAIService from Production (30 min)
- Move to test directory
- Update DependencyContainer to use OfflineAIService

### 5. Run Audit Script (15 min)
```bash
cd "/Users/Brian/Coding Projects/AirFit"
./Scripts/architecture_audit.sh
```

## 📋 Do THIS WEEK (2-3 days)

### 1. Implement WeatherKit (4 hours)
- Create new WeatherKitService
- Delete 467-line WeatherService.swift
- Remove API key requirements

### 2. Fix API Key Protocol Mess (2 hours)
- Keep only APIKeyManagementProtocol
- Delete duplicate definitions
- Update all references

### 3. Update CoachEngine to Modern Protocol (3 hours)
- Change from AIAPIServiceProtocol to AIServiceProtocol
- Remove deprecated implementations

### 4. Create AI Service Protocol Extensions (2 hours)
- Define missing methods properly
- Update FunctionCallDispatcher

## 📊 Tracking Progress

### Phase 1 Checklist (Critical Safety)
- [ ] ConversationSession properties added
- [ ] Force cast removed from DependencyContainer
- [ ] OfflineAIService created
- [ ] SimpleMockAIService moved to tests
- [ ] API key protocols consolidated
- [ ] Build passes without warnings

### Quick Wins Completed
- [ ] WeatherKit implemented (deletes 467 lines!)
- [ ] Deprecated AI services removed (5 files)
- [ ] CoachEngine updated to new protocol
- [ ] Audit script shows 0 critical issues

## 🎯 Success Metrics

### Before
- Force casts: 15+
- Mock services in production: 4
- Duplicate protocols: 3
- Lines of unnecessary code: 2000+

### After Week 1
- Force casts: 0
- Mock services in production: 0
- Duplicate protocols: 0
- Lines removed: 1500+

## 🛠 Useful Commands

```bash
# Find all force casts
grep -r "as!" --include="*.swift" AirFit/ | grep -v "AirFitTests"

# Find mock usage
grep -r "SimpleMockAIService" --include="*.swift" AirFit/

# Check for protocol duplicates
grep -h "protocol.*Protocol" AirFit/Core/Protocols/*.swift | sort | uniq -d

# Run tests after changes
swift test --filter AirFitTests.Core
swift test --filter AirFitTests.Services

# Regenerate project
xcodegen generate
```

## ⚡ Emergency Contacts

If you encounter issues:
1. Check `DEEP_ARCHITECTURE_ANALYSIS.md` for context
2. Refer to `CLEANUP_PHASE_1_CRITICAL_FIXES.md` for detailed steps
3. Run `./Scripts/architecture_audit.sh` to verify fixes

## 🔄 Daily Standup Template

```
Yesterday: Fixed [X] critical issues
- Added ConversationSession properties
- Removed [Y] force casts

Today: Working on [task]
- Implementing WeatherKit
- Consolidating protocols

Blockers:
- Need clarification on [specific issue]
```

Remember: Each fix makes the codebase more stable. Small, incremental changes with testing are better than large, risky refactors.