# 🧹 AirFit Architecture Cleanup

## 🚨 Welcome, Cleanup Agent!
This folder contains everything you need. No need to search elsewhere.

**Current Task**: Fix JSON parsing force casts in PersonaSynthesizer  
**Why**: They WILL crash with malformed AI responses  
**Start**: Read `WORKING_GUIDE.md` for complete orientation

## 📁 This Is Your Workspace
Everything you need for the cleanup is in this folder - it's self-contained and ready to use.

```
Cleanup/
├── README.md              # Overview (you are here)
├── GUIDE_NAVIGATION.md    # 🚦 How to use this workspace
├── WORKING_GUIDE.md       # 📖 Complete working reference
├── QUICK_REFERENCE.md     # ⚡ Commands & paths cheat sheet
├── FILE_MAP.md            # 🗺️ Task → file location mapping
├── ACTION_PLAN.md         # 🎯 Today's specific tasks
├── CLEANUP_TRACKER.md     # 📊 Progress tracking
├── PRESERVATION_GUIDE.md  # 🛡️ DO NOT DELETE these components
├── 01_PHASES/             # 📋 Detailed implementation guides
│   ├── PHASE_1_CRITICAL_FIXES.md    # Force casts & crashes
│   ├── PHASE_2_SERVICE_MIGRATION.md  # WeatherKit & services
│   ├── PHASE_3_STANDARDIZATION.md    # 21 ObservableObject migrations
│   └── PHASE_4_FOUNDATION.md         # DI system & testing
└── 02_ARCHIVE/            # 📦 Historical reference only
```

### 🚀 Quick Start for Agents
1. Read `GUIDE_NAVIGATION.md` to understand this workspace
2. Check `ACTION_PLAN.md` for current task
3. Use `WORKING_GUIDE.md` as main reference
4. Keep `QUICK_REFERENCE.md` open for commands
5. Use `FILE_MAP.md` to find code locations

## 🗺️ The Plan

| Phase | What | Time | Status |
|-------|------|------|--------|
| **1** | Fix 9 force casts | 1 day | Ready to start |
| **2** | WeatherKit + services | 2-3 days | 10% done |
| **3** | Migrate 21 @ObservableObject | 14 days | Not started |
| **4** | Build DI + fix tests | 10 days | Not started |

**Total**: ~4-5 weeks (validated against actual codebase)

## 🎯 Top Priority Issues

1. **JSON parsing force casts** - PersonaSynthesizer will crash
2. **Test infrastructure** - Many tests reference deleted code  
3. **21 ObservableObject classes** - Not 13 as originally thought
4. **3 API key protocols** - Not 2, more complex migration
5. **DI system** - Needs building, not polish

## ✅ What's Working (DO NOT TOUCH)

- **PersonaSynthesis** - <3s generation time ✨
- **LLMOrchestrator** - Multi-provider AI
- **ProductionMonitor** - Excellent telemetry
- **Onboarding Flow** - Months of UX work

## 🛠️ Commands

```bash
# After ANY file changes (XcodeGen bug)
xcodegen generate

# Validate cleanup status
./Scripts/validate_cleanup_claims.sh

# Build & test
swift build
swift test
```

## ❓ FAQ

**Q: What if I break something?**  
A: Check PRESERVATION_GUIDE.md, use git revert

**Q: Why 4-5 weeks?**  
A: We validated against actual code - 21 classes to migrate, not 13

**Q: What's most dangerous?**  
A: JSON parsing force casts - they're production crashes waiting to happen

---
*Last validated: [Current date] - All phases checked against actual codebase*