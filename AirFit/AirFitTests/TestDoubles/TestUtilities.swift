import Foundation
import SwiftData
import XCTest
@testable import AirFit

// MARK: - Base Test Case

/// Base test case with common setup and utilities
class AirFitTestCase: XCTestCase {
    
    var modelContainer: ModelContainer!
    var testUser: User!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory model container for testing
        let schema = Schema([
            User.self,
            Workout.self,
            Exercise.self,
            WorkoutSet.self,
            FoodEntry.self,
            CoachMessage.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        
        // Create test user
        testUser = createTestUser()
    }
    
    override func tearDownWithError() throws {
        modelContainer = nil
        testUser = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Factory Methods
    
    func createTestUser(
        name: String = "Test User",
        email: String = "test@example.com",
        birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    ) -> User {
        let user = User()
        user.name = name
        user.email = email
        user.birthDate = birthDate
        user.biologicalSex = "male"
        user.fitnessGoals = ["lose_weight", "build_muscle"]
        user.activityLevel = "moderately_active"
        user.dietaryPreferences = ["none"]
        return user
    }
    
    func createTestWorkout(
        name: String = "Test Workout",
        date: Date = Date(),
        exercises: [Exercise]? = nil
    ) -> Workout {
        let workout = Workout()
        workout.name = name
        workout.date = date
        workout.exercises = exercises ?? [createTestExercise()]
        return workout
    }
    
    func createTestExercise(
        name: String = "Test Exercise",
        muscleGroups: [String] = ["chest"],
        sets: [WorkoutSet]? = nil
    ) -> Exercise {
        let exercise = Exercise()
        exercise.name = name
        exercise.primaryMuscleGroups = muscleGroups
        exercise.sets = sets ?? [createTestWorkoutSet()]
        return exercise
    }
    
    func createTestWorkoutSet(
        targetReps: Int = 10,
        targetWeight: Double = 50.0,
        completedReps: Int? = nil,
        completedWeight: Double? = nil
    ) -> WorkoutSet {
        let set = WorkoutSet()
        set.targetReps = targetReps
        set.targetWeightKg = targetWeight
        set.completedReps = completedReps
        set.completedWeightKg = completedWeight
        return set
    }
    
    func createTestFoodEntry(
        name: String = "Test Food",
        calories: Int = 200,
        protein: Double = 20.0,
        carbs: Double = 30.0,
        fat: Double = 10.0
    ) -> FoodEntry {
        let entry = FoodEntry()
        entry.name = name
        entry.totalCalories = calories
        entry.totalProtein = protein
        entry.totalCarbs = carbs
        entry.totalFat = fat
        entry.loggedAt = Date()
        entry.user = testUser
        return entry
    }
    
    func createTestCoachMessage(
        content: String = "Test message",
        role: CoachMessage.Role = .coach,
        timestamp: Date = Date()
    ) -> CoachMessage {
        let message = CoachMessage()
        message.content = content
        message.role = role
        message.timestamp = timestamp
        message.user = testUser
        return message
    }
}

// MARK: - Mock Data Generators

struct MockDataGenerator {
    
    // MARK: - HealthKit Data
    
    static func createMockActivityMetrics(
        steps: Int = 8542,
        activeEnergy: Double = 450,
        exerciseMinutes: Int = 32,
        standHours: Int = 9
    ) -> ActivityMetrics {
        var metrics = ActivityMetrics()
        metrics.steps = steps
        metrics.activeEnergyBurned = Measurement(value: activeEnergy, unit: .kilocalories)
        metrics.exerciseMinutes = exerciseMinutes
        metrics.standHours = standHours
        return metrics
    }
    
    static func createMockHeartHealthMetrics(
        restingHeartRate: Int = 68,
        hrv: Double = 35.2,
        vo2Max: Double = 42.5
    ) -> HeartHealthMetrics {
        var metrics = HeartHealthMetrics()
        metrics.restingHeartRate = restingHeartRate
        metrics.hrv = Measurement(value: hrv, unit: .milliseconds)
        metrics.vo2Max = vo2Max
        return metrics
    }
    
    static func createMockBodyMetrics(
        weight: Double = 75.5,
        height: Double = 178,
        bodyFat: Double = 15.2,
        date: Date = Date()
    ) -> BodyMetrics {
        var metrics = BodyMetrics()
        metrics.weight = Measurement(value: weight, unit: .kilograms)
        metrics.height = Measurement(value: height, unit: .centimeters)
        metrics.bodyFatPercentage = bodyFat
        metrics.bmi = weight / pow(height / 100, 2)
        metrics.date = date
        return metrics
    }
    
    static func createMockSleepSession(
        bedtime: Date = Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date(),
        wakeTime: Date = Date(),
        efficiency: Double = 93.8
    ) -> SleepAnalysis.SleepSession {
        let sleepDuration = wakeTime.timeIntervalSince(bedtime)
        return SleepAnalysis.SleepSession(
            bedtime: bedtime,
            wakeTime: wakeTime,
            totalSleepTime: sleepDuration * (efficiency / 100),
            timeInBed: sleepDuration,
            efficiency: efficiency,
            remTime: sleepDuration * 0.25,
            coreTime: sleepDuration * 0.55,
            deepTime: sleepDuration * 0.15,
            awakeTime: sleepDuration * (1 - efficiency / 100)
        )
    }
    
    static func createMockWorkoutData(
        type: String = "Running",
        duration: TimeInterval = 2100,
        calories: Double = 350,
        averageHeartRate: Double = 145,
        date: Date = Date()
    ) -> WorkoutData {
        return WorkoutData(
            workoutType: type,
            startDate: date,
            duration: duration,
            totalEnergyBurned: calories,
            averageHeartRate: averageHeartRate
        )
    }
    
    static func createMockDailyBiometrics(
        date: Date = Date(),
        heartRate: Double = 70,
        hrv: Double = 35,
        sleepDuration: TimeInterval = 7.5 * 3600
    ) -> DailyBiometrics {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let bedtime = calendar.date(byAdding: .hour, value: -8, to: date) ?? date
        
        return DailyBiometrics(
            date: startOfDay,
            heartRate: heartRate,
            hrv: hrv,
            restingHeartRate: heartRate - 5,
            heartRateRecovery: 20,
            vo2Max: 42.5,
            respiratoryRate: 16,
            bedtime: bedtime,
            wakeTime: date,
            sleepDuration: sleepDuration,
            remSleep: sleepDuration * 0.25,
            coreSleep: sleepDuration * 0.55,
            deepSleep: sleepDuration * 0.15,
            awakeTime: sleepDuration * 0.05,
            sleepEfficiency: 90,
            activeEnergyBurned: 450,
            basalEnergyBurned: 1500,
            steps: 8500,
            exerciseTime: 30,
            standHours: 10
        )
    }
    
    // MARK: - AI Data
    
    static func createMockAIRequest(
        systemPrompt: String = "You are a fitness coach.",
        userMessage: String = "Help me with my workout",
        temperature: Double = 0.7,
        maxTokens: Int = 500,
        stream: Bool = false
    ) -> AIRequest {
        return AIRequest(
            systemPrompt: systemPrompt,
            messages: [AIChatMessage(role: .user, content: userMessage)],
            temperature: temperature,
            maxTokens: maxTokens,
            stream: stream,
            user: "test-user"
        )
    }
    
    static func createMockTokenUsage(
        promptTokens: Int = 100,
        completionTokens: Int = 50,
        totalTokens: Int = 150
    ) -> AITokenUsage {
        return AITokenUsage(
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens
        )
    }
    
    // MARK: - Date Helpers
    
    static func daysAgo(_ days: Int, from date: Date = Date()) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: date) ?? date
    }
    
