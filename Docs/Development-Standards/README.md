# Development Standards Guide

**Last Updated**: 2025-01-04  
**Purpose**: Essential standards for AI agents working on AirFit codebase  
**Status**: Consolidated and aligned with production implementation

## Core Standards (AI Agent Onboarding)

### 🏗️ Architecture (Read First)
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Complete architecture overview, patterns, and principles
- **[DEPENDENCY_INJECTION_STANDARDS.md](./DEPENDENCY_INJECTION_STANDARDS.md)** - Lazy dependency injection with async resolution
- **[CONCURRENCY_STANDARDS.md](./CONCURRENCY_STANDARDS.md)** - Actor isolation, @MainActor patterns, Swift 6 compliance
- **[SERVICE__LAYER_STANDARDS.md](./SERVICE__LAYER_STANDARDS.md)** - Service protocols, actor boundaries

### 🤖 AI Implementation
- **[AI_STANDARDS.md](./AI_STANDARDS.md)** - AI system patterns, structured outputs, transparency requirements

### 🎨 UI Implementation
- **[UI_STANDARDS.md](./UI_STANDARDS.md)** - Complete UI system: GlassCard, CascadeText, gradients, animations

### 📋 Code Quality
- **[ERROR_HANDLING_STANDARDS.md](./ERROR_HANDLING_STANDARDS.md)** - AppError patterns, graceful failure
- **[NAMING_STANDARDS.md](./NAMING_STANDARDS.md)** - File naming, type conventions
- **[TEST_STANDARDS.md](./TEST_STANDARDS.md)** - Testing patterns (Note: test suite needs cleanup)

### 🎯 Specialized
- **[SWIFTDATA_STANDARDS.md](./SWIFTDATA_STANDARDS.md)** - When to use SwiftData vs native frameworks, actor constraints
- **[MODULE_BOUNDARY_STANDARDS.md](./MODULE_BOUNDARY_STANDARDS.md)** - Module organization
- **[FILE_MANAGEMENT_STANDARDS.md](./FILE_MANAGEMENT_STANDARDS.md)** - XcodeGen usage
- **[DOCUMENTATION_STANDARDS.md](./DOCUMENTATION_STANDARDS.md)** - Documentation requirements
- **[HEALTHKIT_TEST_DATA.md](./HEALTHKIT_TEST_DATA.md)** - Test data patterns for HealthKit

## AI Agent Quick Start

**Essential Reading Order for New AI Agents**:

1. **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Complete architecture overview and principles
2. **[DEPENDENCY_INJECTION_STANDARDS.md](./DEPENDENCY_INJECTION_STANDARDS.md)** - Master lazy async DI patterns before coding
3. **[CONCURRENCY_STANDARDS.md](./CONCURRENCY_STANDARDS.md)** - Understand actor isolation boundaries  
4. **[AI_STANDARDS.md](./AI_STANDARDS.md)** - Critical: AI implementation patterns and requirements
5. **[SWIFTDATA_STANDARDS.md](./SWIFTDATA_STANDARDS.md)** - Critical: SwiftData vs HealthKit decision matrix
6. **[UI_STANDARDS.md](./UI_STANDARDS.md)** - Learn our component system (GlassCard, CascadeText)
7. **[SERVICE__LAYER_STANDARDS.md](./SERVICE__LAYER_STANDARDS.md)** - Service protocols and actor patterns

**Key Constraints**:
- Build must pass with 0 errors, 0 warnings
- Run `xcodebuild build` after every change
- SwiftLint must pass strict validation
- All services are actors except SwiftData-constrained ones
- UI uses gradient system, no solid backgrounds
- AI responses must be authentic - no fake content
- Test suite is currently deprecated (ignore test files)

## Production Implementation Status

**✅ World-Class Patterns Implemented**:
- Lazy async DI with zero-cost app startup
- Actor-based services with proper isolation
- GlassCard + CascadeText UI system
- Swift 6 compliant concurrency
- LLM-centric architecture with persona coherence
- Structured output support for 99.9% parsing reliability

**📋 Documentation Consolidated** (2025-01-04):
- Added AI_STANDARDS.md for AI implementation patterns
- Removed outdated AI_SYSTEM_IMPLEMENTATION_STATUS.md
- Aligned with actual codebase patterns
- Optimized for AI agent context limits

---
**For AI Agents**: This codebase represents production-ready patterns. Follow the documented standards exactly as they reflect working implementation.