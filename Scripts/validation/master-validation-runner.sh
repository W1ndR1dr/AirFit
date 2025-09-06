#!/bin/bash
# AirFit Master Validation Runner
# Orchestrates the complete final validation process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Master validation log
MASTER_LOG="master_validation_$(date +%Y%m%d_%H%M%S).txt"

echo -e "${PURPLE}${BOLD}🚀 === AirFit Master Validation Suite === 🚀${NC}"
echo "Complete final validation for production readiness"
echo ""
echo "This script orchestrates all validation phases:"
echo "  1. CI Pipeline Verification (automated)"
echo "  2. Device Performance Testing (manual)"
echo "  3. Accessibility Testing (manual)"
echo "  4. User Journey Testing (manual)"
echo "  5. Final Quality Gate Review"
echo ""

# Initialize master log
cat > $MASTER_LOG << EOF
=== AirFit Master Validation Session ===
Date: $(date)
Branch: $(git branch --show-current)
Commit: $(git rev-parse --short HEAD)
Tester: $(whoami)

EOF

# Validation phase tracking
PHASES_COMPLETED=0
TOTAL_PHASES=5

log_phase_completion() {
    local phase_name=$1
    local status=$2
    local notes=$3
    
    PHASES_COMPLETED=$((PHASES_COMPLETED + 1))
    
    echo ""
    echo -e "${YELLOW}📋 Phase $PHASES_COMPLETED/$TOTAL_PHASES: $phase_name - $status${NC}"
    echo ""
    
    cat >> $MASTER_LOG << EOF
Phase $PHASES_COMPLETED/$TOTAL_PHASES: $phase_name
Status: $status
Notes: $notes
Completed: $(date)

EOF
}

# Check prerequisites
echo -e "${BLUE}🔍 Checking Prerequisites${NC}"

# Verify we're on the correct branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "claude/T30-final-gate-sweep" ]; then
    echo -e "${RED}❌ Wrong branch: $CURRENT_BRANCH${NC}"
    echo "Please checkout claude/T30-final-gate-sweep branch first"
    exit 1
fi

# Verify validation scripts exist
REQUIRED_SCRIPTS=(
    "Scripts/validation/ci-pipeline-verification.sh"
    "Scripts/validation/performance-benchmarks.sh"
    "Scripts/validation/accessibility-validation.sh"
    "Scripts/validation/device-validation-suite.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ ! -f "$script" ]; then
        echo -e "${RED}❌ Missing validation script: $script${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ All prerequisites met${NC}"
echo ""

read -p "Ready to begin master validation? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Validation cancelled by user"
    exit 0
fi

echo ""

# PHASE 1: CI Pipeline Verification
echo -e "${BOLD}${BLUE}=== PHASE 1: CI PIPELINE VERIFICATION ===${NC}"
echo "Running automated CI checks..."
echo ""

if ./Scripts/validation/ci-pipeline-verification.sh; then
    log_phase_completion "CI Pipeline Verification" "PASSED" "All automated checks green"
    CI_STATUS="GREEN"
else
    CI_EXIT_CODE=$?
    if [ $CI_EXIT_CODE -eq 1 ]; then
        log_phase_completion "CI Pipeline Verification" "WARNING" "Minor issues detected - review required"
        CI_STATUS="YELLOW"
    else
        log_phase_completion "CI Pipeline Verification" "FAILED" "Critical issues - must fix before proceeding"
        CI_STATUS="RED"
        echo ""
        echo -e "${RED}🚨 CI Pipeline has critical failures!${NC}"
        echo "Please fix the issues and re-run this script."
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}Phase 1 Complete${NC} - CI checks: $CI_STATUS"
echo ""
read -p "Continue to device testing? (y/N): " continue_phase2
if [[ ! $continue_phase2 =~ ^[Yy]$ ]]; then
    echo "Validation stopped after Phase 1"
    exit 0
fi

# PHASE 2: Performance Benchmarking
echo -e "${BOLD}${BLUE}=== PHASE 2: PERFORMANCE BENCHMARKING ===${NC}"
echo ""
echo "This phase requires manual testing on iPhone 16 Pro"
echo "The script will provide automated tooling and manual test guidance"
echo ""

read -p "Do you have iPhone 16 Pro with AirFit installed ready? (y/N): " device_ready
if [[ ! $device_ready =~ ^[Yy]$ ]]; then
    echo "Please prepare device and restart validation"
    exit 0
fi

echo "Running performance benchmark framework..."
./Scripts/validation/performance-benchmarks.sh

