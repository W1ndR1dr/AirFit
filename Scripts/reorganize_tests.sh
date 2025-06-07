#!/bin/bash

# Script to reorganize test files to match main codebase structure
# This will help prevent duplication and errors

set -e

echo "🔄 Starting test folder reorganization..."

# Change to test directory
cd "/Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests"

# Create proper directory structure if not exists
echo "📁 Creating directory structure..."
mkdir -p Modules/AI
mkdir -p Modules/FoodTracking
mkdir -p Modules/Workouts
mkdir -p Services/Context
mkdir -p Services/Health

# Move AI tests to proper location
echo "🚚 Moving AI tests..."
if [ -d "AI" ]; then
    mv AI/* Modules/AI/ 2>/dev/null || true
    rmdir AI 2>/dev/null || true
fi

# Move Context tests to proper location
echo "🚚 Moving Context tests..."
if [ -d "Context" ]; then
    mv Context/* Services/Context/ 2>/dev/null || true
    rmdir Context 2>/dev/null || true
fi

# Move FoodTracking tests to proper location
echo "🚚 Moving FoodTracking tests..."
if [ -d "FoodTracking" ]; then
    mv FoodTracking/* Modules/FoodTracking/ 2>/dev/null || true
    rmdir FoodTracking 2>/dev/null || true
fi

# Move Health tests to proper location
echo "🚚 Moving Health tests..."
if [ -d "Health" ]; then
    mv Health/* Services/Health/ 2>/dev/null || true
    rmdir Health 2>/dev/null || true
fi

# Move Workouts tests to proper location
echo "🚚 Moving Workouts tests..."
if [ -d "Workouts" ]; then
    mv Workouts/* Modules/Workouts/ 2>/dev/null || true
    rmdir Workouts 2>/dev/null || true
fi

# Remove empty Dashboard directory
echo "🧹 Cleaning up empty directories..."
rmdir Dashboard 2>/dev/null || true

# Create a test structure documentation
echo "📝 Creating test structure documentation..."
cat > TEST_STRUCTURE.md << 'EOF'
# Test Structure

This test folder structure mirrors the main codebase structure for consistency:

## Core Tests
- `/Core/` - Tests for core utilities, DI, extensions, etc.

## Data Tests
- `/Data/` - Tests for data models and managers

## Service Tests
- `/Services/` - Tests for all service layer components
  - `/AI/` - AI service tests
  - `/Analytics/` - Analytics service tests
  - `/Context/` - Context assembler tests
  - `/Health/` - HealthKit related tests
  - `/Network/` - Network layer tests
  - `/Speech/` - Speech/voice service tests
  - `/User/` - User service tests
  - `/Weather/` - Weather service tests

## Module Tests
- `/Modules/` - Tests for feature modules
  - `/AI/` - AI module tests (CoachEngine, PersonaEngine, etc.)
  - `/Chat/` - Chat module tests
  - `/Dashboard/` - Dashboard module tests
  - `/FoodTracking/` - Food tracking module tests
  - `/Notifications/` - Notification module tests
  - `/Onboarding/` - Onboarding module tests
  - `/Settings/` - Settings module tests
  - `/Workouts/` - Workout module tests

## Special Test Categories
- `/Integration/` - Integration tests that span multiple modules
- `/Performance/` - Performance and stress tests
- `/Mocks/` - All mock implementations
- `/TestUtils/` - Test utilities and helpers

## Naming Convention
- Unit tests: `{ClassName}Tests.swift`
- Integration tests: `{Feature}IntegrationTests.swift`
- Performance tests: `{Feature}PerformanceTests.swift`
- Mocks: `Mock{ClassName}.swift`
EOF

echo "✅ Test reorganization complete!"
echo ""
echo "Next steps:"
echo "1. Update project.yml with new test file paths"
echo "2. Run 'xcodegen generate'"
echo "3. Fix any import statements in moved test files"
echo "4. Run tests to ensure everything still works"