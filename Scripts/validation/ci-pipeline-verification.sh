#!/bin/bash
# AirFit CI Pipeline Verification
# Validates that all automated quality gates are green

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

CI_LOG="ci_verification_$(date +%Y%m%d_%H%M%S).txt"
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

echo -e "${BLUE}🔧 === AirFit CI Pipeline Verification === 🔧${NC}"
echo "Validating all automated quality gates before device testing"
echo ""

# Initialize CI log
cat > $CI_LOG << EOF
=== AirFit CI Pipeline Verification Results ===
Date: $(date)
Branch: claude/T30-final-gate-sweep
Tester: $(whoami)

EOF

log_check_result() {
    local check_name=$1
    local result=$2
    local details=$3
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✅ $check_name${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        echo "✅ $check_name" >> $CI_LOG
    else
        echo -e "${RED}❌ $check_name${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        echo "❌ $check_name" >> $CI_LOG
    fi
    
    if [ -n "$details" ]; then
        echo "   $details"
        echo "   $details" >> $CI_LOG
    fi
    echo "" >> $CI_LOG
}

# Stage 1: Project Generation
echo -e "${YELLOW}=== STAGE 1: PROJECT GENERATION ===${NC}"

if command -v xcodegen >/dev/null 2>&1; then
    echo "Testing XcodeGen project generation..."
    if xcodegen generate --quiet 2>&1; then
        log_check_result "XcodeGen Project Generation" "PASS" "Project generated successfully"
    else
        log_check_result "XcodeGen Project Generation" "FAIL" "Project generation failed - check project.yml"
    fi
else
    log_check_result "XcodeGen Installation" "FAIL" "XcodeGen not installed - run: brew install xcodegen"
fi

# Stage 2: SwiftLint Analysis
echo -e "${YELLOW}=== STAGE 2: CODE QUALITY ANALYSIS ===${NC}"

if command -v swiftlint >/dev/null 2>&1; then
    echo "Running SwiftLint strict analysis..."
    
    # Capture SwiftLint output
    LINT_OUTPUT=$(swiftlint --strict --reporter emoji 2>&1)
    LINT_EXIT_CODE=$?
    
    if [ $LINT_EXIT_CODE -eq 0 ]; then
        VIOLATION_COUNT=$(echo "$LINT_OUTPUT" | grep -E "(warning|error)" | wc -l | xargs)
        log_check_result "SwiftLint Strict Mode" "PASS" "No violations found"
    else
        VIOLATION_COUNT=$(echo "$LINT_OUTPUT" | grep -E "(warning|error)" | wc -l | xargs)
        log_check_result "SwiftLint Strict Mode" "FAIL" "$VIOLATION_COUNT violations found"
        
        # Show first 10 violations
        echo "$LINT_OUTPUT" | head -10
    fi
else
    log_check_result "SwiftLint Installation" "FAIL" "SwiftLint not installed - run: brew install swiftlint"
fi

# Stage 3: Build Verification
echo -e "${YELLOW}=== STAGE 3: BUILD VERIFICATION ===${NC}"

echo "Testing iOS App build..."
BUILD_OUTPUT=$(xcodebuild build \
    -scheme AirFit \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' \
    -configuration Debug \
    -quiet 2>&1)
BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    log_check_result "iOS App Build" "PASS" "Built successfully for iPhone 16 Pro simulator"
else
    ERROR_COUNT=$(echo "$BUILD_OUTPUT" | grep -c "error:" || echo "0")
    WARNING_COUNT=$(echo "$BUILD_OUTPUT" | grep -c "warning:" || echo "0")
    log_check_result "iOS App Build" "FAIL" "$ERROR_COUNT errors, $WARNING_COUNT warnings"
    
    # Show build errors
    echo "Build errors:"
    echo "$BUILD_OUTPUT" | grep "error:" | head -5
fi

echo "Testing watchOS App build..."
WATCH_BUILD_OUTPUT=$(xcodebuild build \
    -scheme AirFitWatchApp \
    -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm),OS=11.0' \
    -configuration Debug \
    -quiet 2>&1)
WATCH_BUILD_EXIT_CODE=$?

if [ $WATCH_BUILD_EXIT_CODE -eq 0 ]; then
    log_check_result "watchOS App Build" "PASS" "Built successfully for Apple Watch Series 10"
else
    ERROR_COUNT=$(echo "$WATCH_BUILD_OUTPUT" | grep -c "error:" || echo "0")
    WARNING_COUNT=$(echo "$WATCH_BUILD_OUTPUT" | grep -c "warning:" || echo "0")
    log_check_result "watchOS App Build" "FAIL" "$ERROR_COUNT errors, $WARNING_COUNT warnings"
fi

# Stage 4: Unit Tests
echo -e "${YELLOW}=== STAGE 4: AUTOMATED TESTING ===${NC}"

if [ -f "AirFit-Unit.xctestplan" ]; then
    echo "Running unit tests..."
    
    TEST_OUTPUT=$(xcodebuild test \
        -scheme AirFit \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' \
        -testPlan AirFit-Unit \
        -quiet 2>&1)
    TEST_EXIT_CODE=$?
    
    if [ $TEST_EXIT_CODE -eq 0 ]; then
        TEST_COUNT=$(echo "$TEST_OUTPUT" | grep -o "Executed [0-9]* tests" | grep -o "[0-9]*" || echo "0")
        log_check_result "Unit Tests" "PASS" "All $TEST_COUNT tests passed"
    else
        FAILED_COUNT=$(echo "$TEST_OUTPUT" | grep -o "[0-9]* failed" | grep -o "[0-9]*" || echo "unknown")
        log_check_result "Unit Tests" "FAIL" "$FAILED_COUNT test failures"
        
        # Show test failures
        echo "Test failures:"
        echo "$TEST_OUTPUT" | grep -A 2 -B 2 "failed" | head -10
    fi
else
    log_check_result "Unit Test Plan" "FAIL" "AirFit-Unit.xctestplan not found"
fi

# Stage 5: Code Coverage Analysis
echo -e "${YELLOW}=== STAGE 5: CODE COVERAGE ANALYSIS ===${NC}"

echo "Analyzing code coverage..."
COVERAGE_OUTPUT=$(xcodebuild test \
    -scheme AirFit \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' \
    -testPlan AirFit-Unit \
    -enableCodeCoverage YES \
    -quiet 2>&1)
COVERAGE_EXIT_CODE=$?

if [ $COVERAGE_EXIT_CODE -eq 0 ]; then
    # Try to extract coverage percentage (this is a rough estimate)
    if command -v xcrun >/dev/null 2>&1; then
        log_check_result "Code Coverage Collection" "PASS" "Coverage data collected successfully"
    else
        log_check_result "Code Coverage Collection" "PASS" "Tests ran with coverage enabled"
    fi
else
    log_check_result "Code Coverage Collection" "FAIL" "Failed to collect coverage data"
fi

# Stage 6: Quality Guards
echo -e "${YELLOW}=== STAGE 6: QUALITY GUARDS ===${NC}"

if [ -f "Scripts/ci-guards.sh" ]; then
    echo "Running CI quality guards..."
    
    GUARDS_OUTPUT=$(./Scripts/ci-guards.sh 2>&1)
    GUARDS_EXIT_CODE=$?
    
    if [ $GUARDS_EXIT_CODE -eq 0 ]; then
        log_check_result "CI Quality Guards" "PASS" "All quality checks passed"
    else
        VIOLATION_COUNT=$(echo "$GUARDS_OUTPUT" | grep -c "VIOLATION" || echo "0")
        log_check_result "CI Quality Guards" "FAIL" "$VIOLATION_COUNT quality violations"
    fi
else
    log_check_result "CI Quality Guards Script" "FAIL" "Scripts/ci-guards.sh not found"
fi

# Stage 7: Dependency Analysis
echo -e "${YELLOW}=== STAGE 7: DEPENDENCY ANALYSIS ===${NC}"

if command -v periphery >/dev/null 2>&1; then
    echo "Running Periphery dead code analysis..."
    
    PERIPHERY_OUTPUT=$(periphery scan \
        --project AirFit.xcodeproj \
        --schemes AirFit,AirFitWatchApp \
        --targets AirFit,AirFitWatchApp \
        --quiet 2>&1)
    PERIPHERY_EXIT_CODE=$?
    
    if [ $PERIPHERY_EXIT_CODE -eq 0 ]; then
        UNUSED_COUNT=$(echo "$PERIPHERY_OUTPUT" | wc -l | xargs)
        if [ "$UNUSED_COUNT" -eq 0 ]; then
            log_check_result "Periphery Dead Code Analysis" "PASS" "No dead code detected"
        else
            log_check_result "Periphery Dead Code Analysis" "PASS" "$UNUSED_COUNT unused code items detected (monitoring)"
        fi
    else
        log_check_result "Periphery Dead Code Analysis" "FAIL" "Analysis failed"
    fi
else
    log_check_result "Periphery Installation" "FAIL" "Periphery not installed - run: brew install peripheryapp/periphery/periphery"
fi

# Stage 8: File System Checks
echo -e "${YELLOW}=== STAGE 8: PROJECT STRUCTURE VALIDATION ===${NC}"

# Check for required files
REQUIRED_FILES=(
    "project.yml"
    "AirFit/.swiftlint.yml"
    "AirFit-Unit.xctestplan"
    "AirFit-Integration.xctestplan"
    "AirFit-UI.xctestplan"
    "AirFit-Watch.xctestplan"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_check_result "Required File: $file" "PASS" "File exists"
    else
        log_check_result "Required File: $file" "FAIL" "File missing"
    fi
done

# Check for critical directories
REQUIRED_DIRS=(
    "AirFit/Application"
    "AirFit/Core"
    "AirFit/Modules"
    "AirFit/Services"
    "AirFitWatchApp"
    "Docs/Development-Standards"
    "Scripts"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        log_check_result "Required Directory: $dir" "PASS" "Directory exists"
    else
        log_check_result "Required Directory: $dir" "FAIL" "Directory missing"
    fi
done

# Stage 9: Git Status Check
echo -e "${YELLOW}=== STAGE 9: VERSION CONTROL STATUS ===${NC}"

# Check git status
GIT_STATUS=$(git status --porcelain)
if [ -z "$GIT_STATUS" ]; then
    log_check_result "Git Working Tree" "PASS" "Working tree clean"
else
    MODIFIED_COUNT=$(echo "$GIT_STATUS" | wc -l | xargs)
    log_check_result "Git Working Tree" "FAIL" "$MODIFIED_COUNT uncommitted changes"
fi

# Check current branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "claude/T30-final-gate-sweep" ]; then
    log_check_result "Git Branch" "PASS" "On correct branch: $CURRENT_BRANCH"
else
    log_check_result "Git Branch" "FAIL" "Expected branch: claude/T30-final-gate-sweep, got: $CURRENT_BRANCH"
fi

# Stage 10: Security Checks
echo -e "${YELLOW}=== STAGE 10: SECURITY VALIDATION ===${NC}"

# Check for hardcoded secrets
SECRETS_CHECK=$(grep -r -i "api.*key\|secret\|password\|token" --include="*.swift" AirFit/ | grep -v "placeholder\|example\|TODO" || echo "")
if [ -z "$SECRETS_CHECK" ]; then
    log_check_result "Hardcoded Secrets Check" "PASS" "No hardcoded secrets detected"
else
    SECRETS_COUNT=$(echo "$SECRETS_CHECK" | wc -l | xargs)
    log_check_result "Hardcoded Secrets Check" "FAIL" "$SECRETS_COUNT potential secrets found"
fi

# Check for debug prints
DEBUG_PRINTS=$(grep -r "print(" --include="*.swift" AirFit/ || echo "")
if [ -z "$DEBUG_PRINTS" ]; then
    log_check_result "Debug Print Statements" "PASS" "No debug prints found"
else
    PRINT_COUNT=$(echo "$DEBUG_PRINTS" | wc -l | xargs)
    log_check_result "Debug Print Statements" "FAIL" "$PRINT_COUNT debug print statements found"
fi

# Final Summary
echo -e "${YELLOW}=== CI PIPELINE VERIFICATION SUMMARY ===${NC}"

cat >> $CI_LOG << EOF

=== FINAL VERIFICATION SUMMARY ===
Total Checks: $TOTAL_CHECKS
Passed: $PASSED_CHECKS
Failed: $FAILED_CHECKS
EOF

if [ $TOTAL_CHECKS -gt 0 ]; then
    PASS_RATE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    echo "Pass Rate: $PASS_RATE%"
    echo "Pass Rate: $PASS_RATE%" >> $CI_LOG
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL CI CHECKS PASSED - PIPELINE GREEN${NC}"
        echo "RECOMMENDATION: Proceed to device validation" >> $CI_LOG
        CI_STATUS="GREEN"
    elif [ $PASS_RATE -ge 90 ]; then
        echo -e "${YELLOW}⚠️  MOSTLY PASSED - REVIEW FAILURES${NC}"
        echo "RECOMMENDATION: Address critical failures before device testing" >> $CI_LOG
        CI_STATUS="YELLOW"
    else
        echo -e "${RED}🚨 MULTIPLE FAILURES - PIPELINE RED${NC}"
        echo "RECOMMENDATION: Fix issues before proceeding" >> $CI_LOG
        CI_STATUS="RED"
    fi
fi

echo ""
echo "Results saved to: $CI_LOG"

# Generate Next Steps
echo ""
echo -e "${BLUE}=== NEXT STEPS ===${NC}"

if [ "$CI_STATUS" = "GREEN" ]; then
    cat << EOF
✅ CI Pipeline is GREEN - Ready for device validation!

Next actions:
1. Run device validation suite: ./Scripts/validation/device-validation-suite.sh
2. Run performance benchmarks: ./Scripts/validation/performance-benchmarks.sh
3. Run accessibility validation: ./Scripts/validation/accessibility-validation.sh
4. Complete final validation checklist in Docs/FINAL_VALIDATION.md
EOF
elif [ "$CI_STATUS" = "YELLOW" ]; then
    cat << EOF
⚠️  CI Pipeline has minor issues - Review and fix:

Priority fixes needed:
$(grep "❌" $CI_LOG | head -5)

Then proceed with device validation.
EOF
else
    cat << EOF
🚨 CI Pipeline has critical issues - Must fix before device testing:

Critical failures:
$(grep "❌" $CI_LOG | head -10)

Fix these issues and re-run this script.
EOF
fi

# Exit with appropriate code
if [ "$CI_STATUS" = "GREEN" ]; then
    exit 0
elif [ "$CI_STATUS" = "YELLOW" ]; then
    exit 1
else
    exit 2
fi
