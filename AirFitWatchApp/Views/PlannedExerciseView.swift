import SwiftUI
import HealthKit
#if os(watchOS)
import AVFoundation
#endif

struct PlannedExerciseView: View {
    let workoutManager: WatchWorkoutManager
    @State private var currentInput: InputType = .reps
    @State private var reps: Int = 10
    @State private var weight: Double = 20.0
    @State private var rpe: Double = 7.0
    @State private var showingDictation = false
    @State private var showingRestTimer = false
    @FocusState private var focusedField: InputType?
    
    enum InputType: CaseIterable {
        case reps
        case weight
        case rpe
        
        var label: String {
            switch self {
            case .reps: return "Reps"
            case .weight: return "Weight (kg)"
            case .rpe: return "RPE"
            }
        }
    }
    
    var body: some View {
        if showingRestTimer {
            RestTimerView(
                duration: TimeInterval(workoutManager.currentPlannedExercise?.restSeconds ?? 60),
                onComplete: {
                    showingRestTimer = false
                    // Check if there are more sets
                    if let progress = workoutManager.currentSetProgress,
                       progress.current >= progress.total {
                        // No more sets, next exercise will be loaded
                    }
                },
                onSkip: {
                    showingRestTimer = false
                }
            )
        } else {
            VStack(spacing: 0) {
                // Exercise header
                if let exercise = workoutManager.currentPlannedExercise {
                    exerciseHeader(exercise)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                Spacer()
                
                // Main input display
                mainInputDisplay
                
                Spacer()
                
                // Action buttons
                actionButtons
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .navigationBarHidden(true)
            .onAppear {
                setupInitialValues()
                focusedField = .reps
            }
            .sheet(isPresented: $showingDictation) {
                DictationView(
                    title: "Exercise Name", 
                    initialText: workoutManager.currentPlannedExercise?.name ?? "",
                    placeholder: "Exercise name"
                ) { newName in
                    // Note: ExerciseBuilderData.name is immutable (let constant)
                    // To support exercise name changes, we would need to:
                    // 1. Make name mutable in ExerciseBuilderData, or
                    // 2. Create a new ExerciseBuilderData with the updated name
                    // For now, this feature is disabled.
                    AppLogger.warning("Exercise name modification not currently supported", category: .ui)
                }
            }
        }
    }
    
    // MARK: - Exercise Header
    
    @ViewBuilder
    private func exerciseHeader(_ exercise: PlannedExerciseData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                Spacer()
                
                // Dictation button for exercise name
                Button {
                    showingDictation = true
                } label: {
                    Image(systemName: "mic.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            
            if let progress = workoutManager.currentSetProgress {
                HStack(spacing: 8) {
                    Text("Set \(progress.current) of \(progress.total)")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    
                    if let targetRange = exercise.targetRepRange {
                        Text("• Target: \(targetRange)")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Main Input Display
    
    private var mainInputDisplay: some View {
        VStack(spacing: 8) {
            Text(currentInput.label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            
            ZStack {
                // Digital crown indicator
                Circle()
                    .stroke(lineWidth: 3)
                    .foregroundStyle(.blue.opacity(0.3))
                    .frame(width: 120, height: 120)
                
                // Current value
                Group {
                    switch currentInput {
                    case .reps:
                        Text("\(reps)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                    case .weight:
                        Text(String(format: "%.1f", weight))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                    case .rpe:
                        Text(String(format: "%.1f", rpe))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                    }
                }
                .focusable()
                .digitalCrownRotation(detent: $reps, from: 1, through: 50, by: 1, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
                .opacity(currentInput == .reps ? 1 : 0)
                
                Text(String(format: "%.1f", weight))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .focusable()
                    .digitalCrownRotation(detent: $weight, from: 0, through: 200, by: 2.5, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
                    .opacity(currentInput == .weight ? 1 : 0)
                
                Text(String(format: "%.1f", rpe))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .focusable()
                    .digitalCrownRotation(detent: $rpe, from: 1, through: 10, by: 0.5, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
                    .opacity(currentInput == .rpe ? 1 : 0)
            }
            
            // Tap to continue hint
            Text("Tap to continue")
                .font(.system(size: 12))
                .foregroundStyle(.secondary.opacity(0.7))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            advanceToNextInput()
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Skip exercise button
            Button {
                workoutManager.skipCurrentExercise()
            } label: {
                Label("Skip", systemImage: "forward.fill")
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            // Previous input (if not on first)
            if currentInput != .reps {
                Button {
                    goToPreviousInput()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialValues() {
        // Set default values based on planned exercise
        if let exercise = workoutManager.currentPlannedExercise {
            reps = exercise.targetReps
            
            // Try to use last set's weight as default
            if let lastExercise = workoutManager.currentWorkoutData.exercises.last,
               let lastSet = lastExercise.sets.last,
               let lastWeight = lastSet.weightKg {
                weight = lastWeight
            }
        }
    }
    
    private func advanceToNextInput() {
        switch currentInput {
        case .reps:
            currentInput = .weight
            focusedField = .weight
        case .weight:
            currentInput = .rpe
            focusedField = .rpe
        case .rpe:
            // Log the set and reset for next
            logCurrentSet()
        }
    }
    
    private func goToPreviousInput() {
        switch currentInput {
        case .reps:
            break // Already at first
        case .weight:
            currentInput = .reps
            focusedField = .reps
        case .rpe:
            currentInput = .weight
            focusedField = .weight
        }
    }
    
    private func logCurrentSet() {
        // Log the set with all collected values
        workoutManager.logSet(
            reps: reps,
            weight: weight,
            duration: nil,
            rpe: rpe
        )
        
        // Check if we need to show rest timer
        if let progress = workoutManager.currentSetProgress,
           progress.current < progress.total {
            // More sets remaining, show rest timer
            showingRestTimer = true
        }
        
        // Reset to reps for next set
        currentInput = .reps
        focusedField = .reps
        
        // Keep weight the same for next set, reset others
        reps = workoutManager.currentPlannedExercise?.targetReps ?? 10
        rpe = 7.0
    }
}

// MARK: - Preview

#Preview {
    PlannedExerciseView(workoutManager: WatchWorkoutManager())
}