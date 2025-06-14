# Development Standards Guide

**Last Updated**: 2025-06-14  
**Purpose**: Essential standards for AI agents working on AirFit codebase  
**Status**: Consolidated and aligned with production implementation

## Core Standards (AI Agent Onboarding)

### 🏗️ Architecture (Read First)
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Complete architecture overview, patterns, and principles
- **[DI_STANDARDS.md](./DI_STANDARDS.md)** - Lazy dependency injection with async resolution
- **[CONCURRENCY_STANDARDS.md](./CONCURRENCY_STANDARDS.md)** - Actor isolation, @MainActor patterns, Swift 6 compliance
- **[SERVICE_LAYER_STANDARDS.md](./SERVICE_LAYER_STANDARDS.md)** - Service protocols, actor boundaries

### 🎨 UI Implementation
- **[UI_VISION.md](./UI_VISION.md)** - Complete UI system: GlassCard, CascadeText, gradients, animations

### 📋 Code Quality
- **[ERROR_HANDLING_STANDARDS.md](./ERROR_HANDLING_STANDARDS.md)** - AppError patterns, graceful failure
- **[NAMING_STANDARDS.md](./NAMING_STANDARDS.md)** - File naming, type conventions
- **[TEST_STANDARDS.md](./TEST_STANDARDS.md)** - Testing patterns (Note: test suite needs cleanup)

### 🎯 Specialized
- **[SWIFTDATA_STANDARDS.md](./SWIFTDATA_STANDARDS.md)** - When to use SwiftData vs native frameworks, actor constraints
- **[AI_OPTIMIZATION_STANDARDS.md](./AI_OPTIMIZATION_STANDARDS.md)** - LLM performance patterns
- **[MODULE_BOUNDARIES.md](./MODULE_BOUNDARIES.md)** - Module organization
- **[PROJECT_FILE_MANAGEMENT.md](./PROJECT_FILE_MANAGEMENT.md)** - XcodeGen usage
- **[DOCUMENTATION_CHECKLIST.md](./DOCUMENTATION_CHECKLIST.md)** - Documentation requirements

## AI Agent Quick Start

**Essential Reading Order for New AI Agents**:

1. **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Complete architecture overview and principles
2. **[DI_STANDARDS.md](./DI_STANDARDS.md)** - Master lazy async DI patterns before coding
3. **[CONCURRENCY_STANDARDS.md](./CONCURRENCY_STANDARDS.md)** - Understand actor isolation boundaries  
4. **[SWIFTDATA_STANDARDS.md](./SWIFTDATA_STANDARDS.md)** - Critical: SwiftData vs HealthKit decision matrix
5. **[UI_VISION.md](./UI_VISION.md)** - Learn our component system (GlassCard, CascadeText)
6. **[SERVICE_LAYER_STANDARDS.md](./SERVICE_LAYER_STANDARDS.md)** - Service protocols and actor patterns

**Key Constraints**:
- Build must pass with 0 errors, 0 warnings
- Run `xcodebuild build` after every change
- SwiftLint must pass strict validation
- All services are actors except SwiftData-constrained ones
- UI uses gradient system, no solid backgrounds
- Test suite is currently deprecated (ignore test files)

## Production Implementation Status

**✅ World-Class Patterns Implemented**:
- Lazy async DI with zero-cost app startup
- Actor-based services with proper isolation
- GlassCard + CascadeText UI system
- Swift 6 compliant concurrency
- LLM-centric architecture with persona coherence

**📋 Documentation Consolidated** (2025-06-14):
- Removed duplicate/deprecated standards
- Aligned with actual codebase patterns
- Optimized for AI agent context limits

---
**For AI Agents**: This codebase represents production-ready patterns. Follow the documented standards exactly as they reflect working implementation.