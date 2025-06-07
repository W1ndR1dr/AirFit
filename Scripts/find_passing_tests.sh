#!/bin/bash
# Find passing tests by running them individually

cd "/Users/Brian/Coding Projects/AirFit"

# First, build the main app without tests to see if it compiles
echo "Building main app..."
if xcodebuild build -scheme AirFit -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -derivedDataPath build 2>&1 | grep -q "BUILD SUCCEEDED"; then
    echo "✅ Main app builds successfully"
else
    echo "❌ Main app build failed"
    exit 1
fi

# List all test classes
echo -e "\nFinding all test classes..."
TEST_CLASSES=$(find AirFit/AirFitTests -name "*Tests.swift" -not -path "*/Mocks/*" | sort)

echo -e "\nFound test files:"
echo "$TEST_CLASSES" | while read -r file; do
    echo "  - $(basename "$file")"
done

# Try to build just the test target
echo -e "\nBuilding test target..."
if xcodebuild build-for-testing -scheme AirFit -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -derivedDataPath build 2>&1 | grep -q "BUILD SUCCEEDED"; then
    echo "✅ Test target builds successfully"
else
    echo "❌ Test target build failed"
    # Get specific errors
    xcodebuild build-for-testing -scheme AirFit -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -derivedDataPath build 2>&1 | grep -E "error:|failed" | head -20
fi