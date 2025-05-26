#!/bin/bash

# Usage: ./verify_module_tests.sh [module_number]

MODULE=$1

if [ -z "$MODULE" ]; then
    echo "Usage: $0 [module_number]"
    exit 1
fi

echo "Verifying tests for Module $MODULE..."

# Run module-specific tests
xcodebuild test \
    -scheme "AirFit" \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
    -only-testing:AirFitTests/Module${MODULE} \
    -resultBundlePath Module${MODULE}TestResults.xcresult \
    | xcbeautify

# Check if tests passed
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ Module $MODULE tests passed!"
    
    # Extract coverage metrics
    xcrun xccov view --report Module${MODULE}TestResults.xcresult --json > coverage.json
    
    # Parse coverage percentage (requires jq)
    if command -v jq &> /dev/null; then
        COVERAGE=$(jq '.targets[] | select(.name == "AirFit") | .lineCoverage' coverage.json)
        echo "📊 Code coverage: ${COVERAGE}%"
        
        # Check if coverage meets minimum requirement
        MIN_COVERAGE=70
        if (( $(echo "$COVERAGE >= $MIN_COVERAGE" | bc -l) )); then
            echo "✅ Coverage meets minimum requirement of ${MIN_COVERAGE}%"
        else
            echo "❌ Coverage below minimum requirement of ${MIN_COVERAGE}%"
            exit 1
        fi
    else
        echo "⚠️  Install jq to see coverage metrics"
    fi
    
    # Clean up
    rm -f coverage.json
else
    echo "❌ Module $MODULE tests failed!"
    exit 1
fi 