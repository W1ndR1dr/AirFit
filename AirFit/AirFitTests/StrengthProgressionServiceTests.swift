import XCTest
@testable import AirFit

final class StrengthProgressionServiceTests: XCTestCase {
    func testRecordStrengthProgress_CreatesPRForBestSet() async throws {
        let service = StrengthProgressionService()
        let user = User(name: "Tester", preferredUnits: "imperial")

        let workout = Workout(name: "Upper Body", workoutType: .strength, plannedDate: Date(), user: user)
        let bench = Exercise(name: "Bench Press")

        let set1 = ExerciseSet(setNumber: 1, targetReps: 8, targetWeightKg: 60)
        set1.complete(reps: 8, weight: 60)
        let set2 = ExerciseSet(setNumber: 2, targetReps: 6, targetWeightKg: 70)
        set2.complete(reps: 6, weight: 70)
        bench.addSet(set1)
        bench.addSet(set2)

        workout.addExercise(bench)
        workout.completeWorkout()

        try await service.recordStrengthProgress(from: workout, for: user)

        // Should have a record with exerciseName "Bench Press"
        let records = user.strengthRecords.filter { $0.exerciseName == "Bench Press" }
        XCTAssertEqual(records.count, 1)

        // 1RM estimate from best set (70kg x 6): 70 * (1 + 6/30) = 84kg
        XCTAssertGreaterThan(records.first!.oneRepMax, 80)
        XCTAssertLessThan(records.first!.oneRepMax, 90)
    }
}

