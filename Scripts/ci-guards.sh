#!/bin/bash

# AirFit CI Quality Guards
# Comprehensive quality checks for AirFit codebase
# This script runs various quality checks and reports violations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VIOLATIONS_FILE="ci-guards-violations.txt"
SUMMARY_FILE="ci-guards-summary.json"
MAX_FILE_SIZE=1000  # lines
MAX_FUNCTION_SIZE=50  # lines
MAX_TYPE_SIZE=300   # lines

echo -e "${BLUE}🛡️  AirFit CI Quality Guards${NC}"
echo "==============================="

# Initialize reports
echo "" > "$VIOLATIONS_FILE"
echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","violations":[],"summary":{}}' > "$SUMMARY_FILE"

violations_count=0

# Helper function to log violations
log_violation() {
    local category="$1"
    local message="$2"
    local file="$3"
    local line="${4:-}"
    
    violations_count=$((violations_count + 1))
    
    if [ -n "$line" ]; then
        echo "[$category] $message ($file:$line)" | tee -a "$VIOLATIONS_FILE"
    else
        echo "[$category] $message ($file)" | tee -a "$VIOLATIONS_FILE"
    fi
}

# Guard 1: Check for oversized files
echo -e "\n${YELLOW}📏 Checking file sizes...${NC}"
find AirFit -name "*.swift" -not -path "*/.*" | while read -r file; do
    if [ -f "$file" ]; then
        lines=$(wc -l < "$file" | tr -d ' ')
        if [ "$lines" -gt "$MAX_FILE_SIZE" ]; then
            log_violation "FILE_SIZE" "File too large: $lines lines (max: $MAX_FILE_SIZE)" "$file"
        fi
    fi
done

