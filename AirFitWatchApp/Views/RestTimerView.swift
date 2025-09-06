import SwiftUI
#if os(watchOS)
import WatchKit
#endif

struct RestTimerView: View {
    let duration: TimeInterval
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    @State private var timeRemaining: TimeInterval
    @State private var timer: Timer?
    @State private var progress: Double = 1.0
    @State private var lastHapticTime: TimeInterval = 0
    
    init(duration: TimeInterval, onComplete: @escaping () -> Void, onSkip: @escaping () -> Void) {
        self.duration = duration
        self.onComplete = onComplete
        self.onSkip = onSkip
        self._timeRemaining = State(initialValue: duration)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Rest")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.secondary)
            
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 140, height: 140)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.smooth(duration: 0.1), value: progress)
                
                VStack(spacing: 4) {
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    
                    Text("seconds")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 20) {
                // Add time button
                Button {
                    addTime(15)
                } label: {
                    Label("+15s", systemImage: "plus.circle")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                // Skip button
                Button {
                    endTimer()
                    onSkip()
                } label: {
                    Label("Skip", systemImage: "forward.fill")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .focusable()
        .digitalCrownRotation(
            detent: $timeRemaining,
            from: 0,
            through: duration * 2,
            by: 5,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                if timeRemaining > 0 {
                    timeRemaining -= 0.1
                    progress = timeRemaining / duration
                    
                    // Haptic feedback at specific intervals
                    checkHapticFeedback()
                    
                    if timeRemaining <= 0 {
                        endTimer()
                        onComplete()
                    }
                }
            }
        }
    }
    
    private func endTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func addTime(_ seconds: TimeInterval) {
        timeRemaining += seconds
        if timeRemaining > duration {
            progress = 1.0
        } else {
            progress = timeRemaining / duration
        }
        
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
    }
    
    private func checkHapticFeedback() {
        let roundedTime = round(timeRemaining)
        
        // Haptic at 10s, 5s, 3s, 2s, 1s, 0s
        if roundedTime != lastHapticTime {
            lastHapticTime = roundedTime
            
            #if os(watchOS)
            switch roundedTime {
            case 10:
                WKInterfaceDevice.current().play(.click)
            case 5:
                WKInterfaceDevice.current().play(.directionUp)
            case 3, 2, 1:
                WKInterfaceDevice.current().play(.notification)
            case 0:
                WKInterfaceDevice.current().play(.success)
            default:
                break
            }
            #endif
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = Int(ceil(time))
        return "\(seconds)"
    }
}

// MARK: - Preview

#Preview {
    RestTimerView(
        duration: 60,
        onComplete: { AppLogger.info("Rest complete", category: .ui) },
        onSkip: { AppLogger.info("Rest skipped", category: .ui) }
    )
}