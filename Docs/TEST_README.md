# AirFit Test Suite - Start Here

## 🎯 Current Mission
Transform the test suite from mixed patterns (~50% outdated) to 100% standardized, reliable tests.

## 📚 Essential Documents (Read in Order)

1. **[TEST_STANDARDS.md](./TEST_STANDARDS.md)** - MUST READ FIRST
   - All patterns and conventions
   - Mock templates
   - Naming rules
   - File locations

2. **[TEST_EXECUTION_PLAN.md](./TEST_EXECUTION_PLAN.md)** - Your Task List
   - Current progress: 3/156 tasks
   - Next task: Check Phase 1
   - Update after EVERY task

3. **[TEST_MIGRATION_GUIDE.md](./TEST_MIGRATION_GUIDE.md)** - How-To Reference
   - Step-by-step migration patterns
   - Before/after examples
   - Common issues and fixes

4. **[TEST_REFACTORING_PLAN.md](./TEST_REFACTORING_PLAN.md)** - Strategy Overview
   - Why we're doing this
   - Three-phase approach
   - Success criteria

## 🚦 Current Status
- **Phase**: 1 - Clean House (removing outdated tests)
- **Compilation Errors**: ~35 remaining
- **Tests Needing Migration**: ~37 files
- **Good Test Examples**: DIBootstrapperTests, HealthKitManagerTests

## 🎬 Quick Start Commands

```bash
# 1. See what's broken
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' 2>&1 | grep -E "error:"

# 2. Run a specific test
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' \
  -only-testing:"AirFitTests/UserServiceTests"

# 3. Check if a test exists
find . -name "*Tests.swift" | xargs grep -l "ClassName"

# 4. Find a mock
ls AirFit/AirFitTests/Mocks/Mock*.swift | grep "ServiceName"
```

## ⚡ Your First Task

1. Open **[TEST_EXECUTION_PLAN.md](./TEST_EXECUTION_PLAN.md)**
2. Find the first unchecked [ ] task in current phase
3. Mark it [🚧] to show you're working on it
4. Complete the task following TEST_STANDARDS.md
5. Mark it [✅] and update progress counts
6. Commit with message: `test: [action] [what] - [why if needed]`

## 🛡️ Golden Rules

1. **ONE task at a time** - Don't jump ahead
2. **Check before creating** - No duplicate tests/mocks
3. **Follow standards EXACTLY** - Consistency is critical
4. **Update progress immediately** - Others need to know
5. **Ask if unsure** - Better to clarify than guess

## 📈 Progress Snapshot

```
Phase 1: Clean House    [###-------] 3/23 tasks
Phase 2: Standardize    [----------] 0/89 tasks  
Phase 3: Fill Gaps      [----------] 0/44 tasks

Overall: 3/156 tasks (2%)
```

## 🆘 Common Issues Reference

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| "Cannot find type Mock..." | Mock not registered in DI | Add to DITestHelper |
| "Property is private" | Testing implementation | Test through public API |
| "Expression is async..." | Missing await | Add await or make method async |
| "@MainActor-isolated..." | Missing annotation | Add @MainActor to class |

## 🎖️ Definition of Done

A test is complete when:
- ✅ Compiles without warnings
- ✅ Passes reliably (run 3x)
- ✅ Uses DIContainer
- ✅ Follows all standards
- ✅ Task marked complete in plan
- ✅ Changes committed

---

**Remember**: We're building a test suite that will last. Take time to do it right.