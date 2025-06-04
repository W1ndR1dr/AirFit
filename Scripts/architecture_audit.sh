#!/bin/bash

# Architecture Audit Script for AirFit
# This script identifies architectural issues in the codebase

echo "==================================="
echo "AirFit Architecture Audit"
echo "==================================="
echo ""

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Counters
TOTAL_ISSUES=0
CRITICAL_ISSUES=0

# Function to report issues
report_issue() {
    local severity=$1
    local issue=$2
    local count=$3
    
    if [ "$severity" = "CRITICAL" ]; then
        echo -e "${RED}[CRITICAL]${NC} $issue: $count instances"
        CRITICAL_ISSUES=$((CRITICAL_ISSUES + count))
    elif [ "$severity" = "WARNING" ]; then
        echo -e "${YELLOW}[WARNING]${NC} $issue: $count instances"
    else
        echo -e "${GREEN}[INFO]${NC} $issue: $count instances"
    fi
    TOTAL_ISSUES=$((TOTAL_ISSUES + count))
}

echo "1. Checking for force casts..."
echo "==============================="
FORCE_CASTS=$(grep -r "as!" --include="*.swift" AirFit/ 2>/dev/null | grep -v "AirFitTests" | wc -l)
if [ $FORCE_CASTS -gt 0 ]; then
    report_issue "CRITICAL" "Force casts found" $FORCE_CASTS
    echo "   Locations:"
    grep -r "as!" --include="*.swift" AirFit/ 2>/dev/null | grep -v "AirFitTests" | head -5
    echo ""
fi

echo "2. Checking for mock services in production..."
echo "=============================================="
PROD_MOCKS=$(grep -r "Mock[A-Z]" --include="*.swift" AirFit/ 2>/dev/null | grep -v "AirFitTests" | grep -v "Preview" | wc -l)
if [ $PROD_MOCKS -gt 0 ]; then
    report_issue "CRITICAL" "Mock services in production" $PROD_MOCKS
    echo "   Locations:"
    grep -r "Mock[A-Z]" --include="*.swift" AirFit/ 2>/dev/null | grep -v "AirFitTests" | grep -v "Preview" | head -5
    echo ""
fi

echo "3. Checking for @MainActor services..."
echo "======================================"
MAINACTOR_SERVICES=$(grep -r "@MainActor.*class.*:.*ServiceProtocol" --include="*.swift" AirFit/Services/ 2>/dev/null | wc -l)
if [ $MAINACTOR_SERVICES -gt 0 ]; then
    report_issue "WARNING" "@MainActor services (should be actors)" $MAINACTOR_SERVICES
    echo "   Files:"
    grep -l "@MainActor.*class.*:.*ServiceProtocol" --include="*.swift" AirFit/Services/ 2>/dev/null | head -5
    echo ""
fi

echo "4. Analyzing file sizes..."
echo "=========================="
LARGE_FILES=$(find AirFit -name "*.swift" -type f -exec wc -l {} \; 2>/dev/null | awk '$1 > 500 {print $2 " (" $1 " lines)"}' | wc -l)
if [ $LARGE_FILES -gt 0 ]; then
    report_issue "WARNING" "Files over 500 lines" $LARGE_FILES
    echo "   Largest files:"
    find AirFit -name "*.swift" -type f -exec wc -l {} \; 2>/dev/null | sort -rn | head -5 | awk '{print "   " $2 " (" $1 " lines)"}'
    echo ""
fi

echo "5. Checking for TODO/FIXME comments..."
echo "======================================"
TODOS=$(grep -r "TODO\|FIXME" --include="*.swift" AirFit/ 2>/dev/null | wc -l)
if [ $TODOS -gt 0 ]; then
    report_issue "INFO" "TODO/FIXME comments" $TODOS
    echo "   Sample TODOs:"
    grep -r "TODO\|FIXME" --include="*.swift" AirFit/ 2>/dev/null | head -3 | sed 's/^/   /'
    echo ""
fi

echo "6. Checking for duplicate protocol definitions..."
echo "================================================"
# Look for protocols defined multiple times
DUPLICATE_PROTOCOLS=$(grep -h "protocol.*Protocol" --include="*.swift" AirFit/Core/Protocols/ 2>/dev/null | sort | uniq -d | wc -l)
if [ $DUPLICATE_PROTOCOLS -gt 0 ]; then
    report_issue "CRITICAL" "Duplicate protocol definitions" $DUPLICATE_PROTOCOLS
    echo "   Duplicates:"
    grep -h "protocol.*Protocol" --include="*.swift" AirFit/Core/Protocols/ 2>/dev/null | sort | uniq -d | head -5
    echo ""
fi

echo "7. Checking for hardcoded values..."
echo "==================================="
HARDCODED=$(grep -r "72\.0\|\"User\"\|\"Current Location\"" --include="*.swift" AirFit/ 2>/dev/null | grep -v "Tests" | wc -l)
if [ $HARDCODED -gt 0 ]; then
    report_issue "WARNING" "Hardcoded values" $HARDCODED
    echo ""
fi

echo "8. Checking for fatalError usage..."
echo "==================================="
FATAL_ERRORS=$(grep -r "fatalError" --include="*.swift" AirFit/ 2>/dev/null | grep -v "Tests" | wc -l)
if [ $FATAL_ERRORS -gt 0 ]; then
    report_issue "WARNING" "fatalError usage" $FATAL_ERRORS
    echo "   Locations:"
    grep -r "fatalError" --include="*.swift" AirFit/ 2>/dev/null | grep -v "Tests" | head -3
    echo ""
fi

echo "9. Checking for missing inverse relationships..."
echo "=============================================="
# Simple check for @Relationship without inverse
NO_INVERSE=$(grep -r "@Relationship(" --include="*.swift" AirFit/Data/Models/ 2>/dev/null | grep -v "inverse:" | wc -l)
if [ $NO_INVERSE -gt 0 ]; then
    report_issue "WARNING" "Relationships missing inverse" $NO_INVERSE
    echo ""
fi

echo "10. Checking service protocol alignment..."
echo "========================================="
# Check if FunctionCallDispatcher references exist for methods
MISSING_METHODS=$(grep -r "generatePlan\|analyzePerformance\|createOrRefineGoal" --include="*.swift" AirFit/ 2>/dev/null | grep -v "Protocol" | wc -l)
if [ $MISSING_METHODS -gt 0 ]; then
    report_issue "CRITICAL" "References to non-existent protocol methods" $MISSING_METHODS
    echo ""
fi

echo "==================================="
echo "Audit Summary"
echo "==================================="
echo -e "Total Issues Found: ${YELLOW}$TOTAL_ISSUES${NC}"
echo -e "Critical Issues: ${RED}$CRITICAL_ISSUES${NC}"
echo ""

if [ $CRITICAL_ISSUES -gt 0 ]; then
    echo -e "${RED}⚠️  CRITICAL ISSUES REQUIRE IMMEDIATE ATTENTION${NC}"
    echo "See CLEANUP_PHASE_1_CRITICAL_FIXES.md for resolution steps"
else
    echo -e "${GREEN}✅ No critical issues found${NC}"
fi

echo ""
echo "For detailed cleanup instructions, see:"
echo "- ARCHITECTURE_CLEANUP_EXECUTIVE_SUMMARY.md"
echo "- CLEANUP_PHASE_*.md documents"

# Generate report file
REPORT_FILE="architecture_audit_$(date +%Y%m%d_%H%M%S).txt"
echo "Generating detailed report: $REPORT_FILE"

# Exit with error if critical issues found
if [ $CRITICAL_ISSUES -gt 0 ]; then
    exit 1
fi