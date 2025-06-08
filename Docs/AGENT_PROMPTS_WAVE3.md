# Codex Agent Prompts - Wave 3: Integration & Advanced Features

## Instructions for Execution
1. Send each agent the AGENTS.md content as their system prompt
2. Then send their specific analysis prompt below
3. Each agent should output to the specified deliverable file

---

## Agent 11: Network & API Integration Analysis

**Deliverable**: `Docs/Research Reports/Network_Integration_Analysis.md`

```
Analyze all network and API integration patterns. Document:

1. Network Architecture:
   - NetworkClient implementation
   - Request/response patterns
   - Error handling
   - Retry logic

2. API Integrations:
   - AI provider APIs (OpenAI, Anthropic, Gemini)
   - Weather API
   - HealthKit queries
   - Future API plans

3. Security:
   - API key management
   - Keychain integration
   - Request authentication
   - Data encryption

4. Performance:
   - Request optimization
   - Caching strategies
   - Batch operations
   - Background transfers

5. Offline Support:
   - Offline capabilities
   - Data sync when online
   - Conflict resolution
   - Queue management

Document all external dependencies and integration points.
```

---

## Agent 12: Voice & Speech Integration Analysis

**Deliverable**: `Docs/Research Reports/Voice_Integration_Analysis.md`

```
Analyze the voice input and speech processing implementation. Document:

1. Voice Architecture:
   - VoiceInputManager design
   - WhisperKit integration
   - Model management
   - Performance optimization

2. Voice UI/UX:
   - Voice input views
   - Visual feedback
   - Error handling
   - Accessibility

3. Speech Processing:
   - Audio capture
   - Speech-to-text pipeline
   - Language support
   - Accuracy metrics

4. Integration Points:
   - Food tracking voice input
   - Conversational interactions
   - Voice commands
   - Future voice features

5. Performance:
   - Processing speed
   - Memory usage
   - Battery impact
   - Model optimization

Document the complete voice pipeline from input to action.
```

---

## Agent 13: HealthKit & Fitness Integration Analysis

**Deliverable**: `Docs/Research Reports/HealthKit_Integration_Analysis.md`

```
Analyze the HealthKit integration and fitness tracking implementation. Document:

1. HealthKit Architecture:
   - HealthKitManager implementation
   - Permission management
   - Data types used
   - Background delivery

2. Data Integration:
   - Nutrition data sync
   - Workout data sync
   - Health metrics tracking
   - Data priorities

3. Fitness Features:
   - Workout tracking
   - Exercise library
   - Performance analytics
   - Goal tracking

4. Sync Patterns:
   - Real-time sync
   - Batch sync
   - Conflict resolution
   - Data integrity

5. Privacy & Security:
   - Data permissions
   - User consent
   - Data minimization
   - Secure storage

Document all health data flows and privacy considerations.
```

---

## Agent 14: Performance & Optimization Analysis

**Deliverable**: `Docs/Research Reports/Performance_Analysis.md`

```
Analyze performance characteristics and optimizations. Document:

1. Performance Targets:
   - App launch time (<1.5s)
   - Transition smoothness (120fps)
   - Memory usage (<150MB)
   - Battery efficiency

2. Current Performance:
   - Measure key metrics
   - Identify bottlenecks
   - Memory leaks
   - CPU hotspots

3. Optimizations:
   - SwiftUI optimizations
   - Data query optimization
   - Image/asset optimization
   - Network optimization

4. Monitoring:
   - Performance tracking
   - Crash reporting
   - Analytics integration
   - User metrics

5. Future Improvements:
   - Identified optimization opportunities
   - Architecture improvements
   - Code refactoring needs
   - Technical debt

Include performance profiles and optimization recommendations.
```

---

## Agent 15: Configuration & Build System Analysis

**Deliverable**: `Docs/Research Reports/Build_Configuration_Analysis.md`

```
Analyze the build configuration and project setup. Document:

1. Project Configuration:
   - project.yml structure
   - XcodeGen usage
   - Target configuration
   - Build settings

2. File Management:
   - File inclusion patterns
   - XcodeGen nesting bug
   - Manual file additions
   - Verification scripts

3. Build Pipeline:
   - Build phases
   - Run scripts
   - Code generation
   - Asset processing

4. Environment Management:
   - Development vs production
   - Feature flags
   - Configuration files
   - Secrets management

5. CI/CD Readiness:
   - Build automation
   - Test automation
   - Deployment preparation
   - Release process

Document the complete build system and identify improvements.
```