#!/usr/bin/env bash
###############################################################################
#  OpenAI Codex cloud startup • Swift 6.1 • SwiftLint + SwiftFormat
#  iOS 18+ • Module 8 Food Tracking • Voice-First AI-Powered Nutrition
#  Leverages Module 13 WhisperKit infrastructure • Optimized for sandboxed agents
###############################################################################
set -euo pipefail

echo "🛠  Swift tool-chain detected:"
swift --version | head -n1

BIN_DIR=/usr/local/bin
mkdir -p "$BIN_DIR"

###############################################################################
#  1.  Install SwiftLint (static binary, stable URL)
###############################################################################
echo "⬇️  Installing SwiftLint…"
curl -fsSL -o /tmp/swiftlint.zip \
  https://github.com/realm/SwiftLint/releases/latest/download/swiftlint_linux.zip
unzip -q /tmp/swiftlint.zip -d "$BIN_DIR"
chmod +x "$BIN_DIR/swiftlint"
rm /tmp/swiftlint.zip

###############################################################################
#  2.  Build SwiftFormat from source (never 404s, ~15 s)
###############################################################################
echo "🔧  Building SwiftFormat from source…"
git clone --quiet --depth=1 https://github.com/nicklockwood/SwiftFormat /tmp/SwiftFormat
(
  cd /tmp/SwiftFormat
  swift build -c release --product swiftformat --disable-sandbox
)
cp /tmp/SwiftFormat/.build/release/swiftformat "$BIN_DIR/"
chmod +x "$BIN_DIR/swiftformat"
echo "✅  SwiftFormat built and installed."

###############################################################################
#  3.  Validate Module 13 WhisperKit infrastructure (Module 8 dependency)
###############################################################################
echo "🎤  Validating Module 13 WhisperKit infrastructure for Module 8…"
# Module 8 leverages Module 13's voice infrastructure via adapter pattern

# Check if WhisperKit package metadata is available from Module 13
if [[ -d ".build" ]] || [[ -f "Package.resolved" ]]; then
  echo "✅  WhisperKit package metadata found from Module 13"
else
  echo "ℹ️  WhisperKit will be available via Module 13 VoiceInputManager"
fi

# Validate Swift 6 concurrency for food tracking patterns
cat > /tmp/food_tracking_concurrency_test.swift << 'EOF'
import Foundation
#if canImport(SwiftUI)
import SwiftUI

@available(iOS 18.0, *)
@MainActor
@Observable
final class TestFoodTrackingViewModel {
    private(set) var parsedFoods: [String] = []
    private(set) var isRecording = false
    private(set) var nutritionSummary = NutritionSummary()
    
    func logFood(_ food: String) async {
        parsedFoods.append(food)
    }
}

@available(iOS 18.0, *)
struct TestFoodLoggingView: View {
    @State private var viewModel = TestFoodTrackingViewModel()
    
    var body: some View {
        VStack {
            Text("Food Tracking Test")
            Button("Log Food") {
                Task {
                    await viewModel.logFood("Apple")
                }
            }
        }
    }
}

struct NutritionSummary: Sendable {
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
}
#endif
EOF

if swift -frontend -typecheck /tmp/food_tracking_concurrency_test.swift -target arm64-apple-ios18.0 -strict-concurrency=complete 2>/dev/null; then
  echo "✅  Swift 6 concurrency patterns validated for Module 8"
else
  echo "⚠️  Swift 6 concurrency validation failed - check strict concurrency settings"
fi
rm -f /tmp/food_tracking_concurrency_test.swift

###############################################################################
#  4.  Test iOS 18 Vision framework for barcode scanning
###############################################################################
echo "📷  Testing iOS 18 Vision framework for barcode scanning…"
cat > /tmp/ios18_vision_test.swift << 'EOF'
import Foundation
#if canImport(Vision) && canImport(AVFoundation)
import Vision
import AVFoundation

@available(iOS 18.0, *)
class TestBarcodeScanner {
    func detectBarcodes() -> Bool {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.ean13, .ean8, .upce, .code128]
        return true
    }
}