echo ""
read -p "Did performance tests meet targets? (y/N): " perf_results
if [[ $perf_results =~ ^[Yy]$ ]]; then
    read -p "Any performance notes?: " perf_notes
    log_phase_completion "Performance Benchmarking" "PASSED" "$perf_notes"
    PERF_STATUS="PASSED"
else
    read -p "Describe performance issues: " perf_issues
    log_phase_completion "Performance Benchmarking" "FAILED" "$perf_issues"
    PERF_STATUS="FAILED"
    
    echo ""
    echo -e "${RED}⚠️  Performance benchmarks failed${NC}"
    read -p "Continue anyway? (NOT recommended) (y/N): " continue_anyway
    if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
        echo "Validation stopped - fix performance issues first"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}Phase 2 Complete${NC} - Performance: $PERF_STATUS"
echo ""

# PHASE 3: Accessibility Validation
echo -e "${BOLD}${BLUE}=== PHASE 3: ACCESSIBILITY VALIDATION ===${NC}"
echo ""
echo "Comprehensive accessibility testing with VoiceOver, Dynamic Type, etc."
echo ""

read -p "Ready to run accessibility validation? (y/N): " ready_a11y
if [[ ! $ready_a11y =~ ^[Yy]$ ]]; then
    echo "Skipping accessibility validation - NOT RECOMMENDED"
    log_phase_completion "Accessibility Validation" "SKIPPED" "User chose to skip"
    A11Y_STATUS="SKIPPED"
else
    ./Scripts/validation/accessibility-validation.sh
    
    echo ""
    read -p "Did accessibility tests pass? (y/N): " a11y_results
    if [[ $a11y_results =~ ^[Yy]$ ]]; then
        read -p "Any accessibility notes?: " a11y_notes
        log_phase_completion "Accessibility Validation" "PASSED" "$a11y_notes"
        A11Y_STATUS="PASSED"
    else
        read -p "Describe accessibility issues: " a11y_issues
        log_phase_completion "Accessibility Validation" "FAILED" "$a11y_issues"
        A11Y_STATUS="FAILED"
        
        echo ""
        echo -e "${RED}⚠️  Accessibility validation failed${NC}"
        echo "Accessibility issues must be fixed before production!"
        read -p "Continue to log issues? (y/N): " continue_a11y
        if [[ ! $continue_a11y =~ ^[Yy]$ ]]; then
            echo "Validation stopped - fix accessibility issues first"
            exit 1
        fi
    fi
fi

echo ""
echo -e "${GREEN}Phase 3 Complete${NC} - Accessibility: $A11Y_STATUS"
echo ""

# PHASE 4: User Journey Validation
echo -e "${BOLD}${BLUE}=== PHASE 4: USER JOURNEY VALIDATION ===${NC}"
echo ""
echo "Critical user journey testing and comprehensive device validation"
echo ""

read -p "Ready to run complete device validation suite? (y/N): " ready_device
if [[ ! $ready_device =~ ^[Yy]$ ]]; then
    echo "Skipping device validation - NOT RECOMMENDED"
    log_phase_completion "User Journey Validation" "SKIPPED" "User chose to skip"
    JOURNEY_STATUS="SKIPPED"
else
    ./Scripts/validation/device-validation-suite.sh
    
    echo ""
    read -p "Did all user journey tests pass? (y/N): " journey_results
    if [[ $journey_results =~ ^[Yy]$ ]]; then
        read -p "Any user journey notes?: " journey_notes
        log_phase_completion "User Journey Validation" "PASSED" "$journey_notes"
        JOURNEY_STATUS="PASSED"
    else
        read -p "Describe user journey issues: " journey_issues
        log_phase_completion "User Journey Validation" "FAILED" "$journey_issues"
        JOURNEY_STATUS="FAILED"
    fi
fi

echo ""
echo -e "${GREEN}Phase 4 Complete${NC} - User Journeys: $JOURNEY_STATUS"
echo ""

# PHASE 5: Final Quality Gate Review
echo -e "${BOLD}${BLUE}=== PHASE 5: FINAL QUALITY GATE REVIEW ===${NC}"
echo ""
echo "Comprehensive review of all validation results"
echo ""

# Generate final report
cat >> $MASTER_LOG << EOF

=== FINAL VALIDATION REPORT ===

VALIDATION PHASE RESULTS:
✓ Phase 1 - CI Pipeline: $CI_STATUS
✓ Phase 2 - Performance: $PERF_STATUS  
✓ Phase 3 - Accessibility: $A11Y_STATUS
✓ Phase 4 - User Journeys: $JOURNEY_STATUS

EOF

