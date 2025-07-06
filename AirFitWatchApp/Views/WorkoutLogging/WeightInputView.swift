import SwiftUI
#if os(watchOS)
import WatchKit
#endif

/// Screen 3: Weight input with crown
struct WeightInputView: View {
    @Bindable var coordinator: WorkoutLoggingCoordinator
    @FocusState private var isFocused: Bool
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text(coordinator.exerciseName)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text("Weight (\(weightUnit))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.top)
            
            Spacer()
            
            // Crown input visualization
            ZStack {
                // Crown indicator ring with gradient
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.orange.opacity(0.3), .orange.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 140, height: 140)
                
                // Weight value
                Text(String(format: "%.1f", coordinator.weight))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .focusable()
            .focused($isFocused)
            .digitalCrownRotation(
                detent: $coordinator.weight,
                from: 0,
                through: 500,
                by: weightUnit == "lbs" ? 5.0 : 2.5,  // 5lb or 2.5kg increments
                sensitivity: .low,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
            .animation(.interactiveSpring(duration: 0.1), value: coordinator.weight)
            
            // Previous weight reference
            if let lastSet = coordinator.workoutManager?.currentWorkoutData.exercises.last?.sets.dropLast().last,
               let lastWeight = lastSet.weightKg {
                Text("Previous: \(String(format: "%.1f", lastWeight)) \(weightUnit)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .padding(.top, 8)
            } else {
                Text("Tap to continue")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .padding(.top, 8)
            }
            
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
                
                // Unit toggle
                Button {
                    if weightUnit == "lbs" {
                        weightUnit = "kg"
                        coordinator.weight = coordinator.weight / 2.20462
                    } else {
                        weightUnit = "lbs"
                        coordinator.weight = coordinator.weight * 2.20462
                    }
                    #if os(watchOS)
                    WKInterfaceDevice.current().play(.click)
                    #endif
                } label: {
                    Text(weightUnit)
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 44, height: 44)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
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

/// Special screen for drop set second weight
struct DropSetWeightInputView: View {
    @Bindable var coordinator: WorkoutLoggingCoordinator
    @FocusState private var isFocused: Bool
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text(coordinator.exerciseName)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text("Drop Weight (\(weightUnit))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("From \(String(format: "%.1f", coordinator.weight)) → ?")
                    .font(.system(size: 14))
                    .foregroundStyle(.orange)
            }
            .padding(.top)
            
            Spacer()
            
            // Crown input
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.red.opacity(0.3), .orange.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 140, height: 140)
                
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", coordinator.dropWeight))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    // Percentage drop
                    let percentDrop = ((coordinator.weight - coordinator.dropWeight) / coordinator.weight) * 100
                    if percentDrop > 0 {
                        Text("-\(Int(percentDrop))%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.red)
                    }
                }
            }
            .focusable()
            .focused($isFocused)
            .digitalCrownRotation(
                detent: $coordinator.dropWeight,
                from: 0,
                through: coordinator.weight,  // Can't be more than original weight
                by: weightUnit == "lbs" ? 5.0 : 2.5,  // 5lb or 2.5kg increments
                sensitivity: .low,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
            .animation(.interactiveSpring(duration: 0.1), value: coordinator.dropWeight)
            
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
            // Set initial drop weight to 70-80% of original
            coordinator.dropWeight = coordinator.weight * 0.75
        }
    }
}