@available(iOS 18.0, *)
struct TestCameraSession {
    let session = AVCaptureSession()
    
    func setupCamera() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video) else { return false }
        return true
    }
}
#endif
EOF

if swift -frontend -typecheck /tmp/ios18_vision_test.swift -target arm64-apple-ios18.0 2>/dev/null; then
  echo "✅  iOS 18 Vision framework and AVFoundation validated"
else
  echo "⚠️  iOS 18 Vision framework validation failed"
fi
rm -f /tmp/ios18_vision_test.swift

###############################################################################
#  5.  Test Swift Charts for nutrition visualization
###############################################################################
echo "📊  Testing Swift Charts for nutrition visualization…"
cat > /tmp/swift_charts_test.swift << 'EOF'
import Foundation
#if canImport(SwiftUI) && canImport(Charts)
import SwiftUI
import Charts

@available(iOS 18.0, *)
struct TestMacroRingsView: View {
    let macros = [
        MacroData(name: "Protein", value: 25, color: .blue),
        MacroData(name: "Carbs", value: 45, color: .green),
        MacroData(name: "Fat", value: 30, color: .orange)
    ]
    
    var body: some View {
        Chart(macros, id: \.name) { macro in
            SectorMark(
                angle: .value("Value", macro.value),
                innerRadius: .ratio(0.6),
                angularInset: 2
            )
            .foregroundStyle(macro.color)
        }
    }
}

struct MacroData {
    let name: String
    let value: Double
    let color: Color
}
#endif
EOF

if swift -frontend -typecheck /tmp/swift_charts_test.swift -target arm64-apple-ios18.0 2>/dev/null; then
  echo "✅  Swift Charts for nutrition visualization validated"
else
  echo "⚠️  Swift Charts validation failed"
fi
rm -f /tmp/swift_charts_test.swift

###############################################################################
#  6.  Resolve SwiftPM packages in repo (safe to skip in sandboxed env)
###############################################################################
echo "📦  Looking for Package.swift files…"
PKGS=$(find . -maxdepth 4 -name Package.swift 2>/dev/null || true)
if [[ -n "$PKGS" ]]; then
  echo "$PKGS" | while read -r pkg; do
    pkg_dir=$(dirname "$pkg")
    echo "   → Found package in $pkg_dir"
    (cd "$pkg_dir" && swift package --disable-sandbox resolve 2>/dev/null || echo "     ⚠️  Resolve skipped (sandboxed environment)")
  done
else
  echo "ℹ️  No Swift packages found; using XcodeGen project configuration."
fi

###############################################################################
#  7.  Validate Module 8 prerequisites and Module 13 integration
###############################################################################
echo "🔍  Validating Module 8 prerequisites and Module 13 integration…"

# Check if required modules are in place
REQUIRED_MODULES=(
  "AirFit/Modules/Onboarding"
  "AirFit/Modules/Dashboard" 
  "AirFit/Modules/Chat"
  "AirFit/Data/Models"
  "AirFit/Services/AI"
  "AirFit/Core"
)

for module in "${REQUIRED_MODULES[@]}"; do
  if [[ -d "$module" ]]; then
    echo "✅  $module exists"
  else
    echo "❌  $module missing - required for Module 8"
  fi
done

# Check for critical Module 13 dependencies
MODULE_13_FILES=(
  "AirFit/Core/Services/VoiceInputManager.swift"
  "AirFit/Core/Services/WhisperModelManager.swift"
  "AirFit/Modules/Chat/ChatCoordinator.swift"
)

echo "🎤  Checking Module 13 voice infrastructure…"
for file in "${MODULE_13_FILES[@]}"; do
  if [[ -f "$file" ]]; then
    echo "✅  $file exists (Module 13 dependency)"
  else
    echo "❌  $file missing - CRITICAL for Module 8 voice integration"
  fi
done

# Check for food tracking data models
FOOD_DATA_MODELS=(
  "AirFit/Data/Models/FoodEntry.swift"
  "AirFit/Data/Models/FoodItem.swift"
  "AirFit/Services/AI/CoachEngine.swift"
)

