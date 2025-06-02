# Persona Refactor - Master Execution Guide

## 🎯 Mission
Replace the legacy 4-persona system with AI-synthesized, conversational onboarding that creates unique 2000+ token coach personas.

## 🏗️ Architecture Overview
```
Current State (Remove):
- 4 fixed personas (Authoritative, Encouraging, Analytical, Playful)
- Mathematical blending with imperceptible adjustments
- 600 token generic prompts

Target State (Build):
- Infinite unique personas via conversation
- Natural personality synthesis
- 2000+ token rich prompts
- Continuous evolution
```

## 📋 Implementation Phases

### Phase 1: Conversational Foundation ✅
**Duration**: 2 weeks
**Document**: `Phase1_ConversationalFoundation_ENHANCED.md`
**Key Deliverables**:
- Conversation engine with branching logic
- Multi-modal input system (text, voice, cards, sliders)
- Response analysis for personality extraction
- State persistence and resume capability

### Phase 2: AI Synthesis Pipeline ✅
**Duration**: 2 weeks
**Document**: `Phase2_PersonaSynthesis_ENHANCED.md`
**Key Deliverables**:
- LLM provider abstraction (OpenAI, Anthropic, Google)
- Personality extraction from conversations
- Persona synthesis algorithm
- Real-time preview generation
- System prompt builder (2000+ tokens)
- User adjustment interface

### Phase 3: Integration & Testing
**Duration**: 2 weeks
**Document**: `Phase3_IntegrationTesting.md`
**Key Deliverables**:
- Full app integration
- Migration from 4-persona system
- A/B testing framework
- Performance optimization

### Phase 4: Polish & Evolution
**Duration**: 2 weeks
**Document**: `Phase4_DocumentationPolish.md`
**Key Deliverables**:
- UI refinements
- Persona evolution system
- Analytics and metrics
- Documentation

## 🛠️ Technical Stack

### Core Technologies
- **Language**: Swift 6.0 with strict concurrency
- **UI**: SwiftUI (iOS 18.0+)
- **Data**: SwiftData for persistence
- **AI**: Multi-provider LLM integration
- **Voice**: Whisper for transcription

### Key Design Patterns
- **MVVM-C**: Model-View-ViewModel-Coordinator
- **Protocol-Oriented**: Heavy use of protocols for flexibility
- **Async/Await**: Modern concurrency throughout
- **Dependency Injection**: For testability

## 💻 Cursor Workflow

### 1. Session Setup
```bash
# Start each session
1. Open PERSONA_REFACTOR_EXECUTION_GUIDE.md
2. Open relevant Phase document
3. Check current batch progress
4. Load context with @codebase references
```

### 2. Implementation Flow
```bash
# For each task
1. Read task specification
2. Use Cmd+K to generate implementation
3. Run test command immediately
4. Fix any issues before proceeding
5. Commit after each checkpoint
```

### 3. Context Management
```bash
# Every 10-15 tasks
1. Complete current batch
2. Run full test suite
3. Commit all changes
4. Clear Cursor context
5. Start fresh with next batch
```

### 4. Multi-File Operations
```bash
# Use Cursor Composer (Cmd+K)
"Create the ConversationNode model and all related types according to the spec in Phase1_ConversationalFoundation_ENHANCED.md"

# Reference patterns
"@codebase Show me the existing ViewModel pattern used in the app"
```

## 📊 Progress Tracking

### Current Status
```yaml
Phase 1: Not Started
  Batch 1.1 (Core Models): 0/5 tasks
  Batch 1.2 (UI Components): 0/5 tasks
  Batch 1.3 (Flow Implementation): 0/5 tasks
  
Phase 2: Not Started
Phase 3: Not Started  
Phase 4: Not Started
```

### Git Branch Strategy
```bash
# Main refactor branch
git checkout -b persona-refactor

# Phase branches
git checkout -b persona-refactor-phase1
git checkout -b persona-refactor-phase2
# etc.

# Merge back to refactor branch after each phase
git checkout persona-refactor
git merge persona-refactor-phase1
```

## 🧪 Validation Checkpoints

### After Each Batch
1. Run targeted tests: `swift test --filter <BatchName>`
2. Check SwiftLint: `swiftlint --strict`
3. Verify no regressions: `xcodebuild test`

### After Each Phase
1. Full test suite
2. Manual testing of complete flow
3. Performance profiling
4. Memory leak detection
5. UI/UX review

### Before Production
1. A/B test with 10% of users
2. Monitor key metrics
3. Gradual rollout
4. Rollback plan ready

## 🚨 Critical Paths

### Must Preserve
1. **User data**: No loss during migration
2. **App stability**: Fallback to old system if needed
3. **Performance**: No degradation in response times

### Can Iterate On
1. UI polish
2. Animation timing
3. Question wording
4. Preview accuracy

## 📈 Success Metrics

### Technical Metrics
- Conversation completion rate > 85%
- Persona generation < 5 seconds
- Zero data loss during migration
- Test coverage > 85%

### User Metrics
- Satisfaction score > 4.5/5
- D7 retention improvement > 10%
- Reduced support tickets
- Positive app store reviews

## 🔧 Troubleshooting

### Common Issues

1. **SwiftData Predicate Errors**
   - Use #Predicate macro correctly
   - Avoid complex predicates
   - Test with in-memory store

2. **LLM Response Timeouts**
   - Implement proper retry logic
   - Add loading states
   - Cache partial results

3. **Memory Issues**
   - Profile with Instruments
   - Limit conversation history
   - Clean up old sessions

## 🎯 Daily Workflow

### Morning
1. Review progress from previous day
2. Check test suite status
3. Plan current batch
4. Load fresh context

### Implementation
1. Focus on one batch at a time
2. Test immediately after coding
3. Commit at checkpoints
4. Document any deviations

### Evening
1. Run full test suite
2. Update progress tracking
3. Push to remote
4. Plan next day

## 🏁 Definition of Done

### For Each Task
- [ ] Implementation complete
- [ ] Tests written and passing
- [ ] SwiftLint clean
- [ ] Documentation updated
- [ ] Committed to git

### For Each Phase
- [ ] All tasks complete
- [ ] Integration tests passing
- [ ] Manual testing passed
- [ ] Performance validated
- [ ] Stakeholder approval

---

*"Make it work, make it right, make it fast" - Kent Beck*

*This is not just a refactor - it's establishing the foundation for AI-native user experiences. Every decision should optimize for user delight and technical excellence.*