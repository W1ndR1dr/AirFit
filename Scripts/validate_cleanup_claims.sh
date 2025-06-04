#!/bin/bash

# Validation script for cleanup claims
# Run this to get ground truth before proceeding

echo "==================================="
echo "AirFit Cleanup Validation Report"
echo "Generated: $(date)"
echo "==================================="

echo -e "\n### 1. FORCE CASTS ###"
echo "Production force casts (as!):"
grep -rn "as!" --include="*.swift" AirFit/ | grep -v "AirFitTests" | grep -v "Preview" || echo "None found"

echo -e "\n### 2. PROTOCOL USAGE ###"
echo "AIAPIServiceProtocol usage:"
grep -rn "AIAPIServiceProtocol" --include="*.swift" AirFit/ || echo "None found"

echo -e "\nAIServiceProtocol usage:"
grep -rn ": AIServiceProtocol" --include="*.swift" AirFit/ | grep -v "Tests" || echo "None found"

echo -e "\n### 3. API KEY PROTOCOLS ###"
echo "Files with APIKeyManagerProtocol:"
grep -l "APIKeyManagerProtocol" --include="*.swift" -r AirFit/ || echo "None found"

echo -e "\nFiles with APIKeyManagementProtocol:"
grep -l "APIKeyManagementProtocol" --include="*.swift" -r AirFit/ || echo "None found"

echo -e "\n### 4. MOCK SERVICES IN PRODUCTION ###"
grep -rn "SimpleMockAIService\|MockAIService" --include="*.swift" AirFit/ | grep -v "AirFitTests" || echo "None found"

echo -e "\n### 5. CONVERSATIONSESSION PROPERTY USAGE ###"
echo "Searching for supposedly missing properties..."
grep -rn "completionPercentage\|extractedInsights\|responseType\|processingTime" --include="*.swift" AirFit/ | grep -v "ConversationSession.swift" | head -20

echo -e "\n### 6. OBSERVABLEOBJECT USAGE ###"
echo "ViewModels using ObservableObject:"
grep -rn "class.*:.*ObservableObject" --include="*.swift" AirFit/Modules/ || echo "None found"

echo -e "\n### 7. LARGE FILES (potential god objects) ###"
echo "Files over 1000 lines:"
find AirFit -name "*.swift" -exec wc -l {} + | sort -nr | head -10

echo -e "\n### 8. WEATHERKIT STATUS ###"
echo "WeatherService implementation:"
grep -rn "WeatherKit\|WeatherService" --include="*.swift" AirFit/Services/ | head -10

echo -e "\n### 9. BUILD CHECK ###"
echo "Checking if project builds..."
if xcodebuild -list -project AirFit.xcodeproj &>/dev/null; then
    echo "✅ Project file exists and is valid"
else
    echo "❌ Project file issue detected"
fi

echo -e "\n==================================="
echo "Validation complete. Review output before proceeding with cleanup."