echo -e "${YELLOW}📊 FINAL VALIDATION SUMMARY${NC}"
echo ""
echo -e "CI Pipeline Verification: ${CI_STATUS}"
echo -e "Performance Benchmarks: ${PERF_STATUS}"
echo -e "Accessibility Validation: ${A11Y_STATUS}"
echo -e "User Journey Testing: ${JOURNEY_STATUS}"
echo ""

# Calculate overall status
CRITICAL_FAILURES=0
WARNINGS=0

if [ "$CI_STATUS" = "RED" ]; then
    CRITICAL_FAILURES=$((CRITICAL_FAILURES + 1))
elif [ "$CI_STATUS" = "YELLOW" ]; then
    WARNINGS=$((WARNINGS + 1))
fi

if [ "$PERF_STATUS" = "FAILED" ]; then
    CRITICAL_FAILURES=$((CRITICAL_FAILURES + 1))
fi

if [ "$A11Y_STATUS" = "FAILED" ]; then
    CRITICAL_FAILURES=$((CRITICAL_FAILURES + 1))
elif [ "$A11Y_STATUS" = "SKIPPED" ]; then
    WARNINGS=$((WARNINGS + 1))
fi

if [ "$JOURNEY_STATUS" = "FAILED" ]; then
    CRITICAL_FAILURES=$((CRITICAL_FAILURES + 1))
elif [ "$JOURNEY_STATUS" = "SKIPPED" ]; then
    WARNINGS=$((WARNINGS + 1))
fi

# Final recommendation
if [ $CRITICAL_FAILURES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    FINAL_STATUS="🎉 READY FOR PRODUCTION"
    RECOMMENDATION="GO - All validation phases passed successfully"
    echo -e "${GREEN}${BOLD}$FINAL_STATUS${NC}"
elif [ $CRITICAL_FAILURES -eq 0 ]; then
    FINAL_STATUS="⚠️  READY WITH WARNINGS"
    RECOMMENDATION="CONDITIONAL GO - Address warnings before release"
    echo -e "${YELLOW}${BOLD}$FINAL_STATUS${NC}"
else
    FINAL_STATUS="🚨 NOT READY"
    RECOMMENDATION="NO-GO - Fix critical issues before production"
    echo -e "${RED}${BOLD}$FINAL_STATUS${NC}"
fi

echo ""
echo -e "${BLUE}Recommendation: $RECOMMENDATION${NC}"

# Update master log with final status
cat >> $MASTER_LOG << EOF

CRITICAL FAILURES: $CRITICAL_FAILURES
WARNINGS: $WARNINGS

FINAL STATUS: $FINAL_STATUS
RECOMMENDATION: $RECOMMENDATION

SIGN-OFF REQUIRED:
□ Technical Lead: _________________ Date: _______
□ QA Lead: _________________ Date: _______  
□ Product Owner: _________________ Date: _______

EOF

log_phase_completion "Final Quality Gate Review" "COMPLETED" "$RECOMMENDATION"

echo ""
echo -e "${YELLOW}📁 VALIDATION ARTIFACTS${NC}"
echo "Master validation log: $MASTER_LOG"
echo ""

# List all generated artifacts
echo "Additional artifacts generated:"
for artifact in ci_verification_*.txt performance_results_*.json accessibility_results_*.txt validation_results_*.txt; do
    if [ -f "$artifact" ]; then
        echo "  📄 $artifact"
    fi
done

echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"

if [ $CRITICAL_FAILURES -eq 0 ]; then
    cat << EOF
1. Review all validation artifacts
2. Complete sign-offs in master log
3. Update Docs/FINAL_VALIDATION.md with results
4. Commit validation results to branch
5. Create pull request for merge to main
6. Prepare for App Store submission

EOF
else
    cat << EOF
1. Review critical failures in validation logs  
2. Fix identified issues
3. Re-run affected validation phases
4. Do not proceed to production until all critical issues resolved

Critical Issues to Address:
EOF
    
    [ "$CI_STATUS" = "RED" ] && echo "  - CI Pipeline failures"
    [ "$PERF_STATUS" = "FAILED" ] && echo "  - Performance benchmark failures"  
    [ "$A11Y_STATUS" = "FAILED" ] && echo "  - Accessibility violations"
    [ "$JOURNEY_STATUS" = "FAILED" ] && echo "  - User journey test failures"
fi

echo ""
echo -e "${PURPLE}🎯 Master Validation Complete!${NC}"
echo "Review all artifacts and proceed according to recommendations."

# Exit with appropriate status code
if [ $CRITICAL_FAILURES -eq 0 ]; then
    exit 0
else
    exit 1
fi