import SwiftUI
import Observation

/// Coordinates the multi-screen workout logging flow
@MainActor
@Observable
final class WorkoutLoggingCoordinator: ObservableObject {
    // MARK: - Screen State
    enum LoggingScreen: Int, CaseIterable {
        case exercise = 0
        case reps = 1
        case weight = 2
        case rpe = 3
        case comment = 4
        case rest = 5
        
        // Special screens
        case unilateralReps = 10
        case dropSetWeight = 11
        
        var isCore: Bool {
            rawValue < 10
        }
    }
    
    // MARK: - Properties
    private(set) var currentScreen: LoggingScreen = .exercise
    private(set) var screens: [LoggingScreen] = []
    
    // Exercise data
    var exerciseName: String = ""
    var exerciseComment: String = ""
    
    // Set data
    var reps: Int = 10
    var weight: Double = 45.0  // Default to 45 lbs (standard barbell)
    var rpe: Double = 7.0
    var setComment: String = ""
    
    // Special cases
    var isUnilateral: Bool = false
    var leftReps: Int = 10
    var rightReps: Int = 10
    var isDropSet: Bool = false
    var dropWeight: Double = 15.0
    
    // Workout manager reference
    weak var workoutManager: WatchWorkoutManager?
    
    // MARK: - Initialization
    init(workoutManager: WatchWorkoutManager? = nil) {
        self.workoutManager = workoutManager
        setupInitialFlow()
    }
    
    // MARK: - Flow Management
    func setupInitialFlow() {
        // Start with exercise screen
        screens = [.exercise]
        currentScreen = .exercise
        
        // Load defaults from current exercise
        if let currentExercise = workoutManager?.currentPlannedExercise {
            exerciseName = currentExercise.name
            reps = currentExercise.targetReps
            
            // Check if exercise is unilateral
            detectSpecialCases()
        }
        
        // Load weight from last set if available
        if let lastExercise = workoutManager?.currentWorkoutData.exercises.last,
           let lastSet = lastExercise.sets.last,
           let lastWeight = lastSet.weightKg {
            weight = lastWeight
        }
    }
    
    func detectSpecialCases() {
        // Detect unilateral exercises
        isUnilateral = exerciseName.isUnilateralExercise
        
        // Reset special case data
        isDropSet = false
        leftReps = reps
        rightReps = reps
    }
    
    func buildScreenFlow() -> [LoggingScreen] {
        var flow: [LoggingScreen] = [.exercise]
        
        if isUnilateral {
            flow.append(.unilateralReps)
        } else {
            flow.append(.reps)
        }
        
        flow.append(.weight)
        
        if isDropSet {
            flow.append(.dropSetWeight)
        }
        
        flow.append(.rpe)
        flow.append(.comment)
        flow.append(.rest)
        
        return flow
    }
    
    func navigateForward() {
        // Special handling for exercise screen
        if currentScreen == .exercise {
            // Detect special cases and rebuild flow
            detectSpecialCases()
            screens = buildScreenFlow()
        }
        
        // Check for drop set detection from comments
        if currentScreen == .comment && !setComment.isEmpty {
            if let modification = setComment.detectSetModification() {
                switch modification {
                case .dropSet:
                    isDropSet = true
                    // Insert drop set screen if not already there
                    if !screens.contains(.dropSetWeight) {
                        if let restIndex = screens.firstIndex(of: .rest) {
                            screens.insert(.dropSetWeight, at: restIndex)
                        }
                    }
                case .unilateral:
                    // Handle if user mentions unilateral in comment but didn't detect from name
                    break
                }
            }
        }
        
        // Move to next screen
        if let currentIndex = screens.firstIndex(of: currentScreen),
           currentIndex < screens.count - 1 {
            currentScreen = screens[currentIndex + 1]
        } else if currentScreen == .rest || currentScreen == .comment {
            // Complete the set
            completeSet()
        }
    }
    
    func navigateBackward() {
        if let currentIndex = screens.firstIndex(of: currentScreen),
           currentIndex > 0 {
            currentScreen = screens[currentIndex - 1]
        }
    }
    
    func skipToRest() {
        currentScreen = .rest
    }
    
