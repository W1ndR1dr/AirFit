import Foundation
import WatchConnectivity
import CloudKit
import SwiftData

@MainActor
final class WorkoutSyncService: NSObject {
    static let shared = WorkoutSyncService()

    private let session: WCSession
    private var pendingWorkouts: [WorkoutBuilderData] = []
    private let container = CKContainer.default()

    private override init() {
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
            // Queue for later
            pendingWorkouts.append(data)
            await syncToCloudKit(data)
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            try await session.sendMessageData(encoded)
            AppLogger.info("Workout data sent to iPhone", category: .data)
        } catch {
            pendingWorkouts.append(data)
            await syncToCloudKit(data)
            AppLogger.error("Failed to send workout data", error: error, category: .data)
        }
    }

    // MARK: - CloudKit Sync
    private func syncToCloudKit(_ data: WorkoutBuilderData) async {
        let record = CKRecord(recordType: "WorkoutSync")
        record["workoutId"] = data.id.uuidString
        record["data"] = try? JSONEncoder().encode(data)
        record["timestamp"] = Date()

        do {
            _ = try await container.privateCloudDatabase.save(record)
            AppLogger.info("Workout synced to CloudKit", category: .data)
        } catch {
            AppLogger.error("CloudKit sync failed", error: error, category: .data)
        }
    }

    // MARK: - Process Received Data
    func processReceivedWorkout(_ data: WorkoutBuilderData, modelContext: ModelContext) async throws {
        let workout = Workout(
            name: HKWorkoutActivityType(rawValue: UInt(data.workoutType))?.name ?? "Workout",
            workoutType: .general
        )
        workout.plannedDate = data.startTime
        workout.completedDate = data.endTime
        workout.caloriesBurned = data.totalCalories
        workout.durationSeconds = data.duration

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
                set.completedDate = setData.completedAt
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
