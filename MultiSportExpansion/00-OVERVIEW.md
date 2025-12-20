# Multi-Sport Fitness Expansion

> Expanding AirFit from weight-training-focused to a comprehensive multi-sport fitness companion

## Executive Summary

AirFit currently excels at strength training through its Hevy integration. This research explores expanding to support **running, cycling, swimming, yoga**, and other workout types available through Apple HealthKit—without compromising the app's elegant, AI-native design philosophy.

### Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Priority workout type | **Running first** | Most data-rich after strength; GPS routes, pace, HR zones, efficiency metrics |
| Route map importance | **Essential feature** | Full MapKit integration with pace/HR overlays, not just nice-to-have |
| Hevy-free mode | **Simplified fallback** | Basic +/- set counter for non-Hevy users (brothers' use case) |

## Document Index

| Document | Purpose |
|----------|---------|
| [01-HEALTHKIT-CAPABILITIES](./01-HEALTHKIT-CAPABILITIES.md) | What data Apple HealthKit provides |
| [02-ARCHITECTURE-ANALYSIS](./02-ARCHITECTURE-ANALYSIS.md) | Current system design and integration points |
| [03-RUNNING-DEEP-DIVE](./03-RUNNING-DEEP-DIVE.md) | Running-specific features and metrics |
| [04-OTHER-MODALITIES](./04-OTHER-MODALITIES.md) | Cycling, swimming, yoga specifics |
| [05-UI-DESIGN-PRINCIPLES](./05-UI-DESIGN-PRINCIPLES.md) | UX recommendations from design consultation |
| [06-AI-CONTEXT-STRATEGY](./06-AI-CONTEXT-STRATEGY.md) | LLM context injection approach |
| [07-IMPLEMENTATION-PHASES](./07-IMPLEMENTATION-PHASES.md) | Phased rollout roadmap |
| [08-SIMPLIFIED-SET-TRACKER](./08-SIMPLIFIED-SET-TRACKER.md) | Manual tracking for non-Hevy users |

## The Big Picture

### What We Discovered

1. **HealthKit is a goldmine** - The app already reads 50+ workout types, running efficiency metrics, cycling cadence, swimming distance. GPS route data is available but untapped.

2. **Architecture needs abstraction** - Everything currently assumes Hevy. Adding a `WorkoutProvider` protocol would enable multiple data sources.

3. **Don't add tabs** - Expand Dashboard's Training segment instead. The 5-tab structure is elegant; a 6th tab would fragment attention.

4. **Implicit personalization** - The app should learn from usage which activities matter to each user, not require configuration.

5. **AI context is solvable** - Tiered context (always/triggered/on-demand) with compact notation keeps token budgets manageable.

### The Brothers' Use Case

Users who primarily do cardio (running, cycling) and rarely or never use Hevy should find AirFit equally valuable:

- Set Tracker gracefully disappears when no strength data exists
- Running/cycling metrics take center stage
- Simplified manual set counter (+/-) available for occasional strength work
- App adapts automatically based on HealthKit activity patterns

## Research Methodology

This research was conducted through:

1. **Codebase exploration** - Deep analysis of HealthKitManager, Hevy integration, context injection, and UI patterns
2. **Expert consultations** - Three "legendary persona" perspectives:
   - Endurance coaching (Phil Maffetone × Greg McMillan)
   - UX design (Jony Ive × Julie Zhuo)
   - AI systems (Andrej Karpathy × Simon Willison)

## Next Steps

When ready to implement, start with:

1. **Phase 1**: Data foundation (extend WorkoutSnapshot, add cardio fields)
2. **Phase 2**: Running feature (RouteMapView, RunningDetailView)
3. **Phase 3**: UI integration (unified activity stream)
4. **Phase 4**: AI context (cross-modality insights)
5. **Phase 5**: Simplified set tracker

See [07-IMPLEMENTATION-PHASES](./07-IMPLEMENTATION-PHASES.md) for detailed technical tasks.

---

*Research compiled December 2024*
