# Cleanup Documentation

Working directory for AirFit architecture cleanup and standardization efforts.

## 🔥 Active Work
- **FILE_NAMING_FIXES_PLAN.md** - Standardizing all file names (26 files total, 6 done, 20 remaining)
- **CLEANUP_TRACKER.md** - Overall cleanup progress tracking

## 📚 Key References  
- **PRESERVATION_GUIDE.md** - What NOT to delete/change (critical!)
- **ERROR_HANDLING_GUIDE.md** - Error handling patterns
- **BUILD_STATUS.md** - Current build status

## 📁 Organization
- **[../01_PHASES/](../01_PHASES/)** - Cleanup phase definitions
- **[../Archive/](../Archive/)** - Completed work (Phase 3 modules, old plans)

## 🎯 Current Status
- Phase 1: ✅ Critical fixes complete
- Phase 2: ✅ Service migration complete  
- Phase 3: ✅ Module standardization complete
- Phase 4: 🚧 File naming standardization (26 files - in progress)
- Phase 5: ⏳ Modern DI implementation (next)

## 🛠️ Key Commands
```bash
# After ANY file rename
xcodegen generate

# Build check
xcodebuild build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' -quiet
```