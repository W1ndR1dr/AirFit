import Foundation
import WatchConnectivity

/// # WatchWorkoutPlanReceiver
///
/// ## Purpose
/// Handles receiving planned workout data from iOS and coordinating with
/// WatchWorkoutManager for structured workout execution on Apple Watch.
///
/// ## Key Responsibilities
/// - Receive PlannedWorkoutData via WatchConnectivity
/// - Validate incoming workout plans
/// - Coordinate with WatchWorkoutManager for execution
/// - Handle transfer acknowledgments and error reporting
/// - Provide UI notifications for planned workout availability
///
/// ## Integration
/// - **iOS Transfer**: Receives data from WorkoutPlanTransferService
/// - **Watch Execution**: Coordinates with WatchWorkoutManager
/// - **UI Updates**: Posts notifications for SwiftUI views
///
/// ## Usage
/// ```swift
/// let receiver = WatchWorkoutPlanReceiver(workoutManager: workoutManager)
/// await receiver.configure()
///
/// // Service automatically handles incoming planned workouts
/// // UI can observe via NotificationCenter or @StateObject
/// ```

// MARK: - Message Types

/// Type-safe representation of incoming workout transfer messages
struct WorkoutTransferMessage: Sendable {
    let type: String
    let planId: String?
    let planData: Data?
    
    init?(from dictionary: [String: Any]) {
        guard let type = dictionary["type"] as? String else {
            return nil
        }
        self.type = type
        self.planId = dictionary["planId"] as? String
        self.planData = dictionary["planData"] as? Data
    }
}

@MainActor
@Observable
final class WatchWorkoutPlanReceiver: NSObject {
    // MARK: - Properties
    private let session: WCSession
    private let workoutManager: WatchWorkoutManager
    private let decoder = JSONDecoder()

    // Planned workout state
    private(set) var availablePlannedWorkout: PlannedWorkoutData?
    private(set) var isReceivingWorkout = false
    private(set) var lastReceiveError: String?

    // Service state
    private var isConfigured = false

