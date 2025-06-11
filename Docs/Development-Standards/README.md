# Development Standards Guide

**Last Updated**: 2025-06-10  
**Purpose**: Essential standards for AirFit development

## Quick Reference

### 🏗️ Architecture & Patterns
- **[DI_STANDARDS.md](./DI_STANDARDS.md)** - Dependency injection patterns (lazy, async, testable)
- **[CONCURRENCY_STANDARDS.md](./CONCURRENCY_STANDARDS.md)** - Swift 6 concurrency, actors, async/await
- **[ERROR_HANDLING_STANDARDS.md](./ERROR_HANDLING_STANDARDS.md)** - AppError usage, error propagation

### 🎯 Performance & Optimization
- **[MAINACTOR_CLEANUP_STANDARDS.md](./MAINACTOR_CLEANUP_STANDARDS.md)** - When to use @MainActor vs actors
- **[AI_OPTIMIZATION_STANDARDS.md](./AI_OPTIMIZATION_STANDARDS.md)** - AI performance patterns, demo mode

### 🎨 UI Development
- **[STANDARD_COMPONENTS.md](./STANDARD_COMPONENTS.md)** - StandardButton, StandardCard usage
- **[UI_VISION.md](./UI_VISION.md)** - Future UI direction (gradients, animations)

### 📝 Code Organization
- **[NAMING_STANDARDS.md](./NAMING_STANDARDS.md)** - File naming conventions
- **[TEST_STANDARDS.md](./TEST_STANDARDS.md)** - Testing patterns and best practices
- **[PROJECT_FILE_MANAGEMENT.md](./PROJECT_FILE_MANAGEMENT.md)** - XcodeGen and file organization
- **[DOCUMENTATION_CHECKLIST.md](./DOCUMENTATION_CHECKLIST.md)** - Documentation requirements

## New Developer Onboarding

Start with these in order:
1. **DI_STANDARDS** - Understand our dependency injection
2. **CONCURRENCY_STANDARDS** - Learn our async patterns
3. **ERROR_HANDLING_STANDARDS** - Use AppError consistently
4. **STANDARD_COMPONENTS** - Use existing UI components

## Key Principles

### 1. Lazy Everything
- Services created only when needed
- No blocking during app launch
- <0.5s launch time maintained

### 2. Type Safety First
- Protocol-based dependencies
- Compile-time validation
- No force unwrapping

### 3. Performance Conscious
- @MainActor only for UI
- Services as actors
- Efficient data queries

### 4. Consistent Patterns
- All services implement ServiceProtocol
- All errors use AppError
- All UI uses standard components

## Common Tasks

### Adding a New Service
1. Check **DI_STANDARDS** for registration pattern
2. Check **CONCURRENCY_STANDARDS** for actor vs @MainActor
3. Implement ServiceProtocol
4. Register in DIBootstrapper

### Creating a New View
1. Use **STANDARD_COMPONENTS** (StandardButton, StandardCard)
2. Follow **NAMING_STANDARDS** for file names
3. Create ViewModel with proper DI

### Writing Tests
1. Follow **TEST_STANDARDS** for structure
2. Use mock DI container
3. Test async behavior properly

## Architecture References
- Main architecture: `../ARCHITECTURE.md`
- Module boundaries: `../MODULE_BOUNDARIES.md`
- Recovery plan: `../CODEBASE_RECOVERY_PLAN.md`

## Archived Standards
Completed migrations and outdated standards are in `Archive/`