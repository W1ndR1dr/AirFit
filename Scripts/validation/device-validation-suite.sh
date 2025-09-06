#!/bin/bash
# AirFit Device Validation Suite
# Run this script to guide manual testing on iPhone 16 Pro

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
RESULTS_FILE="validation_results_$(date +%Y%m%d_%H%M%S).txt"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Initialize results file
echo "=== AirFit Device Validation Results ===" > $RESULTS_FILE
echo "Date: $(date)" >> $RESULTS_FILE
echo "Device: iPhone 16 Pro (iOS 18.4)" >> $RESULTS_FILE
echo "Branch: claude/T30-final-gate-sweep" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE

log_test_result() {
    local test_name=$1
    local result=$2
    local notes=$3
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✅ $test_name: PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "✅ $test_name: PASS" >> $RESULTS_FILE
    else
        echo -e "${RED}❌ $test_name: FAIL${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "❌ $test_name: FAIL" >> $RESULTS_FILE
    fi
    
    if [ -n "$notes" ]; then
        echo "   Notes: $notes" >> $RESULTS_FILE
    fi
    echo "" >> $RESULTS_FILE
}

prompt_test_result() {
    local test_name=$1
    local instructions=$2
    
    echo -e "${BLUE}🔍 Testing: $test_name${NC}"
    echo "$instructions"
    echo ""
    
    while true; do
        read -p "Did this test PASS or FAIL? (P/F): " result
        case $result in
            [Pp]* ) 
                read -p "Any notes? (optional): " notes
                log_test_result "$test_name" "PASS" "$notes"
                break;;
            [Ff]* ) 
                read -p "Please describe the issue: " notes
                log_test_result "$test_name" "FAIL" "$notes"
                break;;
            * ) echo "Please answer P (pass) or F (fail).";;
        esac
    done
    echo ""
}

echo -e "${YELLOW}=== AirFit Device Validation Suite ===${NC}"
echo "This script will guide you through manual testing on your iPhone 16 Pro"
echo "Make sure AirFit is installed and ready to test"
echo ""
read -p "Press Enter to continue..."

# Gate A: Core Functionality Tests
echo -e "${YELLOW}=== GATE A: CORE FUNCTIONALITY ===${NC}"

prompt_test_result "App Launch Performance" \
"1. Force close AirFit completely (double-tap home, swipe up)
2. Start timer
3. Tap AirFit icon
4. Stop timer when dashboard is interactive
Target: < 1 second"

prompt_test_result "Tab Navigation Responsiveness" \
"1. Switch between all tabs rapidly
2. Each tab should respond within 100ms
3. No lag or stuttering during transitions"

prompt_test_result "Data Persistence" \
"1. Make some changes in the app (log food, chat, etc.)
2. Force quit the app
3. Relaunch and verify your changes are still there"

prompt_test_result "HealthKit Integration" \
"1. Go to Settings and check HealthKit permissions
2. Verify AirFit can read health data
3. Check that health data appears in dashboard cards"

prompt_test_result "AI Chat First Response" \
"1. Open Chat tab
2. Send message: 'Hello, how are you?'
3. Start timer when you tap send
4. Stop timer when first word appears
Target: < 2 seconds"

prompt_test_result "Food Tracking Camera" \
"1. Go to Food Logging
2. Try camera food capture
3. Verify camera opens and can take photos
4. Check if food is properly identified"

prompt_test_result "Dashboard Real Data" \
"1. Open Dashboard tab
2. Verify all cards show real data (not placeholders)
3. Check that data looks accurate and up-to-date"

# Gate B: Performance Benchmarks
echo -e "${YELLOW}=== GATE B: PERFORMANCE BENCHMARKS ===${NC}"

prompt_test_result "Memory Usage Baseline" \
"1. Use app normally for 10 minutes
2. Check Settings > Privacy > Analytics for crash logs
3. App should feel responsive throughout
4. No memory warnings or crashes"

prompt_test_result "Battery Impact Test" \
"1. Note battery percentage before starting
2. Use app actively for 30 minutes
3. Check battery usage in Settings > Battery
4. AirFit should not be a top battery consumer"

