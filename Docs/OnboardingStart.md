 🚀 Agent Implementation Preparation Checklist

  📋 Core Documents to Review

  1. Primary Spec: Docs/ONBOARDING_ENHANCEMENT.md - Complete onboarding design
  2. UI Overhaul Guide: Docs/o3uiconsult.md - Pending Adaline.ai-inspired UI transformation
  3. Codebase Context: CLAUDE.md - Project standards and architecture

  ⚠️ IMPORTANT: UI Design Context

  The app has two UI standards documents:
  - `Docs/Development-Standards/UI_STANDARDS.md` - Current production UI standards
  - `Docs/o3uiconsult.md` - Future UI transformation plan (Adaline.ai-inspired)

  The onboarding enhancement should follow the FUTURE patterns from o3uiconsult.md:
  - Remove GlassCard → Replace with GlassSheet (4pt blur) or no cards at all
  - Gradient Evolution → Each screen advances the gradient
  - ChapterTransition → Cinematic navigation transitions (0.55s)
  - Text directly on gradients → No card containers unless contrast requires it
  - CascadeText animations → 0.6s total, 0.012s per character stagger

  🏗️ Current Architecture

  - API Key Setup: Handled by InitialAPISetupView (BEFORE onboarding)
  - Existing Onboarding: Located in AirFit/Modules/Onboarding/
  - Coordinator: OnboardingFlowCoordinator already exists (needs updating)
  - DI System: Use DIContainer and DIViewModelFactory
  - Services: APIKeyManager (Keychain), LLMOrchestrator, PersonaService
  - Flow Control: AppState manages needsAPISetup → shouldShowOnboarding sequence

  🎨 Design Components Available

  - CascadeText - Animated text component
  - GlassCard - Being phased out, use sparingly
  - BaseScreen - Standard screen wrapper with gradient
  - GradientManager - For gradient evolution
  - HapticService - For feedback
  - AppSpacing - Consistent spacing tokens

  🔧 Implementation Priorities

  Phase 1: Core Infrastructure

  1. Update OnboardingFlowCoordinator for new flow (API key already handled)
  2. Enhance existing InitialAPISetupView with o3 UI patterns
  3. Implement gradient evolution between screens
  4. Add state machine for onboarding progress

  Phase 2: Screen Implementation

  Following the exact flow in ONBOARDING_ENHANCEMENT.md:
  1. Opening screen with CascadeText (API key already set up)
  2. HealthKit authorization with data preview
  3. Life context collection (text input)
  4. Goals progressive disclosure
  5. Communication style selection
  6. LLM synthesis visualization
  7. Coach profile ready

  Phase 3: Integration

  - Connect to LLMOrchestrator for API validation
  - Use HealthKitManager for data prefilling
  - Implement PersonaSynthesisService integration
  - Add fallback paths for edge cases

  🚨 Key Requirements

  1. API Setup First - InitialAPISetupView handles provider selection + key validation
  2. Real-time validation - Format checking + actual connection test (in InitialAPISetupView)
  3. Graceful degradation - Handle no HealthKit, no network (API key is required)
  4. Zero crashes - Fix the current onboarding crash on "Begin"
  5. Beautiful transitions - Follow ChapterTransition pattern from o3uiconsult.md
  6. Gradient Evolution - Each onboarding screen advances the gradient

  📝 Testing Approach

  - Unit tests for state machine and validation
  - Integration tests for API key validation
  - UI tests for complete flow
  - Edge case testing (no network, invalid keys, etc.)

  🎯 Success Criteria

  - Onboarding completes without crashes
  - API key validation works for all 3 providers
  - HealthKit data enriches the experience
  - LLM synthesis creates personalized coach
  - User never feels rushed or confused
  - Beautiful, cinematic transitions throughout

  💡 Implementation Notes

  1. API key setup is handled BEFORE onboarding via InitialAPISetupView
  2. The app currently uses a complex conversational onboarding that's broken
  3. We're replacing it with the streamlined flow in ONBOARDING_ENHANCEMENT.md
  4. Keep the existing PersonaService but update the flow
  5. The UI should feel like Adaline.ai but with pastel gradients (see o3uiconsult.md)
  6. Text sits directly on gradients, minimal use of cards (GlassSheet only when needed)
  7. Every screen should have a single focal point
  8. Apply ChapterTransition between all screens for cinematic feel

  🔐 Security Note

  API keys are securely stored in iOS Keychain with:
  - Hardware encryption
  - kSecAttrAccessibleWhenUnlockedThisDeviceOnly
  - Proper error handling
  - Never logged in plain text

  ---
  Ready for implementation! The agent should start with updating the OnboardingFlowCoordinator to
  implement the new flow, ensuring it incorporates both the onboarding enhancement design and the pending
   UI overhaul principles.