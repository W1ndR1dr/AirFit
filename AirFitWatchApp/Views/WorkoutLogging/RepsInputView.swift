import SwiftUI
#if os(watchOS)
import WatchKit
#endif

/// Screen 2: Reps input with crown
struct RepsInputView: View {
    @Bindable var coordinator: WorkoutLoggingCoordinator
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text(coordinator.exerciseName)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text("Reps")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.top)
            
            Spacer()
            
            // Crown input visualization
            ZStack {
                // Crown indicator ring
                Circle()
                    .stroke(lineWidth: 3)
                    .foregroundStyle(.blue.opacity(0.3))
                    .frame(width: 140, height: 140)
                
                // Reps value
                Text("\(coordinator.reps)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .focusable()
            .focused($isFocused)
            .digitalCrownRotation(
                detent: $coordinator.reps,
                from: 1,
                through: 50,
                by: 1,
                sensitivity: .low,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
            .animation(.interactiveSpring(duration: 0.1), value: coordinator.reps)
            
            // Tap hint
            Text("Tap to continue")
                .font(.system(size: 12))
                .foregroundStyle(.secondary.opacity(0.7))
                .padding(.top, 8)
            
            Spacer()
            
            // Navigation
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
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
            .padding(.horizontal)
            .padding(.bottom)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                coordinator.navigateForward()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            isFocused = true
        }
    }
}

/// Special screen for unilateral exercises
struct UnilateralRepsInputView: View {
    @Bindable var coordinator: WorkoutLoggingCoordinator
    @State private var currentSide: String = "left"  // "left" or "right"
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text(coordinator.exerciseName)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("Reps")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(currentSide == "left" ? "Left" : "Right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(currentSide == "left" ? .blue : .green)
                }
            }
            .padding(.top)
            
            Spacer()
            
            // Side indicator
            HStack(spacing: 20) {
                SideIndicator(side: "left", isActive: currentSide == "left", reps: coordinator.leftReps)
                SideIndicator(side: "right", isActive: currentSide == "right", reps: coordinator.rightReps)
            }
            .padding(.bottom, 20)
            
            // Crown input
            ZStack {
                Circle()
                    .stroke(lineWidth: 3)
                    .foregroundStyle((currentSide == "left" ? Color.blue : Color.green).opacity(0.3))
                    .frame(width: 140, height: 140)
                
                Text("\(currentSide == "left" ? coordinator.leftReps : coordinator.rightReps)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .focusable()
            .focused($isFocused)
            .digitalCrownRotation(
                detent: currentSide == "left" ? $coordinator.leftReps : $coordinator.rightReps,
                from: 1,
                through: 50,
                by: 1,
                sensitivity: .low,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
            .animation(.interactiveSpring(duration: 0.1), value: coordinator.leftReps)
            .animation(.interactiveSpring(duration: 0.1), value: coordinator.rightReps)
            
            // Instructions
            Text(currentSide == "left" ? "Tap for right side" : "Tap to continue")
                .font(.system(size: 12))
                .foregroundStyle(.secondary.opacity(0.7))
                .padding(.top, 8)
            
            Spacer()
            
            // Navigation
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if currentSide == "right" {
                            currentSide = "left"
                        } else {
                            coordinator.navigateBackward()
                        }
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
            .padding(.horizontal)
            .padding(.bottom)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                if currentSide == "left" {
                    currentSide = "right"
                    #if os(watchOS)
                    WKInterfaceDevice.current().play(.click)
                    #endif
                } else {
                    coordinator.navigateForward()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            isFocused = true
            currentSide = "left"
        }
    }
}

// Helper view for side indicator
struct SideIndicator: View {
    let side: String  // "left" or "right"
    let isActive: Bool
    let reps: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text(side == "left" ? "L" : "R")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isActive ? .white : .secondary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isActive ? (side == "left" ? Color.blue : Color.green) : Color.gray.opacity(0.2))
                )
            
            if reps > 0 {
                Text("\(reps)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}