# 🧹 AirFit Architecture Cleanup

## 🎯 Quick Start for New Developers

**Current Status**: Working on Phase 1 (Critical Fixes)  
**Next Task**: Fix force cast in DependencyContainer.swift line 45  
**Time Remaining**: ~2 hours for Phase 1, then move to Phase 2

### Your First Steps:
1. Read `00_CRITICAL/PRESERVATION_GUIDE.md` - Know what NOT to break
2. Check current task in the Status section below
3. Run verification commands after each change
4. Update this README when you complete a task

## 📊 Cleanup Status Dashboard

### Phase 1: Critical Fixes (90% Complete)
- [x] AI Service Protocol Migration
- [x] Removed deprecated AI services
- [ ] **🚨 Fix force cast in DependencyContainer:45** ← DO THIS FIRST
- [ ] Consolidate API key protocols
- [ ] Add missing ConversationSession properties

### Phase 2: Service Migration (40% Complete)
- [x] Mock services moved to tests
- [x] Default services created (Dashboard, HealthKit, User)
- [ ] WeatherKit integration
- [ ] Create DefaultWorkoutService
- [ ] CoachEngine decomposition

### Phase 3: Pattern Standardization (Not Started)
- [ ] Migrate ChatViewModel to @Observable
- [ ] Create OfflineAIService
- [ ] Extend AppError (don't replace)
- [ ] Document module boundaries

### Phase 4: DI Improvements (Not Started)
- [ ] Fix force cast (if not done in Phase 1)
- [ ] Create OfflineAIService (if not done in Phase 3)
- [ ] Document DI system
- [ ] Add health monitoring

## 🛠️ Essential Commands

```bash
# After ANY changes
xcodegen generate
swiftlint --strict

# Verify build
xcodebuild clean build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'

# Check for issues
grep -r "AIAPIServiceProtocol" AirFit/  # Should return nothing
grep -r "force try\|as!" AirFit/        # Find force casts
```

## 📁 Document Organization

```
Cleanup/
├── README.md (this file)
├── 00_CRITICAL/
│   └── PRESERVATION_GUIDE.md          # READ FIRST - What to preserve
├── 01_PHASES/
│   ├── PHASE_1_CRITICAL_FIXES.md     # Current phase
│   ├── PHASE_2_SERVICE_MIGRATION.md  
│   ├── PHASE_3_STANDARDIZATION.md    # Use revised version
│   └── PHASE_4_DI_IMPROVEMENTS.md    # Use revised version
└── 02_ARCHIVE/
    └── (Original analysis and deprecated docs)
```

## ❓ FAQ for New Developers

**Q: What's the most critical thing to know?**  
A: Don't delete anything in PersonaSynthesis, LLMOrchestrator, or modern AI services. Check PRESERVATION_GUIDE.md.

**Q: Why are we doing this cleanup?**  
A: Remove deprecated code, fix force casts, standardize patterns - but preserve working implementations.

**Q: How long should each phase take?**  
A: Phase 1: 2 hours, Phase 2: 1 day, Phase 3: 4 hours, Phase 4: 2 hours

**Q: What if I break something?**  
A: Git revert and check PRESERVATION_GUIDE.md. All critical code is documented there.

## 🚀 Next Actions

1. **If you're starting now**: Fix the force cast at DependencyContainer:45
2. **If Phase 1 is done**: Start WeatherKit integration in Phase 2
3. **If stuck**: The revised Phase 3 & 4 docs have simpler approaches

---
*Last updated: [Date] by [Your Name]*