prompt_test_result "Context Assembly Speed" \
"1. Pull to refresh on Dashboard
2. Time how long until all cards show data
3. Should complete within 3 seconds"

prompt_test_result "Animation Smoothness" \
"1. Navigate through all app screens
2. Watch for smooth 60fps animations
3. No stuttering or frame drops"

# Gate C: User Experience
echo -e "${YELLOW}=== GATE C: USER EXPERIENCE ===${NC}"

prompt_test_result "Complete Onboarding Flow" \
"1. Delete and reinstall app (if possible)
2. Complete entire onboarding process
3. Should flow smoothly from start to finish
4. All features should work after setup"

prompt_test_result "Voice Input Accuracy" \
"1. Try voice input in any text field
2. Speak clearly: 'I ate two eggs and toast'
3. Check transcription accuracy"

prompt_test_result "Visual Polish" \
"1. Check all screens for visual consistency
2. GlassCard effects should render properly
3. Gradients and animations should look smooth"

prompt_test_result "Error Handling" \
"1. Turn off WiFi mid-operation
2. Try to use app with poor connectivity
3. Should show helpful error messages"

# Gate D: Data Integrity
echo -e "${YELLOW}=== GATE D: DATA INTEGRITY ===${NC}"

prompt_test_result "HealthKit Permission Flow" \
"1. Go to device Settings > Health > Data Access
2. Remove AirFit permissions
3. Return to app, should prompt properly
4. Re-grant permissions, should work correctly"

prompt_test_result "Data Synchronization" \
"1. Make changes in AirFit (log food/exercise)
2. Check if data appears in Apple Health
3. Add data in Apple Health
4. Check if it appears in AirFit"

prompt_test_result "AI Persona Consistency" \
"1. Chat with AI across multiple sessions
2. Personality should remain consistent
3. Should remember context from earlier"

# Gate E: Production Readiness
echo -e "${YELLOW}=== GATE E: PRODUCTION READINESS ===${NC}"

prompt_test_result "App Store Readiness" \
"1. App icon displays correctly in all contexts
2. No placeholder text or developer notes visible
3. All screens look polished and complete"

prompt_test_result "Privacy Compliance" \
"1. Check that health data usage is clear
2. Privacy prompts are informative
3. No sensitive data visible in logs"

prompt_test_result "Accessibility Support" \
"1. Enable VoiceOver in Settings
2. Navigate through app using VoiceOver
3. All elements should be properly labeled
4. Navigation should be logical"

# Final Results Summary
echo -e "${YELLOW}=== VALIDATION SUMMARY ===${NC}"
echo "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

# Calculate pass rate
if [ $TOTAL_TESTS -gt 0 ]; then
    PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo "Pass Rate: $PASS_RATE%"
    
    # Final recommendation
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED - READY FOR RELEASE${NC}"
        echo "RECOMMENDATION: GO for production release" >> $RESULTS_FILE
    elif [ $PASS_RATE -ge 90 ]; then
        echo -e "${YELLOW}⚠️  MOSTLY PASSED - REVIEW FAILURES${NC}"
        echo "RECOMMENDATION: Address failures before release" >> $RESULTS_FILE
    else
        echo -e "${RED}🚨 MULTIPLE FAILURES - NOT READY${NC}"
        echo "RECOMMENDATION: NO-GO, significant issues need resolution" >> $RESULTS_FILE
    fi
fi

# Save final summary
echo "" >> $RESULTS_FILE
echo "=== FINAL SUMMARY ===" >> $RESULTS_FILE
echo "Total Tests: $TOTAL_TESTS" >> $RESULTS_FILE
echo "Passed: $PASSED_TESTS" >> $RESULTS_FILE
echo "Failed: $FAILED_TESTS" >> $RESULTS_FILE
if [ $TOTAL_TESTS -gt 0 ]; then
    echo "Pass Rate: $PASS_RATE%" >> $RESULTS_FILE
fi

echo ""
echo "Results saved to: $RESULTS_FILE"
echo -e "${BLUE}Upload this file to complete the validation documentation${NC}"