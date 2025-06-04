# Cleanup Progress Tracker

## Overall Progress: ████░░░░░░░░░░░░ 5%

| Phase | Status | Progress | Critical Tasks | Time Est |
|-------|--------|----------|----------------|----------|
| **Phase 1** | 🟡 Active | 0% | Fix 9 force casts (JSON parsing highest risk) | 1 day |
| **Phase 2** | ⚪ Ready | 10% | WeatherKit, CoachEngine decomposition | 2-3 days |
| **Phase 3** | ⚪ Ready | 0% | Migrate 21 ObservableObject classes | 14 days |
| **Phase 4** | ⚪ Ready | 0% | Fix tests, build DI, add rollback | 10 days |

## 🔥 Critical Path (Do These First!)

1. **JSON parsing force casts in PersonaSynthesizer** - WILL crash with bad AI responses!
2. **Force cast in DependencyContainer:45** - Startup crash risk
3. **Test infrastructure** - Can't safely refactor without working tests
4. **SimpleMockAIService in production** - Replace with OfflineAIService

## ✅ Major Wins Already Completed

- Deleted AIAPIServiceProtocol.swift file (but references remain in tests)
- Moved mock services directory to test location
- Preserved critical PersonaSynthesis system (<3s generation!)

## ⚠️ Previously Marked Complete (But Actually Not)

- ❌ AIAPIServiceProtocol migration - Test mocks still use old protocol
- ❌ SimpleMockAIService removal - Still used as production fallback
- ❌ API key protocol consolidation - Both protocols still exist
- ❌ Force cast elimination - Critical one at line 45 remains

## 🚫 What NOT to Touch

- **PersonaSynthesis/** - Our crown jewel, <3s persona generation
- **LLMOrchestrator** - Multi-provider AI with fallback
- **ConversationFlowManager** - Months of UX refinement
- **FunctionCallDispatcher** - Clean AI function calling

## 📈 Metrics (Validated)

| Metric | Before | Current | Target |
|--------|--------|---------|--------|
| Force casts | Unknown | 9 | 0 |
| Mock services in prod | Unknown | 1 (SimpleMockAIService) | 0 |
| API protocols | Unknown | 3 duplicates | 1 |
| ObservableObject classes | Unknown | 21 | 0 |
| God objects (>1000 lines) | Unknown | 3 (CoachEngine, SettingsListView, PersonaEngineTests) | 0 |
| Singleton services | Unknown | 11 | 0 |

## 🎯 Definition of Done

Each phase is complete when:
- [ ] All tasks checked off
- [ ] Build succeeds with no warnings
- [ ] Tests pass
- [ ] No force casts introduced
- [ ] Preserved systems still work

## ✅ Validation Complete

All phases have been validated against actual codebase:
- **Phase 1**: 9 force casts confirmed, JSON parsing highest risk
- **Phase 2**: CoachEngine is 2350 lines, WeatherKit 0%, 11 singletons found
- **Phase 3**: 21 ObservableObject classes (not 13), 3 API protocols (not 2)
- **Phase 4**: DI system needs building (not polish), tests broken, ProductionMonitor excellent

## 📅 Realistic Timeline

- **Phase 1**: 1 day (critical safety fixes)
- **Phase 2**: 2-3 days (service migration)
- **Phase 3**: 14 days (pattern standardization) 
- **Phase 4**: 10 days (foundation building)
- **Total**: ~4-5 weeks (not 1.5-2 weeks)