    static func hoursAgo(_ hours: Int, from date: Date = Date()) -> Date {
        Calendar.current.date(byAdding: .hour, value: -hours, to: date) ?? date
    }
    
    static func minutesAgo(_ minutes: Int, from date: Date = Date()) -> Date {
        Calendar.current.date(byAdding: .minute, value: -minutes, to: date) ?? date
    }
    
    // MARK: - Random Data
    
    static func randomWorkoutData(count: Int, startDate: Date = Date()) -> [WorkoutData] {
        let workoutTypes = ["Running", "Cycling", "Strength Training", "Swimming", "Yoga"]
        return (0..<count).map { index in
            let date = Calendar.current.date(byAdding: .day, value: -index, to: startDate) ?? startDate
            return createMockWorkoutData(
                type: workoutTypes.randomElement() ?? "Running",
                duration: TimeInterval.random(in: 1800...7200), // 30 minutes to 2 hours
                calories: Double.random(in: 200...800),
                averageHeartRate: Double.random(in: 110...170),
                date: date
            )
        }
    }
    
    static func randomDailyBiometrics(days: Int, startDate: Date = Date()) -> [DailyBiometrics] {
        return (0..<days).map { index in
            let date = Calendar.current.date(byAdding: .day, value: -index, to: startDate) ?? startDate
            return createMockDailyBiometrics(
                date: date,
                heartRate: Double.random(in: 65...75),
                hrv: Double.random(in: 30...40),
                sleepDuration: Double.random(in: 6.5...8.5) * 3600
            )
        }
    }
}

