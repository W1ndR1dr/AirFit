import SwiftUI

/// Main container for the multi-screen workout logging flow
struct WorkoutLoggingView: View {
    @StateObject private var coordinator: WorkoutLoggingCoordinator
    @State private var showTransition = false
    
    init(workoutManager: WatchWorkoutManager) {
        _coordinator = StateObject(wrappedValue: WorkoutLoggingCoordinator(workoutManager: workoutManager))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color.gray.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Screen content with transitions
            Group {
                switch coordinator.currentScreen {
                case .exercise:
                    ExerciseInputView(coordinator: coordinator)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    
                case .reps:
                    RepsInputView(coordinator: coordinator)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    
                case .unilateralReps:
                    UnilateralRepsInputView(coordinator: coordinator)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    
                case .weight:
                    WeightInputView(coordinator: coordinator)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    
                case .dropSetWeight:
                    DropSetWeightInputView(coordinator: coordinator)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    
                case .rpe:
                    RPEInputView(coordinator: coordinator)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    
                case .comment:
                    CommentInputView(coordinator: coordinator)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    
                case .rest:
                    RestTimerView(
                        duration: TimeInterval(
                            coordinator.workoutManager?.currentPlannedExercise?.restSeconds ?? 60
                        ),
                        onComplete: {
                            // Reset for next set
                            coordinator.setupInitialFlow()
                        },
                        onSkip: {
                            // Reset for next set
                            coordinator.setupInitialFlow()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                }
            }
            .animation(.smooth(duration: 0.3), value: coordinator.currentScreen)
            
            // Progress indicator
            VStack {
                ProgressIndicator(
                    current: coordinator.screens.firstIndex(of: coordinator.currentScreen) ?? 0,
                    total: coordinator.screens.count
                )
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

/// Progress indicator showing current screen position
struct ProgressIndicator: View {
    let current: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: index == current ? 20 : 12, height: 4)
                    .animation(.smooth(duration: 0.2), value: current)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    WorkoutLoggingView(workoutManager: WatchWorkoutManager())
}