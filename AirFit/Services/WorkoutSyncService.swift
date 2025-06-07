import Foundation
import WatchConnectivity
import SwiftData
import HealthKit

@MainActor
final class WorkoutSyncService: NSObject {
    static let shared = WorkoutSyncService()

    private let session: WCSession
    private var pendingWorkouts: [WorkoutBuilderData] = []

    override private init() {
        self.session = WCSession.default
        super.init()

        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - Watch -> iPhone
    func sendWorkoutData(_ data: WorkoutBuilderData) async {
        guard session.isReachable else {
            // Queue for later when connection is available
            pendingWorkouts.append(data)
            AppLogger.warning("Watch not reachable, queuing workout data", category: .data)
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            session.sendMessageData(encoded, replyHandler: nil) { error in
                Task { @MainActor in
                    self.pendingWorkouts.append(data)
                    AppLogger.error("Failed to send workout data", error: error, category: .data)
                }
            }
            AppLogger.info("Workout data sent to iPhone", category: .data)
        } catch {
            pendingWorkouts.append(data)
            AppLogger.error("Failed to encode workout data", error: error, category: .data)
        }
    }
    
    // MARK: - Retry Pending Workouts
    func retryPendingWorkouts() async {
        guard session.isReachable, !pendingWorkouts.isEmpty else { return }
        
        let workoutsToRetry = pendingWorkouts
        pendingWorkouts.removeAll()
        
        for workout in workoutsToRetry {
            await sendWorkoutData(workout)
        }
    }


    // MARK: - Process Received Data
    func processReceivedWorkout(_ data: WorkoutBuilderData, modelContext: ModelContext) async throws {
        let workout = Workout(
            name: HKWorkoutActivityType(rawValue: UInt(data.workoutType))?.name ?? "Workout",
            workoutType: .general
        )
        workout.id = data.id
        workout.plannedDate = data.startTime
        workout.completedDate = data.endTime
        workout.caloriesBurned = data.totalCalories
        workout.durationSeconds = data.duration
        
        // Link to existing HealthKit workout if from Watch
        if let healthKitID = data.healthKitWorkoutID {
            workout.healthKitWorkoutID = healthKitID
            workout.healthKitSyncedDate = Date()
        }

        for exerciseData in data.exercises {
            let exercise = Exercise(
                name: exerciseData.name,
                muscleGroups: exerciseData.muscleGroups
            )

            for setData in exerciseData.sets {
                let set = ExerciseSet(
                    setNumber: 0,
                    targetReps: nil,
                    targetWeightKg: nil,
                    targetDurationSeconds: nil
                )
                set.completedReps = setData.reps
                set.completedWeightKg = setData.weightKg
                set.completedDurationSeconds = setData.duration
                set.completedAt = setData.completedAt
                exercise.sets.append(set)
            }

            workout.exercises.append(exercise)
        }

        modelContext.insert(workout)
        try modelContext.save()

        AppLogger.info("Workout processed and saved", category: .data)
    }
}

extension WorkoutSyncService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            AppLogger.error("WCSession activation failed", error: error, category: .data)
        }
    }

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        Task { @MainActor in
            do {
                let workoutData = try JSONDecoder().decode(WorkoutBuilderData.self, from: messageData)
                NotificationCenter.default.post(
                    name: .workoutDataReceived,
                    object: nil,
                    userInfo: ["data": workoutData]
                )
            } catch {
                AppLogger.error("Failed to decode workout data", error: error, category: .data)
            }
        }
    }
}

extension Notification.Name {
    static let workoutDataReceived = Notification.Name("workoutDataReceived")
}