// MARK: - Test Assertions

extension XCTestCase {
    
    /// Assert that two dates are within a specified tolerance
    func assertDatesEqual(
        _ date1: Date,
        _ date2: Date,
        tolerance: TimeInterval = 1.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let difference = abs(date1.timeIntervalSince(date2))
        XCTAssertLessThanOrEqual(
            difference,
            tolerance,
            "Dates differ by \(difference) seconds, expected within \(tolerance) seconds",
            file: file,
            line: line
        )
    }
    
    /// Assert that a double is within a percentage of an expected value
    func assertDoubleEqual(
        _ actual: Double,
        _ expected: Double,
        percentageTolerance: Double = 5.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let tolerance = abs(expected * percentageTolerance / 100.0)
        XCTAssertEqual(
            actual,
            expected,
            accuracy: tolerance,
            file: file,
            line: line
        )
    }
    
    /// Wait for async condition to be true within timeout
    func waitForCondition(
        _ condition: @autoclosure @escaping () -> Bool,
        timeout: TimeInterval = 5.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let endTime = Date().addingTimeInterval(timeout)
        
        while Date() < endTime {
            if condition() {
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        XCTFail("Condition was not met within \(timeout) seconds", file: file, line: line)
    }
}

// MARK: - Error Helpers

struct TestError: Error, Equatable {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}

// MARK: - Async Testing Utilities

@MainActor
class AsyncTestUtilities {
    
    /// Execute block and wait for result
    static func runAsync<T>(_ block: @escaping () async throws -> T) async rethrows -> T {
        return try await block()
    }
    
    /// Collect all values from an async stream
    static func collect<T>(
        from stream: AsyncThrowingStream<T, Error>,
        limit: Int = 100
    ) async throws -> [T] {
        var results: [T] = []
        var count = 0
        
        for try await value in stream {
            results.append(value)
            count += 1
            if count >= limit {
                break
            }
        }
        
        return results
    }
    
    /// Collect values from stream with timeout
    static func collect<T>(
        from stream: AsyncThrowingStream<T, Error>,
        timeout: TimeInterval,
        limit: Int = 100
    ) async throws -> [T] {
        return try await withThrowingTaskGroup(of: [T].self) { group in
            // Task to collect stream values
            group.addTask {
                try await collect(from: stream, limit: limit)
            }
            
            // Task to handle timeout
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TestError("Stream collection timed out after \(timeout) seconds")
            }
            
            // Return first completed task result
            guard let result = try await group.next() else {
                throw TestError("No tasks completed")
            }
            
            group.cancelAll()
            return result
        }
    }
}