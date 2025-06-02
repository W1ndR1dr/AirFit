#!/bin/bash

# AirFit Architecture Tuneup Validation Script
# Purpose: Verify all tuneup phases complete before module development
# Version: 1.0

set -e

echo "🔧 AirFit Architecture Tuneup Validation"
echo "========================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

VALIDATION_FAILED=0

echo ""
echo "📋 Phase 1: SwiftData Schema Verification"
echo "----------------------------------------"

# Check if ConversationSession and ConversationResponse are in Data/Models/
if [ -f "AirFit/Data/Models/ConversationSession.swift" ]; then
    echo -e "${GREEN}✅ ConversationSession.swift in correct location${NC}"
else
    echo -e "${RED}❌ ConversationSession.swift missing from AirFit/Data/Models/${NC}"
    VALIDATION_FAILED=1
fi

if [ -f "AirFit/Data/Models/ConversationResponse.swift" ]; then
    echo -e "${GREEN}✅ ConversationResponse.swift in correct location${NC}"
else
    echo -e "${RED}❌ ConversationResponse.swift missing from AirFit/Data/Models/${NC}"
    VALIDATION_FAILED=1
fi

# Check if models are NOT in old location
if [ -f "AirFit/Modules/Onboarding/Models/ConversationModels.swift" ]; then
    echo -e "${RED}❌ ConversationModels.swift still in old location (should be moved)${NC}"
    VALIDATION_FAILED=1
else
    echo -e "${GREEN}✅ Conversation models moved from old location${NC}"
fi

# Check if schema includes all models
if grep -q "ConversationSession.self" AirFit/Application/AirFitApp.swift; then
    echo -e "${GREEN}✅ ConversationSession in AirFitApp schema${NC}"
else
    echo -e "${RED}❌ ConversationSession missing from schema${NC}"
    VALIDATION_FAILED=1
fi

if grep -q "ConversationResponse.self" AirFit/Application/AirFitApp.swift; then
    echo -e "${GREEN}✅ ConversationResponse in AirFitApp schema${NC}"
else
    echo -e "${RED}❌ ConversationResponse missing from schema${NC}"
    VALIDATION_FAILED=1
fi

echo ""
echo "📋 Phase 2: Production Service Verification"
echo "------------------------------------------"

# Check for MockAIService in production code
if grep -r "MockAIService" AirFit/Application/ > /dev/null 2>&1; then
    echo -e "${RED}❌ MockAIService found in production code${NC}"
    grep -r "MockAIService" AirFit/Application/ | head -5
    VALIDATION_FAILED=1
else
    echo -e "${GREEN}✅ No MockAIService in production code${NC}"
fi

# Check for DependencyContainer usage
if grep -q "DependencyContainer" AirFit/Application/ContentView.swift; then
    echo -e "${GREEN}✅ DependencyContainer pattern implemented${NC}"
else
    echo -e "${YELLOW}⚠️ DependencyContainer not found in ContentView${NC}"
fi

echo ""
echo "📋 Phase 3: Service Architecture Verification"
echo "--------------------------------------------"

# Check for protocols in Core/Protocols/
PROTOCOL_COUNT=$(find AirFit/Core/Protocols -name "*Protocol.swift" 2>/dev/null | wc -l)
if [ "$PROTOCOL_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ Service protocols found in Core/Protocols/ ($PROTOCOL_COUNT files)${NC}"
    find AirFit/Core/Protocols -name "*Protocol.swift" 2>/dev/null | head -5
else
    echo -e "${RED}❌ No service protocols found in Core/Protocols/${NC}"
    VALIDATION_FAILED=1
fi

# Check for DefaultXXXService implementations
DEFAULT_SERVICE_COUNT=$(find AirFit/Services -name "Default*Service.swift" 2>/dev/null | wc -l)
if [ "$DEFAULT_SERVICE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ Default service implementations found ($DEFAULT_SERVICE_COUNT files)${NC}"
else
    echo -e "${YELLOW}⚠️ No Default service implementations found${NC}"
fi

echo ""
echo "📋 Phase 4: Settings Module Status"
echo "---------------------------------"

# Check Settings module directories
SETTINGS_VIEW_COUNT=$(find AirFit/Modules/Settings/Views -name "*.swift" 2>/dev/null | wc -l)
SETTINGS_VIEWMODEL_COUNT=$(find AirFit/Modules/Settings/ViewModels -name "*.swift" 2>/dev/null | wc -l)

if [ "$SETTINGS_VIEW_COUNT" -eq 0 ] && [ "$SETTINGS_VIEWMODEL_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✅ Settings module confirmed empty (ready for Module 11 implementation)${NC}"
else
    echo -e "${YELLOW}⚠️ Settings module has $SETTINGS_VIEW_COUNT views and $SETTINGS_VIEWMODEL_COUNT view models${NC}"
fi

echo ""
echo "📋 Build Verification"
echo "--------------------"

# Basic build check
echo "Building project to verify no compilation errors..."
if xcodebuild clean build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' -quiet > /tmp/build.log 2>&1; then
    echo -e "${GREEN}✅ Project builds successfully${NC}"
else
    echo -e "${RED}❌ Build failed${NC}"
    echo "Last 10 lines of build log:"
    tail -10 /tmp/build.log
    VALIDATION_FAILED=1
fi

echo ""
echo "📋 Data Layer Tests"
echo "------------------"

# Run data layer tests
echo "Running SwiftData tests..."
if xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' -only-testing:AirFitTests/DataLayerTests -quiet > /tmp/test.log 2>&1; then
    echo -e "${GREEN}✅ Data layer tests pass${NC}"
else
    echo -e "${RED}❌ Data layer tests failed${NC}"
    echo "Last 10 lines of test log:"
    tail -10 /tmp/test.log
    VALIDATION_FAILED=1
fi

echo ""
echo "========================================"

if [ $VALIDATION_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 TUNEUP VALIDATION PASSED${NC}"
    echo -e "${GREEN}✅ Architecture is ready for Module 9-12 development${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Module 10: Services Layer (Foundation)"
    echo "2. Module 9 + Module 11: Parallel Implementation" 
    echo "3. Module 12: Testing & Validation"
    exit 0
else
    echo -e "${RED}💥 TUNEUP VALIDATION FAILED${NC}"
    echo -e "${RED}❌ Architecture fixes required before module development${NC}"
    echo ""
    echo "Required actions:"
    echo "1. Review AirFit/Docs/Tuneup.md"
    echo "2. Complete failed tuneup phases"
    echo "3. Re-run validation script"
    exit 1
fi 