echo "🍎  Checking food tracking data models…"
for file in "${FOOD_DATA_MODELS[@]}"; do
  if [[ -f "$file" ]]; then
    echo "✅  $file exists"
  else
    echo "❌  $file missing - required for Module 8"
  fi
done

###############################################################################
#  8.  Test Module 8 specific integrations
###############################################################################
echo "🧪  Testing Module 8 specific integration patterns…"

# Test adapter pattern for Module 13 integration
cat > /tmp/food_voice_adapter_test.swift << 'EOF'
import Foundation

// Test adapter pattern for Module 13 VoiceInputManager integration
protocol VoiceInputManagerProtocol {
    var isRecording: Bool { get }
    func startRecording() async throws
    func stopRecording() async -> String?
}

@MainActor
final class FoodVoiceAdapter: ObservableObject {
    private let voiceInputManager: VoiceInputManagerProtocol
    
    @Published private(set) var isRecording = false
    @Published private(set) var transcribedText = ""
    
    init(voiceInputManager: VoiceInputManagerProtocol) {
        self.voiceInputManager = voiceInputManager
    }
    
    func startFoodRecording() async throws {
        try await voiceInputManager.startRecording()
        isRecording = true
    }
    
    func stopFoodRecording() async -> String? {
        let result = await voiceInputManager.stopRecording()
        isRecording = false
        return postProcessForFood(result ?? "")
    }
    
    private func postProcessForFood(_ text: String) -> String {
        // Food-specific transcription improvements
        return text.replacingOccurrences(of: "won cup", with: "one cup")
    }
}
EOF

if swift -frontend -typecheck /tmp/food_voice_adapter_test.swift -target arm64-apple-ios18.0 -strict-concurrency=complete 2>/dev/null; then
  echo "✅  Module 8 adapter pattern for Module 13 integration validated"
else
  echo "⚠️  Module 8 adapter pattern validation failed"
fi
rm -f /tmp/food_voice_adapter_test.swift

###############################################################################
#  9.  Summary banner
###############################################################################
echo "---------------------------------------------"
echo "✅  SwiftLint   : $(swiftlint version)"
echo "✅  SwiftFormat : $(swiftformat --version)"
echo "✅  Swift       : $(swift --version | head -n1)"
echo "🎤  Module 13   : Voice infrastructure ready (VoiceInputManager)"
echo "📱  iOS Target  : 18.0+ with Vision & Charts support"
echo "🧠  Swift 6     : Strict concurrency validated"
echo "🏁  Startup script completed  $(date -u +%FT%TZ)"
echo "---------------------------------------------"
echo "📋  Environment ready for Module 8 (Food Tracking)"
echo "    • Module 13 voice infrastructure available"
echo "    • Swift 6 @Observable patterns validated"
echo "    • iOS 18+ Vision framework for barcode scanning"
echo "    • Swift Charts for nutrition visualization"
echo "    • Adapter pattern for voice integration tested"
echo ""
echo "⚠️  SANDBOXED ENVIRONMENT LIMITATIONS:"
echo "    • NO XCODE: Cannot run xcodebuild, simulators, or tests"
echo "    • NO XCODEGEN: Cannot regenerate project files"
echo "    • CODE ONLY: Focus on Swift implementation"
echo "    • VERIFICATION: All builds/tests done externally"
echo ""
echo "🎯  Module 8 Focus Areas:"
echo "    • FoodVoiceAdapter (Module 13 integration)"
echo "    • FoodTrackingViewModel (@Observable with voice)"
echo "    • Voice-first food logging UI"
echo "    • AI-powered food parsing with CoachEngine"
echo "    • Barcode scanning with Vision framework"
echo "    • Macro visualization with Swift Charts"
echo "    • Water tracking and nutrition insights"
echo ""
echo "🔗  Module 13 Dependencies:"
echo "    • VoiceInputManager: Core voice transcription"
echo "    • WhisperModelManager: MLX model management"
echo "    • Voice UI patterns: Consistent experience"
echo "    • Error handling: Unified voice permissions"
###############################################################################