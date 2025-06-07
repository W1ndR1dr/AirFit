# Cleanup Documentation

Working directory for AirFit architecture cleanup and standardization efforts.

## 🔥 Active Documents (Simplified)
- **CLEANUP_TRACKER.md** - Single source of truth for all progress and tasks
- **DI_MIGRATION_PLAN.md** - Detailed DI migration strategy (Phase 5)
- **ERROR_HANDLING_GUIDE.md** - Error handling patterns reference
- **PRESERVATION_GUIDE.md** - What NOT to delete/change (critical!)

## 📁 Organization
- **[../Phases/](../Phases/)** - Phase definitions (mostly complete)
- **[../Archive/](../Archive/)** - Completed work and historical docs

## 🎯 Current Priority
**HealthKit/WorkoutKit Integration** - Implementing core Apple ecosystem features before completing cleanup:
- `/Docs/HEALTHKIT_NUTRITION_INTEGRATION_PLAN.md`
- `/Docs/WORKOUTKIT_INTEGRATION_PLAN.md`

## ✅ Completed Phases
- Phase 1: Critical build fixes
- Phase 2: Service architecture migration
- Phase 3: Module standardization
- Phase 4: File naming standardization
- Phase 5: DI implementation (90% - paused for HealthKit work)

## 🛠️ Key Commands
```bash
# After ANY file changes
xcodegen generate

# Build check
xcodebuild build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'

# Run tests
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'
```