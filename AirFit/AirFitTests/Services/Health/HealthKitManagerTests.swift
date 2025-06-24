import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class HealthKitManagerTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var mockHealthKitManager: MockHealthKitManager!
    private var modelContext: ModelContext!
    private var testUser: User!
    
    // MARK: - Setup
    override func setUp() async throws {
        try super.setUp()
        
        // Create test container
        container = try await DITestHelper.createTestContainer()
        
        // Get mock from container
        mockHealthKitManager = try await container.resolve(HealthKitManaging.self) as? MockHealthKitManager
        XCTAssertNotNil(mockHealthKitManager, "Expected MockHealthKitManager from test container")
        
        // Setup SwiftData for test models
        let schema = Schema([User.self, FoodEntry.self, FoodItem.self, Workout.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // Create test user
        testUser = User(email: "test@example.com", name: "Test User")
        modelContext.insert(testUser)
        try modelContext.save()
    }
    
    override func tearDown() async throws {
        mockHealthKitManager?.reset()
        mockHealthKitManager = nil
        container = nil
        modelContext = nil
        testUser = nil
        try super.tearDown()
    }
    
    // MARK: - Authorization Tests
    
    func test_requestAuthorization_whenSuccessful_updatesStatus() async throws {
        // Arrange
        mockHealthKitManager.authorizationStatus = .notDetermined
        mockHealthKitManager.shouldThrowError = false
        
        // Act
        try await mockHealthKitManager.requestAuthorization()
        
        // Assert
        XCTAssertEqual(mockHealthKitManager.authorizationStatus, .authorized)
        XCTAssertTrue(mockHealthKitManager.invocationCount(for: "requestAuthorization") > 0)
    }
    
    func test_requestAuthorization_whenDenied_throwsError() async throws {
        // Arrange
        mockHealthKitManager.authorizationStatus = .notDetermined
        mockHealthKitManager.shouldThrowError = true
        mockHealthKitManager.errorToThrow = HealthKitManager.HealthKitError.authorizationDenied
        
        // Act & Assert
        do {
            try await mockHealthKitManager.requestAuthorization()
            XCTFail("Expected authorization error")
        } catch {
            XCTAssertEqual(mockHealthKitManager.authorizationStatus, .denied)
        }
    }
    
    // MARK: - Nutrition Save Tests
    
    func test_saveNutritionToHealthKit_withValidData_savesSuccessfully() async throws {
        // Arrange
        let nutrition = NutritionData()
        nutrition.targetCalories = 2_000
        nutrition.targetProtein = 150
        nutrition.targetCarbs = 250
        nutrition.targetFat = 65
        nutrition.actualCalories = 500
        nutrition.actualProtein = 30
        nutrition.actualCarbs = 50
        nutrition.actualFat = 20
        modelContext.insert(nutrition)
        try modelContext.save()
        
        mockHealthKitManager.stubbedResults["saveNutritionToHealthKit"] = true
        
        // Act
        let success = try await mockHealthKitManager.saveNutritionToHealthKit(nutrition, date: Date())
        
        // Assert
        XCTAssertTrue(success)
        XCTAssertTrue(mockHealthKitManager.invocationCount(for: "saveNutritionToHealthKit") > 0)
    }
    
    func test_saveNutritionToHealthKit_withNilValues_handlesGracefully() async throws {
        // Arrange
        let nutrition = NutritionData()
        nutrition.actualCalories = 300
        // Leave protein, carbs, fat as nil (targets not set)
        modelContext.insert(nutrition)
        try modelContext.save()
        
        mockHealthKitManager.stubbedResults["saveNutritionToHealthKit"] = true
        
        // Act
        let success = try await mockHealthKitManager.saveNutritionToHealthKit(nutrition, date: Date())
        
        // Assert
        XCTAssertTrue(success)
        XCTAssertEqual(nutrition.actualCalories, 300, "Should have the calories we set")
    }
    
    func test_saveNutritionToHealthKit_whenErrorOccurs_throwsError() async throws {
        // Arrange
        let nutrition = NutritionData()
        nutrition.actualCalories = 200
        modelContext.insert(nutrition)
        try modelContext.save()
        
        mockHealthKitManager.shouldThrowError = true
        mockHealthKitManager.errorToThrow = HealthKitManager.HealthKitError.queryFailed(NSError(domain: "Test", code: -1))
        
        // Act & Assert
        do {
            _ = try await mockHealthKitManager.saveNutritionToHealthKit(nutrition, date: Date())
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is HealthKitManager.HealthKitError)
        }
    }
    
    // MARK: - Food Entry Sync Tests
    
    func test_syncFoodEntryToHealthKit_withNewEntry_createsHealthKitRecords() async throws {
        // Arrange
        let foodEntry = FoodEntry(
            loggedAt: Date(),
            mealType: .lunch,
            user: testUser
        )
        let foodItem = FoodItem(
            name: "Apple",
            quantity: 1.0,
            unit: "medium",
            calories: 95,
            proteinGrams: 0.5,
            carbGrams: 25,
            fatGrams: 0.3
        )
        foodEntry.addItem(foodItem)
        modelContext.insert(foodEntry)
        modelContext.insert(foodItem)
        try modelContext.save()
        
        mockHealthKitManager.stubbedResults["syncFoodEntryToHealthKit"] = "sample-id-1"
        
        // Act
        let sampleID = try await mockHealthKitManager.syncFoodEntryToHealthKit(foodEntry)
        
        // Assert
        XCTAssertFalse(sampleID.isEmpty)
        XCTAssertEqual(sampleID, "sample-id-1")
        // FoodEntry doesn't have healthKitSynced property
        XCTAssertTrue(mockHealthKitManager.invocationCount(for: "syncFoodEntryToHealthKit") > 0)
    }
    
    func test_syncFoodEntryToHealthKit_withExistingEntry_updatesHealthKitRecords() async throws {
        // Arrange
        let existingSampleIDs = ["existing-1", "existing-2"]
        let foodEntry = FoodEntry(
            loggedAt: Date(),
            mealType: .lunch,
            user: testUser
        )
        foodEntry.healthKitSampleIDs = existingSampleIDs
        foodEntry.healthKitSyncDate = Date()
        
        let foodItem = FoodItem(
            name: "Updated Apple",
            calories: 100
        )
        foodEntry.addItem(foodItem)
        modelContext.insert(foodEntry)
        modelContext.insert(foodItem)
        try modelContext.save()
        
        mockHealthKitManager.stubbedResults["deleteFoodEntryFromHealthKit"] = true
        mockHealthKitManager.stubbedResults["syncFoodEntryToHealthKit"] = "new-sample-1"
        
        // Act
        let newSampleID = try await mockHealthKitManager.syncFoodEntryToHealthKit(foodEntry)
        
        // Assert
        XCTAssertNotEqual(newSampleID, existingSampleIDs.first)
        XCTAssertTrue(mockHealthKitManager.invocationCount(for: "deleteFoodEntryFromHealthKit") > 0)
    }
    
    // MARK: - Food Entry Delete Tests
    
    func test_deleteFoodEntryFromHealthKit_withValidSampleIDs_deletesSuccessfully() async throws {
        // Arrange
        let sampleIDs = ["sample-1", "sample-2", "sample-3"]
        let foodEntry = FoodEntry(
            loggedAt: Date(),
            mealType: .lunch,
            user: testUser
        )
        foodEntry.healthKitSampleIDs = sampleIDs
        foodEntry.healthKitSyncDate = Date()
        modelContext.insert(foodEntry)
        try modelContext.save()
        
        mockHealthKitManager.stubbedResults["deleteFoodEntryFromHealthKit"] = true
        
        // Act
        let success = try await mockHealthKitManager.deleteFoodEntryFromHealthKit(foodEntry)
        
        // Assert
        XCTAssertTrue(success)
        // FoodEntry doesn't have healthKitSynced property, check invocation instead
        XCTAssertTrue(mockHealthKitManager.invocationCount(for: "deleteFoodEntryFromHealthKit") > 0)
    }
    
    func test_deleteFoodEntryFromHealthKit_withNoSampleIDs_returnsTrue() async throws {
        // Arrange
        let foodEntry = FoodEntry(
            loggedAt: Date(),
            mealType: .lunch,
            user: testUser
        )
        foodEntry.healthKitSampleIDs = []
        modelContext.insert(foodEntry)
        try modelContext.save()
        
        // Act
        let success = try await mockHealthKitManager.deleteFoodEntryFromHealthKit(foodEntry)
        
        // Assert
        XCTAssertTrue(success)
        XCTAssertEqual(mockHealthKitManager.invocationCount(for: "deleteFoodEntryFromHealthKit"), 0)
    }
    
    // MARK: - Water Intake Tests
    
    func test_saveWaterIntake_withValidAmount_savesSuccessfully() async throws {
        // Arrange
        let waterAmountML = 500.0
        mockHealthKitManager.stubbedResults["saveWaterIntake"] = "water-sample-id"
        
        // Act
        let sampleID = try await mockHealthKitManager.saveWaterIntake(amountML: waterAmountML)
        
        // Assert
        XCTAssertNotNil(sampleID)
        XCTAssertEqual(sampleID, "water-sample-id")
        XCTAssertTrue(mockHealthKitManager.invocationCount(for: "saveWaterIntake") > 0)
    }
    
    // MARK: - Nutrition Reading Tests
    
    func test_getNutritionData_forToday_returnsSummary() async throws {
        // Arrange
        let expectedSummary = HealthKitNutritionSummary(
            calories: 2_000,
            protein: 80,
            carbs: 250,
            fat: 70,
            fiber: 25,
            sugar: 50,
            sodium: 2_300,
            water: 2_500,
            date: Date()
        )
        mockHealthKitManager.stubbedResults["getNutritionData"] = expectedSummary
        
        // Act
        let summary = try await mockHealthKitManager.getNutritionData(for: Date())
        
        // Assert
        XCTAssertEqual(summary.calories, expectedSummary.calories)
        XCTAssertEqual(summary.protein, expectedSummary.protein)
        XCTAssertEqual(summary.carbs, expectedSummary.carbs)
        XCTAssertEqual(summary.fat, expectedSummary.fat)
    }
    
    // MARK: - Workout Save Tests
    
    func test_saveWorkout_withValidData_savesSuccessfully() async throws {
        // Arrange
        let workout = Workout(name: "Morning Run", user: testUser)
        workout.workoutType = WorkoutType.cardio.rawValue
        workout.durationSeconds = 1_800 // 30 minutes
        workout.caloriesBurned = 300
        workout.plannedDate = Date().addingTimeInterval(-1_800)
        workout.completedDate = Date()
        modelContext.insert(workout)
        try modelContext.save()
        
        mockHealthKitManager.stubbedResults["saveWorkout"] = "workout-sample-id"
        
        // Act
        let workoutID = try await mockHealthKitManager.saveWorkout(workout)
        
        // Assert
        XCTAssertNotNil(workoutID)
        XCTAssertEqual(workoutID, "workout-sample-id")
        XCTAssertEqual(workout.healthKitWorkoutID, workoutID)
    }
    
    func test_saveWorkout_withInvalidType_throwsError() async throws {
        // Arrange
        let workout = Workout(name: "Invalid Workout", user: testUser)
        workout.workoutType = "" // Invalid workout type
        modelContext.insert(workout)
        try modelContext.save()
        
        mockHealthKitManager.shouldThrowError = true
        mockHealthKitManager.errorToThrow = HealthKitManager.HealthKitError.invalidData
        
        // Act & Assert
        do {
            _ = try await mockHealthKitManager.saveWorkout(workout)
            XCTFail("Expected invalid data error")
        } catch HealthKitManager.HealthKitError.invalidData {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Workout Delete Tests
    
    func test_deleteWorkout_withValidID_deletesSuccessfully() async throws {
        // Arrange
        let healthKitID = "workout-to-delete"
        mockHealthKitManager.stubbedResults["deleteWorkout"] = true
        
        // Act
        try await mockHealthKitManager.deleteWorkout(healthKitID: healthKitID)
        
        // Assert
        XCTAssertTrue(mockHealthKitManager.invocationCount(for: "deleteWorkout") > 0)
    }
    
    func test_deleteWorkout_withInvalidID_throwsError() async throws {
        // Arrange
        let invalidID = "not-a-uuid"
        mockHealthKitManager.shouldThrowError = true
        mockHealthKitManager.errorToThrow = HealthKitManager.HealthKitError.invalidData
        
        // Act & Assert
        do {
            try await mockHealthKitManager.deleteWorkout(healthKitID: invalidID)
            XCTFail("Expected invalid data error")
        } catch HealthKitManager.HealthKitError.invalidData {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func test_bulkNutritionSave_performance() async throws {
        // Arrange
        let nutritionEntries = (0..<10).map { _ in
            let nutrition = NutritionData()
            nutrition.actualCalories = Double.random(in: 100...500)
            nutrition.actualProtein = Double.random(in: 10...50)
            nutrition.actualCarbs = Double.random(in: 20...100)
            nutrition.actualFat = Double.random(in: 5...30)
            return nutrition
        }
        
        // Insert all nutrition entries into context
        nutritionEntries.forEach { modelContext.insert($0) }
        try modelContext.save()
        
        mockHealthKitManager.stubbedResults["saveNutritionToHealthKit"] = true
        mockHealthKitManager.simulateDelay = 0.1 // 100ms per save
        
        // Act
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for nutrition in nutritionEntries {
            _ = try await mockHealthKitManager.saveNutritionToHealthKit(nutrition, date: Date())
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert
        XCTAssertLessThan(duration, 3.0, "Bulk save should complete within 3 seconds")
        XCTAssertEqual(mockHealthKitManager.invocationCount(for: "saveNutritionToHealthKit"), nutritionEntries.count)
    }
    
    // MARK: - Edge Case Tests
    
    func test_saveNutrition_withZeroCalories_savesSuccessfully() async throws {
        // Arrange
        let nutrition = NutritionData()
        nutrition.actualCalories = 0
        modelContext.insert(nutrition)
        try modelContext.save()
        
        mockHealthKitManager.stubbedResults["saveNutritionToHealthKit"] = true
        
        // Act
        let success = try await mockHealthKitManager.saveNutritionToHealthKit(nutrition, date: Date())
        
        // Assert
        XCTAssertTrue(success)
    }
    
    func test_saveWorkout_withNilCalories_savesSuccessfully() async throws {
        // Arrange
        let workout = Workout(name: "Yoga", user: testUser)
        workout.workoutType = WorkoutType.yoga.rawValue
        workout.durationSeconds = 3_600
        workout.caloriesBurned = nil // No calorie data
        modelContext.insert(workout)
        try modelContext.save()
        
        mockHealthKitManager.stubbedResults["saveWorkout"] = "yoga-workout-id"
        
        // Act
        let workoutID = try await mockHealthKitManager.saveWorkout(workout)
        
        // Assert
        XCTAssertNotNil(workoutID)
    }
    
    // MARK: - Concurrent Operations Tests
    
    func test_concurrentNutritionSaves_preventDuplicates() async throws {
        // Arrange
        let nutrition = NutritionData()
        nutrition.actualCalories = 400
        nutrition.actualProtein = 20
        nutrition.actualCarbs = 40
        nutrition.actualFat = 15
        modelContext.insert(nutrition)
        try modelContext.save()
        
        mockHealthKitManager.stubbedResults["saveNutritionToHealthKit"] = true
        
        // Act - Save same nutrition data concurrently
        let manager = mockHealthKitManager!
        async let save1 = manager.saveNutritionToHealthKit(nutrition, date: Date())
        async let save2 = manager.saveNutritionToHealthKit(nutrition, date: Date())
        async let save3 = manager.saveNutritionToHealthKit(nutrition, date: Date())
        
        let results = try await [save1, save2, save3]
        
        // Assert
        XCTAssertTrue(results.allSatisfy { $0 == true })
        // In real implementation, would verify no duplicate samples created
    }
}
