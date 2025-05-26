#!/bin/bash

echo "=== AirFit Module 1 Fix: Files Missing from Main Target ==="
echo ""
echo "The following Swift files exist but are NOT included in the main AirFit target:"
echo "You need to add these files to the AirFit target in Xcode."
echo ""

echo "📁 Application Files:"
find ./Application -name "*.swift" | sort

echo ""
echo "📁 Core Files:"
find ./Core -name "*.swift" | sort

echo ""
echo "📁 Root Files:"
find . -maxdepth 1 -name "*.swift" | sort

echo ""
echo "📁 Services Files:"
find ./Services -name "*.swift" 2>/dev/null | sort

echo ""
echo "📁 Modules Files:"
find ./Modules -name "*.swift" 2>/dev/null | sort

echo ""
echo "=== Instructions ==="
echo "1. Open AirFit.xcodeproj in Xcode"
echo "2. Select ALL the files listed above in the Project Navigator"
echo "3. In the File Inspector (right panel), check the 'AirFit' target checkbox"
echo "4. For Core files, also check 'AirFitTests' target so tests can access them"
echo "5. Build the project - it should now compile the Swift module properly"
echo ""
echo "Total files to add: $(find . -name "*.swift" -not -path "./AirFitTests/*" -not -path "./AirFitUITests/*" -not -path "./Scripts/*" | wc -l | tr -d ' ')" 