    // MARK: - Initialization
    init(workoutManager: WatchWorkoutManager) {
        self.workoutManager = workoutManager
        self.session = WCSession.default

        super.init()

        // Configure JSON decoding
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Configuration
    func configure() async {
        guard !isConfigured else { return }
        guard WCSession.isSupported() else {
            AppLogger.error("WatchConnectivity not supported", error: nil, category: .data)
            return
        }

        session.delegate = self
        session.activate()

        isConfigured = true
        AppLogger.info("WatchWorkoutPlanReceiver configured", category: .data)
    }

    // MARK: - Planned Workout Management

    /// Check if a planned workout is available for execution
    var hasAvailablePlannedWorkout: Bool {
        availablePlannedWorkout != nil
    }

    /// Start executing the available planned workout
    func startAvailablePlannedWorkout() async throws {
        guard let plannedWorkout = availablePlannedWorkout else {
            throw WorkoutError.saveFailed // Consider creating specific error
        }

        AppLogger.info("Starting available planned workout: \(plannedWorkout.name)", category: .health)

        // Load the planned workout into the manager
        workoutManager.loadPlannedWorkout(plannedWorkout)

        // Start the workout execution
        try await workoutManager.startPlannedWorkout()

        // Clear the available workout (it's now in progress)
        availablePlannedWorkout = nil

        // Notify UI of state change
        NotificationCenter.default.post(
            name: .plannedWorkoutStarted,
            object: nil,
            userInfo: ["workoutName": plannedWorkout.name]
        )
    }

    /// Clear the currently available planned workout
    func clearAvailablePlannedWorkout() {
        availablePlannedWorkout = nil
        AppLogger.info("Cleared available planned workout", category: .data)

        NotificationCenter.default.post(name: .plannedWorkoutCleared, object: nil)
    }

    /// Get a summary of the available planned workout
    var plannedWorkoutSummary: String? {
        guard let workout = availablePlannedWorkout else { return nil }

        let exerciseCount = workout.plannedExercises.count
        let duration = workout.estimatedDuration
        let exercises = workout.plannedExercises.prefix(3).map(\.name).joined(separator: ", ")

        return "\(exerciseCount) exercises • \(duration)min\n\(exercises)"
    }

    // MARK: - Private Methods

    private func handleReceivedMessage(_ message: WorkoutTransferMessage) {
        AppLogger.info("Received message from iPhone: \(message.type)", category: .data)

        switch message.type {
        case "plannedWorkout":
            handlePlannedWorkoutMessage(message)
        default:
            AppLogger.warning("Unknown message type: \(message.type)", category: .data)
        }
    }

    private func handlePlannedWorkoutMessage(_ message: WorkoutTransferMessage) {
        isReceivingWorkout = true
        lastReceiveError = nil

        do {
            guard let planData = message.planData else {
                throw NSError(domain: "WatchWorkoutPlanReceiver", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Missing plan data"])
            }

            // Decode the planned workout
            let plannedWorkout = try decoder.decode(PlannedWorkoutData.self, from: planData)

            // Validate the workout plan
            try validatePlannedWorkout(plannedWorkout)

            // Store the available workout
            availablePlannedWorkout = plannedWorkout

            AppLogger.info("Successfully received planned workout: \(plannedWorkout.name)", category: .data)

            // Send success acknowledgment
            let planId = message.planId ?? plannedWorkout.id.uuidString
            sendAcknowledgment(planId: planId, success: true, error: nil)

            // Notify UI
            NotificationCenter.default.post(
                name: .plannedWorkoutReceived,
                object: nil,
                userInfo: [
                    "workout": plannedWorkout,
                    "workoutName": plannedWorkout.name
                ]
            )

        } catch {
            let errorMessage = "Failed to receive planned workout: \(error.localizedDescription)"
            lastReceiveError = errorMessage
            AppLogger.error("Failed to process planned workout", error: error, category: .data)

            // Send error acknowledgment
            let planId = message.planId ?? "unknown"
            sendAcknowledgment(planId: planId, success: false, error: errorMessage)
        }

        isReceivingWorkout = false
    }

    private func validatePlannedWorkout(_ workout: PlannedWorkoutData) throws {
        guard !workout.name.isEmpty else {
            throw NSError(domain: "WatchWorkoutPlanReceiver", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Workout must have a name"])
        }

        guard !workout.plannedExercises.isEmpty else {
            throw NSError(domain: "WatchWorkoutPlanReceiver", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "Workout must have exercises"])
        }

        guard workout.estimatedDuration > 0 else {
            throw NSError(domain: "WatchWorkoutPlanReceiver", code: -4,
                          userInfo: [NSLocalizedDescriptionKey: "Workout must have positive duration"])
        }

        // Validate exercises
        for exercise in workout.plannedExercises {
            guard !exercise.name.isEmpty else {
                throw NSError(domain: "WatchWorkoutPlanReceiver", code: -5,
                              userInfo: [NSLocalizedDescriptionKey: "All exercises must have names"])
            }

            guard exercise.sets > 0 && exercise.targetReps > 0 else {
                throw NSError(domain: "WatchWorkoutPlanReceiver", code: -6,
                              userInfo: [NSLocalizedDescriptionKey: "All exercises must have positive sets and reps"])
            }
        }
    }

    private func sendAcknowledgment(planId: String, success: Bool, error: String?) {
        guard session.isReachable else {
            AppLogger.warning("Cannot send acknowledgment - iPhone not reachable", category: .data)
            return
        }

        let response: [String: Any] = [
            "success": success,
            "planId": planId,
            "error": error as Any,
            "timestamp": Date().timeIntervalSince1970
        ]

        do {
            try session.updateApplicationContext(response)
            AppLogger.info("Sent acknowledgment for plan: \(planId)", category: .data)
        } catch {
            AppLogger.error("Failed to send acknowledgment", error: error, category: .data)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchWorkoutPlanReceiver: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if let error = error {
                AppLogger.error("WCSession activation failed", error: error, category: .data)
            } else {
                AppLogger.info("WCSession activated with state: \(activationState.rawValue)", category: .data)
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Extract type-safe message
        guard let transferMessage = WorkoutTransferMessage(from: message) else {
            AppLogger.warning("Received invalid message format", category: .data)
            return
        }
        
        Task { @MainActor in
            handleReceivedMessage(transferMessage)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        // Extract type-safe message
        guard let transferMessage = WorkoutTransferMessage(from: message) else {
            AppLogger.warning("Received invalid message format", category: .data)
            replyHandler(["received": false, "error": "Invalid message format"])
            return
        }
        
        Task { @MainActor in
            handleReceivedMessage(transferMessage)
        }
        
        // Send immediate reply for real-time feedback
        let reply: [String: Any] = [
            "received": true,
            "timestamp": Date().timeIntervalSince1970
        ]
        replyHandler(reply)
    }
}

// MARK: - Preview Support

#if DEBUG
extension WatchWorkoutPlanReceiver {
    static func preview(workoutManager: WatchWorkoutManager) -> WatchWorkoutPlanReceiver {
        let receiver = WatchWorkoutPlanReceiver(workoutManager: workoutManager)

        // Mock available planned workout for previews
        receiver.availablePlannedWorkout = PlannedWorkoutData(
            name: "Upper Body Strength",
            workoutType: 1,
            estimatedDuration: 45,
            estimatedCalories: 300,
            plannedExercises: [
                PlannedExerciseData(
                    name: "Push-ups",
                    sets: 3,
                    targetReps: 12,
                    targetRepRange: "10-15",
                    orderIndex: 0
                ),
                PlannedExerciseData(
                    name: "Pull-ups",
                    sets: 3,
                    targetReps: 8,
                    targetRepRange: "6-10",
                    orderIndex: 1
                )
            ],
            targetMuscleGroups: ["Chest", "Back", "Arms"],
            instructions: "Focus on proper form and controlled movements",
            userId: UUID()
        )

        return receiver
    }
}
#endif
