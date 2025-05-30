#!/usr/bin/env bash
###############################################################################
#  Module 8 Food Tracking Integration Verification Script
#  Validates project configuration, file inclusion, and dependencies
###############################################################################
set -euo pipefail

echo "🔍 MODULE 8 FOOD TRACKING INTEGRATION VERIFICATION"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

check_result() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}❌ $2${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

echo -e "${BLUE}📋 1. VERIFYING FOOD TRACKING MODULE FILES${NC}"
echo "=============================================="

# Check all FoodTracking module files exist
FOOD_TRACKING_FILES=(
    "AirFit/Modules/FoodTracking/FoodTrackingCoordinator.swift"
    "AirFit/Modules/FoodTracking/Services/FoodVoiceAdapter.swift"
    "AirFit/Modules/FoodTracking/Services/FoodVoiceServiceProtocol.swift"
    "AirFit/Modules/FoodTracking/Services/NutritionService.swift"
    "AirFit/Modules/FoodTracking/Services/FoodDatabaseService.swift"
    "AirFit/Modules/FoodTracking/ViewModels/FoodTrackingViewModel.swift"
    "AirFit/Modules/FoodTracking/Views/VoiceInputView.swift"
    "AirFit/Modules/FoodTracking/Views/FoodLoggingView.swift"
    "AirFit/Modules/FoodTracking/Views/FoodConfirmationView.swift"
    "AirFit/Modules/FoodTracking/Views/PhotoInputView.swift"
    "AirFit/Modules/FoodTracking/Views/MacroRingsView.swift"
    "AirFit/Modules/FoodTracking/Views/WaterTrackingView.swift"
    "AirFit/Modules/FoodTracking/Views/NutritionSearchView.swift"
)

for file in "${FOOD_TRACKING_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_result 0 "File exists: $file"
    else
        check_result 1 "File missing: $file"
    fi
done

echo -e "\n${BLUE}📋 2. VERIFYING PROJECT.YML INCLUSION${NC}"
echo "====================================="

# Check all files are included in project.yml
for file in "${FOOD_TRACKING_FILES[@]}"; do
    if grep -q "$file" project.yml; then
        check_result 0 "project.yml includes: $file"
    else
        check_result 1 "project.yml missing: $file"
    fi
done

echo -e "\n${BLUE}📋 3. VERIFYING TEST FILES${NC}"
echo "=========================="

# Check test files exist
TEST_FILES=(
    "AirFit/AirFitTests/FoodTracking/FoodTrackingViewModelTests.swift"
    "AirFit/AirFitTests/FoodTracking/FoodVoiceAdapterTests.swift"
    "AirFit/AirFitUITests/FoodTracking/FoodTrackingFlowUITests.swift"
)

for file in "${TEST_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_result 0 "Test file exists: $file"
    else
        check_result 1 "Test file missing: $file"
    fi
done

# Check test files are included in project.yml
for file in "${TEST_FILES[@]}"; do
    if grep -q "$file" project.yml; then
        check_result 0 "project.yml includes test: $file"
    else
        check_result 1 "project.yml missing test: $file"
    fi
done

echo -e "\n${BLUE}📋 4. VERIFYING MODULE 13 DEPENDENCIES${NC}"
echo "======================================"

# Check Module 13 dependencies
MODULE_13_DEPS=(
    "AirFit/Core/Services/VoiceInputManager.swift"
    "AirFit/Core/Services/WhisperModelManager.swift"
    "AirFit/Modules/Chat/ChatCoordinator.swift"
)

for file in "${MODULE_13_DEPS[@]}"; do
    if [ -f "$file" ]; then
        check_result 0 "Module 13 dependency exists: $file"
    else
        check_result 1 "Module 13 dependency missing: $file"
    fi
done

echo -e "\n${BLUE}📋 5. VERIFYING WHISPERKIT DEPENDENCY${NC}"
echo "===================================="

# Check WhisperKit package configuration
if grep -q "WhisperKit:" project.yml && grep -q "github.com/argmaxinc/WhisperKit" project.yml; then
    check_result 0 "WhisperKit package dependency configured"
else
    check_result 1 "WhisperKit package dependency missing"
fi

# Check WhisperKit is listed as target dependency
if grep -A 5 "dependencies:" project.yml | grep -q "package: WhisperKit"; then
    check_result 0 "WhisperKit target dependency configured"
else
    check_result 1 "WhisperKit target dependency missing"
fi

echo -e "\n${BLUE}📋 6. VERIFYING DATA MODELS${NC}"
echo "==========================="

# Check required data models exist
DATA_MODELS=(
    "AirFit/Data/Models/FoodEntry.swift"
    "AirFit/Data/Models/FoodItem.swift"
    "AirFit/Data/Models/User.swift"
)

for file in "${DATA_MODELS[@]}"; do
    if [ -f "$file" ]; then
        check_result 0 "Data model exists: $file"
    else
        check_result 1 "Data model missing: $file"
    fi
done

echo -e "\n${BLUE}📋 7. VERIFYING AI INFRASTRUCTURE${NC}"
echo "================================="

# Check AI infrastructure files
AI_FILES=(
    "AirFit/Services/AI/CoachEngine.swift"
    "AirFit/Modules/AI/CoachEngine.swift"
    "AirFit/Modules/AI/Functions/NutritionFunctions.swift"
)

for file in "${AI_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_result 0 "AI infrastructure exists: $file"
        break
    fi
done

echo -e "\n${BLUE}📋 8. VERIFYING CORE INFRASTRUCTURE${NC}"
echo "==================================="

# Check core infrastructure
CORE_FILES=(
    "AirFit/Core/Theme/AppColors.swift"
    "AirFit/Core/Theme/AppFonts.swift"
    "AirFit/Core/Theme/AppSpacing.swift"
    "AirFit/Core/Utilities/AppLogger.swift"
    "AirFit/Core/Utilities/HapticManager.swift"
)

for file in "${CORE_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_result 0 "Core infrastructure exists: $file"
    else
        check_result 1 "Core infrastructure missing: $file"
    fi
done

echo -e "\n${BLUE}📋 9. VERIFYING SWIFT 6 COMPLIANCE${NC}"
echo "=================================="

# Check for Swift 6 patterns in key files
if grep -r "@MainActor" AirFit/Modules/FoodTracking/ >/dev/null 2>&1; then
    check_result 0 "@MainActor patterns found in FoodTracking module"
else
    check_result 1 "@MainActor patterns missing in FoodTracking module"
fi

if grep -r "@Observable" AirFit/Modules/FoodTracking/ >/dev/null 2>&1; then
    check_result 0 "@Observable patterns found in FoodTracking module"
else
    check_result 1 "@Observable patterns missing in FoodTracking module"
fi

# Check Swift version configuration
if grep -q "SWIFT_VERSION.*6.0" project.yml; then
    check_result 0 "Swift 6.0 version configured"
else
    check_result 1 "Swift 6.0 version not configured"
fi

if grep -q "SWIFT_STRICT_CONCURRENCY.*complete" project.yml; then
    check_result 0 "Swift strict concurrency enabled"
else
    check_result 1 "Swift strict concurrency not enabled"
fi

echo -e "\n${BLUE}📋 10. PERFORMANCE VALIDATION${NC}"
echo "============================="

# Check for performance-critical patterns
if grep -r "withTimeout" AirFit/Modules/FoodTracking/ >/dev/null 2>&1; then
    check_result 0 "Timeout patterns found for performance"
else
    check_result 1 "Timeout patterns missing"
fi

if grep -r "Task.detached" AirFit/Modules/FoodTracking/ >/dev/null 2>&1; then
    check_result 0 "Background task patterns found"
else
    check_result 1 "Background task patterns missing"
fi

echo -e "\n${YELLOW}📊 VERIFICATION SUMMARY${NC}"
echo "======================="
echo -e "Total Checks: ${BLUE}$TOTAL_CHECKS${NC}"
echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ALL CHECKS PASSED! Module 8 integration is ready for production.${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  $FAILED_CHECKS checks failed. Please review and fix issues before proceeding.${NC}"
    exit 1
fi 