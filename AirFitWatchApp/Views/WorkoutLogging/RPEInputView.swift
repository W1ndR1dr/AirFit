import SwiftUI
#if os(watchOS)
import WatchKit
#endif

/// Screen 4: RPE input with crown
struct RPEInputView: View {
    @Bindable var coordinator: WorkoutLoggingCoordinator
    @FocusState private var isFocused: Bool
    
    private var rpeColor: Color {
        switch coordinator.rpe {
        case 0..<5: return .green
        case 5..<7: return .yellow
        case 7..<9: return .orange
        default: return .red
        }
    }
    
    private var rpeDescription: String {
        switch coordinator.rpe {
        case 0..<3: return "Very Easy"
        case 3..<5: return "Easy"
        case 5..<7: return "Moderate"
        case 7..<8: return "Hard"
        case 8..<9: return "Very Hard"
        case 9..<10: return "Near Max"
        case 10: return "Maximum"
        default: return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text(coordinator.exerciseName)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text("RPE")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("Rate of Perceived Exertion")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.top)
            
            Spacer()
            
            // Crown input with color feedback
            ZStack {
                // Colored ring that changes with RPE
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [rpeColor.opacity(0.3), rpeColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 140, height: 140)
                    .animation(.smooth(duration: 0.3), value: coordinator.rpe)
                
                // RPE value and description
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", coordinator.rpe))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text(rpeDescription)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(rpeColor)
                        .animation(.smooth(duration: 0.2), value: rpeDescription)
                }
            }
            .focusable()
            .focused($isFocused)
            .digitalCrownRotation(
                detent: $coordinator.rpe,
                from: 1,
                through: 10,
                by: 0.5,
                sensitivity: .low,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
            .animation(.interactiveSpring(duration: 0.1), value: coordinator.rpe)
            
            // RPE scale reference
            HStack(spacing: 4) {
                ForEach(1...10, id: \.self) { value in
                    Rectangle()
                        .fill(rpeColorForValue(Double(value)))
                        .frame(width: 12, height: 6)
                        .opacity(abs(Double(value) - coordinator.rpe) < 1 ? 1 : 0.3)
                }
            }
            .padding(.top, 12)
            
            Text("Tap to continue")
                .font(.system(size: 12))
                .foregroundStyle(.secondary.opacity(0.7))
                .padding(.top, 8)
            
            Spacer()
            
            // Info and navigation
            VStack(spacing: 12) {
                // RPE guide
                Button {
                    showRPEGuide()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                        Text("What's RPE?")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                
                // Navigation
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.smooth(duration: 0.2)) {
                            coordinator.navigateBackward()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 44, height: 44)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.smooth(duration: 0.2)) {
                coordinator.navigateForward()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            isFocused = true
        }
    }
    
    private func rpeColorForValue(_ value: Double) -> Color {
        switch value {
        case 0..<5: return .green
        case 5..<7: return .yellow
        case 7..<9: return .orange
        default: return .red
        }
    }
    
    private func showRPEGuide() {
        // Could show a sheet with RPE explanation
        // For now, just haptic feedback
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
    }
}