# Guard 2: Check for large functions/methods
echo -e "\n${YELLOW}🔧 Checking function sizes...${NC}"
find AirFit -name "*.swift" -not -path "*/.*" -exec grep -n "func \|init(" {} + | while IFS=: read -r file line_num line_content; do
    if [ -f "$file" ]; then
        # Count lines in function (approximate - until next func/class/struct/})
        func_lines=$(awk -v start="$line_num" '
            NR >= start {
                if (/^[[:space:]]*func |^[[:space:]]*init\(|^[[:space:]]*class |^[[:space:]]*struct |^[[:space:]]*enum / && NR > start) exit
                if (/^[[:space:]]*}[[:space:]]*$/ && brace_count <= 1) exit
                if (/{/) brace_count++
                if (/}/) brace_count--
                count++
            }
            END { print count }
        ' "$file")
        
        if [ -n "$func_lines" ] && [ "$func_lines" -gt "$MAX_FUNCTION_SIZE" ]; then
            func_name=$(echo "$line_content" | sed 's/.*func \([^(]*\).*/\1/')
            log_violation "FUNCTION_SIZE" "Function '$func_name' too large: $func_lines lines (max: $MAX_FUNCTION_SIZE)" "$file" "$line_num"
        fi
    fi
done

# Guard 3: Check for TODO/FIXME comments
echo -e "\n${YELLOW}📝 Checking for TODO/FIXME comments...${NC}"
find AirFit -name "*.swift" -not -path "*/.*" -exec grep -n "TODO\|FIXME" {} + | while IFS=: read -r file line_num content; do
    log_violation "TODO_FIXME" "Found TODO/FIXME comment" "$file" "$line_num"
done

# Guard 4: Check for debugging statements
echo -e "\n${YELLOW}🐛 Checking for debug statements...${NC}"
find AirFit -name "*.swift" -not -path "*/.*" -exec grep -n "print(\|debugPrint(\|NSLog(" {} + | while IFS=: read -r file line_num content; do
    # Skip if it's in a proper logging context or test file
    if [[ ! "$file" =~ Test ]] && [[ ! "$content" =~ AppLogger ]] && [[ ! "$content" =~ os_log ]]; then
        log_violation "DEBUG_PRINT" "Found debug print statement" "$file" "$line_num"
    fi
done

# Guard 5: Check for force unwrapping
echo -e "\n${YELLOW}⚠️  Checking for force unwrapping...${NC}"
find AirFit -name "*.swift" -not -path "*/.*" -exec grep -n "!" {} + | grep -v "!=" | while IFS=: read -r file line_num content; do
    # Skip comments, boolean operators, and safe contexts
    if [[ ! "$content" =~ ^[[:space:]]*// ]] && [[ "$content" =~ [a-zA-Z0-9_]\! ]] && [[ ! "$content" =~ fatalError ]]; then
        log_violation "FORCE_UNWRAP" "Found force unwrapping (!)" "$file" "$line_num"
    fi
done

# Guard 6: Check for hardcoded strings that should be localized
echo -e "\n${YELLOW}🌐 Checking for potential hardcoded strings...${NC}"
find AirFit -name "*.swift" -not -path "*/.*" -exec grep -n '"[A-Za-z][^"]*[A-Za-z]"' {} + | while IFS=: read -r file line_num content; do
    # Skip certain patterns that are likely not user-facing
    if [[ ! "$content" =~ (Logger|Bundle|UserDefaults|NSNotification|Error|Exception|Key|URL|Path|Extension|Identifier) ]] && 
       [[ ! "$content" =~ ^[[:space:]]*// ]] && 
       [[ ! "$file" =~ Test ]] &&
       [[ "$content" =~ Text\(|Alert\(|\.title|\.message ]]; then
        log_violation "HARDCODED_STRING" "Potential hardcoded user-facing string" "$file" "$line_num"
    fi
done

# Guard 7: Check for missing access control
echo -e "\n${YELLOW}🔒 Checking for missing access control...${NC}"
find AirFit -name "*.swift" -not -path "*/.*" -exec grep -n "^class \|^struct \|^enum \|^func \|^var \|^let " {} + | while IFS=: read -r file line_num content; do
    # Skip if already has access control or is in certain contexts
    if [[ ! "$content" =~ (private|internal|public|fileprivate|open) ]] && 
       [[ ! "$content" =~ (@main|override|convenience) ]] &&
       [[ ! "$file" =~ Test ]]; then
        declaration_type=$(echo "$content" | awk '{print $1}')
        log_violation "ACCESS_CONTROL" "Missing access control on $declaration_type declaration" "$file" "$line_num"
    fi
done

# Guard 8: Check for large type definitions
echo -e "\n${YELLOW}📐 Checking type sizes...${NC}"
find AirFit -name "*.swift" -not -path "*/.*" | while read -r file; do
    if [ -f "$file" ]; then
        grep -n "^class \|^struct \|^enum " "$file" | while IFS=: read -r type_declaration; do
            line_num=$(echo "$type_declaration" | cut -d: -f1)
            type_lines=$(awk -v start="$line_num" '
                NR >= start {
                    if (/^class |^struct |^enum / && NR > start) exit
                    if (/^}$/ && brace_count <= 1) exit
                    if (/{/) brace_count++
                    if (/}/) brace_count--
                    count++
                }
                END { print count }
            ' "$file")
            
            if [ -n "$type_lines" ] && [ "$type_lines" -gt "$MAX_TYPE_SIZE" ]; then
                type_name=$(echo "$type_declaration" | sed 's/.*\(class\|struct\|enum\) \([^: {]*\).*/\2/')
                log_violation "TYPE_SIZE" "Type '$type_name' too large: $type_lines lines (max: $MAX_TYPE_SIZE)" "$file" "$line_num"
            fi
        done
    fi
done

# Guard 9: Check for proper error handling patterns
echo -e "\n${YELLOW}🚨 Checking error handling patterns...${NC}"
find AirFit -name "*.swift" -not -path "*/.*" -exec grep -n "try!" {} + | while IFS=: read -r file line_num content; do
    if [[ ! "$file" =~ Test ]]; then
        log_violation "FORCE_TRY" "Found force try (try!) - consider proper error handling" "$file" "$line_num"
    fi
done

# Guard 10: Check for SwiftData imports in UI/ViewModels
echo -e "\n${YELLOW}🏗️  Checking SwiftData imports in UI/ViewModels...${NC}"
find AirFit/Modules -path "*/Views/*" -o -path "*/ViewModels/*" | grep "\.swift$" | while read -r file; do
    if [ -f "$file" ] && grep -q "import SwiftData" "$file"; then
        line_num=$(grep -n "import SwiftData" "$file" | cut -d: -f1)
        log_violation "SWIFTDATA_UI" "SwiftData import found in UI/ViewModel - use repositories/services instead" "$file" "$line_num"
    fi
done

# Guard 11: Check for ad-hoc ModelContainer usage outside DI/tests/previews
echo -e "\n${YELLOW}📦 Checking for ad-hoc ModelContainer usage...${NC}"
find AirFit -name "*.swift" -not -path "*/.*" | while read -r file; do
    if [ -f "$file" ] && grep -q "ModelContainer(" "$file"; then
        # Skip allowed locations
        if [[ ! "$file" =~ (DI/|Tests/|Test|Preview|DataManager\.swift|AirFitApp\.swift|ExerciseDatabase\.swift|ModelContainer\+Test\.swift) ]]; then
            line_num=$(grep -n "ModelContainer(" "$file" | cut -d: -f1)
            log_violation "ADHOC_MODELCONTAINER" "Ad-hoc ModelContainer usage - should use DI container" "$file" "$line_num"
        fi
    fi
done

# Guard 12: Check for NotificationCenter usage in Chat/AI modules
echo -e "\n${YELLOW}📡 Checking NotificationCenter usage in Chat/AI...${NC}"
find AirFit/Modules/Chat AirFit/Modules/AI -name "*.swift" 2>/dev/null | while read -r file; do
    if [ -f "$file" ] && grep -q "NotificationCenter\.default\." "$file"; then
        line_num=$(grep -n "NotificationCenter\.default\." "$file" | cut -d: -f1)
        log_violation "NOTIFICATIONCENTER_CHAT" "NotificationCenter usage in Chat/AI - use ChatStreamingStore protocol" "$file" "$line_num"
    fi
done

# Guard 13: Check for missing @MainActor on ViewModels
echo -e "\n${YELLOW}🎭 Checking ViewModels for @MainActor...${NC}"
find AirFit/Modules -path "*/ViewModels/*" -name "*.swift" | while read -r file; do
    if [ -f "$file" ]; then
        # Look for ViewModel class definitions without @MainActor
        grep -n "class.*ViewModel" "$file" | while IFS=: read -r line_num class_line; do
            # Check if @MainActor is present before the class (within 3 lines)
            context_start=$((line_num - 3))
            if [ $context_start -lt 1 ]; then context_start=1; fi
            
            has_mainactor=$(sed -n "${context_start},${line_num}p" "$file" | grep -c "@MainActor")
            if [ "$has_mainactor" -eq 0 ]; then
                class_name=$(echo "$class_line" | sed 's/.*class \([^: ]*\).*/\1/')
                log_violation "MISSING_MAINACTOR" "ViewModel '$class_name' missing @MainActor annotation" "$file" "$line_num"
            fi
        done
    fi
done

# Guard 14: Check for direct URLSession usage outside network layer
echo -e "\n${YELLOW}🌐 Checking for direct URLSession usage...${NC}"
find AirFit -name "*.swift" -not -path "*/.*" | while read -r file; do
    if [ -f "$file" ] && [[ ! "$file" =~ (Services/Network/|Test|ExerciseDatabase\.swift) ]] && grep -q "URLSession\." "$file"; then
        line_num=$(grep -n "URLSession\." "$file" | cut -d: -f1)
        log_violation "DIRECT_URLSESSION" "Direct URLSession usage - use NetworkClientProtocol" "$file" "$line_num"
    fi
done

# Guard 15: Check for SwiftUI binding misuse (direct @State access from outside view)
echo -e "\n${YELLOW}🔗 Checking SwiftUI binding patterns...${NC}"
find AirFit -name "*.swift" -not -path "*/.*" | while read -r file; do
    if [ -f "$file" ] && grep -q "@State.*private" "$file"; then
        # Check for potential violations where @State isn't private
        grep -n "@State" "$file" | grep -v "private" | while IFS=: read -r line_num state_line; do
            log_violation "STATE_NOT_PRIVATE" "@State should be private - found public/internal @State" "$file" "$line_num"
        done
    fi
done

# Generate summary
echo -e "\n${BLUE}📊 Generating summary...${NC}"

# Count violations by category
categories=$(cat "$VIOLATIONS_FILE" | grep -o '^\[[^]]*\]' | sort | uniq -c | sed 's/^\s*\([0-9]*\)\s*\[\([^]]*\)\]/\1:\2/')

# Recalculate total violations from file (subshells don't preserve the counter)
violations_count=$(grep -c '^\[' "$VIOLATIONS_FILE" || echo 0)

# Create detailed summary with statistics  
echo -e "\n${BLUE}=== DETAILED VIOLATION BREAKDOWN ===${NC}"
echo "$categories" | while IFS=':' read -r count category; do
    if [ -n "$count" ] && [ -n "$category" ]; then
        echo -e "  ${YELLOW}$category:${NC} $count violations"
    fi
done

# Generate fix priority recommendations
echo -e "\n${BLUE}=== FIX PRIORITY RECOMMENDATIONS ===${NC}"
echo -e "${RED}🚨 CRITICAL (Fix First):${NC}"
echo "$categories" | while IFS=':' read -r count category; do
    case $category in
        "ADHOC_MODELCONTAINER"|"SWIFTDATA_UI"|"FORCE_TRY"|"FORCE_UNWRAP")
            echo -e "  • $category ($count violations) - Architecture/Safety violations"
            ;;
    esac
done

echo -e "${YELLOW}⚠️  HIGH (Fix Soon):${NC}"
echo "$categories" | while IFS=':' read -r count category; do
    case $category in
        "MISSING_MAINACTOR"|"NOTIFICATIONCENTER_CHAT"|"DIRECT_URLSESSION")
            echo -e "  • $category ($count violations) - Threading/Architecture issues"
            ;;
    esac
done

echo -e "${BLUE}📋 MEDIUM (Fix When Convenient):${NC}"
echo "$categories" | while IFS=':' read -r count category; do
    case $category in
        "DEBUG_PRINT"|"TODO_FIXME"|"ACCESS_CONTROL"|"HARDCODED_STRING"|"FILE_SIZE"|"FUNCTION_SIZE"|"TYPE_SIZE"|"STATE_NOT_PRIVATE")
            echo -e "  • $category ($count violations) - Code quality issues"
            ;;
    esac
done

# Create JSON summary
jq --argjson violations "$violations_count" \
   --arg categories "$categories" \
   --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
   '.summary.total_violations = $violations | .summary.categories = $categories | .timestamp = $timestamp' \
   "$SUMMARY_FILE" > temp_summary.json && mv temp_summary.json "$SUMMARY_FILE"

# Print results
echo -e "\n${BLUE}================================${NC}"
echo -e "${BLUE}🛡️  CI Guards Summary${NC}"
echo -e "${BLUE}================================${NC}"

if [ "$violations_count" -eq 0 ]; then
    echo -e "${GREEN}✅ No violations found! Code quality looks great.${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Found $violations_count violations:${NC}"
    echo ""
    echo "$categories" | while IFS=':' read -r count category; do
        if [ -n "$count" ] && [ -n "$category" ]; then
            echo -e "  ${YELLOW}$category:${NC} $count violations"
        fi
    done
    echo ""
    echo -e "📄 Full report: ${VIOLATIONS_FILE}"
    echo -e "📊 JSON summary: ${SUMMARY_FILE}"
    
    # For now, exit with success (allow failures)
    # TODO: Change to exit 1 when we're ready to enforce
    echo -e "\n${YELLOW}ℹ️  Currently in monitoring mode - violations logged but not failing CI${NC}"
    exit 0
fi