    private func completeSet() {
        // Log the set based on special cases
        if isUnilateral {
            // Log left side
            workoutManager?.logSet(
                reps: leftReps,
                weight: weight,
                duration: nil,
                rpe: rpe,
                comment: setComment.isEmpty ? nil : setComment,
                side: "L"
            )
            
            // Log right side
            workoutManager?.logSet(
                reps: rightReps,
                weight: weight,
                duration: nil,
                rpe: rpe,
                comment: setComment.isEmpty ? nil : setComment,
                side: "R"
            )
        } else if isDropSet {
            // Log first set
            workoutManager?.logSet(
                reps: reps,
                weight: weight,
                duration: nil,
                rpe: rpe,
                comment: "Drop set: \(String(format: "%.1f", weight))lbs → \(String(format: "%.1f", dropWeight))lbs" + (setComment.isEmpty ? "" : ". \(setComment)")
            )
            
            // Could prompt for second set reps or use a default
            // For now, we'll just log the drop weight info in the comment
        } else {
            // Normal set
            workoutManager?.logSet(
                reps: reps,
                weight: weight,
                duration: nil,
                rpe: rpe,
                comment: setComment.isEmpty ? nil : setComment,
                side: nil
            )
        }
        
        // Notify that set is complete
        NotificationCenter.default.post(name: .setCompleted, object: nil)
        
        // Reset for next set
        resetForNextSet()
    }
    
    private func resetForNextSet() {
        // Keep weight and exercise name
        // Reset reps to target
        if let currentExercise = workoutManager?.currentPlannedExercise {
            reps = currentExercise.targetReps
            leftReps = currentExercise.targetReps
            rightReps = currentExercise.targetReps
        }
        
        // Reset other values
        rpe = 7.0
        setComment = ""
        isDropSet = false
        
        // Rebuild flow for next set
        currentScreen = .reps
        screens = buildScreenFlow()
    }
}

// MARK: - String Extensions for Detection

extension String {
    var isUnilateralExercise: Bool {
        let unilateralKeywords = [
            "/side", "per side", "each side", "/leg", "each leg",
            "single arm", "single leg", "single-arm", "single-leg",
            "unilateral", "bulgarian split", "bss",
            "lunge", "lunges", "one arm", "one leg", "one-arm", "one-leg",
            "l/r", "left/right", "r leg only", "l leg only",
            "alternating", "pistol squat", "single db", "single dumbbell",
            "concentration curl", "one handed", "one-handed"
        ]
        let lowercased = self.lowercased()
        return unilateralKeywords.contains { lowercased.contains($0) }
    }
    
    var isDropSetLikely: Bool {
        let dropSetKeywords = ["drop set", "dropset", "strip set", "drop", "descending"]
        return dropSetKeywords.contains { self.lowercased().contains($0) }
    }
    
    func detectSetModification() -> SetModification? {
        let lowercased = self.lowercased()
        
        // Drop set patterns
        let dropSetPatterns = [
            "dropped to", "drop to", "then",
            "→", "->", ">",  // Arrow notations
            #"\d+\s*[xX]\s*\d+"#  // Pattern like "60x7"
        ]
        
        for pattern in dropSetPatterns {
            if pattern.starts(with: #"\"#) {
                // Regex pattern
                if lowercased.range(of: pattern, options: .regularExpression) != nil {
                    return .dropSet
                }
            } else if lowercased.contains(pattern) {
                return .dropSet
            }
        }
        
        // Unilateral patterns in comments
        if lowercased.contains("right only") || 
           lowercased.contains("left only") ||
           lowercased.contains("r leg only") ||
           lowercased.contains("l leg only") ||
           lowercased.contains("one side") ||
           lowercased.contains("single side") {
            return .unilateral
        }
        
        return nil
    }
}

// MARK: - Supporting Types

enum SetModification {
    case dropSet
    case unilateral
}

// Side is represented as String: "L" for left, "R" for right, nil for both

// MARK: - Notification Names

extension Notification.Name {
    static let setCompleted = Notification.Name("setCompleted")
}

// Note: The logSet method with comment and side support needs to be 
// implemented in WatchWorkoutManager class itself, not as an extension,
// because currentWorkoutData is private(set)